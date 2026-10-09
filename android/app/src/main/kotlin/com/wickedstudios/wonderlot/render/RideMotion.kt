package com.wickedstudios.wonderlot.render

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.BuildingMotion
import com.wickedstudios.wonderlot.gfx.BuildingArtStructures
import com.wickedstudios.wonderlot.gfx.BuildingArtwork
import com.wickedstudios.wonderlot.gfx.CGPoint
import com.wickedstudios.wonderlot.gfx.CGSize
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * The moving parts of a ride, as pure functions of the ride's own clock.
 *
 * Each part is placed in building space: origin at the middle of the building,
 * y upward, in the same points the artwork is drawn in. A ride that is closed
 * or broken simply stops advancing its clock, so nothing has to be scheduled,
 * paused or cancelled.
 */
class MotionPose {
    var x = 0.0
    var y = 0.0

    /** Anticlockwise, in radians. */
    var angle = 0.0
    var scaleX = 1.0
    var scaleY = 1.0
    var alpha = 1.0

    fun reset() {
        x = 0.0; y = 0.0; angle = 0.0; scaleX = 1.0; scaleY = 1.0; alpha = 1.0
    }
}

class MotionPart(
    val bitmap: Bitmap,
    val size: CGSize,
    val anchorX: Double,
    val anchorY: Double,
    val pose: (Double, MotionPose) -> Unit,
)

class MotionSet(val key: String, val parts: List<MotionPart>) {
    var clock = 0.0
}

enum class Ease { linear, inOut, easeIn, easeOut }

/** One leg of a repeating animation: reach [to] in [duration] seconds. A null [to] holds where it is. */
class Seg(val duration: Double, val to: Double? = null, val ease: Ease = Ease.linear, val from: Double? = null)

/** A value that follows a looping list of legs, after an optional delay. */
class Track(private val start: Double, private val segs: List<Seg>, private val delay: Double = 0.0) {
    private val cycle = segs.sumOf { it.duration }

    fun at(time: Double): Double {
        val t = time - delay
        if (t <= 0 || cycle <= 0) return start
        val round = (t / cycle).toInt()
        var local = t - round * cycle

        // The value a cycle begins from: where the last one ended, so loops that return to their start are seamless.
        var value = if (round == 0) start else endValue()
        for (seg in segs) {
            val from = seg.from ?: value
            val target = seg.to ?: from
            if (local <= seg.duration) {
                val u = if (seg.duration <= 0) 1.0 else local / seg.duration
                return from + (target - from) * eased(seg.ease, u)
            }
            local -= seg.duration
            value = target
        }
        return value
    }

    private fun endValue(): Double {
        var value = start
        for (seg in segs) {
            val from = seg.from ?: value
            value = seg.to ?: from
        }
        return value
    }

    private fun eased(ease: Ease, u: Double): Double = when (ease) {
        Ease.linear -> u
        Ease.easeIn -> u * u
        Ease.easeOut -> 1 - (1 - u) * (1 - u)
        Ease.inOut -> u * u * (3 - 2 * u)
    }
}

object RideMotion {

    private const val TWO_PI = PI * 2

    /** Builds every moving part a building has, or nothing for a building that stands still. */
    fun build(appearance: BuildingAppearance, buildingSize: CGSize): List<MotionPart> {
        val motif = appearance.motif
        val motion = motif.motion
        if (motion == BuildingMotion.none) return emptyList()

        val partSize = BuildingArtwork.motionPartSize(motif, buildingSize)
        val parts = ArrayList<MotionPart>()
        for (index in 0 until BuildingArtwork.motionPartCount(motif)) {
            val bitmap = BuildingArtwork.motionTexture(appearance, buildingSize, index) ?: continue
            parts.add(part(motion, motif, bitmap, partSize, index, buildingSize))
        }
        return parts
    }

