package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin


// The two rides that are a channel of water with something loose on it: a
// white-water river and a lantern-lit canal.
//
// Both follow the log flume's rule — one list of points is both the channel
// that gets drawn and the route the boats take — so the water a raft is in is
// always the water on screen. What separates them is pace: the river is rough
// and fast, and the canal is the slowest thing in the park.
internal object BuildingArtWaterCircuits {

    // region Shared channel plotting

    // Samples a run of straights and curves into one closed list of points.
    //
    // Nested helper functions rather than a path object, because the points
    // are needed as points: they are handed to the animation as well as to
    // the drawing.
    internal fun plot(size: CGSize, build: (ChannelPlotter) -> Unit): List<CGPoint> {
        val plotter = ChannelPlotter(size)
        build(plotter)
        return plotter.points
    }

    // Collects sampled points in texture space, in fractions of the building.
    class ChannelPlotter(val size: CGSize) {
        val points = ArrayList<CGPoint>()

        fun at(x: Double, y: Double): CGPoint = CGPoint(x * size.width, y * size.height)

        fun line(from: CGPoint, to: CGPoint, steps: Int) {
            for (step in 0 until steps) {
                val t = (step).toDouble() / (steps).toDouble()
                points.add(CGPoint(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t))
            }
        }

        fun curve(from: CGPoint, control: CGPoint, to: CGPoint, steps: Int) {
            for (step in 0 until steps) {
                val t = (step).toDouble() / (steps).toDouble()
                val inverse: Double = 1 - t
                val startWeight: Double = inverse * inverse
                val controlWeight: Double = 2 * inverse * t
                val endWeight: Double = t * t
                val x: Double = startWeight * from.x + controlWeight * control.x + endWeight * to.x
                val y: Double = startWeight * from.y + controlWeight * control.y + endWeight * to.y
                points.add(CGPoint(x, y))
            }
        }
    }

    // Strokes a closed channel: the bank, the water in it, and a highlight.
    internal fun strokeChannel(points: List<CGPoint>, size: CGSize, bank: UIColor, bankWidth: Double, waterWidth: Double) {
        if (!(points.size > 2)) return
        val channel = UIBezierPath()
        channel.move(points[0])
        for (point in points.drop(1)) { channel.addLine(point) }
        channel.close()

        BuildingArtwork.stroke(channel, bank, bankWidth)
        BuildingArtwork.stroke(channel, ParkPalette.water, waterWidth)
        BuildingArtwork.stroke(channel, ParkPalette.colour(ParkColour.white).withAlphaComponent(0.30),
               max(1, size.height * 0.008))
    }

    // region River Rapids

    // The river, in texture space: out of the station, up through three bends
    // against the current, round the top, and a fast run back down the right
    // bank to the landing.
    internal fun riverRapidsPoints(size: CGSize): List<CGPoint> {
        return plot(size) { river ->
            river.line(river.at(0.12, 0.88), river.at(0.26, 0.90), 5)
            // Up the left side, kinked, so the channel never reads as an oval.
            river.curve(river.at(0.26, 0.90), river.at(0.42, 0.84),
                        river.at(0.40, 0.68), 8)
            river.curve(river.at(0.40, 0.68), river.at(0.38, 0.56),
                        river.at(0.24, 0.50), 8)
            river.curve(river.at(0.24, 0.50), river.at(0.10, 0.42),
                        river.at(0.18, 0.26), 9)
            // Round the top.
            river.curve(river.at(0.18, 0.26), river.at(0.26, 0.10),
                        river.at(0.48, 0.12), 9)
            river.curve(river.at(0.48, 0.12), river.at(0.66, 0.14),
                        river.at(0.72, 0.26), 8)
            // Down the right bank, with a hook in it.
            river.curve(river.at(0.72, 0.26), river.at(0.80, 0.38),
                        river.at(0.66, 0.46), 8)
            river.curve(river.at(0.66, 0.46), river.at(0.84, 0.54),
                        river.at(0.88, 0.68), 9)
            river.curve(river.at(0.88, 0.68), river.at(0.90, 0.84),
                        river.at(0.74, 0.90), 8)
            river.line(river.at(0.74, 0.90), river.at(0.26, 0.92), 10)
            river.curve(river.at(0.26, 0.92), river.at(0.06, 0.94),
                        river.at(0.12, 0.88), 5)
        }
    }

