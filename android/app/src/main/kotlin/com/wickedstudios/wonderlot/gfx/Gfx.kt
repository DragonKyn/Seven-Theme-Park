package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import kotlin.math.max
import kotlin.math.min

/*
 * A small drawing layer that mirrors the parts of UIKit / Core Graphics the
 * park's procedural artwork was written against: UIColor, UIBezierPath, a
 * current graphics context with fill/stroke colours, and CGRect/CGPoint/CGSize.
 * Keeping the shapes of those APIs means the artwork translates almost line
 * for line, and any change to a drawing is made in one place.
 *
 * Geometry is Double throughout (Swift's CGFloat), converted to Float only when
 * it reaches Android's Canvas.
 */

data class CGPoint(var x: Double = 0.0, var y: Double = 0.0) {
    constructor(x: Number, y: Number) : this(x.toDouble(), y.toDouble())

    companion object {
        val zero get() = CGPoint(0.0, 0.0)
    }
}

data class CGSize(var width: Double = 0.0, var height: Double = 0.0) {
    constructor(width: Number, height: Number) : this(width.toDouble(), height.toDouble())

    companion object {
        val zero get() = CGSize(0.0, 0.0)
    }
}

data class CGRect(var x: Double = 0.0, var y: Double = 0.0, var width: Double = 0.0, var height: Double = 0.0) {
    constructor(x: Number, y: Number, width: Number, height: Number) :
        this(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble())

    constructor(origin: CGPoint, size: CGSize) : this(origin.x, origin.y, size.width, size.height)

    val minX get() = x
    val minY get() = y
    val maxX get() = x + width
    val maxY get() = y + height
    val midX get() = x + width / 2
    val midY get() = y + height / 2
    val origin get() = CGPoint(x, y)
    val size get() = CGSize(width, height)

    fun insetBy(dx: Number, dy: Number): CGRect {
        val ix = dx.toDouble()
        val iy = dy.toDouble()
        return CGRect(x + ix, y + iy, width - 2 * ix, height - 2 * iy)
    }

    fun offsetBy(dx: Number, dy: Number) = CGRect(x + dx.toDouble(), y + dy.toDouble(), width, height)

    fun contains(point: CGPoint) = point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY

    fun toRectF() = RectF(x.toFloat(), y.toFloat(), (x + width).toFloat(), (y + height).toFloat())

    companion object {
        val zero get() = CGRect(0.0, 0.0, 0.0, 0.0)
    }
}

/** A 2D affine transform, composed the way Core Graphics composes them. */
class CGAffineTransform(val matrix: Matrix = Matrix()) {
    constructor(translationX: Number, y: Number) : this(Matrix().apply { setTranslate(translationX.toFloat(), y.toFloat()) })

    fun translatedBy(x: Number, y: Number): CGAffineTransform {
        val m = Matrix(matrix)
        m.preTranslate(x.toFloat(), y.toFloat())
        return CGAffineTransform(m)
    }

    fun scaledBy(x: Number, y: Number): CGAffineTransform {
        val m = Matrix(matrix)
        m.preScale(x.toFloat(), y.toFloat())
        return CGAffineTransform(m)
    }

    fun rotated(by: Number): CGAffineTransform {
        val m = Matrix(matrix)
        m.preRotate(Math.toDegrees(by.toDouble()).toFloat())
        return CGAffineTransform(m)
    }

    companion object {
        val identity get() = CGAffineTransform()
        fun translation(x: Number, y: Number) = CGAffineTransform(Matrix().apply { setTranslate(x.toFloat(), y.toFloat()) })
        fun scale(x: Number, y: Number) = CGAffineTransform(Matrix().apply { setScale(x.toFloat(), y.toFloat()) })
        fun rotation(angle: Number) =
            CGAffineTransform(Matrix().apply { setRotate(Math.toDegrees(angle.toDouble()).toFloat()) })
    }
}

class UIColor(val red: Double, val green: Double, val blue: Double, val alpha: Double = 1.0) {
    constructor(red: Number, green: Number, blue: Number, alpha: Number) :
        this(red.toDouble(), green.toDouble(), blue.toDouble(), alpha.toDouble())

