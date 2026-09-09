import Foundation

/// Routing over walkable tiles.
///
/// Instead of running a separate A* query per guest, this builds one
/// breadth-first *distance field* per destination and caches it until the map
/// changes. Every guest heading to the same building then reads its route by
/// descending that field, which is what keeps hundreds of guests affordable:
/// the cost is one grid sweep per destination per layout change, not one
/// search per guest per decision. The same field also answers "how far is
/// that from here" for free, which guest decision scoring needs.
final class PathfindingSystem {

    /// Distance in tiles from every tile to the nearest goal.
    /// `unreachable` marks tiles with no route.
    static let unreachable = Int.max

    private var cache: [[GridCoord]: [Int]] = [:]
    private var cachedGeneration: Int = -1
    private let maxCachedFields = 64

    /// Drops cached fields when the walkable layout has changed.
    private func invalidateIfNeeded(_ map: ParkMap) {
        guard map.generation != cachedGeneration else { return }
        cache.removeAll(keepingCapacity: true)
        cachedGeneration = map.generation
    }

    func clearCache() {
        cache.removeAll(keepingCapacity: true)
        cachedGeneration = -1
    }

    /// Distance field to the nearest of `goals`.
    func distanceField(to goals: [GridCoord], in map: ParkMap) -> [Int] {
        invalidateIfNeeded(map)

        let key = goals.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        if let cached = cache[key] { return cached }

        var distances = [Int](repeating: Self.unreachable, count: map.tileCount)
        var frontier: [GridCoord] = []
        frontier.reserveCapacity(map.tileCount)

        for goal in goals where map.isWalkable(goal) {
            let index = map.linearIndex(of: goal)
            if distances[index] != 0 {
                distances[index] = 0
                frontier.append(goal)
            }
        }

        var head = 0
        while head < frontier.count {
            let coord = frontier[head]
            head += 1
            let distance = distances[map.linearIndex(of: coord)]
            for neighbour in coord.orthogonalNeighbours where map.isWalkable(neighbour) {
                let index = map.linearIndex(of: neighbour)
                if distances[index] > distance + 1 {
                    distances[index] = distance + 1
                    frontier.append(neighbour)
                }
            }
        }

        if cache.count >= maxCachedFields {
            cache.removeAll(keepingCapacity: true)
        }
        cache[key] = distances
        return distances
    }

    /// Tile distance from `start` to the nearest goal, or nil when unreachable.
    func distance(from start: GridCoord, to goals: [GridCoord], in map: ParkMap) -> Int? {
        guard map.isWalkable(start), !goals.isEmpty else { return nil }
        let field = distanceField(to: goals, in: map)
        let value = field[map.linearIndex(of: start)]
        return value == Self.unreachable ? nil : value
    }

    /// Full step-by-step route from `start` to the nearest goal, excluding the
    /// starting tile. Empty when there is no route.
    func route(from start: GridCoord, to goals: [GridCoord], in map: ParkMap) -> [GridCoord] {
        guard map.isWalkable(start), !goals.isEmpty else { return [] }
        let field = distanceField(to: goals, in: map)
        var current = start
        var currentDistance = field[map.linearIndex(of: current)]
        guard currentDistance != Self.unreachable else { return [] }

        var steps: [GridCoord] = []
        steps.reserveCapacity(currentDistance)

        while currentDistance > 0 {
            var best: GridCoord?
            var bestDistance = currentDistance
            for neighbour in current.orthogonalNeighbours where map.isWalkable(neighbour) {
                let distance = field[map.linearIndex(of: neighbour)]
                if distance < bestDistance {
                    bestDistance = distance
                    best = neighbour
                }
            }
            guard let next = best else { break }
            steps.append(next)
            current = next
            currentDistance = bestDistance
            // Defensive stop; a descending field can never exceed the tile count.
            if steps.count > map.tileCount { break }
        }

        return steps
    }
}
