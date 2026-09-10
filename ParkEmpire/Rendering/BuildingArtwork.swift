import SpriteKit
import UIKit

/// Draws the per-motif building artwork.
///
/// Every shape is generated with bezier paths and cached as an `SKTexture`, so
/// the project stays free of image assets. Each motif produces two textures:
/// the static body, and optionally the one part that moves.
enum BuildingArtwork {

    // MARK: - Public entry points

    private static var previewCache: [String: UIImage] = [:]

    /// The building itself, without whatever moves on top of it.
    static func bodyTexture(for appearance: BuildingAppearance, size: CGSize) -> SKTexture {
        SpriteFactory.texture(key: key(for: appearance, prefix: "body", size: size), size: size) {
            context, size in
            drawBody(appearance, context, size)
        }
    }

    /// The same artwork as a plain image, for the build menu. Cached, because
    /// SwiftUI rebuilds the menu far more often than the catalogue changes.
    static func previewImage(for appearance: BuildingAppearance, size: CGSize) -> UIImage {
        let cacheKey = key(for: appearance, prefix: "preview", size: size)
        if let cached = previewCache[cacheKey] { return cached }

        let image = UIGraphicsImageRenderer(size: size).image { rendererContext in
            drawBody(appearance, rendererContext.cgContext, size)
        }
        previewCache[cacheKey] = image
        return image
    }

    private static func key(for appearance: BuildingAppearance,
                            prefix: String,
                            size: CGSize) -> String {
        "\(prefix)-\(appearance.motif.rawValue)-\(appearance.primary.rawValue)"
            + "-\(appearance.secondary.rawValue)-\(appearance.accent.rawValue)"
            + "-\(Int(size.width))x\(Int(size.height))"
    }

    /// Shared by the map texture and the menu preview, so the two can never
    /// show different artwork for the same thing.
    private static func drawBody(_ appearance: BuildingAppearance,
                                 _ context: CGContext,
                                 _ size: CGSize) {
        let primary = ParkPalette.colour(appearance.primary)
        let secondary = ParkPalette.colour(appearance.secondary)
        let accent = ParkPalette.colour(appearance.accent)

        switch appearance.motif {
        case .carousel:  drawCarouselBase(context, size, primary, secondary, accent)
        case .swingBoat: drawSwingBoatBase(context, size, primary, secondary, accent)
        case .dropTower: drawDropTowerBase(context, size, primary, secondary, accent)
        case .coaster:   drawCoasterBase(context, size, primary, secondary, accent)
        case .stall:     drawStall(context, size, primary, secondary, accent)
        case .kiosk:     drawKiosk(context, size, primary, secondary, accent)
        case .shopFront: drawShopFront(context, size, primary, secondary, accent)
        case .restroom:  drawRestroom(context, size, primary, secondary, accent)
        case .bench:     drawBench(context, size, primary, secondary, accent)
        case .bin:       drawBin(context, size, primary, secondary, accent)
        case .tree:      drawTree(context, size, primary, secondary, accent)
        case .conifer:   drawConifer(context, size, primary, secondary, accent)
        case .flowerBed: drawFlowerBed(context, size, primary, secondary, accent)
        case .fountain:  drawFountainBasin(context, size, primary, secondary, accent)
        case .lamp:      drawLamp(context, size, primary, secondary, accent)
        case .topiary:   drawTopiary(context, size, primary, secondary, accent)
        case .statue:    drawStatue(context, size, primary, secondary, accent)
        }
    }

