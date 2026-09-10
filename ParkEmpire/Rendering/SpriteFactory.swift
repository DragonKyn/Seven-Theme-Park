import SpriteKit
import UIKit

/// Generates the placeholder artwork programmatically.
///
/// Everything the map draws is a rounded rectangle or a circle rendered once
/// and cached as an `SKTexture`, which keeps the project asset-free until real
/// art is worth making.
enum SpriteFactory {

    private static var cache: [String: SKTexture] = [:]

    static func clearCache() {
        cache.removeAll()
    }

    /// Flat tile with a subtle inset border.
    static func tileTexture(colour: UIColor, side: CGFloat) -> SKTexture {
        texture(key: "tile-\(colour.hashValue)-\(side)", size: CGSize(width: side, height: side)) { context, size in
            colour.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

            context.setStrokeColor(UIColor.black.withAlphaComponent(0.05).cgColor)
            context.setLineWidth(1)
            context.stroke(CGRect(origin: .zero, size: size))
        }
    }

    /// Rounded block used for rides, shops and facilities.
    static func buildingTexture(colour: UIColor, size: CGSize) -> SKTexture {
        texture(key: "building-\(colour.hashValue)-\(size.width)x\(size.height)", size: size) { context, size in
            let inset = min(size.width, size.height) * 0.07
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            let radius = min(rect.width, rect.height) * 0.18

            context.setShadow(offset: CGSize(width: 0, height: -2),
                              blur: 4,
                              color: UIColor.black.withAlphaComponent(0.25).cgColor)

            colour.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()

            context.setShadow(offset: .zero, blur: 0, color: nil)

            // Light top face to give a hint of depth without going isometric.
            let highlight = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)
            UIColor.white.withAlphaComponent(0.22).setFill()
            UIBezierPath(roundedRect: CGRect(x: highlight.minX,
                                             y: highlight.midY,
                                             width: highlight.width,
                                             height: highlight.height / 2),
                         cornerRadius: radius * 0.6).fill()
        }
    }

    static func circleTexture(colour: UIColor, diameter: CGFloat) -> SKTexture {
        texture(key: "circle-\(colour.hashValue)-\(diameter)",
                size: CGSize(width: diameter, height: diameter)) { _, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            UIColor.white.withAlphaComponent(0.85).setFill()
            UIBezierPath(ovalIn: rect).fill()
            colour.setFill()
            UIBezierPath(ovalIn: rect.insetBy(dx: 1.5, dy: 1.5)).fill()
        }
    }

    /// Scattered specks of rubbish. Three intensity steps are enough to read
    /// the difference at a glance, and it keeps the texture cache tiny.
    static func litterTexture(intensity: Int, side: CGFloat) -> SKTexture {
        texture(key: "litter-\(intensity)-\(side)", size: CGSize(width: side, height: side)) { _, size in
            let count = 2 + intensity * 3
            // Fixed offsets rather than randomness so the same tile always
            // draws the same way between frames.
            let offsets: [(CGFloat, CGFloat)] = [
                (0.22, 0.31), (0.68, 0.19), (0.44, 0.62), (0.81, 0.71),
                (0.14, 0.77), (0.57, 0.42), (0.33, 0.12), (0.72, 0.51),
                (0.09, 0.48), (0.90, 0.36), (0.51, 0.86)
            ]
            ParkPalette.litter.setFill()
            for index in 0..<min(count, offsets.count) {
                let offset = offsets[index]
                let dotSize = size.width * (index % 2 == 0 ? 0.10 : 0.07)
                let rect = CGRect(x: offset.0 * size.width - dotSize / 2,
                                  y: offset.1 * size.height - dotSize / 2,
                                  width: dotSize,
                                  height: dotSize)
                UIBezierPath(ovalIn: rect).fill()
            }
        }
    }

    /// One tile of railway, drawn to match the track it is actually connected
    /// to. `connections` is a bitmask of north, east, south and west.
    ///
    /// A tile with two opposite neighbours is drawn straight through, and one
    /// with two neighbours at right angles is drawn as a proper curve. Drawing
    /// a corner as two straight stubs meeting in the middle is what made a
    /// bend look like two pieces overlapping.
    /// A special coaster piece: the plain tile with the element drawn over it.
    ///
    /// Elements are drawn on top of ordinary track rather than replacing it,
    /// so a loop still reads as connected to whatever it is bolted between.
    static func coasterElementTexture(connections: Int,
                                      side: CGFloat,
                                      element: TerrainType) -> SKTexture {
        let base = trackTileTexture(connections: connections, side: side, coaster: true)
        return texture(key: "coaster-\(element.rawValue)-\(connections)-\(side)",
                       size: CGSize(width: side, height: side)) { context, size in
            context.saveGState()
            // Core Graphics draws images bottom-up; the tile is square and the
            // track pattern is symmetric, so only the flip matters.
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(base.cgImage(), in: CGRect(origin: .zero, size: size))
            context.restoreGState()

            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            ParkPalette.coasterRail.setStroke()

            switch element {
            case .coasterLoop:
                // A ring standing on the track, drawn twice so it reads as a
                // tube rather than as a circle painted on the ground.
                let radius = size.width * 0.30
                let ring = UIBezierPath(ovalIn: CGRect(x: centre.x - radius,
                                                       y: centre.y - radius * 1.05,
                                                       width: radius * 2, height: radius * 2))
                ParkPalette.coasterTie.setStroke()
                ring.lineWidth = max(2, size.width * 0.13)
                ring.stroke()
                ParkPalette.coasterRail.setStroke()
                ring.lineWidth = max(1, size.width * 0.055)
                ring.stroke()

            case .coasterHill:
                // A hump with chain marks up its face.
                let hump = UIBezierPath()
                hump.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.74))
                hump.addQuadCurve(to: CGPoint(x: size.width * 0.92, y: size.height * 0.74),
                                  controlPoint: CGPoint(x: centre.x, y: -size.height * 0.16))
                ParkPalette.coasterTie.setStroke()
                hump.lineWidth = max(2, size.width * 0.13)
                hump.stroke()
                ParkPalette.coasterRail.setStroke()
                hump.lineWidth = max(1, size.width * 0.055)
                hump.stroke()

            case .coasterHelix:
                // Two offset rings, which is as close as a flat tile gets to a
                // corkscrew.
                let radius = size.width * 0.22
                for offset in [-size.width * 0.13, size.width * 0.13] {
                    let ring = UIBezierPath(ovalIn: CGRect(x: centre.x + offset - radius,
                                                           y: centre.y - radius,
                                                           width: radius * 2, height: radius * 2))
                    ParkPalette.coasterTie.setStroke()
                    ring.lineWidth = max(2, size.width * 0.11)
                    ring.stroke()
                    ParkPalette.coasterRail.setStroke()
                    ring.lineWidth = max(1, size.width * 0.048)
                    ring.stroke()
                }

            default:
                break
            }
        }
    }

    static func trackTileTexture(connections: Int,
                                 side: CGFloat,
                                 coaster: Bool = false) -> SKTexture {
        let bed = coaster ? ParkPalette.coasterBed : ParkPalette.ballast
        let tie = coaster ? ParkPalette.coasterTie : ParkPalette.sleeper
        let railColour = coaster ? ParkPalette.coasterRail : ParkPalette.rail

        return texture(key: "track-\(coaster ? "c" : "r")-\(connections)-\(side)",
                       size: CGSize(width: side, height: side)) { _, size in
            bed.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let gauge = size.width * 0.24
            let tieWidth = max(2, size.width * 0.30)
            let railWidth = max(1, size.width * 0.055)

            // Texture space runs y downward, so north is the top of the image.
            let directions: [(bit: Int, vector: CGPoint)] = [
                (1, CGPoint(x: 0, y: -1)),
                (2, CGPoint(x: 1, y: 0)),
                (4, CGPoint(x: 0, y: 1)),
                (8, CGPoint(x: -1, y: 0))
            ]
            let live = directions.filter { connections & $0.bit != 0 }

            func edgePoint(_ vector: CGPoint) -> CGPoint {
                CGPoint(x: centre.x + vector.x * size.width / 2,
                        y: centre.y + vector.y * size.height / 2)
            }

            /// Ties first as one thick dark stroke, then the pair of rails on
            /// top, so the rails read continuous across the whole tile.
            func layTrack(_ build: (UIBezierPath, CGFloat) -> Void) {
                let ties = UIBezierPath()
                build(ties, 0)
                tie.setStroke()
                ties.lineWidth = tieWidth
                ties.stroke()

                railColour.setStroke()
                for offset in [-gauge / 2, gauge / 2] {
                    let rail = UIBezierPath()
                    build(rail, offset)
                    rail.lineWidth = railWidth
                    rail.stroke()
                }
            }

            // Two neighbours at right angles: a curve about the tile corner
            // they share.
            if live.count == 2,
               live[0].vector.x != -live[1].vector.x || live[0].vector.y != -live[1].vector.y {
                let first = live[0].vector
                let second = live[1].vector
                let corner = CGPoint(x: centre.x + (first.x + second.x) * size.width / 2,
                                     y: centre.y + (first.y + second.y) * size.height / 2)
                let radius = size.width / 2
                let start = atan2(-second.y, -second.x)
                var sweep = atan2(-first.y, -first.x) - start
                while sweep > .pi { sweep -= .pi * 2 }
                while sweep < -.pi { sweep += .pi * 2 }

                layTrack { path, offset in
                    let arcRadius = radius + offset
                    let steps = 12
                    for step in 0...steps {
                        let angle = start + sweep * CGFloat(step) / CGFloat(steps)
                        let point = CGPoint(x: corner.x + cos(angle) * arcRadius,
                                            y: corner.y + sin(angle) * arcRadius)
                        if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                    }
                }
                return
            }

            // Everything else is straight arms out of the middle: a through
            // run, a junction, a dead end, or a lone tile showing a stub both
            // ways so a half-drawn line does not look like bare gravel.
            let arms = live.isEmpty ? [directions[1], directions[3]] : live
            for arm in arms {
                let end = edgePoint(arm.vector)
                layTrack { path, offset in
                    // Offset across the direction of travel.
                    let across = CGPoint(x: -arm.vector.y * offset, y: arm.vector.x * offset)
                    path.move(to: CGPoint(x: centre.x + across.x, y: centre.y + across.y))
                    path.addLine(to: CGPoint(x: end.x + across.x, y: end.y + across.y))
                }
            }
        }
    }

    /// A coaster car, nose to the right. Smaller and lower than a railway
    /// carriage, with the riders showing over the sides.
    static func coasterCarTexture(isLeading: Bool, size: CGSize) -> SKTexture {
        texture(key: "coaster-car-\(isLeading ? "lead" : "follow")-\(Int(size.width))x\(Int(size.height))",
                size: size) { context, size in
            let body = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: size.height * 0.14)

            context.setShadow(offset: CGSize(width: 0, height: size.height * 0.12),
                              blur: size.height * 0.18,
                              color: UIColor.black.withAlphaComponent(0.30).cgColor)

            if isLeading {
                let nose = UIBezierPath()
                nose.move(to: CGPoint(x: body.minX, y: body.minY))
                nose.addLine(to: CGPoint(x: body.maxX - body.width * 0.22, y: body.minY))
                nose.addQuadCurve(to: CGPoint(x: body.maxX - body.width * 0.22, y: body.maxY),
                                  controlPoint: CGPoint(x: body.maxX + body.width * 0.18,
                                                        y: body.midY))
                nose.addLine(to: CGPoint(x: body.minX, y: body.maxY))
                nose.close()
                ParkPalette.colour(.red).setFill()
                nose.fill()
            } else {
                ParkPalette.colour(.red).setFill()
                UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.34).fill()
            }
            context.setShadow(offset: .zero, blur: 0, color: nil)

            ParkPalette.colour(.cream).setFill()
            let head = size.height * 0.40
            for offset in [CGFloat(0.24), CGFloat(0.54)] {
                UIBezierPath(ovalIn: CGRect(x: body.minX + body.width * offset,
                                            y: body.midY - head / 2,
                                            width: head, height: head)).fill()
            }

            ParkPalette.coasterTie.setFill()
            UIBezierPath(rect: CGRect(x: body.minX, y: body.maxY - size.height * 0.10,
                                      width: body.width * 0.88,
                                      height: size.height * 0.10)).fill()
        }
    }

    /// A locomotive or a carriage, nose to the right, because the sprite is
    /// turned to face the way it is travelling.
    static func trainCarTexture(isLocomotive: Bool, size: CGSize) -> SKTexture {
        texture(key: "train-\(isLocomotive ? "loco" : "car")-\(Int(size.width))x\(Int(size.height))",
                size: size) { context, size in
            let colour = isLocomotive
                ? ParkPalette.colour(.red)
                : ParkPalette.colour(.cream)

            context.setShadow(offset: CGSize(width: 0, height: size.height * 0.10),
                              blur: size.height * 0.16,
                              color: UIColor.black.withAlphaComponent(0.30).cgColor)

            let body = CGRect(x: size.width * 0.04, y: size.height * 0.16,
                              width: size.width * 0.92, height: size.height * 0.68)
            colour.setFill()
            UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.30).fill()
            context.setShadow(offset: .zero, blur: 0, color: nil)

            if isLocomotive {
                // Boiler front and a funnel, which is the whole silhouette at
                // this size.
                let nose = CGRect(x: body.maxX - body.width * 0.22, y: body.minY,
                                  width: body.width * 0.22, height: body.height)
                ParkPalette.colour(.charcoal).setFill()
                UIBezierPath(roundedRect: nose, cornerRadius: body.height * 0.3).fill()

                let funnel = CGRect(x: body.maxX - body.width * 0.40,
                                    y: body.minY - size.height * 0.10,
                                    width: body.width * 0.13,
                                    height: body.height * 0.42)
                UIBezierPath(roundedRect: funnel, cornerRadius: funnel.width * 0.3).fill()
            } else {
                // Windows down the side.
                ParkPalette.colour(.charcoal).withAlphaComponent(0.55).setFill()
                for index in 0..<3 {
                    let window = CGRect(x: body.minX + body.width * (0.14 + 0.26 * CGFloat(index)),
                                        y: body.midY - body.height * 0.20,
                                        width: body.width * 0.18,
                                        height: body.height * 0.40)
                    UIBezierPath(roundedRect: window, cornerRadius: window.height * 0.25).fill()
                }
            }

            // Underframe, so the car does not float.
            ParkPalette.colour(.charcoal).setFill()
            UIBezierPath(rect: CGRect(x: body.minX + body.width * 0.06,
                                      y: body.maxY - size.height * 0.02,
                                      width: body.width * 0.88,
                                      height: size.height * 0.10)).fill()
        }
    }

    /// The board and posts of the park's entrance sign. The name itself is a
    /// label node on top, because it changes and the texture cache should not
    /// grow a new entry every time the player renames the park.
    static func entranceSignTexture(size: CGSize) -> SKTexture {
        texture(key: "entrance-sign-\(Int(size.width))x\(Int(size.height))", size: size) { context, size in
            // Posts first, so the board covers where they meet it.
            let postWidth = size.width * 0.05
            for x in [size.width * 0.22, size.width * 0.78 - postWidth] {
                let post = CGRect(x: x, y: size.height * 0.45,
                                  width: postWidth, height: size.height * 0.55)
                ParkPalette.signPost.setFill()
                UIBezierPath(rect: post).fill()
            }

            let board = CGRect(x: size.width * 0.04, y: size.height * 0.06,
                               width: size.width * 0.92, height: size.height * 0.62)
            context.setShadow(offset: CGSize(width: 0, height: size.height * 0.04),
                              blur: size.height * 0.09,
                              color: UIColor.black.withAlphaComponent(0.30).cgColor)
            ParkPalette.signFrame.setFill()
            UIBezierPath(roundedRect: board, cornerRadius: board.height * 0.24).fill()
            context.setShadow(offset: .zero, blur: 0, color: nil)

            let face = board.insetBy(dx: board.width * 0.025, dy: board.height * 0.11)
            ParkPalette.signFace.setFill()
            UIBezierPath(roundedRect: face, cornerRadius: face.height * 0.22).fill()
        }
    }

    /// Asphalt with marked bays and a few cars left in them, drawn outside the
    /// park below the sign. Nothing simulates it and nothing can be built on
    /// it; it is there so the gate reads as somewhere people arrive at rather
    /// than the edge of the world.
    static func carParkTexture(level: Int, size: CGSize) -> SKTexture {
        texture(key: "car-park-\(level)-\(Int(size.width))x\(Int(size.height))", size: size) { context, size in
            let asphalt = CGRect(origin: .zero, size: size)
            // Gravel at first, blacker tarmac as it is paved.
            ParkPalette.carParkSurface(level: level).setFill()
            UIBezierPath(roundedRect: asphalt, cornerRadius: size.height * 0.06).fill()

            // Two banks of bays with an aisle between them.
            let bays = 11
            let bayWidth = size.width / CGFloat(bays)
            let bankHeight = size.height * 0.36
            let banks = [size.height * 0.06, size.height * 0.58]

            ParkPalette.bayLine.setStroke()
            for bankTop in banks {
                for index in 0...bays {
                    let line = UIBezierPath()
                    let x = bayWidth * CGFloat(index)
                    line.move(to: CGPoint(x: x, y: bankTop))
                    line.addLine(to: CGPoint(x: x, y: bankTop + bankHeight))
                    line.lineWidth = max(1, size.height * 0.008)
                    line.stroke()
                }
            }

            // Cars in some of the bays, and not the same ones in each bank, so
            // it reads as a car park in use rather than a pattern.
            // More of it paved means more of it used, which is the whole point
            // of paying for the next level.
            let allBays: [(Int, Int)] = [
                (0, 0), (0, 1), (0, 3), (0, 4), (0, 5), (0, 8), (0, 9), (0, 6), (0, 10), (0, 2),
                (1, 1), (1, 2), (1, 4), (1, 7), (1, 8), (1, 10), (1, 0), (1, 5), (1, 9), (1, 3)
            ]
            let filled = 6 + level * 3
            let occupied = Array(allBays.prefix(min(filled, allBays.count)))
            let liveries: [ParkColour] = [.red, .blue, .cream, .slate, .green, .amber, .violet]

            for (order, slot) in occupied.enumerated() {
                let (bank, bay) = slot
                let colour = ParkPalette.colour(liveries[order % liveries.count])
                let body = CGRect(x: bayWidth * CGFloat(bay) + bayWidth * 0.18,
                                  y: banks[bank] + bankHeight * 0.12,
                                  width: bayWidth * 0.64,
                                  height: bankHeight * 0.76)
                colour.setFill()
                UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.3).fill()

                // Windscreen, which is what stops each car reading as a brick.
                let glass = body.insetBy(dx: body.width * 0.18, dy: body.height * 0.30)
                UIColor.black.withAlphaComponent(0.28).setFill()
                UIBezierPath(roundedRect: glass, cornerRadius: glass.width * 0.25).fill()
            }

            // Aisle markings down the middle.
            let aisle = size.height * 0.50
            let dash = UIBezierPath()
            dash.move(to: CGPoint(x: 0, y: aisle))
            dash.addLine(to: CGPoint(x: size.width, y: aisle))
            dash.lineWidth = max(1, size.height * 0.012)
            dash.setLineDash([size.width * 0.03, size.width * 0.03], count: 2, phase: 0)
            ParkPalette.bayLine.setStroke()
            dash.stroke()
        }
    }

    static func outlineTexture(colour: UIColor, size: CGSize, lineWidth: CGFloat = 3) -> SKTexture {
        texture(key: "outline-\(colour.hashValue)-\(size.width)x\(size.height)-\(lineWidth)", size: size) { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            context.setStrokeColor(colour.cgColor)
            context.setLineWidth(lineWidth)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    // MARK: - Rendering helper

    /// Draws once and caches by key. Internal rather than private so the
    /// motif artwork in `BuildingArtwork` shares one cache with everything else.
    static func texture(key: String,
                        size: CGSize,
                        draw: (CGContext, CGSize) -> Void) -> SKTexture {
        if let cached = cache[key] { return cached }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { rendererContext in
            draw(rendererContext.cgContext, size)
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        cache[key] = texture
        return texture
    }
}
