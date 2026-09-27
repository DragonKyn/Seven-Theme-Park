import SpriteKit
import UIKit

/// The three rides that are a structure with one thing moving on them: a mast
/// hung with chairs, an arm on a pivot, and a cable between two towers.
///
/// Kept out of `BuildingArtwork` because that file is already the longest in
/// the project. What these three share is that the structure is most of the
/// drawing and the moving part is small, so the static artwork has to imply
/// the movement even while the ride is shut.
extension BuildingArtwork {

    // MARK: - Sky Swings

    /// The ring the chairs are flung out on, in texture space. Shared with the
    /// motion so the chairs orbit the mast they hang from.
    static func swingRingRect(in size: CGSize) -> CGRect {
        let shortest = min(size.width, size.height)
        let radius = shortest * 0.33
        return CGRect(x: size.width / 2 - radius,
                      y: size.height / 2 - radius,
                      width: radius * 2,
                      height: radius * 2)
    }

    /// A round pad with a tapered mast in the middle of it, crowned like a
    /// fairground tent. The crown is what says this ride spins: it is the
    /// thing the chairs hang from, and it overhangs the pad all the way round.
    static func drawSwingChairsBase(_ context: CGContext,
                                    _ size: CGSize,
                                    _ primary: UIColor,
                                    _ secondary: UIColor,
                                    _ accent: UIColor) {
        let inset = min(size.width, size.height) * 0.07
        let pad = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
        withShadow(context) {
            fill(UIBezierPath(ovalIn: pad), secondary)
        }
        stroke(UIBezierPath(ovalIn: pad.insetBy(dx: pad.width * 0.06, dy: pad.height * 0.06)),
               ParkPalette.colour(.white).withAlphaComponent(0.25),
               width: max(1, size.width * 0.012))

        let centre = CGPoint(x: pad.midX, y: pad.midY)

        // Boarding gate on the near edge, so the ride has a front.
        let gate = CGRect(x: centre.x - pad.width * 0.14,
                          y: pad.maxY - size.height * 0.05,
                          width: pad.width * 0.28,
                          height: size.height * 0.10)
        fill(UIBezierPath(roundedRect: gate, cornerRadius: gate.height * 0.35), accent)

        // The crown, drawn as a scalloped disc: twelve valances round a ring,
        // which is the shape of the canopy the chains come off.
        let crown = swingRingRect(in: size).insetBy(dx: -size.width * 0.02,
                                                    dy: -size.height * 0.02)
        let crownRadius = crown.width / 2
        let scallops = 12
        let valance = UIBezierPath()
        for index in 0..<scallops {
            let from = CGFloat(index) / CGFloat(scallops) * .pi * 2
            let to = CGFloat(index + 1) / CGFloat(scallops) * .pi * 2
            let start = CGPoint(x: centre.x + cos(from) * crownRadius,
                                y: centre.y + sin(from) * crownRadius)
            let end = CGPoint(x: centre.x + cos(to) * crownRadius,
                              y: centre.y + sin(to) * crownRadius)
            let middle = (from + to) / 2
            let bulge = crownRadius * 1.12
            let control = CGPoint(x: centre.x + cos(middle) * bulge,
                                  y: centre.y + sin(middle) * bulge)
            if index == 0 { valance.move(to: start) }
            valance.addQuadCurve(to: end, controlPoint: control)
        }
        valance.close()
        withShadow(context) {
            fill(valance, primary)
        }

        // Alternating panels, the same trick the carousel canopy uses.
        context.saveGState()
        valance.addClip()
        for index in stride(from: 0, to: scallops, by: 2) {
            let start = CGFloat(index) / CGFloat(scallops) * .pi * 2
            let end = CGFloat(index + 1) / CGFloat(scallops) * .pi * 2
            let wedge = UIBezierPath()
            wedge.move(to: centre)
            wedge.addArc(withCenter: centre, radius: crownRadius * 1.2,
                         startAngle: start, endAngle: end, clockwise: true)
            wedge.close()
            fill(wedge, ParkPalette.colour(.cream))
        }
        context.restoreGState()

        // Mast down through the middle of the crown, and its cap.
        let mastWidth = size.width * 0.055
        let mast = CGRect(x: centre.x - mastWidth / 2,
                          y: centre.y - crownRadius * 0.30,
                          width: mastWidth,
                          height: crownRadius * 1.05)
        fill(UIBezierPath(roundedRect: mast, cornerRadius: mastWidth * 0.4), accent)

        let cap = crownRadius * 0.26
        fill(UIBezierPath(ovalIn: CGRect(x: centre.x - cap, y: centre.y - cap,
                                         width: cap * 2, height: cap * 2)), accent)
        fill(UIBezierPath(ovalIn: CGRect(x: centre.x - cap * 0.45, y: centre.y - cap * 0.45,
                                         width: cap * 0.9, height: cap * 0.9)),
             ParkPalette.colour(.cream))
    }

