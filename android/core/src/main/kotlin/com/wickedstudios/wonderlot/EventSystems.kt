@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.util.UUID

private fun durationLabel(minutes: Double): String =
    if (minutes >= 60) "${(minutes / 60).toInt()}h" else "${minutes.toInt()} min"

/** A number that applies to the park for a while and then stops. */
@Serializable
data class TimedModifier(var amount: Double = 0.0, var endsAt: Double = 0.0) {
    /** What it is worth right now, which is nothing once it has run out. */
    fun value(simTime: Double): Double = if (simTime < endsAt) amount else 0.0

    /** Park minutes left, or null when it is over. */
    fun minutesLeft(simTime: Double): Double? = if (simTime < endsAt) endsAt - simTime else null

    companion object {
        val inactive get() = TimedModifier()

        /** Starts one running from now. */
        fun lasting(minutes: Double, worth: Double, from: Double) = TimedModifier(worth, from + minutes)
    }
}

// region Reports

/** A review left by a visitor who never said who they were. */
@Serializable
data class CriticReview(
    val id: UUID = UUID.randomUUID(),
    val criticName: String = "A visitor",
    /** One to five. */
    val stars: Int = 3,
    val headline: String = "A day at the park",
    val praise: String = "",
    val criticism: String = "",
    /** Rating points the review moves the park by, and the park minutes it holds for. */
    val ratingSwing: Double = 0.0,
    val minutes: Double = 0.0,
) {
    val isGood: Boolean get() = ratingSwing > 0
    val isBad: Boolean get() = ratingSwing < 0

    /** Five characters, so the score reads at a glance. */
    val starLine: String get() = "★".repeat(stars) + "☆".repeat(5 - stars)

    /** The line under the headline: whichever remark carries the verdict. */
    val detail: String
        get() {
            if (isBad && criticism.isNotEmpty()) return "\"$criticism\""
            if (praise.isNotEmpty()) return "\"$praise\""
            if (criticism.isNotEmpty()) return "\"$criticism\""
            return "They did not say much else."
        }

    val durationLabel: String get() = durationLabel(minutes)
}

/** A regulator's verdict on one ride. */
@Serializable
data class InspectionReport(
    val id: UUID = UUID.randomUUID(),
    val rideName: String = "a ride",
    val condition: Double = 0.0,
    val passed: Boolean = false,
    val fine: Double = 0.0,
    val bonus: Double = 0.0,
    val minutes: Double = 0.0,
) {
    val headline: String get() = rideName
    val detail: String
        get() = if (passed) "passed its safety inspection" else "failed its safety inspection and has been shut"
    val durationLabel: String get() = durationLabel(minutes)
}

/** One post about the park, and what it did for the gate. */
@Serializable
data class PromotionPost(
    val id: UUID = UUID.randomUUID(),
    val guestName: String = "A visitor",
    val rideName: String = "a ride",
    /** Extra arrivals as a share: 0.3 is thirty per cent more people. */
    val boost: Double = 0.0,
    val minutes: Double = 0.0,
) {
    val durationLabel: String get() = durationLabel(minutes)
}

/** A group that arrived together, and who they were. */
@Serializable
data class TourBusReport(
    val id: UUID = UUID.randomUUID(),
    val groupName: String = "A group",
    val count: Int = 0,
    val childCount: Int = 0,
) {
    val headline: String get() = "$count arrivals in one go"
    val detail: String
        get() = if (childCount * 2 >= count) {
            "A school party is through the gate. Your queues are about to find out."
        } else {
            "A day trip is through the gate. Your queues are about to find out."
        }
}

// endregion

/** The park's anonymous reviewers. A critic looks like everybody else; the verdict lands on the park as it was. */
object CriticSystem {

    /** Whether now is a moment for one to walk in unannounced. */
    fun shouldAdmit(state: GameState): Boolean {
        if (state.attractions.size < Balance.criticMinimumRides) return false
        if (state.clock.simTime < state.nextCriticAt) return false
        return state.guests.none { it.isActive && it.isCritic }
    }

    fun scheduleNext(state: GameState) {
        val days = state.rng.double(Balance.criticGapDays)
        state.nextCriticAt = state.clock.simTime + days * Balance.dayLength
    }

