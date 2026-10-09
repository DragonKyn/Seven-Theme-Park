package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.ParkColour
import com.wickedstudios.wonderlot.TerrainType

/**
 * The ground: walkways, bridges and water. A walkway is drawn from what it
 * joins onto rather than as a square of paving, which is what makes a turn
 * look like a turn.
 */
object TerrainArtwork {

    /** How much of a tile the kerb takes on an open side. */
    private const val margin = 0.07

    /** How hard a corner rounds where two open sides meet. */
    private const val corner = 0.40

    // region Build menu swatches

    private val previewCache = HashMap<String, Bitmap>()

    /**
     * One tile of terrain, drawn exactly as the map draws it. The sample is a
     * straight run rather than an isolated tile, so the paving pattern shows.
     */
    fun previewImage(terrain: TerrainType, style: Int, size: CGSize): Bitmap {
        val key = "terrain-preview-${terrain.name}-$style-${size.width.toInt()}"
        previewCache[key]?.let { return it }

        val runsThrough = 1 or 4
        val image = SpriteFactory.render(size) { context, drawSize ->
            when (terrain) {
                TerrainType.path, TerrainType.entrance -> drawWalkway(runsThrough, style, 0, context, drawSize)
                TerrainType.bridge -> drawBridge(runsThrough, drawSize)
                // Banked on every side, so a single tile reads as a pond rather than as a blue square.
                TerrainType.water -> drawWater(15, style, 0, drawSize)
                TerrainType.rock -> drawRock(0, 1, drawSize)
                TerrainType.forest -> drawForest(0, 1, drawSize)
                else -> {
                    ParkPalette.colour(terrain, false).setFill()
                    UIBezierPath(CGRect(CGPoint.zero, drawSize)).fill()
                }
            }
        }
        previewCache[key] = image
        return image
    }

    // endregion

    // region Walkways

    /** [connections] is a bitmask of north, east, south and west sides that carry on into more walkway. */
    fun walkwayTexture(connections: Int, style: Int, variant: Int, side: Double): Bitmap =
        SpriteFactory.texture("walk-$style-$connections-$variant-$side", CGSize(side, side)) { context, size ->
            drawWalkway(connections, style, variant, context, size)
        }

    fun drawWalkway(connections: Int, style: Int, variant: Int, context: CGContext, size: CGSize) {
        // Grass underneath, because the paving no longer fills the tile.
        (if (variant % 2 == 0) ParkPalette.grass else ParkPalette.grassAlt).setFill()
        UIBezierPath(CGRect(CGPoint.zero, size)).fill()

        val shape = surface(connections, size)
        val finish = WalkwayFinish(style)

        finish.base.setFill()
        shape.fill()

        context.saveGState()
        shape.addClip()
        finish.draw(size, variant, connections)
        context.restoreGState()

        // Kerb. Only the outline is stroked, so it curves round a corner for free.
        finish.kerb.setStroke()
        shape.lineWidth = max(1, size.width * 0.055)
        shape.stroke()
    }

    /**
     * The shape of the paving on one tile: full width across every side that
     * carries on, pulled in on every side that does not, and rounded at any
     * corner between two pulled-in sides.
     */
    private fun surface(connections: Int, size: CGSize): UIBezierPath {
        val inset = size.width * margin
        val north = connections and 1 != 0
        val east = connections and 2 != 0
        val south = connections and 4 != 0
        val west = connections and 8 != 0

        // Texture space runs y downward, so north is the top edge.
        val top = if (north) 0.0 else inset
        val bottom = size.height - (if (south) 0.0 else inset)
        val left = if (west) 0.0 else inset
        val right = size.width - (if (east) 0.0 else inset)
        val radius = size.width * corner

        // A lone tile with nothing attached is a round pad rather than a square of paving nobody laid.
        if (connections == 0) {
            return UIBezierPath(CGRect(left, top, right - left, bottom - top), radius)
        }

        val path = UIBezierPath()

        class Corner(val point: CGPoint, val rounded: Boolean, val centre: CGPoint)

        // Corners are listed clockwise from the top left, each with the two sides that meet there.
        val corners = listOf(
            Corner(CGPoint(left, top), !north && !west, CGPoint(left + radius, top + radius)),
            Corner(CGPoint(right, top), !north && !east, CGPoint(right - radius, top + radius)),
            Corner(CGPoint(right, bottom), !south && !east, CGPoint(right - radius, bottom - radius)),
            Corner(CGPoint(left, bottom), !south && !west, CGPoint(left + radius, bottom - radius)),
        )

        val startAngles = listOf(PI, PI * 1.5, 0.0, PI * 0.5)

        for ((index, c) in corners.withIndex()) {
            if (c.rounded) {
                val start = startAngles[index]
                if (index == 0) path.move(CGPoint(c.centre.x - radius, c.centre.y))
                path.addArc(c.centre, radius, start, start + PI / 2, true)
            } else {
                if (index == 0) path.move(c.point) else path.addLine(c.point)
            }
        }
        path.close()
        return path
    }