    private fun part(motion: BuildingMotion, motif: BuildingMotif, bitmap: Bitmap, size: CGSize, index: Int, building: CGSize): MotionPart {
        val w = building.width
        val h = building.height

        fun make(anchorX: Double = 0.5, anchorY: Double = 0.5, pose: (Double, MotionPose) -> Unit) =
            MotionPart(bitmap, size, anchorX, anchorY, pose)

        return when (motion) {
            BuildingMotion.none -> make { _, _ -> }

            BuildingMotion.spin -> make { t, p -> p.angle = t / 7.0 * TWO_PI }

            BuildingMotion.swing -> {
                // Hung from the apex of the A-frame, so the hull swings from its arms.
                val angle = Track(0.0, listOf(Seg(1.6, 0.5, Ease.inOut), Seg(1.6, -0.5, Ease.inOut)))
                make(0.5, 1.0) { t, p -> p.y = h * 0.36; p.angle = angle.at(t) }
            }

            BuildingMotion.rise -> {
                val low = -h * 0.20
                val high = h * 0.34
                val y = Track(low, listOf(Seg(3.4, high, Ease.easeOut), Seg(1.1), Seg(0.55, low, Ease.easeIn), Seg(1.4)))
                make { t, p -> p.y = y.at(t) }
            }

            BuildingMotion.bob -> {
                val scale = Track(1.0, listOf(Seg(1.1, 1.12, Ease.inOut), Seg(1.1, 0.94, Ease.inOut)))
                make { t, p -> p.scaleY = scale.at(t) }
            }

            BuildingMotion.pop -> {
                // Three moles, three holes, each on its own beat.
                val holes = listOf(Triple(-0.22, 0.02, 0.0), Triple(0.02, -0.08, 0.7), Triple(0.24, 0.06, 1.3))
                val hole = holes[index % holes.size]
                val rise = Track(0.05, listOf(Seg(0.22, 1.0, Ease.easeOut), Seg(0.5), Seg(0.18, 0.05, Ease.easeIn), Seg(1.3)), delay = hole.third)
                make(0.5, 0.0) { t, p -> p.x = w * hole.first; p.y = h * hole.second; p.scaleY = rise.at(t) }
            }

            BuildingMotion.launch -> launch(w, h, ::make)

            BuildingMotion.slide -> {
                val lanes = listOf(-0.30, -0.10, 0.10, 0.30)
                val starts = listOf(0.0, 0.85, 1.7, 2.45)
                val descents = listOf(1.5, 1.35, 1.6, 1.45)
                val slot = index % lanes.size
                val top = h * 0.30
                val bottom = -h * 0.30
                val y = Track(top, listOf(Seg(descents[slot], bottom, Ease.easeIn), Seg(0.5), Seg(0.01, top), Seg(1.1)), delay = starts[slot])
                make { t, p -> p.x = w * lanes[slot]; p.y = y.at(t) }
            }

            BuildingMotion.surf -> {
                // A rider runs the length of the pool, drops off the back of the wave, and another is up.
                val starts = listOf(0.0, 1.9)
                val slot = index % starts.size
                val entry = -w * 0.30
                val exit = w * 0.34
                val x = Track(entry, listOf(Seg(2.6, exit, Ease.inOut), Seg(0.25), Seg(0.01, entry), Seg(0.25), Seg(1.2)), delay = starts[slot])
                val alpha = Track(1.0, listOf(Seg(2.6), Seg(0.25, 0.0), Seg(0.01), Seg(0.25, 1.0), Seg(1.2)), delay = starts[slot])
                make { t, p -> p.x = x.at(t); p.y = h * (if (slot == 0) -0.06 else 0.10); p.alpha = alpha.at(t) }
            }

            BuildingMotion.hover -> {
                val y0 = -h * 0.22
                val y = Track(y0, listOf(Seg(1.9, y0 + h * 0.10, Ease.inOut), Seg(1.9, y0, Ease.inOut)))
                val alpha = Track(1.0, listOf(Seg(1.3, 0.55, Ease.inOut), Seg(1.3, 1.0, Ease.inOut)))
                make { t, p -> p.x = w * 0.30; p.y = y.at(t); p.alpha = alpha.at(t) }
            }

            BuildingMotion.circuit -> {
                val points = BuildingArtwork.motionPath(motif, building)
                val carLength = size.width
                // Each car starts far enough back to sit just behind the one in front, measured in length, not in points.
                val spacing = PathMotion.ringLength(points) / max(points.size, 1)
                val step = max(1, (carLength * 1.05 / max(spacing, 0.001)).roundToInt())
                val back = (index * step) % max(points.size, 1)
                val offset = (points.size - back) % max(points.size, 1)
                val ordered = points.drop(offset) + points.take(offset)
                val loop = PathMotion.Loop(ordered, circuitDuration(motif))
                make { t, p -> follow(loop, t, p) }
            }

            BuildingMotion.race -> {
                val lanes = listOf(0.0, 0.055, -0.045, 0.11)
                val lapTimes = listOf(4.1, 4.6, 3.8, 5.0)
                val startAngles = listOf(0.0, 1.9, 3.4, 4.9)
                val slot = index % lanes.size
                val track = BuildingArtwork.trackRect(building)
                val inset = lanes[slot] * min(w, h)
                val points = PathMotion.ovalPoints(
                    track.midX - w / 2, track.midY - h / 2,
                    max(1.0, track.width / 2 - inset), max(1.0, track.height / 2 - inset), startAngles[slot], 36,
                )
                val loop = PathMotion.Loop(points, lapTimes[slot])
                make { t, p -> follow(loop, t, p) }
            }

            BuildingMotion.bumper -> {
                val arenaW = w * 0.62
                val arenaH = h * 0.52
                val loops = listOf(
                    listOf(-0.5 to -0.5, 0.4 to 0.1, -0.2 to 0.5, 0.5 to -0.3),
                    listOf(0.5 to 0.4, -0.4 to -0.2, 0.1 to -0.5, -0.5 to 0.3),
                    listOf(-0.1 to 0.5, 0.5 to -0.4, -0.5 to 0.0, 0.2 to 0.4),
                    listOf(0.3 to -0.5, -0.5 to 0.4, 0.4 to 0.3, -0.3 to -0.3),
                    listOf(-0.4 to 0.2, 0.2 to -0.4, 0.5 to 0.2, -0.2 to -0.1),
                )
                val lapTimes = listOf(5.4, 6.2, 4.8, 6.8, 5.9)
                val slot = index % loops.size
                val points = loops[slot].map { CGPoint(it.first * arenaW, it.second * arenaH) }
                // A bumper car turns on the spot and then drives, rather than sweeping round the corner.
                val loop = PathMotion.Loop(points, lapTimes[slot], turnFraction = 0.25)
                // A short recoil on its own clock, out of step with the driving.
                val jolt = Track(1.0, listOf(Seg(1.4 + slot * 0.55), Seg(0.07, 1.18), Seg(0.13, 1.0)))
                make { t, p -> follow(loop, t, p); p.scaleX = jolt.at(t); p.scaleY = p.scaleX }
            }

            BuildingMotion.orbit -> {
                val steps = 48
                val chairs = BuildingArtwork.motionPartCount(BuildingMotif.swingChairs)
                val startAngle = index.toDouble() / chairs * TWO_PI
                val ring = BuildingArtStructures.swingRingRect(building)
                val points = PathMotion.ovalPoints(
                    ring.midX - w / 2, ring.midY - h / 2, max(1.0, ring.width / 2), max(1.0, ring.height / 2), startAngle, steps,
                )
                // The chairs are not steered: they hang from the crown and face the way they sit.
                val loop = PathMotion.Loop(points, ORBIT_LAP, headings = List(steps) { 0.0 })
                val swell = Track(1.0, listOf(Seg(ORBIT_LAP, 1.10, Ease.inOut), Seg(ORBIT_LAP, 0.94, Ease.inOut)))
                make(0.5, 1.0) { t, p -> follow(loop, t, p); p.angle = 0.0; p.scaleX = swell.at(t); p.scaleY = p.scaleX }
            }

            BuildingMotion.invert -> {
                // Swings further on every pass until it goes over the top twice, then settles.
                val over = 1.5 + 2 * TWO_PI
                val angle = Track(0.0, listOf(
                    Seg(1.4),
                    Seg(1.0, -0.5, Ease.inOut), Seg(1.2, 0.9, Ease.inOut), Seg(1.2, -1.5, Ease.inOut), Seg(1.1, 1.5, Ease.inOut),
                    Seg(2.3, over),
                    Seg(1.1, -1.2, Ease.inOut, from = 1.5), Seg(1.0, 0.8, Ease.inOut), Seg(0.9, -0.4, Ease.inOut), Seg(0.8, 0.0, Ease.inOut),
                    Seg(1.6),
                ))
                make(0.5, 1.0) { t, p -> p.y = h * 0.16; p.angle = angle.at(t) }
            }

            BuildingMotion.drift -> {
                // A raft is carried round the channel and never points anywhere in particular.
                val points = BuildingArtwork.motionPath(motif, building)
                val rafts = max(BuildingArtwork.motionPartCount(motif), 1)
                val back = if (points.isEmpty()) 0 else (index * points.size / rafts) % points.size
                val offset = if (points.isEmpty()) 0 else (points.size - back) % points.size
                val ordered = points.drop(offset) + points.take(offset)
                val loop = PathMotion.Loop(ordered, 13.0)
                val turns = listOf(TWO_PI to 6.5, -TWO_PI to 8.0, TWO_PI to 9.5)
                val spin = turns[index % turns.size]
                make { t, p ->
                    val pose = loop.pose(t)
                    p.x = pose.x; p.y = pose.y
                    p.angle = t / spin.second * spin.first
                }
            }

            BuildingMotion.zip -> zip(motif, building, index, ::make)
        }
    }

