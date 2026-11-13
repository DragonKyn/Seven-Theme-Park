package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingMotif
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Artwork for the holiday event: eleven rides, eight decorations, and the dressing a ride wears after a makeover.
 * Drawn from paths like everything else, so there are still no image assets. Texture space runs y downward.
 */
object BuildingArtHoliday {

    private fun fill(path: UIBezierPath, colour: UIColor) = BuildingArtwork.fill(path, colour)
    private fun stroke(path: UIBezierPath, colour: UIColor, width: Double) = BuildingArtwork.stroke(path, colour, width)
    private fun withShadow(context: CGContext, body: () -> Unit) = BuildingArtwork.withShadow(context, body)
    private fun oval(x: Double, y: Double, w: Double, h: Double) = UIBezierPath(ovalIn = CGRect(x, y, w, h))
    private fun box(x: Double, y: Double, w: Double, h: Double) = UIBezierPath(rect = CGRect(x, y, w, h))
    private fun rounded(r: CGRect, corner: Double) = UIBezierPath(roundedRect = r, cornerRadius = corner)

    private val snowWhite = UIColor(0.97, 0.98, 1.0, 1.0)
    private val festiveGold = UIColor(1.0, 0.82, 0.28, 1.0)
    private val snowShade = UIColor(0.74, 0.82, 0.93, 1.0)
    private val bulbColours = listOf(
        UIColor(0.92, 0.23, 0.22, 1.0),
        UIColor(1.0, 0.78, 0.22, 1.0),
        UIColor(0.28, 0.78, 0.42, 1.0),
        UIColor(0.35, 0.72, 0.96, 1.0),
    )
    private fun colourOf(motifColour: com.wickedstudios.wonderlot.ParkColour) = ParkPalette.colour(motifColour)

    // region Shared pieces

    /** A five-pointed star, for tree tops and sparks. */
    fun starPath(centre: CGPoint, outer: Double, inner: Double, points: Int = 5): UIBezierPath {
        val path = UIBezierPath()
        val total = points * 2
        for (index in 0 until total) {
            val radius = if (index % 2 == 0) outer else inner
            val angle = -PI / 2 + index.toDouble() / total * PI * 2
            val point = CGPoint(centre.x + cos(angle) * radius, centre.y + sin(angle) * radius)
            if (index == 0) path.move(point) else path.addLine(point)
        }
        path.close()
        return path
    }

    /** A small burst of spokes, the shape of a firework going off. */
    fun burst(centre: CGPoint, radius: Double, spokes: Int, colour: UIColor, width: Double) {
        val path = UIBezierPath()
        for (index in 0 until spokes) {
            val angle = index.toDouble() / spokes * PI * 2
            path.move(CGPoint(centre.x + cos(angle) * radius * 0.35, centre.y + sin(angle) * radius * 0.35))
            path.addLine(CGPoint(centre.x + cos(angle) * radius, centre.y + sin(angle) * radius))
        }
        stroke(path, colour, width)
    }

    /** A drift of snow: a pale mound with a shadowed underside. */
    fun snowMound(rect: CGRect) {
        fill(UIBezierPath(ovalIn = rect.offsetBy(0, rect.height * 0.14)), snowShade)
        fill(UIBezierPath(ovalIn = rect), snowWhite)
    }

    /** A string of bulbs between two points, hanging in a shallow curve. */
    fun lightString(start: CGPoint, end: CGPoint, sag: Double, bulbs: Int, size: Double) {
        val wire = UIBezierPath()
        wire.move(start)
        wire.addQuadCurve(end, CGPoint((start.x + end.x) / 2, (start.y + end.y) / 2 + sag * 2))
        stroke(wire, UIColor(0.15, 0.85), max(0.8, size * 0.35))

        for (index in 0 until bulbs) {
            val t = (index + 0.5) / bulbs
            val x = start.x + (end.x - start.x) * t
            val y = start.y + (end.y - start.y) * t + sag * 4 * t * (1 - t)
            fill(oval(x - size / 2, y - size / 2, size, size), bulbColours[index % bulbColours.size])
        }
    }

    /** An oval stroked in alternating colours, like a barber's pole bent into a loop. */
    fun stripedOval(rect: CGRect, first: UIColor, second: UIColor, segments: Int, width: Double) {
        for (index in 0 until segments) {
            val a0 = index.toDouble() / segments * PI * 2
            val a1 = (index + 1).toDouble() / segments * PI * 2
            val piece = UIBezierPath()
            piece.move(CGPoint(rect.midX + cos(a0) * rect.width / 2, rect.midY + sin(a0) * rect.height / 2))
            piece.addLine(CGPoint(rect.midX + cos(a1) * rect.width / 2, rect.midY + sin(a1) * rect.height / 2))
            stroke(piece, if (index % 2 == 0) first else second, width)
        }
    }

    /** A candy cane standing on the ground at [base]. */
    fun candyCane(base: CGPoint, height: Double, red: UIColor) {
        val width = max(1.5, height * 0.14)
        val stem = UIBezierPath()
        stem.move(base)
        stem.addLine(CGPoint(base.x, base.y - height * 0.78))
        stem.addArc(CGPoint(base.x + height * 0.16, base.y - height * 0.78), height * 0.16, PI, 0.0, true)
        stroke(stem, snowWhite, width)
        for (index in 0 until 4) {
            val y = base.y - height * 0.10 - index * height * 0.20
            val band = UIBezierPath()
            band.move(CGPoint(base.x - width * 0.5, y))
            band.addLine(CGPoint(base.x + width * 0.5, y - height * 0.07))
            stroke(band, red, max(1.0, width * 0.6))
        }
        val hookStripe = UIBezierPath(arcCenter = CGPoint(base.x + height * 0.16, base.y - height * 0.78),
            radius = height * 0.16, startAngle = PI * 1.15, endAngle = PI * 1.55, clockwise = true)
        stroke(hookStripe, red, max(1.0, width * 0.8))
    }

    // endregion

    // region Makeover

    /**
     * What a ride wears after its holiday makeover: a swag of lights across the top, drifts of snow at its feet and a
     * red bow. The same dressing goes on every ride, drawn to the size of whatever it is put on.
     */
    fun drawHolidayDressing(context: CGContext, size: CGSize) {
        val unit = min(size.width, size.height)

        snowMound(CGRect(-size.width * 0.04, size.height * 0.86, size.width * 0.34, size.height * 0.15))
        snowMound(CGRect(size.width * 0.70, size.height * 0.88, size.width * 0.34, size.height * 0.14))
        snowMound(CGRect(size.width * 0.36, size.height * 0.94, size.width * 0.26, size.height * 0.08))

        val bulb = max(2.0, unit * 0.045)
        lightString(CGPoint(size.width * 0.08, size.height * 0.12), CGPoint(size.width * 0.50, size.height * 0.12),
            size.height * 0.05, 6, bulb)
        lightString(CGPoint(size.width * 0.50, size.height * 0.12), CGPoint(size.width * 0.92, size.height * 0.12),
            size.height * 0.05, 6, bulb)

        val bow = CGPoint(size.width * 0.14, size.height * 0.78)
        val loop = unit * 0.07
        val red = UIColor(0.86, 0.16, 0.20, 1.0)
        for (direction in listOf(-1.0, 1.0)) {
            fill(oval(bow.x + direction * loop * 0.9 - loop * 0.9, bow.y - loop * 0.6, loop * 1.8, loop * 1.2), red)
        }
        fill(oval(bow.x - loop * 0.4, bow.y - loop * 0.4, loop * 0.8, loop * 0.8), UIColor(0.62, 0.08, 0.12, 1.0))
        for (direction in listOf(-1.0, 1.0)) {
            val tail = UIBezierPath()
            tail.move(bow)
            tail.addLine(CGPoint(bow.x + direction * loop * 0.7, bow.y + loop * 2))
            stroke(tail, red, max(1.2, unit * 0.025))
        }

        burst(CGPoint(size.width * 0.86, size.height * 0.30), unit * 0.06, 4, festiveGold, max(0.8, unit * 0.014))
        burst(CGPoint(size.width * 0.20, size.height * 0.42), unit * 0.05, 4, snowWhite, max(0.8, unit * 0.014))
    }

