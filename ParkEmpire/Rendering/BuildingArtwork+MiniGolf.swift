import SpriteKit
import UIKit

/// The crazy golf course.
///
/// Drawn as a course rather than as a building: a lawn cut into fairways by
/// low kerbs, with a hole and a flag on each, a hazard or two, and a hut at
/// the front where the putters are handed out. Nothing else in the park is
/// laid out on the ground like this, which is most of what makes it read as
/// golf at a glance rather than as another shed.
extension BuildingArtwork {

    static func drawMiniGolf(_ context: CGContext,
                             _ size: CGSize,
                             _ primary: UIColor,
                             _ secondary: UIColor,
                             _ accent: UIColor) {
        let course = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.05, dy: size.height * 0.05)

        withShadow(context) {
            fill(UIBezierPath(roundedRect: course, cornerRadius: course.height * 0.07), primary)
        }

        // Mown stripes. Fairways are the one place in the park where a flat
        // green would look wrong.
        let stripes = 7
        for index in stride(from: 0, to: stripes, by: 2) {
            let band = CGRect(x: course.minX,
                              y: course.minY + course.height * (CGFloat(index) / CGFloat(stripes)),
                              width: course.width,
                              height: course.height / CGFloat(stripes))
            fill(UIBezierPath(rect: band), UIColor.white.withAlphaComponent(0.07))
        }

        let kerb = ParkPalette.colour(.cream)
        let kerbWidth = max(1, size.width * 0.010)

        // Three fairways of different shapes, divided by low kerbs. Each gets
        // a hole and a flag, so the count of flags is the count of holes.
        let lane = course.width / 3
        for index in 0..<3 {
            let fairway = CGRect(x: course.minX + lane * CGFloat(index),
                                 y: course.minY,
                                 width: lane,
                                 height: course.height)
                .insetBy(dx: lane * 0.10, dy: course.height * 0.07)

            let outline = UIBezierPath(roundedRect: fairway,
                                       cornerRadius: fairway.width * 0.30)
            fill(outline, UIColor.black.withAlphaComponent(0.05))
            stroke(outline, kerb, width: kerbWidth)

            // A dog-leg across the middle of the fairway, which is what makes
            // it a course rather than three rectangles.
            let bend = UIBezierPath()
            bend.move(to: CGPoint(x: fairway.minX + fairway.width * 0.15,
                                  y: fairway.midY + fairway.height * 0.06))
            bend.addLine(to: CGPoint(x: fairway.maxX - fairway.width * 0.15,
                                     y: fairway.midY - fairway.height * 0.04))
            stroke(bend, kerb.withAlphaComponent(0.75), width: kerbWidth)

            drawHole(context,
                     at: CGPoint(x: fairway.midX, y: fairway.minY + fairway.height * 0.18),
                     radius: fairway.width * 0.11,
                     flag: index == 1 ? accent : secondary,
                     height: fairway.height * 0.30)

            // The ball, waiting on the mat at the far end.
            let ball = fairway.width * 0.13
            fill(UIBezierPath(ovalIn: CGRect(x: fairway.midX - ball / 2,
                                             y: fairway.maxY - fairway.height * 0.20,
                                             width: ball, height: ball)),
                 ParkPalette.colour(.white))
        }

        drawWindmill(context,
                     centre: CGPoint(x: course.minX + course.width * 0.18,
                                     y: course.minY + course.height * 0.62),
                     span: course.width * 0.15,
                     body: secondary,
                     sails: ParkPalette.colour(.cream))

        drawPondHazard(context,
                       in: CGRect(x: course.maxX - course.width * 0.26,
                                  y: course.minY + course.height * 0.54,
                                  width: course.width * 0.17,
                                  height: course.height * 0.16))

