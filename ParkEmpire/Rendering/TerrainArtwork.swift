import SpriteKit
import UIKit

/// The ground: walkways, bridges and water.
///
/// A walkway is drawn from what it joins onto rather than as a square of
/// paving, which is what makes a turn look like a turn. The paving is laid
/// over grass and pulled in on any side with nothing beyond it, so a corner
/// rounds off and a dead end finishes rather than stopping mid-slab.
enum TerrainArtwork {

    /// How much of a tile the kerb takes on an open side.
    private static let margin: CGFloat = 0.07
    /// How hard a corner rounds where two open sides meet.
    private static let corner: CGFloat = 0.40

    // MARK: - Walkways

    /// `connections` is a bitmask of north, east, south and west sides that
    /// carry on into more walkway.
    static func walkwayTexture(connections: Int,
                               style: UInt8,
                               variant: Int,
                               side: CGFloat) -> SKTexture {
        SpriteFactory.texture(key: "walk-\(style)-\(connections)-\(variant)-\(side)",
                              size: CGSize(width: side, height: side)) { context, size in
            // Grass underneath, because the paving no longer fills the tile.
            (variant % 2 == 0 ? ParkPalette.grass : ParkPalette.grassAlt).setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

            let shape = surface(connections: connections, size: size)
            let finish = WalkwayFinish(style: style)

            finish.base.setFill()
            shape.fill()

            context.saveGState()
            shape.addClip()
            finish.draw(size: size, variant: variant, connections: connections)
            context.restoreGState()

            // Kerb. Only the outline is stroked, so it curves round a corner
            // for free and disappears where two tiles meet.
            finish.kerb.setStroke()
            shape.lineWidth = max(1, size.width * 0.055)
            shape.stroke()
        }
    }

    /// The shape of the paving on one tile: full width across every side that
    /// carries on, pulled in on every side that does not, and rounded at any
    /// corner between two pulled-in sides.
    private static func surface(connections: Int, size: CGSize) -> UIBezierPath {
        let inset = size.width * margin
        let north = connections & 1 != 0
        let east = connections & 2 != 0
        let south = connections & 4 != 0
        let west = connections & 8 != 0

        // Texture space runs y downward, so north is the top edge.
        let top = north ? 0 : inset
        let bottom = size.height - (south ? 0 : inset)
        let left = west ? 0 : inset
        let right = size.width - (east ? 0 : inset)
        let radius = size.width * corner

        // A lone tile with nothing attached is a round pad rather than a
        // square of paving nobody laid.
        if connections == 0 {
            return UIBezierPath(roundedRect: CGRect(x: left, y: top,
                                                    width: right - left,
                                                    height: bottom - top),
                                cornerRadius: radius)
        }

        let path = UIBezierPath()
        // Corners are listed clockwise from the top left, each with the two
        // sides that meet there.
        let corners: [(point: CGPoint, rounded: Bool, centre: CGPoint)] = [
            (CGPoint(x: left, y: top), !north && !west, CGPoint(x: left + radius, y: top + radius)),
            (CGPoint(x: right, y: top), !north && !east, CGPoint(x: right - radius, y: top + radius)),
            (CGPoint(x: right, y: bottom), !south && !east, CGPoint(x: right - radius, y: bottom - radius)),
            (CGPoint(x: left, y: bottom), !south && !west, CGPoint(x: left + radius, y: bottom - radius))
        ]

        let startAngles: [CGFloat] = [.pi, .pi * 1.5, 0, .pi * 0.5]

        for (index, corner) in corners.enumerated() {
            if corner.rounded {
                let start = startAngles[index]
                if index == 0 {
                    path.move(to: CGPoint(x: corner.centre.x - radius, y: corner.centre.y))
                }
                path.addArc(withCenter: corner.centre,
                            radius: radius,
                            startAngle: start,
                            endAngle: start + .pi / 2,
                            clockwise: true)
            } else {
                if index == 0 {
                    path.move(to: corner.point)
                } else {
                    path.addLine(to: corner.point)
                }
            }
        }
        path.close()
        return path
    }

    /// What a walkway is paved with.
    private struct WalkwayFinish {
        let style: UInt8

        var base: UIColor {
            switch style {
            case 1: return UIColor(red: 0.78, green: 0.52, blue: 0.42, alpha: 1)
            case 2: return UIColor(red: 0.71, green: 0.55, blue: 0.38, alpha: 1)
            case 3: return UIColor(red: 0.40, green: 0.40, blue: 0.43, alpha: 1)
            default: return ParkPalette.path
            }
        }

        var kerb: UIColor {
            switch style {
            case 1: return UIColor(red: 0.60, green: 0.38, blue: 0.30, alpha: 0.85)
            case 2: return UIColor(red: 0.50, green: 0.37, blue: 0.24, alpha: 0.85)
            case 3: return UIColor(red: 0.28, green: 0.28, blue: 0.31, alpha: 0.85)
            default: return ParkPalette.pathJoint
            }
        }

