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
                      turnFraction: Double = 1.0,
                      headings: [CGFloat]? = nil,
                      flair: [Bool]? = nil) {
        guard points.count > 1 else { return }

        // Legs are timed by how long they are rather than by how many there
        // are. A circuit sampled densely round a loop and sparsely along a
        // straight would otherwise crawl through the loop and race the
        // straight, and the turn spread across each leg would jerk wherever
        // the sampling changed.
        var lengths: [CGFloat] = []
        lengths.reserveCapacity(points.count)
        for index in points.indices {
            let next = points[(index + 1) % points.count]
            lengths.append(max(hypot(next.x - points[index].x,
                                     next.y - points[index].y), 0.0001))
        }
        let total = lengths.reduce(0, +)

        node.position = points[0]
        node.zRotation = headings?.first ?? heading(from: points[0], to: points[1])

        var legs: [SKAction] = []
        for index in points.indices {
            let to = points[(index + 1) % points.count]
            let legTime = duration * Double(lengths[index] / total)

            let move = SKAction.move(to: to, duration: legTime)
            move.timingMode = .linear

            // A caller can supply headings where facing should not follow the
            // direction of travel, which is how a train reverses down a line
            // without every carriage spinning round.
            let angle = headings?[index] ?? heading(from: points[index], to: to)
            let turn = SKAction.rotate(toAngle: angle,
                                       duration: max(0.01, legTime * min(1.0, max(0.05, turnFraction))),
                                       shortestUnitArc: true)
            // A leg marked for flair gets a swell as the vehicle crosses it,
            // which is how a flat tile suggests going over the top of a loop.
            if flair?[index] == true {
                let swell = SKAction.sequence([
                    .scale(to: 1.45, duration: max(0.01, legTime * 0.5)),
                    .scale(to: 1.0, duration: max(0.01, legTime * 0.5))
                ])
                legs.append(.group([move, turn, swell]))
            } else {
                legs.append(.group([move, turn]))
            }
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

    /// Rounds the corners off a polyline by repeatedly cutting them.
    ///
    /// A route built from tile centres turns through a right angle at a bend,
    /// so a vehicle following it pivots on the spot at the corner instead of
    /// curving through it. Chaikin's cut takes each leg and replaces its ends
    /// with points a quarter and three quarters along, which after two passes
    /// is close to the arc the rails are actually drawn as.
    static func smoothed(_ points: [CGPoint], closed: Bool, iterations: Int = 2) -> [CGPoint] {
        guard points.count > 2, iterations > 0 else { return points }

        var current = points
        for _ in 0..<iterations {
            var next: [CGPoint] = []
            next.reserveCapacity(current.count * 2)

            // An open line keeps its ends, or the train would stop short of
            // the buffers a little further every pass.
            if !closed { next.append(current[0]) }

            let lastIndex = closed ? current.count - 1 : current.count - 2
            for index in 0...lastIndex {
                let from = current[index]
                let to = current[(index + 1) % current.count]
                next.append(CGPoint(x: from.x * 0.75 + to.x * 0.25,
                                    y: from.y * 0.75 + to.y * 0.25))
                next.append(CGPoint(x: from.x * 0.25 + to.x * 0.75,
                                    y: from.y * 0.25 + to.y * 0.75))
            }

            if !closed { next.append(current[current.count - 1]) }
            current = next
        }
        return current
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
    static func shuttleRun(along line: [CGPoint],
                           carIndex: Int,
                           carSpacing: CGFloat,
                           consistLength: CGFloat,
                           samples: Int) -> (points: [CGPoint], headings: [CGFloat]) {
        guard line.count > 1, samples > 1 else { return (line, []) }

        var cumulative: [CGFloat] = [0]
        cumulative.reserveCapacity(line.count)
        for index in 1..<line.count {
            let step = hypot(line[index].x - line[index - 1].x,
                             line[index].y - line[index - 1].y)
            cumulative.append(cumulative[index - 1] + step)
        }
        let total = cumulative[cumulative.count - 1]
        guard total > 0 else { return (line, []) }

        let head = min(consistLength, total * 0.5)

        var points: [CGPoint] = []
        var headings: [CGFloat] = []
        points.reserveCapacity(samples)
        headings.reserveCapacity(samples)

        for sample in 0..<samples {
            let phase = Double(sample) / Double(samples)
            // A triangle wave: out along the line, then back.
            let along = phase < 0.5 ? phase * 2 : (1 - phase) * 2
            let headDistance = head + (total - head) * CGFloat(along)
            let distance = min(max(headDistance - carSpacing * CGFloat(carIndex), 0), total)
            points.append(point(at: distance, along: line, cumulative: cumulative))
            // Facing follows the rails, not the direction of travel, so the
            // train backs down the line instead of every carriage spinning
            // round at the terminus.
            headings.append(tangent(at: distance, along: line, cumulative: cumulative))
        }

        return (points, headings)
    }

    /// Which way the rails point at a given distance along them.
    private static func tangent(at distance: CGFloat,
                                along line: [CGPoint],
                                cumulative: [CGFloat]) -> CGFloat {
        guard line.count > 1 else { return 0 }
        var index = 1
        while index < cumulative.count - 1 && cumulative[index] < distance { index += 1 }
        return heading(from: line[index - 1], to: line[index])
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
