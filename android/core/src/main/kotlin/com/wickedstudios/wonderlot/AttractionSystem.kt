package com.wickedstudios.wonderlot

import java.util.UUID
import kotlin.math.abs

/** Runs ride cycles: boarding from the queue, running, then unloading and applying the experience to each rider. */
class AttractionSystem {

    fun update(state: GameState, dt: Double) {
        val now = state.clock.simTime

        for (attraction in state.attractions) {
            val definition = attraction.definition ?: continue

            when (attraction.phase) {
                RidePhase.loading -> {
                    // A broken ride keeps its phase but takes nobody aboard.
                    board(attraction, definition, state)

                    if (attraction.riders.isEmpty()) {
                        attraction.phaseTimer = 0.0
                        continue
                    }

                    attraction.phaseTimer += dt
                    val full = attraction.riders.size >= definition.capacity
                    if (full || attraction.phaseTimer >= definition.loadDuration) {
                        attraction.phase = RidePhase.running
                        attraction.phaseTimer = 0.0
                    }
                }

                RidePhase.running -> {
                    attraction.phaseTimer += dt
                    if (attraction.phaseTimer >= definition.rideDuration) {
                        unload(attraction, definition, state, now)
                    }
                }
            }
        }
    }

    // region Boarding

    private fun board(attraction: Attraction, definition: AttractionDefinition, state: GameState) {
        if (!attraction.isOperational) return
        val attractionID = attraction.id

        while (attraction.riders.size < definition.capacity && attraction.queue.isNotEmpty()) {
            val guestID = attraction.queue.removeAt(0)
            val guest = state.guest(guestID) ?: continue
            if (!guest.isActive) continue
            val activity = guest.activity
            if (activity !is GuestActivity.Queueing) continue
            val queuedFor = activity.target as? ParkTarget.Ride ?: continue
            if (queuedFor.id != attractionID) continue

            attraction.riders.add(guestID)
            guest.activity = GuestActivity.Engaged(ParkTarget.Ride(attractionID))
        }

        // Keep queue slot indices tidy so the renderer can line guests up.
        for ((slot, guestID) in attraction.queue.withIndex()) {
            state.guest(guestID)?.queueSlot = slot
        }
    }

    // endregion

    // region Unloading

    private fun unload(attraction: Attraction, definition: AttractionDefinition, state: GameState, now: Double) {
        val riders = attraction.riders.toList()
        val attractionID = attraction.id
        val attractionName = attraction.name

        for (guestID in riders) {
            val guest = state.guest(guestID) ?: continue
            val satisfaction = applyRideExperience(guest, definition, attraction, attractionName, state, now)
            attraction.satisfactionSum += satisfaction
            attraction.satisfactionCount += 1
        }

        if (definition.kind == AttractionKind.transport) {
            for (guestID in riders) setDown(guestID, attractionID, state, now)
            state.statistics.transportTripsTotal += riders.size
        }

        attraction.guestsToday += riders.size
        attraction.totalGuests += riders.size
        state.statistics.ridesGivenTotal += riders.size
        attraction.riders = mutableListOf()
        attraction.phase = RidePhase.loading
        attraction.phaseTimer = 0.0

        state.ledger.spend(definition.operatingCostPerCycle, ExpenseCategory.maintenance)
        // Wear and breakdown risk are MaintenanceSystem's business.
    }

    /** Puts a guest off the train at another station on the same railway. */
    private fun setDown(guestID: UUID, stationID: UUID, state: GameState, now: Double) {
        val guest = state.guest(guestID) ?: return
        val destination = state.transportDestination(stationID) ?: return
        val landing = state.map.accessTiles(destination.rect).firstOrNull() ?: return

        guest.tile = landing
        guest.position = landing.centre
        guest.route = mutableListOf()
        guest.nextDecisionAt = now
        guest.think("The train dropped me right by ${destination.name}.", ThoughtMood.positive, now, ThoughtIcon.ride)
    }

    /** Returns the happiness delta the ride produced, which doubles as the attraction's satisfaction score. */
    private fun applyRideExperience(
        guest: Guest,
        definition: AttractionDefinition,
        attraction: Attraction,
        attractionName: String,
        state: GameState,
        now: Double,
    ): Double {
        val thrillMatch = 1 - abs(definition.excitement - guest.personality.thrillPreference) / 100
        val conditionFactor = 0.7 + 0.3 * attraction.condition / 100

        var satisfaction = Balance.happinessRideBase * (0.35 + thrillMatch) * conditionFactor
        if (thrillMatch > 0.85) satisfaction += Balance.happinessThrillMatchBonus

        guest.adjustHappiness(satisfaction)
        guest.nausea = SimMath.clamp(guest.nausea + definition.nausea * 0.45)
        guest.energy = SimMath.clamp(guest.energy - 3)
        guest.ridesRidden += 1
        guest.activity = GuestActivity.Exploring
        guest.nextDecisionAt = now
        guest.queueWaitEstimate = 0.0

        val recent = guest.recentAttractions
        recent.add(attraction.id)
        while (recent.size > 3) recent.removeAt(0)

        val thought = ThoughtCatalog.afterRide(attractionName, satisfaction)
        guest.think(thought.text, thought.mood, now, ThoughtIcon.ride)

        // A famous visitor films the first thing they ride and posts it.
        if (guest.isInfluencer && !guest.hasPosted) {
            guest.hasPosted = true
            PromotionSystem.post(guest, attraction, state, now)
        }

        return satisfaction
    }

    // endregion
}
