package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.CoasterCarStyle
import com.wickedstudios.wonderlot.ParkColour

/**
 * Generates the park's artwork programmatically. Everything the map draws is
 * a shape rendered once and cached as a bitmap, which keeps the project
 * asset-free.
 */
object SpriteFactory {

    /** Pixels per point the artwork is drawn at. Lower on a phone that is struggling. */
    @Volatile
    var scale: Double = 2.0

    private val cache = HashMap<String, Bitmap>()

    fun clearCache() {
        cache.clear()
        GuestArtwork.clearCache()
    }

    /** Draws once and caches by key. */
    fun texture(key: String, size: CGSize, draw: (CGContext, CGSize) -> Unit): Bitmap {
        cache[key]?.let { return it }
        val image = render(size, draw)
        cache[key] = image
        return image
    }

    /**
     * Draws a texture without keeping it. For artwork with too many possible
     * combinations to cache forever, where the caller keeps its own bounded cache.
     */
    fun render(size: CGSize, draw: (CGContext, CGSize) -> Unit): Bitmap = Gfx.image(size, scale, draw)

    /** Flat tile with a subtle inset border. */
    fun tileTexture(colour: UIColor, side: Double): Bitmap =
        texture("tile-${colour.argb}-$side", CGSize(side, side)) { context, size ->
            colour.setFill()
            UIBezierPath(CGRect(CGPoint.zero, size)).fill()

            context.setStrokeColor(UIColor.black.withAlphaComponent(0.05))
            context.setLineWidth(1)
            context.stroke(CGRect(CGPoint.zero, size))
        }

    // region Ground

    /** Grass with a few tufts on it. Four variants, picked from the coordinate. */
    fun grassTexture(variant: Int, side: Double): Bitmap =
        texture("grass-$variant-$side", CGSize(side, side)) { _, size ->
            val base = if (variant % 2 == 0) ParkPalette.grass else ParkPalette.grassAlt
            base.setFill()
            UIBezierPath(CGRect(CGPoint.zero, size)).fill()

            // Fixed tuft positions per variant, so the same tile always looks the same.
            val tufts = listOf(
                listOf(0.22 to 0.34, 0.68 to 0.62),
                listOf(0.48 to 0.22, 0.16 to 0.76, 0.80 to 0.44),
                listOf(0.34 to 0.68),
                listOf(0.72 to 0.26, 0.30 to 0.52, 0.58 to 0.84),
            )
            ParkPalette.grassTuft.setStroke()
            for ((x, y) in tufts[variant % tufts.size]) {
                val blade = UIBezierPath()
                val foot = CGPoint(size.width * x, size.height * y)
                blade.move(CGPoint(foot.x, foot.y))
                blade.addLine(CGPoint(foot.x - size.width * 0.035, foot.y - size.height * 0.11))
                blade.move(CGPoint(foot.x, foot.y))
                blade.addLine(CGPoint(foot.x + size.width * 0.045, foot.y - size.height * 0.09))
                blade.lineWidth = max(1, size.width * 0.035)
                blade.stroke()
            }
        }

    /** Rounded block used for rides, shops and facilities that have no artwork of their own yet. */
    fun buildingTexture(colour: UIColor, size: CGSize): Bitmap =
        texture("building-${colour.argb}-${size.width}x${size.height}", size) { context, drawSize ->
            val inset = min(drawSize.width, drawSize.height) * 0.07
            val rect = CGRect(CGPoint.zero, drawSize).insetBy(inset, inset)
            val radius = min(rect.width, rect.height) * 0.18

            context.setShadow(CGSize(0.0, -2.0), 4, UIColor.black.withAlphaComponent(0.25))

            colour.setFill()
            UIBezierPath(rect, radius).fill()

            context.setShadow(CGSize.zero, 0, null)

            // Light top face to give a hint of depth without going isometric.
            val highlight = rect.insetBy(rect.width * 0.12, rect.height * 0.12)
            UIColor.white.withAlphaComponent(0.22).setFill()
            UIBezierPath(CGRect(highlight.minX, highlight.midY, highlight.width, highlight.height / 2), radius * 0.6).fill()
        }