    /// One chair on its chains, hanging from the top of its own texture so it
    /// stays upright however far round the ring it is.
    static func drawSwingChair(_ context: CGContext,
                               _ size: CGSize,
                               _ primary: UIColor,
                               _ secondary: UIColor,
                               _ accent: UIColor) {
        // Two chains rather than one, which is what stops the chair reading as
        // a seat on a stick.
        let chains = UIBezierPath()
        for x in [CGFloat(0.34), CGFloat(0.66)] {
            chains.move(to: CGPoint(x: size.width * x, y: 0))
            chains.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.46))
        }
        stroke(chains, ParkPalette.colour(.charcoal).withAlphaComponent(0.85),
               width: max(1, size.width * 0.10))

        let seat = CGRect(x: size.width * 0.10, y: size.height * 0.44,
                          width: size.width * 0.80, height: size.height * 0.40)
        fill(UIBezierPath(roundedRect: seat, cornerRadius: seat.height * 0.34), accent)
        fill(UIBezierPath(rect: CGRect(x: seat.minX, y: seat.maxY - seat.height * 0.22,
                                       width: seat.width, height: seat.height * 0.22)),
             ParkPalette.colour(.charcoal).withAlphaComponent(0.35))

        let head = size.height * 0.26
        fill(UIBezierPath(ovalIn: CGRect(x: seat.midX - head / 2,
                                         y: seat.minY - head * 0.42,
                                         width: head, height: head)),
             ParkPalette.colour(.cream))
    }

    // MARK: - Gravity Hammer

    /// Where the arm is hung, in texture space.
    static func hammerPivot(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height * 0.34)
    }

    /// Two heavy towers leaning in to a hub, on a fenced slab. Drawn without
    /// the arm: the arm is the moving part, and at rest it hangs straight down
    /// the middle of this.
    static func drawPendulumArmBase(_ context: CGContext,
                                    _ size: CGSize,
                                    _ primary: UIColor,
                                    _ secondary: UIColor,
                                    _ accent: UIColor) {
        let slab = CGRect(x: size.width * 0.12, y: size.height * 0.70,
                          width: size.width * 0.76, height: size.height * 0.24)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: slab, cornerRadius: slab.height * 0.22), secondary)
        }

        // Hazard stripes across the slab, because this is the one ride with a
        // gondola that comes down through it.
        context.saveGState()
        UIBezierPath(roundedRect: slab, cornerRadius: slab.height * 0.22).addClip()
        var x = slab.minX - slab.height
        while x < slab.maxX + slab.height {
            let stripe = UIBezierPath()
            stripe.move(to: CGPoint(x: x, y: slab.maxY))
            stripe.addLine(to: CGPoint(x: x + slab.height, y: slab.minY))
            stroke(stripe, accent.withAlphaComponent(0.30), width: max(2, size.width * 0.022))
            x += size.width * 0.09
        }
        context.restoreGState()

        let pivot = hammerPivot(in: size)
        let foot = slab.minY + slab.height * 0.30

        // Towers: a leg out to each side, braced, meeting at the hub. Heavier
        // than the chairlift pylons, because this arm weighs something.
        for direction in [CGFloat(-1), CGFloat(1)] {
            let base = CGPoint(x: pivot.x + direction * size.width * 0.27, y: foot)
            let leg = UIBezierPath()
            leg.move(to: pivot)
            leg.addLine(to: base)
            stroke(leg, accent, width: max(2.5, size.width * 0.038))

            // Diagonal bracing up the leg. Three braces read as a lattice; one
            // reads as a mistake.
            let braces = UIBezierPath()
            for step in 0..<3 {
                let low = CGFloat(step) * 0.30 + 0.12
                let high = low + 0.26
                let inner = CGPoint(x: pivot.x + (base.x - pivot.x) * high,
                                    y: pivot.y + (base.y - pivot.y) * high)
                let outer = CGPoint(x: pivot.x + (base.x - pivot.x) * low,
                                    y: pivot.y + (base.y - pivot.y) * low)
                braces.move(to: inner)
                braces.addLine(to: CGPoint(x: pivot.x, y: outer.y))
                braces.move(to: outer)
                braces.addLine(to: CGPoint(x: pivot.x, y: inner.y))
            }
            stroke(braces, accent.withAlphaComponent(0.55), width: max(1, size.width * 0.012))

            let pier = CGRect(x: base.x - size.width * 0.05, y: base.y,
                              width: size.width * 0.10, height: size.height * 0.08)
            fill(UIBezierPath(roundedRect: pier, cornerRadius: pier.height * 0.3),
                 ParkPalette.colour(.charcoal))
        }

        // The hub, which is the one part of the ride a queue stares at.
        let hub = size.width * 0.075
        fill(UIBezierPath(ovalIn: CGRect(x: pivot.x - hub, y: pivot.y - hub,
                                         width: hub * 2, height: hub * 2)), primary)
        fill(UIBezierPath(ovalIn: CGRect(x: pivot.x - hub * 0.38, y: pivot.y - hub * 0.38,
                                         width: hub * 0.76, height: hub * 0.76)),
             ParkPalette.colour(.charcoal))
    }

    /// The arm and the gondola on the end of it, hung from the top of its own
    /// texture so the sprite can be swung about that point.
    static func drawPendulumGondola(_ context: CGContext,
                                    _ size: CGSize,
                                    _ primary: UIColor,
                                    _ secondary: UIColor,
                                    _ accent: UIColor) {
        // Spar, tapering towards the gondola.
        let spar = UIBezierPath()
        spar.move(to: CGPoint(x: size.width * 0.38, y: 0))
        spar.addLine(to: CGPoint(x: size.width * 0.62, y: 0))
        spar.addLine(to: CGPoint(x: size.width * 0.56, y: size.height * 0.66))
        spar.addLine(to: CGPoint(x: size.width * 0.44, y: size.height * 0.66))
        spar.close()
        fill(spar, secondary)

        // A bright rib up the spar, so the arm is legible against the towers
        // it swings through.
        let rib = UIBezierPath()
        rib.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.04))
        rib.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.64))
        stroke(rib, accent, width: max(1, size.width * 0.09))

        // Gondola: a shell with a row of riders facing out.
        let car = CGRect(x: size.width * 0.02, y: size.height * 0.64,
                         width: size.width * 0.96, height: size.height * 0.30)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: car, cornerRadius: car.height * 0.38), primary)
        }
        fill(UIBezierPath(rect: CGRect(x: car.minX, y: car.midY,
                                       width: car.width, height: car.height * 0.5)),
             ParkPalette.colour(.charcoal).withAlphaComponent(0.30))

        let head = car.height * 0.42
        for offset in [CGFloat(0.24), CGFloat(0.50), CGFloat(0.76)] {
            fill(UIBezierPath(ovalIn: CGRect(x: car.minX + car.width * offset - head / 2,
                                             y: car.minY + car.height * 0.16,
                                             width: head, height: head)),
                 ParkPalette.colour(.cream))
        }
    }

    // MARK: - Treetop Zip

    /// The cable, from the top of the launch tower to the landing deck, in
    /// texture space. Shared with the motion so the rider hangs off the wire
    /// that is drawn.
    static func zipCable(in size: CGSize) -> (start: CGPoint, end: CGPoint) {
        (CGPoint(x: size.width * 0.14, y: size.height * 0.18),
         CGPoint(x: size.width * 0.88, y: size.height * 0.52))
    }

    /// A tall tower on the left, a taut wire falling away to the right, and a
    /// deck at the far end to stop on. The whole ride is a diagonal, which is
    /// why it can be tucked along a side path.
    static func drawZipLineBase(_ context: CGContext,
                                _ size: CGSize,
                                _ primary: UIColor,
                                _ secondary: UIColor,
                                _ accent: UIColor) {
        let cable = zipCable(in: size)

        // Trees under the run. Drawn first, so the wire passes over them and
        // the ride reads as being up in the air.
        for (x, y, scale) in [(0.34, 0.74, 1.0), (0.46, 0.60, 0.8),
                              (0.60, 0.78, 0.9), (0.72, 0.64, 0.7)] {
            let radius = size.height * 0.10 * CGFloat(scale)
            let centre = CGPoint(x: size.width * CGFloat(x), y: size.height * CGFloat(y))
            let trunk = CGRect(x: centre.x - radius * 0.14, y: centre.y,
                               width: radius * 0.28, height: radius * 0.8)
            fill(UIBezierPath(rect: trunk), ParkPalette.colour(.brown))
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius, y: centre.y - radius,
                                             width: radius * 2, height: radius * 1.8)),
                 ParkPalette.colour(.green))
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius * 0.5,
                                             y: centre.y - radius * 0.95,
                                             width: radius, height: radius * 0.9)),
                 ParkPalette.colour(.lime))
        }

        // The wire. A hair of sag, then the wire itself over it.
        let wire = UIBezierPath()
        wire.move(to: cable.start)
        wire.addQuadCurve(to: cable.end,
                          controlPoint: CGPoint(x: (cable.start.x + cable.end.x) / 2,
                                                y: (cable.start.y + cable.end.y) / 2
                                                    + size.height * 0.05))
        stroke(wire, ParkPalette.colour(.charcoal).withAlphaComponent(0.35),
               width: max(2, size.height * 0.030))
        stroke(wire, ParkPalette.colour(.charcoal), width: max(1, size.height * 0.014))

        // Launch tower: a splayed lattice with a deck on top and a rail round
        // it, because somebody has to stand up there.
        let footY = size.height * 0.88
        let legs = UIBezierPath()
        for spread in [CGFloat(-0.045), CGFloat(0.045)] {
            legs.move(to: CGPoint(x: cable.start.x + size.width * spread * 0.3,
                                  y: cable.start.y))
            legs.addLine(to: CGPoint(x: cable.start.x + size.width * spread, y: footY))
        }
        for height in [CGFloat(0.28), CGFloat(0.54), CGFloat(0.80)] {
            let y = cable.start.y + (footY - cable.start.y) * height
            let half = size.width * 0.045 * height
            legs.move(to: CGPoint(x: cable.start.x - half, y: y))
            legs.addLine(to: CGPoint(x: cable.start.x + half, y: y))
        }
        stroke(legs, secondary, width: max(1.5, size.width * 0.012))

        let deck = CGRect(x: cable.start.x - size.width * 0.055,
                          y: cable.start.y - size.height * 0.06,
                          width: size.width * 0.11,
                          height: size.height * 0.07)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: deck, cornerRadius: deck.height * 0.3), primary)
        }

        // Pennant on the tower head, the one bit of colour up there.
        let pole = UIBezierPath()
        pole.move(to: CGPoint(x: deck.midX, y: deck.minY))
        pole.addLine(to: CGPoint(x: deck.midX, y: deck.minY - size.height * 0.12))
        stroke(pole, secondary, width: max(1, size.width * 0.008))
        let flag = UIBezierPath()
        flag.move(to: CGPoint(x: deck.midX, y: deck.minY - size.height * 0.12))
        flag.addLine(to: CGPoint(x: deck.midX + size.width * 0.045,
                                 y: deck.minY - size.height * 0.095))
        flag.addLine(to: CGPoint(x: deck.midX, y: deck.minY - size.height * 0.07))
        flag.close()
        fill(flag, accent)

        // Landing deck: a platform, a braking spring on the wire above it, and
        // a mat to drop onto.
        let landing = CGRect(x: cable.end.x - size.width * 0.085,
                             y: cable.end.y + size.height * 0.02,
                             width: size.width * 0.17,
                             height: size.height * 0.20)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: landing, cornerRadius: landing.height * 0.22),
                 primary)
        }
        fill(UIBezierPath(roundedRect: landing.insetBy(dx: landing.width * 0.16,
                                                       dy: landing.height * 0.26),
                          cornerRadius: landing.height * 0.18),
             accent)

        let spring = UIBezierPath()
        let coils = 5
        for index in 0...coils {
            let t = CGFloat(index) / CGFloat(coils)
            let point = CGPoint(x: cable.end.x - size.width * 0.07 + size.width * 0.07 * t,
                                y: cable.end.y + (index % 2 == 0 ? -1 : 1) * size.height * 0.022)
            if index == 0 { spring.move(to: point) } else { spring.addLine(to: point) }
        }
        stroke(spring, secondary, width: max(1, size.height * 0.016))
    }

    /// A rider on the wire: a trolley at the top of the texture, a harness, and
    /// somebody hanging off it with their legs out.
    static func drawZipRider(_ context: CGContext, _ size: CGSize, _ variant: Int) {
        let trolley = CGRect(x: size.width * 0.12, y: 0,
                             width: size.width * 0.76, height: size.height * 0.16)
        fill(UIBezierPath(roundedRect: trolley, cornerRadius: trolley.height * 0.35),
             ParkPalette.colour(.charcoal))

        let strap = UIBezierPath()
        strap.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.14))
        strap.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.44))
        stroke(strap, ParkPalette.colour(.slate), width: max(1, size.width * 0.22))

        // Body, leaning back the way anybody does on a zip wire.
        let body = CGRect(x: size.width * 0.16, y: size.height * 0.42,
                          width: size.width * 0.68, height: size.height * 0.34)
        fill(UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.42),
             BuildingArtwork.livery(variant))

        let head = size.width * 0.62
        fill(UIBezierPath(ovalIn: CGRect(x: body.midX - head / 2,
                                         y: body.minY - head * 0.72,
                                         width: head, height: head)),
             ParkPalette.colour(.cream))

        // Legs, kicked forward. Two lines, and they are what make the sprite
        // read as a person rather than as a bag on a wire.
        let legs = UIBezierPath()
        for x in [CGFloat(0.36), CGFloat(0.64)] {
            legs.move(to: CGPoint(x: size.width * x, y: size.height * 0.74))
            legs.addLine(to: CGPoint(x: size.width * (x + 0.22), y: size.height * 0.96))
        }
        stroke(legs, ParkPalette.colour(.charcoal), width: max(1, size.width * 0.16))
    }
}