    /** Called as a critic leaves the park, which is the only moment their opinion is complete. */
    fun publish(guestIndex: Int, state: GameState) {
        val guest = state.guests[guestIndex]
        val now = state.clock.simTime
        guest.isCritic = false

        val stars = stars(guest)
        val swing = ratingSwing(stars)

        if (swing > 0) {
            state.reviewRating = TimedModifier.lasting(Balance.criticEffectMinutes, swing, now)
            state.reviewArrivals = TimedModifier.lasting(Balance.criticEffectMinutes, Balance.criticPraiseArrivals, now)
            state.statistics.goodReviewsTotal += 1
        } else if (swing < 0) {
            state.reviewRating = TimedModifier.lasting(Balance.criticEffectMinutes, swing, now)
            state.reviewArrivals = TimedModifier.inactive
            state.statistics.badReviewsTotal += 1
        }

        val review = CriticReview(
            criticName = guest.name,
            stars = stars,
            headline = headline(stars),
            praise = remark(ThoughtMood.positive, guest),
            criticism = remark(ThoughtMood.negative, guest),
            ratingSwing = swing,
            minutes = if (swing == 0.0) 0.0 else Balance.criticEffectMinutes,
        )
        state.pendingReviews.add(review)

        state.postAlert(
            "${guest.name} turned out to be a reviewer, and gave the park $stars out of 5.",
            if (swing < 0) AlertSeverity.warning else AlertSeverity.info, "review", cooldown = 60.0,
        )
    }

    /** What the visit was worth, out of five. Happiness carries it; the adjustments are what a reviewer would single out. */
    private fun stars(guest: Guest): Int {
        var score = guest.happiness
        if (guest.ridesRidden == 0) score -= 25
        if (guest.purchases > 0) score += 5
        val reason = guest.departureReason
        if (reason != null && reason != DepartureReason.satisfied.text) score -= 15

        return when {
            score >= 85 -> 5
            score >= Balance.criticPraiseHappiness -> 4
            score >= 55 -> 3
            score >= Balance.criticComplaintHappiness -> 2
            else -> 1
        }
    }

    private fun ratingSwing(stars: Int): Double = when (stars) {
        5 -> Balance.criticPraiseRating
        4 -> Balance.criticPraiseRating * 0.6
        2 -> -Balance.criticComplaintRating * 0.6
        1 -> -Balance.criticComplaintRating
        // Three stars moves nothing, which is a real verdict.
        else -> 0.0
    }

    /** The most recent thing they thought in the given mood, quoted back. */
    private fun remark(mood: ThoughtMood, guest: Guest): String =
        guest.thoughts.lastOrNull { it.mood == mood }?.text ?: ""

    private fun headline(stars: Int): String = when (stars) {
        5 -> "One of the best days out anywhere"
        4 -> "Well worth the trip"
        3 -> "A perfectly fine afternoon"
        2 -> "Hard to recommend as it stands"
        else -> "I would not go back"
    }
}

/** The park's safety inspections: the regulator names a ride, and gives the park an hour to get a mechanic to it. */
object InspectionSystem {

    fun update(state: GameState) {
        val now = state.clock.simTime

        // Somebody is already here: the only question is whether they have seen enough.
        val rideID = state.inspectingRideID
        if (rideID != null) {
            if (now < state.inspectionVerdictAt) return
            deliverVerdict(rideID, state, now)
            return
        }

        if (state.attractions.size < Balance.safetyInspectionMinimumRides || now < state.nextSafetyInspectionAt) return
        arrive(state, now)
    }

    fun scheduleNext(state: GameState) {
        val days = state.rng.double(Balance.safetyInspectionGapDays)
        state.nextSafetyInspectionAt = state.clock.simTime + days * Balance.dayLength
    }

    private fun arrive(state: GameState, now: Double) {
        // The worst ride in the park, by condition.
        val worst = state.attractions.minByOrNull { it.condition }
        if (worst == null) {
            scheduleNext(state)
            return
        }

        state.inspectingRideID = worst.id
        state.inspectionVerdictAt = now + Balance.safetyInspectionWarning
        state.postAlert("A safety inspector is looking over ${worst.name}.", AlertSeverity.warning,
            "inspection", ParkTarget.Ride(worst.id), 60.0)
    }