    /** What a walkway is paved with. */
    private class WalkwayFinish(val style: Int) {
        val base: UIColor
            get() = when (style) {
                1 -> UIColor(0.78, 0.52, 0.42, 1.0)
                2 -> UIColor(0.71, 0.55, 0.38, 1.0)
                3 -> UIColor(0.40, 0.40, 0.43, 1.0)
                else -> ParkPalette.path
            }

        val kerb: UIColor
            get() = when (style) {
                1 -> UIColor(0.60, 0.38, 0.30, 0.85)
                2 -> UIColor(0.50, 0.37, 0.24, 0.85)
                3 -> UIColor(0.28, 0.28, 0.31, 0.85)
                else -> ParkPalette.pathJoint
            }

        private val line: UIColor
            get() = when (style) {
                1 -> UIColor(0.63, 0.40, 0.32, 0.75)
                2 -> UIColor(0.52, 0.38, 0.25, 0.80)
                3 -> UIColor(1.0, 1.0, 1.0, 0.10)
                else -> ParkPalette.pathJoint
            }

        fun draw(size: CGSize, variant: Int, connections: Int) {
            when (style) {
                1 -> drawBrick(size, variant)
                2 -> drawPlanks(size, connections)
                3 -> drawTarmac(size, variant)
                else -> drawSlabs(size, variant)
            }
        }

        /** Slabs, with the joint shifted every row so the courses interlock. */
        private fun drawSlabs(size: CGSize, variant: Int) {
            val joints = UIBezierPath()
            val rows = 2
            for (row in 0..rows) {
                val y = size.height * row / rows
                joints.move(CGPoint(0.0, y))
                joints.addLine(CGPoint(size.width, y))
            }
            for (row in 0 until rows) {
                val y = size.height * row / rows
                val offset = if ((row + variant) % 2 == 0) 0.5 else 0.25
                joints.move(CGPoint(size.width * offset, y))
                joints.addLine(CGPoint(size.width * offset, y + size.height / rows))
            }
            line.setStroke()
            joints.lineWidth = max(0.5, size.width * 0.022)
            joints.stroke()
        }

        /** Small bricks in a running bond. */
        private fun drawBrick(size: CGSize, variant: Int) {
            val rows = 4
            val columns = 3
            line.setStroke()
            val bricks = UIBezierPath()
            for (row in 0..rows) {
                val y = size.height * row / rows
                bricks.move(CGPoint(0.0, y))
                bricks.addLine(CGPoint(size.width, y))
            }
            for (row in 0 until rows) {
                val y = size.height * row / rows
                val shift = if ((row + variant) % 2 == 0) 0.0 else 0.5
                for (column in 0..columns) {
                    val x = size.width * (column + shift) / columns
                    bricks.move(CGPoint(x, y))
                    bricks.addLine(CGPoint(x, y + size.height / rows))
                }
            }
            bricks.lineWidth = max(0.5, size.width * 0.020)
            bricks.stroke()
        }

        /** Boards laid across the direction of travel. */
        private fun drawPlanks(size: CGSize, connections: Int) {
            val vertical = (connections and 1 != 0) || (connections and 4 != 0)
            val planks = UIBezierPath()
            val count = 5
            for (index in 1 until count) {
                val offset = index.toDouble() / count
                if (vertical) {
                    planks.move(CGPoint(0.0, size.height * offset))
                    planks.addLine(CGPoint(size.width, size.height * offset))
                } else {
                    planks.move(CGPoint(size.width * offset, 0.0))
                    planks.addLine(CGPoint(size.width * offset, size.height))
                }
            }
            line.setStroke()
            planks.lineWidth = max(0.5, size.width * 0.028)
            planks.stroke()
        }

        /** Chippings, so a flat dark tile is not a flat dark tile. */
        private fun drawTarmac(size: CGSize, variant: Int) {
            line.setFill()
            val spots = listOf(0.22 to 0.30, 0.61 to 0.22, 0.38 to 0.58, 0.76 to 0.66, 0.16 to 0.78)
            for ((index, spot) in spots.withIndex()) {
                if ((index + variant) % 2 != 0) continue
                val side = size.width * 0.07
                UIBezierPath(ovalIn = CGRect(size.width * spot.first, size.height * spot.second, side, side)).fill()
            }
        }
    }