    /// The moving part, drawn in its own texture so it can be animated
    /// independently. Nil for anything that does not move.
    static func motionTexture(for appearance: BuildingAppearance, size: CGSize) -> SKTexture? {
        guard appearance.motif.motion != .none else { return nil }

        let partSize = motionPartSize(for: appearance.motif, buildingSize: size)
        let key = "motion-\(appearance.motif.rawValue)-\(appearance.primary.rawValue)"
            + "-\(appearance.secondary.rawValue)-\(appearance.accent.rawValue)"
            + "-\(Int(partSize.width))x\(Int(partSize.height))"

        return SpriteFactory.texture(key: key, size: partSize) { context, size in
            let primary = ParkPalette.colour(appearance.primary)
            let secondary = ParkPalette.colour(appearance.secondary)
            let accent = ParkPalette.colour(appearance.accent)

            switch appearance.motif {
            case .carousel:  drawCanopy(context, size, primary, secondary, accent)
            case .swingBoat: drawBoat(context, size, primary, secondary, accent)
            case .dropTower: drawTowerCar(context, size, primary, secondary, accent)
            case .coaster:   drawTrain(context, size, primary, secondary, accent)
            case .fountain:  drawFountainJet(context, size, primary, secondary, accent)
            default:         break
            }
        }
    }

    /// Size of the moving part relative to the building it sits on.
    static func motionPartSize(for motif: BuildingMotif, buildingSize: CGSize) -> CGSize {
        let shortest = min(buildingSize.width, buildingSize.height)
        switch motif {
        case .carousel:
            return CGSize(width: shortest * 0.78, height: shortest * 0.78)
        case .swingBoat:
            return CGSize(width: buildingSize.width * 0.46, height: buildingSize.height * 0.52)
        case .dropTower:
            return CGSize(width: shortest * 0.30, height: shortest * 0.18)
        case .coaster:
            return CGSize(width: shortest * 0.26, height: shortest * 0.16)
        case .fountain:
            return CGSize(width: shortest * 0.30, height: shortest * 0.42)
        default:
            return .zero
        }
    }

    // MARK: - Shared drawing helpers

    private static func fill(_ path: UIBezierPath, _ colour: UIColor) {
        colour.setFill()
        path.fill()
    }