    private fun deliverVerdict(rideID: UUID, state: GameState, now: Double) {
        state.inspectingRideID = null
        scheduleNext(state)

        // The ride was demolished while they were looking at it, which is one way of passing an inspection.
        val ride = state.attraction(rideID) ?: return

        val passed = !ride.isBroken && ride.condition >= Balance.safetyInspectionPassCondition
        var reportedCondition = ride.condition

        if (passed) {
            state.inspectionBonus = TimedModifier.lasting(Balance.safetyInspectionBonusMinutes,
                Balance.safetyInspectionRatingBonus, now)
            ride.timeSinceInspection = 0.0
            state.statistics.safetyInspectionsPassedTotal += 1
            state.postAlert("${ride.name} passed its safety inspection.", AlertSeverity.info,
                "inspection.result", ParkTarget.Ride(rideID), 60.0)
        } else {
            state.ledger.spend(Balance.safetyInspectionFine, ExpenseCategory.maintenance)
            ride.isImpounded = true
            ride.condition = minOf(ride.condition, Balance.safetyInspectionFailedCondition)
            ride.timeSinceInspection = Balance.inspectionInterval
            ride.phase = RidePhase.loading
            ride.phaseTimer = 0.0
            reportedCondition = ride.condition
            MaintenanceSystem.evacuate(ride, state, "They stopped ${ride.name} with me still on it.",
                "All that queuing and they shut ${ride.name} down.")
            state.statistics.safetyInspectionsFailedTotal += 1
            state.postAlert("${ride.name} failed its safety inspection and has been shut. A mechanic will have to put it right.",
                AlertSeverity.critical, "inspection.result", ParkTarget.Ride(rideID), 60.0)

            if (state.staffCount(StaffRole.mechanic) == 0) {
                state.postAlert("You have no mechanics. A ride an inspector has shut stays shut.",
                    AlertSeverity.critical, "staff.mechanic.missing", cooldown = 300.0)
            }
        }

        state.pendingInspections.add(
            InspectionReport(
                rideName = ride.name,
                condition = reportedCondition,
                passed = passed,
                fine = if (passed) 0.0 else Balance.safetyInspectionFine,
                bonus = if (passed) Balance.safetyInspectionRatingBonus else 0.0,
                minutes = if (passed) Balance.safetyInspectionBonusMinutes else 0.0,
            ),
        )
    }
}

/** The park's occasional famous visitor: rides something, posts about it, and the gate gets a rush. */
object PromotionSystem {

    fun shouldAdmitInfluencer(state: GameState): Boolean {
        if (state.attractions.size < Balance.influencerMinimumRides) return false
        if (state.clock.simTime < state.nextInfluencerAt) return false
        return state.guests.none { it.isActive && it.isInfluencer }
    }

    fun scheduleNext(state: GameState) {
        val days = state.rng.double(Balance.influencerGapDays)
        state.nextInfluencerAt = state.clock.simTime + days * Balance.dayLength
    }

    /** Called when a famous visitor gets off a ride. The boost scales with how exciting the ride was. */
    fun post(guest: Guest, attraction: Attraction, state: GameState, now: Double) {
        val excitement = attraction.definition?.excitement ?: 40.0
        val boost = Balance.promotionBoostFloor + (excitement / 100) * Balance.promotionBoostRange
        val minutes = Balance.promotionMinutes

        state.promotionBoost = boost
        // One sim-second is one park minute, so the duration goes on as it is.
        state.promotionEndsAt = now + minutes

        val post = PromotionPost(guestName = guest.name, rideName = attraction.name, boost = boost, minutes = minutes)
        state.pendingPromotions.add(post)
        state.statistics.promotionsTotal += 1

        guest.think("Posting this. My followers are going to love ${attraction.name}.", ThoughtMood.positive, now, ThoughtIcon.ride)

        state.postAlert("${post.guestName} posted about ${attraction.name}. Expect a rush at the gate.",
            AlertSeverity.info, "promotion", ParkTarget.Ride(attraction.id), 60.0)
    }
}

/** Tour buses pulling up at the gate: twenty people in one second rather than over ten minutes. */
object TourBusSystem {

    /** Whether one is due. Booked against the clock rather than rolled for. */
    fun shouldArrive(state: GameState): Boolean {
        if (state.attractions.size < Balance.tourBusMinimumRides) return false
        return state.clock.simTime >= state.nextTourBusAt
    }

    fun scheduleNext(state: GameState) {
        val days = state.rng.double(Balance.tourBusGapDays)
        state.nextTourBusAt = state.clock.simTime + days * Balance.dayLength
    }
}
