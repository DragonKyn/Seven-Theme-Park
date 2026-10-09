package com.wickedstudios.wonderlot

import kotlin.math.abs

/**
 * Rubbish: who is carrying it, where it ends up, and how much guests mind. No
 * bins means guests drop rubbish on the paths, litter makes guests unhappy and
 * drags the park rating down, and only a janitor can reverse it.
 */
class CleanlinessSystem {

    fun update(state: GameState, dt: Double) {
        val now = state.clock.simTime

        // One check for the whole park rather than one per guest.
        val hasUsableBin = state.facilities.any {
            it.definition?.kind == FacilityKind.bin && it.isOpen && !it.isFull
        }

        // Where the guards are standing. Gathered once rather than per guest.
        val guards = state.staff.filter { it.role == StaffRole.security }.map { it.position }

        for (guest in state.guests) {
            if (!guest.isActive) continue
            applyLitterDisgust(guest, state, dt)
            eatPopcorn(guest, state, dt, now)
            if (guest.carryingTrash <= 0) continue
            guest.trashCarriedFor += dt
            val watched = guards.any { SimMath.distance(it, guest.position) <= Balance.securityRadius }
            maybeDropLitter(guest, state, dt, hasUsableBin, watched, now)
        }
    }

    /**
     * Working through a bag of popcorn, and what to do with the empty bag.
     * Somewhere to put it nearby and the guest carries it there like any other
     * rubbish; nowhere near, and it goes on the ground where they are standing.
     */
    private fun eatPopcorn(guest: Guest, state: GameState, dt: Double, now: Double) {
        if (guest.popcornRemaining <= 0) return
        guest.popcornRemaining -= dt
        if (guest.popcornRemaining > 0) return
        guest.popcornRemaining = 0.0

        val tile = guest.tile
        val binNearby = state.facilities.any { facility ->
            if (facility.definition?.kind != FacilityKind.bin || !facility.isOpen || facility.isFull) return@any false
            val distance = abs(facility.origin.x - tile.x) + abs(facility.origin.y - tile.y)
            distance <= Balance.popcornBinRadius
        }

        if (binNearby) {
            guest.carryingTrash = minOf(3, guest.carryingTrash + 1)
            guest.trashCarriedFor = 0.0
        } else {
            state.map.addLitter(Balance.popcornLitter, tile)
            guest.think("No bin near, so the empty bag goes on the ground.", ThoughtMood.negative, now, ThoughtIcon.dirty)
        }
    }

    /** Standing in rubbish is unpleasant, and some guests mind far more. */
    private fun applyLitterDisgust(guest: Guest, state: GameState, dt: Double) {
        val litter = state.map.litter(guest.tile)
        if (litter <= 5) return
        val sensitivity = guest.personality.cleanlinessSensitivity / 100
        val penalty = (litter / 100) * sensitivity * Balance.happinessLitterPenalty * dt
        guest.adjustHappiness(-penalty)
    }

    /**
     * A guest holding rubbish gets steadily more willing to just drop it. Tidy
     * guests hold on far longer, and everyone gives up sooner with no bin to aim for.
     */
    private fun maybeDropLitter(guest: Guest, state: GameState, dt: Double, hasUsableBin: Boolean, watched: Boolean, now: Double) {
        val impatience = minOf(1.0, guest.trashCarriedFor / Balance.trashPatience)
        val tidiness = guest.personality.cleanlinessSensitivity / 100
        var chance = Balance.litterDropChancePerSecond * impatience * (1.6 - tidiness) * dt
        if (!hasUsableBin) chance *= 2.5
        // Nobody drops a wrapper in front of a guard.
        if (watched) chance *= (1 - Balance.securityLitterDeterrence)
        chance *= state.adBoosts.litterFactor

        if (!state.rng.chance(chance)) return

        state.map.addLitter(Balance.litterPerPiece, guest.tile)
        guest.carryingTrash -= 1
        guest.trashCarriedFor = 0.0

        if (!hasUsableBin) {
            guest.think("There's nowhere to put my rubbish.", ThoughtMood.negative, now, ThoughtIcon.dirty)
        }
    }

    companion object {
        /** Called when a guest finishes at a bin. */
        fun disposeOfTrash(guest: Guest, facility: Facility, state: GameState) {
            val carried = guest.carryingTrash
            if (carried <= 0) return
            guest.carryingTrash = 0
            guest.trashCarriedFor = 0.0
            facility.soiling = SimMath.clamp(facility.soiling + Balance.binFillPerItem * carried)
        }
    }
}
