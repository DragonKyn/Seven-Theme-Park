package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin


// Decoration made for the water.
//
// Every piece here is drawn on a clear background and is meant to be placed
// on a pond tile, so the water shows through round it. Each one also lays
// down a soft patch of water of its own first: in the build menu the piece
// is drawn on a plain card, and lily pads or lanterns with no water under
// them read as green and red blobs rather than as floating things.
internal object BuildingArtWaterScenery {

    // region Shared pieces

    // A calm patch under the piece. Translucent, so on a real pond it only
    // deepens the water a little and does not show an edge.
    internal fun drawWaterPatch(size: CGSize) {
        val area = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.04, size.height * 0.04)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  area), ParkPalette.water.withAlphaComponent(0.55))
    }

    // A pale ring on the surface, which is what tells the eye that something
    // is sitting in water rather than on top of it.
    internal fun drawRipple(rect: CGRect, width: Double) {
        val ring = UIBezierPath(ovalIn =  rect)
        BuildingArtwork.stroke(ring, UIColor.white.withAlphaComponent(0.55), width)
    }

    internal fun discRect(centre: CGPoint, diameter: Double): CGRect {
        return CGRect(centre.x - diameter / 2, centre.y - diameter / 2,
               diameter, diameter)
    }

    // region Lily pads

    private class LilyPad(val x: Double, val y: Double, val radius: Double, val turn: Double, val flower: Boolean)

    private class Boulder(val x: Double, val y: Double, val radius: Double, val turn: Double)

    private class Lantern(val x: Double, val y: Double, val scale: Double)

    internal fun drawLilyPads(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        drawWaterPatch(size)

        val layouts = listOf(
            listOf(LilyPad(0.30, 0.64, 0.17, 0.4, false),
             LilyPad(0.64, 0.40, 0.21, 2.2, true),
             LilyPad(0.70, 0.76, 0.11, 4.0, false)),
            listOf(LilyPad(0.50, 0.50, 0.24, 1.0, true),
             LilyPad(0.22, 0.28, 0.12, 3.1, false),
             LilyPad(0.78, 0.74, 0.12, 5.0, false)),
            listOf(LilyPad(0.25, 0.70, 0.15, 0.2, false),
             LilyPad(0.52, 0.58, 0.17, 2.0, false),
             LilyPad(0.76, 0.34, 0.15, 3.6, true),
             LilyPad(0.34, 0.26, 0.11, 5.2, false))
        )

        val reference = min(size.width, size.height)
        val notch: Double = 0.55

        for (pad in layouts[variant % layouts.size]) {
            val centre = CGPoint(pad.x * size.width, pad.y * size.height)
            val radius = pad.radius * reference
            val start = pad.turn + notch / 2
            val end = pad.turn + PI * 2 - notch / 2

            // A round leaf with a wedge missing, which is what makes it a
            // lily pad and not a plate.
            val leaf = UIBezierPath()
            leaf.move(centre)
            leaf.addArc(centre, radius,
                        start, end, true)
            leaf.close()
            BuildingArtwork.withShadow(context) { BuildingArtwork.fill(leaf, primary) }

            val sheen = UIBezierPath()
            sheen.move(centre)
            sheen.addArc(centre, radius * 0.6,
                         start, end, true)
            sheen.close()
            BuildingArtwork.fill(sheen, accent.withAlphaComponent(0.5))

            if (pad.flower) {
                drawBlossom(centre, radius * 0.7, secondary)
            }
        }
    }

    internal fun drawBlossom(centre: CGPoint, radius: Double, petal: UIColor) {
        val petalSize = radius * 0.62
        for (index in 0 until 5) {
            val angle = (index).toDouble() / 5 * PI * 2
            val spot = CGPoint(centre.x + cos(angle) * radius * 0.5,
                               centre.y + sin(angle) * radius * 0.5)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  discRect(spot, petalSize)), petal)
        }
        val heart = discRect(centre, radius * 0.4)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  heart), ParkPalette.colour(ParkColour.yellow))
    }

    // region Reeds

    internal fun drawReeds(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        drawWaterPatch(size)

        val ripple = CGRect(size.width * 0.14, size.height * 0.72,
                            size.width * 0.72, size.height * 0.20)
        drawRipple(ripple, max(1.5, size.width * 0.02))

        val leans = listOf(
            listOf(-0.10, 0.02, 0.09, 0.14),
            listOf(0.12, 0.04, -0.06, -0.12),
            listOf(-0.04, 0.08, -0.08, 0.05)
        )
        val lean = leans[variant % leans.size]
        val bases = listOf(0.30, 0.44, 0.58, 0.72)
        val tops = listOf(0.18, 0.08, 0.14, 0.24)
        val stalk = max(2, size.width * 0.045)

        for (index in 0 until bases.size) {
            val base = CGPoint(bases[index] * size.width, size.height * 0.86)
            val tip = CGPoint(base.x + lean[index] * size.width,
                              tops[index] * size.height)
            val bow = CGPoint(base.x, (base.y + tip.y) / 2)

            val blade = UIBezierPath()
            blade.move(base)
            blade.addQuadCurve(tip, bow)
            blade.lineCapStyle = LineCap.round
            BuildingArtwork.stroke(blade, (if (index % 2 == 0) primary else accent), stalk)

            // Cattail heads on alternate stalks.
            if (index % 2 == 0) {
                val headWidth = stalk * 1.9
                val headHeight = stalk * 4.2
                val head = CGRect(tip.x - headWidth / 2,
                                  tip.y - headHeight * 0.1,
                                  headWidth, headHeight)
                BuildingArtwork.fill(UIBezierPath(head, headWidth / 2), secondary)
            }
        }
    }

    // region Water rocks

    // How far each corner of a boulder is pushed in or out, so no two sides
    // match. Fixed rather than random: the same rock must draw the same way
    // every time its texture is rebuilt.
    private val boulderProfile = listOf(1.0, 0.86, 0.96, 0.82, 1.0, 0.88, 0.94, 0.84)

    internal fun drawWaterRock(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        drawWaterPatch(size)
        val reference = min(size.width, size.height)

        // Where each boulder sits, how big it is, and how it is turned.
        val layouts = listOf(
            listOf(Boulder(0.50, 0.52, 0.27, 0.3)),
            listOf(Boulder(0.36, 0.56, 0.22, 0.9), Boulder(0.66, 0.40, 0.16, 2.4), Boulder(0.64, 0.72, 0.11, 4.1)),
            listOf(Boulder(0.26, 0.64, 0.13, 0.5), Boulder(0.50, 0.46, 0.14, 1.7), Boulder(0.74, 0.60, 0.13, 3.2),
             Boulder(0.60, 0.26, 0.09, 4.4))
        )

        for (spot in layouts[variant % layouts.size]) {
            val centre = CGPoint(spot.x * size.width, spot.y * size.height)
            val radius = spot.radius * reference

            // Foam first, so the rock stands in it.
            val wash = CGRect(centre.x - radius * 1.35, centre.y - radius * 1.05,
                              radius * 2.7, radius * 2.1)
            drawRipple(wash, max(1.5, radius * 0.16))

            drawBoulder(context, centre, radius, spot.turn,
                        primary, secondary, accent)
        }
    }

    internal fun drawBoulder(context: CGContext, centre: CGPoint, radius: Double, turn: Double, stone: UIColor, moss: UIColor, foam: UIColor) {
        fun outline(scale: Double, lift: Double): UIBezierPath {
            val path = UIBezierPath()
            val corners = boulderProfile.size
            for (index in 0 until corners) {
                val angle = turn + (index).toDouble() / (corners).toDouble() * PI * 2
                val reach = radius * scale * boulderProfile[index]
                val point = CGPoint(centre.x + cos(angle) * reach,
                                    centre.y + sin(angle) * reach * 0.82 - lift)
                if (index == 0) { path.move(point) } else { path.addLine(point) }
            }
            path.close()
            path.lineJoinStyle = LineJoin.round
            return path
        }

        val body = outline(1.0, 0.0)
        BuildingArtwork.withShadow(context) { BuildingArtwork.fill(body, stone) }
        BuildingArtwork.stroke(body, stone, max(1.5, radius * 0.18))

        // A paler face catching the light, then moss on the top of it.
        BuildingArtwork.fill(outline(0.62, radius * 0.18), UIColor.white.withAlphaComponent(0.28))
        val mossRect = CGRect(centre.x - radius * 0.55, centre.y - radius * 0.62,
                              radius * 0.80, radius * 0.42)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  mossRect), moss.withAlphaComponent(0.85))

        // A fleck of foam where the water breaks on it.
        val splash = CGRect(centre.x + radius * 0.35, centre.y + radius * 0.50,
                            radius * 0.50, radius * 0.20)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  splash), foam.withAlphaComponent(0.85))
    }

    // region Floating lanterns

    internal fun drawFloatingLanterns(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        drawWaterPatch(size)

        val reference = min(size.width, size.height)
        val spots = if (variant % 2 == 0) listOf(Lantern(0.22, 0.56, 1.0), Lantern(0.50, 0.40, 0.8), Lantern(0.78, 0.58, 0.95))
            else listOf(Lantern(0.28, 0.42, 0.9), Lantern(0.52, 0.66, 1.0), Lantern(0.76, 0.40, 0.85))
        val glow = ParkPalette.colour(ParkColour.amber)

        for ((index, spot) in spots.withIndex()) {
            val side = reference * 0.28 * spot.scale
            val centre = CGPoint(spot.x * size.width, spot.y * size.height)

            // The light first, spilling onto the water round it.
            BuildingArtwork.fill(UIBezierPath(ovalIn =  discRect(centre, side * 2.6)),
                 glow.withAlphaComponent(0.20))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  discRect(centre, side * 1.7)),
                 glow.withAlphaComponent(0.30))

            val paper = CGRect(centre.x - side / 2, centre.y - side * 0.45,
                               side, side * 0.9)
            BuildingArtwork.withShadow(context) {
                BuildingArtwork.fill(UIBezierPath(paper, side * 0.3),
 (if (index % 2 == 0) primary else secondary))
            }

            // Ribs, a cap and the flame showing through.
            val rib = UIBezierPath()
            rib.move(CGPoint(centre.x, paper.minY))
            rib.addLine(CGPoint(centre.x, paper.maxY))
            BuildingArtwork.stroke(rib, accent.withAlphaComponent(0.7), max(1, side * 0.06))

            val cap = CGRect(paper.minX + side * 0.18, paper.minY - side * 0.06,
                             side * 0.64, side * 0.14)
            BuildingArtwork.fill(UIBezierPath(cap, side * 0.05),
                 ParkPalette.colour(ParkColour.charcoal))

            val flame = discRect(centre, side * 0.34)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  flame), accent)
        }
    }

    // region Pond fountain

    // The stone ring and pedestal. The jet is drawn on its own so it can
    // pulse, exactly as it is for a fountain on the ground.
    internal fun drawPondFountainBasin(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        drawWaterPatch(size)

        val reference = min(size.width, size.height)
        val ring = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.14, size.height * 0.14)

        BuildingArtwork.withShadow(context) {
            BuildingArtwork.stroke(UIBezierPath(ovalIn =  ring), primary, reference * 0.09)
        }
        BuildingArtwork.stroke(UIBezierPath(ovalIn =  ring), secondary.withAlphaComponent(0.6),
               reference * 0.025)

        // Rings spreading out from the jet.
        val inner = ring.insetBy(ring.width * 0.22, ring.height * 0.22)
        drawRipple(inner, max(1.5, reference * 0.025))
        if (variant % 2 == 1) {
            val tier = ring.insetBy(ring.width * 0.36, ring.height * 0.36)
            BuildingArtwork.stroke(UIBezierPath(ovalIn =  tier), primary, reference * 0.06)
        }

        val pedestal = discRect(CGPoint(size.width / 2, size.height / 2),
                                reference * 0.16)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  pedestal), accent)
    }
}
