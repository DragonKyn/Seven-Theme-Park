package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.CoasterElementMotif
import com.wickedstudios.wonderlot.ParkColour

/**
 * Draws the coaster elements, and hands out the exact line a train should
 * follow through one. The drawing and the path are the same list of points.
 * An element is drawn taller than the ground it occupies, so the sprite
 * reaches up out of its footprint and the track line runs along the bottom.
 */
object CoasterElementArtwork {

    // region The line

    /** The centreline of an element, in texture space, entering at the left edge and leaving at the right. */
    fun centreline(motif: CoasterElementMotif, size: CGSize, trackY: Double): List<CGPoint> {
        val line = size.height * trackY
        return when (motif) {
            CoasterElementMotif.airtimeHills -> hills(size, line)
            CoasterElementMotif.verticalLoop -> loop(size, line)
            CoasterElementMotif.corkscrew -> corkscrew(size, line)
            CoasterElementMotif.jump -> jump(size, line)
            CoasterElementMotif.helixTower -> helix(size, line)
        }
    }

    private fun hills(size: CGSize, line: Double): List<CGPoint> {
        val points = ArrayList<CGPoint>()
        points.add(CGPoint(0.0, line))
        val humps = 3
        val rise = min(line - size.height * 0.08, size.height * 0.44)
        for (index in 0 until humps) {
            val from = size.width * index / humps
            val to = size.width * (index + 1) / humps
            points += quad(CGPoint(from, line), CGPoint((from + to) / 2, line - rise * 2), CGPoint(to, line), 12)
        }
        return points
    }

    private fun loop(size: CGSize, line: Double): List<CGPoint> {
        val radius = min(size.width * 0.34, (line - size.height * 0.08) / 2)
        val centre = CGPoint(size.width / 2, line - radius)

        val points = ArrayList<CGPoint>()
        points.add(CGPoint(0.0, line))
        points.add(CGPoint(centre.x - radius * 0.9, line))
        // Entered and left at the foot, travelling the same way both times.
        val steps = 44
        for (step in 0..steps) {
            val angle = PI / 2 - step.toDouble() / steps * PI * 2
            points.add(CGPoint(centre.x + cos(angle) * radius, centre.y + sin(angle) * radius))
        }
        points.add(CGPoint(centre.x + radius * 0.9, line))
        points.add(CGPoint(size.width, line))
        return points
    }

    private fun corkscrew(size: CGSize, line: Double): List<CGPoint> {
        val radiusX = size.width * 0.12
        val radiusY = min(size.width * 0.12, (line - size.height * 0.10) / 2)
        val points = ArrayList<CGPoint>()
        points.add(CGPoint(0.0, line))

        for (index in 0 until 2) {
            val centre = CGPoint(size.width * (0.30 + 0.38 * index), line - radiusY)
            points.add(CGPoint(centre.x - radiusX, line))
            val steps = 30
            for (step in 0..steps) {
                val angle = PI - step.toDouble() / steps * PI * 2
                points.add(CGPoint(centre.x + cos(angle) * radiusX, centre.y + sin(angle) * radiusY))
            }
            points.add(CGPoint(centre.x + radiusX, line))
        }
        points.add(CGPoint(size.width, line))
        return points
    }

    private fun jump(size: CGSize, line: Double): List<CGPoint> {
        val lip = line - min(size.height * 0.30, line - size.height * 0.20)
        val points = ArrayList<CGPoint>()
        points.add(CGPoint(0.0, line))
        points += quad(CGPoint(size.width * 0.20, line), CGPoint(size.width * 0.30, line), CGPoint(size.width * 0.36, lip), 8)
        // Through the air. The train is unsupported here, which is the point.
        points += quad(CGPoint(size.width * 0.36, lip), CGPoint(size.width * 0.50, lip - size.height * 0.34),
            CGPoint(size.width * 0.64, lip), 14)
        points += quad(CGPoint(size.width * 0.64, lip), CGPoint(size.width * 0.70, line), CGPoint(size.width * 0.80, line), 8)
        points.add(CGPoint(size.width, line))
        return points
    }

