package com.wickedstudios.wonderlot.render

import com.wickedstudios.wonderlot.gfx.CGPoint
import kotlin.math.atan2
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/**
 * Moving a sprite along a route and pointing it the right way. Shared by the
 * rides that have something driving round them and by the trains that run the
 * player's own track.
 *
 * Positions are a pure function of time, so a ride that is stopped simply
 * stops asking for a new time, and nothing has to be scheduled or cancelled.
 */
object PathMotion {

    /** Where a vehicle is on its route, and which way it faces. */
    class Pose(val x: Double, val y: Double, val heading: Double)

    /**
     * A closed loop of points driven at constant speed. Legs are timed by how
     * long they are, so a circuit sampled densely round a loop and sparsely
     * along a straight does not crawl through one and race the other. The
     * heading eases through the whole of each leg, as the original does.
     */
    class Loop(
        val points: List<CGPoint>,
        val duration: Double,
        private val headings: List<Double>? = null,
        /** How much of each leg is spent turning: a kart sweeps through all of it, a bumper car snaps round and then drives. */
        private val turnFraction: Double = 1.0,
    ) {
        private val lengths = DoubleArray(points.size)
        private val total: Double

        init {
            var sum = 0.0
            for (index in points.indices) {
                val next = points[(index + 1) % points.size]
                lengths[index] = max(hypot(next.x - points[index].x, next.y - points[index].y), 0.0001)
                sum += lengths[index]
            }
            total = sum
        }

        /** The pose at [time] seconds, with [phase] (0..1) as how far round it starts. */
        fun pose(time: Double, phase: Double = 0.0): Pose {
            if (points.size < 2) return Pose(points.firstOrNull()?.x ?: 0.0, points.firstOrNull()?.y ?: 0.0, 0.0)
            var fraction = (time / duration + phase) % 1.0
            if (fraction < 0) fraction += 1.0

            var distance = fraction * total
            var index = 0
            while (index < points.size - 1 && distance > lengths[index]) {
                distance -= lengths[index]
                index += 1
            }
            val u = (distance / lengths[index]).coerceIn(0.0, 1.0)
            val from = points[index]
            val to = points[(index + 1) % points.size]

            val previousIndex = (index - 1 + points.size) % points.size
            val previous = headings?.get(previousIndex) ?: heading(points[previousIndex], from)
            val current = headings?.get(index) ?: heading(from, to)
            val turned = min(1.0, u / min(1.0, max(0.05, turnFraction)))
            return Pose(from.x + (to.x - from.x) * u, from.y + (to.y - from.y) * u, easeAngle(previous, current, turned))
        }
    }

    fun heading(from: CGPoint, to: CGPoint): Double = atan2(to.y - from.y, to.x - from.x)

    /** The shortest way round from one angle to another. */
    fun easeAngle(from: Double, to: Double, u: Double): Double {
        var delta = (to - from) % (Math.PI * 2)
        if (delta > Math.PI) delta -= Math.PI * 2
        if (delta < -Math.PI) delta += Math.PI * 2
        return from + delta * u
    }

    /** Points around an oval, starting at [startAngle] so several vehicles can share one track. */
    fun ovalPoints(centreX: Double, centreY: Double, radiusX: Double, radiusY: Double, startAngle: Double, steps: Int): List<CGPoint> =
        (0 until steps).map { step ->
            val angle = startAngle + step.toDouble() / steps * Math.PI * 2
            CGPoint(centreX + Math.cos(angle) * radiusX, centreY + Math.sin(angle) * radiusY)
        }

    /**
     * Rounds the corners off a polyline by repeatedly cutting them, so a
     * vehicle curves through a bend instead of pivoting on the spot.
     */
    fun smoothed(points: List<CGPoint>, closed: Boolean, iterations: Int = 2): List<CGPoint> {
        if (points.size <= 2 || iterations <= 0) return points

        var current = points
        repeat(iterations) {
            val next = ArrayList<CGPoint>(current.size * 2)

            // An open line keeps its ends, or the train would stop short of the buffers.
            if (!closed) next.add(current[0])

            val lastIndex = if (closed) current.size - 1 else current.size - 2
            for (index in 0..lastIndex) {
                val from = current[index]
                val to = current[(index + 1) % current.size]
                next.add(CGPoint(from.x * 0.75 + to.x * 0.25, from.y * 0.75 + to.y * 0.25))
                next.add(CGPoint(from.x * 0.25 + to.x * 0.75, from.y * 0.25 + to.y * 0.75))
            }

            if (!closed) next.add(current[current.size - 1])
            current = next
        }
        return current
    }

    class Shuttle(val points: List<CGPoint>, val headings: List<Double>)

    /**
     * Positions for one vehicle of a train running out and back along a
     * dead-ended line. A rigid train keeps every car the same distance back
     * along the rails, and what changes is which end leads.
     */
    fun shuttleRun(line: List<CGPoint>, carIndex: Int, carSpacing: Double, consistLength: Double, samples: Int): Shuttle {
        if (line.size <= 1 || samples <= 1) return Shuttle(line, emptyList())

        val cumulative = ArrayList<Double>(line.size)
        cumulative.add(0.0)
        for (index in 1 until line.size) {
            cumulative.add(cumulative[index - 1] + hypot(line[index].x - line[index - 1].x, line[index].y - line[index - 1].y))
        }
        val total = cumulative.last()
        if (total <= 0) return Shuttle(line, emptyList())

        val head = min(consistLength, total * 0.5)

        val points = ArrayList<CGPoint>(samples)
        val headings = ArrayList<Double>(samples)

        for (sample in 0 until samples) {
            val phase = sample.toDouble() / samples
            // A triangle wave: out along the line, then back.
            val along = if (phase < 0.5) phase * 2 else (1 - phase) * 2
            val headDistance = head + (total - head) * along
            val distance = min(max(headDistance - carSpacing * carIndex, 0.0), total)
            points.add(pointAt(distance, line, cumulative))
            // Facing follows the rails, not the direction of travel.
            headings.add(tangent(distance, line, cumulative))
        }
        return Shuttle(points, headings)
    }

    private fun tangent(distance: Double, line: List<CGPoint>, cumulative: List<Double>): Double {
        if (line.size <= 1) return 0.0
        var index = 1
        while (index < cumulative.size - 1 && cumulative[index] < distance) index += 1
        return heading(line[index - 1], line[index])
    }

    private fun pointAt(distance: Double, line: List<CGPoint>, cumulative: List<Double>): CGPoint {
        val last = cumulative.lastOrNull() ?: return line[0]
        if (distance <= 0) return line[0]
        if (distance >= last) return line[line.size - 1]

        var index = 1
        while (index < cumulative.size && cumulative[index] < distance) index += 1
        val previous = cumulative[index - 1]
        val span = cumulative[index] - previous
        val t = if (span > 0) (distance - previous) / span else 0.0
        val from = line[index - 1]
        val to = line[index]
        return CGPoint(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t)
    }

    /** Length of a polyline, treated as a closed ring. */
    fun ringLength(points: List<CGPoint>): Double {
        if (points.size <= 1) return 0.0
        var total = 0.0
        for (index in points.indices) {
            val next = points[(index + 1) % points.size]
            total += hypot(next.x - points[index].x, next.y - points[index].y)
        }
        return total
    }
}