    fun circleTexture(colour: UIColor, diameter: Double): Bitmap =
        texture("circle-${colour.argb}-$diameter", CGSize(diameter, diameter)) { _, size ->
            val rect = CGRect(CGPoint.zero, size).insetBy(1, 1)
            UIColor.white.withAlphaComponent(0.85).setFill()
            UIBezierPath(ovalIn = rect).fill()
            colour.setFill()
            UIBezierPath(ovalIn = rect.insetBy(1.5, 1.5)).fill()
        }

    /** Scattered specks of rubbish. Three intensity steps are enough to read at a glance. */
    fun litterTexture(intensity: Int, side: Double): Bitmap =
        texture("litter-$intensity-$side", CGSize(side, side)) { _, size ->
            val count = 2 + intensity * 3
            val offsets = listOf(
                0.22 to 0.31, 0.68 to 0.19, 0.44 to 0.62, 0.81 to 0.71,
                0.14 to 0.77, 0.57 to 0.42, 0.33 to 0.12, 0.72 to 0.51,
                0.09 to 0.48, 0.90 to 0.36, 0.51 to 0.86,
            )
            ParkPalette.litter.setFill()
            for (index in 0 until min(count, offsets.size)) {
                val offset = offsets[index]
                val dotSize = size.width * (if (index % 2 == 0) 0.10 else 0.07)
                val rect = CGRect(offset.first * size.width - dotSize / 2, offset.second * size.height - dotSize / 2,
                    dotSize, dotSize)
                UIBezierPath(ovalIn = rect).fill()
            }
        }

    /**
     * One tile of railway, drawn to match the track it is actually connected to.
     * [connections] is a bitmask of north, east, south and west.
     */
    fun trackTileTexture(connections: Int, side: Double, coaster: Boolean = false, rail: ParkColour? = null): Bitmap {
        val bed = if (coaster) ParkPalette.coasterBed else ParkPalette.ballast
        val tie = if (coaster) ParkPalette.coasterTie else ParkPalette.sleeper
        val railColour = if (coaster) ParkPalette.coasterRail(rail) else ParkPalette.rail

        return texture("track-${if (coaster) "c" else "r"}-$connections-$side-${rail?.name ?: "stock"}",
            CGSize(side, side)) { _, size ->
            bed.setFill()
            UIBezierPath(CGRect(CGPoint.zero, size)).fill()

            val centre = CGPoint(size.width / 2, size.height / 2)
            val gauge = size.width * 0.24
            val tieWidth = max(2, size.width * 0.30)
            val railWidth = max(1, size.width * 0.055)

            // Texture space runs y downward, so north is the top of the image.
            class Arm(val bit: Int, val vx: Double, val vy: Double)
            val directions = listOf(Arm(1, 0.0, -1.0), Arm(2, 1.0, 0.0), Arm(4, 0.0, 1.0), Arm(8, -1.0, 0.0))
            val live = directions.filter { connections and it.bit != 0 }

            fun edgePoint(arm: Arm) = CGPoint(centre.x + arm.vx * size.width / 2, centre.y + arm.vy * size.height / 2)

            /** Ties first as one thick dark stroke, then the pair of rails on top. */
            fun layTrack(build: (UIBezierPath, Double) -> Unit) {
                val ties = UIBezierPath()
                build(ties, 0.0)
                tie.setStroke()
                ties.lineWidth = tieWidth
                ties.stroke()

                railColour.setStroke()
                for (offset in listOf(-gauge / 2, gauge / 2)) {
                    val railPath = UIBezierPath()
                    build(railPath, offset)
                    railPath.lineWidth = railWidth
                    railPath.stroke()
                }
            }

            // Two neighbours at right angles: a curve about the tile corner they share.
            if (live.size == 2 && (live[0].vx != -live[1].vx || live[0].vy != -live[1].vy)) {
                val first = live[0]
                val second = live[1]
                val corner = CGPoint(centre.x + (first.vx + second.vx) * size.width / 2,
                    centre.y + (first.vy + second.vy) * size.height / 2)
                val radius = size.width / 2
                val start = atan2(-second.vy, -second.vx)
                var sweep = atan2(-first.vy, -first.vx) - start
                while (sweep > PI) sweep -= PI * 2
                while (sweep < -PI) sweep += PI * 2

                layTrack { path, offset ->
                    val arcRadius = radius + offset
                    val steps = 12
                    for (step in 0..steps) {
                        val angle = start + sweep * step / steps
                        val point = CGPoint(corner.x + cos(angle) * arcRadius, corner.y + sin(angle) * arcRadius)
                        if (step == 0) path.move(point) else path.addLine(point)
                    }
                }
                return@texture
            }

            // Straight arms out of the middle: a through run, a junction, a dead end, or a lone tile.
            val arms = if (live.isEmpty()) listOf(directions[1], directions[3]) else live
            for (arm in arms) {
                val end = edgePoint(arm)
                layTrack { path, offset ->
                    // Offset across the direction of travel.
                    val acrossX = -arm.vy * offset
                    val acrossY = arm.vx * offset
                    path.move(CGPoint(centre.x + acrossX, centre.y + acrossY))
                    path.addLine(CGPoint(end.x + acrossX, end.y + acrossY))
                }
            }
        }
    }

