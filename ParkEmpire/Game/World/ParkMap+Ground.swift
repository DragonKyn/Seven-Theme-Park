import Foundation

/// Where a building may stand, and what standing there does to the walkways.
extension ParkMap {

    /// True when every tile of `rect` is inside the park, unoccupied, and
    /// either bare grass or a plain walkway.
    ///
    /// A walkway counts because a building does not have to be put beside the
    /// path: it can be put on it, and the pavement is the ground underneath
    /// it. Entrances and bridges do not count. One is the gate and the other
    /// is a deck over water, and neither is somewhere to build.
    func isAreaClearGround(_ rect: GridRect) -> Bool {
        for coord in rect.coords {
            guard let tile = tile(at: coord) else { return false }
            guard tile.terrain == .grass || tile.terrain == .path else { return false }
            if tile.isOccupied { return false }
        }
        return true
    }

    /// Whether putting something that blocks movement on `rect` would leave
    /// any walkway cut off from the entrance.
    ///
    /// Covering the path that was the way into a corner of the park is the one
    /// mistake building on pavement makes easy, and it is a quiet one: every
    /// guest in the far half is stranded and nothing says why. Walkway tiles
    /// the footprint covers itself are not counted as lost, only the ones
    /// beyond them that could no longer be reached.
    func wouldStrandWalkways(by rect: GridRect) -> Bool {
        let covered = Set(rect.coords.compactMap { coord -> Int? in
            isInside(coord) ? linearIndex(of: coord) : nil
        })
        guard covered.contains(where: { tiles[$0].terrain.isWalkableTerrain }) else { return false }

        let before = reachableFromEntrance(excluding: [])
        let after = reachableFromEntrance(excluding: covered)

        for index in 0..<tileCount where before[index] && !covered.contains(index) && !after[index] {
            return true
        }
        return false
    }

    /// Every walkable tile a guest could reach from the gate, flagged by
    /// linear index. `excluding` is treated as blocked.
    private func reachableFromEntrance(excluding blocked: Set<Int>) -> [Bool] {
        var reached = Array(repeating: false, count: tileCount)
        guard isInside(entranceCoord) else { return reached }

        var frontier = [linearIndex(of: entranceCoord)]
        reached[frontier[0]] = true

        while let index = frontier.popLast() {
            for neighbour in coord(atLinearIndex: index).orthogonalNeighbours {
                guard isInside(neighbour) else { continue }
                let next = linearIndex(of: neighbour)
                guard !reached[next], !blocked.contains(next), tiles[next].isWalkable else { continue }
                reached[next] = true
                frontier.append(next)
            }
        }
        return reached
    }
}