    /** A spiral that stands above the track: a ramp up, two and a half turns climbing a tower, and a ramp down. */
    private fun helix(size: CGSize, line: Double): List<CGPoint> {
        val centre = CGPoint(size.width / 2, line - size.height * 0.34)
        val radiusX = size.width * 0.32
        val radiusY = size.height * 0.15
        val climb = size.height * 0.16

        val points = ArrayList<CGPoint>()
        points.add(CGPoint(0.0, line))
        val start = CGPoint(centre.x - radiusX, centre.y + radiusY)
        points += quad(CGPoint(size.width * 0.08, line), CGPoint(size.width * 0.20, line), start, 10)

        val steps = 84
        var last = start
        for (step in 0..steps) {
            val progress = step.toDouble() / steps
            val angle = PI + progress * PI * 2 * 2.5
            last = CGPoint(centre.x + cos(angle) * radiusX, centre.y + sin(angle) * radiusY - climb * progress)
            points.add(last)
        }

        points += quad(last, CGPoint(size.width * 0.84, line), CGPoint(size.width * 0.94, line), 10)
        points.add(CGPoint(size.width, line))
        return points
    }

    /** Samples a quadratic curve. */
    private fun quad(from: CGPoint, control: CGPoint, to: CGPoint, steps: Int): List<CGPoint> =
        (0..steps).map { step ->
            val t = step.toDouble() / steps
            val inverse = 1 - t
            val fromWeight = inverse * inverse
            val controlWeight = 2 * inverse * t
            val toWeight = t * t
            CGPoint(fromWeight * from.x + controlWeight * control.x + toWeight * to.x,
                fromWeight * from.y + controlWeight * control.y + toWeight * to.y)
        }

    // endregion

    // region The picture

    fun texture(motif: CoasterElementMotif, size: CGSize, trackY: Double, rail: ParkColour? = null): Bitmap =
        SpriteFactory.texture("element-${motif.name}-${size.width.toInt()}x${size.height.toInt()}-${(trackY * 100).toInt()}-${rail?.name ?: "stock"}",
            size) { _, drawSize -> draw(motif, drawSize, trackY, rail) }

    private val previews = HashMap<String, Bitmap>()

    /** The same image for the build menu, so what you pick is what you get. */
    fun previewImage(motif: CoasterElementMotif, size: CGSize, trackY: Double): Bitmap {
        val key = "${motif.name}-${size.width.toInt()}x${size.height.toInt()}"
        previews[key]?.let { return it }
        val image = SpriteFactory.render(size) { _, drawSize -> draw(motif, drawSize, trackY, null) }
        previews[key] = image
        return image
    }

    private fun draw(motif: CoasterElementMotif, size: CGSize, trackY: Double, rail: ParkColour?) {
        val points = centreline(motif, size, trackY)
        if (points.size <= 1) return

        val path = UIBezierPath()
        path.move(points[0])
        for (point in points.drop(1)) path.addLine(point)

        // Uprights first, so the track sits on top of them.
        val deck = size.height * trackY
        val legs = UIBezierPath()
        for ((index, point) in points.withIndex()) {
            if (index % 6 == 0 && point.y < deck - 4) {
                legs.move(point)
                legs.addLine(CGPoint(point.x, deck))
            }
        }
        // Thicker than a hairline: these are steel columns, not pencil marks.
        ParkPalette.coasterSupport.setStroke()
        legs.lineWidth = max(1.5, size.height * 0.030)
        legs.stroke()

        // A spine along the track line, which is what the columns stand on.
        val spine = UIBezierPath()
        spine.move(CGPoint(0.0, deck))
        spine.addLine(CGPoint(size.width, deck))
        ParkPalette.coasterSupport.setStroke()
        spine.lineWidth = max(1.5, size.height * 0.026)
        spine.stroke()

        // Ties, then rail. The same two-pass stroke the track tiles use.
        ParkPalette.coasterTie.setStroke()
        path.lineWidth = max(3, size.height * 0.115)
        path.lineCapStyle = LineCap.round
        path.lineJoinStyle = LineJoin.round
        path.stroke()

        ParkPalette.coasterRail(rail).setStroke()
        path.lineWidth = max(1.5, size.height * 0.050)
        path.stroke()

        if (motif == CoasterElementMotif.jump) markGap(size, trackY, rail)
    }

    /** Hazard marks under a jump, so the gap reads as deliberate. */
    private fun markGap(size: CGSize, trackY: Double, rail: ParkColour?) {
        val deck = size.height * trackY
        ParkPalette.coasterRail(rail).withAlphaComponent(0.45).setFill()
        for (index in 0 until 3) {
            val mark = CGRect(size.width * (0.42 + 0.07 * index), deck + size.height * 0.04, size.width * 0.035, size.height * 0.07)
            UIBezierPath(mark).fill()
        }
    }

    // endregion
}