    /** A special coaster piece: the plain tile with the element drawn over it. */
    fun coasterElementTexture(connections: Int, side: Double, element: com.wickedstudios.wonderlot.TerrainType): Bitmap {
        val base = trackTileTexture(connections, side, coaster = true)
        return texture("coaster-${element.name}-$connections-$side", CGSize(side, side)) { context, size ->
            context.draw(base, CGRect(CGPoint.zero, size))

            val centre = CGPoint(size.width / 2, size.height / 2)
            ParkPalette.coasterRail.setStroke()

            fun tube(path: UIBezierPath, outer: Double, inner: Double) {
                ParkPalette.coasterTie.setStroke()
                path.lineWidth = outer
                path.stroke()
                ParkPalette.coasterRail.setStroke()
                path.lineWidth = inner
                path.stroke()
            }

            when (element) {
                com.wickedstudios.wonderlot.TerrainType.coasterLoop -> {
                    val radius = size.width * 0.30
                    val ring = UIBezierPath(ovalIn = CGRect(centre.x - radius, centre.y - radius * 1.05, radius * 2, radius * 2))
                    tube(ring, max(2, size.width * 0.13), max(1, size.width * 0.055))
                }
                com.wickedstudios.wonderlot.TerrainType.coasterHill -> {
                    val hump = UIBezierPath()
                    hump.move(CGPoint(size.width * 0.08, size.height * 0.74))
                    hump.addQuadCurve(CGPoint(size.width * 0.92, size.height * 0.74), CGPoint(centre.x, -size.height * 0.16))
                    tube(hump, max(2, size.width * 0.13), max(1, size.width * 0.055))
                }
                com.wickedstudios.wonderlot.TerrainType.coasterJump -> {
                    val lip = size.width * 0.30
                    for (direction in listOf(-1.0, 1.0)) {
                        val ramp = UIBezierPath()
                        val outer = CGPoint(centre.x + direction * size.width * 0.5, centre.y)
                        val inner = CGPoint(centre.x + direction * lip * 0.5, centre.y - size.height * 0.26)
                        ramp.move(outer)
                        ramp.addQuadCurve(inner, CGPoint(centre.x + direction * lip, centre.y))
                        tube(ramp, max(2, size.width * 0.13), max(1, size.width * 0.055))
                    }
                    ParkPalette.coasterRail.withAlphaComponent(0.5).setFill()
                    for (step in 0 until 2) {
                        val mark = CGRect(centre.x - size.width * 0.05, centre.y + size.height * (0.10 + 0.14 * step),
                            size.width * 0.10, size.height * 0.07)
                        UIBezierPath(mark).fill()
                    }
                }
                com.wickedstudios.wonderlot.TerrainType.coasterHelix -> {
                    val radius = size.width * 0.22
                    for (offset in listOf(-size.width * 0.13, size.width * 0.13)) {
                        val ring = UIBezierPath(ovalIn = CGRect(centre.x + offset - radius, centre.y - radius, radius * 2, radius * 2))
                        tube(ring, max(2, size.width * 0.11), max(1, size.width * 0.048))
                    }
                }
                else -> {}
            }
        }
    }

