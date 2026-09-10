import SpriteKit
import UIKit

/// Draws the little figures that walk around the park.
///
/// Guests and staff are the same body with different clothes and different
/// things in their hands, so the body lives here and the two callers add what
/// makes them recognisable.
enum PersonArtwork {

    /// How much bigger a figure is drawn than the sprite it fills, so it
    /// survives being zoomed in on.
    static let supersample: CGFloat = 3
    /// Width of a figure as a share of its height.
    static let aspect: CGFloat = 0.72

    enum Headwear {
        case none
        /// Flat brim.
        case cap
        /// Wide brim, for sun and for gardening.
        case sunHat
        /// Rounded shell with a ridge, for anyone near machinery.
        case hardHat
        /// Cone with a pompom.
        case partyHat
    }

    struct Look {
        let skin: GuestAppearance.SkinTone
        let hair: GuestAppearance.HairColour
        let shirt: UIColor
        let headwear: Headwear
        let headwearColour: UIColor
        /// 1.0 is an adult. Children and seniors are drawn shorter rather than
        /// drawn again.
        let heightScale: CGFloat
    }

    /// Where the parts of a drawn figure ended up, so a caller can hang a
    /// broom or a wrench off it without guessing.
    struct Layout {
        let head: CGRect
        let body: CGRect
        let bottom: CGFloat
    }

    /// Draws one figure and reports where its parts landed.
    ///
    /// `tint` colours the pad on the ground under the figure. That pad is how
    /// mood and role stay readable when the park is zoomed out and the figure
    /// itself is a few pixels tall; drawing it on the ground rather than
    /// behind the figure keeps it from reading as a coloured blob.
    @discardableResult
    static func draw(_ look: Look,
                     tint: UIColor,
                     context: CGContext,
                     size: CGSize) -> Layout {
        let figureHeight = size.height * look.heightScale
        let bottom = size.height - (size.height - figureHeight) * 0.20
        let centreX = size.width / 2
        let headSize = figureHeight * 0.42

        // Ground pad. Sized from the figure rather than the canvas, so a
        // caller can ask for a wider sprite to make room for a tool without
        // the person inside it growing to match.
        let padWidth = figureHeight * 0.62
        let pad = CGRect(x: centreX - padWidth / 2,
                         y: bottom - figureHeight * 0.10,
                         width: padWidth,
                         height: figureHeight * 0.15)
        tint.withAlphaComponent(0.92).setFill()
        UIBezierPath(ovalIn: pad).fill()

        let bodyWidth = figureHeight * 0.43
        let body = CGRect(x: centreX - bodyWidth / 2,
                          y: bottom - figureHeight * 0.58,
                          width: bodyWidth,
                          height: figureHeight * 0.50)
        let head = CGRect(x: centreX - headSize / 2,
                          y: bottom - figureHeight * 0.58 - headSize * 0.76,
                          width: headSize,
                          height: headSize)

        // A dark hairline around body and head is what stops a small figure
        // dissolving into the grass behind it.
        let outline = UIColor.black.withAlphaComponent(0.32)
        let outlineWidth = max(1, figureHeight * 0.04)

        let bodyPath = UIBezierPath(roundedRect: body, cornerRadius: bodyWidth * 0.30)
        look.shirt.setFill()
        bodyPath.fill()
        outline.setStroke()
        bodyPath.lineWidth = outlineWidth
        bodyPath.stroke()

        let headPath = UIBezierPath(ovalIn: head)
        skinColour(look.skin).setFill()
        headPath.fill()
        outline.setStroke()
        headPath.lineWidth = outlineWidth
        headPath.stroke()

        // Hair sits as a cap over the top half of the head, which reads at
        // this size where individual strands would not.
        let hair = UIBezierPath()
        hair.addArc(withCenter: CGPoint(x: head.midX, y: head.midY),
                    radius: head.width / 2,
                    startAngle: .pi,
                    endAngle: 0,
                    clockwise: true)
        hair.close()
        hairColour(look.hair).setFill()
        hair.fill()

        drawHeadwear(look, head: head, context: context, size: size)

        return Layout(head: head, body: body, bottom: bottom)
    }

