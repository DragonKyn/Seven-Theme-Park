import Foundation

/// Where an employee is up to on a journey that includes the park railway.
///
/// A job on the far side of the park is sometimes reachable only by train:
/// the walkways on that side join nothing on this one. The employee walks to
/// a platform, waits for the train, rides, steps off at the other station and
/// walks on to the job. Guests are carried by the same railway, so an
/// employee has to be able to use it too, or whole parts of a map are
/// somewhere nobody can clean, mend or entertain.
struct StaffTransfer: Codable, Equatable {
    /// The station they board at.
    var stationID: UUID
    /// The walkway tile they step off onto.
    var landing: GridCoord
    /// Sim-seconds of waiting on the platform, then of riding.
    var waiting: Double
    var riding: Double
    var boarded: Bool = false
}

/// A way to get somewhere on foot and by train, and what it is worth.
struct TrainHop {
    /// Where on the platform to stand, nearest first is not required: the
    /// pathfinder takes the closest.
    let boarding: [GridCoord]
    let transfer: StaffTransfer
    /// Tiles-equivalent length of the whole trip, for comparing it with jobs
    /// reachable on foot.
    let cost: Int
}

/// Works out whether, and how, an employee can reach somewhere by train.
///
/// Built once per job search. The expensive part, finding which stretches of
/// walkway join, is done for the whole map at once and shared, so asking about
/// each of several hundred pieces of litter is a lookup rather than a search.
struct StaffTransit {

    struct Station {
        let id: UUID
        let route: Int
        /// Tiles an employee can stand on to use it.
        let platforms: [GridCoord]
    }

    private let map: ParkMap
    private let stations: [Station]
    private let labels: [Int]
    private let walkingDistance: (GridCoord) -> Int?

    /// Nil when there is nothing to ride: fewer than two working stations on
    /// the same railway, or none this employee can walk to.
    init?(state: GameState,
          field: [Int],
          labels: [Int]) {
        let map = state.map
        let network = state.trackNetwork
        guard !network.isEmpty else { return nil }

        var stations: [Station] = []
        for attraction in state.attractions where attraction.isOperational {
            guard attraction.definition?.kind == .transport,
                  let route = network.routeIndex(touching: attraction.rect) else { continue }
            let platforms = map.accessTiles(for: attraction.rect)
            guard !platforms.isEmpty else { continue }
            stations.append(Station(id: attraction.id, route: route, platforms: platforms))
        }
        guard stations.count > 1 else { return nil }

        self.map = map
        self.stations = stations
        self.labels = labels
        self.walkingDistance = { coord in
            guard map.isInside(coord) else { return nil }
            let value = field[map.linearIndex(of: coord)]
            return value == PathfindingSystem.unreachable ? nil : value
        }
    }

    /// The best way to reach any of `destinations`, or nil when no train gets
    /// there.
    func plan(to destinations: [GridCoord]) -> TrainHop? {
        let wanted = Set(destinations.compactMap { label(of: $0) })
        guard !wanted.isEmpty else { return nil }

        var best: TrainHop?
        for from in stations {
            // The nearest platform the employee can actually walk to.
            var walk: Int?
            for tile in from.platforms {
                guard let distance = walkingDistance(tile) else { continue }
                if distance < (walk ?? Int.max) { walk = distance }
            }
            guard let walkToPlatform = walk else { continue }

            for to in stations where to.id != from.id && to.route == from.route {
                for landing in to.platforms {
                    guard let island = label(of: landing), wanted.contains(island) else { continue }
                    let onward = destinations.map { landing.manhattanDistance(to: $0) }.min() ?? 0
                    let cost = walkToPlatform + Balance.staffTrainTiles + onward
                    guard cost < (best?.cost ?? Int.max) else { continue }

                    best = TrainHop(boarding: from.platforms,
                                    transfer: StaffTransfer(stationID: from.id,
                                                            landing: landing,
                                                            waiting: Balance.staffTrainWait,
                                                            riding: Balance.staffTrainRide),
                                    cost: cost)
                }
            }
        }
        return best
    }

    private func label(of coord: GridCoord) -> Int? {
        guard map.isInside(coord) else { return nil }
        let value = labels[map.linearIndex(of: coord)]
        return value >= 0 ? value : nil
    }

    // MARK: - Which walkways join

    /// Numbers every stretch of walkway that joins up, by tile, with -1 for
    /// anything that is not walkable. Two tiles with the same number can be
    /// walked between; two with different numbers cannot.
    static func islands(in map: ParkMap) -> [Int] {
        var labels = Array(repeating: -1, count: map.tileCount)
        var next = 0

        for start in 0..<map.tileCount where labels[start] < 0 {
            let origin = map.coord(atLinearIndex: start)
            guard map.isWalkable(origin) else { continue }

            labels[start] = next
            var frontier = [origin]
            while let coord = frontier.popLast() {
                for neighbour in coord.orthogonalNeighbours where map.isWalkable(neighbour) {
                    let index = map.linearIndex(of: neighbour)
                    guard labels[index] < 0 else { continue }
                    labels[index] = next
                    frontier.append(neighbour)
                }
            }
            next += 1
        }
        return labels
    }
}