    /** A grey, as UIColor(white:alpha:). */
    constructor(white: Number, alpha: Number) : this(white.toDouble(), white.toDouble(), white.toDouble(), alpha.toDouble())

    val argb: Int
        get() {
            fun channel(v: Double) = (v.coerceIn(0.0, 1.0) * 255 + 0.5).toInt()
            return (channel(alpha) shl 24) or (channel(red) shl 16) or (channel(green) shl 8) or channel(blue)
        }

    fun withAlphaComponent(a: Number) = UIColor(red, green, blue, a.toDouble())

    /** Blends towards another colour. */
    fun blended(with: UIColor, fraction: Double) = UIColor(
        red + (with.red - red) * fraction, green + (with.green - green) * fraction,
        blue + (with.blue - blue) * fraction, alpha + (with.alpha - alpha) * fraction,
    )

    fun setFill() {
        Gfx.context.fillColor = this
    }

    fun setStroke() {
        Gfx.context.strokeColor = this
    }

    override fun equals(other: Any?) = other is UIColor && other.argb == argb
    override fun hashCode() = argb

    companion object {
        val white get() = UIColor(1.0, 1.0, 1.0, 1.0)
        val black get() = UIColor(0.0, 0.0, 0.0, 1.0)
        val clear get() = UIColor(0.0, 0.0, 0.0, 0.0)
    }
}

enum class UIRectCorner { topLeft, topRight, bottomLeft, bottomRight }
enum class LineCap { butt, round, square }
enum class LineJoin { miter, round, bevel }
enum class BlendMode { normal, clear, multiply, destinationOut }

/** A shape. Like UIBezierPath, it carries its own stroke width and is drawn into the current context. */
class UIBezierPath() {
    val path = Path()
    var lineWidth: Double = 1.0
    var lineCapStyle: LineCap = LineCap.butt
    var lineJoinStyle: LineJoin = LineJoin.miter
    var usesEvenOddFillRule: Boolean = false
    private var dash: FloatArray? = null
    private var current = CGPoint(0.0, 0.0)

    constructor(rect: CGRect) : this() {
        path.addRect(rect.toRectF(), Path.Direction.CW)
    }

    constructor(ovalIn: CGRect, @Suppress("UNUSED_PARAMETER") oval: Boolean = true) : this() {
        path.addOval(ovalIn.toRectF(), Path.Direction.CW)
    }

    constructor(roundedRect: CGRect, cornerRadius: Number) : this() {
        val radius = min(cornerRadius.toDouble(), min(roundedRect.width, roundedRect.height) / 2).toFloat()
        path.addRoundRect(roundedRect.toRectF(), radius, radius, Path.Direction.CW)
    }

    constructor(rect: CGRect, corners: List<UIRectCorner>, radii: CGSize) : this() {
        val rx = radii.width.toFloat()
        val ry = radii.height.toFloat()
        fun r(corner: UIRectCorner) = if (corner in corners) floatArrayOf(rx, ry) else floatArrayOf(0f, 0f)
        val tl = r(UIRectCorner.topLeft)
        val tr = r(UIRectCorner.topRight)
        val br = r(UIRectCorner.bottomRight)
        val bl = r(UIRectCorner.bottomLeft)
        path.addRoundRect(rect.toRectF(), floatArrayOf(tl[0], tl[1], tr[0], tr[1], br[0], br[1], bl[0], bl[1]), Path.Direction.CW)
    }

    /** An arc about a centre, in radians, clockwise in the y-down space the artwork is drawn in. */
    constructor(arcCenter: CGPoint, radius: Number, startAngle: Number, endAngle: Number, clockwise: Boolean) : this() {
        addArc(arcCenter, radius, startAngle, endAngle, clockwise, newSubpath = true)
    }

    fun move(to: CGPoint) {
        path.moveTo(to.x.toFloat(), to.y.toFloat())
        current = to
    }

    fun addLine(to: CGPoint) {
        path.lineTo(to.x.toFloat(), to.y.toFloat())
        current = to
    }

