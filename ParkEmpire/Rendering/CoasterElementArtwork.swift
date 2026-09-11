import SpriteKit
import UIKit

/// Draws the coaster elements, and hands out the exact line a train should
/// follow through one.
///
/// The drawing and the path are the same list of points. That is the whole
/// point of this file: before, an element was a picture of a loop painted over
/// track the train drove straight through, which is why they felt like
/// decoration rather than ride.
///
/// An element is drawn taller than the ground it occupies. A loop across three
/// tiles of track needs height to be a loop, so the sprite reaches up out of
/// its footprint and the track line runs along the bottom of it.
enum CoasterElementArtwork {

    /// Where the track runs through a drawing, as a share of its height. The
    /// footprint sits at the bottom; everything above it is the element.
    static func trackLine(footprintHeight: Int, visualHeight: Int) -> CGFloat {
        let visual = CGFloat(max(visualHeight, 1))
        return (visual - CGFloat(footprintHeight) / 2) / visual
    }

    // MARK: - The line

    /// The centreline of an element, in texture space, entering at the left
    /// edge and leaving at the right edge on the track line.
    static func centreline(for motif: CoasterElementMotif,
                           size: CGSize,
                           trackY: CGFloat) -> [CGPoint] {
        let line = size.height * trackY
        switch motif {
        case .airtimeHills: return hills(size, line)
        case .verticalLoop: return loop(size, line)
        case .corkscrew: return corkscrew(size, line)
        case .jump: return jump(size, line)
        case .helixTower: return helix(size, line)
        }
    }

    private static func hills(_ size: CGSize, _ line: CGFloat) -> [CGPoint] {
        var points = [CGPoint(x: 0, y: line)]
        let humps = 3
        let rise = min(line - size.height * 0.08, size.height * 0.44)
        for index in 0..<humps {
            let from = size.width * CGFloat(index) / CGFloat(humps)
            let to = size.width * CGFloat(index + 1) / CGFloat(humps)
            points += quad(from: CGPoint(x: from, y: line),
                           control: CGPoint(x: (from + to) / 2, y: line - rise * 2),
                           to: CGPoint(x: to, y: line),
                           steps: 12)
        }
        return points
    }

    private static func loop(_ size: CGSize, _ line: CGFloat) -> [CGPoint] {
        let radius = min(size.width * 0.34, (line - size.height * 0.08) / 2)
        let centre = CGPoint(x: size.width / 2, y: line - radius)

        var points = [CGPoint(x: 0, y: line),
                      CGPoint(x: centre.x - radius * 0.9, y: line)]
        // Entered and left at the foot, travelling the same way both times, so
        // the train goes up the far side first the way a real loop is run.
        let steps = 44
        for step in 0...steps {
            let angle = CGFloat.pi / 2 - CGFloat(step) / CGFloat(steps) * .pi * 2
            points.append(CGPoint(x: centre.x + cos(angle) * radius,
                                  y: centre.y + sin(angle) * radius))
        }
        points.append(CGPoint(x: centre.x + radius * 0.9, y: line))
        points.append(CGPoint(x: size.width, y: line))
        return points
    }

    private static func corkscrew(_ size: CGSize, _ line: CGFloat) -> [CGPoint] {
        let radiusX = size.width * 0.12
        let radiusY = min(size.width * 0.12, (line - size.height * 0.10) / 2)
        var points = [CGPoint(x: 0, y: line)]

        for index in 0..<2 {
            let centre = CGPoint(x: size.width * (0.30 + 0.38 * CGFloat(index)),
                                 y: line - radiusY)
            points.append(CGPoint(x: centre.x - radiusX, y: line))
            let steps = 30
            for step in 0...steps {
                let angle = CGFloat.pi - CGFloat(step) / CGFloat(steps) * .pi * 2
                points.append(CGPoint(x: centre.x + cos(angle) * radiusX,
                                      y: centre.y + sin(angle) * radiusY))
            }
            points.append(CGPoint(x: centre.x + radiusX, y: line))
        }
        points.append(CGPoint(x: size.width, y: line))
        return points
    }

    private static func jump(_ size: CGSize, _ line: CGFloat) -> [CGPoint] {
        let lip = line - min(size.height * 0.30, line - size.height * 0.20)
        var points = [CGPoint(x: 0, y: line)]
        points += quad(from: CGPoint(x: size.width * 0.20, y: line),
                       control: CGPoint(x: size.width * 0.30, y: line),
                       to: CGPoint(x: size.width * 0.36, y: lip),
                       steps: 8)
        // Through the air. The train is unsupported here, which is the point.
        points += quad(from: CGPoint(x: size.width * 0.36, y: lip),
                       control: CGPoint(x: size.width * 0.50, y: lip - size.height * 0.34),
                       to: CGPoint(x: size.width * 0.64, y: lip),
                       steps: 14)
        points += quad(from: CGPoint(x: size.width * 0.64, y: lip),
                       control: CGPoint(x: size.width * 0.70, y: line),
                       to: CGPoint(x: size.width * 0.80, y: line),
                       steps: 8)
        points.append(CGPoint(x: size.width, y: line))
        return points
    }

