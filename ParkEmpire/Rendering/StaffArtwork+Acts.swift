import SpriteKit
import UIKit

/// The props that make each kind of entertainer recognisable.
///
/// Like every employee, an entertainer is told apart by what is on their head
/// and what is in their hands, so each act has one of each: the balloon
/// artist a cap and a bunch of balloons, the mime a beret and a painted face,
/// the juggler a jester's hat and three balls in the air, the magician a top
/// hat, a cape and a wand.
extension StaffArtwork {

    /// A red megaphone held up and out to one side, with the sound coming out of
    /// it. Something that reads at a glance at this size: a cone, a bright
    /// colour, and a few arcs in front of it.
    static func drawMegaphone(layout: PersonArtwork.Layout) {
        let unit = layout.body.width
        let grip = CGPoint(x: layout.body.maxX + unit * 0.10,
                           y: layout.body.minY + layout.body.height * 0.48)
        let run = unit * 0.62
        let rise = -unit * 0.50
        let length = (run * run + rise * rise).squareRoot()
        let direction = CGPoint(x: run / length, y: rise / length)
        let across = CGPoint(x: -direction.y, y: direction.x)
        let mouth = CGPoint(x: grip.x + run, y: grip.y + rise)

        let narrow = unit * 0.07
        let wide = unit * 0.25
        let cone = UIBezierPath()
        cone.move(to: CGPoint(x: grip.x + across.x * narrow, y: grip.y + across.y * narrow))
        cone.addLine(to: CGPoint(x: mouth.x + across.x * wide, y: mouth.y + across.y * wide))
        cone.addLine(to: CGPoint(x: mouth.x - across.x * wide, y: mouth.y - across.y * wide))
        cone.addLine(to: CGPoint(x: grip.x - across.x * narrow, y: grip.y - across.y * narrow))
        cone.close()
        ParkPalette.colour(.red).setFill()
        cone.fill()
        UIColor.black.withAlphaComponent(0.32).setStroke()
        cone.lineWidth = max(0.6, unit * 0.05)
        cone.stroke()

        // A white band near the wide end.
        let bandAt = CGPoint(x: mouth.x - direction.x * unit * 0.16, y: mouth.y - direction.y * unit * 0.16)
        let band = UIBezierPath()
        band.move(to: CGPoint(x: bandAt.x + across.x * wide * 0.80, y: bandAt.y + across.y * wide * 0.80))
        band.addLine(to: CGPoint(x: bandAt.x - across.x * wide * 0.80, y: bandAt.y - across.y * wide * 0.80))
        UIColor.white.setStroke()
        band.lineWidth = max(1, unit * 0.10)
        band.stroke()

        // The opening, seen end on.
        let opening = UIBezierPath(ovalIn: CGRect(x: -wide, y: -unit * 0.07,
                                                  width: wide * 2, height: unit * 0.14))
        opening.apply(CGAffineTransform(rotationAngle: atan2(across.y, across.x)))
        opening.apply(CGAffineTransform(translationX: mouth.x, y: mouth.y))
        ParkPalette.colour(.charcoal).setFill()
        opening.fill()

        // The handle in the hand.
        let handle = UIBezierPath(ovalIn: CGRect(x: grip.x - unit * 0.08, y: grip.y - unit * 0.08,
                                                 width: unit * 0.16, height: unit * 0.16))
        ParkPalette.colour(.charcoal).setFill()
        handle.fill()

        // Sound, as two arcs coming off the mouth.
        let heading = atan2(direction.y, direction.x)
        let centre = CGPoint(x: mouth.x + direction.x * unit * 0.06, y: mouth.y + direction.y * unit * 0.06)
        UIColor.white.withAlphaComponent(0.9).setStroke()
        for radius in [unit * 0.26, unit * 0.42] {
            let arc = UIBezierPath(arcCenter: centre, radius: radius,
                                   startAngle: heading - 0.55, endAngle: heading + 0.55,
                                   clockwise: true)
            arc.lineCapStyle = .round
            arc.lineWidth = max(0.8, unit * 0.06)
            arc.stroke()
        }
    }