    // endregion

    // region Vehicles and signs

    /** A coaster car, nose to the right. */
    fun coasterCarTexture(isLeading: Boolean, style: CoasterCarStyle, colour: ParkColour, size: CGSize): Bitmap =
        texture("coaster-car-${style.name}-${colour.name}-${if (isLeading) "lead" else "follow"}-${size.width.toInt()}x${size.height.toInt()}",
            size) { context, drawSize ->
            val body = CGRect(CGPoint.zero, drawSize).insetBy(0.5, drawSize.height * 0.14)
            val paint = ParkPalette.colour(colour)

            context.setShadow(CGSize(0.0, drawSize.height * 0.12), drawSize.height * 0.18,
                UIColor.black.withAlphaComponent(0.30))
            paint.setFill()

            when (style) {
                CoasterCarStyle.classic ->
                    if (isLeading) {
                        val nose = UIBezierPath()
                        nose.move(CGPoint(body.minX, body.minY))
                        nose.addLine(CGPoint(body.maxX - body.width * 0.22, body.minY))
                        nose.addQuadCurve(CGPoint(body.maxX - body.width * 0.22, body.maxY),
                            CGPoint(body.maxX + body.width * 0.18, body.midY))
                        nose.addLine(CGPoint(body.minX, body.maxY))
                        nose.close()
                        nose.fill()
                    } else {
                        UIBezierPath(body, body.height * 0.34).fill()
                    }

                CoasterCarStyle.rocket -> {
                    // Long and pointed, with a fin off the back.
                    val nose = UIBezierPath()
                    nose.move(CGPoint(body.minX, body.minY + body.height * 0.18))
                    nose.addLine(CGPoint(body.maxX - body.width * 0.30, body.minY))
                    nose.addQuadCurve(CGPoint(body.maxX - body.width * 0.30, body.maxY),
                        CGPoint(body.maxX + body.width * 0.30, body.midY))
                    nose.addLine(CGPoint(body.minX, body.maxY - body.height * 0.18))
                    nose.close()
                    nose.fill()

                    val fin = UIBezierPath()
                    fin.move(CGPoint(body.minX + body.width * 0.06, body.minY))
                    fin.addLine(CGPoint(body.minX + body.width * 0.28, body.minY - body.height * 0.30))
                    fin.addLine(CGPoint(body.minX + body.width * 0.30, body.minY))
                    fin.close()
                    ParkPalette.coasterTie.setFill()
                    fin.fill()
                    paint.setFill()
                }

                CoasterCarStyle.mineCart -> {
                    // Square, wooden, with a band round it.
                    UIBezierPath(body).fill()
                    ParkPalette.colour(ParkColour.brown).setFill()
                    UIBezierPath(CGRect(body.minX, body.minY, body.width, body.height * 0.16)).fill()
                    UIBezierPath(CGRect(body.minX, body.maxY - body.height * 0.16, body.width, body.height * 0.16)).fill()
                    paint.setFill()
                }

                CoasterCarStyle.bobsled -> {
                    // One smooth shell, no seams.
                    UIBezierPath(body, body.height * 0.5).fill()
                    if (isLeading) {
                        ParkPalette.colour(ParkColour.cream).setFill()
                        UIBezierPath(ovalIn = CGRect(body.maxX - body.width * 0.24, body.midY - body.height * 0.18,
                            body.width * 0.18, body.height * 0.36)).fill()
                        paint.setFill()
                    }
                }
            }
            context.setShadow(CGSize.zero, 0, null)

            // Riders, except in a bobsled where they are under the shell.
            if (style != CoasterCarStyle.bobsled) {
                ParkPalette.colour(ParkColour.cream).setFill()
                val head = drawSize.height * 0.40
                for (offset in listOf(0.24, 0.54)) {
                    UIBezierPath(ovalIn = CGRect(body.minX + body.width * offset, body.midY - head / 2, head, head)).fill()
                }
            }

            ParkPalette.coasterTie.setFill()
            UIBezierPath(CGRect(body.minX, body.maxY - drawSize.height * 0.10, body.width * 0.88, drawSize.height * 0.10)).fill()
        }