    fun addCurve(to: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
        path.cubicTo(controlPoint1.x.toFloat(), controlPoint1.y.toFloat(),
            controlPoint2.x.toFloat(), controlPoint2.y.toFloat(), to.x.toFloat(), to.y.toFloat())
        current = to
    }

    fun addQuadCurve(to: CGPoint, controlPoint: CGPoint) {
        path.quadTo(controlPoint.x.toFloat(), controlPoint.y.toFloat(), to.x.toFloat(), to.y.toFloat())
        current = to
    }

    fun addArc(withCenter: CGPoint, radius: Number, startAngle: Number, endAngle: Number, clockwise: Boolean,
               newSubpath: Boolean = false) {
        val r = radius.toDouble()
        val rect = RectF((withCenter.x - r).toFloat(), (withCenter.y - r).toFloat(),
            (withCenter.x + r).toFloat(), (withCenter.y + r).toFloat())
        val start = Math.toDegrees(startAngle.toDouble())
        var sweep = Math.toDegrees(endAngle.toDouble()) - start
        // Android sweeps positive angles clockwise on screen, as UIKit does in a flipped context.
        if (clockwise) { while (sweep < 0) sweep += 360.0 } else { while (sweep > 0) sweep -= 360.0 }
        if (newSubpath) path.arcTo(rect, start.toFloat(), sweep.toFloat(), true)
        else path.arcTo(rect, start.toFloat(), sweep.toFloat(), false)
    }

    fun close() = path.close()

    fun append(other: UIBezierPath) {
        path.addPath(other.path)
    }

    fun apply(transform: CGAffineTransform) {
        path.transform(transform.matrix)
    }

    fun setLineDash(pattern: List<Number>, phase: Number = 0) {
        dash = if (pattern.isEmpty()) null else pattern.map { it.toFloat() }.toFloatArray()
        dashPhase = phase.toFloat()
    }

    private var dashPhase = 0f

    val bounds: CGRect
        get() {
            val box = RectF()
            @Suppress("DEPRECATION")
            path.computeBounds(box, true)
            return CGRect(box.left.toDouble(), box.top.toDouble(), (box.right - box.left).toDouble(), (box.bottom - box.top).toDouble())
        }

    fun fill() {
        val ctx = Gfx.context
        path.fillType = if (usesEvenOddFillRule) Path.FillType.EVEN_ODD else Path.FillType.WINDING
        ctx.drawPath(path, fill = true, color = ctx.fillColor, lineWidth = 0.0, cap = lineCapStyle, join = lineJoinStyle, dash = null, dashPhase = 0f)
    }

    fun stroke() {
        val ctx = Gfx.context
        ctx.drawPath(path, fill = false, color = ctx.strokeColor, lineWidth = lineWidth, cap = lineCapStyle, join = lineJoinStyle, dash = dash, dashPhase = dashPhase)
    }

    fun addClip() {
        Gfx.context.canvas.clipPath(path)
    }
}

/** The state of one drawing surface. */
class CGContext(val canvas: Canvas) {
    var fillColor: UIColor = UIColor.black
    var strokeColor: UIColor = UIColor.black
    var lineWidth: Double = 1.0
    private var shadow: Triple<CGSize, Double, UIColor>? = null
    var blend: BlendMode = BlendMode.normal

    private class Saved(val fill: UIColor, val stroke: UIColor, val lineWidth: Double,
                        val shadow: Triple<CGSize, Double, UIColor>?, val blend: BlendMode)

    private val stack = ArrayList<Saved>()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    fun saveGState() {
        canvas.save()
        stack.add(Saved(fillColor, strokeColor, lineWidth, shadow, blend))
    }

    fun restoreGState() {
        canvas.restore()
        val saved = stack.removeLastOrNull() ?: return
        fillColor = saved.fill
        strokeColor = saved.stroke
        lineWidth = saved.lineWidth
        shadow = saved.shadow
        blend = saved.blend
    }

