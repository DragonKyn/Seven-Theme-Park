import Foundation

/// Drives the simulation on a fixed tick, independent of the render rate.
///
/// Rendering calls `advance(state:realDelta:)` once per frame; the engine
/// converts that into a whole number of `Balance.tickDuration` steps scaled by
/// the current game speed. Every system therefore always sees the same `dt`,
/// which keeps behaviour identical at 1x and 4x.
final class SimulationEngine {

    let pathfinder = PathfindingSystem()

    private lazy var demand = DemandSystem()
    private lazy var guestAI = GuestAISystem(pathfinder: pathfinder)
    private lazy var movement = MovementSystem(pathfinder: pathfinder)
    private lazy var attractionSystem = AttractionSystem()
    private lazy var facilitySystem = FacilitySystem()
    private lazy var cleanliness = CleanlinessSystem()
    private lazy var maintenance = MaintenanceSystem()
    private lazy var staffSystem = StaffSystem(pathfinder: pathfinder)
    private lazy var economy = EconomySystem()
    private lazy var rating = RatingSystem()

    private var accumulator: Double = 0

    /// Runs whole ticks for the elapsed real time. Returns how many ran.
    @discardableResult
    func advance(state: GameState, realDelta: Double) -> Int {
        let speed = state.clock.speed.multiplier
        guard speed > 0, realDelta > 0 else { return 0 }

        accumulator += realDelta * speed

        var ticks = 0
        while accumulator >= Balance.tickDuration && ticks < Balance.maxTicksPerFrame {
            accumulator -= Balance.tickDuration
            tick(state: state)
            ticks += 1
        }

        // If we hit the ceiling the device could not keep up; drop the backlog
        // rather than spiralling further behind.
        if ticks >= Balance.maxTicksPerFrame {
            accumulator = 0
        }

        return ticks
    }

    /// The park still needs a rating breakdown when paused.
    func ratingBreakdown(state: GameState) -> [RatingSystem.Component] {
        rating.evaluate(state: state)
    }

    func resetTiming() {
        accumulator = 0
        pathfinder.clearCache()
    }

    private func tick(state: GameState) {
        let dt = Balance.tickDuration
        state.clock.simTime += dt

        demand.update(state: state, dt: dt)
        guestAI.update(state: state, dt: dt)
        movement.update(state: state, dt: dt)
        attractionSystem.update(state: state, dt: dt)
        facilitySystem.update(state: state, dt: dt)
        cleanliness.update(state: state, dt: dt)
        maintenance.update(state: state, dt: dt)
        staffSystem.update(state: state, dt: dt)
        economy.update(state: state, dt: dt)
        rating.update(state: state)

        purgeDepartedGuests(state: state)
    }

    /// Guests that have left are removed from the array, and any stale
    /// references to them are cleared out of queues.
    private func purgeDepartedGuests(state: GameState) {
        guard state.guests.contains(where: { !$0.isActive }) else { return }

        let departed = Set(state.guests.filter { !$0.isActive }.map(\.id))
        state.guests.removeAll { departed.contains($0.id) }

        for index in state.attractions.indices {
            state.attractions[index].queue.removeAll { departed.contains($0) }
            state.attractions[index].riders.removeAll { departed.contains($0) }
        }
        for index in state.facilities.indices {
            state.facilities[index].queue.removeAll { departed.contains($0) }
            state.facilities[index].slots.removeAll { departed.contains($0.guestID) }
        }
    }
}
