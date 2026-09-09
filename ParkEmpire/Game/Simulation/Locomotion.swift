import CoreGraphics
import Foundation

/// Walking along a route. Shared by guests and staff so there is exactly one
/// implementation of "move towards the next tile".
enum Locomotion {

    enum StepResult {
        /// Still travelling.
        case moving
        /// The route is finished; the walker is standing on its goal.
        case arrived
        /// The next tile is no longer walkable, so the route was discarded.
        case blocked
    }

    static func advance(position: inout CGPoint,
                        tile: inout GridCoord,
                        route: inout [GridCoord],
                        speed: Double,
                        dt: Double,
                        map: ParkMap) -> StepResult {
        guard let next = route.first else { return .arrived }

        // The layout can change under a walker; let the caller re-plan.
        guard map.isWalkable(next) else {
            route.removeAll()
            return .blocked
        }

        let destination = next.centre
        let dx = Double(destination.x - position.x)
        let dy = Double(destination.y - position.y)
        let remaining = (dx * dx + dy * dy).squareRoot()
        let travel = speed * dt

        if remaining <= travel || remaining < 0.0001 {
            position = destination
            tile = next
            route.removeFirst()
            return route.isEmpty ? .arrived : .moving
        }

        let scale = travel / remaining
        position = CGPoint(x: position.x + CGFloat(dx * scale),
                           y: position.y + CGFloat(dy * scale))
        return .moving
    }
}
