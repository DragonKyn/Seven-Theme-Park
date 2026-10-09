package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin


// The three rides that are a structure with one thing moving on them: a mast
// hung with chairs, an arm on a pivot, and a cable between two towers.
//
// Kept out of `BuildingArtwork` because that file is already the longest in
// the project. What these three share is that the structure is most of the
// drawing and the moving part is small, so the static artwork has to imply
// the movement even while the ride is shut.
internal object BuildingArtStructures {

    // region Sky Swings

    // The ring the chairs are flung out on, in texture space. Shared with the
    // motion so the chairs orbit the mast they hang from.
    internal fun swingRingRect(size: CGSize): CGRect {
        val shortest = min(size.width, size.height)
        val radius = shortest * 0.33
        return CGRect(size.width / 2 - radius,
                      size.height / 2 - radius,
                      radius * 2,
                      radius * 2)
    }

    // A round pad with a tapered mast in the middle of it, crowned like a
    // fairground tent. The crown is what says this ride spins: it is the
    // thing the chairs hang from, and it overhangs the pad all the way round.
    internal fun drawSwingChairsBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val inset = min(size.width, size.height) * 0.07
        val pad = CGRect(CGPoint.zero, size).insetBy(inset, inset)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(ovalIn =  pad), secondary)
        }
        BuildingArtwork.stroke(UIBezierPath(ovalIn =  pad.insetBy(pad.width * 0.06, pad.height * 0.06)),
               ParkPalette.colour(ParkColour.white).withAlphaComponent(0.25),
               max(1, size.width * 0.012))

        val centre = CGPoint(pad.midX, pad.midY)

        // Boarding gate on the near edge, so the ride has a front.
        val gate = CGRect(centre.x - pad.width * 0.14,
                          pad.maxY - size.height * 0.05,
                          pad.width * 0.28,
                          size.height * 0.10)
        BuildingArtwork.fill(UIBezierPath(gate, gate.height * 0.35), accent)

        // The crown, drawn as a scalloped disc: twelve valances round a ring,
        // which is the shape of the canopy the chains come off.
        val crown = swingRingRect(size).insetBy(-size.width * 0.02,
                                                    -size.height * 0.02)
        val crownRadius = crown.width / 2
        val scallops = 12
        val valance = UIBezierPath()
        for (index in 0 until scallops) {
            val from = (index).toDouble() / (scallops).toDouble() * PI * 2
            val to = (index + 1).toDouble() / (scallops).toDouble() * PI * 2
            val start = CGPoint(centre.x + cos(from) * crownRadius,
                                centre.y + sin(from) * crownRadius)
            val end = CGPoint(centre.x + cos(to) * crownRadius,
                              centre.y + sin(to) * crownRadius)
            val middle = (from + to) / 2
            val bulge = crownRadius * 1.12
            val control = CGPoint(centre.x + cos(middle) * bulge,
                                  centre.y + sin(middle) * bulge)
            if (index == 0) { valance.move(start) }
            valance.addQuadCurve(end, control)
        }
        valance.close()
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(valance, primary)
        }

        // Alternating panels, the same trick the carousel canopy uses.
        context.saveGState()
        valance.addClip()
        for (index in 0 until scallops step 2) {
            val start = (index).toDouble() / (scallops).toDouble() * PI * 2
            val end = (index + 1).toDouble() / (scallops).toDouble() * PI * 2
            val wedge = UIBezierPath()
            wedge.move(centre)
            wedge.addArc(centre, crownRadius * 1.2,
                         start, end, true)
            wedge.close()
            BuildingArtwork.fill(wedge, ParkPalette.colour(ParkColour.cream))
        }
        context.restoreGState()

        // Mast down through the middle of the crown, and its cap.
        val mastWidth = size.width * 0.055
        val mast = CGRect(centre.x - mastWidth / 2,
                          centre.y - crownRadius * 0.30,
                          mastWidth,
                          crownRadius * 1.05)
        BuildingArtwork.fill(UIBezierPath(mast, mastWidth * 0.4), accent)

        val cap = crownRadius * 0.26
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - cap, centre.y - cap,
                                         cap * 2, cap * 2)), accent)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - cap * 0.45, centre.y - cap * 0.45,
                                         cap * 0.9, cap * 0.9)),
             ParkPalette.colour(ParkColour.cream))
    }

    // One chair on its chains, hanging from the top of its own texture so it
    // stays upright however far round the ring it is.
    internal fun drawSwingChair(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Two chains rather than one, which is what stops the chair reading as
        // a seat on a stick.
        val chains = UIBezierPath()
        for (x in listOf((0.34).toDouble(), (0.66).toDouble())) {
            chains.move(CGPoint(size.width * x, 0))
            chains.addLine(CGPoint(size.width * 0.5, size.height * 0.46))
        }
        BuildingArtwork.stroke(chains, ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.85),
               max(1, size.width * 0.10))

        val seat = CGRect(size.width * 0.10, size.height * 0.44,
                          size.width * 0.80, size.height * 0.40)
        BuildingArtwork.fill(UIBezierPath(seat, seat.height * 0.34), accent)
        BuildingArtwork.fill(UIBezierPath(CGRect(seat.minX, seat.maxY - seat.height * 0.22,
                                       seat.width, seat.height * 0.22)),
             ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.35))

        val head = size.height * 0.26
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(seat.midX - head / 2,
                                         seat.minY - head * 0.42,
                                         head, head)),
             ParkPalette.colour(ParkColour.cream))
    }

    // region Gravity Hammer

    // Where the arm is hung, in texture space.
    internal fun hammerPivot(size: CGSize): CGPoint {
        return CGPoint(size.width / 2, size.height * 0.34)
    }

    // Two heavy towers leaning in to a hub, on a fenced slab. Drawn without
    // the arm: the arm is the moving part, and at rest it hangs straight down
    // the middle of this.
    internal fun drawPendulumArmBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val slab = CGRect(size.width * 0.12, size.height * 0.70,
                          size.width * 0.76, size.height * 0.24)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(slab, slab.height * 0.22), secondary)
        }

        // Hazard stripes across the slab, because this is the one ride with a
        // gondola that comes down through it.
        context.saveGState()
        UIBezierPath(slab, slab.height * 0.22).addClip()
        var x = slab.minX - slab.height
        while (x < slab.maxX + slab.height) {
            val stripe = UIBezierPath()
            stripe.move(CGPoint(x, slab.maxY))
            stripe.addLine(CGPoint(x + slab.height, slab.minY))
            BuildingArtwork.stroke(stripe, accent.withAlphaComponent(0.30), max(2, size.width * 0.022))
            x += size.width * 0.09
        }
        context.restoreGState()

        val pivot = hammerPivot(size)
        val foot = slab.minY + slab.height * 0.30

        // Towers: a leg out to each side, braced, meeting at the hub. Heavier
        // than the chairlift pylons, because this arm weighs something.
        for (direction in listOf((-1).toDouble(), (1).toDouble())) {
            val base = CGPoint(pivot.x + direction * size.width * 0.27, foot)
            val leg = UIBezierPath()
            leg.move(pivot)
            leg.addLine(base)
            BuildingArtwork.stroke(leg, accent, max(2.5, size.width * 0.038))

            // Diagonal bracing up the leg. Three braces read as a lattice; one
            // reads as a mistake.
            val braces = UIBezierPath()
            for (step in 0 until 3) {
                val low = (step).toDouble() * 0.30 + 0.12
                val high = low + 0.26
                val inner = CGPoint(pivot.x + (base.x - pivot.x) * high,
                                    pivot.y + (base.y - pivot.y) * high)
                val outer = CGPoint(pivot.x + (base.x - pivot.x) * low,
                                    pivot.y + (base.y - pivot.y) * low)
                braces.move(inner)
                braces.addLine(CGPoint(pivot.x, outer.y))
                braces.move(outer)
                braces.addLine(CGPoint(pivot.x, inner.y))
            }
            BuildingArtwork.stroke(braces, accent.withAlphaComponent(0.55), max(1, size.width * 0.012))

            val pier = CGRect(base.x - size.width * 0.05, base.y,
                              size.width * 0.10, size.height * 0.08)
            BuildingArtwork.fill(UIBezierPath(pier, pier.height * 0.3),
                 ParkPalette.colour(ParkColour.charcoal))
        }

        // The hub, which is the one part of the ride a queue stares at.
        val hub = size.width * 0.075
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(pivot.x - hub, pivot.y - hub,
                                         hub * 2, hub * 2)), primary)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(pivot.x - hub * 0.38, pivot.y - hub * 0.38,
                                         hub * 0.76, hub * 0.76)),
             ParkPalette.colour(ParkColour.charcoal))
    }

    // The arm and the gondola on the end of it, hung from the top of its own
    // texture so the sprite can be swung about that point.
    internal fun drawPendulumGondola(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Spar, tapering towards the gondola.
        val spar = UIBezierPath()
        spar.move(CGPoint(size.width * 0.38, 0))
        spar.addLine(CGPoint(size.width * 0.62, 0))
        spar.addLine(CGPoint(size.width * 0.56, size.height * 0.66))
        spar.addLine(CGPoint(size.width * 0.44, size.height * 0.66))
        spar.close()
        BuildingArtwork.fill(spar, secondary)

        // A bright rib up the spar, so the arm is legible against the towers
        // it swings through.
        val rib = UIBezierPath()
        rib.move(CGPoint(size.width * 0.5, size.height * 0.04))
        rib.addLine(CGPoint(size.width * 0.5, size.height * 0.64))
        BuildingArtwork.stroke(rib, accent, max(1, size.width * 0.09))

        // Gondola: a shell with a row of riders facing out.
        val car = CGRect(size.width * 0.02, size.height * 0.64,
                         size.width * 0.96, size.height * 0.30)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(car, car.height * 0.38), primary)
        }
        BuildingArtwork.fill(UIBezierPath(CGRect(car.minX, car.midY,
                                       car.width, car.height * 0.5)),
             ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.30))

        val head = car.height * 0.42
        for (offset in listOf((0.24).toDouble(), (0.50).toDouble(), (0.76).toDouble())) {
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(car.minX + car.width * offset - head / 2,
                                             car.minY + car.height * 0.16,
                                             head, head)),
                 ParkPalette.colour(ParkColour.cream))
        }
    }

    // region Treetop Zip

    // The cable, from the top of the launch tower to the landing deck, in
    // texture space. Shared with the motion so the rider hangs off the wire
    // that is drawn.
    internal fun zipCable(size: CGSize): Segment {
        return Segment(CGPoint(size.width * 0.14, size.height * 0.18),
         CGPoint(size.width * 0.88, size.height * 0.52))
    }

    // A tall tower on the left, a taut wire falling away to the right, and a
    // deck at the far end to stop on. The whole ride is a diagonal, which is
    // why it can be tucked along a side path.
    internal fun drawZipLineBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val cable = zipCable(size)

        // Trees under the run. Drawn first, so the wire passes over them and
        // the ride reads as being up in the air.
        for ((x, y, scale) in listOf(Triple(0.34, 0.74, 1.0), Triple(0.46, 0.60, 0.8), Triple(0.60, 0.78, 0.9), Triple(0.72, 0.64, 0.7))) {
            val radius = size.height * 0.10 * (scale).toDouble()
            val centre = CGPoint(size.width * (x).toDouble(), size.height * (y).toDouble())
            val trunk = CGRect(centre.x - radius * 0.14, centre.y,
                               radius * 0.28, radius * 0.8)
            BuildingArtwork.fill(UIBezierPath(trunk), ParkPalette.colour(ParkColour.brown))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius, centre.y - radius,
                                             radius * 2, radius * 1.8)),
                 ParkPalette.colour(ParkColour.green))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius * 0.5,
                                             centre.y - radius * 0.95,
                                             radius, radius * 0.9)),
                 ParkPalette.colour(ParkColour.lime))
        }

        // The wire. A hair of sag, then the wire itself over it.
        val wire = UIBezierPath()
        wire.move(cable.start)
        wire.addQuadCurve(cable.end,
                          CGPoint((cable.start.x + cable.end.x) / 2,
                                                (cable.start.y + cable.end.y) / 2
                                                    + size.height * 0.05))
        BuildingArtwork.stroke(wire, ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.35),
               max(2, size.height * 0.030))
        BuildingArtwork.stroke(wire, ParkPalette.colour(ParkColour.charcoal), max(1, size.height * 0.014))

        // Launch tower: a splayed lattice with a deck on top and a rail round
        // it, because somebody has to stand up there.
        val footY = size.height * 0.88
        val legs = UIBezierPath()
        for (spread in listOf((-0.045).toDouble(), (0.045).toDouble())) {
            legs.move(CGPoint(cable.start.x + size.width * spread * 0.3,
                                  cable.start.y))
            legs.addLine(CGPoint(cable.start.x + size.width * spread, footY))
        }
        for (height in listOf((0.28).toDouble(), (0.54).toDouble(), (0.80).toDouble())) {
            val y = cable.start.y + (footY - cable.start.y) * height
            val half = size.width * 0.045 * height
            legs.move(CGPoint(cable.start.x - half, y))
            legs.addLine(CGPoint(cable.start.x + half, y))
        }
        BuildingArtwork.stroke(legs, secondary, max(1.5, size.width * 0.012))

        val deck = CGRect(cable.start.x - size.width * 0.055,
                          cable.start.y - size.height * 0.06,
                          size.width * 0.11,
                          size.height * 0.07)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(deck, deck.height * 0.3), primary)
        }

        // Pennant on the tower head, the one bit of colour up there.
        val pole = UIBezierPath()
        pole.move(CGPoint(deck.midX, deck.minY))
        pole.addLine(CGPoint(deck.midX, deck.minY - size.height * 0.12))
        BuildingArtwork.stroke(pole, secondary, max(1, size.width * 0.008))
        val flag = UIBezierPath()
        flag.move(CGPoint(deck.midX, deck.minY - size.height * 0.12))
        flag.addLine(CGPoint(deck.midX + size.width * 0.045,
                                 deck.minY - size.height * 0.095))
        flag.addLine(CGPoint(deck.midX, deck.minY - size.height * 0.07))
        flag.close()
        BuildingArtwork.fill(flag, accent)

        // Landing deck: a platform, a braking spring on the wire above it, and
        // a mat to drop onto.
        val landing = CGRect(cable.end.x - size.width * 0.085,
                             cable.end.y + size.height * 0.02,
                             size.width * 0.17,
                             size.height * 0.20)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(landing, landing.height * 0.22),
                 primary)
        }
        BuildingArtwork.fill(UIBezierPath(landing.insetBy(landing.width * 0.16,
                                                       landing.height * 0.26),
                          landing.height * 0.18),
             accent)

        val spring = UIBezierPath()
        val coils = 5
        for (index in 0..coils) {
            val t = (index).toDouble() / (coils).toDouble()
            val point = CGPoint(cable.end.x - size.width * 0.07 + size.width * 0.07 * t,
                                cable.end.y + ( (if (index % 2 == 0) -1 else 1)) * size.height * 0.022)
            if (index == 0) { spring.move(point) } else { spring.addLine(point) }
        }
        BuildingArtwork.stroke(spring, secondary, max(1, size.height * 0.016))
    }

    // A rider on the wire: a trolley at the top of the texture, a harness, and
    // somebody hanging off it with their legs out.
    internal fun drawZipRider(context: CGContext, size: CGSize, variant: Int) {
        val trolley = CGRect(size.width * 0.12, 0,
                             size.width * 0.76, size.height * 0.16)
        BuildingArtwork.fill(UIBezierPath(trolley, trolley.height * 0.35),
             ParkPalette.colour(ParkColour.charcoal))

        val strap = UIBezierPath()
        strap.move(CGPoint(size.width * 0.5, size.height * 0.14))
        strap.addLine(CGPoint(size.width * 0.5, size.height * 0.44))
        BuildingArtwork.stroke(strap, ParkPalette.colour(ParkColour.slate), max(1, size.width * 0.22))

        // Body, leaning back the way anybody does on a zip wire.
        val body = CGRect(size.width * 0.16, size.height * 0.42,
                          size.width * 0.68, size.height * 0.34)
        BuildingArtwork.fill(UIBezierPath(body, body.width * 0.42),
             BuildingArtwork.livery(variant))

        val head = size.width * 0.62
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(body.midX - head / 2,
                                         body.minY - head * 0.72,
                                         head, head)),
             ParkPalette.colour(ParkColour.cream))

        // Legs, kicked forward. Two lines, and they are what make the sprite
        // read as a person rather than as a bag on a wire.
        val legs = UIBezierPath()
        for (x in listOf((0.36).toDouble(), (0.64).toDouble())) {
            legs.move(CGPoint(size.width * x, size.height * 0.74))
            legs.addLine(CGPoint(size.width * (x + 0.22), size.height * 0.96))
        }
        BuildingArtwork.stroke(legs, ParkPalette.colour(ParkColour.charcoal), max(1, size.width * 0.16))
    }
}