    private const val ORBIT_LAP = 4.4

    private fun circuitDuration(motif: BuildingMotif): Double = when (motif) {
        BuildingMotif.megaCoaster -> 8.5
        BuildingMotif.logFlume -> 11.0
        BuildingMotif.lanternCruise -> 16.0
        else -> 5.5
    }

    private fun follow(loop: PathMotion.Loop, time: Double, pose: MotionPose) {
        val at = loop.pose(time)
        pose.x = at.x
        pose.y = at.y
        pose.angle = at.heading
    }

    /** Winched down, held, then fired well clear of the masts, spinning, with a couple of diminishing bounces. */
    private fun launch(w: Double, h: Double, make: (Double, Double, (Double, MotionPose) -> Unit) -> MotionPart): MotionPart {
        val pad = -h * 0.18
        val charged = -h * 0.38
        val apex = h * 1.05
        val firstBounce = h * 0.34
        val secondBounce = h * 0.08

        val y = Track(pad, listOf(
            Seg(1.3), Seg(1.1, charged, Ease.inOut), Seg(0.45), Seg(0.45),
            Seg(0.42, apex, Ease.easeOut), Seg(0.10),
            Seg(0.52, secondBounce, Ease.easeIn), Seg(0.34, firstBounce, Ease.easeOut), Seg(0.38, pad, Ease.easeIn),
            Seg(0.22, secondBounce, Ease.easeOut), Seg(0.24, pad, Ease.easeIn), Seg(1.2),
        ))
        // A held breath at full stretch: three quick shudders before it fires.
        val a = w * 0.012
        val shudder = ArrayList<Seg>()
        shudder.add(Seg(2.4))
        repeat(3) { shudder.addAll(listOf(Seg(0.05, a), Seg(0.05, -a), Seg(0.05, 0.0))) }
        shudder.add(Seg(0.45 + 0.42 + 0.10 + 0.52 + 0.34 + 0.38 + 0.22 + 0.24 + 1.2))
        val x = Track(0.0, shudder)
        val spin = Track(0.0, listOf(Seg(3.3), Seg(0.42, TWO_PI), Seg(3.0, TWO_PI), Seg(0.0, 0.0)))
        return make(0.5, 0.5) { t, p -> p.x = x.at(t); p.y = y.at(t); p.angle = spin.at(t) }
    }