    /** A locomotive or a carriage, nose to the right. */
    fun trainCarTexture(isLocomotive: Boolean, size: CGSize): Bitmap =
        texture("train-${if (isLocomotive) "loco" else "car"}-${size.width.toInt()}x${size.height.toInt()}", size) { context, drawSize ->
            val colour = if (isLocomotive) ParkPalette.colour(ParkColour.red) else ParkPalette.colour(ParkColour.cream)

            context.setShadow(CGSize(0.0, drawSize.height * 0.10), drawSize.height * 0.16,
                UIColor.black.withAlphaComponent(0.30))

            val body = CGRect(drawSize.width * 0.04, drawSize.height * 0.16, drawSize.width * 0.92, drawSize.height * 0.68)
            colour.setFill()
            UIBezierPath(body, body.height * 0.30).fill()
            context.setShadow(CGSize.zero, 0, null)

            if (isLocomotive) {
                // Boiler front and a funnel, which is the whole silhouette at this size.
                val nose = CGRect(body.maxX - body.width * 0.22, body.minY, body.width * 0.22, body.height)
                ParkPalette.colour(ParkColour.charcoal).setFill()
                UIBezierPath(nose, body.height * 0.3).fill()

                val funnel = CGRect(body.maxX - body.width * 0.40, body.minY - drawSize.height * 0.10,
                    body.width * 0.13, body.height * 0.42)
                UIBezierPath(funnel, funnel.width * 0.3).fill()
            } else {
                // Windows down the side.
                ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.55).setFill()
                for (index in 0 until 3) {
                    val window = CGRect(body.minX + body.width * (0.14 + 0.26 * index), body.midY - body.height * 0.20,
                        body.width * 0.18, body.height * 0.40)
                    UIBezierPath(window, window.height * 0.25).fill()
                }
            }