    // endregion

    // region Rides: Christmas

    fun drawReindeerCarouselBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val inset = min(size.width, size.height) * 0.08
        val platform = CGRect(CGPoint.zero, size).insetBy(inset, inset)

        withShadow(context) { fill(UIBezierPath(ovalIn = platform), secondary) }
        stroke(UIBezierPath(ovalIn = platform), accent, max(1.5, size.width * 0.035))
        stroke(UIBezierPath(ovalIn = platform.insetBy(platform.width * 0.045, platform.width * 0.045)),
            primary, max(1.0, size.width * 0.018))

        val radius = platform.width * 0.34
        val centre = CGPoint(platform.midX, platform.midY)
        val brown = ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown)
        for (index in 0 until 8) {
            val angle = index.toDouble() / 8 * PI * 2
            val point = CGPoint(centre.x + cos(angle) * radius, centre.y + sin(angle) * radius)
            val body = platform.width * 0.10
            fill(oval(point.x - body / 2, point.y - body / 2, body, body), brown)
            val antlers = UIBezierPath()
            for (side in listOf(-1.0, 1.0)) {
                antlers.move(CGPoint(point.x + side * body * 0.2, point.y - body * 0.4))
                antlers.addLine(CGPoint(point.x + side * body * 0.7, point.y - body * 0.95))
                antlers.move(CGPoint(point.x + side * body * 0.45, point.y - body * 0.7))
                antlers.addLine(CGPoint(point.x + side * body * 0.95, point.y - body * 0.7))
            }
            stroke(antlers, ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.cream), max(0.8, body * 0.14))
            if (index % 2 == 0) {
                val nose = body * 0.28
                fill(oval(point.x - nose / 2, point.y + body * 0.05, nose, nose), primary)
            }
        }

        val pole = platform.width * 0.10
        fill(oval(centre.x - pole / 2, centre.y - pole / 2, pole, pole), accent)
    }

    /** The red and green canopy, with snow along its rim and a star at the peak. Square, so it spins about its middle. */
    fun drawReindeerCanopy(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val circle = CGRect(CGPoint.zero, size).insetBy(1, 1)
        val centre = CGPoint(circle.midX, circle.midY)
        val radius = circle.width / 2

        context.saveGState()
        UIBezierPath(ovalIn = circle).addClip()
        val segments = 12
        for (index in 0 until segments) {
            val start = index.toDouble() / segments * PI * 2
            val end = (index + 1).toDouble() / segments * PI * 2
            val wedge = UIBezierPath()
            wedge.move(centre)
            wedge.addArc(centre, radius, start, end, true)
            wedge.close()
            fill(wedge, if (index % 2 == 0) primary else accent)
        }
        context.restoreGState()

        stroke(UIBezierPath(ovalIn = circle.insetBy(radius * 0.06, radius * 0.06)), snowWhite, max(1.5, radius * 0.14))
        fill(starPath(centre, radius * 0.24, radius * 0.10), festiveGold)
    }

    fun drawSleighRideBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val track = BuildingArtwork.trackRect(size)

        val hill = track.insetBy(-size.width * 0.06, -size.height * 0.08)
        withShadow(context) { fill(UIBezierPath(ovalIn = hill), snowWhite) }
        fill(UIBezierPath(ovalIn = track.insetBy(track.width * 0.18, track.height * 0.18)), UIColor(0.88, 0.93, 0.99, 1.0))

        stroke(UIBezierPath(ovalIn = track), ParkPalette.coasterTie, max(2.5, size.height * 0.085))
        stroke(UIBezierPath(ovalIn = track), secondary, max(1.5, size.height * 0.04))

        val spots = listOf(Pair(0.36, 0.42), Pair(0.50, 0.55), Pair(0.62, 0.40), Pair(0.52, 0.30))
        for ((fx, fy) in spots) {
            val centre = CGPoint(size.width * fx, size.height * fy)
            val height = size.height * 0.16
            val fir = UIBezierPath()
            fir.move(CGPoint(centre.x, centre.y - height / 2))
            fir.addLine(CGPoint(centre.x + height * 0.32, centre.y + height / 2))
            fir.addLine(CGPoint(centre.x - height * 0.32, centre.y + height / 2))
            fir.close()
            fill(fir, ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.green))
            fill(oval(centre.x - height * 0.14, centre.y - height * 0.40, height * 0.28, height * 0.22), snowWhite)
        }

        val hut = CGRect(track.midX - size.width * 0.12, track.maxY - size.height * 0.05, size.width * 0.24, size.height * 0.15)
        fill(rounded(hut, hut.height * 0.25), primary)
        fill(rounded(CGRect(hut.minX - hut.width * 0.04, hut.minY - hut.height * 0.10, hut.width * 1.08, hut.height * 0.34),
            hut.height * 0.17), snowWhite)
    }

    /** One sleigh, facing right: a red body with a curled front, gold runners and two riders. */
    fun drawSleigh(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val runner = UIBezierPath()
        runner.move(CGPoint(size.width * 0.06, size.height * 0.88))
        runner.addLine(CGPoint(size.width * 0.80, size.height * 0.88))
        runner.addQuadCurve(CGPoint(size.width * 0.96, size.height * 0.62), CGPoint(size.width * 0.98, size.height * 0.90))
        stroke(runner, festiveGold, max(1.0, size.height * 0.10))

        val body = UIBezierPath()
        body.move(CGPoint(size.width * 0.10, size.height * 0.26))
        body.addLine(CGPoint(size.width * 0.78, size.height * 0.26))
        body.addQuadCurve(CGPoint(size.width * 0.94, size.height * 0.46), CGPoint(size.width * 0.90, size.height * 0.28))
        body.addLine(CGPoint(size.width * 0.82, size.height * 0.76))
        body.addLine(CGPoint(size.width * 0.12, size.height * 0.76))
        body.close()
        fill(body, primary)

        stroke(box(size.width * 0.12, size.height * 0.50, size.width * 0.70, 0.0), festiveGold, max(0.8, size.height * 0.07))

        val head = size.height * 0.32
        for (offset in listOf(0.26, 0.56)) {
            fill(oval(size.width * offset, size.height * 0.06, head, head),
                if (offset < 0.4) snowWhite else ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.cream))
        }
    }

    fun drawCandyCoasterBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val track = BuildingArtwork.trackRect(size)

        val columns = UIBezierPath()
        for (index in 0 until 10) {
            val angle = index.toDouble() / 10 * PI * 2
            val point = CGPoint(track.midX + cos(angle) * track.width / 2, track.midY + sin(angle) * track.height / 2)
            columns.move(point)
            columns.addLine(CGPoint(point.x, point.y + size.height * 0.07))
        }
        stroke(columns, ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.cream), max(1.5, size.width * 0.016))

        stroke(UIBezierPath(ovalIn = track), ParkPalette.coasterTie, max(2.5, size.height * 0.090))
        stripedOval(track, primary, secondary, 44, max(1.8, size.height * 0.050))

        val station = CGRect(track.midX - size.width * 0.13, track.maxY - size.height * 0.06, size.width * 0.26, size.height * 0.16)
        fill(rounded(station, station.height * 0.3), accent)
        fill(rounded(CGRect(station.minX, station.minY, station.width, station.height * 0.30), station.height * 0.15), primary)
    }

    fun drawSnowGlobeBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val inset = min(size.width, size.height) * 0.07
        val dome = CGRect(CGPoint.zero, size).insetBy(inset, inset)

        withShadow(context) { fill(UIBezierPath(ovalIn = dome), secondary.withAlphaComponent(0.92)) }
        fill(UIBezierPath(ovalIn = dome.insetBy(dome.width * 0.06, dome.width * 0.06)), primary.withAlphaComponent(0.30))
        stroke(UIBezierPath(ovalIn = dome), primary, max(1.5, size.width * 0.03))

        val flakes = listOf(Pair(0.30, 0.26), Pair(0.62, 0.22), Pair(0.74, 0.46), Pair(0.22, 0.58),
            Pair(0.46, 0.70), Pair(0.68, 0.74), Pair(0.38, 0.40))
        for ((fx, fy) in flakes) {
            val r = size.width * 0.018
            fill(oval(size.width * fx - r, size.height * fy - r, r * 2, r * 2), snowWhite)
        }

        val glint = UIBezierPath(arcCenter = CGPoint(dome.midX, dome.midY), radius = dome.width * 0.40,
            startAngle = PI * 1.1, endAngle = PI * 1.4, clockwise = true)
        stroke(glint, UIColor.white.withAlphaComponent(0.8), max(1.2, size.width * 0.03))

        val base = CGRect(size.width * 0.18, size.height * 0.86, size.width * 0.64, size.height * 0.10)
        fill(rounded(base, base.height * 0.4), accent)
        fill(box(base.minX + base.width * 0.1, base.midY - base.height * 0.08, base.width * 0.8, base.height * 0.16), snowWhite)
    }

    /** The spinning pods: four round cabins with a white lid each. */
    fun drawSnowGlobePods(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val centre = CGPoint(size.width / 2, size.height / 2)
        val pod = size.width * 0.26
        for (index in 0 until 4) {
            val angle = index.toDouble() / 4 * PI * 2 + PI / 4
            val point = CGPoint(centre.x + cos(angle) * size.width * 0.28, centre.y + sin(angle) * size.height * 0.28)
            val rect = CGRect(point.x - pod / 2, point.y - pod / 2, pod, pod)
            withShadow(context) { fill(UIBezierPath(ovalIn = rect), accent) }
            fill(UIBezierPath(ovalIn = rect.insetBy(pod * 0.18, pod * 0.18)), snowWhite)
            fill(oval(point.x - pod * 0.08, point.y - pod * 0.08, pod * 0.16, pod * 0.16), accent)
        }
        val hub = size.width * 0.16
        fill(oval(centre.x - hub / 2, centre.y - hub / 2, hub, hub), festiveGold)
    }

    fun drawPolarExpressBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val track = BuildingArtwork.trackRect(size)

        val ground = track.insetBy(-size.width * 0.05, -size.height * 0.07)
        fill(UIBezierPath(ovalIn = ground), snowWhite)

        stroke(UIBezierPath(ovalIn = track), ParkPalette.coasterTie, max(2.5, size.height * 0.085))
        stroke(UIBezierPath(ovalIn = track), accent, max(1.5, size.height * 0.036))

        val centre = CGPoint(size.width / 2, size.height * 0.50)
        val tall = size.height * 0.46
        fill(box(centre.x - tall * 0.05, centre.y + tall * 0.30, tall * 0.10, tall * 0.16),
            ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown))
        for (tier in 0 until 3) {
            val top = centre.y - tall / 2 + tier * tall * 0.20
            val width = tall * (0.34 + tier * 0.12)
            val path = UIBezierPath()
            path.move(CGPoint(centre.x, top))
            path.addLine(CGPoint(centre.x + width / 2, top + tall * 0.34))
            path.addLine(CGPoint(centre.x - width / 2, top + tall * 0.34))
            path.close()
            fill(path, secondary)
        }
        val baubles = listOf(Triple(-0.08, 0.02, 0), Triple(0.09, 0.10, 1), Triple(-0.15, 0.22, 2), Triple(0.14, 0.28, 0), Triple(0.0, 0.18, 1))
        for ((dx, dy, colour) in baubles) {
            val r = tall * 0.035
            fill(oval(centre.x + dx * tall - r, centre.y - tall / 2 + dy * tall * 1.4 - r, r * 2, r * 2), bulbColours[colour])
        }
        fill(starPath(CGPoint(centre.x, centre.y - tall / 2 - tall * 0.02), tall * 0.10, tall * 0.04), festiveGold)

        val station = CGRect(track.midX - size.width * 0.12, track.maxY - size.height * 0.05, size.width * 0.24, size.height * 0.14)
        fill(rounded(station, station.height * 0.3), primary)
        fill(rounded(CGRect(station.minX, station.minY - station.height * 0.06, station.width, station.height * 0.30),
            station.height * 0.15), snowWhite)
    }

    /** One piece of the train, nose to the right. The first is the engine with a funnel; the rest are carriages. */
    fun drawTrainCar(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, variant: Int) {
        val body = CGRect(CGPoint.zero, size).insetBy(0.5, size.height * 0.16)
        if (variant == 0) {
            fill(rounded(body, body.height * 0.34), primary)
            fill(box(body.maxX - body.width * 0.30, body.minY - size.height * 0.14, body.width * 0.16, size.height * 0.22),
                ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.charcoal))
            fill(oval(body.maxX - body.width * 0.55, body.minY - size.height * 0.10, size.width * 0.10, size.height * 0.16),
                UIColor.white.withAlphaComponent(0.85))
        } else {
            fill(rounded(body, body.height * 0.28), secondary)
            for (slot in 0 until 3) {
                fill(box(body.minX + body.width * (0.10 + 0.28 * slot), body.minY + body.height * 0.22,
                    body.width * 0.18, body.height * 0.42), festiveGold)
            }
        }
        fill(box(body.minX, body.maxY - size.height * 0.08, body.width, size.height * 0.08),
            ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.charcoal))
    }

    fun drawGingerbreadManorBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        snowMound(CGRect(size.width * 0.04, size.height * 0.70, size.width * 0.92, size.height * 0.26))

        val walls = CGRect(size.width * 0.14, size.height * 0.34, size.width * 0.72, size.height * 0.46)
        withShadow(context) { fill(rounded(walls, walls.height * 0.06), primary) }

        val roof = UIBezierPath()
        roof.move(CGPoint(size.width * 0.08, size.height * 0.38))
        roof.addLine(CGPoint(size.width * 0.50, size.height * 0.06))
        roof.addLine(CGPoint(size.width * 0.92, size.height * 0.38))
        roof.close()
        fill(roof, UIColor(0.36, 0.22, 0.14, 1.0))
        val icing = UIBezierPath()
        icing.move(CGPoint(size.width * 0.08, size.height * 0.38))
        icing.addLine(CGPoint(size.width * 0.50, size.height * 0.06))
        icing.addLine(CGPoint(size.width * 0.92, size.height * 0.38))
        stroke(icing, secondary, max(2.0, size.width * 0.04))

        for (index in 0 until 7) {
            val r = size.width * 0.045
            fill(oval(size.width * (0.12 + 0.105 * index) - r, size.height * 0.36 - r, r * 2, r * 2.4), secondary)
        }

        fill(rounded(CGRect(size.width * 0.43, size.height * 0.56, size.width * 0.14, size.height * 0.24), size.width * 0.04), accent)
        for (x in listOf(0.22, 0.66)) {
            val pane = CGRect(size.width * x, size.height * 0.46, size.width * 0.12, size.height * 0.12)
            fill(UIBezierPath(rect = pane), festiveGold)
            stroke(UIBezierPath(rect = pane), secondary, max(1.0, size.width * 0.012))
        }

        val gumdrops = listOf(bulbColours[0], bulbColours[2], bulbColours[1], bulbColours[3], bulbColours[0], bulbColours[2])
        for ((index, colour) in gumdrops.withIndex()) {
            val r = size.width * 0.028
            fill(oval(size.width * (0.18 + 0.12 * index) - r, size.height * 0.80 - r, r * 2, r * 2), colour)
        }

        for (x in listOf(0.06, 0.94)) {
            candyCane(CGPoint(size.width * x, size.height * 0.82), size.height * 0.22, accent)
        }
    }

    /** The little gingerbread man that hovers on the porch. */
    fun drawGingerbreadMan(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val tan = UIColor(0.74, 0.46, 0.22, 1.0)
        val limb = max(1.5, size.width * 0.20)
        val arms = UIBezierPath()
        arms.move(CGPoint(size.width * 0.10, size.height * 0.46))
        arms.addLine(CGPoint(size.width * 0.90, size.height * 0.46))
        stroke(arms, tan, limb)
        val legs = UIBezierPath()
        legs.move(CGPoint(size.width * 0.30, size.height * 0.96))
        legs.addLine(CGPoint(size.width * 0.50, size.height * 0.62))
        legs.addLine(CGPoint(size.width * 0.70, size.height * 0.96))
        stroke(legs, tan, limb)
        fill(oval(size.width * 0.24, size.height * 0.04, size.width * 0.52, size.height * 0.34), tan)
        fill(rounded(CGRect(size.width * 0.30, size.height * 0.40, size.width * 0.40, size.height * 0.30), size.width * 0.10), tan)
        for (x in listOf(0.40, 0.60)) fill(oval(size.width * x - 1, size.height * 0.15, 2.0, 2.0), snowWhite)
        for (y in listOf(0.48, 0.58)) fill(oval(size.width * 0.50 - 1.2, size.height * y, 2.4, 2.4), accent)
    }

    fun drawStarTopperBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val pad = CGRect(size.width * 0.10, size.height * 0.76, size.width * 0.80, size.height * 0.18)
        withShadow(context) { fill(rounded(pad, pad.height * 0.35), snowWhite) }

        val centre = size.width / 2
        for (tier in 0 until 3) {
            val top = size.height * (0.16 + 0.17 * tier)
            val width = size.width * (0.40 + 0.17 * tier)
            val path = UIBezierPath()
            path.move(CGPoint(centre, top))
            path.addLine(CGPoint(centre + width / 2, top + size.height * 0.28))
            path.addLine(CGPoint(centre - width / 2, top + size.height * 0.28))
            path.close()
            fill(path, primary)
            fill(oval(centre - width * 0.20, top + size.height * 0.20, width * 0.40, size.height * 0.06), snowWhite)
        }

        val column = CGRect(size.width * 0.46, size.height * 0.10, size.width * 0.08, size.height * 0.70)
        fill(rounded(column, column.width * 0.3), ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown))

        val baubles = listOf(Triple(0.36, 0.40, 0), Triple(0.62, 0.48, 1), Triple(0.30, 0.62, 2), Triple(0.70, 0.66, 3), Triple(0.50, 0.30, 0))
        for ((x, y, colour) in baubles) {
            val r = size.width * 0.026
            fill(oval(size.width * x - r, size.height * y - r, r * 2, r * 2), bulbColours[colour])
        }

        fill(starPath(CGPoint(centre, size.height * 0.10), size.width * 0.13, size.width * 0.055), accent)
    }

    // endregion

    // region Rides: New Year's

    fun drawCountdownWheelBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        BuildingArtwork.drawFerrisWheelBase(context, size, primary, secondary, accent)

        val hub = CGPoint(size.width / 2, size.height / 2)
        val radius = size.width * 0.13
        fill(oval(hub.x - radius, hub.y - radius, radius * 2, radius * 2), snowWhite)
        stroke(oval(hub.x - radius, hub.y - radius, radius * 2, radius * 2), secondary, max(1.5, size.width * 0.03))
        val hands = UIBezierPath()
        hands.move(hub)
        hands.addLine(CGPoint(hub.x, hub.y - radius * 0.75))
        stroke(hands, primary, max(1.0, size.width * 0.02))
        for (index in 0 until 12) {
            val angle = index.toDouble() / 12 * PI * 2
            val tick = UIBezierPath()
            tick.move(CGPoint(hub.x + cos(angle) * radius * 0.82, hub.y + sin(angle) * radius * 0.82))
            tick.addLine(CGPoint(hub.x + cos(angle) * radius * 0.94, hub.y + sin(angle) * radius * 0.94))
            stroke(tick, primary, 0.8)
        }
    }

    fun drawConfettiSwingBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        BuildingArtStructures.drawSwingChairsBase(context, size, primary, secondary, accent)

        val scraps = listOf(Triple(0.12, 0.84, 0), Triple(0.30, 0.90, 1), Triple(0.52, 0.88, 2), Triple(0.74, 0.92, 3),
            Triple(0.88, 0.80, 0), Triple(0.20, 0.20, 2), Triple(0.82, 0.18, 1), Triple(0.60, 0.10, 3), Triple(0.40, 0.14, 0))
        for ((x, y, colour) in scraps) {
            val paper = size.width * 0.04
            fill(box(size.width * x, size.height * y, paper, paper * 0.6), bulbColours[colour])
        }
        val tube = CGRect(size.width * 0.84, size.height * 0.62, size.width * 0.07, size.height * 0.18)
        fill(rounded(tube, tube.width * 0.3), accent)
        fill(box(tube.minX, tube.minY + tube.height * 0.35, tube.width, tube.height * 0.14), snowWhite)
    }

    fun drawBallDropBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val pad = CGRect(size.width * 0.10, size.height * 0.74, size.width * 0.80, size.height * 0.20)
        withShadow(context) { fill(rounded(pad, pad.height * 0.35), secondary) }
        val column = CGRect(size.width * 0.44, size.height * 0.04, size.width * 0.12, size.height * 0.74)
        fill(rounded(column, column.width * 0.3), primary)
        val bands = 6
        for (index in 0 until bands) {
            val y = column.minY + column.height * (index + 0.5) / bands
            fill(box(column.minX, y, column.width, max(1.0, size.height * 0.014)), accent)
        }
        fill(box(size.width * 0.495, 0.0, size.width * 0.01, size.height * 0.10), accent)
        val lights = 7
        for (index in 0 until lights) {
            fill(oval(pad.minX + pad.width * (index + 0.5) / lights - 1.5, pad.midY - 1.5, 3.0, 3.0), bulbColours[index % 4])
        }
    }

    /** The ball: white and faceted, with a gold glint. */
    fun drawDropBall(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val rect = CGRect(CGPoint.zero, size).insetBy(0.5, 0.5)
        fill(UIBezierPath(ovalIn = rect), secondary)
        stroke(UIBezierPath(ovalIn = rect), primary, max(1.0, size.width * 0.08))
        val facets = UIBezierPath()
        facets.move(CGPoint(rect.minX, rect.midY)); facets.addLine(CGPoint(rect.maxX, rect.midY))
        facets.move(CGPoint(rect.midX, rect.minY)); facets.addLine(CGPoint(rect.midX, rect.maxY))
        stroke(facets, primary.withAlphaComponent(0.6), max(0.8, size.width * 0.04))
        fill(starPath(CGPoint(rect.midX - rect.width * 0.12, rect.midY - rect.height * 0.14), rect.width * 0.14, rect.width * 0.05, 4), accent)
    }

    fun drawStarburstCoasterBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val track = BuildingArtwork.trackRect(size)

        val columns = UIBezierPath()
        for (index in 0 until 10) {
            val angle = index.toDouble() / 10 * PI * 2
            val point = CGPoint(track.midX + cos(angle) * track.width / 2, track.midY + sin(angle) * track.height / 2)
            columns.move(point)
            columns.addLine(CGPoint(point.x, point.y + size.height * 0.07))
        }
        stroke(columns, ParkPalette.coasterSupport, max(1.5, size.width * 0.014))

        stroke(UIBezierPath(ovalIn = track), ParkPalette.coasterTie, max(2.5, size.height * 0.090))
        stroke(UIBezierPath(ovalIn = track), secondary, max(1.5, size.height * 0.042))

        val spots = listOf(Triple(0.50, 0.10, 0), Triple(0.88, 0.50, 1), Triple(0.14, 0.46, 1), Triple(0.70, 0.16, 0), Triple(0.30, 0.14, 1))
        for ((x, y, kind) in spots) {
            burst(CGPoint(size.width * x, size.height * y), size.width * 0.07, 8, if (kind == 0) accent else festiveGold, max(1.0, size.width * 0.012))
            fill(starPath(CGPoint(size.width * x, size.height * y), size.width * 0.022, size.width * 0.009), snowWhite)
        }

        val station = CGRect(track.midX - size.width * 0.13, track.maxY - size.height * 0.06, size.width * 0.26, size.height * 0.16)
        fill(rounded(station, station.height * 0.3), primary)
        fill(starPath(CGPoint(station.midX, station.midY), station.height * 0.30, station.height * 0.12), accent)
    }

    // endregion

    // region Decorations

    fun drawXmasTree(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        fill(box(size.width * 0.44, size.height * 0.80, size.width * 0.12, size.height * 0.16),
            ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown))
        withShadow(context) {
            for (tier in 0 until 3) {
                val top = size.height * (0.12 + 0.20 * tier)
                val width = size.width * (0.42 + 0.18 * tier)
                val path = UIBezierPath()
                path.move(CGPoint(size.width / 2, top))
                path.addLine(CGPoint(size.width / 2 + width / 2, top + size.height * 0.34))
                path.addLine(CGPoint(size.width / 2 - width / 2, top + size.height * 0.34))
                path.close()
                fill(path, primary)
            }
        }
        for (tier in 0 until 3) {
            val top = size.height * (0.12 + 0.20 * tier)
            fill(oval(size.width * 0.40, top + size.height * 0.07, size.width * 0.20, size.height * 0.05), snowWhite)
        }
        val sets = listOf(listOf(0, 1, 2, 0, 1), listOf(1, 3, 1, 3, 0), listOf(2, 0, 3, 2, 1))
        val positions = listOf(Pair(0.42, 0.34), Pair(0.60, 0.46), Pair(0.36, 0.56), Pair(0.64, 0.66), Pair(0.50, 0.78))
        for ((index, position) in positions.withIndex()) {
            val r = size.width * 0.04
            fill(oval(size.width * position.first - r, size.height * position.second - r, r * 2, r * 2),
                bulbColours[sets[variant % 3][index]])
        }
        fill(starPath(CGPoint(size.width / 2, size.height * 0.10), size.width * 0.12, size.width * 0.05), accent)
    }

    fun drawSnowman(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        fill(oval(size.width * 0.12, size.height * 0.86, size.width * 0.76, size.height * 0.10), snowShade)
        withShadow(context) {
            fill(oval(size.width * 0.16, size.height * 0.50, size.width * 0.68, size.height * 0.42), primary)
            fill(oval(size.width * 0.24, size.height * 0.26, size.width * 0.52, size.height * 0.34), primary)
        }
        fill(oval(size.width * 0.30, size.height * 0.06, size.width * 0.40, size.height * 0.30), primary)
        val charcoal = ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.charcoal)
        fill(box(size.width * 0.34, size.height * 0.00, size.width * 0.32, size.height * 0.10), charcoal)
        fill(box(size.width * 0.28, size.height * 0.09, size.width * 0.44, size.height * 0.03), charcoal)
        for (x in listOf(0.42, 0.58)) fill(oval(size.width * x - 1, size.height * 0.17, 2.2, 2.2), charcoal)
        val nose = UIBezierPath()
        nose.move(CGPoint(size.width * 0.50, size.height * 0.21))
        nose.addLine(CGPoint(size.width * 0.68, size.height * 0.24))
        nose.addLine(CGPoint(size.width * 0.50, size.height * 0.26))
        nose.close()
        fill(nose, accent)
        fill(rounded(CGRect(size.width * 0.30, size.height * 0.31, size.width * 0.40, size.height * 0.06), size.height * 0.03), secondary)
        fill(box(size.width * 0.60, size.height * 0.34, size.width * 0.07, size.height * 0.16), secondary)
        for (y in listOf(0.50, 0.62, 0.74)) fill(oval(size.width * 0.50 - 1.2, size.height * y, 2.4, 2.4), charcoal)
    }

    fun drawWreathArch(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        for (x in listOf(0.14, 0.80)) {
            fill(box(size.width * x, size.height * 0.30, size.width * 0.06, size.height * 0.66),
                ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown))
            for (step in 0 until 4) {
                val y = size.height * (0.40 + 0.14 * step)
                val wrap = UIBezierPath()
                wrap.move(CGPoint(size.width * x - 1, y))
                wrap.addLine(CGPoint(size.width * x + size.width * 0.07, y + size.height * 0.06))
                stroke(wrap, primary, max(1.5, size.width * 0.035))
            }
        }
        val ring = CGRect(size.width * 0.10, size.height * 0.02, size.width * 0.80, size.height * 0.42)
        stroke(UIBezierPath(ovalIn = ring), primary, max(2.5, size.height * 0.08))
        for (index in 0 until 10) {
            val angle = index.toDouble() / 10 * PI * 2
            val r = size.width * 0.022
            fill(oval(ring.midX + cos(angle) * ring.width / 2 - r, ring.midY + sin(angle) * ring.height / 2 - r, r * 2, r * 2),
                if (index % 2 == 0) secondary else snowWhite)
        }
        val bow = CGPoint(size.width / 2, size.height * 0.45)
        for (side in listOf(-1.0, 1.0)) {
            fill(oval(bow.x + side * size.width * 0.07 - size.width * 0.07, bow.y - size.height * 0.04, size.width * 0.14, size.height * 0.09), secondary)
        }
        fill(oval(bow.x - size.width * 0.03, bow.y - size.height * 0.02, size.width * 0.06, size.height * 0.06), accent)
    }

    fun drawGiftStack(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        fun giftBox(rect: CGRect, wrap: UIColor, ribbon: UIColor) {
            withShadow(context) { fill(rounded(rect, rect.height * 0.06), wrap) }
            fill(box(rect.midX - rect.width * 0.07, rect.minY, rect.width * 0.14, rect.height), ribbon)
            fill(box(rect.minX, rect.midY - rect.height * 0.07, rect.width, rect.height * 0.14), ribbon)
        }
        giftBox(CGRect(size.width * 0.08, size.height * 0.56, size.width * 0.58, size.height * 0.38), primary, accent)
        giftBox(CGRect(size.width * 0.52, size.height * 0.66, size.width * 0.40, size.height * 0.28), secondary, snowWhite)
        giftBox(CGRect(size.width * 0.20, size.height * 0.30, size.width * 0.40, size.height * 0.28), accent, primary)
        val bow = CGPoint(size.width * 0.40, size.height * 0.28)
        for (side in listOf(-1.0, 1.0)) {
            fill(oval(bow.x + side * size.width * 0.06 - size.width * 0.06, bow.y - size.height * 0.06, size.width * 0.12, size.height * 0.10), primary)
        }
        fill(oval(bow.x - size.width * 0.025, bow.y - size.height * 0.03, size.width * 0.05, size.height * 0.06), secondary)
    }

    fun drawLightPole(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val pole = CGRect(size.width * 0.46, size.height * 0.10, size.width * 0.08, size.height * 0.84)
        withShadow(context) { fill(rounded(pole, pole.width * 0.3), primary) }
        val top = CGPoint(size.width * 0.50, size.height * 0.14)
        val bulb = max(2.0, size.width * 0.07)
        lightString(top, CGPoint(size.width * 0.04, size.height * 0.46), size.height * 0.08, 5, bulb)
        lightString(top, CGPoint(size.width * 0.96, size.height * 0.46), size.height * 0.08, 5, bulb)
        lightString(CGPoint(size.width * 0.04, size.height * 0.46), CGPoint(size.width * 0.50, size.height * 0.78), size.height * 0.08, 5, bulb)
        lightString(CGPoint(size.width * 0.96, size.height * 0.46), CGPoint(size.width * 0.50, size.height * 0.78), size.height * 0.08, 5, bulb)
        fill(starPath(CGPoint(size.width / 2, size.height * 0.07), size.width * 0.10, size.width * 0.04), secondary)
    }

    fun drawCandyCanePost(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        fill(oval(size.width * 0.16, size.height * 0.88, size.width * 0.68, size.height * 0.10), snowShade)
        candyCane(CGPoint(size.width * 0.36, size.height * 0.94), size.height * 0.90, primary)
        val bow = CGPoint(size.width * 0.36, size.height * 0.44)
        for (side in listOf(-1.0, 1.0)) {
            fill(oval(bow.x + side * size.width * 0.07 - size.width * 0.07, bow.y - size.height * 0.04, size.width * 0.14, size.height * 0.08), accent)
        }
    }

    fun drawFireworkStand(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val rack = CGRect(size.width * 0.06, size.height * 0.70, size.width * 0.88, size.height * 0.20)
        withShadow(context) { fill(rounded(rack, rack.height * 0.2), ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown)) }
        val colours = listOf(primary, accent, secondary, bulbColours[0], bulbColours[2], accent)
        for (index in 0 until 6) {
            val x = size.width * (0.14 + 0.14 * index)
            val tipX = x + size.width * 0.02 * (index - 2)
            val rocket = UIBezierPath()
            rocket.move(CGPoint(x, size.height * 0.76))
            rocket.addLine(CGPoint(tipX, size.height * 0.34))
            stroke(rocket, colours[index % colours.size], max(2.0, size.width * 0.04))
            val head = UIBezierPath()
            head.move(CGPoint(tipX - size.width * 0.03, size.height * 0.36))
            head.addLine(CGPoint(tipX, size.height * 0.22))
            head.addLine(CGPoint(tipX + size.width * 0.03, size.height * 0.36))
            head.close()
            fill(head, snowWhite)
        }
        burst(CGPoint(size.width * 0.28, size.height * 0.12), size.width * 0.12, 8, accent, max(1.0, size.width * 0.012))
        burst(CGPoint(size.width * 0.72, size.height * 0.14), size.width * 0.10, 8, festiveGold, max(1.0, size.width * 0.012))
    }

    fun drawCountdownClock(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val tower = CGRect(size.width * 0.28, size.height * 0.30, size.width * 0.44, size.height * 0.64)
        withShadow(context) { fill(rounded(tower, tower.width * 0.1), primary) }
        fill(box(tower.minX - size.width * 0.04, tower.maxY - size.height * 0.05, tower.width + size.width * 0.08, size.height * 0.07), secondary)
        val roof = UIBezierPath()
        roof.move(CGPoint(size.width * 0.50, size.height * 0.04))
        roof.addLine(CGPoint(size.width * 0.76, size.height * 0.30))
        roof.addLine(CGPoint(size.width * 0.24, size.height * 0.30))
        roof.close()
        fill(roof, secondary)
        fill(starPath(CGPoint(size.width / 2, size.height * 0.05), size.width * 0.09, size.width * 0.04), accent)
        val face = CGRect(size.width * 0.34, size.height * 0.38, size.width * 0.32, size.width * 0.32)
        fill(UIBezierPath(ovalIn = face), snowWhite)
        stroke(UIBezierPath(ovalIn = face), secondary, max(1.2, size.width * 0.03))
        val hands = UIBezierPath()
        hands.move(CGPoint(face.midX, face.midY)); hands.addLine(CGPoint(face.midX, face.minY + face.height * 0.14))
        hands.move(CGPoint(face.midX, face.midY)); hands.addLine(CGPoint(face.midX - face.width * 0.10, face.minY + face.height * 0.20))
        stroke(hands, primary, max(1.0, size.width * 0.025))
        for (index in 0 until 4) {
            fill(oval(size.width * 0.48, size.height * (0.64 + 0.06 * index), size.width * 0.04, size.width * 0.04), bulbColours[index % 4])
        }
    }

    // endregion

    // region Skating rink and the two seasonal stalls

    fun drawSkatingRinkBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val sheet = CGRect(CGPoint.zero, size).insetBy(size.width * 0.08, size.height * 0.10)
        // Boards round the edge, with snow banked against them.
        withShadow(context) { fill(rounded(sheet, min(sheet.width, sheet.height) * 0.40), secondary) }
        stroke(rounded(sheet, min(sheet.width, sheet.height) * 0.40), accent, max(2.0, size.height * 0.045))
        val ice = sheet.insetBy(sheet.width * 0.04, sheet.height * 0.06)
        fill(rounded(ice, min(ice.width, ice.height) * 0.38), primary.withAlphaComponent(0.55).blended(snowWhite, 0.5))
        // Scratches in the ice: a few long curves.
        val marks = UIBezierPath()
        marks.move(CGPoint(ice.minX + ice.width * 0.15, ice.midY - ice.height * 0.18))
        marks.addQuadCurve(CGPoint(ice.maxX - ice.width * 0.15, ice.midY - ice.height * 0.10), CGPoint(ice.midX, ice.minY + ice.height * 0.10))
        marks.move(CGPoint(ice.minX + ice.width * 0.20, ice.midY + ice.height * 0.20))
        marks.addQuadCurve(CGPoint(ice.maxX - ice.width * 0.10, ice.midY + ice.height * 0.16), CGPoint(ice.midX, ice.maxY - ice.height * 0.04))
        stroke(marks, UIColor.white.withAlphaComponent(0.85), max(0.8, size.height * 0.012))
        // The centre mark and snow banked at the corners.
        stroke(oval(ice.midX - ice.width * 0.08, ice.midY - ice.height * 0.12, ice.width * 0.16, ice.height * 0.24), accent.withAlphaComponent(0.7), max(1.0, size.height * 0.014))
        snowMound(CGRect(size.width * 0.02, size.height * 0.74, size.width * 0.20, size.height * 0.20))
        snowMound(CGRect(size.width * 0.78, size.height * 0.04, size.width * 0.20, size.height * 0.18))
        // A string of bulbs along the near board.
        lightString(CGPoint(size.width * 0.14, size.height * 0.94), CGPoint(size.width * 0.86, size.height * 0.94), size.height * 0.03, 9, max(2.0, size.width * 0.022))
    }

    /** One skater, in a coloured jacket and a bobble hat; the variant picks the colours. */
    fun drawSkater(context: CGContext, size: CGSize, variant: Int) {
        val coat = bulbColours[variant % bulbColours.size]
        val hat = bulbColours[(variant + 2) % bulbColours.size]
        val skin = UIColor(0.93, 0.76, 0.60, 1.0)
        val trousers = UIColor(0.20, 0.22, 0.30, 1.0)
        fill(box(size.width * 0.34, size.height * 0.62, size.width * 0.14, size.height * 0.34), trousers)
        fill(box(size.width * 0.54, size.height * 0.62, size.width * 0.14, size.height * 0.34), trousers)
        fill(rounded(CGRect(size.width * 0.26, size.height * 0.30, size.width * 0.52, size.height * 0.40), size.width * 0.12), coat)
        val arms = UIBezierPath()
        arms.move(CGPoint(size.width * 0.20, size.height * 0.46)); arms.addLine(CGPoint(size.width * 0.84, size.height * 0.40))
        stroke(arms, coat, max(1.2, size.width * 0.12))
        fill(oval(size.width * 0.34, size.height * 0.04, size.width * 0.36, size.height * 0.30), skin)
        fill(oval(size.width * 0.32, size.height * 0.00, size.width * 0.40, size.height * 0.18), hat)
        fill(oval(size.width * 0.46, size.height * -0.04, size.width * 0.12, size.height * 0.12), snowWhite)
    }

    fun drawHotCocoaStand(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        snowMound(CGRect(size.width * 0.04, size.height * 0.80, size.width * 0.92, size.height * 0.18))
        val counter = CGRect(size.width * 0.12, size.height * 0.40, size.width * 0.76, size.height * 0.46)
        withShadow(context) { fill(rounded(counter, size.width * 0.04), primary) }
        // Striped awning with a snowy top.
        val stripes = 6
        for (index in 0 until stripes) {
            val x = counter.minX - size.width * 0.04 + (counter.width + size.width * 0.08) * index / stripes
            fill(box(x, size.height * 0.20, (counter.width + size.width * 0.08) / stripes + 0.5, size.height * 0.24), if (index % 2 == 0) accent else snowWhite)
        }
        fill(rounded(CGRect(counter.minX - size.width * 0.05, size.height * 0.12, counter.width + size.width * 0.10, size.height * 0.12), size.height * 0.06), snowWhite)
        // A big cup on the front with steam and marshmallows.
        val cup = CGRect(size.width * 0.38, size.height * 0.54, size.width * 0.24, size.height * 0.26)
        val body = UIBezierPath()
        body.move(CGPoint(cup.minX, cup.minY)); body.addLine(CGPoint(cup.maxX, cup.minY))
        body.addLine(CGPoint(cup.maxX - cup.width * 0.14, cup.maxY)); body.addLine(CGPoint(cup.minX + cup.width * 0.14, cup.maxY)); body.close()
        fill(body, secondary)
        fill(box(cup.minX, cup.minY, cup.width, cup.height * 0.22), UIColor(0.36, 0.20, 0.12, 1.0))
        for (dx in listOf(0.22, 0.52, 0.76)) fill(oval(cup.minX + cup.width * dx - 3, cup.minY - 3, 6.0, 5.0), snowWhite)
        for (dx in listOf(0.30, 0.55, 0.74)) {
            val steam = UIBezierPath()
            steam.move(CGPoint(cup.minX + cup.width * dx, cup.minY - size.height * 0.04))
            steam.addQuadCurve(CGPoint(cup.minX + cup.width * dx, cup.minY - size.height * 0.16), CGPoint(cup.minX + cup.width * (dx + 0.18), cup.minY - size.height * 0.10))
            stroke(steam, UIColor.white.withAlphaComponent(0.75), max(0.8, size.width * 0.012))
        }
        // Two mugs on the shelf and a bulb string.
        for (x in listOf(0.18, 0.72)) fill(rounded(CGRect(size.width * x, size.height * 0.60, size.width * 0.10, size.height * 0.12), 2.0), accent)
        lightString(CGPoint(size.width * 0.12, size.height * 0.16), CGPoint(size.width * 0.88, size.height * 0.16), size.height * 0.04, 8, max(2.0, size.width * 0.026))
    }

    fun drawCandyStand(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        snowMound(CGRect(size.width * 0.04, size.height * 0.80, size.width * 0.92, size.height * 0.18))
        val counter = CGRect(size.width * 0.12, size.height * 0.42, size.width * 0.76, size.height * 0.44)
        withShadow(context) { fill(rounded(counter, size.width * 0.04), accent) }
        // A big striped awning in red and white, with a scalloped edge.
        val stripes = 8
        val span = counter.width + size.width * 0.10
        for (index in 0 until stripes) {
            val x = counter.minX - size.width * 0.05 + span * index / stripes
            val colour = if (index % 2 == 0) primary else secondary
            fill(box(x, size.height * 0.18, span / stripes + 0.5, size.height * 0.22), colour)
            fill(oval(x, size.height * 0.34, span / stripes + 0.5, size.height * 0.10), colour)
        }
        // Jars of sweets along the counter, a candy cane either side, and a lollipop sign on top.
        val jars = listOf(primary, bulbColours[1], accent, bulbColours[3])
        for ((index, colour) in jars.withIndex()) {
            val x = counter.minX + counter.width * (0.08 + 0.22 * index)
            fill(rounded(CGRect(x, size.height * 0.52, size.width * 0.14, size.height * 0.20), size.width * 0.03), snowWhite.withAlphaComponent(0.85))
            for (dot in 0 until 4) fill(oval(x + size.width * (0.02 + 0.03 * (dot % 3)), size.height * (0.60 + 0.04 * (dot / 3)), 4.0, 4.0), colour)
        }
        candyCane(CGPoint(size.width * 0.06, size.height * 0.84), size.height * 0.34, primary)
        candyCane(CGPoint(size.width * 0.94, size.height * 0.84), size.height * 0.34, primary)
        val stick = UIBezierPath(); stick.move(CGPoint(size.width * 0.50, size.height * 0.20)); stick.addLine(CGPoint(size.width * 0.50, size.height * 0.08))
        stroke(stick, snowWhite, max(1.2, size.width * 0.02))
        stripedOval(CGRect(size.width * 0.44, size.height * -0.02, size.width * 0.12, size.height * 0.14), primary, snowWhite, 14, max(1.0, size.width * 0.02))
    }

    // endregion

    // region Candy canes, lights, the snow family and the snow cone cart

    fun drawCandyCaneFence(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        fill(oval(size.width * 0.02, size.height * 0.84, size.width * 0.96, size.height * 0.12), snowShade)
        // A striped rail between the canes.
        val rail = CGRect(size.width * 0.04, size.height * 0.52, size.width * 0.92, size.height * 0.10)
        withShadow(context) { fill(rounded(rail, rail.height * 0.5), snowWhite) }
        for (index in 0 until 12) {
            if (index % 2 == 0) fill(box(rail.minX + rail.width * index / 12, rail.minY, rail.width / 12 + 0.5, rail.height), primary)
        }
        // Three canes, each with a green bow where the hook meets the stem.
        for (x in listOf(0.18, 0.50, 0.82)) {
            candyCane(CGPoint(size.width * x, size.height * 0.92), size.height * 0.80, primary)
            val bow = CGPoint(size.width * x, size.height * 0.40)
            for (side in listOf(-1.0, 1.0)) fill(oval(bow.x + side * size.width * 0.045 - size.width * 0.045, bow.y - size.height * 0.03, size.width * 0.09, size.height * 0.06), accent)
        }
        snowMound(CGRect(size.width * 0.00, size.height * 0.86, size.width * 0.28, size.height * 0.12))
        snowMound(CGRect(size.width * 0.72, size.height * 0.86, size.width * 0.28, size.height * 0.12))
    }

    fun drawHolidayLights(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        fill(oval(size.width * 0.04, size.height * 0.84, size.width * 0.92, size.height * 0.12), snowShade)
        // Two stakes.
        val wood = ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown)
        for (x in listOf(0.10, 0.88)) {
            fill(rounded(CGRect(size.width * x, size.height * 0.30, size.width * 0.04, size.height * 0.60), 1.5), wood)
            fill(oval(size.width * (x - 0.01), size.height * 0.26, size.width * 0.06, size.width * 0.06), festiveGold)
        }
        // Three loops of bulbs, each with a soft glow behind it.
        val rows = listOf(0.34, 0.52, 0.70)
        for ((row, y) in rows.withIndex()) {
            val start = CGPoint(size.width * 0.12, size.height * y)
            val end = CGPoint(size.width * 0.90, size.height * y)
            for (b in 0 until 8) {
                val t = (b + 0.5) / 8
                val bx = start.x + (end.x - start.x) * t
                val by = start.y + (end.y - start.y) * t + size.height * 0.14 * t * (1 - t)
                fill(oval(bx - size.width * 0.045, by - size.width * 0.045, size.width * 0.09, size.width * 0.09), bulbColours[(b + row) % 4].withAlphaComponent(0.28))
            }
            lightString(start, end, size.height * 0.07, 8, max(2.5, size.width * 0.045))
        }
    }

    private fun snowmanAt(centreX: Double, baseY: Double, height: Double, scarf: UIColor, nose: UIColor, hat: Boolean) {
        val w = height * 0.62
        fill(oval(centreX - w * 0.60, baseY - height * 0.08, w * 1.2, height * 0.10), snowShade)
        fill(oval(centreX - w * 0.50, baseY - height * 0.50, w, height * 0.50), snowWhite)
        fill(oval(centreX - w * 0.36, baseY - height * 0.80, w * 0.72, height * 0.40), snowWhite)
        val head = w * 0.54
        val headTop = baseY - height * 1.00
        fill(oval(centreX - head / 2, headTop, head, head), snowWhite)
        val charcoal = ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.charcoal)
        if (hat) {
            fill(box(centreX - head * 0.30, headTop - head * 0.34, head * 0.60, head * 0.40), charcoal)
            fill(box(centreX - head * 0.48, headTop + head * 0.02, head * 0.96, head * 0.08), charcoal)
        }
        for (dx in listOf(-0.16, 0.16)) fill(oval(centreX + head * dx - 1, headTop + head * 0.34, 2.2, 2.2), charcoal)
        val carrot = UIBezierPath()
        carrot.move(CGPoint(centreX, headTop + head * 0.46)); carrot.addLine(CGPoint(centreX + head * 0.42, headTop + head * 0.54)); carrot.addLine(CGPoint(centreX, headTop + head * 0.60)); carrot.close()
        fill(carrot, nose)
        fill(rounded(CGRect(centreX - head * 0.42, headTop + head * 0.82, head * 0.84, head * 0.16), head * 0.08), scarf)
        fill(box(centreX + head * 0.18, headTop + head * 0.90, head * 0.18, head * 0.52), scarf)
        for (dy in listOf(0.40, 0.62)) fill(oval(centreX - 1.2, baseY - height * dy, 2.4, 2.4), charcoal)
    }

    fun drawSnowFamily(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        withShadow(context) {
            snowmanAt(size.width * 0.28, size.height * 0.94, size.height * 0.84, secondary, accent, true)
        }
        snowmanAt(size.width * 0.58, size.height * 0.94, size.height * 0.62, secondary, accent, false)
        snowmanAt(size.width * 0.82, size.height * 0.94, size.height * 0.42, bulbColours[2], accent, false)
        // A tiny stick arm on the tall one, holding the small one's hand.
        val arm = UIBezierPath(); arm.move(CGPoint(size.width * 0.40, size.height * 0.56)); arm.addLine(CGPoint(size.width * 0.50, size.height * 0.62))
        stroke(arm, ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown), max(1.0, size.width * 0.016))
    }

    fun drawSnowConeCart(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        snowMound(CGRect(size.width * 0.02, size.height * 0.86, size.width * 0.96, size.height * 0.13))
        // Wheels and the body of the cart.
        val charcoal = ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.charcoal)
        for (x in listOf(0.22, 0.60)) fill(oval(size.width * x, size.height * 0.78, size.width * 0.18, size.width * 0.18), charcoal)
        val body = CGRect(size.width * 0.12, size.height * 0.48, size.width * 0.76, size.height * 0.36)
        withShadow(context) { fill(rounded(body, size.width * 0.05), primary) }
        fill(box(body.minX, body.minY + body.height * 0.40, body.width, body.height * 0.12), secondary)
        // Syrup bottles lined up on top.
        val syrups = listOf(accent, bulbColours[1], bulbColours[2], bulbColours[0])
        for ((index, colour) in syrups.withIndex()) {
            val x = body.minX + body.width * (0.10 + 0.20 * index)
            fill(rounded(CGRect(x, body.minY - size.height * 0.12, size.width * 0.08, size.height * 0.14), 2.0), colour)
            fill(box(x + size.width * 0.02, body.minY - size.height * 0.17, size.width * 0.04, size.height * 0.06), secondary)
        }
        // A heap of shaved ice in a cone on the front.
        val cone = UIBezierPath()
        cone.move(CGPoint(size.width * 0.44, size.height * 0.60)); cone.addLine(CGPoint(size.width * 0.56, size.height * 0.60)); cone.addLine(CGPoint(size.width * 0.50, size.height * 0.80)); cone.close()
        fill(cone, UIColor(0.95, 0.88, 0.70, 1.0))
        fill(oval(size.width * 0.41, size.height * 0.50, size.width * 0.18, size.height * 0.14), snowWhite)
        fill(oval(size.width * 0.44, size.height * 0.46, size.width * 0.12, size.height * 0.10), accent.withAlphaComponent(0.8))
        // A striped umbrella over everything, with snow on top.
        val pole = UIBezierPath(); pole.move(CGPoint(size.width * 0.50, size.height * 0.48)); pole.addLine(CGPoint(size.width * 0.50, size.height * 0.10))
        stroke(pole, ParkPalette.colour(com.wickedstudios.wonderlot.ParkColour.brown), max(1.2, size.width * 0.02))
        val segments = 6
        for (index in 0 until segments) {
            val x0 = size.width * (0.06 + 0.88 * index / segments)
            val x1 = size.width * (0.06 + 0.88 * (index + 1) / segments)
            val panel = UIBezierPath()
            panel.move(CGPoint(size.width * 0.50, size.height * 0.04)); panel.addLine(CGPoint(x1, size.height * 0.24)); panel.addLine(CGPoint(x0, size.height * 0.24)); panel.close()
            fill(panel, if (index % 2 == 0) primary else snowWhite)
        }
        snowMound(CGRect(size.width * 0.38, size.height * 0.00, size.width * 0.24, size.height * 0.08))
    }

    // endregion

    // region Sizes

    /** How big the moving part is for the holiday rides, or null for a motif that has none of its own. */
    fun motionPartSize(motif: BuildingMotif, buildingSize: CGSize): CGSize? {
        val shortest = min(buildingSize.width, buildingSize.height)
        return when (motif) {
            BuildingMotif.reindeerCarousel -> CGSize(shortest * 0.78, shortest * 0.78)
            BuildingMotif.sleighRide -> CGSize(shortest * 0.22, shortest * 0.14)
            BuildingMotif.candyCoaster, BuildingMotif.starburstCoaster -> CGSize(shortest * 0.19, shortest * 0.12)
            BuildingMotif.snowGlobe -> CGSize(shortest * 0.70, shortest * 0.70)
            BuildingMotif.polarExpress -> CGSize(shortest * 0.17, shortest * 0.11)
            BuildingMotif.gingerbreadManor -> CGSize(shortest * 0.18, shortest * 0.26)
            BuildingMotif.starTopper -> CGSize(shortest * 0.30, shortest * 0.18)
            BuildingMotif.countdownWheel -> CGSize(shortest * 0.82, shortest * 0.82)
            BuildingMotif.confettiSwing -> CGSize(shortest * 0.16, shortest * 0.22)
            BuildingMotif.ballDrop -> CGSize(shortest * 0.20, shortest * 0.20)
            BuildingMotif.skatingRink -> CGSize(shortest * 0.11, shortest * 0.15)
            else -> null
        }
    }

    /** How many moving parts each holiday ride has. */
    fun motionPartCount(motif: BuildingMotif): Int? = when (motif) {
        BuildingMotif.sleighRide, BuildingMotif.candyCoaster, BuildingMotif.starburstCoaster -> 3
        BuildingMotif.polarExpress -> 4
        BuildingMotif.confettiSwing -> 6
        BuildingMotif.skatingRink -> 5
        else -> null
    }

    // endregion
}