    // Grass, a rocky river cut into it, white water on the bends, and a
    // boarding station at the bottom. No slab: the park's own ground runs up
    // to the bank, the way it does under the flume.
    internal fun drawRiverRapidsBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val points = riverRapidsPoints(size)

        // Planting first, so the bank overlaps it rather than the other way
        // round.
        for ((x, y, scale) in listOf(Triple(0.30, 0.76, 1.0), Triple(0.55, 0.36, 0.9), Triple(0.52, 0.62, 0.8), Triple(0.08, 0.66, 0.9), Triple(0.34, 0.30, 0.7), Triple(0.80, 0.42, 0.8), Triple(0.94, 0.52, 0.7), Triple(0.62, 0.72, 0.9), Triple(0.46, 0.50, 0.6))) {
            val radius = size.height * 0.055 * (scale).toDouble()
            val centre = CGPoint(size.width * (x).toDouble(), size.height * (y).toDouble())
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius,
                                             centre.y - radius * 0.85,
                                             radius * 2, radius * 1.7)),
                 ParkPalette.colour(ParkColour.green))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius * 0.55,
                                             centre.y - radius * 1.05,
                                             radius * 1.1, radius)),
                 ParkPalette.colour(ParkColour.lime))
        }

        strokeChannel(points, size,
                      secondary,
                      max(4, size.height * 0.130),
                      max(2, size.height * 0.095))

        // Rocks in the stream, and the broken water round them. Fixed
        // positions, so the same river always looks the same.
        for ((index, spot) in listOf(Pair(0.30, 0.79), Pair(0.21, 0.38), Pair(0.60, 0.13), Pair(0.71, 0.36), Pair(0.87, 0.78)).withIndex()) {
            val centre = CGPoint(size.width * (spot.first).toDouble(),
                                 size.height * (spot.second).toDouble())
            val radius = size.height * ( (if (index % 2 == 0) 0.022 else 0.018))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius, centre.y - radius,
                                             radius * 2, radius * 1.7)),
                 ParkPalette.rockShade)

            val foam = UIBezierPath()
            for (step in 0 until 3) {
                val spread = (step).toDouble() - 1
                foam.move(CGPoint(centre.x + spread * radius * 1.3,
                                      centre.y + radius * 1.1))
                foam.addLine(CGPoint(centre.x + spread * radius * 1.8,
                                         centre.y + radius * 2.4))
            }
            BuildingArtwork.stroke(foam, ParkPalette.colour(ParkColour.white).withAlphaComponent(0.75),
                   max(1, size.height * 0.009))
        }

        // Riffles down the channel, so still paint reads as moving water.
        val riffles = UIBezierPath()
        for ((index, point) in points.withIndex()) {
            if (!(index % 9 == 0)) continue
            riffles.move(CGPoint(point.x - size.width * 0.012, point.y))
            riffles.addLine(CGPoint(point.x + size.width * 0.012, point.y))
        }
        BuildingArtwork.stroke(riffles, ParkPalette.colour(ParkColour.white).withAlphaComponent(0.45),
               max(1, size.height * 0.008))

        // Station across the bottom-left, where the rafts are pulled in.
        val station = CGRect(size.width * 0.06, size.height * 0.78,
                             size.width * 0.20, size.height * 0.14)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(station, station.height * 0.28),
                 primary)
        }
        BuildingArtwork.fill(UIBezierPath(CGRect(station.minX, station.minY,
                                       station.width, station.height * 0.32)),
             accent)
    }

    // A raft from above: an inflated ring with riders round the rim, facing
    // outward, because a round raft has no front.
    internal fun drawRaft(context: CGContext, size: CGSize, variant: Int) {
        val ring = CGRect(CGPoint.zero, size).insetBy(0.5, 0.5)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  ring), BuildingArtwork.livery(variant))

        val well = ring.insetBy(ring.width * 0.24, ring.height * 0.24)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  well),
             ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.45))

        // Six riders round the ring.
        val head = min(ring.width, ring.height) * 0.20
        val orbit = min(ring.width, ring.height) * 0.32
        val centre = CGPoint(ring.midX, ring.midY)
        for (index in 0 until 6) {
            val angle = (index).toDouble() / 6 * PI * 2
            val point = CGPoint(centre.x + cos(angle) * orbit,
                                centre.y + sin(angle) * orbit)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(point.x - head / 2, point.y - head / 2,
                                             head, head)),
                 ParkPalette.colour(ParkColour.cream))
        }
    }

    // region Lantern Cruise

    // The canal, in texture space: a rounded loop across the lower two thirds
    // of the plot, passing under the arch of the show building at the top left
    // and back out along the front.
    internal fun lanternCanalPoints(size: CGSize): List<CGPoint> {
        return plot(size) { canal ->
            canal.line(canal.at(0.14, 0.86), canal.at(0.80, 0.88), 14)
            canal.curve(canal.at(0.80, 0.88), canal.at(0.92, 0.88),
                        canal.at(0.90, 0.72), 6)
            canal.curve(canal.at(0.90, 0.72), canal.at(0.88, 0.56),
                        canal.at(0.74, 0.54), 7)
            canal.line(canal.at(0.74, 0.54), canal.at(0.34, 0.50), 9)
            canal.curve(canal.at(0.34, 0.50), canal.at(0.18, 0.48),
                        canal.at(0.16, 0.62), 7)
            canal.curve(canal.at(0.16, 0.62), canal.at(0.10, 0.78),
                        canal.at(0.14, 0.86), 6)
        }
    }

    // A show building along the back, a lantern-lit canal in front of it, and
    // a jetty on the near side. The lanterns are the whole idea of the ride:
    // strung over the water, on posts along the bank, and lit in the arch the
    // boats come out of.
    internal fun drawLanternCruiseBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Show building across the back.
        val hall = CGRect(size.width * 0.08, size.height * 0.06,
                          size.width * 0.84, size.height * 0.36)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(hall, hall.height * 0.14), primary)
        }

        // A gabled roofline, drawn as three shallow peaks along the top.
        val roof = UIBezierPath()
        roof.move(CGPoint(hall.minX, hall.minY + hall.height * 0.30))
        for (index in 0 until 3) {
            val span = hall.width / 3
            val startX = hall.minX + span * (index).toDouble()
            roof.addLine(CGPoint(startX + span / 2,
                                     hall.minY - hall.height * 0.14))
            roof.addLine(CGPoint(startX + span,
                                     hall.minY + hall.height * 0.30))
        }
        roof.close()
        BuildingArtwork.fill(roof, secondary)

        // The arch the boats come out of, and the light inside it.
        val arch = CGRect(hall.minX + hall.width * 0.10,
                          hall.maxY - hall.height * 0.46,
                          hall.width * 0.22,
                          hall.height * 0.52)
        val mouth = UIBezierPath(arch, arch.width * 0.45)
        BuildingArtwork.fill(mouth, ParkPalette.colour(ParkColour.charcoal))
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(arch.midX - arch.width * 0.20,
                                         arch.minY + arch.height * 0.18,
                                         arch.width * 0.40,
                                         arch.width * 0.40)),
             accent.withAlphaComponent(0.75))

        // Windows along the rest of the facade, lit.
        val windowWidth = hall.width * 0.075
        for (index in 0 until 4) {
            val x = hall.minX + hall.width * (0.42 + 0.14 * (index).toDouble())
            val pane = CGRect(x, hall.maxY - hall.height * 0.40,
                              windowWidth, hall.height * 0.30)
            BuildingArtwork.fill(UIBezierPath(pane, pane.width * 0.35),
                 accent.withAlphaComponent(0.85))
        }

        val points = lanternCanalPoints(size)
        strokeChannel(points, size,
                      ParkPalette.colour(ParkColour.cream),
                      max(4, size.height * 0.110),
                      max(2, size.height * 0.075))

        // Lantern posts along the outer bank, each with its own glow. Taken
        // off the canal itself, so they space themselves round the loop rather
        // than needing positions of their own.
        for ((index, point) in points.withIndex()) {
            if (!(index % 12 == 0)) continue
            val post = UIBezierPath()
            post.move(CGPoint(point.x, point.y + size.height * 0.055))
            post.addLine(CGPoint(point.x, point.y + size.height * 0.085))
            BuildingArtwork.stroke(post, ParkPalette.colour(ParkColour.brown), max(1, size.width * 0.008))

            val bulb = size.height * 0.024
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(point.x - bulb,
                                             point.y + size.height * 0.040,
                                             bulb * 2, bulb * 2)),
                 accent.withAlphaComponent(0.35))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(point.x - bulb * 0.5,
                                             point.y + size.height * 0.050,
                                             bulb, bulb)),
                 accent)
        }

        // A string of bunting lanterns across the middle of the loop, over the
        // water, which is what the guests in the boats look up at.
        val string = UIBezierPath()
        val left = CGPoint(size.width * 0.20, size.height * 0.66)
        val right = CGPoint(size.width * 0.82, size.height * 0.70)
        string.move(left)
        string.addQuadCurve(right,
                            CGPoint(size.width * 0.5,
                                                  size.height * 0.78))
        BuildingArtwork.stroke(string, ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.45),
               max(1, size.height * 0.007))
        for (index in 0 until 5) {
            val t = (index + 1).toDouble() / 6
            val inverse: Double = 1 - t
            val startWeight: Double = inverse * inverse
            val controlWeight: Double = 2 * inverse * t
            val endWeight: Double = t * t
            val x: Double = startWeight * left.x + controlWeight * size.width * 0.5
                + endWeight * right.x
            val y: Double = startWeight * left.y + controlWeight * size.height * 0.78
                + endWeight * right.y
            val bulb = size.height * 0.020
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(x - bulb, y,
                                             bulb * 2, bulb * 2.4)),
 (if (index % 2 == 0) accent else ParkPalette.colour(ParkColour.pink)))
        }

        // Jetty on the near bank, where the queue steps into a boat.
        val jetty = CGRect(size.width * 0.20, size.height * 0.88,
                           size.width * 0.26, size.height * 0.09)
        BuildingArtwork.fill(UIBezierPath(jetty, jetty.height * 0.3),
             ParkPalette.colour(ParkColour.brown))
    }

    // A canal boat, prow to the right, with a lantern on a pole at the front
    // and passengers sitting down the middle.
    internal fun drawCanalBoat(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val hull = UIBezierPath()
        val top = size.height * 0.20
        val bottom = size.height * 0.80
        hull.move(CGPoint(size.width * 0.06, top))
        hull.addLine(CGPoint(size.width * 0.70, top))
        hull.addQuadCurve(CGPoint(size.width * 0.70, bottom),
                          CGPoint(size.width * 1.08, size.height * 0.5))
        hull.addLine(CGPoint(size.width * 0.06, bottom))
        hull.addQuadCurve(CGPoint(size.width * 0.06, top),
                          CGPoint(size.width * -0.06, size.height * 0.5))
        hull.close()
        BuildingArtwork.fill(hull, ParkPalette.colour(ParkColour.brown))

        val well = CGRect(size.width * 0.14, size.height * 0.34,
                          size.width * 0.54, size.height * 0.32)
        BuildingArtwork.fill(UIBezierPath(well, well.height * 0.4), secondary)

        val head = size.height * 0.26
        for (offset in listOf((0.22).toDouble(), (0.40).toDouble(), (0.58).toDouble())) {
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * offset,
                                             size.height * 0.5 - head / 2,
                                             head, head)),
                 ParkPalette.colour(ParkColour.cream))
        }

        // The lantern at the prow. Small, bright, and the reason the ride has
        // its name.
        val bulb = size.height * 0.16
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.80 - bulb,
                                         size.height * 0.5 - bulb,
                                         bulb * 2, bulb * 2)),
             accent.withAlphaComponent(0.40))
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.80 - bulb * 0.5,
                                         size.height * 0.5 - bulb * 0.5,
                                         bulb, bulb)),
             accent)
    }
}
