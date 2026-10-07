import SpriteKit
import UIKit

/// The two newest guest amenities: a washroom with marble and attendants, and
/// a cart that sells popcorn.
extension BuildingArtwork {

    // MARK: - Luxury washroom

    /// A small marble hall: gold roof band, columns, and a tall arched door
    /// between two ordinary ones. Wider than the plain restroom, and dressed up
    /// enough that nobody mistakes the two at a glance.
    static func drawLuxuryRestroom(_ context: CGContext,
                                   _ size: CGSize,
                                   _ primary: UIColor,
                                   _ secondary: UIColor,
                                   _ accent: UIColor) {
        let body = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.05, dy: size.height * 0.10)
        let outline = UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.10)

        withShadow(context) { fill(outline, primary) }

        // Gold roof band, clipped to the building so it follows the corners.
        context.saveGState()
        outline.addClip()
        let band = CGRect(x: body.minX, y: body.minY,
                          width: body.width, height: body.height * 0.22)
        fill(UIBezierPath(rect: band), secondary)
        let rule = CGRect(x: body.minX, y: band.maxY,
                          width: body.width, height: body.height * 0.035)
        fill(UIBezierPath(rect: rule), secondary.withAlphaComponent(0.7))
        context.restoreGState()

        // Columns either side of the middle, in pale stone.
        let columnWidth = body.width * 0.05
        let columnTop = band.maxY + body.height * 0.05
        let columnHeight = body.maxY - columnTop - body.height * 0.05
        for fraction in [0.31, 0.69] as [CGFloat] {
            let column = CGRect(x: body.minX + body.width * fraction - columnWidth / 2,
                                y: columnTop, width: columnWidth, height: columnHeight)
            fill(UIBezierPath(roundedRect: column, cornerRadius: columnWidth * 0.4),
                 secondary.withAlphaComponent(0.85))
        }

        // The tall arched door in the middle, framed in gold.
        let doorWidth = body.width * 0.20
        let door = CGRect(x: body.midX - doorWidth / 2,
                          y: columnTop,
                          width: doorWidth,
                          height: columnHeight)
        let arch = CGSize(width: doorWidth / 2, height: doorWidth / 2)
        let frame = door.insetBy(dx: -doorWidth * 0.08, dy: -doorWidth * 0.08)
        fill(UIBezierPath(roundedRect: frame,
                          byRoundingCorners: [.topLeft, .topRight],
                          cornerRadii: arch), secondary)
        fill(UIBezierPath(roundedRect: door,
                          byRoundingCorners: [.topLeft, .topRight],
                          cornerRadii: arch), accent)

        // An ordinary door at each end.
        let sideWidth = body.width * 0.13
        for fraction in [0.14, 0.86] as [CGFloat] {
            let side = CGRect(x: body.minX + body.width * fraction - sideWidth / 2,
                              y: columnTop + columnHeight * 0.22,
                              width: sideWidth, height: columnHeight * 0.78)
            fill(UIBezierPath(roundedRect: side, cornerRadius: sideWidth * 0.25), accent)
        }

        // Planters flanking the entrance.
        let planter = body.height * 0.13
        for fraction in [0.43, 0.57] as [CGFloat] {
            let spot = CGRect(x: body.minX + body.width * fraction - planter / 2,
                              y: body.maxY - planter * 0.9,
                              width: planter, height: planter)
            fill(UIBezierPath(ovalIn: spot), ParkPalette.colour(.green))
        }
    }

    // MARK: - Popcorn cart

    /// A striped awning over a glass case of popcorn, on two wheels.
    static func drawPopcornCart(_ context: CGContext,
                                _ size: CGSize,
                                _ primary: UIColor,
                                _ secondary: UIColor,
                                _ accent: UIColor) {
        let wheel = size.width * 0.17
        for fraction in [0.28, 0.72] as [CGFloat] {
            let rim = CGRect(x: size.width * fraction - wheel / 2,
                             y: size.height * 0.80, width: wheel, height: wheel)
            fill(UIBezierPath(ovalIn: rim), ParkPalette.colour(.charcoal))
        }

        // The cart itself.
        let cart = CGRect(x: size.width * 0.14, y: size.height * 0.52,
                          width: size.width * 0.72, height: size.height * 0.32)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: cart, cornerRadius: cart.height * 0.2), primary)
        }

        // The glass case, with the popcorn heaped in it.
        let glass = CGRect(x: size.width * 0.20, y: size.height * 0.28,
                           width: size.width * 0.60, height: size.height * 0.26)
        fill(UIBezierPath(roundedRect: glass, cornerRadius: glass.height * 0.15),
             UIColor.white.withAlphaComponent(0.78))
        let puff = glass.height * 0.46
        for index in 0..<5 {
            let x = glass.minX + glass.width * (0.12 + 0.19 * CGFloat(index))
            let y = glass.minY + glass.height * (index % 2 == 0 ? 0.08 : 0.22)
            let kernel = CGRect(x: x - puff / 2, y: y, width: puff, height: puff)
            fill(UIBezierPath(ovalIn: kernel), index % 2 == 0 ? secondary : accent)
        }

        // The awning, in stripes, wider than the cart.
        let awning = UIBezierPath()
        awning.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.30))
        awning.addLine(to: CGPoint(x: size.width * 0.20, y: size.height * 0.08))
        awning.addLine(to: CGPoint(x: size.width * 0.80, y: size.height * 0.08))
        awning.addLine(to: CGPoint(x: size.width * 0.92, y: size.height * 0.30))
        awning.close()

        context.saveGState()
        awning.addClip()
        let stripes = 6
        let stripeWidth = size.width * 0.84 / CGFloat(stripes)
        for index in 0..<stripes {
            let stripe = CGRect(x: size.width * 0.08 + stripeWidth * CGFloat(index),
                                y: size.height * 0.06,
                                width: stripeWidth, height: size.height * 0.26)
            fill(UIBezierPath(rect: stripe), index % 2 == 0 ? primary : secondary)
        }
        context.restoreGState()
    }
}
