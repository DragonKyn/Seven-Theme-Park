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

    /// A costume is a head taller than a person, and drawn that way.
    static let mascotScale: CGFloat = 1.45

    /// An entertainer with something held up over their head is drawn on a
    /// bigger canvas, with the figure the same size inside it, so there is
    /// room above them for balloons and balls instead of the top of the
    /// picture cutting them off.
    static let propScale: CGFloat = 1.45

    static func sizeScale(for look: StaffLook) -> CGFloat {
        switch look.role {
        case .mascot: return mascotScale
        case .entertainer: return look.act == .mime ? 1 : propScale
        case .janitor, .mechanic, .security: return 1
        }
    }

    /// How big the person is inside that canvas: the reverse of how much
    /// bigger the canvas is, so they stay the size everybody else is.
    static func figureScale(for look: StaffLook) -> CGFloat {
        1 / sizeScale(for: look)
    }

    /// What a drawing is filed under. Only the parts of the look that show are
    /// in it: a mascot has no use for the park's uniform, and a classic
    /// entertainer has no colour of its own to choose.
    static func cacheKey(for look: StaffLook, uniform: ParkColour) -> String {
        switch look.role {
        case .mascot:
            return "mascot-\(look.costume.rawValue)-\(look.primary.rawValue)"
                + "-\(look.secondary.rawValue)-\(look.trim.rawValue)"
        case .entertainer where look.act != .classic:
            return "act-\(look.act.rawValue)-\(look.primary.rawValue)"
        default:
            return "staff-\(look.role.rawValue)-\(uniform.rawValue)"
        }
    }

    static func texture(for look: StaffLook,
                        uniform: ParkColour,
                        height: CGFloat) -> SKTexture {
        let scale = sizeScale(for: look)
        let size = CGSize(width: height * scale * aspect * PersonArtwork.supersample,
                          height: height * scale * PersonArtwork.supersample)
        let key = cacheKey(for: look, uniform: uniform) + "-\(Int(size.height))"

        return SpriteFactory.texture(key: key, size: size) { context, size in
            draw(look, uniform: uniform, context: context, size: size)
        }
    }

    /// The same drawing as an image, for the hiring screen and the staff panel.
    static func previewImage(for look: StaffLook, uniform: ParkColour, size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { renderer in
            draw(look, uniform: uniform, context: renderer.cgContext, size: size)
        }
    }

    private static func draw(_ look: StaffLook,
                             uniform: ParkColour,
                             context: CGContext,
                             size: CGSize) {
        if look.role == .mascot {
            drawMascot(look, size: size)
            return
        }

        let shirt = shirtColour(for: look, uniform: uniform)
        if look.role == .entertainer && look.act == .magician {
            drawCapeBehind(colour: ParkPalette.colour(look.primary),
                           size: size,
                           figureScale: figureScale(for: look))
        }

        let layout = PersonArtwork.draw(personLook(for: look, shirt: shirt),
                                        tint: ParkPalette.colour(for: look.role),
                                        context: context,
                                        size: size)

        switch look.role {
        case .janitor:
            drawOveralls(layout: layout)
            drawBroom(layout: layout, size: size)
        case .mechanic:
            drawWrench(layout: layout, size: size, context: context)
        case .entertainer:
            switch look.act {
            case .classic: drawMegaphone(layout: layout)
            case .clown:
                drawClownCollar(layout: layout)
                drawHorn(layout: layout)
            case .balloonArtist: drawBalloonBunch(layout: layout)
            case .mime: break
            // The balls are not painted: they are sprites of their own, so
            // they can be thrown. See `JugglerRig`.
            case .juggler: break
            case .magician: drawWand(layout: layout)
            }
        case .security:
            drawSecurityMarkings(layout: layout)
        case .mascot:
            break
        }
    }

    /// The uniform for everybody but the entertainers who have an act of their
    /// own, who wear what the act calls for.
    private static func shirtColour(for look: StaffLook, uniform: ParkColour) -> UIColor {
        guard look.role == .entertainer else { return ParkPalette.colour(uniform) }
        switch look.act {
        case .classic: return ParkPalette.colour(uniform)
        case .magician: return ParkPalette.colour(.cream)
        case .clown, .balloonArtist, .mime, .juggler: return ParkPalette.colour(look.primary)
        }
    }

    private static func personLook(for look: StaffLook, shirt: UIColor) -> PersonArtwork.Look {
        let role = look.role
        let headwear: PersonArtwork.Headwear
        let headwearColour: UIColor
        var pattern = GuestAppearance.ShirtPattern.plain
        var facePaint: UIColor?
        var handColour: UIColor?
        var clownFace = false
        var bottoms = ParkPalette.colour(.charcoal)

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
            switch look.act {
            case .classic:
                headwear = .partyHat
                headwearColour = ParkPalette.colour(.red)
            case .clown:
                headwear = .clownWig
                headwearColour = ParkPalette.colour(.orange)
                pattern = .vest
                facePaint = ParkPalette.colour(.white)
                handColour = ParkPalette.colour(.white)
                clownFace = true
                bottoms = ParkPalette.colour(.yellow)
            case .balloonArtist:
                headwear = .cap
                headwearColour = ParkPalette.colour(.white)
            case .mime:
                headwear = .beret
                headwearColour = ParkPalette.colour(.charcoal)
                pattern = .stripes
                facePaint = ParkPalette.colour(.white)
                handColour = ParkPalette.colour(.white)
            case .juggler:
                headwear = .jesterHat
                headwearColour = ParkPalette.colour(look.primary)
            case .magician:
                headwear = .topHat
                headwearColour = ParkPalette.colour(.charcoal)
            }
        case .security:
            // A dark peaked cap whatever the park's colours are. A guard in a
            // pink cap is not a guard.
            headwear = .cap
            headwearColour = ParkPalette.colour(.charcoal)
        case .mascot:
            headwear = .none
            headwearColour = shirt
        }

        return PersonArtwork.Look(
            skin: .tan,
            hair: .dark,
            shirt: shirt,
            headwear: headwear,
            headwearColour: headwearColour,
            heightScale: figureScale(for: look),
            // Work trousers, the same for everybody: the uniform is the
            // shirt, and that is what the park's colour is for.
            bottoms: bottoms,
            pattern: pattern,
            accessory: role == .security ? .sunglasses : GuestAppearance.Accessory.none,
            expression: role == .entertainer ? .happy : .neutral,
            facePaint: facePaint,
            handColour: handColour,
            clownFace: clownFace)
    }

    // MARK: - Tools

    /// What makes a guard read as a guard at this size: a dark peaked cap,
    /// sunglasses and a badge. The cap and the glasses come from the figure
    /// itself; the badge is the part only a guard has.
    ///
    /// The word SECURITY was here first and it did not work — squeezed across
    /// a shirt a few pixels wide it was a smudge. A shield says the same thing
    /// in one shape.
    private static func drawSecurityMarkings(layout: PersonArtwork.Layout) {
        drawBadge(body: layout.body)
    }

    /// A shield on the left breast, with a star punched into it.
    private static func drawBadge(body: CGRect) {
        let width = body.width * 0.34
        let height = width * 1.15
        let centre = CGPoint(x: body.minX + body.width * 0.30,
                             y: body.minY + body.height * 0.34)

        let shield = UIBezierPath()
        shield.move(to: CGPoint(x: centre.x - width / 2, y: centre.y - height / 2))
        shield.addLine(to: CGPoint(x: centre.x + width / 2, y: centre.y - height / 2))
        shield.addLine(to: CGPoint(x: centre.x + width / 2, y: centre.y + height * 0.12))
        shield.addQuadCurve(to: CGPoint(x: centre.x, y: centre.y + height / 2),
                            controlPoint: CGPoint(x: centre.x + width * 0.42,
                                                  y: centre.y + height * 0.44))
        shield.addQuadCurve(to: CGPoint(x: centre.x - width / 2, y: centre.y + height * 0.12),
                            controlPoint: CGPoint(x: centre.x - width * 0.42,
                                                  y: centre.y + height * 0.44))
        shield.close()

        fillPath(shield, ParkPalette.colour(.amber))
        ParkPalette.colour(.charcoal).withAlphaComponent(0.75).setStroke()
        shield.lineWidth = max(0.5, width * 0.16)
        shield.stroke()

        let pip = width * 0.30
        fillPath(UIBezierPath(ovalIn: CGRect(x: centre.x - pip / 2, y: centre.y - pip / 2,
                                             width: pip, height: pip)),
                 ParkPalette.colour(.charcoal))
    }

    private static func fillPath(_ path: UIBezierPath, _ colour: UIColor) {
        colour.setFill()
        path.fill()
    }

    /// Bib and brace over the uniform shirt.
    ///
    /// A fixed workwear blue whatever the park's colours are, for the same
    /// reason the mechanic's hard hat is always amber: the point of the
    /// garment is that it is recognisable, and a bib in the park's pastel of
    /// the week is not. The shirt still shows at the shoulders and sleeves,
    /// so the employee is plainly one of yours.
    private static func drawOveralls(layout: PersonArtwork.Layout) {
        let body = layout.body
        let denim = ParkPalette.colour(.indigo)
        let stitch = ParkPalette.colour(.cream).withAlphaComponent(0.55)

        // The bib: a panel up the middle of the chest, narrower than the body
        // so the shirt reads as a shirt either side of it.
        let bib = CGRect(x: body.minX + body.width * 0.20,
                         y: body.minY + body.height * 0.26,
                         width: body.width * 0.60,
                         height: body.height * 0.78)
        denim.setFill()
        UIBezierPath(roundedRect: bib, cornerRadius: body.width * 0.10).fill()

        // Braces over each shoulder, angled in towards the bib.
        let braceWidth = max(0.6, body.width * 0.13)
        denim.setStroke()
        for side in [-1.0, 1.0] as [CGFloat] {
            let brace = UIBezierPath()
            brace.move(to: CGPoint(x: body.midX + side * body.width * 0.34,
                                   y: body.minY + body.height * 0.02))
            brace.addLine(to: CGPoint(x: body.midX + side * body.width * 0.20,
                                      y: bib.minY + braceWidth * 0.5))
            brace.lineWidth = braceWidth
            brace.lineCapStyle = .round
            brace.stroke()
        }

        // A pocket on the bib, which is the detail that says workwear rather
        // than apron at a glance.
        let pocket = CGRect(x: bib.midX - bib.width * 0.22,
                            y: bib.minY + bib.height * 0.16,
                            width: bib.width * 0.44,
                            height: bib.height * 0.24)
        stitch.setStroke()
        let outline = UIBezierPath(roundedRect: pocket, cornerRadius: pocket.height * 0.25)
        outline.lineWidth = max(0.4, body.width * 0.06)
        outline.stroke()
    }

    /// A broom held out at an angle, bristles on the ground.
    ///
    /// Held at a slant rather than upright: a vertical pole beside somebody
    /// reads as a flag or a railing, and only the angle says they are using
    /// it. The bristle block is wide because at this size it is most of what
    /// anybody can actually see.
    private static func drawBroom(layout: PersonArtwork.Layout, size: CGSize) {
        let unit = layout.body.width
        let grip = CGPoint(x: layout.body.maxX + unit * 0.16,
                           y: layout.body.minY + layout.body.height * 0.30)
        let foot = CGPoint(x: layout.body.maxX + unit * 0.86,
                           y: layout.bottom - unit * 0.16)

        let handle = UIBezierPath()
        handle.move(to: grip)
        handle.addLine(to: foot)
        ParkPalette.colour(.brown).setStroke()
        handle.lineWidth = max(1, unit * 0.20)
        handle.lineCapStyle = .round
        handle.stroke()

        // The head, square to the ground rather than to the handle, because
        // that is how a broom actually sits when somebody is sweeping with it.
        let head = CGRect(x: foot.x - unit * 0.46,
                          y: foot.y - unit * 0.04,
                          width: unit * 0.92,
                          height: unit * 0.34)
        ParkPalette.colour(.charcoal).setFill()
        UIBezierPath(roundedRect: CGRect(x: head.minX, y: head.minY,
                                         width: head.width, height: head.height * 0.42),
                     cornerRadius: head.height * 0.18).fill()

        ParkPalette.colour(.sand).setFill()
        UIBezierPath(rect: CGRect(x: head.minX, y: head.minY + head.height * 0.34,
                                  width: head.width, height: head.height * 0.66)).fill()

        // A few bristle gaps, which is what stops it reading as a block.
        ParkPalette.colour(.brown).withAlphaComponent(0.45).setStroke()
        let bristle = UIBezierPath()
        for step in 1...3 {
            let x = head.minX + head.width * (CGFloat(step) / 4)
            bristle.move(to: CGPoint(x: x, y: head.minY + head.height * 0.40))
            bristle.addLine(to: CGPoint(x: x, y: head.maxY))
        }
        bristle.lineWidth = max(0.4, unit * 0.05)
        bristle.stroke()
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
}
