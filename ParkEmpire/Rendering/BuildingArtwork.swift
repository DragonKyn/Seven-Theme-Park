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
        case .megaCoaster: drawMegaCoasterBase(context, size, primary, secondary, accent)
        case .ferrisWheel: drawFerrisWheelBase(context, size, primary, secondary, accent)
        case .teacups:   drawTeacupsBase(context, size, primary, secondary, accent)
        case .bumperCars: drawBumperCarsBase(context, size, primary, secondary, accent)
        case .hauntedHouse: drawHauntedHouse(context, size, primary, secondary, accent)
        case .goKarts:   drawGoKartsBase(context, size, primary, secondary, accent)
        case .logFlume:  drawLogFlumeBase(context, size, primary, secondary, accent)
        case .slingshot: drawSlingshotBase(context, size, primary, secondary, accent)
        case .carpetSlide: drawCarpetSlideBase(context, size, primary, secondary, accent)
        case .trainStation: drawTrainStation(context, size, primary, secondary, accent)
        case .stall:     drawStall(context, size, primary, secondary, accent)
        case .kiosk:     drawKiosk(context, size, primary, secondary, accent)
        case .burgerStall: drawBurgerStall(context, size, primary, secondary, accent)
        case .pizzaStall: drawPizzaStall(context, size, primary, secondary, accent)
        case .drinkKiosk: drawDrinkKiosk(context, size, primary, secondary, accent)
        case .iceCreamStall: drawIceCreamStall(context, size, primary, secondary, accent)
        case .souvenirShop: drawSouvenirShop(context, size, primary, secondary, accent)
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
    /// How many moving parts a motif has. A track with one vehicle on it is a
    /// test track; a bumper car arena with one car in it has nothing to bump.
    static func motionPartCount(for motif: BuildingMotif) -> Int {
        switch motif {
        case .goKarts: return 4
        case .bumperCars: return 5
        // A coaster train is a string of cars. One car going round on its own
        // is a maintenance vehicle.
        case .megaCoaster: return 4
        case .coaster: return 3
        // Two logs on the circuit, so there is always one on the drop or
        // climbing towards it.
        case .logFlume: return 2
        // Four lanes, four mats. One mat on a four-lane slide looks like the
        // other three are shut.
        case .carpetSlide: return 4
        default: return 1
        }
    }

    ///  picks between vehicles where a motif has several, so no two
    /// karts in a race are the same colour.
    static func motionTexture(for appearance: BuildingAppearance,
                              size: CGSize,
                              variant: Int = 0) -> SKTexture? {
        guard appearance.motif.motion != .none else { return nil }

        let partSize = motionPartSize(for: appearance.motif, buildingSize: size)
        let key = "motion-\(appearance.motif.rawValue)-\(appearance.primary.rawValue)"
            + "-\(appearance.secondary.rawValue)-\(appearance.accent.rawValue)"
            + "-\(variant)-\(Int(partSize.width))x\(Int(partSize.height))"

        return SpriteFactory.texture(key: key, size: partSize) { context, size in
            let primary = ParkPalette.colour(appearance.primary)
            let secondary = ParkPalette.colour(appearance.secondary)
            let accent = ParkPalette.colour(appearance.accent)

            switch appearance.motif {
            case .carousel:  drawCanopy(context, size, primary, secondary, accent)
            case .swingBoat: drawBoat(context, size, primary, secondary, accent)
            case .dropTower: drawTowerCar(context, size, primary, secondary, accent)
            case .coaster, .megaCoaster: drawCoasterCar(context, size, primary, variant)
            case .ferrisWheel: drawWheel(context, size, primary, secondary, accent)
            case .teacups:   drawCups(context, size, primary, secondary, accent)
            case .goKarts: drawKart(context, size, variant)
            case .bumperCars: drawBumperCar(context, size, variant)
            case .logFlume:  drawLog(context, size, primary, secondary, accent)
            case .slingshot: drawCapsule(context, size, primary, secondary, accent)
            case .carpetSlide: drawMat(context, size, primary, secondary, accent)
            case .hauntedHouse: drawGhost(context, size, primary, secondary, accent)
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
            return CGSize(width: shortest * 0.19, height: shortest * 0.12)
        case .megaCoaster:
            // Measured against the building rather than its shorter side: a
            // nine-by-six coaster is wide, and a car scaled off the short side
            // ends up the size of the station.
            return CGSize(width: buildingSize.width * 0.075,
                          height: buildingSize.height * 0.055)
        case .ferrisWheel:
            return CGSize(width: shortest * 0.82, height: shortest * 0.82)
        case .teacups:
            return CGSize(width: shortest * 0.62, height: shortest * 0.62)
        case .goKarts:
            return CGSize(width: shortest * 0.21, height: shortest * 0.13)
        case .bumperCars:
            return CGSize(width: shortest * 0.22, height: shortest * 0.18)
        case .logFlume:
            return CGSize(width: buildingSize.width * 0.115,
                          height: buildingSize.height * 0.085)
        case .slingshot:
            return CGSize(width: shortest * 0.26, height: shortest * 0.26)
        case .carpetSlide:
            return CGSize(width: buildingSize.width * 0.16, height: buildingSize.height * 0.12)
        case .hauntedHouse:
            return CGSize(width: shortest * 0.20, height: shortest * 0.26)
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

    /// One car of a coaster train, nose to the right. The lead car gets a
    /// pointed nose; the rest are plain, which is what makes a string of them
    /// read as a train rather than as four identical blocks.
    private static func drawCoasterCar(_ context: CGContext,
                                       _ size: CGSize,
                                       _ primary: UIColor,
                                       _ variant: Int) {
        let isLead = variant == 0
        let body = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: size.height * 0.12)

        if isLead {
            // Wedge nose, which is the whole silhouette at this size.
            let nose = UIBezierPath()
            nose.move(to: CGPoint(x: body.minX, y: body.minY))
            nose.addLine(to: CGPoint(x: body.maxX - body.width * 0.20, y: body.minY))
            nose.addQuadCurve(to: CGPoint(x: body.maxX - body.width * 0.20, y: body.maxY),
                              controlPoint: CGPoint(x: body.maxX + body.width * 0.16,
                                                    y: body.midY))
            nose.addLine(to: CGPoint(x: body.minX, y: body.maxY))
            nose.close()
            fill(nose, primary)
        } else {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.34), primary)
        }

        // Riders: two pale dots per car, which is what says these are people
        // and not freight.
        let head = size.height * 0.34
        for offset in [CGFloat(0.26), CGFloat(0.56)] {
            fill(UIBezierPath(ovalIn: CGRect(x: body.minX + body.width * offset,
                                             y: body.midY - head / 2,
                                             width: head, height: head)),
                 ParkPalette.colour(.cream))
        }

        // Dark strip along the bottom, so the car sits on the rail rather than
        // floating over it.
        fill(UIBezierPath(rect: CGRect(x: body.minX, y: body.maxY - size.height * 0.10,
                                       width: body.width * 0.86, height: size.height * 0.10)),
             ParkPalette.colour(.charcoal))
    }

    /// The path a vehicle on a circuit follows, in node space: origin at the
    /// middle of the building and y upward, ready to drive a sprite along.
    ///
    /// Most circuits are the oval below. A full-size coaster has a shape of
    /// its own, which is the point of it.
    static func motionPath(for motif: BuildingMotif, buildingSize: CGSize) -> [CGPoint] {
        let texturePoints: [CGPoint]
        switch motif {
        case .megaCoaster:
            texturePoints = megaCoasterPoints(in: buildingSize)
        case .logFlume:
            texturePoints = logFlumePoints(in: buildingSize)
        default:
            let track = trackRect(in: buildingSize)
            texturePoints = (0..<36).map { step in
                let angle = CGFloat(step) / 36 * .pi * 2
                return CGPoint(x: track.midX + cos(angle) * track.width / 2,
                               y: track.midY + sin(angle) * track.height / 2)
            }
        }

        // Texture space runs y downward from the top-left; the scene runs y
        // upward from the middle.
        return texturePoints.map {
            CGPoint(x: $0.x - buildingSize.width / 2,
                    y: buildingSize.height / 2 - $0.y)
        }
    }

    /// The oval the coaster train runs, in texture coordinates. Shared so the
    /// drawn track and the animation path cannot drift apart.
    static func trackRect(in size: CGSize) -> CGRect {
        CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.16, dy: size.height * 0.20)
    }

    // MARK: - Wheel and spinners

    private static func drawFerrisWheelBase(_ context: CGContext,
                                            _ size: CGSize,
                                            _ primary: UIColor,
                                            _ secondary: UIColor,
                                            _ accent: UIColor) {
        let pad = CGRect(x: size.width * 0.10, y: size.height * 0.72,
                         width: size.width * 0.80, height: size.height * 0.22)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: pad, cornerRadius: pad.height * 0.35), secondary)
        }

        // Two legs leaning in to the hub the wheel turns on.
        let hub = CGPoint(x: size.width / 2, y: size.height / 2)
        let legWidth = max(2, size.width * 0.045)
        for direction in [CGFloat(-1), CGFloat(1)] {
            let leg = UIBezierPath()
            leg.move(to: hub)
            leg.addLine(to: CGPoint(x: hub.x + direction * size.width * 0.26,
                                    y: size.height * 0.80))
            stroke(leg, accent, width: legWidth)
        }

        let cap = CGRect(x: hub.x - legWidth, y: hub.y - legWidth,
                         width: legWidth * 2, height: legWidth * 2)
        fill(UIBezierPath(ovalIn: cap), primary)
    }

    /// The rim, its spokes and the cabins hanging off it.
    private static func drawWheel(_ context: CGContext,
                                  _ size: CGSize,
                                  _ primary: UIColor,
                                  _ secondary: UIColor,
                                  _ accent: UIColor) {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - max(2, size.width * 0.08)

        let spokes = 8
        for index in 0..<spokes {
            let angle = CGFloat(index) / CGFloat(spokes) * .pi * 2
            let spoke = UIBezierPath()
            spoke.move(to: centre)
            spoke.addLine(to: CGPoint(x: centre.x + cos(angle) * radius,
                                      y: centre.y + sin(angle) * radius))
            stroke(spoke, accent, width: max(1, size.width * 0.025))
        }

        let rim = CGRect(x: centre.x - radius, y: centre.y - radius,
                         width: radius * 2, height: radius * 2)
        stroke(UIBezierPath(ovalIn: rim), primary, width: max(1.5, size.width * 0.05))

        let cabin = size.width * 0.13
        for index in 0..<spokes {
            let angle = CGFloat(index) / CGFloat(spokes) * .pi * 2
            let point = CGPoint(x: centre.x + cos(angle) * radius - cabin / 2,
                                y: centre.y + sin(angle) * radius - cabin / 2)
            fill(UIBezierPath(roundedRect: CGRect(origin: point,
                                                  size: CGSize(width: cabin, height: cabin)),
                              cornerRadius: cabin * 0.3),
                 index % 2 == 0 ? secondary : ParkPalette.colour(.cream))
        }
    }

    private static func drawTeacupsBase(_ context: CGContext,
                                        _ size: CGSize,
                                        _ primary: UIColor,
                                        _ secondary: UIColor,
                                        _ accent: UIColor) {
        let floor = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.10, dy: size.height * 0.10)
        withShadow(context) {
            fill(UIBezierPath(ovalIn: floor), secondary)
        }
        stroke(UIBezierPath(ovalIn: floor.insetBy(dx: floor.width * 0.14, dy: floor.height * 0.14)),
               accent, width: max(1, size.width * 0.02))
    }

    /// Three cups clustered on a turntable.
    private static func drawCups(_ context: CGContext,
                                 _ size: CGSize,
                                 _ primary: UIColor,
                                 _ secondary: UIColor,
                                 _ accent: UIColor) {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let orbit = size.width * 0.28
        let cup = size.width * 0.36
        let colours = [primary, accent, ParkPalette.colour(.cream)]

        for index in 0..<3 {
            let angle = CGFloat(index) / 3 * .pi * 2
            let rect = CGRect(x: centre.x + cos(angle) * orbit - cup / 2,
                              y: centre.y + sin(angle) * orbit - cup / 2,
                              width: cup, height: cup)
            fill(UIBezierPath(ovalIn: rect), colours[index])
            stroke(UIBezierPath(ovalIn: rect.insetBy(dx: cup * 0.24, dy: cup * 0.24)),
                   ParkPalette.colour(.charcoal), width: max(1, size.width * 0.02))
        }
    }

    // MARK: - Circuits

    private static func drawBumperCarsBase(_ context: CGContext,
                                           _ size: CGSize,
                                           _ primary: UIColor,
                                           _ secondary: UIColor,
                                           _ accent: UIColor) {
        let arena = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.06, dy: size.height * 0.07)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: arena, cornerRadius: arena.height * 0.18), primary)
        }

        let floor = arena.insetBy(dx: arena.width * 0.07, dy: arena.height * 0.09)
        fill(UIBezierPath(roundedRect: floor, cornerRadius: floor.height * 0.15),
             ParkPalette.colour(.charcoal))

        // Bulbs around the rail, the one detail that says fairground.
        let bulbs = 10
        for index in 0..<bulbs {
            let step = CGFloat(index) / CGFloat(bulbs)
            let x = arena.minX + arena.width * step + arena.width / CGFloat(bulbs) / 2
            let dot = size.width * 0.035
            for y in [arena.minY + dot, arena.maxY - dot * 2] {
                fill(UIBezierPath(ovalIn: CGRect(x: x - dot / 2, y: y,
                                                 width: dot, height: dot)), accent)
            }
        }
    }

    private static func drawGoKartsBase(_ context: CGContext,
                                        _ size: CGSize,
                                        _ primary: UIColor,
                                        _ secondary: UIColor,
                                        _ accent: UIColor) {
        let ground = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.04, dy: size.height * 0.05)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: ground, cornerRadius: ground.height * 0.12), secondary)
        }

        // Asphalt, then a white edge line on top of it.
        let track = trackRect(in: size)
        stroke(UIBezierPath(ovalIn: track), ParkPalette.colour(.charcoal),
               width: max(3, size.height * 0.13))
        stroke(UIBezierPath(ovalIn: track), ParkPalette.colour(.white),
               width: max(1, size.height * 0.012))

        // Start line across the bottom straight.
        let line = CGRect(x: track.midX - size.width * 0.01,
                          y: track.maxY - size.height * 0.065,
                          width: size.width * 0.02, height: size.height * 0.13)
        fill(UIBezierPath(rect: line), ParkPalette.colour(.white))

        let pit = CGRect(x: track.midX + size.width * 0.06,
                         y: track.maxY - size.height * 0.02,
                         width: size.width * 0.22, height: size.height * 0.15)
        fill(UIBezierPath(roundedRect: pit, cornerRadius: pit.height * 0.3), primary)
        fill(UIBezierPath(rect: CGRect(x: pit.minX, y: pit.minY,
                                       width: pit.width, height: pit.height * 0.3)), accent)
    }

    /// Livery for the vehicles a motif has several of. Fixed rather than taken
    /// from the building's own colours, because four karts in four shades of
    /// the same colour is not a race.
    private static let liveries: [ParkColour] = [.red, .blue, .yellow, .green, .violet]

    private static func livery(_ variant: Int) -> UIColor {
        ParkPalette.colour(liveries[variant % liveries.count])
    }

    /// A kart seen from above, nose to the right, because the sprite is turned
    /// to face the way it is travelling.
    private static func drawKart(_ context: CGContext, _ size: CGSize, _ variant: Int) {
        let colour = livery(variant)
        let tyre = ParkPalette.colour(.charcoal)

        // Tyres first, so the body sits over their inner edge.
        let tyreWidth = size.width * 0.22
        let tyreHeight = size.height * 0.26
        for x in [size.width * 0.14, size.width * 0.66] {
            for y in [-size.height * 0.02, size.height * 0.76] {
                fill(UIBezierPath(roundedRect: CGRect(x: x, y: y,
                                                      width: tyreWidth, height: tyreHeight),
                                  cornerRadius: tyreHeight * 0.4), tyre)
            }
        }

        // Chassis: wide at the back, tapering to a point at the nose.
        let body = UIBezierPath()
        body.move(to: CGPoint(x: size.width * 0.06, y: size.height * 0.26))
        body.addLine(to: CGPoint(x: size.width * 0.60, y: size.height * 0.18))
        body.addQuadCurve(to: CGPoint(x: size.width * 0.60, y: size.height * 0.82),
                          controlPoint: CGPoint(x: size.width * 1.02, y: size.height * 0.50))
        body.addLine(to: CGPoint(x: size.width * 0.06, y: size.height * 0.74))
        body.close()
        fill(body, colour)

        // Driver, and the roll bar behind them.
        let helmet = size.height * 0.34
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.34,
                                         y: size.height * 0.5 - helmet / 2,
                                         width: helmet, height: helmet)),
             ParkPalette.colour(.cream))

        let bar = CGRect(x: size.width * 0.16, y: size.height * 0.28,
                         width: size.width * 0.09, height: size.height * 0.44)
        fill(UIBezierPath(roundedRect: bar, cornerRadius: bar.width * 0.4), tyre)
    }

    /// A bumper car seen from above: a round shell inside a fat rubber ring,
    /// which is the only part of it that ever actually touches anything.
    private static func drawBumperCar(_ context: CGContext, _ size: CGSize, _ variant: Int) {
        let colour = livery(variant)

        let bumper = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
        fill(UIBezierPath(ovalIn: bumper), ParkPalette.colour(.charcoal))

        let shell = bumper.insetBy(dx: bumper.width * 0.16, dy: bumper.height * 0.18)
        fill(UIBezierPath(ovalIn: shell), colour)

        // Driver, set slightly back from the front.
        let head = min(shell.width, shell.height) * 0.44
        fill(UIBezierPath(ovalIn: CGRect(x: shell.midX - head * 0.75,
                                         y: shell.midY - head / 2,
                                         width: head, height: head)),
             ParkPalette.colour(.cream))

        // Pole to the ceiling grid, drawn as a bright cap at the back.
        let pole = min(shell.width, shell.height) * 0.20
        fill(UIBezierPath(ovalIn: CGRect(x: shell.minX + shell.width * 0.06,
                                         y: shell.midY - pole / 2,
                                         width: pole, height: pole)),
             ParkPalette.colour(.amber))
    }

    // MARK: - Shop emblems

    /// Draws the shared booth, then whatever the shop actually sells on a
    /// board above it.
    ///
    /// The emblems are deliberately blunt: a burger is three stacked bands, a
    /// cone is a triangle under a scoop. At this size a drawing of a burger
    /// and a drawing of a sandwich look identical, so what matters is that
    /// each shop's silhouette is different from its neighbour's.
    private static func drawBurgerStall(_ context: CGContext,
                                        _ size: CGSize,
                                        _ primary: UIColor,
                                        _ secondary: UIColor,
                                        _ accent: UIColor) {
        drawStall(context, size, primary, secondary, accent)
        let board = signBoard(context, size, accent)

        let width = board.width * 0.62
        let bun = CGRect(x: board.midX - width / 2, y: board.midY - board.height * 0.26,
                         width: width, height: board.height * 0.52)
        // Top bun.
        let top = UIBezierPath(arcCenter: CGPoint(x: bun.midX, y: bun.midY - bun.height * 0.06),
                               radius: width / 2,
                               startAngle: .pi, endAngle: 0, clockwise: true)
        top.close()
        fill(top, ParkPalette.colour(.amber))
        // Filling and base.
        fill(UIBezierPath(rect: CGRect(x: bun.minX, y: bun.midY - bun.height * 0.05,
                                       width: width, height: bun.height * 0.20)),
             ParkPalette.colour(.brown))
        fill(UIBezierPath(roundedRect: CGRect(x: bun.minX, y: bun.midY + bun.height * 0.17,
                                              width: width, height: bun.height * 0.22),
                          cornerRadius: bun.height * 0.10),
             ParkPalette.colour(.amber))
    }

    private static func drawPizzaStall(_ context: CGContext,
                                       _ size: CGSize,
                                       _ primary: UIColor,
                                       _ secondary: UIColor,
                                       _ accent: UIColor) {
        drawStall(context, size, primary, secondary, accent)
        let board = signBoard(context, size, accent)

        // A single slice, point down.
        let slice = UIBezierPath()
        let width = board.width * 0.52
        slice.move(to: CGPoint(x: board.midX - width / 2, y: board.midY - board.height * 0.24))
        slice.addLine(to: CGPoint(x: board.midX + width / 2, y: board.midY - board.height * 0.24))
        slice.addLine(to: CGPoint(x: board.midX, y: board.midY + board.height * 0.30))
        slice.close()
        fill(slice, ParkPalette.colour(.amber))

        // Crust along the top, pepperoni on the face.
        fill(UIBezierPath(roundedRect: CGRect(x: board.midX - width / 2,
                                              y: board.midY - board.height * 0.30,
                                              width: width, height: board.height * 0.12),
                          cornerRadius: board.height * 0.06),
             ParkPalette.colour(.brown))
        let dot = board.height * 0.11
        for offset in [CGPoint(x: -0.12, y: -0.08), CGPoint(x: 0.11, y: -0.06), CGPoint(x: -0.01, y: 0.10)] {
            fill(UIBezierPath(ovalIn: CGRect(x: board.midX + board.width * offset.x - dot / 2,
                                             y: board.midY + board.height * offset.y - dot / 2,
                                             width: dot, height: dot)),
                 ParkPalette.colour(.red))
        }
    }

    private static func drawDrinkKiosk(_ context: CGContext,
                                       _ size: CGSize,
                                       _ primary: UIColor,
                                       _ secondary: UIColor,
                                       _ accent: UIColor) {
        drawKiosk(context, size, primary, secondary, accent)
        let board = signBoard(context, size, accent)

        // A tapered cup with a lid and a straw.
        let cup = UIBezierPath()
        let top = board.midY - board.height * 0.18
        let bottom = board.midY + board.height * 0.30
        let halfTop = board.width * 0.17
        let halfBottom = board.width * 0.12
        cup.move(to: CGPoint(x: board.midX - halfTop, y: top))
        cup.addLine(to: CGPoint(x: board.midX + halfTop, y: top))
        cup.addLine(to: CGPoint(x: board.midX + halfBottom, y: bottom))
        cup.addLine(to: CGPoint(x: board.midX - halfBottom, y: bottom))
        cup.close()
        fill(cup, ParkPalette.colour(.cream))

        fill(UIBezierPath(roundedRect: CGRect(x: board.midX - halfTop * 1.15,
                                              y: top - board.height * 0.10,
                                              width: halfTop * 2.3, height: board.height * 0.12),
                          cornerRadius: board.height * 0.05),
             ParkPalette.colour(.red))

        let straw = UIBezierPath()
        straw.move(to: CGPoint(x: board.midX + halfTop * 0.35, y: top - board.height * 0.08))
        straw.addLine(to: CGPoint(x: board.midX + halfTop * 0.85, y: top - board.height * 0.38))
        stroke(straw, ParkPalette.colour(.red), width: max(1, board.width * 0.05))
    }

    private static func drawIceCreamStall(_ context: CGContext,
                                          _ size: CGSize,
                                          _ primary: UIColor,
                                          _ secondary: UIColor,
                                          _ accent: UIColor) {
        drawKiosk(context, size, primary, secondary, accent)
        let board = signBoard(context, size, accent)

        // Cone, point down, with a scoop on top.
        let cone = UIBezierPath()
        let width = board.width * 0.34
        let top = board.midY - board.height * 0.02
        cone.move(to: CGPoint(x: board.midX - width / 2, y: top))
        cone.addLine(to: CGPoint(x: board.midX + width / 2, y: top))
        cone.addLine(to: CGPoint(x: board.midX, y: board.midY + board.height * 0.34))
        cone.close()
        fill(cone, ParkPalette.colour(.sand))

        let scoop = board.height * 0.34
        fill(UIBezierPath(ovalIn: CGRect(x: board.midX - scoop / 2,
                                         y: top - scoop * 0.78,
                                         width: scoop, height: scoop)),
             ParkPalette.colour(.pink))
        fill(UIBezierPath(ovalIn: CGRect(x: board.midX - scoop * 0.30,
                                         y: top - scoop * 1.10,
                                         width: scoop * 0.62, height: scoop * 0.62)),
             ParkPalette.colour(.cream))
    }

    private static func drawSouvenirShop(_ context: CGContext,
                                         _ size: CGSize,
                                         _ primary: UIColor,
                                         _ secondary: UIColor,
                                         _ accent: UIColor) {
        drawShopFront(context, size, primary, secondary, accent)
        let board = signBoard(context, size, accent)

        // A wrapped box with a ribbon over it.
        let box = CGRect(x: board.midX - board.width * 0.20, y: board.midY - board.height * 0.16,
                         width: board.width * 0.40, height: board.height * 0.44)
        fill(UIBezierPath(roundedRect: box, cornerRadius: board.height * 0.05),
             ParkPalette.colour(.red))
        fill(UIBezierPath(rect: CGRect(x: box.midX - box.width * 0.09, y: box.minY,
                                       width: box.width * 0.18, height: box.height)),
             ParkPalette.colour(.cream))
        fill(UIBezierPath(rect: CGRect(x: box.minX, y: box.midY - box.height * 0.09,
                                       width: box.width, height: box.height * 0.18)),
             ParkPalette.colour(.cream))
        // Bow.
        let bow = box.height * 0.30
        for direction in [CGFloat(-1), CGFloat(1)] {
            fill(UIBezierPath(ovalIn: CGRect(x: box.midX + direction * bow * 0.5 - bow / 2,
                                             y: box.minY - bow * 0.55,
                                             width: bow, height: bow * 0.8)),
                 ParkPalette.colour(.cream))
        }
    }

    /// A blank board over the top of a booth, and the space left to draw on.
    /// Every shop gets the same board so the row of them reads as a parade.
    @discardableResult
    private static func signBoard(_ context: CGContext,
                                  _ size: CGSize,
                                  _ accent: UIColor) -> CGRect {
        let board = CGRect(x: size.width * 0.24, y: size.height * 0.05,
                           width: size.width * 0.52, height: size.height * 0.34)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: board, cornerRadius: board.height * 0.22),
                 ParkPalette.colour(.cream))
        }
        stroke(UIBezierPath(roundedRect: board, cornerRadius: board.height * 0.22),
               accent, width: max(1, size.width * 0.018))
        return board
    }

    // MARK: - Log flume

    /// The channel a log runs, in texture space.
    ///
    /// Like the big coaster, one list of points is both the trough that gets
    /// drawn and the path the log follows. A flume is a lift, a long run at
    /// height, one big drop into water, and a slow return, and it should read
    /// as all four rather than as a blue oval.
    static func logFlumePoints(in size: CGSize) -> [CGPoint] {
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * size.width, y: y * size.height)
        }

        var points: [CGPoint] = []

        func line(_ from: CGPoint, _ to: CGPoint, steps: Int) {
            for step in 0..<steps {
                let t = CGFloat(step) / CGFloat(steps)
                points.append(CGPoint(x: from.x + (to.x - from.x) * t,
                                      y: from.y + (to.y - from.y) * t))
            }
        }

        func curve(_ from: CGPoint, _ control: CGPoint, to: CGPoint, steps: Int) {
            for step in 0..<steps {
                let t = CGFloat(step) / CGFloat(steps)
                let inverse = 1 - t
                points.append(CGPoint(
                    x: inverse * inverse * from.x + 2 * inverse * t * control.x + t * t * to.x,
                    y: inverse * inverse * from.y + 2 * inverse * t * control.y + t * t * to.y))
            }
        }

        // Out of the loading trough and up the lift.
        line(at(0.07, 0.88), at(0.24, 0.88), steps: 5)
        line(at(0.24, 0.88), at(0.33, 0.17), steps: 13)
        // A gentle run along the top, which is where the queue watches from.
        curve(at(0.33, 0.17), at(0.42, 0.11), to: at(0.56, 0.15), steps: 8)
        // The drop. Steep, and straight into the water.
        curve(at(0.56, 0.15), at(0.70, 0.28), to: at(0.73, 0.74), steps: 12)
        // Out of the splash and round the bottom back to the start.
        curve(at(0.73, 0.74), at(0.80, 0.84), to: at(0.90, 0.82), steps: 6)
        curve(at(0.90, 0.82), at(0.95, 0.86), to: at(0.93, 0.94), steps: 4)
        line(at(0.93, 0.94), at(0.11, 0.94), steps: 16)
        curve(at(0.11, 0.94), at(0.04, 0.94), to: at(0.07, 0.88), steps: 4)

        return points
    }

    /// Where the drop lands, so the pool and the channel agree.
    private static func flumeSplash(in size: CGSize) -> CGRect {
        CGRect(x: size.width * 0.60, y: size.height * 0.66,
               width: size.width * 0.30, height: size.height * 0.22)
    }

    private static func drawLogFlumeBase(_ context: CGContext,
                                         _ size: CGSize,
                                         _ primary: UIColor,
                                         _ secondary: UIColor,
                                         _ accent: UIColor) {
        let ground = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.03, dy: size.height * 0.04)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: ground, cornerRadius: ground.height * 0.10), secondary)
        }

        // Planting round the edges, which is what stops a brown trough on
        // brown ground reading as one shape. Fixed positions, so the same
        // flume always looks the same.
        let bushes: [(CGFloat, CGFloat, CGFloat)] = [
            (0.10, 0.62, 0.9), (0.17, 0.72, 0.7), (0.44, 0.86, 1.0),
            (0.52, 0.72, 0.7), (0.40, 0.36, 0.8), (0.86, 0.34, 1.0),
            (0.93, 0.48, 0.7), (0.24, 0.36, 0.7), (0.66, 0.88, 0.8)
        ]
        for (x, y, scale) in bushes {
            let radius = size.height * 0.055 * scale
            let centre = CGPoint(x: size.width * x, y: size.height * y)
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius, y: centre.y - radius * 0.85,
                                             width: radius * 2, height: radius * 1.7)),
                 ParkPalette.colour(.green))
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius * 0.55,
                                             y: centre.y - radius * 1.05,
                                             width: radius * 1.1, height: radius * 1.0)),
                 ParkPalette.colour(.lime))
        }

        // The splash pool goes down before the channel, so the trough passes
        // over the water rather than stopping at it.
        let pool = flumeSplash(in: size)
        fill(UIBezierPath(ovalIn: pool), ParkPalette.water)
        stroke(UIBezierPath(ovalIn: pool.insetBy(dx: pool.width * 0.10, dy: pool.height * 0.14)),
               ParkPalette.colour(.white).withAlphaComponent(0.55),
               width: max(1, size.height * 0.010))

        let points = logFlumePoints(in: size)
        guard points.count > 2 else { return }

        // Trestles under the raised sections, which is what makes the height
        // read as height.
        let deck = size.height * 0.95
        let trestles = UIBezierPath()
        for (index, point) in points.enumerated() where index % 4 == 0 && point.y < deck - 6 {
            trestles.move(to: point)
            trestles.addLine(to: CGPoint(x: point.x, y: deck))
        }
        stroke(trestles, ParkPalette.colour(.brown).withAlphaComponent(0.5),
               width: max(1, size.width * 0.009))

        let channel = UIBezierPath()
        channel.move(to: points[0])
        for point in points.dropFirst() { channel.addLine(to: point) }
        channel.close()

        // Timber trough, then the water sitting in it.
        stroke(channel, ParkPalette.flumeTimber, width: max(3, size.height * 0.055))
        stroke(channel, ParkPalette.water, width: max(1.5, size.height * 0.030))
        stroke(channel, ParkPalette.colour(.white).withAlphaComponent(0.35),
               width: max(1, size.height * 0.008))

        // Spray where the drop meets the pool.
        let spray = UIBezierPath()
        for step in 0..<5 {
            let spread = CGFloat(step) / 4 - 0.5
            let origin = CGPoint(x: pool.midX + spread * pool.width * 0.55,
                                 y: pool.minY + pool.height * 0.35)
            spray.move(to: origin)
            spray.addLine(to: CGPoint(x: origin.x + spread * size.width * 0.06,
                                      y: origin.y - size.height * 0.11))
        }
        stroke(spray, ParkPalette.colour(.white).withAlphaComponent(0.8),
               width: max(1, size.width * 0.012))

        // Loading station over the bottom-left straight.
        let station = CGRect(x: size.width * 0.05, y: size.height * 0.80,
                             width: size.width * 0.22, height: size.height * 0.13)
        fill(UIBezierPath(roundedRect: station, cornerRadius: station.height * 0.3), primary)
        fill(UIBezierPath(rect: CGRect(x: station.minX, y: station.minY,
                                       width: station.width, height: station.height * 0.32)),
             accent)
    }

    /// A hollowed log with riders in it, prow to the right.
    private static func drawLog(_ context: CGContext,
                                _ size: CGSize,
                                _ primary: UIColor,
                                _ secondary: UIColor,
                                _ accent: UIColor) {
        let hull = UIBezierPath()
        let top = size.height * 0.16
        let bottom = size.height * 0.84
        hull.move(to: CGPoint(x: size.width * 0.04, y: top))
        hull.addLine(to: CGPoint(x: size.width * 0.72, y: top))
        // Rounded prow at the leading end.
        hull.addQuadCurve(to: CGPoint(x: size.width * 0.72, y: bottom),
                          controlPoint: CGPoint(x: size.width * 1.06, y: size.height * 0.5))
        hull.addLine(to: CGPoint(x: size.width * 0.04, y: bottom))
        hull.addQuadCurve(to: CGPoint(x: size.width * 0.04, y: top),
                          controlPoint: CGPoint(x: size.width * -0.10, y: size.height * 0.5))
        hull.close()
        fill(hull, ParkPalette.colour(.brown))

        // Hollow, so it reads as something you sit in.
        let well = CGRect(x: size.width * 0.14, y: size.height * 0.30,
                          width: size.width * 0.62, height: size.height * 0.40)
        fill(UIBezierPath(roundedRect: well, cornerRadius: well.height * 0.45),
             ParkPalette.colour(.charcoal).withAlphaComponent(0.55))

        // Two riders.
        let head = size.height * 0.30
        for offset in [CGFloat(0.20), CGFloat(0.48)] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * offset,
                                             y: size.height * 0.5 - head / 2,
                                             width: head, height: head)),
                 ParkPalette.colour(.cream))
        }
    }

    // MARK: - Towers and slides

    private static func drawSlingshotBase(_ context: CGContext,
                                          _ size: CGSize,
                                          _ primary: UIColor,
                                          _ secondary: UIColor,
                                          _ accent: UIColor) {
        let pad = CGRect(x: size.width * 0.14, y: size.height * 0.78,
                         width: size.width * 0.72, height: size.height * 0.16)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: pad, cornerRadius: pad.height * 0.35), secondary)
        }

        // Twin masts, leaning very slightly apart.
        for direction in [CGFloat(-1), CGFloat(1)] {
            let mast = UIBezierPath()
            mast.move(to: CGPoint(x: size.width / 2 + direction * size.width * 0.22,
                                  y: size.height * 0.04))
            mast.addLine(to: CGPoint(x: size.width / 2 + direction * size.width * 0.30,
                                     y: size.height * 0.82))
            stroke(mast, accent, width: max(2, size.width * 0.055))
        }

        // The elastic, slack between the two mast heads.
        let cable = UIBezierPath()
        cable.move(to: CGPoint(x: size.width * 0.28, y: size.height * 0.06))
        cable.addQuadCurve(to: CGPoint(x: size.width * 0.72, y: size.height * 0.06),
                           controlPoint: CGPoint(x: size.width * 0.50, y: size.height * 0.30))
        stroke(cable, primary, width: max(1, size.width * 0.025))
    }

    private static func drawCapsule(_ context: CGContext,
                                    _ size: CGSize,
                                    _ primary: UIColor,
                                    _ secondary: UIColor,
                                    _ accent: UIColor) {
        let ball = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
        fill(UIBezierPath(ovalIn: ball), primary)
        stroke(UIBezierPath(ovalIn: ball.insetBy(dx: ball.width * 0.18, dy: ball.height * 0.18)),
               ParkPalette.colour(.charcoal), width: max(1, size.width * 0.09))
    }

    private static func drawCarpetSlideBase(_ context: CGContext,
                                            _ size: CGSize,
                                            _ primary: UIColor,
                                            _ secondary: UIColor,
                                            _ accent: UIColor) {
        let ground = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.06, dy: size.height * 0.06)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: ground, cornerRadius: ground.height * 0.12), secondary)
        }

        // Four lanes running top to bottom, with humps drawn as bands.
        let lanes = 4
        let laneWidth = ground.width * 0.17
        for index in 0..<lanes {
            let spacing = ground.width / CGFloat(lanes + 1)
            let x = ground.minX + spacing * CGFloat(index + 1) - laneWidth / 2
            let lane = CGRect(x: x, y: ground.minY + ground.height * 0.10,
                              width: laneWidth, height: ground.height * 0.66)
            fill(UIBezierPath(roundedRect: lane, cornerRadius: laneWidth * 0.3),
                 index % 2 == 0 ? primary : accent)
            for hump in 1...3 {
                let y = lane.minY + lane.height * CGFloat(hump) / 4
                fill(UIBezierPath(rect: CGRect(x: lane.minX, y: y,
                                               width: lane.width,
                                               height: max(1, size.height * 0.012))),
                     ParkPalette.colour(.cream))
            }
        }

        // Landing mat across the bottom.
        let landing = CGRect(x: ground.minX, y: ground.maxY - ground.height * 0.16,
                             width: ground.width, height: ground.height * 0.14)
        fill(UIBezierPath(roundedRect: landing, cornerRadius: landing.height * 0.3),
             ParkPalette.colour(.charcoal))
    }

    private static func drawMat(_ context: CGContext,
                                _ size: CGSize,
                                _ primary: UIColor,
                                _ secondary: UIColor,
                                _ accent: UIColor) {
        let mat = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
        fill(UIBezierPath(roundedRect: mat, cornerRadius: mat.height * 0.4),
             ParkPalette.colour(.cream))
    }

    /// A platform under a canopy, with a clock on the gable end. The train
    /// belongs to the track rather than to the building, so nothing here moves.
    private static func drawTrainStation(_ context: CGContext,
                                         _ size: CGSize,
                                         _ primary: UIColor,
                                         _ secondary: UIColor,
                                         _ accent: UIColor) {
        let platform = CGRect(x: size.width * 0.04, y: size.height * 0.52,
                              width: size.width * 0.92, height: size.height * 0.40)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: platform, cornerRadius: platform.height * 0.18), secondary)
        }

        // Edge stripe along the platform, the way a real one is painted.
        fill(UIBezierPath(rect: CGRect(x: platform.minX, y: platform.maxY - size.height * 0.06,
                                       width: platform.width, height: size.height * 0.045)),
             accent)

        let canopy = CGRect(x: size.width * 0.08, y: size.height * 0.14,
                            width: size.width * 0.84, height: size.height * 0.30)
        fill(UIBezierPath(roundedRect: canopy, cornerRadius: canopy.height * 0.30), primary)

        // Posts holding the canopy up over the platform.
        for x in [size.width * 0.16, size.width * 0.80] {
            fill(UIBezierPath(rect: CGRect(x: x, y: canopy.maxY,
                                           width: size.width * 0.035,
                                           height: size.height * 0.16)),
                 ParkPalette.colour(.brown))
        }

        let clock = min(size.width, size.height) * 0.18
        fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.50 - clock / 2,
                                         y: canopy.midY - clock / 2,
                                         width: clock, height: clock)),
             ParkPalette.colour(.cream))
        stroke(UIBezierPath(ovalIn: CGRect(x: size.width * 0.50 - clock / 2,
                                           y: canopy.midY - clock / 2,
                                           width: clock, height: clock)),
               ParkPalette.colour(.charcoal), width: max(1, size.width * 0.012))
    }

    // MARK: - Haunted house

    private static func drawHauntedHouse(_ context: CGContext,
                                         _ size: CGSize,
                                         _ primary: UIColor,
                                         _ secondary: UIColor,
                                         _ accent: UIColor) {
        let body = CGRect(x: size.width * 0.14, y: size.height * 0.38,
                          width: size.width * 0.72, height: size.height * 0.52)
        withShadow(context) {
            fill(UIBezierPath(rect: body), primary)
        }

        // Steep gabled roof overhanging the walls on both sides.
        let roof = UIBezierPath()
        roof.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.40))
        roof.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.08))
        roof.addLine(to: CGPoint(x: size.width * 0.92, y: size.height * 0.40))
        roof.close()
        fill(roof, secondary)

        // Lit windows, the only warm thing about it.
        let windowSize = CGSize(width: size.width * 0.13, height: size.height * 0.13)
        for x in [CGFloat(0.24), CGFloat(0.63)] {
            let rect = CGRect(origin: CGPoint(x: size.width * x, y: size.height * 0.48),
                              size: windowSize)
            fill(UIBezierPath(roundedRect: rect, cornerRadius: windowSize.width * 0.2), accent)
        }

        let door = CGRect(x: size.width * 0.43, y: size.height * 0.68,
                          width: size.width * 0.14, height: size.height * 0.22)
        fill(UIBezierPath(roundedRect: door, cornerRadius: door.width * 0.4),
             ParkPalette.colour(.charcoal))
    }

    private static func drawGhost(_ context: CGContext,
                                  _ size: CGSize,
                                  _ primary: UIColor,
                                  _ secondary: UIColor,
                                  _ accent: UIColor) {
        let body = UIBezierPath()
        let waist = size.height * 0.66
        body.move(to: CGPoint(x: size.width * 0.10, y: waist))
        body.addQuadCurve(to: CGPoint(x: size.width * 0.90, y: waist),
                          controlPoint: CGPoint(x: size.width * 0.50, y: -size.height * 0.24))
        // A scalloped hem, which is what makes a white blob read as a ghost.
        body.addLine(to: CGPoint(x: size.width * 0.90, y: size.height * 0.94))
        body.addQuadCurve(to: CGPoint(x: size.width * 0.50, y: size.height * 0.94),
                          controlPoint: CGPoint(x: size.width * 0.70, y: size.height * 0.72))
        body.addQuadCurve(to: CGPoint(x: size.width * 0.10, y: size.height * 0.94),
                          controlPoint: CGPoint(x: size.width * 0.30, y: size.height * 0.72))
        body.close()
        fill(body, ParkPalette.colour(.white))

        let eye = size.width * 0.16
        for x in [CGFloat(0.28), CGFloat(0.56)] {
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * x, y: size.height * 0.42,
                                             width: eye, height: eye)),
                 ParkPalette.colour(.charcoal))
        }
    }

    // MARK: - Mega coaster

    /// The circuit a big coaster's train runs, in texture space.
    ///
    /// One list of points serves as both the track that gets drawn and the
    /// path the train follows, so the two can never disagree about where the
    /// rails are. A lift hill, a drop, a vertical loop and a run back to the
    /// station, which is what makes it read as a coaster rather than an oval.
    static func megaCoasterPoints(in size: CGSize) -> [CGPoint] {
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * size.width, y: y * size.height)
        }

        var points: [CGPoint] = []

        func line(_ from: CGPoint, _ to: CGPoint, steps: Int) {
            for step in 0..<steps {
                let t = CGFloat(step) / CGFloat(steps)
                points.append(CGPoint(x: from.x + (to.x - from.x) * t,
                                      y: from.y + (to.y - from.y) * t))
            }
        }

        func curve(_ from: CGPoint, _ control: CGPoint, to: CGPoint, steps: Int) {
            for step in 0..<steps {
                let t = CGFloat(step) / CGFloat(steps)
                let inverse = 1 - t
                points.append(CGPoint(
                    x: inverse * inverse * from.x + 2 * inverse * t * control.x + t * t * to.x,
                    y: inverse * inverse * from.y + 2 * inverse * t * control.y + t * t * to.y))
            }
        }

        func loop(centre: CGPoint, radius: CGFloat, steps: Int) {
            // Entered and left at the foot of the circle, which in texture
            // space is the largest y.
            for step in 0..<steps {
                // Sweeping downwards from the foot takes the train up the far
                // side first, which is the way a real vertical loop is run
                // when you enter it going right.
                let angle = CGFloat.pi / 2 - CGFloat(step) / CGFloat(steps) * .pi * 2
                points.append(CGPoint(x: centre.x + cos(angle) * radius,
                                      y: centre.y + sin(angle) * radius))
            }
        }

        // The loop is entered and left at its lowest point, travelling right
        // both times. Sending the train in one way and out the other is what
        // made it turn on a dime coming off the loop.
        let loopCentre = at(0.72, 0.62)
        let loopRadius = size.height * 0.28
        let loopFoot = CGPoint(x: loopCentre.x, y: loopCentre.y + loopRadius)

        // Out of the station and up the lift hill.
        line(at(0.06, 0.90), at(0.22, 0.90), steps: 5)
        line(at(0.22, 0.90), at(0.32, 0.13), steps: 16)
        // Over the crest and down the first drop.
        curve(at(0.32, 0.13), at(0.40, 0.10), to: at(0.44, 0.22), steps: 6)
        curve(at(0.44, 0.22), at(0.51, 0.68), to: at(0.56, 0.90), steps: 11)
        // Level run into the foot of the loop, still going right.
        line(at(0.56, 0.90), loopFoot, steps: 5)
        loop(centre: loopCentre, radius: loopRadius, steps: 30)
        // Straight out the far side, under the loop, and back along the
        // bottom to the station.
        line(loopFoot, at(0.90, 0.90), steps: 6)
        curve(at(0.90, 0.90), at(0.95, 0.91), to: at(0.94, 0.955), steps: 4)
        line(at(0.94, 0.955), at(0.11, 0.955), steps: 18)
        curve(at(0.11, 0.955), at(0.04, 0.955), to: at(0.06, 0.90), steps: 4)

        return points
    }

    private static func drawMegaCoasterBase(_ context: CGContext,
                                            _ size: CGSize,
                                            _ primary: UIColor,
                                            _ secondary: UIColor,
                                            _ accent: UIColor) {
        let ground = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.02, dy: size.height * 0.03)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: ground, cornerRadius: ground.height * 0.10), secondary)
        }

        let points = megaCoasterPoints(in: size)
        guard points.count > 2 else { return }

        // Supports first, so the track sits on top of them. Every few points
        // is enough to read as a structure without becoming a fence.
        let deck = size.height * 0.97
        let supports = UIBezierPath()
        for (index, point) in points.enumerated() where index % 5 == 0 && point.y < deck - 4 {
            supports.move(to: point)
            supports.addLine(to: CGPoint(x: point.x, y: deck))
        }
        stroke(supports, ParkPalette.colour(.slate).withAlphaComponent(0.55),
               width: max(1, size.width * 0.008))

        let track = UIBezierPath()
        track.move(to: points[0])
        for point in points.dropFirst() { track.addLine(to: point) }
        track.close()

        // Ties, then the rail on top, the same way the railway tiles are drawn.
        stroke(track, ParkPalette.colour(.charcoal), width: max(2.5, size.height * 0.030))
        stroke(track, accent, width: max(1, size.height * 0.013))

        // Station shed over the bottom-left straight, where the train boards.
        let station = CGRect(x: size.width * 0.05, y: size.height * 0.84,
                             width: size.width * 0.26, height: size.height * 0.12)
        fill(UIBezierPath(roundedRect: station, cornerRadius: station.height * 0.3), primary)

        // Chain marks up the lift hill, which is the bit everyone recognises.
        let chain = UIBezierPath()
        chain.move(to: CGPoint(x: size.width * 0.30, y: size.height * 0.90))
        chain.addLine(to: CGPoint(x: size.width * 0.40, y: size.height * 0.12))
        stroke(chain, ParkPalette.colour(.cream).withAlphaComponent(0.75),
               width: max(1, size.height * 0.008))
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