            // Underframe, so the car does not float.
            ParkPalette.colour(ParkColour.charcoal).setFill()
            UIBezierPath(CGRect(body.minX + body.width * 0.06, body.maxY - drawSize.height * 0.02,
                body.width * 0.88, drawSize.height * 0.10)).fill()
        }

    /** The board and posts of the park's entrance sign. The name itself is drawn on top. */
    fun entranceSignTexture(size: CGSize): Bitmap =
        texture("entrance-sign-${size.width.toInt()}x${size.height.toInt()}", size) { context, drawSize ->
            // Posts first, so the board covers where they meet it.
            val postWidth = drawSize.width * 0.05
            for (x in listOf(drawSize.width * 0.22, drawSize.width * 0.78 - postWidth)) {
                val post = CGRect(x, drawSize.height * 0.45, postWidth, drawSize.height * 0.55)
                ParkPalette.signPost.setFill()
                UIBezierPath(post).fill()
            }

            val board = CGRect(drawSize.width * 0.04, drawSize.height * 0.06, drawSize.width * 0.92, drawSize.height * 0.62)
            context.setShadow(CGSize(0.0, drawSize.height * 0.04), drawSize.height * 0.09,
                UIColor.black.withAlphaComponent(0.30))
            ParkPalette.signFrame.setFill()
            UIBezierPath(board, board.height * 0.24).fill()
            context.setShadow(CGSize.zero, 0, null)

            val face = board.insetBy(board.width * 0.025, board.height * 0.11)
            ParkPalette.signFace.setFill()
            UIBezierPath(face, face.height * 0.22).fill()
        }

    /** Asphalt with marked bays and a few cars left in them, drawn outside the park below the sign. */
    fun carParkTexture(level: Int, size: CGSize): Bitmap =
        texture("car-park-$level-${size.width.toInt()}x${size.height.toInt()}", size) { _, drawSize ->
            val asphalt = CGRect(CGPoint.zero, drawSize)
            ParkPalette.carParkSurface(level).setFill()
            UIBezierPath(asphalt, drawSize.height * 0.06).fill()

            // Two banks of bays with an aisle between them.
            val bays = 11
            val bayWidth = drawSize.width / bays
            val bankHeight = drawSize.height * 0.36
            val banks = listOf(drawSize.height * 0.06, drawSize.height * 0.58)

            ParkPalette.bayLine.setStroke()
            for (bankTop in banks) {
                for (index in 0..bays) {
                    val line = UIBezierPath()
                    val x = bayWidth * index
                    line.move(CGPoint(x, bankTop))
                    line.addLine(CGPoint(x, bankTop + bankHeight))
                    line.lineWidth = max(1, drawSize.height * 0.008)
                    line.stroke()
                }
            }

            // Cars in some of the bays, and not the same ones in each bank. More of it paved means more of it used.
            val allBays = listOf(
                0 to 0, 0 to 1, 0 to 3, 0 to 4, 0 to 5, 0 to 8, 0 to 9, 0 to 6, 0 to 10, 0 to 2,
                1 to 1, 1 to 2, 1 to 4, 1 to 7, 1 to 8, 1 to 10, 1 to 0, 1 to 5, 1 to 9, 1 to 3,
            )
            val filled = 6 + level * 3
            val occupied = allBays.take(min(filled, allBays.size))
            val liveries = listOf(ParkColour.red, ParkColour.blue, ParkColour.cream, ParkColour.slate,
                ParkColour.green, ParkColour.amber, ParkColour.violet)

            for ((order, slot) in occupied.withIndex()) {
                val (bank, bay) = slot
                val colour = ParkPalette.colour(liveries[order % liveries.size])
                val body = CGRect(bayWidth * bay + bayWidth * 0.18, banks[bank] + bankHeight * 0.12,
                    bayWidth * 0.64, bankHeight * 0.76)
                colour.setFill()
                UIBezierPath(body, body.width * 0.3).fill()

                // Windscreen, which is what stops each car reading as a brick.
                val glass = body.insetBy(body.width * 0.18, body.height * 0.30)
                UIColor.black.withAlphaComponent(0.28).setFill()
                UIBezierPath(glass, glass.width * 0.25).fill()
            }

            // Aisle markings down the middle.
            val aisle = drawSize.height * 0.50
            val dash = UIBezierPath()
            dash.move(CGPoint(0.0, aisle))
            dash.addLine(CGPoint(drawSize.width, aisle))
            dash.lineWidth = max(1, drawSize.height * 0.012)
            dash.setLineDash(listOf(drawSize.width * 0.03, drawSize.width * 0.03), 0)
            ParkPalette.bayLine.setStroke()
            dash.stroke()
        }

    fun outlineTexture(colour: UIColor, size: CGSize, lineWidth: Double = 3.0): Bitmap =
        texture("outline-${colour.argb}-${size.width}x${size.height}-$lineWidth", size) { context, drawSize ->
            val rect = CGRect(CGPoint.zero, drawSize).insetBy(lineWidth / 2, lineWidth / 2)
            context.setStrokeColor(colour)
            context.setLineWidth(lineWidth)
            val path = UIBezierPath(rect, 6)
            path.lineWidth = lineWidth
            path.stroke()
        }

    // endregion
}