        drawClubhouse(context,
                      in: CGRect(x: course.midX - course.width * 0.17,
                                 y: course.maxY - course.height * 0.15,
                                 width: course.width * 0.34,
                                 height: course.height * 0.13),
                      body: secondary,
                      roof: accent)
    }

    // MARK: - Pieces

    /// A cup with a flagstick in it. The flag is the tallest thing on the
    /// course and the only part visible when the park is zoomed out.
    private static func drawHole(_ context: CGContext,
                                 at centre: CGPoint,
                                 radius: CGFloat,
                                 flag: UIColor,
                                 height: CGFloat) {
        fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius, y: centre.y - radius * 0.62,
                                         width: radius * 2, height: radius * 1.24)),
             UIColor.black.withAlphaComponent(0.62))

        let stick = UIBezierPath()
        stick.move(to: centre)
        stick.addLine(to: CGPoint(x: centre.x, y: centre.y - height))
        stroke(stick, ParkPalette.colour(.white), width: max(1, radius * 0.42))

        let pennant = UIBezierPath()
        pennant.move(to: CGPoint(x: centre.x, y: centre.y - height))
        pennant.addLine(to: CGPoint(x: centre.x + radius * 1.9, y: centre.y - height * 0.84))
        pennant.addLine(to: CGPoint(x: centre.x, y: centre.y - height * 0.68))
        pennant.close()
        fill(pennant, flag)
    }

    /// The obstacle everybody pictures when they hear crazy golf.
    private static func drawWindmill(_ context: CGContext,
                                     centre: CGPoint,
                                     span: CGFloat,
                                     body: UIColor,
                                     sails: UIColor) {
        let tower = CGRect(x: centre.x - span * 0.26, y: centre.y - span * 0.30,
                           width: span * 0.52, height: span * 0.80)
        fill(UIBezierPath(roundedRect: tower, cornerRadius: tower.width * 0.22), body)

        let cap = UIBezierPath()
        cap.move(to: CGPoint(x: tower.minX - span * 0.08, y: tower.minY))
        cap.addLine(to: CGPoint(x: tower.maxX + span * 0.08, y: tower.minY))
        cap.addLine(to: CGPoint(x: tower.midX, y: tower.minY - span * 0.26))
        cap.close()
        fill(cap, sails)

        // Four sails, drawn as one cross so the shape survives being small.
        let hub = CGPoint(x: tower.midX, y: tower.minY + span * 0.10)
        let arm = span * 0.46
        let blades = UIBezierPath()
        blades.move(to: CGPoint(x: hub.x - arm, y: hub.y - arm * 0.36))
        blades.addLine(to: CGPoint(x: hub.x + arm, y: hub.y + arm * 0.36))
        blades.move(to: CGPoint(x: hub.x - arm * 0.36, y: hub.y + arm))
        blades.addLine(to: CGPoint(x: hub.x + arm * 0.36, y: hub.y - arm))
        stroke(blades, sails, width: max(1, span * 0.13))
        fill(UIBezierPath(ovalIn: CGRect(x: hub.x - span * 0.07, y: hub.y - span * 0.07,
                                         width: span * 0.14, height: span * 0.14)),
             ParkPalette.colour(.charcoal))
    }

    /// A water hazard, which on a course this size is a puddle with a rim.
    private static func drawPondHazard(_ context: CGContext, in rect: CGRect) {
        let pond = UIBezierPath(ovalIn: rect)
        fill(pond, ParkPalette.colour(.cyan).withAlphaComponent(0.85))
        stroke(pond, ParkPalette.colour(.sand), width: max(1, rect.width * 0.10))

        let glint = UIBezierPath()
        glint.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.midY))
        glint.addLine(to: CGPoint(x: rect.minX + rect.width * 0.52, y: rect.midY))
        stroke(glint, UIColor.white.withAlphaComponent(0.55), width: max(0.5, rect.height * 0.10))
    }

    /// Where the putters are handed out, at the front so it faces the path.
    private static func drawClubhouse(_ context: CGContext,
                                      in rect: CGRect,
                                      body: UIColor,
                                      roof: UIColor) {
        withShadow(context) {
            fill(UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.25), body)
        }
        let awning = CGRect(x: rect.minX, y: rect.minY,
                            width: rect.width, height: rect.height * 0.42)
        fill(UIBezierPath(roundedRect: awning, cornerRadius: awning.height * 0.4), roof)

        // A rack of putters leaning against the counter.
        let clubs = UIBezierPath()
        for index in 0..<3 {
            let x = rect.minX + rect.width * (0.24 + 0.22 * CGFloat(index))
            clubs.move(to: CGPoint(x: x, y: rect.maxY - rect.height * 0.10))
            clubs.addLine(to: CGPoint(x: x + rect.width * 0.05, y: rect.minY + rect.height * 0.50))
        }
        stroke(clubs, ParkPalette.colour(.charcoal).withAlphaComponent(0.7),
               width: max(0.5, rect.height * 0.08))
    }
}
