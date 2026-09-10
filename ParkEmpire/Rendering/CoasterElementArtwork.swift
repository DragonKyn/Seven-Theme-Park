import SpriteKit
import UIKit

/// Draws the coaster elements: the loops, corkscrews and jumps that sit on
/// track the player has laid.
///
/// These are drawn across their whole footprint rather than tile by tile,
/// which is the entire point of them. A vertical loop across three tiles can
/// be a loop; a vertical loop inside one tile is a doodle.
enum CoasterElementArtwork {

    static func texture(for motif: CoasterElementMotif, size: CGSize) -> SKTexture {
        SpriteFactory.texture(key: "element-\(motif.rawValue)-\(Int(size.width))x\(Int(size.height))",
                              size: size) { context, size in
            switch motif {
            case .verticalLoop: drawVerticalLoop(context, size)
            case .corkscrew: drawCorkscrew(context, size)
            case .airtimeHills: drawAirtimeHills(context, size)
            case .jump: drawJump(context, size)
            case .helixTower: drawHelixTower(context, size)
            }
        }
    }

    /// The same image for the build menu, so what you pick is what you get.
    static func previewImage(for motif: CoasterElementMotif, size: CGSize) -> UIImage {
        if let cached = previews["\(motif.rawValue)-\(Int(size.width))"] { return cached }
        let image = UIGraphicsImageRenderer(size: size).image { rendererContext in
            switch motif {
            case .verticalLoop: drawVerticalLoop(rendererContext.cgContext, size)
            case .corkscrew: drawCorkscrew(rendererContext.cgContext, size)
            case .airtimeHills: drawAirtimeHills(rendererContext.cgContext, size)
            case .jump: drawJump(rendererContext.cgContext, size)
            case .helixTower: drawHelixTower(rendererContext.cgContext, size)
            }
        }
        previews["\(motif.rawValue)-\(Int(size.width))"] = image
        return image
    }

    private static var previews: [String: UIImage] = [:]

    // MARK: - Drawing helpers

    /// Track is always drawn twice: a dark tie bed, then the rail on top. It
    /// is what makes a stroked line read as track rather than as a pen mark.
    private static func layTrack(_ path: UIBezierPath, _ size: CGSize, weight: CGFloat = 1) {
        ParkPalette.coasterTie.setStroke()
        path.lineWidth = max(2.5, size.height * 0.17 * weight)
        path.lineCapStyle = .round
        path.stroke()

        ParkPalette.coasterRail.setStroke()
        path.lineWidth = max(1, size.height * 0.075 * weight)
        path.stroke()
    }

    /// Uprights down to the ground under a raised piece.
    private static func supports(_ points: [CGPoint], _ size: CGSize) {
        let deck = size.height * 0.94
        let legs = UIBezierPath()
        for point in points where point.y < deck - 3 {
            legs.move(to: point)
            legs.addLine(to: CGPoint(x: point.x, y: deck))
        }
        ParkPalette.colour(.slate).withAlphaComponent(0.55).setStroke()
        legs.lineWidth = max(1, size.width * 0.010)
        legs.stroke()
    }

    // MARK: - Elements

