package com.wickedstudios.wonderlot.render

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.GridCoord
import kotlin.math.hypot

/**
 * Hosts the park renderer and turns touches into commands.
 *
 * A one-finger drag moves the camera, so looking around the park can never
 * place anything by accident. Two modes take that finger for themselves:
 * drawing a walkway, and sliding a placement that is waiting to be confirmed.
 * In both, two fingers still move the camera.
 */
@SuppressLint("ViewConstructor")
class ParkView(
    context: Context,
    val controller: GameController,
    val renderer: ParkRenderer,
    /** Told whenever the interface should be redrawn from the controller. */
    private val onVersion: (Int) -> Unit,
) : View(context) {

    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop.toFloat()
    private val density = resources.displayMetrics.density

    private var lastFrameNanos = 0L
    private var reportedVersion = -1

    // Gesture state.
    private var downX = 0f
    private var downY = 0f
    private var lastX = 0f
    private var lastY = 0f
    private var moved = false
    private var multiTouch = false
    private var lastSpread = 0f
    private var lastMidX = 0f
    private var lastMidY = 0f

    /** Where a drag of a waiting placement started, and where the placement was at the time. */
    private var dragAnchor: GridCoord? = null
    private var dragOrigin: GridCoord? = null

    init {
        isFocusable = true
        if (renderer.isInteractive) renderer.centreOnEntrance()
    }

    override fun onDraw(canvas: Canvas) {
        val now = System.nanoTime()
        val delta = if (lastFrameNanos == 0L) 0.0 else (now - lastFrameNanos) / 1_000_000_000.0
        lastFrameNanos = now

        renderer.frame(canvas, width, height, density, delta)

        if (controller.uiVersion != reportedVersion) {
            reportedVersion = controller.uiVersion
            onVersion(reportedVersion)
        }
        postInvalidateOnAnimation()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        lastFrameNanos = 0L
    }

    private val takesOneFinger: Boolean
        get() = (controller.canDraw && controller.build.isDrawing) || controller.build.pending != null

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (!renderer.isInteractive) return false

        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.x
                downY = event.y
                lastX = event.x
                lastY = event.y
                moved = false
                multiTouch = false
                dragAnchor = null
                dragOrigin = null
                parent?.requestDisallowInterceptTouchEvent(true)
            }

            MotionEvent.ACTION_POINTER_DOWN -> {
                multiTouch = true
                moved = true
                captureTwoFingers(event)
            }

            MotionEvent.ACTION_MOVE -> {
                if (event.pointerCount >= 2) {
                    twoFingerMove(event)
                } else if (!multiTouch) {
                    singleFingerMove(event)
                } else {
                    // One finger left after a pinch: carry on from where it is, without a jump.
                    lastX = event.x
                    lastY = event.y
                }
            }

            MotionEvent.ACTION_POINTER_UP -> {
                // The remaining finger takes over smoothly.
                val remaining = if (event.actionIndex == 0) 1 else 0
                if (remaining < event.pointerCount) {
                    lastX = event.getX(remaining)
                    lastY = event.getY(remaining)
                }
            }

            MotionEvent.ACTION_UP -> {
                if (!moved && !multiTouch) handleTap(event.x, event.y)
                if (controller.build.isDrawing) {
                    controller.endPaint()
                    renderer.tileAt(event.x, event.y)?.let { controller.updateGhost(it) }
                }
                dragAnchor = null
                dragOrigin = null
            }

            MotionEvent.ACTION_CANCEL -> {
                controller.endPaint()
                dragAnchor = null
                dragOrigin = null
            }
        }
        return true
    }

    private fun captureTwoFingers(event: MotionEvent) {
        if (event.pointerCount < 2) return
        lastSpread = hypot(event.getX(0) - event.getX(1), event.getY(0) - event.getY(1))
        lastMidX = (event.getX(0) + event.getX(1)) / 2
        lastMidY = (event.getY(0) + event.getY(1)) / 2
    }

    private fun twoFingerMove(event: MotionEvent) {
        val spread = hypot(event.getX(0) - event.getX(1), event.getY(0) - event.getY(1))
        val midX = (event.getX(0) + event.getX(1)) / 2
        val midY = (event.getY(0) + event.getY(1)) / 2

        if (lastSpread > 0f && spread > 0f) renderer.zoomBy((spread / lastSpread).toDouble(), midX, midY)
        renderer.panBy(midX - lastMidX, midY - lastMidY)

        lastSpread = spread
        lastMidX = midX
        lastMidY = midY
    }

    private fun singleFingerMove(event: MotionEvent) {
        if (!moved && hypot(event.x - downX, event.y - downY) < touchSlop) return
        moved = true

        val coord = renderer.tileAt(event.x, event.y)

        if (controller.build.pending != null) {
            if (coord == null) return
            // Moved by how far the finger has travelled rather than to wherever it is, so the building keeps
            // the same offset from the fingertip it had when the drag started.
            val anchor = dragAnchor
            val origin = dragOrigin
            if (anchor == null || origin == null) {
                dragAnchor = renderer.tileAt(downX, downY) ?: coord
                dragOrigin = controller.build.pending?.origin
            } else {
                controller.movePending(GridCoord(origin.x + coord.x - anchor.x, origin.y + coord.y - anchor.y))
            }
            return
        }

        if (controller.canDraw && controller.build.isDrawing) {
            if (coord != null) {
                controller.updateGhost(coord)
                controller.paint(coord)
            }
            return
        }

        renderer.panBy(event.x - lastX, event.y - lastY)
        lastX = event.x
        lastY = event.y
    }

    private fun handleTap(x: Float, y: Float) {
        val coord = renderer.tileAt(x, y) ?: return
        val (guestID, staffID) = renderer.personNear(renderer.worldX(x), renderer.worldY(y), controller.state, controller.build.isActive)
        controller.handleTap(coord, guestID, staffID)
    }
}
