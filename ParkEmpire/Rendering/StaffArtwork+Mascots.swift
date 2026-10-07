import SpriteKit
import UIKit

/// Park mascots: a person in a big costume.
///
/// Every costume shares one body, a round torso, a belly, mitts and a bow tie,
/// so the mascot reads as the same kind of character whichever animal it is.
/// What changes is the silhouette, because at this size that is all anybody
/// sees: a bear is round ears, a bunny is long ones, a lion is a mane, an
/// elephant is a trunk and two enormous ears.
///
/// Three colours run through all of them. The first is the fur or feathers,
/// the second is whatever is set against it (belly, muzzle, mane, beak), and
/// the third is the bow tie and shoes. All three can be repainted by the
/// player, so nothing here is drawn in a colour that is not one of them,
/// apart from the things that are the same on every animal: white gloves, the
/// whites of the eyes, and ink.
extension StaffArtwork {

    // MARK: - Drawing kit

    private struct Pen {
        let ink: UIColor
        let line: CGFloat

        func fill(_ path: UIBezierPath, _ colour: UIColor, outlined: Bool = true) {
            colour.setFill()
            path.fill()
            if outlined {
                ink.setStroke()
                path.lineWidth = line
                path.stroke()
            }
        }

        func oval(_ centre: CGPoint, _ width: CGFloat, _ height: CGFloat,
                  _ colour: UIColor, angle: CGFloat = 0, outlined: Bool = true) {
            let path = UIBezierPath(ovalIn: CGRect(x: -width / 2, y: -height / 2,
                                                   width: width, height: height))
            path.apply(CGAffineTransform(rotationAngle: angle))
            path.apply(CGAffineTransform(translationX: centre.x, y: centre.y))
            fill(path, colour, outlined: outlined)
        }

        func polygon(_ points: [CGPoint], _ colour: UIColor, outlined: Bool = true) {
            guard let first = points.first else { return }
            let path = UIBezierPath()
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            path.close()
            path.lineJoinStyle = .round
            fill(path, colour, outlined: outlined)
        }

        /// A fat curved line with an outline round it, for tails and trunks.
        func tube(_ path: UIBezierPath, _ colour: UIColor, width: CGFloat) {
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            ink.setStroke()
            path.lineWidth = width + line * 2
            path.stroke()
            colour.setStroke()
            path.lineWidth = width
            path.stroke()
        }

        func stroke(_ path: UIBezierPath, _ colour: UIColor, width: CGFloat) {
            path.lineCapStyle = .round
            colour.setStroke()
            path.lineWidth = width
            path.stroke()
        }
    }

    /// Where things go. `m` is the costume's own unit: nearly all the
    /// measurements below are fractions of it.
    private struct Costume {
        let look: StaffLook
        let primary: UIColor
        let secondary: UIColor
        let trim: UIColor
        let cx: CGFloat
        let floor: CGFloat
        let m: CGFloat
        let pen: Pen

        var headCentre: CGPoint { CGPoint(x: cx, y: floor - 0.70 * m) }

        /// A point measured from the middle of the head, in units of `m`.
        func head(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
            CGPoint(x: cx + dx * m, y: headCentre.y + dy * m)
        }

        /// A point measured from the floor in the middle, up and across.
        func low(_ dx: CGFloat, _ up: CGFloat) -> CGPoint {
            CGPoint(x: cx + dx * m, y: floor - up * m)
        }

        var gloves: Bool {
            switch look.costume {
            case .duck, .owl, .penguin: return false
            default: return true
            }
        }
    }

    // MARK: - Entry point

