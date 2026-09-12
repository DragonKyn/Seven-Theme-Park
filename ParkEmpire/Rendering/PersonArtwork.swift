import SpriteKit
import UIKit

/// Draws the little figures that walk around the park.
///
/// Guests and staff are the same body with different clothes and different
/// things in their hands, so the body lives here and the two callers add what
/// makes them recognisable.
///
/// Everything is built out of a handful of rounded shapes, because a figure is
/// about nineteen points tall on the map. What has to survive that size, in
/// order: the silhouette, the shirt colour, the face, and only then the
/// details somebody who zooms in will find.
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
        /// Brim with no crown.
        case visor
        /// Headband with two pom-poms on springs.
        case bobbleBand
        /// Rounded shell with a ridge, for anyone near machinery.
        case hardHat
        /// Cone with a pompom.
        case partyHat
    }

    /// How the face is drawn. Three states, like the mood pad under the
    /// figure, because a continuous range of expressions is unreadable at
    /// this size.
    enum Expression {
        case happy
        case neutral
        case sad
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
        /// Trousers, shorts or a skirt.
        var bottoms: UIColor = UIColor(red: 0.32, green: 0.35, blue: 0.42, alpha: 1)
        var pattern: GuestAppearance.ShirtPattern = .plain
        var accessory: GuestAppearance.Accessory = .none
        var expression: Expression = .neutral
        /// Something won at a carnival booth, carried under the arm or hugged
        /// in front. Nil for everybody who has not won anything.
        var prize: GuestPrize? = nil
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

        drawPack(look, body: body, figureHeight: figureHeight, outline: outline)
        drawLegs(look, body: body, bottom: bottom, figureHeight: figureHeight, outline: outline)

        // Torso: shirt, then whatever is printed on it, then the legwear
        // showing below the hem, all clipped to the one silhouette.
        let bodyPath = UIBezierPath(roundedRect: body, cornerRadius: bodyWidth * 0.30)
        look.shirt.setFill()
        bodyPath.fill()

        context.saveGState()
        bodyPath.addClip()
        drawShirtPattern(look, body: body)
        let hem = CGRect(x: body.minX, y: body.maxY - body.height * 0.30,
                         width: body.width, height: body.height * 0.30)
        look.bottoms.setFill()
        UIBezierPath(rect: hem).fill()
        context.restoreGState()

        outline.setStroke()
        bodyPath.lineWidth = outlineWidth
        bodyPath.stroke()

        drawArms(look, body: body, figureHeight: figureHeight, outline: outline)
        drawStrap(look, body: body, figureHeight: figureHeight, outline: outline)

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

        drawFace(look, head: head)
        drawHeadwear(look, head: head, context: context, size: size)
        drawPrize(look, body: body)

        return Layout(head: head, body: body, bottom: bottom)
    }

    // MARK: - The body

    /// Two legs and two shoes below the hem. Barely a few pixels each, and
    /// they are most of what makes a figure read as standing rather than as a
    /// coloured capsule.
    private static func drawLegs(_ look: Look,
                                 body: CGRect,
                                 bottom: CGFloat,
                                 figureHeight: CGFloat,
                                 outline: UIColor) {
        let legWidth = figureHeight * 0.075
        let legTop = body.maxY - figureHeight * 0.02
        let footY = bottom - figureHeight * 0.02

        for dx in [-figureHeight * 0.085, figureHeight * 0.085] {
            let leg = CGRect(x: body.midX + dx - legWidth / 2,
                             y: legTop,
                             width: legWidth,
                             height: footY - legTop)
            skinColour(look.skin).setFill()
            UIBezierPath(rect: leg).fill()

            let shoe = CGRect(x: leg.minX - legWidth * 0.25,
                              y: footY - figureHeight * 0.035,
                              width: legWidth * 1.5,
                              height: figureHeight * 0.05)
            ParkPalette.colour(.charcoal).setFill()
            UIBezierPath(ovalIn: shoe).fill()
        }
    }

    /// Arms down the sides of the torso.
    private static func drawArms(_ look: Look,
                                 body: CGRect,
                                 figureHeight: CGFloat,
                                 outline: UIColor) {
        let armWidth = figureHeight * 0.065
        let armTop = body.minY + body.height * 0.26

        for x in [body.minX - armWidth * 0.45, body.maxX - armWidth * 0.55] {
            let arm = CGRect(x: x, y: armTop,
                             width: armWidth, height: body.height * 0.62)
            let path = UIBezierPath(roundedRect: arm, cornerRadius: armWidth / 2)
            look.shirt.setFill()
            path.fill()
            // The forearm shows below a short sleeve.
            let hand = CGRect(x: arm.minX, y: arm.maxY - arm.height * 0.34,
                              width: armWidth, height: arm.height * 0.34)
            skinColour(look.skin).setFill()
            UIBezierPath(roundedRect: hand, cornerRadius: armWidth / 2).fill()
            outline.setStroke()
            path.lineWidth = max(0.5, figureHeight * 0.022)
            path.stroke()
        }
    }

    /// Stripes or an open jacket, drawn inside the torso's own outline.
    private static func drawShirtPattern(_ look: Look, body: CGRect) {
        switch look.pattern {
        case .plain:
            return

        case .stripes:
            UIColor.white.withAlphaComponent(0.55).setFill()
            for index in 0..<2 {
                let band = CGRect(x: body.minX,
                                  y: body.minY + body.height * (0.20 + 0.24 * CGFloat(index)),
                                  width: body.width,
                                  height: body.height * 0.12)
                UIBezierPath(rect: band).fill()
            }

        case .vest:
            UIColor.black.withAlphaComponent(0.22).setFill()
            let panel = CGRect(x: body.midX - body.width * 0.16,
                               y: body.minY,
                               width: body.width * 0.32,
                               height: body.height)
            UIBezierPath(rect: panel).fill()
        }
    }

    /// The bulk of a backpack, behind the shoulders. Drawn before the body so
    /// only its edges show, which is how a pack looks from the front.
    private static func drawPack(_ look: Look,
                                 body: CGRect,
                                 figureHeight: CGFloat,
                                 outline: UIColor) {
        guard look.accessory == .backpack else { return }
        let pack = CGRect(x: body.minX - figureHeight * 0.045,
                          y: body.minY + body.height * 0.10,
                          width: body.width + figureHeight * 0.09,
                          height: body.height * 0.62)
        let path = UIBezierPath(roundedRect: pack, cornerRadius: pack.width * 0.24)
        ParkPalette.colour(.brown).setFill()
        path.fill()
        outline.setStroke()
        path.lineWidth = max(0.5, figureHeight * 0.022)
        path.stroke()
    }

    /// What is worn over the shirt: backpack straps, or a camera on its strap.
    private static func drawStrap(_ look: Look,
                                  body: CGRect,
                                  figureHeight: CGFloat,
                                  outline: UIColor) {
        switch look.accessory {
        case .none, .sunglasses:
            return

        case .backpack:
            ParkPalette.colour(.charcoal).setFill()
            for dx in [-body.width * 0.24, body.width * 0.24] {
                let strap = CGRect(x: body.midX + dx - body.width * 0.055,
                                   y: body.minY + body.height * 0.06,
                                   width: body.width * 0.11,
                                   height: body.height * 0.52)
                UIBezierPath(roundedRect: strap, cornerRadius: strap.width * 0.4).fill()
            }

        case .phone:
            // Held up in front of the chest, screen towards us, with a
            // broadcast arc over it. Somebody filming holds their arms up,
            // which is what makes them readable in a crowd.
            let phone = CGRect(x: body.midX - body.width * 0.20,
                               y: body.minY - body.height * 0.10,
                               width: body.width * 0.40,
                               height: body.height * 0.46)
            let case_ = UIBezierPath(roundedRect: phone, cornerRadius: phone.width * 0.22)
            ParkPalette.colour(.charcoal).setFill()
            case_.fill()
            outline.setStroke()
            case_.lineWidth = max(0.5, figureHeight * 0.022)
            case_.stroke()

            ParkPalette.colour(.cyan).withAlphaComponent(0.9).setFill()
            UIBezierPath(roundedRect: phone.insetBy(dx: phone.width * 0.14,
                                                    dy: phone.height * 0.12),
                         cornerRadius: phone.width * 0.14).fill()

            let arcs = UIBezierPath()
            for step in 1...2 {
                let radius = figureHeight * (0.10 + 0.06 * CGFloat(step))
                arcs.addArc(withCenter: CGPoint(x: phone.midX, y: phone.minY),
                            radius: radius,
                            startAngle: .pi * 1.15,
                            endAngle: .pi * 1.85,
                            clockwise: true)
                arcs.close()
            }
            ParkPalette.colour(.pink).withAlphaComponent(0.85).setStroke()
            arcs.lineWidth = max(0.5, figureHeight * 0.022)
            arcs.stroke()

        case .camera:
            let strap = UIBezierPath()
            strap.move(to: CGPoint(x: body.midX - body.width * 0.26,
                                   y: body.minY + body.height * 0.06))
            strap.addLine(to: CGPoint(x: body.midX, y: body.midY))
            strap.addLine(to: CGPoint(x: body.midX + body.width * 0.26,
                                      y: body.minY + body.height * 0.06))
            ParkPalette.colour(.charcoal).setStroke()
            strap.lineWidth = max(0.5, figureHeight * 0.020)
            strap.stroke()

            let camera = CGRect(x: body.midX - body.width * 0.20,
                                y: body.midY - body.height * 0.04,
                                width: body.width * 0.40,
                                height: body.height * 0.22)
            ParkPalette.colour(.charcoal).setFill()
            UIBezierPath(roundedRect: camera, cornerRadius: camera.height * 0.25).fill()
            let lens = min(camera.width, camera.height) * 0.52
            ParkPalette.colour(.slate).setFill()
            UIBezierPath(ovalIn: CGRect(x: camera.midX - lens / 2,
                                        y: camera.midY - lens / 2,
                                        width: lens, height: lens)).fill()
        }
    }

    // MARK: - The face

    /// Two eyes and a mouth that follows the mood.
    ///
    /// This is the single biggest thing that makes a crowd read as people. The
    /// pad under a guest already says how they feel from across the park; the
    /// face says it when the player has zoomed in to find out why.
    private static func drawFace(_ look: Look, head: CGRect) {
        let eye = head.width * 0.10
        let eyeY = head.midY + head.height * 0.04

        if look.accessory == .sunglasses {
            let lensWidth = head.width * 0.30
            let lensHeight = head.height * 0.20
            ParkPalette.colour(.charcoal).setFill()
            for dx in [-head.width * 0.18, head.width * 0.18] {
                let lens = CGRect(x: head.midX + dx - lensWidth / 2,
                                  y: eyeY - lensHeight * 0.45,
                                  width: lensWidth, height: lensHeight)
                UIBezierPath(roundedRect: lens, cornerRadius: lensHeight * 0.4).fill()
            }
            UIBezierPath(rect: CGRect(x: head.midX - head.width * 0.07,
                                      y: eyeY - lensHeight * 0.10,
                                      width: head.width * 0.14,
                                      height: lensHeight * 0.20)).fill()
        } else {
            ParkPalette.colour(.charcoal).setFill()
            for dx in [-head.width * 0.17, head.width * 0.17] {
                UIBezierPath(ovalIn: CGRect(x: head.midX + dx - eye / 2,
                                            y: eyeY - eye / 2,
                                            width: eye, height: eye * 1.15)).fill()
            }
        }

        let mouth = UIBezierPath()
        let mouthY = head.midY + head.height * 0.24
        let halfWidth = head.width * 0.16

        switch look.expression {
        case .happy:
            mouth.move(to: CGPoint(x: head.midX - halfWidth, y: mouthY - head.height * 0.03))
            mouth.addQuadCurve(to: CGPoint(x: head.midX + halfWidth, y: mouthY - head.height * 0.03),
                               controlPoint: CGPoint(x: head.midX, y: mouthY + head.height * 0.12))
        case .neutral:
            mouth.move(to: CGPoint(x: head.midX - halfWidth * 0.7, y: mouthY))
            mouth.addLine(to: CGPoint(x: head.midX + halfWidth * 0.7, y: mouthY))
        case .sad:
            mouth.move(to: CGPoint(x: head.midX - halfWidth, y: mouthY + head.height * 0.05))
            mouth.addQuadCurve(to: CGPoint(x: head.midX + halfWidth, y: mouthY + head.height * 0.05),
                               controlPoint: CGPoint(x: head.midX, y: mouthY - head.height * 0.09))
        }

        ParkPalette.colour(.charcoal).setStroke()
        mouth.lineWidth = max(0.5, head.width * 0.075)
        mouth.lineCapStyle = .round
        mouth.stroke()
    }

    // MARK: - Prizes

    /// A prize the guest won, carried where its size allows.
    ///
    /// A small one is tucked under the near arm, on the left, because staff
    /// carry their tools on the right and a guest and an employee are the same
    /// body underneath. A giant one will not go under an arm at all, so it is
    /// held in front with both arms round it.
    ///
    /// Bold rather than detailed: at this size what has to read is "that
    /// person won something big", not which animal it is.
    private static func drawPrize(_ look: Look, body: CGRect) {
        guard let prize = look.prize else { return }

        let unit = body.width * prize.size.scale
        let colour = ParkPalette.colour(prize.colour)
        let outline = UIColor.black.withAlphaComponent(0.32)
        let outlineWidth = max(0.5, body.width * 0.07)

        let centre = prize.size.isHugged
            ? CGPoint(x: body.midX, y: body.midY + body.width * 0.30)
            : CGPoint(x: body.minX + body.width * 0.06, y: body.midY + body.width * 0.10)

        func blob(_ rect: CGRect, _ fill: UIColor, oval: Bool = true) {
            let path = oval
                ? UIBezierPath(ovalIn: rect)
                : UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.3)
            fill.setFill()
            path.fill()
            outline.setStroke()
            path.lineWidth = outlineWidth
            path.stroke()
        }

        let torso = unit * 0.46
        let head = unit * 0.34

        switch prize.kind {
        case .star:
            let points = 5
            let outer = unit * 0.30
            let star = UIBezierPath()
            for step in 0..<(points * 2) {
                let radius = step % 2 == 0 ? outer : outer * 0.44
                let angle = -CGFloat.pi / 2 + CGFloat(step) * .pi / CGFloat(points)
                let point = CGPoint(x: centre.x + cos(angle) * radius,
                                    y: centre.y + sin(angle) * radius)
                if step == 0 { star.move(to: point) } else { star.addLine(to: point) }
            }
            star.close()
            colour.setFill()
            star.fill()
            outline.setStroke()
            star.lineWidth = outlineWidth
            star.stroke()

        case .ball:
            let side = unit * 0.56
            let ball = CGRect(x: centre.x - side / 2, y: centre.y - side / 2,
                              width: side, height: side)
            blob(ball, colour)
            let stripe = UIBezierPath()
            stripe.move(to: CGPoint(x: ball.minX + side * 0.12, y: ball.midY))
            stripe.addQuadCurve(to: CGPoint(x: ball.maxX - side * 0.12, y: ball.midY),
                                controlPoint: CGPoint(x: ball.midX, y: ball.minY))
            UIColor.white.withAlphaComponent(0.85).setStroke()
            stripe.lineWidth = max(0.5, unit * 0.10)
            stripe.stroke()

        case .duck:
            blob(CGRect(x: centre.x - torso / 2, y: centre.y - torso * 0.20,
                        width: torso, height: torso * 0.80), colour)
            blob(CGRect(x: centre.x - head * 0.20, y: centre.y - head * 0.72,
                        width: head, height: head), colour)
            blob(CGRect(x: centre.x + head * 0.52, y: centre.y - head * 0.34,
                        width: head * 0.44, height: head * 0.28),
                 ParkPalette.colour(.orange), oval: false)

        case .bear, .dog, .bunny:
            blob(CGRect(x: centre.x - torso / 2, y: centre.y - torso * 0.10,
                        width: torso, height: torso * 0.92), colour)
            blob(CGRect(x: centre.x - head / 2, y: centre.y - head * 0.74,
                        width: head, height: head), colour)

            // The ears are the whole difference between the three of them.
            let ear = head * 0.44
            switch prize.kind {
            case .bunny:
                for dx in [-head * 0.22, head * 0.22] {
                    blob(CGRect(x: centre.x + dx - ear * 0.26,
                                y: centre.y - head * 1.28,
                                width: ear * 0.52, height: ear * 1.30), colour)
                }
            case .dog:
                for dx in [-head * 0.46, head * 0.46] {
                    blob(CGRect(x: centre.x + dx - ear * 0.30,
                                y: centre.y - head * 0.66,
                                width: ear * 0.60, height: ear * 1.00), colour)
                }
            default:
                for dx in [-head * 0.38, head * 0.38] {
                    blob(CGRect(x: centre.x + dx - ear / 2,
                                y: centre.y - head * 0.92,
                                width: ear, height: ear), colour)
                }
            }
        }

        // Two arms round a giant one, so it reads as held rather than as a
        // second person standing in front of the first.
        guard prize.size.isHugged else { return }
        let armWidth = body.width * 0.16
        for dx in [-torso * 0.52, torso * 0.52] {
            let arm = CGRect(x: centre.x + dx - armWidth / 2,
                             y: centre.y + torso * 0.10,
                             width: armWidth, height: torso * 0.46)
            let path = UIBezierPath(roundedRect: arm, cornerRadius: armWidth / 2)
            look.shirt.setFill()
            path.fill()
            outline.setStroke()
            path.lineWidth = outlineWidth
            path.stroke()
        }
    }

    // MARK: - Hats

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

        case .visor:
            // Brim and a band, with the top of the head left bare.
            let brim = CGRect(x: head.minX - head.width * 0.16,
                              y: head.minY + head.height * 0.20,
                              width: head.width * 1.32, height: head.height * 0.16)
            look.headwearColour.setFill()
            UIBezierPath(ovalIn: brim).fill()
            let band = CGRect(x: head.minX + head.width * 0.04,
                              y: head.minY + head.height * 0.12,
                              width: head.width * 0.92, height: head.height * 0.14)
            UIBezierPath(roundedRect: band, cornerRadius: band.height * 0.5).fill()

        case .bobbleBand:
            let band = UIBezierPath()
            band.move(to: CGPoint(x: head.minX + head.width * 0.10,
                                  y: head.minY + head.height * 0.24))
            band.addQuadCurve(to: CGPoint(x: head.maxX - head.width * 0.10,
                                          y: head.minY + head.height * 0.24),
                              controlPoint: CGPoint(x: head.midX, y: head.minY - head.height * 0.06))
            look.headwearColour.setStroke()
            band.lineWidth = max(0.5, head.width * 0.09)
            band.stroke()

            let bobble = head.width * 0.26
            look.headwearColour.setFill()
            for dx in [-head.width * 0.30, head.width * 0.30] {
                UIBezierPath(ovalIn: CGRect(x: head.midX + dx - bobble / 2,
                                            y: head.minY - head.height * 0.26,
                                            width: bobble, height: bobble)).fill()
            }

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