    /** One rider down the wire: away fast, braked into the landing, then back up to the tower for the next. */
    private fun zip(
        motif: BuildingMotif, building: CGSize, index: Int,
        make: (Double, Double, (Double, MotionPose) -> Unit) -> MotionPart,
    ): MotionPart {
        val cable = BuildingArtwork.motionPath(motif, building)
        val start = cable.firstOrNull() ?: CGPoint.zero
        val end = cable.lastOrNull() ?: CGPoint.zero
        val middle = CGPoint((start.x + end.x) / 2, (start.y + end.y) / 2)
        val bounce = CGPoint(end.x - (end.x - start.x) * 0.06, end.y - (end.y - start.y) * 0.06)
        val delay = 1.1 + index * 2.6

        fun axis(from: Double, mid: Double, rebound: Double, to: Double) = Track(from, listOf(
            Seg(0.01, from), Seg(0.9), Seg(0.85, mid, Ease.easeIn), Seg(0.95, to, Ease.easeOut),
            Seg(0.22, rebound), Seg(0.26, to), Seg(0.8), Seg(0.25), Seg(1.4),
        ), delay = delay)

        val x = axis(start.x, middle.x, bounce.x, end.x)
        val y = axis(start.y, middle.y, bounce.y, end.y)
        val alpha = Track(0.0, listOf(
            Seg(0.01, 0.0), Seg(0.20, 1.0), Seg(0.7), Seg(0.85), Seg(0.95), Seg(0.22), Seg(0.26),
            Seg(0.8), Seg(0.25, 0.0), Seg(1.4),
        ), delay = delay)
        return make(0.5, 1.0) { t, p -> p.x = x.at(t); p.y = y.at(t); p.alpha = alpha.at(t) }
    }
}
