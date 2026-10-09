package com.wickedstudios.wonderlot

/**
 * Drives the simulation on a fixed tick, independent of the render rate. The
 * renderer calls [advance] once per frame; the engine converts that into a
 * whole number of ticks scaled by the current game speed.
 */
class SimulationEngine {

    val pathfinder = PathfindingSystem()

    private val demand = DemandSystem()
    private val guestAI = GuestAISystem(pathfinder)
    private val movement = MovementSystem(pathfinder)
    private val attractionSystem = AttractionSystem()
    private val facilitySystem = FacilitySystem()
    private val cleanliness = CleanlinessSystem()
    private val maintenance = MaintenanceSystem()
    private val staffSystem = StaffSystem(pathfinder)
    private val economy = EconomySystem()
    private val rating = RatingSystem()
    private val achievements = AchievementSystem()

    /** Simulation steps allowed in one frame before the backlog is dropped. */
    var maxTicksPerFrame: Int = Balance.maxTicksPerFrame

    private var accumulator = 0.0

    /** Runs whole ticks for the elapsed real time. Returns how many ran. */
    fun advance(state: GameState, realDelta: Double): Int {
        val speed = state.clock.speed.multiplier
        if (speed <= 0 || realDelta <= 0) return 0

        accumulator += realDelta * speed

        val ceiling = maxTicksPerFrame
        var ticks = 0
        while (accumulator >= Balance.tickDuration && ticks < ceiling) {
            accumulator -= Balance.tickDuration
            tick(state)
            ticks += 1
        }

        // If we hit the ceiling the device could not keep up; drop the backlog.
        if (ticks >= ceiling) accumulator = 0.0

        return ticks
    }

    /** The park still needs a rating breakdown when paused. */
    fun ratingBreakdown(state: GameState): List<RatingSystem.Component> = rating.evaluate(state)

    /** Seeds the demo park's crowd. */
    fun seedGuests(count: Int, state: GameState) = demand.seed(count, state)

    fun resetTiming() {
        accumulator = 0.0
        pathfinder.clearCache()
    }

    private fun tick(state: GameState) {
        val dt = Balance.tickDuration
        state.clock.simTime += dt

        demand.update(state, dt)
        guestAI.update(state, dt)
        movement.update(state, dt)
        attractionSystem.update(state, dt)
        facilitySystem.update(state, dt)
        cleanliness.update(state, dt)
        // After the litter is counted and before the rating runs.
        TroublemakerSystem.update(state, dt)
        maintenance.update(state, dt)
        // After maintenance and before the staff, so a ride shut this tick is already on the mechanic's list.
        InspectionSystem.update(state)
        staffSystem.update(state, dt)
        economy.update(state, dt)
        rating.update(state)

        // Only does the work when the player has actually changed the map, or
        // when a coaster has not been rated yet.
        val unrated = state.attractions.any {
            it.baseDefinition?.kind == AttractionKind.custom && it.coaster == null && it.trackLength > 0
        }
        if (state.trackedRideGeneration != state.map.generation || unrated) {
            state.trackedRideGeneration = state.map.generation
            state.refreshTrackedRides()
        }
        achievements.update(state)
        TrialSystem.update(state)

        purgeDepartedGuests(state)
    }

    /** Guests that have left are removed, and any stale references to them are cleared out of queues. */
    private fun purgeDepartedGuests(state: GameState) {
        if (state.guests.none { !it.isActive }) return

        val departed = state.guests.filter { !it.isActive }.map { it.id }.toHashSet()
        state.guests.removeAll { it.id in departed }

        for (attraction in state.attractions) {
            attraction.queue.removeAll { it in departed }
            attraction.riders.removeAll { it in departed }
        }
        for (facility in state.facilities) {
            facility.queue.removeAll { it in departed }
            facility.slots.removeAll { it.guestID in departed }
        }
    }
}
