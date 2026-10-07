import SpriteKit
import UIKit

/// Decoration made for the water.
///
/// Every piece here is drawn on a clear background and is meant to be placed
/// on a pond tile, so the water shows through round it. Each one also lays
/// down a soft patch of water of its own first: in the build menu the piece
/// is drawn on a plain card, and lily pads or lanterns with no water under
/// them read as green and red blobs rather than as floating things.
extension BuildingArtwork {

    // MARK: - Shared pieces

    /// A calm patch under the piece. Translucent, so on a real pond it only
    /// deepens the water a little and does not show an edge.
    private static func drawWaterPatch(_ size: CGSize) {
        let area = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.04, dy: size.height * 0.04)
        fill(UIBezierPath(ovalIn: area), ParkPalette.water.withAlphaComponent(0.55))
    }

    /// A pale ring on the surface, which is what tells the eye that something
    /// is sitting in water rather than on top of it.
    private static func drawRipple(around rect: CGRect, width: CGFloat) {
        let ring = UIBezierPath(ovalIn: rect)
        stroke(ring, UIColor.white.withAlphaComponent(0.55), width: width)
    }

    private static func discRect(centre: CGPoint, diameter: CGFloat) -> CGRect {
        CGRect(x: centre.x - diameter / 2, y: centre.y - diameter / 2,
               width: diameter, height: diameter)
    }

    // MARK: - Lily pads

    private struct LilyPad {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let turn: CGFloat
        let flower: Bool
    }

    static func drawLilyPads(_ context: CGContext,
                             _ size: CGSize,
                             _ primary: UIColor,
                             _ secondary: UIColor,
                             _ accent: UIColor,
                             _ variant: Int) {
        drawWaterPatch(size)

        let layouts: [[LilyPad]] = [
            [LilyPad(x: 0.30, y: 0.64, radius: 0.17, turn: 0.4, flower: false),
             LilyPad(x: 0.64, y: 0.40, radius: 0.21, turn: 2.2, flower: true),
             LilyPad(x: 0.70, y: 0.76, radius: 0.11, turn: 4.0, flower: false)],
            [LilyPad(x: 0.50, y: 0.50, radius: 0.24, turn: 1.0, flower: true),
             LilyPad(x: 0.22, y: 0.28, radius: 0.12, turn: 3.1, flower: false),
             LilyPad(x: 0.78, y: 0.74, radius: 0.12, turn: 5.0, flower: false)],
            [LilyPad(x: 0.25, y: 0.70, radius: 0.15, turn: 0.2, flower: false),
             LilyPad(x: 0.52, y: 0.58, radius: 0.17, turn: 2.0, flower: false),
             LilyPad(x: 0.76, y: 0.34, radius: 0.15, turn: 3.6, flower: true),
             LilyPad(x: 0.34, y: 0.26, radius: 0.11, turn: 5.2, flower: false)]
        ]

        let reference = min(size.width, size.height)
        let notch: CGFloat = 0.55

        for pad in layouts[variant % layouts.count] {
            let centre = CGPoint(x: pad.x * size.width, y: pad.y * size.height)
            let radius = pad.radius * reference
            let start = pad.turn + notch / 2
            let end = pad.turn + CGFloat.pi * 2 - notch / 2

            // A round leaf with a wedge missing, which is what makes it a
            // lily pad and not a plate.
            let leaf = UIBezierPath()
            leaf.move(to: centre)
            leaf.addArc(withCenter: centre, radius: radius,
                        startAngle: start, endAngle: end, clockwise: true)
            leaf.close()
            withShadow(context) { fill(leaf, primary) }

            let sheen = UIBezierPath()
            sheen.move(to: centre)
            sheen.addArc(withCenter: centre, radius: radius * 0.6,
                         startAngle: start, endAngle: end, clockwise: true)
            sheen.close()
            fill(sheen, accent.withAlphaComponent(0.5))

            if pad.flower {
                drawBlossom(at: centre, radius: radius * 0.7, petal: secondary)
            }
        }
    }

    private static func drawBlossom(at centre: CGPoint, radius: CGFloat, petal: UIColor) {
        let petalSize = radius * 0.62
        for index in 0..<5 {
            let angle = CGFloat(index) / 5 * CGFloat.pi * 2
            let spot = CGPoint(x: centre.x + cos(angle) * radius * 0.5,
                               y: centre.y + sin(angle) * radius * 0.5)
            fill(UIBezierPath(ovalIn: discRect(centre: spot, diameter: petalSize)), petal)
        }
        let heart = discRect(centre: centre, diameter: radius * 0.4)
        fill(UIBezierPath(ovalIn: heart), ParkPalette.colour(.yellow))
    }

    // MARK: - Reeds

    static func drawReeds(_ context: CGContext,
                          _ size: CGSize,
                          _ primary: UIColor,
                          _ secondary: UIColor,
                          _ accent: UIColor,
                          _ variant: Int) {
        drawWaterPatch(size)

        let ripple = CGRect(x: size.width * 0.14, y: size.height * 0.72,
                            width: size.width * 0.72, height: size.height * 0.20)
        drawRipple(around: ripple, width: max(1.5, size.width * 0.02))

        let leans: [[CGFloat]] = [
            [-0.10, 0.02, 0.09, 0.14],
            [0.12, 0.04, -0.06, -0.12],
            [-0.04, 0.08, -0.08, 0.05]
        ]
        let lean = leans[variant % leans.count]
        let bases: [CGFloat] = [0.30, 0.44, 0.58, 0.72]
        let tops: [CGFloat] = [0.18, 0.08, 0.14, 0.24]
        let stalk = max(2, size.width * 0.045)

        for index in 0..<bases.count {
            let base = CGPoint(x: bases[index] * size.width, y: size.height * 0.86)
            let tip = CGPoint(x: base.x + lean[index] * size.width,
                              y: tops[index] * size.height)
            let bow = CGPoint(x: base.x, y: (base.y + tip.y) / 2)

            let blade = UIBezierPath()
            blade.move(to: base)
            blade.addQuadCurve(to: tip, controlPoint: bow)
            blade.lineCapStyle = .round
            stroke(blade, index % 2 == 0 ? primary : accent, width: stalk)

            // Cattail heads on alternate stalks.
            if index % 2 == 0 {
                let headWidth = stalk * 1.9
                let headHeight = stalk * 4.2
                let head = CGRect(x: tip.x - headWidth / 2,
                                  y: tip.y - headHeight * 0.1,
                                  width: headWidth, height: headHeight)
                fill(UIBezierPath(roundedRect: head, cornerRadius: headWidth / 2), secondary)
            }
        }
    }

    // MARK: - Water rocks

    /// How far each corner of a boulder is pushed in or out, so no two sides
    /// match. Fixed rather than random: the same rock must draw the same way
    /// every time its texture is rebuilt.
    private static let boulderProfile: [CGFloat] = [1.0, 0.86, 0.96, 0.82, 1.0, 0.88, 0.94, 0.84]

    static func drawWaterRock(_ context: CGContext,
                              _ size: CGSize,
                              _ primary: UIColor,
                              _ secondary: UIColor,
                              _ accent: UIColor,
                              _ variant: Int) {
        drawWaterPatch(size)
        let reference = min(size.width, size.height)

        // Where each boulder sits, how big it is, and how it is turned.
        let layouts: [[(x: CGFloat, y: CGFloat, radius: CGFloat, turn: CGFloat)]] = [
            [(0.50, 0.52, 0.27, 0.3)],
            [(0.36, 0.56, 0.22, 0.9), (0.66, 0.40, 0.16, 2.4), (0.64, 0.72, 0.11, 4.1)],
            [(0.26, 0.64, 0.13, 0.5), (0.50, 0.46, 0.14, 1.7), (0.74, 0.60, 0.13, 3.2),
             (0.60, 0.26, 0.09, 4.4)]
        ]

        for spot in layouts[variant % layouts.count] {
            let centre = CGPoint(x: spot.x * size.width, y: spot.y * size.height)
            let radius = spot.radius * reference

            // Foam first, so the rock stands in it.
            let wash = CGRect(x: centre.x - radius * 1.35, y: centre.y - radius * 1.05,
                              width: radius * 2.7, height: radius * 2.1)
            drawRipple(around: wash, width: max(1.5, radius * 0.16))

            drawBoulder(context, centre: centre, radius: radius, turn: spot.turn,
                        stone: primary, moss: secondary, foam: accent)
        }
    }

    private static func drawBoulder(_ context: CGContext,
                                    centre: CGPoint,
                                    radius: CGFloat,
                                    turn: CGFloat,
                                    stone: UIColor,
                                    moss: UIColor,
                                    foam: UIColor) {
        func outline(scale: CGFloat, lift: CGFloat) -> UIBezierPath {
            let path = UIBezierPath()
            let corners = boulderProfile.count
            for index in 0..<corners {
                let angle = turn + CGFloat(index) / CGFloat(corners) * CGFloat.pi * 2
                let reach = radius * scale * boulderProfile[index]
                let point = CGPoint(x: centre.x + cos(angle) * reach,
                                    y: centre.y + sin(angle) * reach * 0.82 - lift)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.close()
            path.lineJoinStyle = .round
            return path
        }

        let body = outline(scale: 1.0, lift: 0)
        withShadow(context) { fill(body, stone) }
        stroke(body, stone, width: max(1.5, radius * 0.18))

        // A paler face catching the light, then moss on the top of it.
        fill(outline(scale: 0.62, lift: radius * 0.18), UIColor.white.withAlphaComponent(0.28))
        let mossRect = CGRect(x: centre.x - radius * 0.55, y: centre.y - radius * 0.62,
                              width: radius * 0.80, height: radius * 0.42)
        fill(UIBezierPath(ovalIn: mossRect), moss.withAlphaComponent(0.85))

        // A fleck of foam where the water breaks on it.
        let splash = CGRect(x: centre.x + radius * 0.35, y: centre.y + radius * 0.50,
                            width: radius * 0.50, height: radius * 0.20)
        fill(UIBezierPath(ovalIn: splash), foam.withAlphaComponent(0.85))
    }

    // MARK: - Floating lanterns

    static func drawFloatingLanterns(_ context: CGContext,
                                     _ size: CGSize,
                                     _ primary: UIColor,
                                     _ secondary: UIColor,
                                     _ accent: UIColor,
                                     _ variant: Int) {
        drawWaterPatch(size)

        let reference = min(size.width, size.height)
        let spots: [(x: CGFloat, y: CGFloat, scale: CGFloat)] = variant % 2 == 0
            ? [(0.22, 0.56, 1.0), (0.50, 0.40, 0.8), (0.78, 0.58, 0.95)]
            : [(0.28, 0.42, 0.9), (0.52, 0.66, 1.0), (0.76, 0.40, 0.85)]
        let glow = ParkPalette.colour(.amber)

        for (index, spot) in spots.enumerated() {
            let side = reference * 0.28 * spot.scale
            let centre = CGPoint(x: spot.x * size.width, y: spot.y * size.height)

            // The light first, spilling onto the water round it.
            fill(UIBezierPath(ovalIn: discRect(centre: centre, diameter: side * 2.6)),
                 glow.withAlphaComponent(0.20))
            fill(UIBezierPath(ovalIn: discRect(centre: centre, diameter: side * 1.7)),
                 glow.withAlphaComponent(0.30))

            let paper = CGRect(x: centre.x - side / 2, y: centre.y - side * 0.45,
                               width: side, height: side * 0.9)
            withShadow(context) {
                fill(UIBezierPath(roundedRect: paper, cornerRadius: side * 0.3),
                     index % 2 == 0 ? primary : secondary)
            }

            // Ribs, a cap and the flame showing through.
            let rib = UIBezierPath()
            rib.move(to: CGPoint(x: centre.x, y: paper.minY))
            rib.addLine(to: CGPoint(x: centre.x, y: paper.maxY))
            stroke(rib, accent.withAlphaComponent(0.7), width: max(1, side * 0.06))

            let cap = CGRect(x: paper.minX + side * 0.18, y: paper.minY - side * 0.06,
                             width: side * 0.64, height: side * 0.14)
            fill(UIBezierPath(roundedRect: cap, cornerRadius: side * 0.05),
                 ParkPalette.colour(.charcoal))

            let flame = discRect(centre: centre, diameter: side * 0.34)
            fill(UIBezierPath(ovalIn: flame), accent)
        }
    }

    // MARK: - Pond fountain

    /// The stone ring and pedestal. The jet is drawn on its own so it can
    /// pulse, exactly as it is for a fountain on the ground.
    static func drawPondFountainBasin(_ context: CGContext,
                                      _ size: CGSize,
                                      _ primary: UIColor,
                                      _ secondary: UIColor,
                                      _ accent: UIColor,
                                      _ variant: Int) {
        drawWaterPatch(size)

        let reference = min(size.width, size.height)
        let ring = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.14, dy: size.height * 0.14)

        withShadow(context) {
            stroke(UIBezierPath(ovalIn: ring), primary, width: reference * 0.09)
        }
        stroke(UIBezierPath(ovalIn: ring), secondary.withAlphaComponent(0.6),
               width: reference * 0.025)

        // Rings spreading out from the jet.
        let inner = ring.insetBy(dx: ring.width * 0.22, dy: ring.height * 0.22)
        drawRipple(around: inner, width: max(1.5, reference * 0.025))
        if variant % 2 == 1 {
            let tier = ring.insetBy(dx: ring.width * 0.36, dy: ring.height * 0.36)
            stroke(UIBezierPath(ovalIn: tier), primary, width: reference * 0.06)
        }

        let pedestal = discRect(centre: CGPoint(x: size.width / 2, y: size.height / 2),
                                diameter: reference * 0.16)
        fill(UIBezierPath(ovalIn: pedestal), accent)
    }
}