    fun translateBy(x: Number, y: Number) = canvas.translate(x.toFloat(), y.toFloat())
    fun scaleBy(x: Number, y: Number) = canvas.scale(x.toFloat(), y.toFloat())
    fun rotate(by: Number) = canvas.rotate(Math.toDegrees(by.toDouble()).toFloat())

    @JvmName("applyFillColor") fun setFillColor(color: UIColor) { fillColor = color }
    @JvmName("applyStrokeColor") fun setStrokeColor(color: UIColor) { strokeColor = color }
    fun setLineWidth(width: Number) { lineWidth = width.toDouble() }
    fun setBlendMode(mode: BlendMode) { blend = mode }

    /** A soft shadow beneath whatever is drawn next; pass a null colour to turn it off. */
    fun setShadow(offset: CGSize, blur: Number, color: UIColor?) {
        shadow = if (color == null) null else Triple(offset, blur.toDouble(), color)
    }

    fun fill(rect: CGRect) {
        UIBezierPath(rect).also { it.fill() }
    }

    fun stroke(rect: CGRect) {
        UIBezierPath(rect).also {
            it.lineWidth = lineWidth
            it.stroke()
        }
    }

    fun fillEllipse(rect: CGRect) {
        UIBezierPath(ovalIn = rect).fill()
    }

    fun clip(rect: CGRect) {
        canvas.clipRect(rect.toRectF())
    }

    fun draw(bitmap: Bitmap, rect: CGRect) {
        canvas.drawBitmap(bitmap, null, rect.toRectF(), null)
    }

    internal fun drawPath(path: Path, fill: Boolean, color: UIColor, lineWidth: Double,
                          cap: LineCap, join: LineJoin, dash: FloatArray?, dashPhase: Float) {
        paint.reset()
        paint.isAntiAlias = true
        paint.color = color.argb
        paint.style = if (fill) Paint.Style.FILL else Paint.Style.STROKE
        if (!fill) {
            paint.strokeWidth = lineWidth.toFloat()
            paint.strokeCap = when (cap) {
                LineCap.butt -> Paint.Cap.BUTT
                LineCap.round -> Paint.Cap.ROUND
                LineCap.square -> Paint.Cap.SQUARE
            }
            paint.strokeJoin = when (join) {
                LineJoin.miter -> Paint.Join.MITER
                LineJoin.round -> Paint.Join.ROUND
                LineJoin.bevel -> Paint.Join.BEVEL
            }
            if (dash != null) paint.pathEffect = DashPathEffect(dash, dashPhase)
        }
        shadow?.let { (offset, blur, shadowColor) ->
            paint.setShadowLayer(max(0.01, blur).toFloat(), offset.width.toFloat(), -offset.height.toFloat(), shadowColor.argb)
        }
        when (blend) {
            BlendMode.clear -> paint.xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.CLEAR)
            BlendMode.destinationOut -> paint.xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.DST_OUT)
            BlendMode.multiply -> paint.xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.MULTIPLY)
            BlendMode.normal -> {}
        }
        canvas.drawPath(path, paint)
    }
}

/** The graphics context everything draws into. */
object Gfx {
    private val stack = ArrayList<CGContext>()

    val context: CGContext
        get() = stack.lastOrNull() ?: error("Nothing is being drawn right now")

    /** Draws into [canvas] for the duration of [block]. */
    fun <T> with(canvas: Canvas, block: (CGContext) -> T): T {
        val ctx = CGContext(canvas)
        stack.add(ctx)
        try {
            return block(ctx)
        } finally {
            stack.removeAt(stack.lastIndex)
        }
    }

    /**
     * Renders to an image of [size] points at [scale] pixels per point. The
     * drawing works in points with the origin at the top left, as UIKit's
     * image renderer does.
     */
    fun image(size: CGSize, scale: Double, draw: (CGContext, CGSize) -> Unit): Bitmap {
        val width = max(1, Math.ceil(size.width * scale).toInt())
        val height = max(1, Math.ceil(size.height * scale).toInt())
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.scale(scale.toFloat(), scale.toFloat())
        with(canvas) { draw(it, size) }
        return bitmap
    }
}