    private static func helix(_ size: CGSize, _ line: CGFloat) -> [CGPoint] {
        let centre = CGPoint(x: size.width / 2, y: line)
        let outer = min(size.width, size.height) * 0.38
        var points = [CGPoint(x: 0, y: line)]

        let steps = 96
        for step in 0...steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let angle = .pi + progress * .pi * 2 * 3
            let radius = outer * (1 - progress * 0.55)
            points.append(CGPoint(x: centre.x + cos(angle) * radius,
                                  y: centre.y + sin(angle) * radius * 0.68))
        }
        points.append(CGPoint(x: size.width, y: line))
        return points
    }

    /// Samples a quadratic curve. The weights are named because the one-line
    /// form is more than Swift's type checker will take.
    private static func quad(from: CGPoint,
                             control: CGPoint,
                             to: CGPoint,
                             steps: Int) -> [CGPoint] {
        (0...steps).map { step -> CGPoint in
            let t = CGFloat(step) / CGFloat(steps)
            let inverse: CGFloat = 1 - t
            let fromWeight: CGFloat = inverse * inverse
            let controlWeight: CGFloat = 2 * inverse * t
            let toWeight: CGFloat = t * t
            let x: CGFloat = fromWeight * from.x + controlWeight * control.x + toWeight * to.x
            let y: CGFloat = fromWeight * from.y + controlWeight * control.y + toWeight * to.y
            return CGPoint(x: x, y: y)
        }
    }

    // MARK: - The picture

    static func texture(for motif: CoasterElementMotif,
                        size: CGSize,
                        trackY: CGFloat) -> SKTexture {
        SpriteFactory.texture(
            key: "element-\(motif.rawValue)-\(Int(size.width))x\(Int(size.height))-\(Int(trackY * 100))",
            size: size) { context, size in
            draw(motif, size: size, trackY: trackY)
        }
    }

    /// The same image for the build menu, so what you pick is what you get.
    static func previewImage(for motif: CoasterElementMotif,
                             size: CGSize,
                             trackY: CGFloat) -> UIImage {
        let key = "\(motif.rawValue)-\(Int(size.width))x\(Int(size.height))"
        if let cached = previews[key] { return cached }
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            draw(motif, size: size, trackY: trackY)
        }
        previews[key] = image
        return image
    }

    private static var previews: [String: UIImage] = [:]

    private static func draw(_ motif: CoasterElementMotif, size: CGSize, trackY: CGFloat) {
        let points = centreline(for: motif, size: size, trackY: trackY)
        guard points.count > 1 else { return }

        let path = UIBezierPath()
        path.move(to: points[0])
        for point in points.dropFirst() { path.addLine(to: point) }

        // Uprights first, so the track sits on top of them. Every few points
        // is enough to read as a structure without becoming a fence.
        let deck = size.height * trackY
        let legs = UIBezierPath()
        for (index, point) in points.enumerated() where index % 6 == 0 && point.y < deck - 4 {
            legs.move(to: point)
            legs.addLine(to: CGPoint(x: point.x, y: deck))
        }
        // Thicker than a hairline: these are steel columns, not pencil marks.
        ParkPalette.coasterSupport.setStroke()
        legs.lineWidth = max(1.5, size.height * 0.030)
        legs.stroke()

        // A spine along the track line, which is what the columns stand on.
        let spine = UIBezierPath()
        spine.move(to: CGPoint(x: 0, y: deck))
        spine.addLine(to: CGPoint(x: size.width, y: deck))
        ParkPalette.coasterSupport.setStroke()
        spine.lineWidth = max(1.5, size.height * 0.026)
        spine.stroke()

        // Ties, then rail. The same two-pass stroke the track tiles use, so an
        // element and the track it sits on read as one railway.
        ParkPalette.coasterTie.setStroke()
        path.lineWidth = max(3, size.height * 0.115)
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()

        ParkPalette.coasterRail.setStroke()
        path.lineWidth = max(1.5, size.height * 0.050)
        path.stroke()

        if motif == .jump { markGap(size: size, trackY: trackY) }
    }

    /// Hazard marks under a jump, so the gap reads as deliberate.
    private static func markGap(size: CGSize, trackY: CGFloat) {
        let deck = size.height * trackY
        ParkPalette.coasterRail.withAlphaComponent(0.45).setFill()
        for index in 0..<3 {
            let mark = CGRect(x: size.width * (0.42 + 0.07 * CGFloat(index)),
                              y: deck + size.height * 0.04,
                              width: size.width * 0.035,
                              height: size.height * 0.07)
            UIBezierPath(rect: mark).fill()
        }
    }
}
