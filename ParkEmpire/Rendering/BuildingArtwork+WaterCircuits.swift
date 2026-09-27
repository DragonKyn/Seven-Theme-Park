import SpriteKit
import UIKit

/// The two rides that are a channel of water with something loose on it: a
/// white-water river and a lantern-lit canal.
///
/// Both follow the log flume's rule — one list of points is both the channel
/// that gets drawn and the route the boats take — so the water a raft is in is
/// always the water on screen. What separates them is pace: the river is rough
/// and fast, and the canal is the slowest thing in the park.
extension BuildingArtwork {

    // MARK: - Shared channel plotting

    /// Samples a run of straights and curves into one closed list of points.
    ///
    /// Nested helper functions rather than a path object, because the points
    /// are needed as points: they are handed to the animation as well as to
    /// the drawing.
    private static func plot(in size: CGSize,
                            _ build: (inout ChannelPlotter) -> Void) -> [CGPoint] {
        var plotter = ChannelPlotter(size: size)
        build(&plotter)
        return plotter.points
    }

    /// Collects sampled points in texture space, in fractions of the building.
    struct ChannelPlotter {
        let size: CGSize
        var points: [CGPoint] = []

        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * size.width, y: y * size.height)
        }

        mutating func line(_ from: CGPoint, _ to: CGPoint, steps: Int) {
            for step in 0..<steps {
                let t = CGFloat(step) / CGFloat(steps)
                points.append(CGPoint(x: from.x + (to.x - from.x) * t,
                                      y: from.y + (to.y - from.y) * t))
            }
        }

        mutating func curve(_ from: CGPoint, _ control: CGPoint, to: CGPoint, steps: Int) {
            for step in 0..<steps {
                let t = CGFloat(step) / CGFloat(steps)
                let inverse: CGFloat = 1 - t
                let startWeight: CGFloat = inverse * inverse
                let controlWeight: CGFloat = 2 * inverse * t
                let endWeight: CGFloat = t * t
                let x: CGFloat = startWeight * from.x + controlWeight * control.x
                    + endWeight * to.x
                let y: CGFloat = startWeight * from.y + controlWeight * control.y
                    + endWeight * to.y
                points.append(CGPoint(x: x, y: y))
            }
        }
    }

    /// Strokes a closed channel: the bank, the water in it, and a highlight.
    private static func strokeChannel(_ points: [CGPoint],
                                      in size: CGSize,
                                      bank: UIColor,
                                      bankWidth: CGFloat,
                                      waterWidth: CGFloat) {
        guard points.count > 2 else { return }
        let channel = UIBezierPath()
        channel.move(to: points[0])
        for point in points.dropFirst() { channel.addLine(to: point) }
        channel.close()

        stroke(channel, bank, width: bankWidth)
        stroke(channel, ParkPalette.water, width: waterWidth)
        stroke(channel, ParkPalette.colour(.white).withAlphaComponent(0.30),
               width: max(1, size.height * 0.008))
    }

    // MARK: - River Rapids

    /// The river, in texture space: out of the station, up through three bends
    /// against the current, round the top, and a fast run back down the right
    /// bank to the landing.
    static func riverRapidsPoints(in size: CGSize) -> [CGPoint] {
        plot(in: size) { river in
            river.line(river.at(0.12, 0.88), river.at(0.26, 0.90), steps: 5)
            // Up the left side, kinked, so the channel never reads as an oval.
            river.curve(river.at(0.26, 0.90), river.at(0.42, 0.84),
                        to: river.at(0.40, 0.68), steps: 8)
            river.curve(river.at(0.40, 0.68), river.at(0.38, 0.56),
                        to: river.at(0.24, 0.50), steps: 8)
            river.curve(river.at(0.24, 0.50), river.at(0.10, 0.42),
                        to: river.at(0.18, 0.26), steps: 9)
            // Round the top.
            river.curve(river.at(0.18, 0.26), river.at(0.26, 0.10),
                        to: river.at(0.48, 0.12), steps: 9)
            river.curve(river.at(0.48, 0.12), river.at(0.66, 0.14),
                        to: river.at(0.72, 0.26), steps: 8)
            // Down the right bank, with a hook in it.
            river.curve(river.at(0.72, 0.26), river.at(0.80, 0.38),
                        to: river.at(0.66, 0.46), steps: 8)
            river.curve(river.at(0.66, 0.46), river.at(0.84, 0.54),
                        to: river.at(0.88, 0.68), steps: 9)
            river.curve(river.at(0.88, 0.68), river.at(0.90, 0.84),
                        to: river.at(0.74, 0.90), steps: 8)
            river.line(river.at(0.74, 0.90), river.at(0.26, 0.92), steps: 10)
            river.curve(river.at(0.26, 0.92), river.at(0.06, 0.94),
                        to: river.at(0.12, 0.88), steps: 5)
        }
    }

    /// Grass, a rocky river cut into it, white water on the bends, and a
    /// boarding station at the bottom. No slab: the park's own ground runs up
    /// to the bank, the way it does under the flume.
    static func drawRiverRapidsBase(_ context: CGContext,
                                    _ size: CGSize,
                                    _ primary: UIColor,
                                    _ secondary: UIColor,
                                    _ accent: UIColor) {
        let points = riverRapidsPoints(in: size)

        // Planting first, so the bank overlaps it rather than the other way
        // round.
        for (x, y, scale) in [(0.30, 0.76, 1.0), (0.55, 0.36, 0.9), (0.52, 0.62, 0.8),
                              (0.08, 0.66, 0.9), (0.34, 0.30, 0.7), (0.80, 0.42, 0.8),
                              (0.94, 0.52, 0.7), (0.62, 0.72, 0.9), (0.46, 0.50, 0.6)] {
            let radius = size.height * 0.055 * CGFloat(scale)
            let centre = CGPoint(x: size.width * CGFloat(x), y: size.height * CGFloat(y))
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius,
                                             y: centre.y - radius * 0.85,
                                             width: radius * 2, height: radius * 1.7)),
                 ParkPalette.colour(.green))
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius * 0.55,
                                             y: centre.y - radius * 1.05,
                                             width: radius * 1.1, height: radius)),
                 ParkPalette.colour(.lime))
        }

        strokeChannel(points, in: size,
                      bank: secondary,
                      bankWidth: max(4, size.height * 0.130),
                      waterWidth: max(2, size.height * 0.095))

        // Rocks in the stream, and the broken water round them. Fixed
        // positions, so the same river always looks the same.
        for (index, spot) in [(0.30, 0.79), (0.21, 0.38), (0.60, 0.13),
                              (0.71, 0.36), (0.87, 0.78)].enumerated() {
            let centre = CGPoint(x: size.width * CGFloat(spot.0),
                                 y: size.height * CGFloat(spot.1))
            let radius = size.height * (index % 2 == 0 ? 0.022 : 0.018)
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius, y: centre.y - radius,
                                             width: radius * 2, height: radius * 1.7)),
                 ParkPalette.rockShade)

            let foam = UIBezierPath()
            for step in 0..<3 {
                let spread = CGFloat(step) - 1
                foam.move(to: CGPoint(x: centre.x + spread * radius * 1.3,
                                      y: centre.y + radius * 1.1))
                foam.addLine(to: CGPoint(x: centre.x + spread * radius * 1.8,
                                         y: centre.y + radius * 2.4))
            }
            stroke(foam, ParkPalette.colour(.white).withAlphaComponent(0.75),
                   width: max(1, size.height * 0.009))
        }

        // Riffles down the channel, so still paint reads as moving water.
        let riffles = UIBezierPath()
        for (index, point) in points.enumerated() where index % 9 == 0 {
            riffles.move(to: CGPoint(x: point.x - size.width * 0.012, y: point.y))
            riffles.addLine(to: CGPoint(x: point.x + size.width * 0.012, y: point.y))
        }
        stroke(riffles, ParkPalette.colour(.white).withAlphaComponent(0.45),
               width: max(1, size.height * 0.008))

        // Station across the bottom-left, where the rafts are pulled in.
        let station = CGRect(x: size.width * 0.06, y: size.height * 0.78,
                             width: size.width * 0.20, height: size.height * 0.14)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: station, cornerRadius: station.height * 0.28),
                 primary)
        }
        fill(UIBezierPath(rect: CGRect(x: station.minX, y: station.minY,
                                       width: station.width, height: station.height * 0.32)),
             accent)
    }

    /// A raft from above: an inflated ring with riders round the rim, facing
    /// outward, because a round raft has no front.
    static func drawRaft(_ context: CGContext, _ size: CGSize, _ variant: Int) {
        let ring = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
        fill(UIBezierPath(ovalIn: ring), livery(variant))

        let well = ring.insetBy(dx: ring.width * 0.24, dy: ring.height * 0.24)
        fill(UIBezierPath(ovalIn: well),
             ParkPalette.colour(.charcoal).withAlphaComponent(0.45))

        // Six riders round the ring.
        let head = min(ring.width, ring.height) * 0.20
        let orbit = min(ring.width, ring.height) * 0.32
        let centre = CGPoint(x: ring.midX, y: ring.midY)
        for index in 0..<6 {
            let angle = CGFloat(index) / 6 * .pi * 2
            let point = CGPoint(x: centre.x + cos(angle) * orbit,
                                y: centre.y + sin(angle) * orbit)
            fill(UIBezierPath(ovalIn: CGRect(x: point.x - head / 2, y: point.y - head / 2,
                                             width: head, height: head)),
                 ParkPalette.colour(.cream))
        }
    }

    // MARK: - Lantern Cruise

    /// The canal, in texture space: a rounded loop across the lower two thirds
    /// of the plot, passing under the arch of the show building at the top left
    /// and back out along the front.
    static func lanternCanalPoints(in size: CGSize) -> [CGPoint] {
        plot(in: size) { canal in
            canal.line(canal.at(0.14, 0.86), canal.at(0.80, 0.88), steps: 14)
            canal.curve(canal.at(0.80, 0.88), canal.at(0.92, 0.88),
                        to: canal.at(0.90, 0.72), steps: 6)
            canal.curve(canal.at(0.90, 0.72), canal.at(0.88, 0.56),
                        to: canal.at(0.74, 0.54), steps: 7)
            canal.line(canal.at(0.74, 0.54), canal.at(0.34, 0.50), steps: 9)
            canal.curve(canal.at(0.34, 0.50), canal.at(0.18, 0.48),
                        to: canal.at(0.16, 0.62), steps: 7)
            canal.curve(canal.at(0.16, 0.62), canal.at(0.10, 0.78),
                        to: canal.at(0.14, 0.86), steps: 6)
        }
    }

    /// A show building along the back, a lantern-lit canal in front of it, and
    /// a jetty on the near side. The lanterns are the whole idea of the ride:
    /// strung over the water, on posts along the bank, and lit in the arch the
    /// boats come out of.
    static func drawLanternCruiseBase(_ context: CGContext,
                                      _ size: CGSize,
                                      _ primary: UIColor,
                                      _ secondary: UIColor,
                                      _ accent: UIColor) {
        // Show building across the back.
        let hall = CGRect(x: size.width * 0.08, y: size.height * 0.06,
                          width: size.width * 0.84, height: size.height * 0.36)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: hall, cornerRadius: hall.height * 0.14), primary)
        }

        // A gabled roofline, drawn as three shallow peaks along the top.
        let roof = UIBezierPath()
        roof.move(to: CGPoint(x: hall.minX, y: hall.minY + hall.height * 0.30))
        for index in 0..<3 {
            let span = hall.width / 3
            let startX = hall.minX + span * CGFloat(index)
            roof.addLine(to: CGPoint(x: startX + span / 2,
                                     y: hall.minY - hall.height * 0.14))
            roof.addLine(to: CGPoint(x: startX + span,
                                     y: hall.minY + hall.height * 0.30))
        }
        roof.close()
        fill(roof, secondary)

        // The arch the boats come out of, and the light inside it.
        let arch = CGRect(x: hall.minX + hall.width * 0.10,
                          y: hall.maxY - hall.height * 0.46,
                          width: hall.width * 0.22,
                          height: hall.height * 0.52)
        let mouth = UIBezierPath(roundedRect: arch, cornerRadius: arch.width * 0.45)
        fill(mouth, ParkPalette.colour(.charcoal))
        fill(UIBezierPath(ovalIn: CGRect(x: arch.midX - arch.width * 0.20,
                                         y: arch.minY + arch.height * 0.18,
                                         width: arch.width * 0.40,
                                         height: arch.width * 0.40)),
             accent.withAlphaComponent(0.75))

        // Windows along the rest of the facade, lit.
        let windowWidth = hall.width * 0.075
        for index in 0..<4 {
            let x = hall.minX + hall.width * (0.42 + 0.14 * CGFloat(index))
            let pane = CGRect(x: x, y: hall.maxY - hall.height * 0.40,
                              width: windowWidth, height: hall.height * 0.30)
            fill(UIBezierPath(roundedRect: pane, cornerRadius: pane.width * 0.35),
                 accent.withAlphaComponent(0.85))
        }

        let points = lanternCanalPoints(in: size)
        strokeChannel(points, in: size,
                      bank: ParkPalette.colour(.cream),
                      bankWidth: max(4, size.height * 0.110),
                      waterWidth: max(2, size.height * 0.075))

        // Lantern posts along the outer bank, each with its own glow. Taken
        // off the canal itself, so they space themselves round the loop rather
        // than needing positions of their own.
        for (index, point) in points.enumerated() where index % 12 == 0 {
            let post = UIBezierPath()
            post.move(to: CGPoint(x: point.x, y: point.y + size.height * 0.055))
            post.addLine(to: CGPoint(x: point.x, y: point.y + size.height * 0.085))
            stroke(post, ParkPalette.colour(.brown), width: max(1, size.width * 0.008))

            let bulb = size.height * 0.024
            fill(UIBezierPath(ovalIn: CGRect(x: point.x - bulb,
                                             y: point.y + size.height * 0.040,
                                             width: bulb * 2, height: bulb * 2)),
                 accent.withAlphaComponent(0.35))
            fill(UIBezierPath(ovalIn: CGRect(x: point.x - bulb * 0.5,
                                             y: point.y + size.height * 0.050,
                                             width: bulb, height: bulb)),
                 accent)
        }

        // A string of bunting lanterns across the middle of the loop, over the
        // water, which is what the guests in the boats look up at.
        let string = UIBezierPath()
        let left = CGPoint(x: size.width * 0.20, y: size.height * 0.66)
        let right = CGPoint(x: size.width * 0.82, y: size.height * 0.70)
        string.move(to: left)
        string.addQuadCurve(to: right,
                            controlPoint: CGPoint(x: size.width * 0.5,
                                                  y: size.height * 0.78))
        stroke(string, ParkPalette.colour(.charcoal).withAlphaComponent(0.45),
               width: max(1, size.height * 0.007))
        for index in 0..<5 {
            let t = CGFloat(index + 1) / 6
            let inverse: CGFloat = 1 - t
            let startWeight: CGFloat = inverse * inverse
            let controlWeight: CGFloat = 2 * inverse * t
            let endWeight: CGFloat = t * t
            let x: CGFloat = startWeight * left.x + controlWeight * size.width * 0.5
                + endWeight * right.x
            let y: CGFloat = startWeight * left.y + controlWeight * size.height * 0.78
                + endWeight * right.y
            let bulb = size.height * 0.020
            fill(UIBezierPath(ovalIn: CGRect(x: x - bulb, y: y,
                                             width: bulb * 2, height: bulb * 2.4)),
                 index % 2 == 0 ? accent : ParkPalette.colour(.pink))
        }

        // Jetty on the near bank, where the queue steps into a boat.
        let jetty = CGRect(x: size.width * 0.20, y: size.height * 0.88,
                           width: size.width * 0.26, height: size.height * 0.09)
        fill(UIBezierPath(roundedRect: jetty, cornerRadius: jetty.height * 0.3),
             ParkPalette.colour(.brown))
    }

    /// A canal boat, prow to the right, with a lantern on a pole at the front
    /// and passengers sitting down the middle.
    static func drawCanalBoat(_ context: CGContext,
                              _ size: CGSize,
                              _ primary: UIColor,
                              _ secondary: UIColor,
                              _ accent: UIColor) {
        let hull = UIBezierPath()
        let top = size.height * 0.20
        let bottom = size.height * 0.80
        hull.move(to: CGPoint(x: size.width * 0.06, y: top))
        hull.addLine(to: CGPoint(x: size.width * 0.70, y: top))
        hull.addQuadCurve(to: CGPoint(x: size.width * 0.70, y: bottom),
                          controlPoint: CGPoint(x: size.width * 1.08, y: size.height * 0.5))
        hull.addLine(to: CGPoint(x: size.width * 0.06, y: bottom))
        hull.addQuadCurve(to: CGPoint(x: size.width * 0.06, y: top),
                          controlPoint: CGPoint(x: size.width * -0.06, y: size.height * 0.5))
        hull.close()
        fill(hull, ParkPalette.colour(.brown))

        let well = CGRect(x: size.width * 0.14, y: size.height * 0.34,
                          width: size.width * 0.54, height: size.height * 0.32)
        fill(UIBezierPath(roundedRect: well, cornerRadius: well.height * 0.4), secondary)

        let head = size.height * 0.26
        for offset in [CGFloat(0.22), CGFloat(0.40), CGFloat(0.58)] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * offset,
                                             y: size.height * 0.5 - head / 2,
                                             width: head, height: head)),
                 ParkPalette.colour(.cream))
        }

        // The lantern at the prow. Small, bright, and the reason the ride has
        // its name.
        let bulb = size.height * 0.16
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.80 - bulb,
                                         y: size.height * 0.5 - bulb,
                                         width: bulb * 2, height: bulb * 2)),
             accent.withAlphaComponent(0.40))
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.80 - bulb * 0.5,
                                         y: size.height * 0.5 - bulb * 0.5,
                                         width: bulb, height: bulb)),
             accent)
    }
}
