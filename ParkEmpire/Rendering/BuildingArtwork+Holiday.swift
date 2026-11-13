import SpriteKit
import UIKit

/// Artwork for the holiday event: eleven rides, eight decorations, and the
/// dressing a ride wears after a makeover.
///
/// Drawn the way everything else is, from bezier paths, so there are still no
/// image assets in the project. Texture space runs y downward from the
/// top-left.
extension BuildingArtwork {

    // MARK: - Shared pieces

    private static var snowWhite: UIColor { UIColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1) }
    private static var festiveGold: UIColor { UIColor(red: 1.0, green: 0.82, blue: 0.28, alpha: 1) }
    private static var bulbColours: [UIColor] {
        [UIColor(red: 0.92, green: 0.23, blue: 0.22, alpha: 1),
         UIColor(red: 1.0, green: 0.78, blue: 0.22, alpha: 1),
         UIColor(red: 0.28, green: 0.78, blue: 0.42, alpha: 1),
         UIColor(red: 0.35, green: 0.72, blue: 0.96, alpha: 1)]
    }

    /// A five-pointed star, for tree tops and sparks.
    static func starPath(centre: CGPoint, outer: CGFloat, inner: CGFloat, points: Int = 5) -> UIBezierPath {
        let path = UIBezierPath()
        let total = points * 2
        for index in 0..<total {
            let radius = index % 2 == 0 ? outer : inner
            let angle = -CGFloat.pi / 2 + CGFloat(index) / CGFloat(total) * .pi * 2
            let point = CGPoint(x: centre.x + cos(angle) * radius,
                                y: centre.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.close()
        return path
    }

    /// A small burst of spokes, the shape of a firework going off.
    static func burst(_ centre: CGPoint, radius: CGFloat, spokes: Int, colour: UIColor, width: CGFloat) {
        let path = UIBezierPath()
        for index in 0..<spokes {
            let angle = CGFloat(index) / CGFloat(spokes) * .pi * 2
            path.move(to: CGPoint(x: centre.x + cos(angle) * radius * 0.35,
                                  y: centre.y + sin(angle) * radius * 0.35))
            path.addLine(to: CGPoint(x: centre.x + cos(angle) * radius,
                                     y: centre.y + sin(angle) * radius))
        }
        stroke(path, colour, width: width)
    }

    /// A drift of snow: a pale mound with a shadowed underside.
    static func snowMound(_ rect: CGRect) {
        fill(UIBezierPath(ovalIn: rect.offsetBy(dx: 0, dy: rect.height * 0.14)),
             UIColor(red: 0.74, green: 0.82, blue: 0.93, alpha: 1))
        fill(UIBezierPath(ovalIn: rect), snowWhite)
    }

    /// A string of bulbs between two points, hanging in a shallow curve.
    static func lightString(from start: CGPoint, to end: CGPoint, sag: CGFloat, bulbs: Int, size: CGFloat) {
        let wire = UIBezierPath()
        wire.move(to: start)
        wire.addQuadCurve(to: end, controlPoint: CGPoint(x: (start.x + end.x) / 2,
                                                        y: (start.y + end.y) / 2 + sag * 2))
        stroke(wire, UIColor(white: 0.15, alpha: 0.85), width: max(0.8, size * 0.35))

        let colours = bulbColours
        for index in 0..<bulbs {
            let t = (CGFloat(index) + 0.5) / CGFloat(bulbs)
            // The point on the curve, with the sag worked out for that t.
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t + sag * 4 * t * (1 - t)
            fill(UIBezierPath(ovalIn: CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)),
                 colours[index % colours.count])
        }
    }

    // MARK: - Makeover

    /// What a ride wears after its holiday makeover: a swag of lights across
    /// the top, drifts of snow at its feet and a red bow. The same dressing goes
    /// on every ride, so it is drawn to the size of whatever it is put on.
    static func drawHolidayDressing(_ context: CGContext, _ size: CGSize) {
        let unit = min(size.width, size.height)

        // Snow banked up at the feet, left and right, with a few specks.
        snowMound(CGRect(x: -size.width * 0.04, y: size.height * 0.86,
                         width: size.width * 0.34, height: size.height * 0.15))
        snowMound(CGRect(x: size.width * 0.70, y: size.height * 0.88,
                         width: size.width * 0.34, height: size.height * 0.14))
        snowMound(CGRect(x: size.width * 0.36, y: size.height * 0.94,
                         width: size.width * 0.26, height: size.height * 0.08))

        // Lights in two swags across the upper part.
        let bulb = max(2, unit * 0.045)
        lightString(from: CGPoint(x: size.width * 0.08, y: size.height * 0.12),
                    to: CGPoint(x: size.width * 0.50, y: size.height * 0.12),
                    sag: size.height * 0.05, bulbs: 6, size: bulb)
        lightString(from: CGPoint(x: size.width * 0.50, y: size.height * 0.12),
                    to: CGPoint(x: size.width * 0.92, y: size.height * 0.12),
                    sag: size.height * 0.05, bulbs: 6, size: bulb)

        // A red bow with two tails, low on the left.
        let bow = CGPoint(x: size.width * 0.14, y: size.height * 0.78)
        let loop = unit * 0.07
        let red = UIColor(red: 0.86, green: 0.16, blue: 0.20, alpha: 1)
        for direction in [CGFloat(-1), CGFloat(1)] {
            fill(UIBezierPath(ovalIn: CGRect(x: bow.x + direction * loop * 0.9 - loop * 0.9,
                                             y: bow.y - loop * 0.6, width: loop * 1.8, height: loop * 1.2)), red)
        }
        fill(UIBezierPath(ovalIn: CGRect(x: bow.x - loop * 0.4, y: bow.y - loop * 0.4,
                                         width: loop * 0.8, height: loop * 0.8)),
             UIColor(red: 0.62, green: 0.08, blue: 0.12, alpha: 1))
        for direction in [CGFloat(-1), CGFloat(1)] {
            let tail = UIBezierPath()
            tail.move(to: bow)
            tail.addLine(to: CGPoint(x: bow.x + direction * loop * 0.7, y: bow.y + loop * 2))
            stroke(tail, red, width: max(1.2, unit * 0.025))
        }

        // A couple of sparkles.
        burst(CGPoint(x: size.width * 0.86, y: size.height * 0.30), radius: unit * 0.06,
              spokes: 4, colour: festiveGold, width: max(0.8, unit * 0.014))
        burst(CGPoint(x: size.width * 0.20, y: size.height * 0.42), radius: unit * 0.05,
              spokes: 4, colour: snowWhite, width: max(0.8, unit * 0.014))
    }

    // MARK: - Rides: Christmas

    static func drawReindeerCarouselBase(_ context: CGContext, _ size: CGSize,
                                         _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let inset = min(size.width, size.height) * 0.08
        let platform = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)

        withShadow(context) {
            fill(UIBezierPath(ovalIn: platform), secondary)
        }
        stroke(UIBezierPath(ovalIn: platform), accent, width: max(1.5, size.width * 0.035))
        stroke(UIBezierPath(ovalIn: platform.insetBy(dx: platform.width * 0.045, dy: platform.width * 0.045)),
               primary, width: max(1, size.width * 0.018))

        // Eight reindeer round the ring: a brown body, a pair of antlers and
        // every other one with a red nose.
        let radius = platform.width * 0.34
        let centre = CGPoint(x: platform.midX, y: platform.midY)
        let brown = ParkPalette.colour(.brown)
        for index in 0..<8 {
            let angle = CGFloat(index) / 8 * .pi * 2
            let point = CGPoint(x: centre.x + cos(angle) * radius, y: centre.y + sin(angle) * radius)
            let body = platform.width * 0.10
            fill(UIBezierPath(ovalIn: CGRect(x: point.x - body / 2, y: point.y - body / 2,
                                             width: body, height: body)), brown)
            let antlers = UIBezierPath()
            for side in [CGFloat(-1), CGFloat(1)] {
                antlers.move(to: CGPoint(x: point.x + side * body * 0.2, y: point.y - body * 0.4))
                antlers.addLine(to: CGPoint(x: point.x + side * body * 0.7, y: point.y - body * 0.95))
                antlers.move(to: CGPoint(x: point.x + side * body * 0.45, y: point.y - body * 0.7))
                antlers.addLine(to: CGPoint(x: point.x + side * body * 0.95, y: point.y - body * 0.7))
            }
            stroke(antlers, ParkPalette.colour(.cream), width: max(0.8, body * 0.14))
            if index % 2 == 0 {
                let nose = body * 0.28
                fill(UIBezierPath(ovalIn: CGRect(x: point.x - nose / 2, y: point.y + body * 0.05,
                                                 width: nose, height: nose)), primary)
            }
        }

        // A green pole with a gold star over the middle.
        let pole = platform.width * 0.10
        fill(UIBezierPath(ovalIn: CGRect(x: centre.x - pole / 2, y: centre.y - pole / 2,
                                         width: pole, height: pole)), accent)
    }

    /// The red and green canopy, with snow along its rim and a star at the
    /// peak. Drawn square so it spins about its middle.
    static func drawReindeerCanopy(_ context: CGContext, _ size: CGSize,
                                   _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let circle = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
        let centre = CGPoint(x: circle.midX, y: circle.midY)
        let radius = circle.width / 2

        context.saveGState()
        UIBezierPath(ovalIn: circle).addClip()
        let segments = 12
        for index in 0..<segments {
            let start = CGFloat(index) / CGFloat(segments) * .pi * 2
            let end = CGFloat(index + 1) / CGFloat(segments) * .pi * 2
            let wedge = UIBezierPath()
            wedge.move(to: centre)
            wedge.addArc(withCenter: centre, radius: radius, startAngle: start, endAngle: end, clockwise: true)
            wedge.close()
            fill(wedge, index % 2 == 0 ? primary : accent)
        }
        context.restoreGState()

        // Snow along the rim.
        stroke(UIBezierPath(ovalIn: circle.insetBy(dx: radius * 0.06, dy: radius * 0.06)),
               snowWhite, width: max(1.5, radius * 0.14))
        fill(starPath(centre: centre, outer: radius * 0.24, inner: radius * 0.10), festiveGold)
    }

    static func drawSleighRideBase(_ context: CGContext, _ size: CGSize,
                                   _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let track = trackRect(in: size)

        // A snowy hill the track runs round.
        let hill = track.insetBy(dx: -size.width * 0.06, dy: -size.height * 0.08)
        withShadow(context) {
            fill(UIBezierPath(ovalIn: hill), snowWhite)
        }
        fill(UIBezierPath(ovalIn: track.insetBy(dx: track.width * 0.18, dy: track.height * 0.18)),
             UIColor(red: 0.88, green: 0.93, blue: 0.99, alpha: 1))

        // The track: dark ties, a green rail.
        stroke(UIBezierPath(ovalIn: track), ParkPalette.coasterTie, width: max(2.5, size.height * 0.085))
        stroke(UIBezierPath(ovalIn: track), secondary, width: max(1.5, size.height * 0.04))

        // Four firs on the hill, each with snow on its shoulders.
        let spots: [(CGFloat, CGFloat)] = [(0.36, 0.42), (0.50, 0.55), (0.62, 0.40), (0.52, 0.30)]
        for (fx, fy) in spots {
            let centre = CGPoint(x: size.width * fx, y: size.height * fy)
            let height = size.height * 0.16
            let fir = UIBezierPath()
            fir.move(to: CGPoint(x: centre.x, y: centre.y - height / 2))
            fir.addLine(to: CGPoint(x: centre.x + height * 0.32, y: centre.y + height / 2))
            fir.addLine(to: CGPoint(x: centre.x - height * 0.32, y: centre.y + height / 2))
            fir.close()
            fill(fir, ParkPalette.colour(.green))
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - height * 0.14, y: centre.y - height * 0.40,
                                             width: height * 0.28, height: height * 0.22)), snowWhite)
        }

        // The boarding hut, red with a white roof.
        let hut = CGRect(x: track.midX - size.width * 0.12, y: track.maxY - size.height * 0.05,
                         width: size.width * 0.24, height: size.height * 0.15)
        fill(UIBezierPath(roundedRect: hut, cornerRadius: hut.height * 0.25), primary)
        fill(UIBezierPath(roundedRect: CGRect(x: hut.minX - hut.width * 0.04, y: hut.minY - hut.height * 0.10,
                                              width: hut.width * 1.08, height: hut.height * 0.34),
                          cornerRadius: hut.height * 0.17), snowWhite)
    }

    /// One sleigh, facing right: a red body with a curled front, gold runners
    /// and two riders.
    static func drawSleigh(_ context: CGContext, _ size: CGSize,
                           _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let runner = UIBezierPath()
        runner.move(to: CGPoint(x: size.width * 0.06, y: size.height * 0.88))
        runner.addLine(to: CGPoint(x: size.width * 0.80, y: size.height * 0.88))
        runner.addQuadCurve(to: CGPoint(x: size.width * 0.96, y: size.height * 0.62),
                            controlPoint: CGPoint(x: size.width * 0.98, y: size.height * 0.90))
        stroke(runner, festiveGold, width: max(1, size.height * 0.10))

        let body = UIBezierPath()
        body.move(to: CGPoint(x: size.width * 0.10, y: size.height * 0.26))
        body.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.26))
        body.addQuadCurve(to: CGPoint(x: size.width * 0.94, y: size.height * 0.46),
                          controlPoint: CGPoint(x: size.width * 0.90, y: size.height * 0.28))
        body.addLine(to: CGPoint(x: size.width * 0.82, y: size.height * 0.76))
        body.addLine(to: CGPoint(x: size.width * 0.12, y: size.height * 0.76))
        body.close()
        fill(body, primary)

        stroke(UIBezierPath(rect: CGRect(x: size.width * 0.12, y: size.height * 0.50,
                                         width: size.width * 0.70, height: 0)),
               festiveGold, width: max(0.8, size.height * 0.07))

        let head = size.height * 0.32
        for offset in [CGFloat(0.26), CGFloat(0.56)] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * offset, y: size.height * 0.06,
                                             width: head, height: head)),
                 offset < 0.4 ? snowWhite : ParkPalette.colour(.cream))
        }
    }

    static func drawCandyCoasterBase(_ context: CGContext, _ size: CGSize,
                                     _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let track = trackRect(in: size)

        // Candy-cane columns round the outside.
        let columns = UIBezierPath()
        for index in 0..<10 {
            let angle = CGFloat(index) / 10 * .pi * 2
            let point = CGPoint(x: track.midX + cos(angle) * track.width / 2,
                                y: track.midY + sin(angle) * track.height / 2)
            columns.move(to: point)
            columns.addLine(to: CGPoint(x: point.x, y: point.y + size.height * 0.07))
        }
        stroke(columns, ParkPalette.colour(.cream), width: max(1.5, size.width * 0.016))

        stroke(UIBezierPath(ovalIn: track), ParkPalette.coasterTie, width: max(2.5, size.height * 0.090))
        stripedOval(track, first: primary, second: secondary, segments: 44, width: max(1.8, size.height * 0.050))

        // A gingerbread-coloured station with a striped roof.
        let station = CGRect(x: track.midX - size.width * 0.13, y: track.maxY - size.height * 0.06,
                             width: size.width * 0.26, height: size.height * 0.16)
        fill(UIBezierPath(roundedRect: station, cornerRadius: station.height * 0.3), accent)
        fill(UIBezierPath(roundedRect: CGRect(x: station.minX, y: station.minY,
                                              width: station.width, height: station.height * 0.30),
                          cornerRadius: station.height * 0.15), primary)
    }

    /// An oval stroked in alternating colours, like a barber's pole bent into a loop.
    static func stripedOval(_ rect: CGRect, first: UIColor, second: UIColor, segments: Int, width: CGFloat) {
        for index in 0..<segments {
            let a0 = CGFloat(index) / CGFloat(segments) * .pi * 2
            let a1 = CGFloat(index + 1) / CGFloat(segments) * .pi * 2
            let piece = UIBezierPath()
            piece.move(to: CGPoint(x: rect.midX + cos(a0) * rect.width / 2, y: rect.midY + sin(a0) * rect.height / 2))
            piece.addLine(to: CGPoint(x: rect.midX + cos(a1) * rect.width / 2, y: rect.midY + sin(a1) * rect.height / 2))
            stroke(piece, index % 2 == 0 ? first : second, width: width)
        }
    }

    static func drawSnowGlobeBase(_ context: CGContext, _ size: CGSize,
                                  _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let inset = min(size.width, size.height) * 0.07
        let dome = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)

        withShadow(context) {
            fill(UIBezierPath(ovalIn: dome), secondary.withAlphaComponent(0.92))
        }
        fill(UIBezierPath(ovalIn: dome.insetBy(dx: dome.width * 0.06, dy: dome.width * 0.06)),
             primary.withAlphaComponent(0.30))
        stroke(UIBezierPath(ovalIn: dome), primary, width: max(1.5, size.width * 0.03))

        // Snow falling inside the glass.
        let flakes: [(CGFloat, CGFloat)] = [(0.30, 0.26), (0.62, 0.22), (0.74, 0.46), (0.22, 0.58),
                                            (0.46, 0.70), (0.68, 0.74), (0.38, 0.40)]
        for (fx, fy) in flakes {
            let r = size.width * 0.018
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * fx - r, y: size.height * fy - r,
                                             width: r * 2, height: r * 2)), snowWhite)
        }

        // A glint on the glass.
        let glint = UIBezierPath(arcCenter: CGPoint(x: dome.midX, y: dome.midY), radius: dome.width * 0.40,
                                 startAngle: .pi * 1.1, endAngle: .pi * 1.4, clockwise: true)
        stroke(glint, UIColor.white.withAlphaComponent(0.8), width: max(1.2, size.width * 0.03))

        // A red base ring with a white band.
        let base = CGRect(x: size.width * 0.18, y: size.height * 0.86, width: size.width * 0.64, height: size.height * 0.10)
        fill(UIBezierPath(roundedRect: base, cornerRadius: base.height * 0.4), accent)
        fill(UIBezierPath(rect: CGRect(x: base.minX + base.width * 0.1, y: base.midY - base.height * 0.08,
                                       width: base.width * 0.8, height: base.height * 0.16)), snowWhite)
    }

    /// The spinning pods: four round cabins with a white lid each.
    static func drawSnowGlobePods(_ context: CGContext, _ size: CGSize,
                                  _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let pod = size.width * 0.26
        for index in 0..<4 {
            let angle = CGFloat(index) / 4 * .pi * 2 + .pi / 4
            let point = CGPoint(x: centre.x + cos(angle) * size.width * 0.28,
                                y: centre.y + sin(angle) * size.height * 0.28)
            let rect = CGRect(x: point.x - pod / 2, y: point.y - pod / 2, width: pod, height: pod)
            withShadow(context) {
                fill(UIBezierPath(ovalIn: rect), accent)
            }
            fill(UIBezierPath(ovalIn: rect.insetBy(dx: pod * 0.18, dy: pod * 0.18)), snowWhite)
            fill(UIBezierPath(ovalIn: CGRect(x: point.x - pod * 0.08, y: point.y - pod * 0.08,
                                             width: pod * 0.16, height: pod * 0.16)), accent)
        }
        let hub = size.width * 0.16
        fill(UIBezierPath(ovalIn: CGRect(x: centre.x - hub / 2, y: centre.y - hub / 2, width: hub, height: hub)),
             festiveGold)
    }

    static func drawPolarExpressBase(_ context: CGContext, _ size: CGSize,
                                     _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let track = trackRect(in: size)

        // Snow under the ring.
        let ground = track.insetBy(dx: -size.width * 0.05, dy: -size.height * 0.07)
        fill(UIBezierPath(ovalIn: ground), snowWhite)

        stroke(UIBezierPath(ovalIn: track), ParkPalette.coasterTie, width: max(2.5, size.height * 0.085))
        stroke(UIBezierPath(ovalIn: track), accent, width: max(1.5, size.height * 0.036))

        // The tree the size of a house: three tiers, a trunk, baubles and a star.
        let centre = CGPoint(x: size.width / 2, y: size.height * 0.50)
        let tall = size.height * 0.46
        fill(UIBezierPath(rect: CGRect(x: centre.x - tall * 0.05, y: centre.y + tall * 0.30,
                                       width: tall * 0.10, height: tall * 0.16)), ParkPalette.colour(.brown))
        for tier in 0..<3 {
            let top = centre.y - tall / 2 + CGFloat(tier) * tall * 0.20
            let width = tall * (0.34 + CGFloat(tier) * 0.12)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: centre.x, y: top))
            path.addLine(to: CGPoint(x: centre.x + width / 2, y: top + tall * 0.34))
            path.addLine(to: CGPoint(x: centre.x - width / 2, y: top + tall * 0.34))
            path.close()
            fill(path, secondary)
        }
        let baubles: [(CGFloat, CGFloat, Int)] = [(-0.08, 0.02, 0), (0.09, 0.10, 1), (-0.15, 0.22, 2), (0.14, 0.28, 0), (0, 0.18, 1)]
        for (dx, dy, colour) in baubles {
            let r = tall * 0.035
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x + dx * tall - r, y: centre.y - tall / 2 + dy * tall * 1.4 - r,
                                             width: r * 2, height: r * 2)), bulbColours[colour])
        }
        fill(starPath(centre: CGPoint(x: centre.x, y: centre.y - tall / 2 - tall * 0.02), outer: tall * 0.10, inner: tall * 0.04),
             festiveGold)

        // The station, red with a white roof.
        let station = CGRect(x: track.midX - size.width * 0.12, y: track.maxY - size.height * 0.05,
                             width: size.width * 0.24, height: size.height * 0.14)
        fill(UIBezierPath(roundedRect: station, cornerRadius: station.height * 0.3), primary)
        fill(UIBezierPath(roundedRect: CGRect(x: station.minX, y: station.minY - station.height * 0.06,
                                              width: station.width, height: station.height * 0.30),
                          cornerRadius: station.height * 0.15), snowWhite)
    }

    /// One piece of the train, nose to the right. The first is the engine
    /// with a funnel; the rest are carriages with lit windows.
    static func drawTrainCar(_ context: CGContext, _ size: CGSize,
                             _ primary: UIColor, _ secondary: UIColor, _ variant: Int) {
        let body = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: size.height * 0.16)
        if variant == 0 {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.34), primary)
            fill(UIBezierPath(rect: CGRect(x: body.maxX - body.width * 0.30, y: body.minY - size.height * 0.14,
                                           width: body.width * 0.16, height: size.height * 0.22)),
                 ParkPalette.colour(.charcoal))
            fill(UIBezierPath(ovalIn: CGRect(x: body.maxX - body.width * 0.55, y: body.minY - size.height * 0.10,
                                             width: size.width * 0.10, height: size.height * 0.16)),
                 UIColor.white.withAlphaComponent(0.85))
        } else {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.28), secondary)
            for slot in 0..<3 {
                let window = CGRect(x: body.minX + body.width * (0.10 + 0.28 * CGFloat(slot)), y: body.minY + body.height * 0.22,
                                    width: body.width * 0.18, height: body.height * 0.42)
                fill(UIBezierPath(rect: window), festiveGold)
            }
        }
        fill(UIBezierPath(rect: CGRect(x: body.minX, y: body.maxY - size.height * 0.08,
                                       width: body.width, height: size.height * 0.08)), ParkPalette.colour(.charcoal))
    }

    static func drawGingerbreadManorBase(_ context: CGContext, _ size: CGSize,
                                         _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        // Snowy ground under the house.
        snowMound(CGRect(x: size.width * 0.04, y: size.height * 0.70, width: size.width * 0.92, height: size.height * 0.26))

        // The house: gingerbread walls.
        let walls = CGRect(x: size.width * 0.14, y: size.height * 0.34, width: size.width * 0.72, height: size.height * 0.46)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: walls, cornerRadius: walls.height * 0.06), primary)
        }

        // A steep roof with icing along both edges and snow on top.
        let roof = UIBezierPath()
        roof.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.38))
        roof.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.06))
        roof.addLine(to: CGPoint(x: size.width * 0.92, y: size.height * 0.38))
        roof.close()
        fill(roof, UIColor(red: 0.36, green: 0.22, blue: 0.14, alpha: 1))
        let icing = UIBezierPath()
        icing.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.38))
        icing.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.06))
        icing.addLine(to: CGPoint(x: size.width * 0.92, y: size.height * 0.38))
        stroke(icing, secondary, width: max(2, size.width * 0.04))

        // Scalloped icing along the eaves.
        for index in 0..<7 {
            let r = size.width * 0.045
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * (0.12 + 0.105 * CGFloat(index)) - r, y: size.height * 0.36 - r,
                                             width: r * 2, height: r * 2.4)), secondary)
        }

        // Door and windows with lollipop-bright panes.
        fill(UIBezierPath(roundedRect: CGRect(x: size.width * 0.43, y: size.height * 0.56, width: size.width * 0.14, height: size.height * 0.24),
                          cornerRadius: size.width * 0.04), accent)
        for x in [CGFloat(0.22), CGFloat(0.66)] {
            fill(UIBezierPath(rect: CGRect(x: size.width * x, y: size.height * 0.46, width: size.width * 0.12, height: size.height * 0.12)),
                 festiveGold)
            stroke(UIBezierPath(rect: CGRect(x: size.width * x, y: size.height * 0.46, width: size.width * 0.12, height: size.height * 0.12)),
                   secondary, width: max(1, size.width * 0.012))
        }

        // Gumdrops along the foundation.
        let gumdrops = [bulbColours[0], bulbColours[2], bulbColours[1], bulbColours[3], bulbColours[0], bulbColours[2]]
        for (index, colour) in gumdrops.enumerated() {
            let r = size.width * 0.028
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * (0.18 + 0.12 * CGFloat(index)) - r, y: size.height * 0.80 - r,
                                             width: r * 2, height: r * 2)), colour)
        }

        // Two candy-cane posts at the gate.
        for x in [CGFloat(0.06), CGFloat(0.94)] {
            candyCane(at: CGPoint(x: size.width * x, y: size.height * 0.82), height: size.height * 0.22, red: accent)
        }
    }

    /// A candy cane standing on the ground at `base`.
    static func candyCane(at base: CGPoint, height: CGFloat, red: UIColor) {
        let width = max(1.5, height * 0.14)
        let stem = UIBezierPath()
        stem.move(to: base)
        stem.addLine(to: CGPoint(x: base.x, y: base.y - height * 0.78))
        stem.addArc(withCenter: CGPoint(x: base.x + height * 0.16, y: base.y - height * 0.78), radius: height * 0.16,
                    startAngle: .pi, endAngle: 0, clockwise: true)
        stroke(stem, snowWhite, width: width)
        // Red stripes, as short diagonal bands along the stem.
        for index in 0..<4 {
            let y = base.y - height * 0.10 - CGFloat(index) * height * 0.20
            let band = UIBezierPath()
            band.move(to: CGPoint(x: base.x - width * 0.5, y: y))
            band.addLine(to: CGPoint(x: base.x + width * 0.5, y: y - height * 0.07))
            stroke(band, red, width: max(1, width * 0.6))
        }
        let hookStripe = UIBezierPath(arcCenter: CGPoint(x: base.x + height * 0.16, y: base.y - height * 0.78),
                                      radius: height * 0.16, startAngle: .pi * 1.15, endAngle: .pi * 1.55, clockwise: true)
        stroke(hookStripe, red, width: max(1, width * 0.8))
    }

    /// The little gingerbread man that hovers on the porch.
    static func drawGingerbreadMan(_ context: CGContext, _ size: CGSize,
                                   _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let tan = UIColor(red: 0.74, green: 0.46, blue: 0.22, alpha: 1)
        let limb = max(1.5, size.width * 0.20)
        let arms = UIBezierPath()
        arms.move(to: CGPoint(x: size.width * 0.10, y: size.height * 0.46))
        arms.addLine(to: CGPoint(x: size.width * 0.90, y: size.height * 0.46))
        stroke(arms, tan, width: limb)
        let legs = UIBezierPath()
        legs.move(to: CGPoint(x: size.width * 0.30, y: size.height * 0.96))
        legs.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.62))
        legs.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * 0.96))
        stroke(legs, tan, width: limb)
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.24, y: size.height * 0.04, width: size.width * 0.52, height: size.height * 0.34)), tan)
        fill(UIBezierPath(roundedRect: CGRect(x: size.width * 0.30, y: size.height * 0.40, width: size.width * 0.40, height: size.height * 0.30),
                          cornerRadius: size.width * 0.10), tan)
        for x in [CGFloat(0.40), CGFloat(0.60)] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * x - 1, y: size.height * 0.15, width: 2, height: 2)), snowWhite)
        }
        for y in [CGFloat(0.48), CGFloat(0.58)] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.50 - 1.2, y: size.height * y, width: 2.4, height: 2.4)), accent)
        }
    }

    static func drawStarTopperBase(_ context: CGContext, _ size: CGSize,
                                   _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let pad = CGRect(x: size.width * 0.10, y: size.height * 0.76, width: size.width * 0.80, height: size.height * 0.18)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: pad, cornerRadius: pad.height * 0.35), snowWhite)
        }

        // The tree the column is dressed as: three tiers, widest at the bottom.
        let centre = size.width / 2
        for tier in 0..<3 {
            let top = size.height * (0.16 + 0.17 * CGFloat(tier))
            let width = size.width * (0.40 + 0.17 * CGFloat(tier))
            let path = UIBezierPath()
            path.move(to: CGPoint(x: centre, y: top))
            path.addLine(to: CGPoint(x: centre + width / 2, y: top + size.height * 0.28))
            path.addLine(to: CGPoint(x: centre - width / 2, y: top + size.height * 0.28))
            path.close()
            fill(path, primary)
            fill(UIBezierPath(ovalIn: CGRect(x: centre - width * 0.20, y: top + size.height * 0.20, width: width * 0.40, height: size.height * 0.06)),
                 snowWhite)
        }

        // The column the car climbs, down the middle.
        let column = CGRect(x: size.width * 0.46, y: size.height * 0.10, width: size.width * 0.08, height: size.height * 0.70)
        fill(UIBezierPath(roundedRect: column, cornerRadius: column.width * 0.3), ParkPalette.colour(.brown))

        let baubles: [(CGFloat, CGFloat, Int)] = [(0.36, 0.40, 0), (0.62, 0.48, 1), (0.30, 0.62, 2), (0.70, 0.66, 3), (0.50, 0.30, 0)]
        for (x, y, colour) in baubles {
            let r = size.width * 0.026
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * x - r, y: size.height * y - r, width: r * 2, height: r * 2)), bulbColours[colour])
        }

        // The star on top, drawn big so it reads at a distance.
        fill(starPath(centre: CGPoint(x: centre, y: size.height * 0.10), outer: size.width * 0.13, inner: size.width * 0.055), accent)
    }

    // MARK: - Rides: New Year's

    static func drawCountdownWheelBase(_ context: CGContext, _ size: CGSize,
                                       _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        drawFerrisWheelBase(context, size, primary, secondary, accent)

        // The clock at the hub, with both hands at midnight.
        let hub = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = size.width * 0.13
        fill(UIBezierPath(ovalIn: CGRect(x: hub.x - radius, y: hub.y - radius, width: radius * 2, height: radius * 2)), snowWhite)
        stroke(UIBezierPath(ovalIn: CGRect(x: hub.x - radius, y: hub.y - radius, width: radius * 2, height: radius * 2)),
               secondary, width: max(1.5, size.width * 0.03))
        let hands = UIBezierPath()
        hands.move(to: hub)
        hands.addLine(to: CGPoint(x: hub.x, y: hub.y - radius * 0.75))
        stroke(hands, primary, width: max(1, size.width * 0.02))
        for index in 0..<12 {
            let angle = CGFloat(index) / 12 * .pi * 2
            let tick = UIBezierPath()
            tick.move(to: CGPoint(x: hub.x + cos(angle) * radius * 0.82, y: hub.y + sin(angle) * radius * 0.82))
            tick.addLine(to: CGPoint(x: hub.x + cos(angle) * radius * 0.94, y: hub.y + sin(angle) * radius * 0.94))
            stroke(tick, primary, width: 0.8)
        }
    }

    static func drawConfettiSwingBase(_ context: CGContext, _ size: CGSize,
                                      _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        drawSwingChairsBase(context, size, primary, secondary, accent)

        // Paper everywhere: small coloured scraps on the ground and in the air.
        let scraps: [(CGFloat, CGFloat, Int)] = [(0.12, 0.84, 0), (0.30, 0.90, 1), (0.52, 0.88, 2), (0.74, 0.92, 3),
                                                 (0.88, 0.80, 0), (0.20, 0.20, 2), (0.82, 0.18, 1), (0.60, 0.10, 3), (0.40, 0.14, 0)]
        for (x, y, colour) in scraps {
            let paper = size.width * 0.04
            fill(UIBezierPath(rect: CGRect(x: size.width * x, y: size.height * y, width: paper, height: paper * 0.6)),
                 bulbColours[colour])
        }
        // The cannon at the back, a striped tube pointing up.
        let tube = CGRect(x: size.width * 0.84, y: size.height * 0.62, width: size.width * 0.07, height: size.height * 0.18)
        fill(UIBezierPath(roundedRect: tube, cornerRadius: tube.width * 0.3), accent)
        fill(UIBezierPath(rect: CGRect(x: tube.minX, y: tube.minY + tube.height * 0.35, width: tube.width, height: tube.height * 0.14)), snowWhite)
    }

    static func drawBallDropBase(_ context: CGContext, _ size: CGSize,
                                 _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let pad = CGRect(x: size.width * 0.10, y: size.height * 0.74, width: size.width * 0.80, height: size.height * 0.20)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: pad, cornerRadius: pad.height * 0.35), secondary)
        }
        let column = CGRect(x: size.width * 0.44, y: size.height * 0.04, width: size.width * 0.12, height: size.height * 0.74)
        fill(UIBezierPath(roundedRect: column, cornerRadius: column.width * 0.3), primary)
        let bands = 6
        for index in 0..<bands {
            let y = column.minY + column.height * (CGFloat(index) + 0.5) / CGFloat(bands)
            fill(UIBezierPath(rect: CGRect(x: column.minX, y: y, width: column.width, height: max(1, size.height * 0.014))), accent)
        }
        // A flagpole-style spire at the top for the ball to climb to.
        fill(UIBezierPath(rect: CGRect(x: size.width * 0.495, y: 0, width: size.width * 0.01, height: size.height * 0.10)), accent)
        // Lit numerals' worth of lights on the platform edge.
        let lights = 7
        for index in 0..<lights {
            fill(UIBezierPath(ovalIn: CGRect(x: pad.minX + pad.width * (CGFloat(index) + 0.5) / CGFloat(lights) - 1.5,
                                             y: pad.midY - 1.5, width: 3, height: 3)), bulbColours[index % 4])
        }
    }

    /// The ball: white and faceted, with a gold glint.
    static func drawDropBall(_ context: CGContext, _ size: CGSize,
                             _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
        fill(UIBezierPath(ovalIn: rect), secondary)
        stroke(UIBezierPath(ovalIn: rect), primary, width: max(1, size.width * 0.08))
        let facets = UIBezierPath()
        facets.move(to: CGPoint(x: rect.minX, y: rect.midY)); facets.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        facets.move(to: CGPoint(x: rect.midX, y: rect.minY)); facets.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        stroke(facets, primary.withAlphaComponent(0.6), width: max(0.8, size.width * 0.04))
        fill(starPath(centre: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.midY - rect.height * 0.14),
                      outer: rect.width * 0.14, inner: rect.width * 0.05, points: 4), accent)
    }

    static func drawStarburstCoasterBase(_ context: CGContext, _ size: CGSize,
                                         _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let track = trackRect(in: size)

        let columns = UIBezierPath()
        for index in 0..<10 {
            let angle = CGFloat(index) / 10 * .pi * 2
            let point = CGPoint(x: track.midX + cos(angle) * track.width / 2,
                                y: track.midY + sin(angle) * track.height / 2)
            columns.move(to: point)
            columns.addLine(to: CGPoint(x: point.x, y: point.y + size.height * 0.07))
        }
        stroke(columns, ParkPalette.coasterSupport, width: max(1.5, size.width * 0.014))

        stroke(UIBezierPath(ovalIn: track), ParkPalette.coasterTie, width: max(2.5, size.height * 0.090))
        stroke(UIBezierPath(ovalIn: track), secondary, width: max(1.5, size.height * 0.042))

        // Bursts of sparks off the track, which is how every lap ends.
        let spots: [(CGFloat, CGFloat, Int)] = [(0.50, 0.10, 0), (0.88, 0.50, 1), (0.14, 0.46, 1), (0.70, 0.16, 0), (0.30, 0.14, 1)]
        for (x, y, kind) in spots {
            burst(CGPoint(x: size.width * x, y: size.height * y), radius: size.width * 0.07, spokes: 8,
                  colour: kind == 0 ? accent : festiveGold, width: max(1, size.width * 0.012))
            fill(starPath(centre: CGPoint(x: size.width * x, y: size.height * y), outer: size.width * 0.022, inner: size.width * 0.009),
                 snowWhite)
        }

        let station = CGRect(x: track.midX - size.width * 0.13, y: track.maxY - size.height * 0.06,
                             width: size.width * 0.26, height: size.height * 0.16)
        fill(UIBezierPath(roundedRect: station, cornerRadius: station.height * 0.3), primary)
        fill(starPath(centre: CGPoint(x: station.midX, y: station.midY), outer: station.height * 0.30, inner: station.height * 0.12),
             accent)
    }

    // MARK: - Decorations

    static func drawXmasTree(_ context: CGContext, _ size: CGSize,
                             _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor, _ variant: Int) {
        let trunk = CGRect(x: size.width * 0.44, y: size.height * 0.80, width: size.width * 0.12, height: size.height * 0.16)
        fill(UIBezierPath(rect: trunk), ParkPalette.colour(.brown))
        withShadow(context) {
            for tier in 0..<3 {
                let top = size.height * (0.12 + 0.20 * CGFloat(tier))
                let width = size.width * (0.42 + 0.18 * CGFloat(tier))
                let path = UIBezierPath()
                path.move(to: CGPoint(x: size.width / 2, y: top))
                path.addLine(to: CGPoint(x: size.width / 2 + width / 2, y: top + size.height * 0.34))
                path.addLine(to: CGPoint(x: size.width / 2 - width / 2, y: top + size.height * 0.34))
                path.close()
                fill(path, primary)
            }
        }
        // Snow on the shoulders of each tier.
        for tier in 0..<3 {
            let top = size.height * (0.12 + 0.20 * CGFloat(tier))
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.40, y: top + size.height * 0.07, width: size.width * 0.20, height: size.height * 0.05)),
                 snowWhite)
        }
        // Three different ways to hang it, so a row of trees is not a stamp.
        let sets: [[Int]] = [[0, 1, 2, 0, 1], [1, 3, 1, 3, 0], [2, 0, 3, 2, 1]]
        let positions: [(CGFloat, CGFloat)] = [(0.42, 0.34), (0.60, 0.46), (0.36, 0.56), (0.64, 0.66), (0.50, 0.78)]
        for (index, position) in positions.enumerated() {
            let r = size.width * 0.04
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * position.0 - r, y: size.height * position.1 - r, width: r * 2, height: r * 2)),
                 bulbColours[sets[variant % 3][index]])
        }
        fill(starPath(centre: CGPoint(x: size.width / 2, y: size.height * 0.10), outer: size.width * 0.12, inner: size.width * 0.05), accent)
    }

    static func drawSnowman(_ context: CGContext, _ size: CGSize,
                            _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let shadow = CGRect(x: size.width * 0.12, y: size.height * 0.86, width: size.width * 0.76, height: size.height * 0.10)
        fill(UIBezierPath(ovalIn: shadow), UIColor(red: 0.74, green: 0.82, blue: 0.93, alpha: 1))
        withShadow(context) {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.16, y: size.height * 0.50, width: size.width * 0.68, height: size.height * 0.42)), primary)
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.24, y: size.height * 0.26, width: size.width * 0.52, height: size.height * 0.34)), primary)
        }
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.30, y: size.height * 0.06, width: size.width * 0.40, height: size.height * 0.30)), primary)
        // Hat.
        fill(UIBezierPath(rect: CGRect(x: size.width * 0.34, y: size.height * 0.00, width: size.width * 0.32, height: size.height * 0.10)),
             ParkPalette.colour(.charcoal))
        fill(UIBezierPath(rect: CGRect(x: size.width * 0.28, y: size.height * 0.09, width: size.width * 0.44, height: size.height * 0.03)),
             ParkPalette.colour(.charcoal))
        // Face.
        for x in [CGFloat(0.42), CGFloat(0.58)] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * x - 1, y: size.height * 0.17, width: 2.2, height: 2.2)), ParkPalette.colour(.charcoal))
        }
        let nose = UIBezierPath()
        nose.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.21))
        nose.addLine(to: CGPoint(x: size.width * 0.68, y: size.height * 0.24))
        nose.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.26))
        nose.close()
        fill(nose, accent)
        // Scarf and buttons.
        fill(UIBezierPath(roundedRect: CGRect(x: size.width * 0.30, y: size.height * 0.31, width: size.width * 0.40, height: size.height * 0.06),
                          cornerRadius: size.height * 0.03), secondary)
        fill(UIBezierPath(rect: CGRect(x: size.width * 0.60, y: size.height * 0.34, width: size.width * 0.07, height: size.height * 0.16)), secondary)
        for y in [CGFloat(0.50), CGFloat(0.62), CGFloat(0.74)] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.50 - 1.2, y: size.height * y, width: 2.4, height: 2.4)), ParkPalette.colour(.charcoal))
        }
    }

    static func drawWreathArch(_ context: CGContext, _ size: CGSize,
                               _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        for x in [CGFloat(0.14), CGFloat(0.80)] {
            fill(UIBezierPath(rect: CGRect(x: size.width * x, y: size.height * 0.30, width: size.width * 0.06, height: size.height * 0.66)),
                 ParkPalette.colour(.brown))
            // Garland wound round each post.
            for step in 0..<4 {
                let y = size.height * (0.40 + 0.14 * CGFloat(step))
                let wrap = UIBezierPath()
                wrap.move(to: CGPoint(x: size.width * x - 1, y: y))
                wrap.addLine(to: CGPoint(x: size.width * x + size.width * 0.07, y: y + size.height * 0.06))
                stroke(wrap, primary, width: max(1.5, size.width * 0.035))
            }
        }
        // The wreath across the top: a green ring with berries and a bow.
        let ring = CGRect(x: size.width * 0.10, y: size.height * 0.02, width: size.width * 0.80, height: size.height * 0.42)
        stroke(UIBezierPath(ovalIn: ring), primary, width: max(2.5, size.height * 0.08))
        for index in 0..<10 {
            let angle = CGFloat(index) / 10 * .pi * 2
            let r = size.width * 0.022
            fill(UIBezierPath(ovalIn: CGRect(x: ring.midX + cos(angle) * ring.width / 2 - r, y: ring.midY + sin(angle) * ring.height / 2 - r,
                                             width: r * 2, height: r * 2)), index % 2 == 0 ? secondary : snowWhite)
        }
        let bow = CGPoint(x: size.width / 2, y: size.height * 0.45)
        for side in [CGFloat(-1), CGFloat(1)] {
            fill(UIBezierPath(ovalIn: CGRect(x: bow.x + side * size.width * 0.07 - size.width * 0.07, y: bow.y - size.height * 0.04,
                                             width: size.width * 0.14, height: size.height * 0.09)), secondary)
        }
        fill(UIBezierPath(ovalIn: CGRect(x: bow.x - size.width * 0.03, y: bow.y - size.height * 0.02, width: size.width * 0.06, height: size.height * 0.06)),
             accent)
    }

    static func drawGiftStack(_ context: CGContext, _ size: CGSize,
                              _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        func box(_ rect: CGRect, _ wrap: UIColor, _ ribbon: UIColor) {
            withShadow(context) {
                fill(UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.06), wrap)
            }
            fill(UIBezierPath(rect: CGRect(x: rect.midX - rect.width * 0.07, y: rect.minY, width: rect.width * 0.14, height: rect.height)), ribbon)
            fill(UIBezierPath(rect: CGRect(x: rect.minX, y: rect.midY - rect.height * 0.07, width: rect.width, height: rect.height * 0.14)), ribbon)
        }
        box(CGRect(x: size.width * 0.08, y: size.height * 0.56, width: size.width * 0.58, height: size.height * 0.38), primary, accent)
        box(CGRect(x: size.width * 0.52, y: size.height * 0.66, width: size.width * 0.40, height: size.height * 0.28), secondary, snowWhite)
        box(CGRect(x: size.width * 0.20, y: size.height * 0.30, width: size.width * 0.40, height: size.height * 0.28), accent, primary)
        // A bow on the top box.
        let bow = CGPoint(x: size.width * 0.40, y: size.height * 0.28)
        for side in [CGFloat(-1), CGFloat(1)] {
            fill(UIBezierPath(ovalIn: CGRect(x: bow.x + side * size.width * 0.06 - size.width * 0.06, y: bow.y - size.height * 0.06,
                                             width: size.width * 0.12, height: size.height * 0.10)), primary)
        }
        fill(UIBezierPath(ovalIn: CGRect(x: bow.x - size.width * 0.025, y: bow.y - size.height * 0.03, width: size.width * 0.05, height: size.height * 0.06)), secondary)
    }

    static func drawLightPole(_ context: CGContext, _ size: CGSize,
                              _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let pole = CGRect(x: size.width * 0.46, y: size.height * 0.10, width: size.width * 0.08, height: size.height * 0.84)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: pole, cornerRadius: pole.width * 0.3), primary)
        }
        // Strings of lights looping out to both sides and back.
        let top = CGPoint(x: size.width * 0.50, y: size.height * 0.14)
        lightString(from: top, to: CGPoint(x: size.width * 0.04, y: size.height * 0.46), sag: size.height * 0.08, bulbs: 5, size: max(2, size.width * 0.07))
        lightString(from: top, to: CGPoint(x: size.width * 0.96, y: size.height * 0.46), sag: size.height * 0.08, bulbs: 5, size: max(2, size.width * 0.07))
        lightString(from: CGPoint(x: size.width * 0.04, y: size.height * 0.46), to: CGPoint(x: size.width * 0.50, y: size.height * 0.78),
                    sag: size.height * 0.08, bulbs: 5, size: max(2, size.width * 0.07))
        lightString(from: CGPoint(x: size.width * 0.96, y: size.height * 0.46), to: CGPoint(x: size.width * 0.50, y: size.height * 0.78),
                    sag: size.height * 0.08, bulbs: 5, size: max(2, size.width * 0.07))
        fill(starPath(centre: CGPoint(x: size.width / 2, y: size.height * 0.07), outer: size.width * 0.10, inner: size.width * 0.04), secondary)
    }

    static func drawCandyCanePost(_ context: CGContext, _ size: CGSize,
                                  _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.16, y: size.height * 0.88, width: size.width * 0.68, height: size.height * 0.10)),
             UIColor(red: 0.74, green: 0.82, blue: 0.93, alpha: 1))
        candyCane(at: CGPoint(x: size.width * 0.36, y: size.height * 0.94), height: size.height * 0.90, red: primary)
        // A green bow where the hook meets the stem.
        let bow = CGPoint(x: size.width * 0.36, y: size.height * 0.44)
        for side in [CGFloat(-1), CGFloat(1)] {
            fill(UIBezierPath(ovalIn: CGRect(x: bow.x + side * size.width * 0.07 - size.width * 0.07, y: bow.y - size.height * 0.04,
                                             width: size.width * 0.14, height: size.height * 0.08)), accent)
        }
    }

    static func drawFireworkStand(_ context: CGContext, _ size: CGSize,
                                  _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        // A wooden rack with a row of rockets leaning on it.
        let rack = CGRect(x: size.width * 0.06, y: size.height * 0.70, width: size.width * 0.88, height: size.height * 0.20)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: rack, cornerRadius: rack.height * 0.2), ParkPalette.colour(.brown))
        }
        let colours = [primary, accent, secondary, bulbColours[0], bulbColours[2], accent]
        for index in 0..<6 {
            let x = size.width * (0.14 + 0.14 * CGFloat(index))
            let rocket = UIBezierPath()
            rocket.move(to: CGPoint(x: x, y: size.height * 0.76))
            rocket.addLine(to: CGPoint(x: x + size.width * 0.02 * CGFloat(index - 2), y: size.height * 0.34))
            stroke(rocket, colours[index % colours.count], width: max(2, size.width * 0.04))
            let head = UIBezierPath()
            let tipX = x + size.width * 0.02 * CGFloat(index - 2)
            head.move(to: CGPoint(x: tipX - size.width * 0.03, y: size.height * 0.36))
            head.addLine(to: CGPoint(x: tipX, y: size.height * 0.22))
            head.addLine(to: CGPoint(x: tipX + size.width * 0.03, y: size.height * 0.36))
            head.close()
            fill(head, snowWhite)
        }
        // A pair of bursts above, frozen at their peak.
        burst(CGPoint(x: size.width * 0.28, y: size.height * 0.12), radius: size.width * 0.12, spokes: 8, colour: accent, width: max(1, size.width * 0.012))
        burst(CGPoint(x: size.width * 0.72, y: size.height * 0.14), radius: size.width * 0.10, spokes: 8, colour: festiveGold, width: max(1, size.width * 0.012))
    }

    static func drawCountdownClock(_ context: CGContext, _ size: CGSize,
                                   _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let tower = CGRect(x: size.width * 0.28, y: size.height * 0.30, width: size.width * 0.44, height: size.height * 0.64)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: tower, cornerRadius: tower.width * 0.1), primary)
        }
        fill(UIBezierPath(rect: CGRect(x: tower.minX - size.width * 0.04, y: tower.maxY - size.height * 0.05,
                                       width: tower.width + size.width * 0.08, height: size.height * 0.07)), secondary)
        // Pointed top with a star.
        let roof = UIBezierPath()
        roof.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.04))
        roof.addLine(to: CGPoint(x: size.width * 0.76, y: size.height * 0.30))
        roof.addLine(to: CGPoint(x: size.width * 0.24, y: size.height * 0.30))
        roof.close()
        fill(roof, secondary)
        fill(starPath(centre: CGPoint(x: size.width / 2, y: size.height * 0.05), outer: size.width * 0.09, inner: size.width * 0.04), accent)
        // The face, one minute to midnight.
        let face = CGRect(x: size.width * 0.34, y: size.height * 0.38, width: size.width * 0.32, height: size.width * 0.32)
        fill(UIBezierPath(ovalIn: face), snowWhite)
        stroke(UIBezierPath(ovalIn: face), secondary, width: max(1.2, size.width * 0.03))
        let hands = UIBezierPath()
        hands.move(to: CGPoint(x: face.midX, y: face.midY)); hands.addLine(to: CGPoint(x: face.midX, y: face.minY + face.height * 0.14))
        hands.move(to: CGPoint(x: face.midX, y: face.midY)); hands.addLine(to: CGPoint(x: face.midX - face.width * 0.10, y: face.minY + face.height * 0.20))
        stroke(hands, primary, width: max(1, size.width * 0.025))
        // Lit bulbs down the front.
        for index in 0..<4 {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.48, y: size.height * (0.64 + 0.06 * CGFloat(index)), width: size.width * 0.04, height: size.width * 0.04)),
                 bulbColours[index % 4])
        }
    }

    // MARK: - Skating rink and the two seasonal stalls

    static func drawSkatingRinkBase(_ context: CGContext, _ size: CGSize,
                                    _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        let sheet = CGRect(origin: .zero, size: size).insetBy(dx: size.width * 0.08, dy: size.height * 0.10)
        let corner = min(sheet.width, sheet.height) * 0.40
        withShadow(context) {
            fill(UIBezierPath(roundedRect: sheet, cornerRadius: corner), secondary)
        }
        stroke(UIBezierPath(roundedRect: sheet, cornerRadius: corner), accent, width: max(2, size.height * 0.045))
        let ice = sheet.insetBy(dx: sheet.width * 0.04, dy: sheet.height * 0.06)
        fill(UIBezierPath(roundedRect: ice, cornerRadius: min(ice.width, ice.height) * 0.38),
             UIColor(red: 0.74, green: 0.90, blue: 0.95, alpha: 1))
        // Scratches in the ice: a few long curves.
        let marks = UIBezierPath()
        marks.move(to: CGPoint(x: ice.minX + ice.width * 0.15, y: ice.midY - ice.height * 0.18))
        marks.addQuadCurve(to: CGPoint(x: ice.maxX - ice.width * 0.15, y: ice.midY - ice.height * 0.10),
                           controlPoint: CGPoint(x: ice.midX, y: ice.minY + ice.height * 0.10))
        marks.move(to: CGPoint(x: ice.minX + ice.width * 0.20, y: ice.midY + ice.height * 0.20))
        marks.addQuadCurve(to: CGPoint(x: ice.maxX - ice.width * 0.10, y: ice.midY + ice.height * 0.16),
                           controlPoint: CGPoint(x: ice.midX, y: ice.maxY - ice.height * 0.04))
        stroke(marks, UIColor.white.withAlphaComponent(0.85), width: max(0.8, size.height * 0.012))
        // The centre mark and snow banked at the corners.
        stroke(UIBezierPath(ovalIn: CGRect(x: ice.midX - ice.width * 0.08, y: ice.midY - ice.height * 0.12,
                                           width: ice.width * 0.16, height: ice.height * 0.24)),
               accent.withAlphaComponent(0.7), width: max(1, size.height * 0.014))
        snowMound(CGRect(x: size.width * 0.02, y: size.height * 0.74, width: size.width * 0.20, height: size.height * 0.20))
        snowMound(CGRect(x: size.width * 0.78, y: size.height * 0.04, width: size.width * 0.20, height: size.height * 0.18))
        lightString(from: CGPoint(x: size.width * 0.14, y: size.height * 0.94),
                    to: CGPoint(x: size.width * 0.86, y: size.height * 0.94),
                    sag: size.height * 0.03, bulbs: 9, size: max(2, size.width * 0.022))
    }

    /// One skater, in a coloured jacket and a bobble hat; the variant picks the colours.
    static func drawSkater(_ context: CGContext, _ size: CGSize, _ variant: Int) {
        let coat = bulbColours[variant % bulbColours.count]
        let hat = bulbColours[(variant + 2) % bulbColours.count]
        let skin = UIColor(red: 0.93, green: 0.76, blue: 0.60, alpha: 1)
        let trousers = UIColor(red: 0.20, green: 0.22, blue: 0.30, alpha: 1)
        fill(UIBezierPath(rect: CGRect(x: size.width * 0.34, y: size.height * 0.62, width: size.width * 0.14, height: size.height * 0.34)), trousers)
        fill(UIBezierPath(rect: CGRect(x: size.width * 0.54, y: size.height * 0.62, width: size.width * 0.14, height: size.height * 0.34)), trousers)
        fill(UIBezierPath(roundedRect: CGRect(x: size.width * 0.26, y: size.height * 0.30, width: size.width * 0.52, height: size.height * 0.40),
                          cornerRadius: size.width * 0.12), coat)
        let arms = UIBezierPath()
        arms.move(to: CGPoint(x: size.width * 0.20, y: size.height * 0.46))
        arms.addLine(to: CGPoint(x: size.width * 0.84, y: size.height * 0.40))
        stroke(arms, coat, width: max(1.2, size.width * 0.12))
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.34, y: size.height * 0.04, width: size.width * 0.36, height: size.height * 0.30)), skin)
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.32, y: size.height * 0.00, width: size.width * 0.40, height: size.height * 0.18)), hat)
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.46, y: size.height * -0.04, width: size.width * 0.12, height: size.height * 0.12)), snowWhite)
    }

    static func drawHotCocoaStand(_ context: CGContext, _ size: CGSize,
                                  _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        snowMound(CGRect(x: size.width * 0.04, y: size.height * 0.80, width: size.width * 0.92, height: size.height * 0.18))
        let counter = CGRect(x: size.width * 0.12, y: size.height * 0.40, width: size.width * 0.76, height: size.height * 0.46)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: counter, cornerRadius: size.width * 0.04), primary)
        }
        // Striped awning with a snowy top.
        let stripes = 6
        let span = counter.width + size.width * 0.08
        for index in 0..<stripes {
            let x = counter.minX - size.width * 0.04 + span * CGFloat(index) / CGFloat(stripes)
            fill(UIBezierPath(rect: CGRect(x: x, y: size.height * 0.20, width: span / CGFloat(stripes) + 0.5, height: size.height * 0.24)),
                 index % 2 == 0 ? accent : snowWhite)
        }
        fill(UIBezierPath(roundedRect: CGRect(x: counter.minX - size.width * 0.05, y: size.height * 0.12,
                                              width: counter.width + size.width * 0.10, height: size.height * 0.12),
                          cornerRadius: size.height * 0.06), snowWhite)
        // A big cup on the front with steam and marshmallows.
        let cup = CGRect(x: size.width * 0.38, y: size.height * 0.54, width: size.width * 0.24, height: size.height * 0.26)
        let body = UIBezierPath()
        body.move(to: CGPoint(x: cup.minX, y: cup.minY)); body.addLine(to: CGPoint(x: cup.maxX, y: cup.minY))
        body.addLine(to: CGPoint(x: cup.maxX - cup.width * 0.14, y: cup.maxY))
        body.addLine(to: CGPoint(x: cup.minX + cup.width * 0.14, y: cup.maxY)); body.close()
        fill(body, secondary)
        fill(UIBezierPath(rect: CGRect(x: cup.minX, y: cup.minY, width: cup.width, height: cup.height * 0.22)),
             UIColor(red: 0.36, green: 0.20, blue: 0.12, alpha: 1))
        for dx in [CGFloat(0.22), 0.52, 0.76] {
            fill(UIBezierPath(ovalIn: CGRect(x: cup.minX + cup.width * dx - 3, y: cup.minY - 3, width: 6, height: 5)), snowWhite)
        }
        for dx in [CGFloat(0.30), 0.55, 0.74] {
            let steam = UIBezierPath()
            steam.move(to: CGPoint(x: cup.minX + cup.width * dx, y: cup.minY - size.height * 0.04))
            steam.addQuadCurve(to: CGPoint(x: cup.minX + cup.width * dx, y: cup.minY - size.height * 0.16),
                               controlPoint: CGPoint(x: cup.minX + cup.width * (dx + 0.18), y: cup.minY - size.height * 0.10))
            stroke(steam, UIColor.white.withAlphaComponent(0.75), width: max(0.8, size.width * 0.012))
        }
        for x in [CGFloat(0.18), 0.72] {
            fill(UIBezierPath(roundedRect: CGRect(x: size.width * x, y: size.height * 0.60, width: size.width * 0.10, height: size.height * 0.12), cornerRadius: 2), accent)
        }
        lightString(from: CGPoint(x: size.width * 0.12, y: size.height * 0.16), to: CGPoint(x: size.width * 0.88, y: size.height * 0.16),
                    sag: size.height * 0.04, bulbs: 8, size: max(2, size.width * 0.026))
    }

    static func drawCandyStand(_ context: CGContext, _ size: CGSize,
                               _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        snowMound(CGRect(x: size.width * 0.04, y: size.height * 0.80, width: size.width * 0.92, height: size.height * 0.18))
        let counter = CGRect(x: size.width * 0.12, y: size.height * 0.42, width: size.width * 0.76, height: size.height * 0.44)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: counter, cornerRadius: size.width * 0.04), accent)
        }
        // A big striped awning in red and white, with a scalloped edge.
        let stripes = 8
        let span = counter.width + size.width * 0.10
        for index in 0..<stripes {
            let x = counter.minX - size.width * 0.05 + span * CGFloat(index) / CGFloat(stripes)
            let colour = index % 2 == 0 ? primary : secondary
            fill(UIBezierPath(rect: CGRect(x: x, y: size.height * 0.18, width: span / CGFloat(stripes) + 0.5, height: size.height * 0.22)), colour)
            fill(UIBezierPath(ovalIn: CGRect(x: x, y: size.height * 0.34, width: span / CGFloat(stripes) + 0.5, height: size.height * 0.10)), colour)
        }
        // Jars of sweets along the counter, a candy cane either side, and a lollipop sign on top.
        let jars = [primary, bulbColours[1], accent, bulbColours[3]]
        for (index, colour) in jars.enumerated() {
            let x = counter.minX + counter.width * (0.08 + 0.22 * CGFloat(index))
            fill(UIBezierPath(roundedRect: CGRect(x: x, y: size.height * 0.52, width: size.width * 0.14, height: size.height * 0.20),
                              cornerRadius: size.width * 0.03), snowWhite.withAlphaComponent(0.85))
            for dot in 0..<4 {
                fill(UIBezierPath(ovalIn: CGRect(x: x + size.width * (0.02 + 0.03 * CGFloat(dot % 3)),
                                                 y: size.height * (0.60 + 0.04 * CGFloat(dot / 3)), width: 4, height: 4)), colour)
            }
        }
        candyCane(at: CGPoint(x: size.width * 0.06, y: size.height * 0.84), height: size.height * 0.34, red: primary)
        candyCane(at: CGPoint(x: size.width * 0.94, y: size.height * 0.84), height: size.height * 0.34, red: primary)
        let stick = UIBezierPath()
        stick.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.20))
        stick.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.08))
        stroke(stick, snowWhite, width: max(1.2, size.width * 0.02))
        stripedOval(CGRect(x: size.width * 0.44, y: size.height * -0.02, width: size.width * 0.12, height: size.height * 0.14),
                    first: primary, second: snowWhite, segments: 14, width: max(1, size.width * 0.02))
    }

    // MARK: - Candy canes, lights, the snow family and the snow cone cart

    static func drawCandyCaneFence(_ context: CGContext, _ size: CGSize,
                                   _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.02, y: size.height * 0.84, width: size.width * 0.96, height: size.height * 0.12)),
             UIColor(red: 0.74, green: 0.82, blue: 0.93, alpha: 1))
        let rail = CGRect(x: size.width * 0.04, y: size.height * 0.52, width: size.width * 0.92, height: size.height * 0.10)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: rail, cornerRadius: rail.height * 0.5), snowWhite)
        }
        for index in 0..<12 where index % 2 == 0 {
            fill(UIBezierPath(rect: CGRect(x: rail.minX + rail.width * CGFloat(index) / 12, y: rail.minY,
                                           width: rail.width / 12 + 0.5, height: rail.height)), primary)
        }
        for x in [CGFloat(0.18), 0.50, 0.82] {
            candyCane(at: CGPoint(x: size.width * x, y: size.height * 0.92), height: size.height * 0.80, red: primary)
            let bow = CGPoint(x: size.width * x, y: size.height * 0.40)
            for side in [CGFloat(-1), CGFloat(1)] {
                fill(UIBezierPath(ovalIn: CGRect(x: bow.x + side * size.width * 0.045 - size.width * 0.045, y: bow.y - size.height * 0.03,
                                                 width: size.width * 0.09, height: size.height * 0.06)), accent)
            }
        }
        snowMound(CGRect(x: 0, y: size.height * 0.86, width: size.width * 0.28, height: size.height * 0.12))
        snowMound(CGRect(x: size.width * 0.72, y: size.height * 0.86, width: size.width * 0.28, height: size.height * 0.12))
    }

    static func drawHolidayLights(_ context: CGContext, _ size: CGSize,
                                  _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.04, y: size.height * 0.84, width: size.width * 0.92, height: size.height * 0.12)),
             UIColor(red: 0.74, green: 0.82, blue: 0.93, alpha: 1))
        let wood = ParkPalette.colour(.brown)
        for x in [CGFloat(0.10), 0.88] {
            fill(UIBezierPath(roundedRect: CGRect(x: size.width * x, y: size.height * 0.30, width: size.width * 0.04, height: size.height * 0.60), cornerRadius: 1.5), wood)
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * (x - 0.01), y: size.height * 0.26, width: size.width * 0.06, height: size.width * 0.06)), festiveGold)
        }
        let rows: [CGFloat] = [0.34, 0.52, 0.70]
        for (row, y) in rows.enumerated() {
            let start = CGPoint(x: size.width * 0.12, y: size.height * y)
            let end = CGPoint(x: size.width * 0.90, y: size.height * y)
            for b in 0..<8 {
                let t = (CGFloat(b) + 0.5) / 8
                let bx = start.x + (end.x - start.x) * t
                let by = start.y + (end.y - start.y) * t + size.height * 0.14 * t * (1 - t)
                fill(UIBezierPath(ovalIn: CGRect(x: bx - size.width * 0.045, y: by - size.width * 0.045, width: size.width * 0.09, height: size.width * 0.09)),
                     bulbColours[(b + row) % 4].withAlphaComponent(0.28))
            }
            lightString(from: start, to: end, sag: size.height * 0.07, bulbs: 8, size: max(2.5, size.width * 0.045))
        }
    }

    private static func snowmanAt(_ centreX: CGFloat, _ baseY: CGFloat, _ height: CGFloat,
                                  scarf: UIColor, nose: UIColor, hat: Bool) {
        let w = height * 0.62
        fill(UIBezierPath(ovalIn: CGRect(x: centreX - w * 0.60, y: baseY - height * 0.08, width: w * 1.2, height: height * 0.10)),
             UIColor(red: 0.74, green: 0.82, blue: 0.93, alpha: 1))
        fill(UIBezierPath(ovalIn: CGRect(x: centreX - w * 0.50, y: baseY - height * 0.50, width: w, height: height * 0.50)), snowWhite)
        fill(UIBezierPath(ovalIn: CGRect(x: centreX - w * 0.36, y: baseY - height * 0.80, width: w * 0.72, height: height * 0.40)), snowWhite)
        let head = w * 0.54
        let headTop = baseY - height
        fill(UIBezierPath(ovalIn: CGRect(x: centreX - head / 2, y: headTop, width: head, height: head)), snowWhite)
        let charcoal = ParkPalette.colour(.charcoal)
        if hat {
            fill(UIBezierPath(rect: CGRect(x: centreX - head * 0.30, y: headTop - head * 0.34, width: head * 0.60, height: head * 0.40)), charcoal)
            fill(UIBezierPath(rect: CGRect(x: centreX - head * 0.48, y: headTop + head * 0.02, width: head * 0.96, height: head * 0.08)), charcoal)
        }
        for dx in [CGFloat(-0.16), 0.16] {
            fill(UIBezierPath(ovalIn: CGRect(x: centreX + head * dx - 1, y: headTop + head * 0.34, width: 2.2, height: 2.2)), charcoal)
        }
        let carrot = UIBezierPath()
        carrot.move(to: CGPoint(x: centreX, y: headTop + head * 0.46))
        carrot.addLine(to: CGPoint(x: centreX + head * 0.42, y: headTop + head * 0.54))
        carrot.addLine(to: CGPoint(x: centreX, y: headTop + head * 0.60))
        carrot.close()
        fill(carrot, nose)
        fill(UIBezierPath(roundedRect: CGRect(x: centreX - head * 0.42, y: headTop + head * 0.82, width: head * 0.84, height: head * 0.16), cornerRadius: head * 0.08), scarf)
        fill(UIBezierPath(rect: CGRect(x: centreX + head * 0.18, y: headTop + head * 0.90, width: head * 0.18, height: head * 0.52)), scarf)
        for dy in [CGFloat(0.40), 0.62] {
            fill(UIBezierPath(ovalIn: CGRect(x: centreX - 1.2, y: baseY - height * dy, width: 2.4, height: 2.4)), charcoal)
        }
    }

    static func drawSnowFamily(_ context: CGContext, _ size: CGSize,
                               _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        withShadow(context) {
            snowmanAt(size.width * 0.28, size.height * 0.94, size.height * 0.84, scarf: secondary, nose: accent, hat: true)
        }
        snowmanAt(size.width * 0.58, size.height * 0.94, size.height * 0.62, scarf: secondary, nose: accent, hat: false)
        snowmanAt(size.width * 0.82, size.height * 0.94, size.height * 0.42, scarf: bulbColours[2], nose: accent, hat: false)
        let arm = UIBezierPath()
        arm.move(to: CGPoint(x: size.width * 0.40, y: size.height * 0.56))
        arm.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.62))
        stroke(arm, ParkPalette.colour(.brown), width: max(1, size.width * 0.016))
    }

    static func drawSnowConeCart(_ context: CGContext, _ size: CGSize,
                                 _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor) {
        snowMound(CGRect(x: size.width * 0.02, y: size.height * 0.86, width: size.width * 0.96, height: size.height * 0.13))
        let charcoal = ParkPalette.colour(.charcoal)
        for x in [CGFloat(0.22), 0.60] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * x, y: size.height * 0.78, width: size.width * 0.18, height: size.width * 0.18)), charcoal)
        }
        let body = CGRect(x: size.width * 0.12, y: size.height * 0.48, width: size.width * 0.76, height: size.height * 0.36)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: body, cornerRadius: size.width * 0.05), primary)
        }
        fill(UIBezierPath(rect: CGRect(x: body.minX, y: body.minY + body.height * 0.40, width: body.width, height: body.height * 0.12)), secondary)
        let syrups = [accent, bulbColours[1], bulbColours[2], bulbColours[0]]
        for (index, colour) in syrups.enumerated() {
            let x = body.minX + body.width * (0.10 + 0.20 * CGFloat(index))
            fill(UIBezierPath(roundedRect: CGRect(x: x, y: body.minY - size.height * 0.12, width: size.width * 0.08, height: size.height * 0.14), cornerRadius: 2), colour)
            fill(UIBezierPath(rect: CGRect(x: x + size.width * 0.02, y: body.minY - size.height * 0.17, width: size.width * 0.04, height: size.height * 0.06)), secondary)
        }
        let cone = UIBezierPath()
        cone.move(to: CGPoint(x: size.width * 0.44, y: size.height * 0.60))
        cone.addLine(to: CGPoint(x: size.width * 0.56, y: size.height * 0.60))
        cone.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.80))
        cone.close()
        fill(cone, UIColor(red: 0.95, green: 0.88, blue: 0.70, alpha: 1))
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.41, y: size.height * 0.50, width: size.width * 0.18, height: size.height * 0.14)), snowWhite)
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.44, y: size.height * 0.46, width: size.width * 0.12, height: size.height * 0.10)), accent.withAlphaComponent(0.8))
        let pole = UIBezierPath()
        pole.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.48))
        pole.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.10))
        stroke(pole, ParkPalette.colour(.brown), width: max(1.2, size.width * 0.02))
        let segments = 6
        for index in 0..<segments {
            let x0 = size.width * (0.06 + 0.88 * CGFloat(index) / CGFloat(segments))
            let x1 = size.width * (0.06 + 0.88 * CGFloat(index + 1) / CGFloat(segments))
            let panel = UIBezierPath()
            panel.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.04))
            panel.addLine(to: CGPoint(x: x1, y: size.height * 0.24))
            panel.addLine(to: CGPoint(x: x0, y: size.height * 0.24))
            panel.close()
            fill(panel, index % 2 == 0 ? primary : snowWhite)
        }
        snowMound(CGRect(x: size.width * 0.38, y: 0, width: size.width * 0.24, height: size.height * 0.08))
    }

    // MARK: - Sizes

    /// How big the moving part is for the holiday rides, or nil for a motif
    /// that has none of its own.
    static func holidayMotionPartSize(for motif: BuildingMotif, buildingSize: CGSize) -> CGSize? {
        let shortest = min(buildingSize.width, buildingSize.height)
        switch motif {
        case .reindeerCarousel: return CGSize(width: shortest * 0.78, height: shortest * 0.78)
        case .sleighRide: return CGSize(width: shortest * 0.22, height: shortest * 0.14)
        case .candyCoaster, .starburstCoaster: return CGSize(width: shortest * 0.19, height: shortest * 0.12)
        case .snowGlobe: return CGSize(width: shortest * 0.70, height: shortest * 0.70)
        case .polarExpress: return CGSize(width: shortest * 0.17, height: shortest * 0.11)
        case .gingerbreadManor: return CGSize(width: shortest * 0.18, height: shortest * 0.26)
        case .starTopper: return CGSize(width: shortest * 0.30, height: shortest * 0.18)
        case .countdownWheel: return CGSize(width: shortest * 0.82, height: shortest * 0.82)
        case .confettiSwing: return CGSize(width: shortest * 0.16, height: shortest * 0.22)
        case .ballDrop: return CGSize(width: shortest * 0.20, height: shortest * 0.20)
        case .skatingRink: return CGSize(width: shortest * 0.11, height: shortest * 0.15)
        default: return nil
        }
    }

    /// How many moving parts each holiday ride has.
    static func holidayMotionPartCount(for motif: BuildingMotif) -> Int? {
        switch motif {
        case .sleighRide: return 3
        case .candyCoaster, .starburstCoaster: return 3
        case .polarExpress: return 4
        case .confettiSwing: return 6
        case .skatingRink: return 5
        default: return nil
        }
    }
}
