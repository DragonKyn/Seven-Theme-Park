import CoreGraphics
import Foundation

/// Walks guests along the routes the AI gave them and handles what happens the
/// moment they arrive somewhere.
final class MovementSystem {

    private let pathfinder: PathfindingSystem

    init(pathfinder: PathfindingSystem) {
        self.pathfinder = pathfinder
    }

    func update(state: GameState, dt: Double) {
        let map = state.map
        let now = state.clock.simTime

        for index in state.guests.indices {
            guard state.guests[index].isActive else { continue }

            let target: ParkTarget?
            switch state.guests[index].activity {
            case .walking(let value): target = value
            case .arriving, .exploring: target = nil
            default: continue
            }

            if state.guests[index].route.isEmpty {
                if let target {
                    MovementSystem.beginActivity(at: target, guestIndex: index, state: state, now: now)
                }
                continue
            }

            // Worked on a local copy: three simultaneous `inout` arguments
            // through an array subscript would be overlapping access.
            var guest = state.guests[index]
            let result = Locomotion.advance(position: &guest.position,
                                            tile: &guest.tile,
                                            route: &guest.route,
                                            speed: guest.walkSpeed,
                                            dt: dt,
                                            map: map)
            state.guests[index] = guest

            switch result {
            case .moving:
                break

            case .arrived:
                if let target {
                    MovementSystem.beginActivity(at: target, guestIndex: index, state: state, now: now)
                } else {
                    state.guests[index].activity = .exploring
                }

            case .blocked:
                replan(guestIndex: index, target: target, state: state, map: map, now: now)
            }
        }
    }

    /// Something was built or demolished across the guest's path.
    private func replan(guestIndex: Int,
                        target: ParkTarget?,
                        state: GameState,
                        map: ParkMap,
                        now: Double) {
        guard let target else {
            state.guests[guestIndex].activity = .exploring
            state.guests[guestIndex].nextDecisionAt = now
            return
        }

        let access = state.accessTiles(for: target)
        let route = pathfinder.route(from: state.guests[guestIndex].tile, to: access, in: map)
        if route.isEmpty {
            state.guests[guestIndex].activity = .exploring
            state.guests[guestIndex].nextDecisionAt = now
        } else {
            state.guests[guestIndex].route = route
        }
    }

    // MARK: - Arrival

    /// What a guest does the instant it reaches its goal: join a queue, take a
    /// seat, leave the park, or simply look around.
    static func beginActivity(at target: ParkTarget, guestIndex: Int, state: GameState, now: Double) {
        switch target {
        case .attraction(let id):
            guard let attractionIndex = state.attractionIndex(id: id),
                  let definition = state.attractions[attractionIndex].definition,
                  state.attractions[attractionIndex].isOperational else {
                sendExploring(guestIndex: guestIndex, state: state, now: now)
                return
            }

            let queueCapacity = definition.capacity * 6
            guard state.attractions[attractionIndex].queue.count < queueCapacity else {
                state.guests[guestIndex].think(
                    ThoughtCatalog.queueTooLong(state.attractions[attractionIndex].name),
                    mood: .negative,
                    at: now,
                    icon: .queue)
                sendExploring(guestIndex: guestIndex, state: state, now: now)
                return
            }

            let wait = state.attractions[attractionIndex].estimatedWait(definition: definition)
            state.attractions[attractionIndex].queue.append(state.guests[guestIndex].id)
            state.guests[guestIndex].activity = .queueing(target)
            state.guests[guestIndex].queueJoinedAt = now
            state.guests[guestIndex].queueWaitEstimate = wait
            state.guests[guestIndex].queueSlot = state.attractions[attractionIndex].queue.count - 1

        case .facility(let id):
            guard let facilityIndex = state.facilityIndex(id: id),
                  let definition = state.facilities[facilityIndex].definition,
                  state.facilities[facilityIndex].isOpen,
                  !state.facilities[facilityIndex].isUnusable else {
                if let facilityIndex = state.facilityIndex(id: id),
                   state.facilities[facilityIndex].isUnusable {
                    state.guests[guestIndex].think(
                        unusableThought(for: state.facilities[facilityIndex]),
                        mood: .negative,
                        at: now)
                }
                sendExploring(guestIndex: guestIndex, state: state, now: now)
                return
            }

            guard state.facilities[facilityIndex].queue.count < definition.queueCapacity else {
                state.guests[guestIndex].think(
                    ThoughtCatalog.queueTooLong(state.facilities[facilityIndex].name),
                    mood: .negative,
                    at: now,
                    icon: .queue)
                sendExploring(guestIndex: guestIndex, state: state, now: now)
                return
            }

            let wait = state.facilities[facilityIndex].estimatedWait(definition: definition)
            state.facilities[facilityIndex].queue.append(state.guests[guestIndex].id)
            state.guests[guestIndex].activity = .queueing(target)
            state.guests[guestIndex].queueJoinedAt = now
            state.guests[guestIndex].queueWaitEstimate = wait
            state.guests[guestIndex].queueSlot = state.facilities[facilityIndex].queue.count - 1

        case .exit:
            depart(guestIndex: guestIndex, state: state)

        case .wanderSpot:
            state.guests[guestIndex].activity = .exploring
            state.guests[guestIndex].nextDecisionAt = now
        }
    }

    private static func unusableThought(for facility: Facility) -> String {
        facility.definition?.kind == .bin
            ? "That bin is overflowing."
            : "That restroom is in a disgusting state."
    }

    private static func sendExploring(guestIndex: Int, state: GameState, now: Double) {
        state.guests[guestIndex].activity = .exploring
        state.guests[guestIndex].route = []
        state.guests[guestIndex].nextDecisionAt = now + 2
    }

    /// Removes the guest from play and books the statistics for its visit.
    static func depart(guestIndex: Int, state: GameState) {
        let guest = state.guests[guestIndex]
        let reason = guest.departureReason ?? DepartureReason.satisfied.rawValue
        state.statistics.recordDeparture(reason: reason)

        // A reviewer's opinion is only complete on the way out.
        if guest.isCritic {
            CriticSystem.publish(guestIndex: guestIndex, state: state)
        }

        state.guests[guestIndex].activity = .departed
        state.guests[guestIndex].route = []
    }
}