    // endregion

    // region Natural ground

    fun rockTexture(edges: Int, variant: Int, side: Double): Bitmap =
        SpriteFactory.texture("rock-$edges-$variant-$side", CGSize(side, side)) { _, size ->
            drawRock(edges, variant, size)
        }

    fun drawRock(edges: Int, variant: Int, size: CGSize) {
        ParkPalette.rock.setFill()
        UIBezierPath(CGRect(CGPoint.zero, size)).fill()

        // Boulders, placed by variant so a field of rock is not a grid.
        val layouts = listOf(
            listOf(Triple(0.30, 0.34, 0.26), Triple(0.70, 0.66, 0.20)),
            listOf(Triple(0.62, 0.30, 0.24), Triple(0.26, 0.70, 0.18)),
            listOf(Triple(0.50, 0.52, 0.30)),
            listOf(Triple(0.24, 0.26, 0.18), Triple(0.72, 0.40, 0.22), Triple(0.40, 0.76, 0.16)),
        )
        for ((x, y, radius) in layouts[variant % layouts.size]) {
            val rect = CGRect(size.width * (x - radius), size.height * (y - radius * 0.8),
                size.width * radius * 2, size.height * radius * 1.6)
            ParkPalette.rockShade.setFill()
            UIBezierPath(ovalIn = rect.offsetBy(0, size.height * 0.05)).fill()
            ParkPalette.rockLight.setFill()
            UIBezierPath(ovalIn = rect).fill()
        }

        drawEdges(edges, ParkPalette.rockShade, size, 0.14)
    }

    fun forestTexture(edges: Int, variant: Int, side: Double): Bitmap =
        SpriteFactory.texture("forest-$edges-$variant-$side", CGSize(side, side)) { _, size ->
            drawForest(edges, variant, size)
        }

    fun drawForest(edges: Int, variant: Int, size: CGSize) {
        ParkPalette.forestDeep.setFill()
        UIBezierPath(CGRect(CGPoint.zero, size)).fill()

        // Crowns overlapping the tile edge slightly, so neighbouring tiles merge into one canopy.
        val crowns = listOf(
            listOf(Triple(0.28, 0.30, 0.32), Triple(0.74, 0.40, 0.30), Triple(0.46, 0.78, 0.30)),
            listOf(Triple(0.64, 0.26, 0.34), Triple(0.24, 0.62, 0.30), Triple(0.78, 0.80, 0.26)),
            listOf(Triple(0.40, 0.40, 0.38), Triple(0.84, 0.72, 0.24)),
            listOf(Triple(0.20, 0.22, 0.26), Triple(0.62, 0.52, 0.34), Triple(0.22, 0.84, 0.24)),
        )
        for ((x, y, radius) in crowns[variant % crowns.size]) {
            val rect = CGRect(size.width * (x - radius), size.height * (y - radius),
                size.width * radius * 2, size.height * radius * 2)
            ParkPalette.forest.setFill()
            UIBezierPath(ovalIn = rect).fill()
            // A lit side on each crown, which is what makes it a tree.
            ParkPalette.forestCanopy.setFill()
            UIBezierPath(ovalIn = rect.insetBy(rect.width * 0.22, rect.height * 0.22)
                .offsetBy(-rect.width * 0.08, -rect.height * 0.08)).fill()
        }

        drawEdges(edges, ParkPalette.forestDeep.withAlphaComponent(0.85), size, 0.10)
    }

    /** A band along each side named in [edges] (north, east, south, west). */
    private fun drawEdges(edges: Int, colour: UIColor, size: CGSize, depth: Double) {
        if (edges == 0) return
        colour.setFill()
        val band = size.width * depth
        // Texture space runs y downward, so north is the top edge.
        if (edges and 1 != 0) UIBezierPath(CGRect(0.0, 0.0, size.width, band)).fill()
        if (edges and 4 != 0) UIBezierPath(CGRect(0.0, size.height - band, size.width, band)).fill()
        if (edges and 8 != 0) UIBezierPath(CGRect(0.0, 0.0, band, size.height)).fill()
        if (edges and 2 != 0) UIBezierPath(CGRect(size.width - band, 0.0, band, size.height)).fill()
    }

    // endregion

    // region Bridges

    /** A deck over the water, railed on the sides the walk does not continue. */
    fun bridgeTexture(connections: Int, side: Double): Bitmap =
        SpriteFactory.texture("bridge-$connections-$side", CGSize(side, side)) { _, size ->
            drawBridge(connections, size)
        }

