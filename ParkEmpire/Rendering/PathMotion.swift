import SpriteKit
import UIKit

/// Moving a sprite along a route and pointing it the right way.
///
/// Shared by the rides that have something driving round them and by the
/// trains that run the player's own track, so a kart and a locomotive follow
/// exactly the same rules about which way is forward.
enum PathMotion {

    /// Drives a sprite round a closed loop of points, turning it to face the
    /// way it is going at every step.
    ///
    /// `SKAction.follow(orientToPath:)` used to do the driving, and left the
    /// karts side-on to the track. Steering explicitly costs a handful more
    /// actions and takes SpriteKit's orientation convention out of the
    /// argument: the artwork points along positive x, and so does the heading
    /// this sets.
    ///
    /// `turnFraction` is how much of each leg is spent turning. A kart sweeps
    /// through the whole leg; a bumper car snaps round and then drives.
    static func drive(_ node: SKSpriteNode,
                      around points: [CGPoint],
                      duration: TimeInterval,
                      turnFraction: Double = 1.0) {
        guard points.count > 1 else { return }

        let leg = duration / Double(points.count)
        let turnTime = max(0.01, leg * min(1.0, max(0.05, turnFraction)))

        node.position = points[0]
        node.zRotation = heading(from: points[0], to: points[1])

        var legs: [SKAction] = []
        for index in points.indices {
            let from = points[index]
            let to = points[(index + 1) % points.count]
            let move = SKAction.move(to: to, duration: leg)
            move.timingMode = .linear
            let turn = SKAction.rotate(toAngle: heading(from: from, to: to),
                                       duration: turnTime,
                                       shortestUnitArc: true)
            legs.append(.group([move, turn]))
        }

        node.run(.repeatForever(.sequence(legs)))
    }

    private static func heading(from: CGPoint, to: CGPoint) -> CGFloat {
        atan2(to.y - from.y, to.x - from.x)
    }

    /// Points around an oval, starting at `startAngle` so several vehicles can
    /// share one track without sharing a starting position.
    static func ovalPoints(_ trackRect: CGRect,
                           in buildingSize: CGSize,
                           inset: CGFloat,
                           startAngle: CGFloat,
                           steps: Int) -> [CGPoint] {
        let radiusX = max(1, trackRect.width / 2 - inset)
        let radiusY = max(1, trackRect.height / 2 - inset)
        // The track is drawn in texture space with y downward; the scene has y
        // upward. The oval is centred, so only the origin has to move.
        let centre = CGPoint(x: trackRect.midX - buildingSize.width / 2,
                             y: trackRect.midY - buildingSize.height / 2)

        return (0..<steps).map { step in
            let angle = startAngle + CGFloat(step) / CGFloat(steps) * .pi * 2
            return CGPoint(x: centre.x + cos(angle) * radiusX,
                           y: centre.y + sin(angle) * radiusY)
        }
    }

    // MARK: - Shuttles

    /// Positions for one vehicle of a train running out and back along a
    /// dead-ended line.
    ///
    /// A rigid train does not rearrange itself when it reverses: every car
    /// stays the same distance back along the rails, and what changes is which
    /// end leads. Offsetting cars by array index instead makes them pass
    /// through one another at the turnaround, which is what a single railcar
    /// was working around.
    ///
    /// The head stops short of the near end by the length of the train, so the
    /// last car comes to rest at the platform rather than the first.
    static func shuttlePoints(along line: [CGPoint],
                              carIndex: Int,
                              carSpacing: CGFloat,
                              consistLength: CGFloat,
                              samples: Int) -> [CGPoint] {
        guard line.count > 1, samples > 1 else { return line }

        var cumulative: [CGFloat] = [0]
        cumulative.reserveCapacity(line.count)
        for index in 1..<line.count {
            let step = hypot(line[index].x - line[index - 1].x,
                             line[index].y - line[index - 1].y)
            cumulative.append(cumulative[index - 1] + step)
        }
        let total = cumulative[cumulative.count - 1]
        guard total > 0 else { return line }

        let head = min(consistLength, total * 0.5)

        return (0..<samples).map { sample in
            let phase = Double(sample) / Double(samples)
            // A triangle wave: out along the line, then back.
            let along = phase < 0.5 ? phase * 2 : (1 - phase) * 2
            let headDistance = head + (total - head) * CGFloat(along)
            let distance = min(max(headDistance - carSpacing * CGFloat(carIndex), 0), total)
            return point(at: distance, along: line, cumulative: cumulative)
        }
    }

    /// Where a given distance along a polyline falls.
    private static func point(at distance: CGFloat,
                              along line: [CGPoint],
                              cumulative: [CGFloat]) -> CGPoint {
        guard let last = cumulative.last, distance > 0 else { return line[0] }
        guard distance < last else { return line[line.count - 1] }

        var index = 1
        while index < cumulative.count && cumulative[index] < distance { index += 1 }
        let previous = cumulative[index - 1]
        let span = cumulative[index] - previous
        let t = span > 0 ? (distance - previous) / span : 0
        let from = line[index - 1]
        let to = line[index]
        return CGPoint(x: from.x + (to.x - from.x) * t,
                       y: from.y + (to.y - from.y) * t)
    }

    /// Length of a polyline, treated as a closed ring.
    static func ringLength(of points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for index in points.indices {
            let next = points[(index + 1) % points.count]
            total += hypot(next.x - points[index].x, next.y - points[index].y)
        }
        return total
    }
}