    /// A full vertical loop: in along the bottom, up and over, and out the
    /// far side. The crossing in the middle is what says loop.
    private static func drawVerticalLoop(_ context: CGContext, _ size: CGSize) {
        let baseline = size.height * 0.82
        let centre = CGPoint(x: size.width * 0.5, y: size.height * 0.44)
        let radius = min(size.width * 0.30, size.height * 0.36)

        supports([CGPoint(x: size.width * 0.30, y: baseline - radius * 0.2),
                  CGPoint(x: size.width * 0.70, y: baseline - radius * 0.2)], size)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: baseline))
        path.addLine(to: CGPoint(x: size.width * 0.34, y: baseline))
        // Round the loop, entered and left at its foot travelling the same way.
        let steps = 40
        for step in 0...steps {
            let angle = CGFloat.pi / 2 - CGFloat(step) / CGFloat(steps) * .pi * 2
            path.addLine(to: CGPoint(x: centre.x + cos(angle) * radius,
                                     y: centre.y + sin(angle) * radius))
        }
        path.addLine(to: CGPoint(x: size.width * 0.66, y: baseline))
        path.addLine(to: CGPoint(x: size.width, y: baseline))
        layTrack(path, size)
    }

    /// Two barrel rolls: a pair of flattened rings strung along the run, with
    /// the track threading through both.
    private static func drawCorkscrew(_ context: CGContext, _ size: CGSize) {
        let baseline = size.height * 0.78
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: baseline))

        let radiusX = size.width * 0.13
        let radiusY = size.height * 0.30
        for index in 0..<2 {
            let centre = CGPoint(x: size.width * (0.31 + 0.34 * CGFloat(index)),
                                 y: size.height * 0.46)
            path.addLine(to: CGPoint(x: centre.x - radiusX, y: baseline))
            let steps = 30
            for step in 0...steps {
                let angle = CGFloat.pi - CGFloat(step) / CGFloat(steps) * .pi * 2
                path.addLine(to: CGPoint(x: centre.x + cos(angle) * radiusX,
                                         y: centre.y + sin(angle) * radiusY))
            }
            path.addLine(to: CGPoint(x: centre.x + radiusX, y: baseline))
        }
        path.addLine(to: CGPoint(x: size.width, y: baseline))

        supports([CGPoint(x: size.width * 0.18, y: baseline - size.height * 0.1),
                  CGPoint(x: size.width * 0.50, y: baseline - size.height * 0.1),
                  CGPoint(x: size.width * 0.82, y: baseline - size.height * 0.1)], size)
        layTrack(path, size)
    }

    /// A run of humps. Nothing clever, and every circuit wants some.
    private static func drawAirtimeHills(_ context: CGContext, _ size: CGSize) {
        let baseline = size.height * 0.76
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: baseline))

        let humps = 3
        var crests: [CGPoint] = []
        for index in 0..<humps {
            let from = size.width * CGFloat(index) / CGFloat(humps)
            let to = size.width * CGFloat(index + 1) / CGFloat(humps)
            let crest = CGPoint(x: (from + to) / 2, y: size.height * 0.26)
            crests.append(crest)
            path.addQuadCurve(to: CGPoint(x: to, y: baseline),
                              controlPoint: CGPoint(x: crest.x, y: size.height * 0.02))
        }

        supports(crests.map { CGPoint(x: $0.x, y: baseline - size.height * 0.12) }, size)
        layTrack(path, size)
    }

    /// A ramp, a gap, and a ramp, with the arc the train takes marked over it.
    private static func drawJump(_ context: CGContext, _ size: CGSize) {
        let baseline = size.height * 0.80

        let approach = UIBezierPath()
        approach.move(to: CGPoint(x: 0, y: baseline))
        approach.addLine(to: CGPoint(x: size.width * 0.22, y: baseline))
        approach.addQuadCurve(to: CGPoint(x: size.width * 0.36, y: size.height * 0.50),
                              controlPoint: CGPoint(x: size.width * 0.32, y: baseline))

        let landing = UIBezierPath()
        landing.move(to: CGPoint(x: size.width, y: baseline))
        landing.addLine(to: CGPoint(x: size.width * 0.78, y: baseline))
        landing.addQuadCurve(to: CGPoint(x: size.width * 0.64, y: size.height * 0.50),
                             controlPoint: CGPoint(x: size.width * 0.68, y: baseline))

        supports([CGPoint(x: size.width * 0.30, y: size.height * 0.58),
                  CGPoint(x: size.width * 0.70, y: size.height * 0.58)], size)
        layTrack(approach, size)
        layTrack(landing, size)

        // The flight path, dashed, because there is nothing under it.
        let flight = UIBezierPath()
        flight.move(to: CGPoint(x: size.width * 0.36, y: size.height * 0.50))
        flight.addQuadCurve(to: CGPoint(x: size.width * 0.64, y: size.height * 0.50),
                            controlPoint: CGPoint(x: size.width * 0.50, y: size.height * 0.10))
        flight.setLineDash([size.width * 0.03, size.width * 0.025], count: 2, phase: 0)
        flight.lineWidth = max(1, size.height * 0.045)
        ParkPalette.coasterRail.withAlphaComponent(0.75).setStroke()
        flight.stroke()

        // Hazard marks in the gap.
        ParkPalette.coasterRail.withAlphaComponent(0.4).setFill()
        for index in 0..<3 {
            let mark = CGRect(x: size.width * (0.42 + 0.07 * CGFloat(index)),
                              y: baseline + size.height * 0.04,
                              width: size.width * 0.04,
                              height: size.height * 0.10)
            UIBezierPath(rect: mark).fill()
        }
    }

    /// A descending spiral, drawn as three rings of shrinking radius so the
    /// track reads as going down as well as round.
    private static func drawHelixTower(_ context: CGContext, _ size: CGSize) {
        let centre = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: size.height * 0.5))

        let turns = 3
        let steps = 100
        let outer = min(size.width, size.height) * 0.40
        for step in 0...steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let angle = .pi + progress * .pi * 2 * CGFloat(turns)
            let radius = outer * (1 - progress * 0.55)
            path.addLine(to: CGPoint(x: centre.x + cos(angle) * radius,
                                     y: centre.y + sin(angle) * radius * 0.72))
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height * 0.5))

        supports([CGPoint(x: centre.x, y: centre.y)], size)
        layTrack(path, size, weight: 0.8)
    }
}
