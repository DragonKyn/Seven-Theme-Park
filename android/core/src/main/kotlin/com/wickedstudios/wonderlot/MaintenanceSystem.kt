package com.wickedstudios.wonderlot

/**
 * Wear, inspections and breakdowns. Condition falls only while a ride is
 * running; overdue inspections double the breakdown hazard.
 */
class MaintenanceSystem {

    fun update(state: GameState, dt: Double) {
        for (attraction in state.attractions) {
            attraction.timeSinceInspection += dt

            val definition = attraction.definition ?: continue
            if (!attraction.isOperational || attraction.phase != RidePhase.running) continue

            attraction.condition = SimMath.clamp(
                attraction.condition - definition.maintenanceRate * state.perks.wearFactor * state.adBoosts.wearFactor * dt,
            )

            rollForBreakdown(attraction, definition, state, dt)
        }
    }

    private fun rollForBreakdown(attraction: Attraction, definition: AttractionDefinition, state: GameState, dt: Double) {
        val missingCondition = 1 - attraction.condition / 100
        if (missingCondition <= 0.02) return

        val cycleLength = maxOf(1.0, definition.loadDuration + definition.rideDuration)
        val overdue = if (attraction.isInspectionOverdue) Balance.overdueInspectionPenalty else 1.0
        // A per-second hazard so the result is independent of tick rate.
        val hazardPerSecond = Balance.breakdownChanceAtZeroCondition *
            missingCondition * missingCondition * overdue / cycleLength *
            state.perks.breakdownFactor * state.adBoosts.breakdownFactor

        if (!state.rng.chance(hazardPerSecond * dt)) return
        breakDown(attraction, state)
    }

    /** Closes the ride, empties it, and disappoints everyone involved. */
    private fun breakDown(attraction: Attraction, state: GameState) {
        val name = attraction.name
        val attractionID = attraction.id

        attraction.isBroken = true
        attraction.totalBreakdowns += 1
        attraction.phase = RidePhase.loading
        attraction.phaseTimer = 0.0

        evacuate(attraction, state, "$name broke down while I was on it!", "All that queuing and $name broke down.")

        state.statistics.breakdownsTotal += 1
        state.postAlert("$name has broken down.", AlertSeverity.critical, "breakdown.$attractionID",
            ParkTarget.Ride(attractionID), 60.0)

        if (state.staffCount(StaffRole.mechanic) == 0) {
            state.postAlert("You have no mechanics. Broken rides will stay closed.", AlertSeverity.critical,
                "staff.mechanic.missing", cooldown = 300.0)
        }
    }

    companion object {
        /**
         * Empties a ride of everybody on it and everybody waiting for it.
         * Shared with the safety inspector, which shuts rides without breaking them.
         */
        fun evacuate(attraction: Attraction, state: GameState, riderMessage: String, queueMessage: String) {
            val now = state.clock.simTime

            // Riders are let off mid-experience, which they take badly.
            val riders = attraction.riders.toList()
            attraction.riders = mutableListOf()
            for (guestID in riders) {
                val guest = state.guest(guestID) ?: continue
                guest.adjustHappiness(-Balance.happinessRideBrokeDown)
                guest.activity = GuestActivity.Exploring
                guest.nextDecisionAt = now
                guest.think(riderMessage, ThoughtMood.negative, now)
            }

            // The queue is cleared, as promised on the tin.
            val queued = attraction.queue.toList()
            attraction.queue = mutableListOf()
            for (guestID in queued) {
                val guest = state.guest(guestID) ?: continue
                guest.adjustHappiness(-Balance.happinessQueueAbandonPenalty)
                guest.activity = GuestActivity.Exploring
                guest.nextDecisionAt = now
                guest.think(queueMessage, ThoughtMood.negative, now)
            }
        }

        fun completeRepair(attraction: Attraction, state: GameState) {
            state.statistics.repairsCompletedTotal += 1
            attraction.isBroken = false
            // A repair is what lifts an impound too.
            attraction.isImpounded = false
            attraction.condition = maxOf(attraction.condition, Balance.repairedCondition)
            attraction.timeSinceInspection = 0.0
            attraction.phase = RidePhase.loading
            attraction.phaseTimer = 0.0

            state.postAlert("${attraction.name} is running again.", AlertSeverity.info, "repaired.${attraction.id}",
                ParkTarget.Ride(attraction.id), 60.0)
        }

        fun completeInspection(attraction: Attraction, state: GameState) {
            attraction.timeSinceInspection = 0.0
            attraction.condition = SimMath.clamp(attraction.condition + Balance.inspectionConditionBonus)
        }
    }
}
