import Foundation

/// The railway the player has laid, worked out from the track tiles on the map.
///
/// Track is terrain, so there is nothing to keep in step: the network is
/// derived from the tiles whenever the map changes and thrown away otherwise.
/// A route is an ordered ring of tiles a train can run without ever jumping,
/// which is also what decides whether two stations are connected.
struct TrackNetwork {

    /// One connected run of track, ordered so consecutive tiles touch.
    ///
    /// A loop's last tile touches its first. A line is stored one way only:
    /// what a train does when it reaches the end is the renderer's business,
    /// and storing the return leg here would double every line.
    struct Route {
        let tiles: [GridCoord]
        /// True when the track forms a closed loop rather than a dead-ended
        /// line. A line is still runnable: the train shuttles along it.
        let isLoop: Bool
    }

    let routes: [Route]

    static let empty = TrackNetwork(routes: [])

    // MARK: - Building

    static func build(map: ParkMap) -> TrackNetwork {
        var remaining = Set(map.coords(ofTerrain: .track))
        guard !remaining.isEmpty else { return .empty }

        var routes: [Route] = []
        while let seed = remaining.first {
            let component = flood(from: seed, remaining: &remaining)
            // A single tile of track is somebody halfway through drawing a
            // line, not a railway.
            guard component.count > 1, let route = order(component) else { continue }
            routes.append(route)
        }
        return TrackNetwork(routes: routes)
    }

    private static func flood(from seed: GridCoord, remaining: inout Set<GridCoord>) -> Set<GridCoord> {
        var component: Set<GridCoord> = []
        var stack = [seed]
        while let coord = stack.popLast() {
            guard remaining.remove(coord) != nil else { continue }
            component.insert(coord)
            for neighbour in coord.orthogonalNeighbours where remaining.contains(neighbour) {
                stack.append(neighbour)
            }
        }
        return component
    }

    /// Walks a connected clump of track into a driveable order.
    ///
    /// Starting from a dead end where there is one means a line is walked end
    /// to end rather than from the middle. Branches off the main run are left
    /// out: a train can only be in one place, and a route that teleported at a
    /// junction would look worse than one that ignores the siding.
    private static func order(_ component: Set<GridCoord>) -> Route? {
        func neighbours(of coord: GridCoord) -> [GridCoord] {
            coord.orthogonalNeighbours.filter { component.contains($0) }
        }

        let endpoint = component.first { neighbours(of: $0).count == 1 }
        guard let start = endpoint ?? component.first else { return nil }

        var ordered: [GridCoord] = []
        var visited: Set<GridCoord> = []
        var current = start

        while true {
            ordered.append(current)
            visited.insert(current)
            // Prefer whichever unvisited neighbour keeps the run going; with
            // no branches there is only ever one.
            guard let next = neighbours(of: current).first(where: { !visited.contains($0) }) else {
                break
            }
            current = next
        }

        guard ordered.count > 1 else { return nil }

        let closes = ordered[0].isOrthogonallyAdjacent(to: ordered[ordered.count - 1])
        return Route(tiles: ordered, isLoop: closes)
    }

    // MARK: - Stations

    /// Which route, if any, a building's footprint sits against.
    func routeIndex(touching rect: GridRect) -> Int? {
        let adjacent = Set(rect.adjacentCoords)
        for (index, route) in routes.enumerated() where route.tiles.contains(where: { adjacent.contains($0) }) {
            return index
        }
        return nil
    }

    var isEmpty: Bool { routes.isEmpty }
}