        private var line: UIColor {
            switch style {
            case 1: return UIColor(red: 0.63, green: 0.40, blue: 0.32, alpha: 0.75)
            case 2: return UIColor(red: 0.52, green: 0.38, blue: 0.25, alpha: 0.80)
            case 3: return UIColor(white: 1, alpha: 0.10)
            default: return ParkPalette.pathJoint
            }
        }

        func draw(size: CGSize, variant: Int, connections: Int) {
            switch style {
            case 1: drawBrick(size: size, variant: variant)
            case 2: drawPlanks(size: size, connections: connections)
            case 3: drawTarmac(size: size, variant: variant)
            default: drawSlabs(size: size, variant: variant)
            }
        }

        /// Slabs, with the joint shifted every row so the courses interlock.
        private func drawSlabs(size: CGSize, variant: Int) {
            let joints = UIBezierPath()
            let rows = 2
            for row in 0...rows {
                let y = size.height * CGFloat(row) / CGFloat(rows)
                joints.move(to: CGPoint(x: 0, y: y))
                joints.addLine(to: CGPoint(x: size.width, y: y))
            }
            for row in 0..<rows {
                let y = size.height * CGFloat(row) / CGFloat(rows)
                let offset: CGFloat = (row + variant) % 2 == 0 ? 0.5 : 0.25
                joints.move(to: CGPoint(x: size.width * offset, y: y))
                joints.addLine(to: CGPoint(x: size.width * offset,
                                           y: y + size.height / CGFloat(rows)))
            }
            line.setStroke()
            joints.lineWidth = max(0.5, size.width * 0.022)
            joints.stroke()
        }

        /// Small bricks in a running bond.
        private func drawBrick(size: CGSize, variant: Int) {
            let rows = 4
            let columns = 3
            line.setStroke()
            let bricks = UIBezierPath()
            for row in 0...rows {
                let y = size.height * CGFloat(row) / CGFloat(rows)
                bricks.move(to: CGPoint(x: 0, y: y))
                bricks.addLine(to: CGPoint(x: size.width, y: y))
            }
            for row in 0..<rows {
                let y = size.height * CGFloat(row) / CGFloat(rows)
                let shift: CGFloat = (row + variant) % 2 == 0 ? 0 : 0.5
                for column in 0...columns {
                    let x = size.width * (CGFloat(column) + shift) / CGFloat(columns)
                    bricks.move(to: CGPoint(x: x, y: y))
                    bricks.addLine(to: CGPoint(x: x, y: y + size.height / CGFloat(rows)))
                }
            }
            bricks.lineWidth = max(0.5, size.width * 0.020)
            bricks.stroke()
        }

        /// Boards laid across the direction of travel.
        private func drawPlanks(size: CGSize, connections: Int) {
            // Boards run across the walk, so a run that goes north to south
            // gets boards that go east to west.
            let vertical = (connections & 1 != 0) || (connections & 4 != 0)
            let planks = UIBezierPath()
            let count = 5
            for index in 1..<count {
                let offset = CGFloat(index) / CGFloat(count)
                if vertical {
                    planks.move(to: CGPoint(x: 0, y: size.height * offset))
                    planks.addLine(to: CGPoint(x: size.width, y: size.height * offset))
                } else {
                    planks.move(to: CGPoint(x: size.width * offset, y: 0))
                    planks.addLine(to: CGPoint(x: size.width * offset, y: size.height))
                }
            }
            line.setStroke()
            planks.lineWidth = max(0.5, size.width * 0.028)
            planks.stroke()
        }

        /// Chippings, so a flat dark tile is not a flat dark tile.
        private func drawTarmac(size: CGSize, variant: Int) {
            line.setFill()
            let spots: [(CGFloat, CGFloat)] = [
                (0.22, 0.30), (0.61, 0.22), (0.38, 0.58), (0.76, 0.66), (0.16, 0.78)
            ]
            for (index, spot) in spots.enumerated() where (index + variant) % 2 == 0 {
                let side = size.width * 0.07
                UIBezierPath(ovalIn: CGRect(x: size.width * spot.0, y: size.height * spot.1,
                                            width: side, height: side)).fill()
            }
        }
    }

    // MARK: - Bridges