    static func drawMascot(_ look: StaffLook, size: CGSize) {
        let u = size.height
        let costume = Costume(look: look,
                              primary: ParkPalette.colour(look.primary),
                              secondary: ParkPalette.colour(look.secondary),
                              trim: ParkPalette.colour(look.trim),
                              cx: size.width / 2,
                              floor: u * 0.97,
                              m: u * 0.76,
                              pen: Pen(ink: UIColor.black.withAlphaComponent(0.34),
                                       line: max(1, u * 0.017)))

        // A faint shadow to stand on, the same as everybody else.
        UIColor.black.withAlphaComponent(0.13).setFill()
        let pad = CGRect(x: costume.cx - costume.m * 0.30, y: costume.floor - costume.m * 0.05,
                         width: costume.m * 0.60, height: costume.m * 0.09)
        UIBezierPath(ovalIn: pad).fill()

        drawBackdrop(costume)
        drawFeet(costume)
        drawBody(costume)
        drawArms(costume)
        drawNeckwear(costume)
        drawHead(costume)
        drawFace(costume)
    }

    // MARK: - Behind everything: tails, wings, manes, ears

    private static func drawBackdrop(_ c: Costume) {
        let pen = c.pen
        switch c.look.costume {
        case .bear:
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.25, -0.24), c.m * 0.21, c.m * 0.21, c.primary)
                pen.oval(c.head(side * 0.25, -0.24), c.m * 0.11, c.m * 0.11, c.secondary, outlined: false)
            }

        case .bunny:
            for side in [-1.0, 1.0] as [CGFloat] {
                let centre = c.head(side * 0.14, -0.42)
                pen.oval(centre, c.m * 0.15, c.m * 0.34, c.primary, angle: side * 0.14)
                pen.oval(centre, c.m * 0.08, c.m * 0.24, c.secondary, angle: side * 0.14, outlined: false)
            }

        case .cat:
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.polygon([c.head(side * 0.31, -0.06), c.head(side * 0.29, -0.40),
                             c.head(side * 0.08, -0.26)], c.primary)
                pen.polygon([c.head(side * 0.27, -0.12), c.head(side * 0.26, -0.32),
                             c.head(side * 0.13, -0.24)], c.secondary, outlined: false)
            }
            let tail = UIBezierPath()
            tail.move(to: c.low(0.22, 0.14))
            tail.addQuadCurve(to: c.low(0.52, 0.52), controlPoint: c.low(0.56, 0.10))
            pen.tube(tail, c.primary, width: c.m * 0.09)

        case .owl:
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.polygon([c.head(side * 0.30, -0.02), c.head(side * 0.26, -0.40),
                             c.head(side * 0.08, -0.24)], c.primary)
            }

        case .dragon:
            // Wings, bat-like, behind the shoulders.
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.polygon([c.low(side * 0.20, 0.48), c.low(side * 0.58, 0.82),
                             c.low(side * 0.50, 0.50), c.low(side * 0.60, 0.36),
                             c.low(side * 0.38, 0.40), c.low(side * 0.26, 0.20)],
                            c.secondary)
            }
            let tail = UIBezierPath()
            tail.move(to: c.low(0.20, 0.12))
            tail.addQuadCurve(to: c.low(0.54, 0.40), controlPoint: c.low(0.56, 0.06))
            pen.tube(tail, c.primary, width: c.m * 0.10)
            pen.polygon([c.low(0.54, 0.50), c.low(0.62, 0.38), c.low(0.46, 0.38)], c.secondary)

        case .lion:
            // The mane: a ring of tufts, then the disc they stand round.
            let centre = c.head(0, 0.0)
            for index in 0..<12 {
                let angle = CGFloat(index) / 12 * CGFloat.pi * 2
                let spot = CGPoint(x: centre.x + cos(angle) * c.m * 0.34,
                                   y: centre.y + sin(angle) * c.m * 0.32)
                pen.oval(spot, c.m * 0.22, c.m * 0.22, c.secondary)
            }
            pen.oval(centre, c.m * 0.70, c.m * 0.66, c.secondary, outlined: false)
            let tail = UIBezierPath()
            tail.move(to: c.low(0.22, 0.14))
            tail.addQuadCurve(to: c.low(0.50, 0.44), controlPoint: c.low(0.54, 0.08))
            pen.tube(tail, c.primary, width: c.m * 0.07)
            pen.oval(c.low(0.52, 0.48), c.m * 0.16, c.m * 0.18, c.secondary)

        case .elephant:
            for side in [-1.0, 1.0] as [CGFloat] {
                let centre = c.head(side * 0.40, 0.02)
                pen.oval(centre, c.m * 0.32, c.m * 0.40, c.primary, angle: side * -0.12)
                pen.oval(centre, c.m * 0.21, c.m * 0.29, c.secondary, angle: side * -0.12, outlined: false)
            }

        case .frog, .duck, .penguin:
            break
        }
    }

    // MARK: - Feet

    private static func drawFeet(_ c: Costume) {
        let colour: UIColor
        switch c.look.costume {
        case .duck: colour = c.secondary
        case .penguin: colour = ParkPalette.colour(.amber)
        default: colour = c.trim
        }
        let width = c.look.costume == .frog || c.look.costume == .duck ? 0.27 : 0.22

        for side in [-1.0, 1.0] as [CGFloat] {
            c.pen.oval(c.low(side * 0.14, 0.05), c.m * width, c.m * 0.11, colour)
        }
    }

    // MARK: - Body

    private static func drawBody(_ c: Costume) {
        let pen = c.pen
        pen.oval(c.low(0, 0.30), c.m * 0.54, c.m * 0.48, c.primary)

        // Belly.
        let belly = c.low(0, 0.27)
        switch c.look.costume {
        case .penguin:
            pen.oval(belly, c.m * 0.38, c.m * 0.40, c.secondary, outlined: false)
        case .lion:
            pen.oval(belly, c.m * 0.32, c.m * 0.30,
                     UIColor.white.withAlphaComponent(0.30), outlined: false)
        case .owl:
            pen.oval(belly, c.m * 0.36, c.m * 0.36, c.secondary, outlined: false)
            // Feathers: little scallops down the chest.
            for row in 0..<3 {
                for column in 0..<(row + 2) {
                    let offset = (CGFloat(column) - CGFloat(row + 1) / 2) * 0.12
                    let spot = c.low(offset, 0.36 - CGFloat(row) * 0.09)
                    let scallop = UIBezierPath()
                    scallop.addArc(withCenter: spot, radius: c.m * 0.05,
                                   startAngle: 0, endAngle: .pi, clockwise: true)
                    pen.stroke(scallop, c.primary.withAlphaComponent(0.7), width: c.m * 0.02)
                }
            }
        case .dragon:
            pen.oval(belly, c.m * 0.32, c.m * 0.34, c.secondary, outlined: false)
            for row in 0..<4 {
                let band = UIBezierPath()
                let y = c.floor - c.m * (0.16 + 0.07 * CGFloat(row))
                band.move(to: CGPoint(x: c.cx - c.m * 0.12, y: y))
                band.addLine(to: CGPoint(x: c.cx + c.m * 0.12, y: y))
                pen.stroke(band, c.primary.withAlphaComponent(0.45), width: c.m * 0.02)
            }
        default:
            pen.oval(belly, c.m * 0.32, c.m * 0.30, c.secondary, outlined: false)
        }
    }

    // MARK: - Arms and gloves

    private static func drawArms(_ c: Costume) {
        let pen = c.pen
        for side in [-1.0, 1.0] as [CGFloat] {
            let angle = side * -0.32
            let shoulder = c.low(side * 0.31, 0.32)
            let width: CGFloat = c.look.costume == .penguin ? 0.11 : 0.15
            pen.oval(shoulder, c.m * width, c.m * 0.31, c.primary, angle: angle)

            guard c.gloves else { continue }
            // The hand, at the far end of the arm.
            let reach = c.m * 0.15
            let hand = CGPoint(x: shoulder.x - sin(angle) * reach,
                               y: shoulder.y + cos(angle) * reach)
            pen.oval(hand, c.m * 0.17, c.m * 0.14, UIColor.white)
        }
    }

    // MARK: - Bow tie, or a scarf

    private static func drawNeckwear(_ c: Costume) {
        let pen = c.pen
        let neck = c.low(0, 0.53)

        if c.look.costume == .penguin {
            // A scarf: a band round the neck and a tail hanging down the front.
            pen.oval(neck, c.m * 0.40, c.m * 0.11, c.trim)
            pen.polygon([CGPoint(x: neck.x + c.m * 0.07, y: neck.y),
                         CGPoint(x: neck.x + c.m * 0.17, y: neck.y + c.m * 0.02),
                         CGPoint(x: neck.x + c.m * 0.15, y: neck.y + c.m * 0.22),
                         CGPoint(x: neck.x + c.m * 0.06, y: neck.y + c.m * 0.20)], c.trim)
            return
        }

        pen.polygon([neck,
                     CGPoint(x: neck.x - c.m * 0.14, y: neck.y - c.m * 0.07),
                     CGPoint(x: neck.x - c.m * 0.14, y: neck.y + c.m * 0.07)], c.trim)
        pen.polygon([neck,
                     CGPoint(x: neck.x + c.m * 0.14, y: neck.y - c.m * 0.07),
                     CGPoint(x: neck.x + c.m * 0.14, y: neck.y + c.m * 0.07)], c.trim)
        pen.oval(neck, c.m * 0.07, c.m * 0.07, c.trim)
    }

    // MARK: - Head

    private static func drawHead(_ c: Costume) {
        let wide: CGFloat = c.look.costume == .frog ? 0.70 : 0.62
        let tall: CGFloat = c.look.costume == .frog ? 0.50 : 0.56
        c.pen.oval(c.head(0, 0), c.m * wide, c.m * tall, c.primary)
    }

    // MARK: - Faces

    private static func drawFace(_ c: Costume) {
        let pen = c.pen
        let dark = ParkPalette.colour(.charcoal)

        switch c.look.costume {
        case .bear:
            pen.oval(c.head(0, 0.10), c.m * 0.31, c.m * 0.22, c.secondary)
            pen.oval(c.head(0, 0.03), c.m * 0.11, c.m * 0.07, dark, outlined: false)
            smile(c, at: c.head(0, 0.09), width: 0.12)
            eyes(c, dx: 0.14, dy: -0.07, diameter: 0.15)

        case .frog:
            // The eyes sit up on top of the head, which is the whole frog.
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.20, -0.28), c.m * 0.25, c.m * 0.25, c.primary)
            }
            eyes(c, dx: 0.20, dy: -0.28, diameter: 0.17)
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.26, 0.08), c.m * 0.12, c.m * 0.08,
                         ParkPalette.colour(.pink).withAlphaComponent(0.55), outlined: false)
                pen.oval(c.head(side * 0.05, -0.04), c.m * 0.03, c.m * 0.03, dark, outlined: false)
            }
            let mouth = UIBezierPath()
            mouth.move(to: c.head(-0.25, 0.06))
            mouth.addQuadCurve(to: c.head(0.25, 0.06), controlPoint: c.head(0, 0.22))
            pen.stroke(mouth, dark, width: c.m * 0.03)

        case .bunny:
            pen.oval(c.head(0, 0.10), c.m * 0.28, c.m * 0.19, UIColor.white)
            pen.oval(c.head(0, 0.04), c.m * 0.08, c.m * 0.055, c.secondary, outlined: false)
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.26, 0.08), c.m * 0.11, c.m * 0.08,
                         c.secondary.withAlphaComponent(0.45), outlined: false)
            }
            let teeth = CGRect(x: c.head(0, 0).x - c.m * 0.045, y: c.head(0, 0.13).y,
                               width: c.m * 0.09, height: c.m * 0.08)
            pen.fill(UIBezierPath(roundedRect: teeth, cornerRadius: c.m * 0.02), UIColor.white)
            let split = UIBezierPath()
            split.move(to: CGPoint(x: teeth.midX, y: teeth.minY))
            split.addLine(to: CGPoint(x: teeth.midX, y: teeth.maxY))
            pen.stroke(split, c.look.primary == .white ? dark.withAlphaComponent(0.4) : c.primary, width: c.m * 0.01)
            eyes(c, dx: 0.14, dy: -0.08, diameter: 0.15)

        case .duck:
            // Three tufts on top, and a broad flat beak.
            for dx in [-0.07, 0.0, 0.07] as [CGFloat] {
                pen.oval(c.head(dx, -0.30), c.m * 0.07, c.m * 0.14, c.primary, angle: dx * 3)
            }
            eyes(c, dx: 0.14, dy: -0.10, diameter: 0.14)
            pen.oval(c.head(0, 0.10), c.m * 0.40, c.m * 0.17, c.secondary)
            let seam = UIBezierPath()
            seam.move(to: c.head(-0.17, 0.10))
            seam.addLine(to: c.head(0.17, 0.10))
            pen.stroke(seam, UIColor.black.withAlphaComponent(0.28), width: c.m * 0.015)

        case .cat:
            let stripes = UIBezierPath()
            for dx in [-0.08, 0.0, 0.08] as [CGFloat] {
                stripes.move(to: c.head(dx, -0.27))
                stripes.addLine(to: c.head(dx * 0.8, -0.17))
            }
            pen.stroke(stripes, UIColor.black.withAlphaComponent(0.25), width: c.m * 0.025)
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.07, 0.10), c.m * 0.16, c.m * 0.14, c.secondary, outlined: false)
            }
            pen.polygon([c.head(-0.04, 0.04), c.head(0.04, 0.04), c.head(0, 0.09)],
                        ParkPalette.colour(.pink), outlined: false)
            let whiskers = UIBezierPath()
            for side in [-1.0, 1.0] as [CGFloat] {
                for tilt in [-0.04, 0.0, 0.04] as [CGFloat] {
                    whiskers.move(to: c.head(side * 0.14, 0.10 + tilt * 0.5))
                    whiskers.addLine(to: c.head(side * 0.36, 0.10 + tilt * 2))
                }
            }
            pen.stroke(whiskers, UIColor.white.withAlphaComponent(0.9), width: c.m * 0.012)
            eyes(c, dx: 0.14, dy: -0.07, diameter: 0.15)

        case .owl:
            // Two big round faces with the eyes in them, and a small beak.
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.15, -0.03), c.m * 0.30, c.m * 0.30, c.secondary)
            }
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.15, -0.03), c.m * 0.21, c.m * 0.21, UIColor.white)
                pen.oval(c.head(side * 0.15, -0.03), c.m * 0.13, c.m * 0.13,
                         ParkPalette.colour(.amber), outlined: false)
                pen.oval(c.head(side * 0.15, -0.03), c.m * 0.07, c.m * 0.07, dark, outlined: false)
            }
            pen.polygon([c.head(-0.045, 0.06), c.head(0.045, 0.06), c.head(0, 0.17)],
                        ParkPalette.colour(.amber))

        case .penguin:
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.10, 0.03), c.m * 0.23, c.m * 0.28, c.secondary, outlined: false)
            }
            eyes(c, dx: 0.12, dy: -0.04, diameter: 0.13)
            pen.polygon([c.head(-0.07, 0.07), c.head(0.07, 0.07), c.head(0, 0.17)],
                        ParkPalette.colour(.amber))

        case .dragon:
            // Horns and a crest, a long snout with nostrils and a few teeth.
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.polygon([c.head(side * 0.22, -0.20), c.head(side * 0.30, -0.44),
                             c.head(side * 0.12, -0.26)], c.secondary)
            }
            for dx in [-0.09, 0.0, 0.09] as [CGFloat] {
                pen.polygon([c.head(dx - 0.04, -0.27), c.head(dx, -0.38),
                             c.head(dx + 0.04, -0.27)], c.secondary, outlined: false)
            }
            pen.oval(c.head(0, 0.10), c.m * 0.34, c.m * 0.22, UIColor.white.withAlphaComponent(0.28),
                     outlined: false)
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.06, 0.04), c.m * 0.035, c.m * 0.03, dark, outlined: false)
                pen.polygon([c.head(side * 0.13, 0.17), c.head(side * 0.10, 0.17),
                             c.head(side * 0.115, 0.21)], UIColor.white, outlined: false)
            }
            // Eyes with a slit for a pupil.
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.14, -0.08), c.m * 0.15, c.m * 0.15,
                         ParkPalette.colour(.amber))
                pen.oval(c.head(side * 0.14, -0.08), c.m * 0.04, c.m * 0.11, dark, outlined: false)
            }

        case .lion:
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.22, -0.25), c.m * 0.14, c.m * 0.14, c.primary)
            }
            pen.oval(c.head(0, 0.10), c.m * 0.28, c.m * 0.20, UIColor.white.withAlphaComponent(0.55),
                     outlined: false)
            pen.polygon([c.head(-0.05, 0.03), c.head(0.05, 0.03), c.head(0, 0.09)],
                        ParkPalette.colour(.brown), outlined: false)
            smile(c, at: c.head(0, 0.10), width: 0.14)
            eyes(c, dx: 0.14, dy: -0.07, diameter: 0.14)

        case .elephant:
            // The trunk, curling down and a little to one side, with tusks.
            for side in [-1.0, 1.0] as [CGFloat] {
                pen.oval(c.head(side * 0.11, 0.20), c.m * 0.06, c.m * 0.13,
                         UIColor.white, angle: side * 0.25)
            }
            let trunk = UIBezierPath()
            trunk.move(to: c.head(0, 0.02))
            trunk.addQuadCurve(to: c.head(0.07, 0.40), controlPoint: c.head(-0.04, 0.26))
            pen.tube(trunk, c.primary, width: c.m * 0.13)
            let rings = UIBezierPath()
            for step in 1...3 {
                let y = 0.10 + CGFloat(step) * 0.08
                rings.move(to: c.head(-0.05, y))
                rings.addLine(to: c.head(0.05, y))
            }
            pen.stroke(rings, UIColor.black.withAlphaComponent(0.18), width: c.m * 0.015)
            eyes(c, dx: 0.14, dy: -0.07, diameter: 0.12)
        }
    }

    // MARK: - Small parts

    /// Two round eyes with a glint, which is what makes a costume look back.
    private static func eyes(_ c: Costume, dx: CGFloat, dy: CGFloat, diameter: CGFloat) {
        let dark = ParkPalette.colour(.charcoal)
        for side in [-1.0, 1.0] as [CGFloat] {
            let centre = c.head(side * dx, dy)
            c.pen.oval(centre, c.m * diameter, c.m * diameter, UIColor.white)
            c.pen.oval(CGPoint(x: centre.x, y: centre.y + c.m * 0.005),
                       c.m * diameter * 0.52, c.m * diameter * 0.58, dark, outlined: false)
            c.pen.oval(CGPoint(x: centre.x - c.m * diameter * 0.10, y: centre.y - c.m * diameter * 0.12),
                       c.m * diameter * 0.17, c.m * diameter * 0.17, UIColor.white, outlined: false)
        }
    }

    /// A small curved smile under the nose.
    private static func smile(_ c: Costume, at point: CGPoint, width: CGFloat) {
        let mouth = UIBezierPath()
        mouth.move(to: CGPoint(x: point.x - c.m * width, y: point.y + c.m * 0.01))
        mouth.addQuadCurve(to: CGPoint(x: point.x + c.m * width, y: point.y + c.m * 0.01),
                           controlPoint: CGPoint(x: point.x, y: point.y + c.m * 0.09))
        c.pen.stroke(mouth, ParkPalette.colour(.charcoal), width: c.m * 0.025)
    }
}