    fun drawBridge(connections: Int, size: CGSize) {
        ParkPalette.water.setFill()
        UIBezierPath(CGRect(CGPoint.zero, size)).fill()

        val deck = ParkPalette.colour(ParkColour.brown)
        val plank = UIColor(0.42, 0.30, 0.20, 0.8)
        val rail = ParkPalette.colour(ParkColour.sand)

        // The deck runs the way the walk does; a bridge with nothing attached is drawn north to south.
        val northSouth = (connections and 1 != 0) || (connections and 4 != 0) || connections == 0
        val body = if (northSouth) CGRect(size.width * 0.08, 0.0, size.width * 0.84, size.height)
        else CGRect(0.0, size.height * 0.08, size.width, size.height * 0.84)
        deck.setFill()
        UIBezierPath(body).fill()

        val planks = UIBezierPath()
        val count = 6
        for (index in 1 until count) {
            val offset = index.toDouble() / count
            if (northSouth) {
                planks.move(CGPoint(body.minX, size.height * offset))
                planks.addLine(CGPoint(body.maxX, size.height * offset))
            } else {
                planks.move(CGPoint(size.width * offset, body.minY))
                planks.addLine(CGPoint(size.width * offset, body.maxY))
            }
        }
        plank.setStroke()
        planks.lineWidth = max(0.5, size.width * 0.030)
        planks.stroke()

        // Rails down both long sides.
        rail.setFill()
        val thickness = max(1, size.width * 0.07)
        if (northSouth) {
            UIBezierPath(CGRect(body.minX, 0.0, thickness, size.height)).fill()
            UIBezierPath(CGRect(body.maxX - thickness, 0.0, thickness, size.height)).fill()
        } else {
            UIBezierPath(CGRect(0.0, body.minY, size.width, thickness)).fill()
            UIBezierPath(CGRect(0.0, body.maxY - thickness, size.width, thickness)).fill()
        }
    }

    // endregion

    // region Water

    /** [shores] is a bitmask of the sides that are not more water. */
    fun waterTexture(shores: Int, style: Int, variant: Int, side: Double): Bitmap =
        SpriteFactory.texture("water-$style-$shores-$variant-$side", CGSize(side, side)) { _, size ->
            drawWater(shores, style, variant, size)
        }

    fun drawWater(shores: Int, style: Int, variant: Int, size: CGSize) {
        val palette = WaterFinish(style)
        (if (variant % 2 == 0) palette.base else palette.alternate).setFill()
        UIBezierPath(CGRect(CGPoint.zero, size)).fill()

        // A ripple or two, offset by variant so the surface is not a grid.
        palette.ripple.setStroke()
        val ripples = UIBezierPath()
        val lift = if (variant % 2 == 0) 0.34 else 0.62
        for (step in 0 until 2) {
            val y = size.height * (lift + 0.24 * step)
            ripples.move(CGPoint(size.width * 0.18, y))
            ripples.addQuadCurve(CGPoint(size.width * 0.62, y), CGPoint(size.width * 0.40, y - size.height * 0.07))
        }
        ripples.lineWidth = max(1, size.width * 0.030)
        ripples.stroke()

        if (shores == 0) return
        val band = size.width * 0.16
        palette.shore.setFill()
        if (shores and 1 != 0) UIBezierPath(CGRect(0.0, 0.0, size.width, band)).fill()
        if (shores and 4 != 0) UIBezierPath(CGRect(0.0, size.height - band, size.width, band)).fill()
        if (shores and 8 != 0) UIBezierPath(CGRect(0.0, 0.0, band, size.height)).fill()
        if (shores and 2 != 0) UIBezierPath(CGRect(size.width - band, 0.0, band, size.height)).fill()
    }

    /** What colour the water is. */
    private class WaterFinish(val style: Int) {
        val base: UIColor
            get() = when (style) {
                1 -> UIColor(0.22, 0.76, 0.74, 1.0)
                2 -> UIColor(0.16, 0.32, 0.56, 1.0)
                else -> ParkPalette.water
            }

        val alternate: UIColor
            get() = when (style) {
                1 -> UIColor(0.18, 0.71, 0.70, 1.0)
                2 -> UIColor(0.13, 0.27, 0.50, 1.0)
                else -> ParkPalette.waterAlt
            }

        val ripple: UIColor get() = if (style == 2) UIColor(1.0, 1.0, 1.0, 0.12) else ParkPalette.waterRipple

        val shore: UIColor
            get() = when (style) {
                1 -> UIColor(0.85, 0.93, 0.78, 0.65)
                2 -> UIColor(0.44, 0.58, 0.74, 0.55)
                else -> ParkPalette.waterShore
            }
    }

    // endregion
}
