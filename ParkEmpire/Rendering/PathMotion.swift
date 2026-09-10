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
}