    private static func stroke(_ path: UIBezierPath, _ colour: UIColor, width: CGFloat) {
        colour.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    /// A soft drop shadow so buildings sit above the grass rather than on it.
    private static func withShadow(_ context: CGContext, _ body: () -> Void) {
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 2),
                          blur: 4,
                          color: UIColor.black.withAlphaComponent(0.28).cgColor)
        body()
        context.restoreGState()
    }

    // MARK: - Rides

    private static func drawCarouselBase(_ context: CGContext,
                                         _ size: CGSize,
                                         _ primary: UIColor,
                                         _ secondary: UIColor,
                                         _ accent: UIColor) {
        let inset = min(size.width, size.height) * 0.08
        let platform = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)

        withShadow(context) {
            fill(UIBezierPath(ovalIn: platform), secondary)
        }
        stroke(UIBezierPath(ovalIn: platform), accent, width: max(1, size.width * 0.02))

        // Horses read as spokes at this size; a ring of dots is clearer.
        let radius = platform.width * 0.34
        let centre = CGPoint(x: platform.midX, y: platform.midY)
        for index in 0..<8 {
            let angle = CGFloat(index) / 8 * .pi * 2
            let dot = CGSize(width: platform.width * 0.10, height: platform.width * 0.10)
            let point = CGPoint(x: centre.x + cos(angle) * radius - dot.width / 2,
                                y: centre.y + sin(angle) * radius - dot.height / 2)
            fill(UIBezierPath(ovalIn: CGRect(origin: point, size: dot)), primary)
        }
    }

    /// The striped conical roof. Drawn square so it can spin about its centre.
    private static func drawCanopy(_ context: CGContext,
                                   _ size: CGSize,
                                   _ primary: UIColor,
                                   _ secondary: UIColor,
                                   _ accent: UIColor) {
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
            wedge.addArc(withCenter: centre, radius: radius,
                         startAngle: start, endAngle: end, clockwise: true)
            wedge.close()
            fill(wedge, index % 2 == 0 ? primary : ParkPalette.colour(.cream))
        }
        context.restoreGState()

        // Centre pole cap.
        let cap = CGRect(x: centre.x - radius * 0.16, y: centre.y - radius * 0.16,
                         width: radius * 0.32, height: radius * 0.32)
        fill(UIBezierPath(ovalIn: cap), accent)
    }

    private static func drawSwingBoatBase(_ context: CGContext,
                                          _ size: CGSize,
                                          _ primary: UIColor,
                                          _ secondary: UIColor,
                                          _ accent: UIColor) {
        // Ground pad.
        let pad = CGRect(x: size.width * 0.08, y: size.height * 0.62,
                         width: size.width * 0.84, height: size.height * 0.30)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: pad, cornerRadius: pad.height * 0.35), secondary)
        }

        // A-frame, drawn as two thick legs meeting near the top.
        let apex = CGPoint(x: size.width / 2, y: size.height * 0.14)
        let legWidth = max(2, size.width * 0.045)
        for direction in [CGFloat(-1), CGFloat(1)] {
            let foot = CGPoint(x: size.width / 2 + direction * size.width * 0.30,
                               y: size.height * 0.70)
            let leg = UIBezierPath()
            leg.move(to: apex)
            leg.addLine(to: foot)
            stroke(leg, accent, width: legWidth)
        }

        let hub = CGRect(x: apex.x - legWidth, y: apex.y - legWidth,
                         width: legWidth * 2, height: legWidth * 2)
        fill(UIBezierPath(ovalIn: hub), primary)
    }

    /// Hull plus its two suspension arms, drawn hanging from the top edge so
    /// the sprite can pivot about that point.
    private static func drawBoat(_ context: CGContext,
                                 _ size: CGSize,
                                 _ primary: UIColor,
                                 _ secondary: UIColor,
                                 _ accent: UIColor) {
        let armWidth = max(1.5, size.width * 0.07)
        for direction in [CGFloat(-1), CGFloat(1)] {
            let arm = UIBezierPath()
            arm.move(to: CGPoint(x: size.width / 2, y: 1))
            arm.addLine(to: CGPoint(x: size.width / 2 + direction * size.width * 0.30,
                                    y: size.height * 0.66))
            stroke(arm, accent, width: armWidth)
        }

        // Hull: flat deck, curved bottom.
        let hull = UIBezierPath()
        let top = size.height * 0.62
        let bottom = size.height * 0.96
        hull.move(to: CGPoint(x: size.width * 0.06, y: top))
        hull.addLine(to: CGPoint(x: size.width * 0.94, y: top))
        hull.addQuadCurve(to: CGPoint(x: size.width * 0.50, y: bottom),
                          controlPoint: CGPoint(x: size.width * 0.86, y: bottom))
        hull.addQuadCurve(to: CGPoint(x: size.width * 0.06, y: top),
                          controlPoint: CGPoint(x: size.width * 0.14, y: bottom))
        hull.close()
        fill(hull, primary)

        let stripe = CGRect(x: size.width * 0.10, y: top + (bottom - top) * 0.18,
                            width: size.width * 0.80, height: max(1, size.height * 0.05))
        fill(UIBezierPath(rect: stripe), ParkPalette.colour(.cream))
    }

    private static func drawDropTowerBase(_ context: CGContext,
                                          _ size: CGSize,
                                          _ primary: UIColor,
                                          _ secondary: UIColor,
                                          _ accent: UIColor) {
        let pad = CGRect(x: size.width * 0.10, y: size.height * 0.74,
                         width: size.width * 0.80, height: size.height * 0.20)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: pad, cornerRadius: pad.height * 0.35), secondary)
        }

        let column = CGRect(x: size.width * 0.42, y: size.height * 0.06,
                            width: size.width * 0.16, height: size.height * 0.72)
        fill(UIBezierPath(roundedRect: column, cornerRadius: column.width * 0.3), accent)

        // Banding up the column gives the drop something to read against.
        let bands = 5
        for index in 0..<bands {
            let y = column.minY + column.height * (CGFloat(index) + 0.5) / CGFloat(bands)
            let band = CGRect(x: column.minX, y: y, width: column.width,
                              height: max(1, size.height * 0.015))
            fill(UIBezierPath(rect: band), ParkPalette.colour(.cream))
        }

        let cap = CGRect(x: size.width * 0.36, y: size.height * 0.02,
                         width: size.width * 0.28, height: size.height * 0.07)
        fill(UIBezierPath(roundedRect: cap, cornerRadius: cap.height * 0.4), primary)
    }

    private static func drawTowerCar(_ context: CGContext,
                                     _ size: CGSize,
                                     _ primary: UIColor,
                                     _ secondary: UIColor,
                                     _ accent: UIColor) {
        let body = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
        fill(UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.35), primary)
        let seats = body.insetBy(dx: body.width * 0.14, dy: body.height * 0.30)
        fill(UIBezierPath(rect: seats), ParkPalette.colour(.charcoal))
    }

    private static func drawCoasterBase(_ context: CGContext,
                                        _ size: CGSize,
                                        _ primary: UIColor,
                                        _ secondary: UIColor,
                                        _ accent: UIColor) {
        let ground = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.05, dy: size.height * 0.06)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: ground, cornerRadius: ground.height * 0.14), secondary)
        }

        let track = trackRect(in: size)
        // Sleepers first, then the rail on top, so the rail reads continuous.
        stroke(UIBezierPath(ovalIn: track), ParkPalette.colour(.charcoal),
               width: max(2, size.height * 0.075))
        stroke(UIBezierPath(ovalIn: track), accent, width: max(1, size.height * 0.035))

        // Station shed on the near side of the loop.
        let station = CGRect(x: track.midX - size.width * 0.13,
                             y: track.maxY - size.height * 0.06,
                             width: size.width * 0.26,
                             height: size.height * 0.16)
        fill(UIBezierPath(roundedRect: station, cornerRadius: station.height * 0.3), primary)
    }

    private static func drawTrain(_ context: CGContext,
                                  _ size: CGSize,
                                  _ primary: UIColor,
                                  _ secondary: UIColor,
                                  _ accent: UIColor) {
        let body = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
        fill(UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.4), primary)
        let nose = CGRect(x: body.maxX - body.width * 0.28, y: body.minY,
                          width: body.width * 0.28, height: body.height)
        fill(UIBezierPath(roundedRect: nose, cornerRadius: body.height * 0.4),
             ParkPalette.colour(.cream))
    }

    /// The oval the coaster train runs, in texture coordinates. Shared so the
    /// drawn track and the animation path cannot drift apart.
    static func trackRect(in size: CGSize) -> CGRect {
        CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.16, dy: size.height * 0.20)
    }

    // MARK: - Shops and services

    private static func drawStall(_ context: CGContext,
                                  _ size: CGSize,
                                  _ primary: UIColor,
                                  _ secondary: UIColor,
                                  _ accent: UIColor) {
        let body = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.09, dy: size.height * 0.09)

        withShadow(context) {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.14), primary)
        }

        // Striped awning across the top third.
        let awning = CGRect(x: body.minX, y: body.minY,
                            width: body.width, height: body.height * 0.34)
        context.saveGState()
        UIBezierPath(roundedRect: awning, cornerRadius: body.width * 0.14).addClip()
        let stripes = 6
        for index in 0..<stripes {
            let stripe = CGRect(x: awning.minX + awning.width * CGFloat(index) / CGFloat(stripes),
                                y: awning.minY,
                                width: awning.width / CGFloat(stripes),
                                height: awning.height)
            fill(UIBezierPath(rect: stripe),
                 index % 2 == 0 ? secondary : ParkPalette.colour(.cream))
        }
        context.restoreGState()

        // Counter.
        let counter = CGRect(x: body.minX + body.width * 0.12,
                             y: body.maxY - body.height * 0.26,
                             width: body.width * 0.76,
                             height: body.height * 0.16)
        fill(UIBezierPath(roundedRect: counter, cornerRadius: counter.height * 0.3), accent)
    }

    private static func drawKiosk(_ context: CGContext,
                                  _ size: CGSize,
                                  _ primary: UIColor,
                                  _ secondary: UIColor,
                                  _ accent: UIColor) {
        let body = CGRect(x: size.width * 0.16, y: size.height * 0.30,
                          width: size.width * 0.68, height: size.height * 0.60)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.16), primary)
        }

        // Domed roof overhanging the body.
        let dome = CGRect(x: size.width * 0.08, y: size.height * 0.10,
                          width: size.width * 0.84, height: size.height * 0.34)
        fill(UIBezierPath(ovalIn: dome), secondary)

        let window = CGRect(x: body.minX + body.width * 0.18,
                            y: body.minY + body.height * 0.28,
                            width: body.width * 0.64,
                            height: body.height * 0.34)
        fill(UIBezierPath(roundedRect: window, cornerRadius: window.height * 0.25), accent)
    }

    private static func drawShopFront(_ context: CGContext,
                                      _ size: CGSize,
                                      _ primary: UIColor,
                                      _ secondary: UIColor,
                                      _ accent: UIColor) {
        let body = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.08, dy: size.height * 0.08)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.12), primary)
        }

        let roof = CGRect(x: body.minX, y: body.minY,
                          width: body.width, height: body.height * 0.26)
        context.saveGState()
        UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.12).addClip()
        fill(UIBezierPath(rect: roof), secondary)
        context.restoreGState()

        let windows = 3
        for index in 0..<windows {
            let slot = body.width / CGFloat(windows)
            let window = CGRect(x: body.minX + slot * CGFloat(index) + slot * 0.22,
                                y: body.minY + body.height * 0.46,
                                width: slot * 0.56,
                                height: body.height * 0.34)
            fill(UIBezierPath(roundedRect: window, cornerRadius: window.width * 0.2), accent)
        }
    }

    private static func drawRestroom(_ context: CGContext,
                                     _ size: CGSize,
                                     _ primary: UIColor,
                                     _ secondary: UIColor,
                                     _ accent: UIColor) {
        let body = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.10, dy: size.height * 0.10)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.12), primary)
        }

        let roof = CGRect(x: body.minX, y: body.minY,
                          width: body.width, height: body.height * 0.22)
        context.saveGState()
        UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.12).addClip()
        fill(UIBezierPath(rect: roof), secondary)
        context.restoreGState()

        // Two doors, which is what makes a restroom readable at this size.
        for direction in [CGFloat(0), CGFloat(1)] {
            let door = CGRect(x: body.minX + body.width * (0.16 + 0.38 * direction),
                              y: body.minY + body.height * 0.38,
                              width: body.width * 0.30,
                              height: body.height * 0.50)
            fill(UIBezierPath(roundedRect: door, cornerRadius: door.width * 0.2), accent)
        }
    }

    private static func drawBench(_ context: CGContext,
                                  _ size: CGSize,
                                  _ primary: UIColor,
                                  _ secondary: UIColor,
                                  _ accent: UIColor) {
        let seat = CGRect(x: size.width * 0.10, y: size.height * 0.40,
                          width: size.width * 0.80, height: size.height * 0.30)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: seat, cornerRadius: seat.height * 0.3), primary)
        }
        let back = CGRect(x: size.width * 0.10, y: size.height * 0.22,
                          width: size.width * 0.80, height: size.height * 0.14)
        fill(UIBezierPath(roundedRect: back, cornerRadius: back.height * 0.4), secondary)

        for direction in [CGFloat(0), CGFloat(1)] {
            let leg = CGRect(x: size.width * (0.18 + 0.52 * direction),
                             y: seat.maxY,
                             width: size.width * 0.10,
                             height: size.height * 0.18)
            fill(UIBezierPath(rect: leg), accent)
        }
    }

    private static func drawBin(_ context: CGContext,
                                _ size: CGSize,
                                _ primary: UIColor,
                                _ secondary: UIColor,
                                _ accent: UIColor) {
        let body = CGRect(x: size.width * 0.28, y: size.height * 0.32,
                          width: size.width * 0.44, height: size.height * 0.52)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.18), primary)
        }
        let lid = CGRect(x: size.width * 0.22, y: size.height * 0.22,
                         width: size.width * 0.56, height: size.height * 0.14)
        fill(UIBezierPath(roundedRect: lid, cornerRadius: lid.height * 0.45), secondary)

        let ridge = CGRect(x: body.minX + body.width * 0.20, y: body.minY + body.height * 0.24,
                           width: body.width * 0.60, height: max(1, size.height * 0.04))
        fill(UIBezierPath(rect: ridge), accent)
    }

    // MARK: - Scenery

    private static func drawTree(_ context: CGContext,
                                 _ size: CGSize,
                                 _ primary: UIColor,
                                 _ secondary: UIColor,
                                 _ accent: UIColor) {
        let trunk = CGRect(x: size.width * 0.44, y: size.height * 0.58,
                           width: size.width * 0.12, height: size.height * 0.34)
        fill(UIBezierPath(roundedRect: trunk, cornerRadius: trunk.width * 0.4), accent)

        withShadow(context) {
            let canopy = CGRect(x: size.width * 0.12, y: size.height * 0.14,
                                width: size.width * 0.76, height: size.height * 0.56)
            fill(UIBezierPath(ovalIn: canopy), primary)
        }
        // A lighter blob catches the light and stops the canopy reading flat.
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.20, y: size.height * 0.18,
                                         width: size.width * 0.34, height: size.height * 0.34)),
             secondary)
    }

    private static func drawConifer(_ context: CGContext,
                                    _ size: CGSize,
                                    _ primary: UIColor,
                                    _ secondary: UIColor,
                                    _ accent: UIColor) {
        let trunk = CGRect(x: size.width * 0.45, y: size.height * 0.72,
                           width: size.width * 0.10, height: size.height * 0.22)
        fill(UIBezierPath(roundedRect: trunk, cornerRadius: trunk.width * 0.4), accent)

        withShadow(context) {
            // Two stacked triangles read as a fir at any zoom level.
            let tiers: [(CGFloat, CGFloat, CGFloat)] = [(0.10, 0.55, 0.62), (0.32, 0.78, 0.78)]
            for tier in tiers {
                let cone = UIBezierPath()
                cone.move(to: CGPoint(x: size.width * 0.5, y: size.height * tier.0))
                cone.addLine(to: CGPoint(x: size.width * (0.5 + tier.2 / 2), y: size.height * tier.1))
                cone.addLine(to: CGPoint(x: size.width * (0.5 - tier.2 / 2), y: size.height * tier.1))
                cone.close()
                fill(cone, primary)
            }
        }
    }

    private static func drawFlowerBed(_ context: CGContext,
                                      _ size: CGSize,
                                      _ primary: UIColor,
                                      _ secondary: UIColor,
                                      _ accent: UIColor) {
        let bed = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.10, dy: size.height * 0.22)
        fill(UIBezierPath(roundedRect: bed, cornerRadius: bed.height * 0.3), accent)

        // Fixed offsets, so a bed always looks the same between frames.
        let spots: [(CGFloat, CGFloat)] = [
            (0.26, 0.36), (0.50, 0.28), (0.74, 0.38),
            (0.34, 0.62), (0.62, 0.66), (0.50, 0.50)
        ]
        for (index, spot) in spots.enumerated() {
            let diameter = size.width * 0.17
            let rect = CGRect(x: spot.0 * size.width - diameter / 2,
                              y: spot.1 * size.height - diameter / 2,
                              width: diameter, height: diameter)
            fill(UIBezierPath(ovalIn: rect), index % 2 == 0 ? primary : secondary)
        }
    }

    private static func drawFountainBasin(_ context: CGContext,
                                          _ size: CGSize,
                                          _ primary: UIColor,
                                          _ secondary: UIColor,
                                          _ accent: UIColor) {
        let basin = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.08, dy: size.height * 0.08)
        withShadow(context) {
            fill(UIBezierPath(ovalIn: basin), accent)
        }
        let water = basin.insetBy(dx: basin.width * 0.14, dy: basin.height * 0.14)
        fill(UIBezierPath(ovalIn: water), primary)

        let inner = water.insetBy(dx: water.width * 0.26, dy: water.height * 0.26)
        fill(UIBezierPath(ovalIn: inner), secondary)
    }

    /// The water, drawn separately so it can pulse.
    private static func drawFountainJet(_ context: CGContext,
                                        _ size: CGSize,
                                        _ primary: UIColor,
                                        _ secondary: UIColor,
                                        _ accent: UIColor) {
        let column = CGRect(x: size.width * 0.38, y: size.height * 0.18,
                            width: size.width * 0.24, height: size.height * 0.72)
        fill(UIBezierPath(roundedRect: column, cornerRadius: column.width / 2),
             ParkPalette.colour(.white).withAlphaComponent(0.85))

        let crown = CGRect(x: size.width * 0.20, y: 0,
                           width: size.width * 0.60, height: size.height * 0.30)
        fill(UIBezierPath(ovalIn: crown),
             ParkPalette.colour(.white).withAlphaComponent(0.70))
    }

    private static func drawLamp(_ context: CGContext,
                                 _ size: CGSize,
                                 _ primary: UIColor,
                                 _ secondary: UIColor,
                                 _ accent: UIColor) {
        let base = CGRect(x: size.width * 0.34, y: size.height * 0.80,
                          width: size.width * 0.32, height: size.height * 0.12)
        fill(UIBezierPath(roundedRect: base, cornerRadius: base.height * 0.4), accent)

        let post = CGRect(x: size.width * 0.45, y: size.height * 0.30,
                          width: size.width * 0.10, height: size.height * 0.54)
        fill(UIBezierPath(rect: post), accent)

        withShadow(context) {
            let head = CGRect(x: size.width * 0.30, y: size.height * 0.12,
                              width: size.width * 0.40, height: size.height * 0.26)
            fill(UIBezierPath(ovalIn: head), primary)
        }
        let glow = CGRect(x: size.width * 0.38, y: size.height * 0.18,
                          width: size.width * 0.24, height: size.height * 0.14)
        fill(UIBezierPath(ovalIn: glow), secondary)
    }

    private static func drawTopiary(_ context: CGContext,
                                    _ size: CGSize,
                                    _ primary: UIColor,
                                    _ secondary: UIColor,
                                    _ accent: UIColor) {
        let planter = CGRect(x: size.width * 0.26, y: size.height * 0.66,
                             width: size.width * 0.48, height: size.height * 0.26)
        fill(UIBezierPath(roundedRect: planter, cornerRadius: planter.height * 0.22), accent)

        withShadow(context) {
            let bush = CGRect(x: size.width * 0.16, y: size.height * 0.14,
                              width: size.width * 0.68, height: size.height * 0.58)
            fill(UIBezierPath(roundedRect: bush, cornerRadius: bush.width * 0.34), primary)
        }
        let sheen = CGRect(x: size.width * 0.26, y: size.height * 0.22,
                           width: size.width * 0.26, height: size.height * 0.22)
        fill(UIBezierPath(ovalIn: sheen), secondary)
    }

    private static func drawStatue(_ context: CGContext,
                                   _ size: CGSize,
                                   _ primary: UIColor,
                                   _ secondary: UIColor,
                                   _ accent: UIColor) {
        let plinth = CGRect(x: size.width * 0.22, y: size.height * 0.64,
                            width: size.width * 0.56, height: size.height * 0.28)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: plinth, cornerRadius: plinth.height * 0.16), accent)
        }

        let torso = CGRect(x: size.width * 0.38, y: size.height * 0.28,
                           width: size.width * 0.24, height: size.height * 0.40)
        fill(UIBezierPath(roundedRect: torso, cornerRadius: torso.width * 0.4), primary)

        let head = CGRect(x: size.width * 0.41, y: size.height * 0.14,
                          width: size.width * 0.18, height: size.height * 0.18)
        fill(UIBezierPath(ovalIn: head), primary)

        let sash = CGRect(x: torso.minX, y: torso.minY + torso.height * 0.30,
                          width: torso.width, height: max(1, size.height * 0.04))
        fill(UIBezierPath(rect: sash), secondary)
    }
}
