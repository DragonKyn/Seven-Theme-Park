import UIKit

/// The two holiday performers. Both are the ordinary entertainer figure with
/// the costume drawn over it, the way the other acts are.
extension StaffArtwork {

    /// Santa: a white band on the red hat, a full white beard, and a black belt
    /// with a gold buckle.
    static func drawSantaExtras(layout: PersonArtwork.Layout) {
        let head = layout.head
        let body = layout.body
        let white = UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1)

        // Fur band where the hat meets the head.
        let band = CGRect(x: head.minX - head.width * 0.04, y: head.minY + head.height * 0.10,
                          width: head.width * 1.08, height: head.height * 0.20)
        white.setFill()
        UIBezierPath(roundedRect: band, cornerRadius: band.height * 0.5).fill()

        // Beard: a rounded shape over the lower half of the face, with a moustache.
        let beard = UIBezierPath()
        beard.move(to: CGPoint(x: head.minX + head.width * 0.02, y: head.midY - head.height * 0.04))
        beard.addQuadCurve(to: CGPoint(x: head.midX, y: head.maxY + head.height * 0.26),
                           controlPoint: CGPoint(x: head.minX - head.width * 0.04, y: head.maxY + head.height * 0.20))
        beard.addQuadCurve(to: CGPoint(x: head.maxX - head.width * 0.02, y: head.midY - head.height * 0.04),
                           controlPoint: CGPoint(x: head.maxX + head.width * 0.04, y: head.maxY + head.height * 0.20))
        beard.addQuadCurve(to: CGPoint(x: head.minX + head.width * 0.02, y: head.midY - head.height * 0.04),
                           controlPoint: CGPoint(x: head.midX, y: head.midY + head.height * 0.10))
        beard.close()
        white.setFill()
        beard.fill()

        // A touch of rosy cheek above it.
        UIColor(red: 0.95, green: 0.55, blue: 0.52, alpha: 0.7).setFill()
        for side in [CGFloat(-1), CGFloat(1)] {
            let r = head.width * 0.10
            UIBezierPath(ovalIn: CGRect(x: head.midX + side * head.width * 0.26 - r, y: head.midY - head.height * 0.08,
                                        width: r * 2, height: r * 1.4)).fill()
        }

        // Belt and buckle.
        let belt = CGRect(x: body.minX, y: body.midY + body.height * 0.06, width: body.width, height: body.height * 0.16)
        ParkPalette.colour(.charcoal).setFill()
        UIBezierPath(rect: belt).fill()
        let buckle = CGRect(x: body.midX - belt.height * 0.55, y: belt.minY - belt.height * 0.05,
                            width: belt.height * 1.1, height: belt.height * 1.1)
        UIColor(red: 1.0, green: 0.82, blue: 0.28, alpha: 1).setFill()
        UIBezierPath(rect: buckle).fill()

        // White trim down the front of the coat.
        white.setFill()
        UIBezierPath(rect: CGRect(x: body.midX - body.width * 0.05, y: body.minY, width: body.width * 0.10,
                                  height: belt.minY - body.minY)).fill()
    }

    /// Mrs. Claus: white hair in a bun with a red bow, small round glasses, a
    /// white apron over the green dress, and a tray of cookies.
    static func drawMrsClausExtras(layout: PersonArtwork.Layout) {
        let head = layout.head
        let body = layout.body
        let white = UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1)

        // The bun on top of the head, with a bow at its base.
        let bun = head.width * 0.40
        white.setFill()
        UIBezierPath(ovalIn: CGRect(x: head.midX - bun / 2, y: head.minY - bun * 0.62, width: bun, height: bun)).fill()
        let red = UIColor(red: 0.86, green: 0.16, blue: 0.20, alpha: 1)
        red.setFill()
        for side in [CGFloat(-1), CGFloat(1)] {
            UIBezierPath(ovalIn: CGRect(x: head.midX + side * bun * 0.30 - bun * 0.20, y: head.minY - bun * 0.08,
                                        width: bun * 0.40, height: bun * 0.26)).fill()
        }

        // Round glasses.
        UIColor(white: 0.2, alpha: 1).setStroke()
        for side in [CGFloat(-1), CGFloat(1)] {
            let r = head.width * 0.14
            let lens = UIBezierPath(ovalIn: CGRect(x: head.midX + side * head.width * 0.20 - r, y: head.midY - r * 0.9,
                                                   width: r * 2, height: r * 2))
            lens.lineWidth = max(0.6, head.width * 0.03)
            lens.stroke()
        }

        // Apron, white with a red trim, over the body.
        let apron = CGRect(x: body.minX + body.width * 0.12, y: body.minY + body.height * 0.12,
                           width: body.width * 0.76, height: body.height * 0.88)
        white.setFill()
        UIBezierPath(roundedRect: apron, cornerRadius: apron.width * 0.14).fill()
        red.setFill()
        UIBezierPath(rect: CGRect(x: apron.minX, y: apron.minY, width: apron.width, height: apron.height * 0.10)).fill()

        // A tray of cookies held out to the side.
        let tray = CGRect(x: body.maxX - body.width * 0.05, y: body.midY, width: body.width * 0.62, height: body.width * 0.12)
        UIColor(red: 0.74, green: 0.76, blue: 0.80, alpha: 1).setFill()
        UIBezierPath(roundedRect: tray, cornerRadius: tray.height * 0.4).fill()
        UIColor(red: 0.74, green: 0.46, blue: 0.22, alpha: 1).setFill()
        for index in 0..<3 {
            let r = tray.height * 0.9
            UIBezierPath(ovalIn: CGRect(x: tray.minX + tray.width * (0.12 + 0.28 * CGFloat(index)), y: tray.minY - r * 0.8,
                                        width: r, height: r)).fill()
        }
    }
}