    /// A deck over the water, railed on the sides the walk does not continue.
    static func bridgeTexture(connections: Int, side: CGFloat) -> SKTexture {
        SpriteFactory.texture(key: "bridge-\(connections)-\(side)",
                              size: CGSize(width: side, height: side)) { _, size in
            ParkPalette.water.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

            let deck = ParkPalette.colour(.brown)
            let plank = UIColor(red: 0.42, green: 0.30, blue: 0.20, alpha: 0.8)
            let rail = ParkPalette.colour(.sand)

            // The deck runs the way the walk does; a bridge with nothing
            // attached is drawn north to south so it still reads as a deck.
            let northSouth = (connections & 1 != 0) || (connections & 4 != 0) || connections == 0
            let body = northSouth
                ? CGRect(x: size.width * 0.08, y: 0, width: size.width * 0.84, height: size.height)
                : CGRect(x: 0, y: size.height * 0.08, width: size.width, height: size.height * 0.84)
            deck.setFill()
            UIBezierPath(rect: body).fill()

            let planks = UIBezierPath()
            let count = 6
            for index in 1..<count {
                let offset = CGFloat(index) / CGFloat(count)
                if northSouth {
                    planks.move(to: CGPoint(x: body.minX, y: size.height * offset))
                    planks.addLine(to: CGPoint(x: body.maxX, y: size.height * offset))
                } else {
                    planks.move(to: CGPoint(x: size.width * offset, y: body.minY))
                    planks.addLine(to: CGPoint(x: size.width * offset, y: body.maxY))
                }
            }
            plank.setStroke()
            planks.lineWidth = max(0.5, size.width * 0.030)
            planks.stroke()

            // Rails down both long sides.
            rail.setFill()
            let thickness = max(1, size.width * 0.07)
            if northSouth {
                UIBezierPath(rect: CGRect(x: body.minX, y: 0,
                                          width: thickness, height: size.height)).fill()
                UIBezierPath(rect: CGRect(x: body.maxX - thickness, y: 0,
                                          width: thickness, height: size.height)).fill()
            } else {
                UIBezierPath(rect: CGRect(x: 0, y: body.minY,
                                          width: size.width, height: thickness)).fill()
                UIBezierPath(rect: CGRect(x: 0, y: body.maxY - thickness,
                                          width: size.width, height: thickness)).fill()
            }
        }
    }

    // MARK: - Water

    /// `shores` is a bitmask of the sides that are not more water. A pond
    /// drawn without edges is a blue rectangle; the edge is what makes it read
    /// as water in a bank.
    static func waterTexture(shores: Int, style: UInt8, variant: Int, side: CGFloat) -> SKTexture {
        SpriteFactory.texture(key: "water-\(style)-\(shores)-\(variant)-\(side)",
                              size: CGSize(width: side, height: side)) { _, size in
            let palette = WaterFinish(style: style)
            (variant % 2 == 0 ? palette.base : palette.alternate).setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

            // A ripple or two, offset by variant so the surface is not a grid.
            palette.ripple.setStroke()
            let ripples = UIBezierPath()
            let lift = variant % 2 == 0 ? CGFloat(0.34) : CGFloat(0.62)
            for step in 0..<2 {
                let y = size.height * (lift + 0.24 * CGFloat(step))
                ripples.move(to: CGPoint(x: size.width * 0.18, y: y))
                ripples.addQuadCurve(to: CGPoint(x: size.width * 0.62, y: y),
                                     controlPoint: CGPoint(x: size.width * 0.40,
                                                           y: y - size.height * 0.07))
            }
            ripples.lineWidth = max(1, size.width * 0.030)
            ripples.stroke()

            guard shores != 0 else { return }
            let band = size.width * 0.16
            palette.shore.setFill()
            if shores & 1 != 0 {
                UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: band)).fill()
            }
            if shores & 4 != 0 {
                UIBezierPath(rect: CGRect(x: 0, y: size.height - band,
                                          width: size.width, height: band)).fill()
            }
            if shores & 8 != 0 {
                UIBezierPath(rect: CGRect(x: 0, y: 0, width: band, height: size.height)).fill()
            }
            if shores & 2 != 0 {
                UIBezierPath(rect: CGRect(x: size.width - band, y: 0,
                                          width: band, height: size.height)).fill()
            }
        }
    }

    /// What colour the water is.
    private struct WaterFinish {
        let style: UInt8

        var base: UIColor {
            switch style {
            case 1: return UIColor(red: 0.22, green: 0.76, blue: 0.74, alpha: 1)
            case 2: return UIColor(red: 0.16, green: 0.32, blue: 0.56, alpha: 1)
            default: return ParkPalette.water
            }
        }

        var alternate: UIColor {
            switch style {
            case 1: return UIColor(red: 0.18, green: 0.71, blue: 0.70, alpha: 1)
            case 2: return UIColor(red: 0.13, green: 0.27, blue: 0.50, alpha: 1)
            default: return ParkPalette.waterAlt
            }
        }

        var ripple: UIColor {
            style == 2
                ? UIColor(white: 1, alpha: 0.12)
                : ParkPalette.waterRipple
        }

        var shore: UIColor {
            switch style {
            case 1: return UIColor(red: 0.85, green: 0.93, blue: 0.78, alpha: 0.65)
            case 2: return UIColor(red: 0.44, green: 0.58, blue: 0.74, alpha: 0.55)
            default: return ParkPalette.waterShore
            }
        }
    }
}
