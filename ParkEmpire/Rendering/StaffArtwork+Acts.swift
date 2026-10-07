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

    /// Three balls in an arc over the hands.
    static func drawJugglingBalls(layout: PersonArtwork.Layout) {
        let unit = layout.body.width
        let colours: [ParkColour] = [.red, .yellow, .blue]
        let spots: [(CGFloat, CGFloat)] = [(-0.34, 0.20), (0.0, 0.70), (0.38, 0.28)]

        for (index, spot) in spots.enumerated() {
            let centre = CGPoint(x: layout.body.midX + unit * spot.0,
                                 y: layout.body.minY - unit * spot.1)
            let side = unit * 0.34
            ParkPalette.colour(colours[index]).setFill()
            UIBezierPath(ovalIn: CGRect(x: centre.x - side / 2, y: centre.y - side / 2,
                                        width: side, height: side)).fill()
            UIColor.white.withAlphaComponent(0.55).setFill()
            UIBezierPath(ovalIn: CGRect(x: centre.x - side * 0.28, y: centre.y - side * 0.30,
                                        width: side * 0.22, height: side * 0.22)).fill()
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