    private static func drawHeadwear(_ look: Look,
                                     head: CGRect,
                                     context: CGContext,
                                     size: CGSize) {
        switch look.headwear {
        case .none:
            return

        case .cap:
            let crown = CGRect(x: head.minX, y: head.minY - head.height * 0.10,
                               width: head.width, height: head.height * 0.46)
            look.headwearColour.setFill()
            UIBezierPath(roundedRect: crown, cornerRadius: crown.height * 0.5).fill()
            let peak = CGRect(x: head.midX, y: head.minY + head.height * 0.22,
                              width: head.width * 0.62, height: head.height * 0.14)
            UIBezierPath(roundedRect: peak, cornerRadius: peak.height / 2).fill()

        case .sunHat:
            let brim = CGRect(x: head.minX - head.width * 0.28,
                              y: head.minY + head.height * 0.16,
                              width: head.width * 1.56, height: head.height * 0.20)
            look.headwearColour.setFill()
            UIBezierPath(ovalIn: brim).fill()
            let crown = CGRect(x: head.minX + head.width * 0.16,
                               y: head.minY - head.height * 0.08,
                               width: head.width * 0.68, height: head.height * 0.38)
            UIBezierPath(ovalIn: crown).fill()

        case .hardHat:
            let shell = CGRect(x: head.minX - head.width * 0.10,
                               y: head.minY - head.height * 0.16,
                               width: head.width * 1.20, height: head.height * 0.60)
            look.headwearColour.setFill()
            UIBezierPath(ovalIn: shell).fill()
            // Flat underside, so the shell reads as a helmet rather than a ball.
            let brim = CGRect(x: shell.minX, y: shell.midY + shell.height * 0.14,
                              width: shell.width, height: shell.height * 0.22)
            UIBezierPath(roundedRect: brim, cornerRadius: brim.height * 0.5).fill()
            // Ridge down the middle.
            let ridge = CGRect(x: shell.midX - shell.width * 0.05,
                               y: shell.minY + shell.height * 0.06,
                               width: shell.width * 0.10, height: shell.height * 0.42)
            UIColor.black.withAlphaComponent(0.18).setFill()
            UIBezierPath(rect: ridge).fill()

        case .partyHat:
            let cone = UIBezierPath()
            cone.move(to: CGPoint(x: head.midX, y: head.minY - head.height * 0.56))
            cone.addLine(to: CGPoint(x: head.minX + head.width * 0.06,
                                     y: head.minY + head.height * 0.22))
            cone.addLine(to: CGPoint(x: head.maxX - head.width * 0.06,
                                     y: head.minY + head.height * 0.22))
            cone.close()
            look.headwearColour.setFill()
            cone.fill()

            let pompom = head.width * 0.26
            ParkPalette.colour(.cream).setFill()
            UIBezierPath(ovalIn: CGRect(x: head.midX - pompom / 2,
                                        y: head.minY - head.height * 0.66,
                                        width: pompom, height: pompom)).fill()
        }
    }

    // MARK: - Palette

    static func skinColour(_ tone: GuestAppearance.SkinTone) -> UIColor {
        switch tone {
        case .deep:  return UIColor(red: 0.42, green: 0.28, blue: 0.20, alpha: 1)
        case .tan:   return UIColor(red: 0.68, green: 0.48, blue: 0.34, alpha: 1)
        case .olive: return UIColor(red: 0.83, green: 0.66, blue: 0.48, alpha: 1)
        case .fair:  return UIColor(red: 0.95, green: 0.81, blue: 0.68, alpha: 1)
        }
    }

    static func hairColour(_ colour: GuestAppearance.HairColour) -> UIColor {
        switch colour {
        case .dark:   return UIColor(red: 0.16, green: 0.13, blue: 0.12, alpha: 1)
        case .brown:  return UIColor(red: 0.40, green: 0.27, blue: 0.17, alpha: 1)
        case .sandy:  return UIColor(red: 0.79, green: 0.66, blue: 0.39, alpha: 1)
        case .ginger: return UIColor(red: 0.76, green: 0.40, blue: 0.19, alpha: 1)
        case .grey:   return UIColor(red: 0.78, green: 0.78, blue: 0.79, alpha: 1)
        }
    }
}
