import SpriteKit
import UIKit

/// Draws employees.
///
/// Everyone wears the park's uniform colour, so the crowd reads as "these
/// people work here" at a glance. What separates the three roles is what is
/// on their head and what is in their hands, which stays readable when the
/// uniform is changed to something the roles were never designed around.
enum StaffArtwork {

    /// Wider than a guest, because an employee is carrying something and the
    /// tool has to fit in the sprite alongside them.
    static let aspect: CGFloat = 1.05

    static func texture(for role: StaffRole,
                        uniform: ParkColour,
                        height: CGFloat) -> SKTexture {
        let size = CGSize(width: height * aspect * PersonArtwork.supersample,
                          height: height * PersonArtwork.supersample)
        let key = "staff-\(role.rawValue)-\(uniform.rawValue)-\(Int(size.height))"

        return SpriteFactory.texture(key: key, size: size) { context, size in
            let shirt = ParkPalette.colour(uniform)
            let layout = PersonArtwork.draw(look(for: role, shirt: shirt),
                                            tint: ParkPalette.colour(for: role),
                                            context: context,
                                            size: size)

            switch role {
            case .janitor: drawBroom(layout: layout, size: size)
            case .mechanic: drawWrench(layout: layout, size: size, context: context)
            case .entertainer: drawBalloons(layout: layout, size: size)
            }
        }
    }

    private static func look(for role: StaffRole, shirt: UIColor) -> PersonArtwork.Look {
        let headwear: PersonArtwork.Headwear
        let headwearColour: UIColor
        switch role {
        case .janitor:
            headwear = .cap
            headwearColour = shirt
        case .mechanic:
            // Amber whatever the uniform is: a hard hat that blends in is not
            // doing its job, on a building site or on a map.
            headwear = .hardHat
            headwearColour = ParkPalette.colour(.amber)
        case .entertainer:
            headwear = .partyHat
            headwearColour = ParkPalette.colour(.red)
        }

        return PersonArtwork.Look(
            skin: .tan,
            hair: .dark,
            shirt: shirt,
            headwear: headwear,
            headwearColour: headwearColour,
            heightScale: 1.0)
    }

    // MARK: - Tools

    /// A long handle down the right-hand side with a block of bristles at the
    /// foot. At this size the bristles are the whole silhouette.
    private static func drawBroom(layout: PersonArtwork.Layout, size: CGSize) {
        let unit = layout.body.width
        let x = layout.body.maxX + unit * 0.34

        let handle = UIBezierPath()
        handle.move(to: CGPoint(x: x, y: layout.head.midY))
        handle.addLine(to: CGPoint(x: x, y: layout.bottom - unit * 0.10))
        ParkPalette.colour(.brown).setStroke()
        handle.lineWidth = max(1, unit * 0.16)
        handle.stroke()

        let bristles = CGRect(x: x - unit * 0.30,
                              y: layout.bottom - unit * 0.34,
                              width: unit * 0.60,
                              height: unit * 0.26)
        ParkPalette.colour(.sand).setFill()
        UIBezierPath(roundedRect: bristles, cornerRadius: bristles.height * 0.3).fill()
    }

    /// A stubby spanner held out from the body, open jaw uppermost.
    private static func drawWrench(layout: PersonArtwork.Layout,
                                   size: CGSize,
                                   context: CGContext) {
        let unit = layout.body.width
        let shaft = CGRect(x: layout.body.maxX + unit * 0.16,
                           y: layout.body.midY - unit * 0.06,
                           width: unit * 0.18,
                           height: unit * 0.62)
        ParkPalette.colour(.slate).setFill()
        UIBezierPath(roundedRect: shaft, cornerRadius: shaft.width * 0.4).fill()

        let jaw = CGRect(x: shaft.midX - unit * 0.22,
                         y: shaft.minY - unit * 0.24,
                         width: unit * 0.44,
                         height: unit * 0.30)
        UIBezierPath(ovalIn: jaw).fill()

        // Bite out of the jaw, which is what makes it a spanner and not a
        // mallet. Punched through to transparency so whatever the employee is
        // standing on shows through it.
        context.saveGState()
        context.setBlendMode(.clear)
        UIColor.black.setFill()
        UIBezierPath(ovalIn: jaw.insetBy(dx: jaw.width * 0.30, dy: jaw.height * 0.26)).fill()
        context.restoreGState()
    }

    /// Two balloons on strings, drifting off the shoulder.
    private static func drawBalloons(layout: PersonArtwork.Layout, size: CGSize) {
        let unit = layout.body.width
        let anchor = CGPoint(x: layout.body.maxX + unit * 0.08, y: layout.body.midY)
        let balloons: [(CGFloat, CGFloat, ParkColour)] = [
            (0.34, 0.62, .red),
            (0.62, 0.30, .yellow)
        ]

        for (dx, dy, colour) in balloons {
            let centre = CGPoint(x: anchor.x + unit * dx,
                                 y: layout.head.minY - unit * dy)

            let string = UIBezierPath()
            string.move(to: anchor)
            string.addQuadCurve(to: centre,
                                controlPoint: CGPoint(x: anchor.x, y: centre.y))
            UIColor.white.withAlphaComponent(0.75).setStroke()
            string.lineWidth = max(0.5, unit * 0.05)
            string.stroke()

            let side = unit * 0.52
            ParkPalette.colour(colour).setFill()
            UIBezierPath(ovalIn: CGRect(x: centre.x - side / 2,
                                        y: centre.y - side / 2,
                                        width: side, height: side * 1.15)).fill()
        }
    }
}
