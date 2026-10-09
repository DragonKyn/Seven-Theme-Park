@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.util.UUID

/** What one disruptive visitor did, and how their visit ended. */
@Serializable
data class EjectionReport(
    val id: UUID = UUID.randomUUID(),
    val guestName: String = "A visitor",
    /** Null when nobody removed them and they left in their own time. */
    val guardName: String? = null,
    /** Pieces of rubbish they left behind. */
    val litterDropped: Int = 0,
    /** Park minutes they were in the park. */
    val minutes: Double = 0.0,
) {
    val wasEscorted: Boolean get() = guardName != null

    val detail: String
        get() = if (wasEscorted) "The guests around them settled as soon as they were off the premises."
        else "Nobody was on hand to step in. A guard on duty would have seen them off."

    val durationLabel: String
        get() = if (minutes >= 60) "${(minutes / 60).toInt()}h" else "${minutes.toInt()} min"
}

/**
 * The park's occasional nuisance: drops rubbish faster than a janitor can
 * sweep it, sours the mood of everybody near them, and shoves people out of
 * queues. A park with a security guard has them walked out.
 */
object TroublemakerSystem {

    /** Whether now is a moment for one to walk in. */
    fun shouldAdmit(state: GameState): Boolean {
        if (state.guestCount < Balance.troublemakerMinimumGuests) return false
        if (state.clock.simTime < state.nextTroublemakerAt) return false
        return state.troublemakerIndex == null
    }

    /** Whether security have clocked them yet; the grace period lets them make a mess worth clearing up. */
    fun isNoticed(guest: Guest, simTime: Double): Boolean {
        val arrived = guest.troublemakerUntil - Balance.troublemakerStayLength
        return simTime >= arrived + Balance.troublemakerGracePeriod
    }

    fun scheduleNext(state: GameState) {
        val days = state.rng.double(Balance.troublemakerGapDays)
        state.nextTroublemakerAt = state.clock.simTime + days * Balance.dayLength
    }

    /**
     * Turns a freshly admitted guest into the nuisance. The look is made
     * entirely of appearance values that already exist, so cached guest
     * textures cannot collide.
     */
    fun mark(guest: Guest, state: GameState, now: Double) {
        guest.isTroublemaker = true
        guest.troublemakerUntil = now + Balance.troublemakerStayLength
        guest.appearance = GuestAppearance(
            shirt = ParkColour.charcoal, hair = guest.appearance.hair, skin = guest.appearance.skin,
            hat = GuestAppearance.HatStyle.hood, bottoms = ParkColour.charcoal,
            pattern = GuestAppearance.ShirtPattern.vest, accessory = GuestAppearance.Accessory.sunglasses,
        )

        if (state.staffCount(StaffRole.security) == 0) {
            state.postAlert("Somebody is causing trouble and you have no security.", AlertSeverity.warning,
                "staff.security.missing", cooldown = 300.0)
        }
    }

    fun update(state: GameState, dt: Double) {
        val index = state.troublemakerIndex ?: return
        val now = state.clock.simTime
        val nuisance = state.guests[index]
        val centre = nuisance.position

        // Everybody nearby has a worse time of it.
        val drain = Balance.troublemakerHappinessPerSecond * dt
        for (other in state.guests) {
            if (other === nuisance || !other.isActive) continue
            if (SimMath.distance(other.position, centre) > Balance.troublemakerRadius) continue
            other.adjustHappiness(-drain)
        }

        if (state.rng.chance(Balance.troublemakerLitterChancePerSecond * dt)) {
            state.map.addLitter(Balance.litterPerPiece, nuisance.tile)
            nuisance.troublemakerLitter += 1
        }

        if (state.rng.chance(Balance.troublemakerQueueChancePerSecond * dt)) {
            barge(centre, state, now)
        }

        if (now >= nuisance.troublemakerUntil) {
            remove(index, state, null)
        }
    }

    /** Pushes somebody out of a queue they had been waiting in. */
    private fun barge(centre: Vec2, state: GameState, now: Double) {
        for (attraction in state.attractions) {
            if (attraction.queue.isEmpty()) continue
            if (SimMath.distance(attraction.origin.centre, centre) > Balance.troublemakerQueueRadius) continue
            val victimID = attraction.queue.firstOrNull() ?: continue
            val victim = state.guest(victimID) ?: continue

            GuestAISystem.removeFromQueue(victimID, ParkTarget.Ride(attraction.id), state)
            victim.activity = GuestActivity.Exploring
            victim.route = mutableListOf()
            victim.nextDecisionAt = now
            victim.adjustHappiness(-Balance.troublemakerQueuePenalty)
            victim.think("Someone shoved in and pushed me out of the queue.", ThoughtMood.negative, now, ThoughtIcon.queue)
            return
        }
    }

    /**
     * Ends the visit, either because a guard caught up with them or because
     * they had their afternoon and left. Deliberately not routed through the
     * ordinary departure, which files a reason against the park's complaints.
     */
    fun remove(guestIndex: Int, state: GameState, guardName: String?) {
        val guest = state.guests[guestIndex]
        guest.isTroublemaker = false
        guest.activity = GuestActivity.Departed
        guest.route = mutableListOf()

        state.pendingEjections.add(
            EjectionReport(guestName = guest.name, guardName = guardName,
                litterDropped = guest.troublemakerLitter, minutes = guest.timeInPark),
        )

        if (guardName != null) {
            state.statistics.troublemakersEjectedTotal += 1
            // Relief for everybody who watched it happen.
            for (other in state.guests) {
                if (!other.isActive) continue
                if (SimMath.distance(other.position, guest.position) > Balance.escortReliefRadius) continue
                other.adjustHappiness(Balance.escortHappinessRelief)
            }
            state.postAlert("Security escorted ${guest.name} out of the park.", AlertSeverity.info, "escort", cooldown = 30.0)
        } else {
            state.statistics.troublemakersEscapedTotal += 1
            state.postAlert("${guest.name} caused trouble all afternoon and walked out unchallenged.",
                AlertSeverity.warning, "escort.missed", cooldown = 120.0)
        }
    }
}