    /// A ruff of white scallops round the neck, which is most of what makes a
    /// clown a clown from a distance.
    static func drawClownCollar(layout: PersonArtwork.Layout) {
        let unit = layout.body.width
        let diameter = unit * 0.26
        for step in -2...2 {
            let x = layout.body.midX + CGFloat(step) * unit * 0.17
            let y = layout.body.minY + unit * 0.02 + CGFloat(abs(step)) * unit * 0.025
            let rect = CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: rect).fill()
            UIColor.black.withAlphaComponent(0.25).setStroke()
            let outline = UIBezierPath(ovalIn: rect)
            outline.lineWidth = max(0.5, unit * 0.04)
            outline.stroke()
        }
    }

    /// A squeaky horn: a black rubber bulb and a gold bell.
    static func drawHorn(layout: PersonArtwork.Layout) {
        let unit = layout.body.width
        let grip = CGPoint(x: layout.body.maxX + unit * 0.08, y: layout.body.midY + unit * 0.12)
        let tip = CGPoint(x: grip.x + unit * 0.52, y: grip.y - unit * 0.20)

        let bell = UIBezierPath()
        bell.move(to: CGPoint(x: grip.x, y: grip.y - unit * 0.06))
        bell.addLine(to: CGPoint(x: tip.x, y: tip.y - unit * 0.22))
        bell.addLine(to: CGPoint(x: tip.x, y: tip.y + unit * 0.22))
        bell.addLine(to: CGPoint(x: grip.x, y: grip.y + unit * 0.06))
        bell.close()
        ParkPalette.colour(.amber).setFill()
        bell.fill()
        UIColor.black.withAlphaComponent(0.32).setStroke()
        bell.lineWidth = max(0.6, unit * 0.05)
        bell.stroke()

        let bulb = CGRect(x: grip.x - unit * 0.17, y: grip.y - unit * 0.12,
                          width: unit * 0.26, height: unit * 0.24)
        ParkPalette.colour(.charcoal).setFill()
        UIBezierPath(ovalIn: bulb).fill()
    }

    /// A bunch of balloons in four colours on strings, held up off the shoulder.
    static func drawBalloonBunch(layout: PersonArtwork.Layout) {
        let unit = layout.body.width
        let anchor = CGPoint(x: layout.body.maxX + unit * 0.06, y: layout.body.midY)
        let bunch: [(dx: CGFloat, dy: CGFloat, colour: ParkColour)] = [
            (0.22, 0.78, .red),
            (0.52, 0.52, .yellow),
            (0.20, 0.36, .green),
            (0.56, 0.96, .blue)
        ]

        for balloon in bunch {
            let centre = CGPoint(x: anchor.x + unit * balloon.dx,
                                 y: layout.head.minY - unit * (balloon.dy - 0.30))

            let string = UIBezierPath()
            string.move(to: anchor)
            string.addQuadCurve(to: centre,
                                controlPoint: CGPoint(x: anchor.x + unit * balloon.dx * 0.2,
                                                      y: centre.y + unit * 0.2))
            UIColor.white.withAlphaComponent(0.8).setStroke()
            string.lineWidth = max(0.5, unit * 0.04)
            string.stroke()

            let side = unit * 0.46
            let rect = CGRect(x: centre.x - side / 2, y: centre.y - side * 0.58,
                              width: side, height: side * 1.16)
            ParkPalette.colour(balloon.colour).setFill()
            UIBezierPath(ovalIn: rect).fill()
            UIColor.white.withAlphaComponent(0.55).setFill()
            UIBezierPath(ovalIn: CGRect(x: rect.minX + side * 0.18, y: rect.minY + side * 0.14,
                                        width: side * 0.16, height: side * 0.22)).fill()
        }
    }

    /// A short black wand with a white tip, held out to the side, and a spark
    /// of gold where the magic comes out.
    static func drawWand(layout: PersonArtwork.Layout) {
        let unit = layout.body.width
        let grip = CGPoint(x: layout.body.maxX + unit * 0.04, y: layout.body.midY + unit * 0.10)
        let tip = CGPoint(x: layout.body.maxX + unit * 0.62, y: layout.body.minY - unit * 0.06)

        let wand = UIBezierPath()
        wand.move(to: grip)
        wand.addLine(to: tip)
        wand.lineCapStyle = .round
        ParkPalette.colour(.charcoal).setStroke()
        wand.lineWidth = max(1, unit * 0.12)
        wand.stroke()

        let end = UIBezierPath()
        end.move(to: CGPoint(x: tip.x - (tip.x - grip.x) * 0.16, y: tip.y - (tip.y - grip.y) * 0.16))
        end.addLine(to: tip)
        end.lineCapStyle = .round
        UIColor.white.setStroke()
        end.lineWidth = max(1, unit * 0.12)
        end.stroke()

        // A four-pointed spark.
        let spark = UIBezierPath()
        let reach = unit * 0.26
        let waist = unit * 0.06
        let centre = CGPoint(x: tip.x + unit * 0.06, y: tip.y - unit * 0.10)
        spark.move(to: CGPoint(x: centre.x, y: centre.y - reach))
        spark.addLine(to: CGPoint(x: centre.x + waist, y: centre.y - waist))
        spark.addLine(to: CGPoint(x: centre.x + reach, y: centre.y))
        spark.addLine(to: CGPoint(x: centre.x + waist, y: centre.y + waist))
        spark.addLine(to: CGPoint(x: centre.x, y: centre.y + reach))
        spark.addLine(to: CGPoint(x: centre.x - waist, y: centre.y + waist))
        spark.addLine(to: CGPoint(x: centre.x - reach, y: centre.y))
        spark.addLine(to: CGPoint(x: centre.x - waist, y: centre.y - waist))
        spark.close()
        ParkPalette.colour(.yellow).setFill()
        spark.fill()
    }

    /// The cape, drawn before the figure so it hangs behind the shoulders and
    /// shows either side of the body. Placed with the same proportions the
    /// figure is drawn to, since the figure has not been drawn yet.
    static func drawCapeBehind(colour: UIColor, size: CGSize, figureScale: CGFloat) {
        let figure = size.height * figureScale
        let centreX = size.width / 2
        let bottom = size.height - (size.height - figure) * 0.20
        let top = bottom - figure * 0.58
        let hem = bottom - figure * 0.06

        let cape = UIBezierPath()
        cape.move(to: CGPoint(x: centreX - figure * 0.20, y: top))
        cape.addLine(to: CGPoint(x: centreX + figure * 0.20, y: top))
        cape.addQuadCurve(to: CGPoint(x: centreX + figure * 0.40, y: hem),
                          controlPoint: CGPoint(x: centreX + figure * 0.34, y: top + figure * 0.20))
        cape.addQuadCurve(to: CGPoint(x: centreX - figure * 0.40, y: hem),
                          controlPoint: CGPoint(x: centreX, y: hem + figure * 0.04))
        cape.addQuadCurve(to: CGPoint(x: centreX - figure * 0.20, y: top),
                          controlPoint: CGPoint(x: centreX - figure * 0.34, y: top + figure * 0.20))
        cape.close()

        colour.setFill()
        cape.fill()
        UIColor.black.withAlphaComponent(0.32).setStroke()
        cape.lineWidth = max(1, figure * 0.03)
        cape.stroke()

        // A pale lining just showing at the hem.
        let lining = UIBezierPath()
        lining.move(to: CGPoint(x: centreX - figure * 0.38, y: hem - figure * 0.01))
        lining.addQuadCurve(to: CGPoint(x: centreX + figure * 0.38, y: hem - figure * 0.01),
                            controlPoint: CGPoint(x: centreX, y: hem + figure * 0.03))
        UIColor.white.withAlphaComponent(0.6).setStroke()
        lining.lineWidth = max(1, figure * 0.025)
        lining.stroke()
    }
}
