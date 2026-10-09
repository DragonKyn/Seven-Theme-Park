@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.util.UUID

/** One thing a trial asks for. Every goal reads a number the park already keeps. */
sealed class TrialGoal {
    data class GuestsInPark(val count: Int) : TrialGoal()
    data class GuestsAdmitted(val count: Int) : TrialGoal()
    data class ParkRating(val value: Double) : TrialGoal()
    data class Cash(val value: Double) : TrialGoal()
    data class Rides(val count: Int) : TrialGoal()
    data class Happiness(val value: Double) : TrialGoal()

    /** A particular thing, built this many times. */
    data class Build(val definitionID: String, val count: Int) : TrialGoal()
    data class CoasterLength(val count: Int) : TrialGoal()
    data class ThrillRide(val value: Double) : TrialGoal()
    data class Shops(val count: Int) : TrialGoal()
    data class Scenery(val count: Int) : TrialGoal()
    data class Staff(val count: Int) : TrialGoal()
    data class Improvements(val count: Int) : TrialGoal()
    data class Prizes(val count: Int) : TrialGoal()

    val target: Double
        get() = when (this) {
            is GuestsInPark -> count.toDouble()
            is GuestsAdmitted -> count.toDouble()
            is Rides -> count.toDouble()
            is CoasterLength -> count.toDouble()
            is Shops -> count.toDouble()
            is Scenery -> count.toDouble()
            is Staff -> count.toDouble()
            is Improvements -> count.toDouble()
            is Prizes -> count.toDouble()
            is Build -> count.toDouble()
            is ParkRating -> value
            is Cash -> value
            is Happiness -> value
            is ThrillRide -> value
        }

    fun current(state: GameState): Double = when (this) {
        is GuestsInPark -> state.guestCount.toDouble()
        is GuestsAdmitted -> state.statistics.guestsAdmittedTotal.toDouble()
        is ParkRating -> state.parkRating
        is Cash -> state.ledger.cash
        is Rides -> state.attractions.size.toDouble()
        is Happiness -> state.averageHappiness
        is Build -> countOf(definitionID, state).toDouble()
        is CoasterLength -> (state.attractions.maxOfOrNull { it.trackLength } ?: 0).toDouble()
        is ThrillRide -> state.attractions.mapNotNull { it.definition?.excitement }.maxOrNull() ?: 0.0
        is Shops -> state.facilities.count { it.definition?.kind?.sellsGoods == true }.toDouble()
        is Scenery -> state.scenery.size.toDouble()
        is Staff -> state.staff.size.toDouble()
        is Improvements -> state.statistics.upgradesBoughtTotal.toDouble()
        is Prizes -> state.statistics.prizesWonTotal.toDouble()
    }

    fun isMet(state: GameState): Boolean = current(state) >= target

    /** What the goal asks for, in a line. */
    val title: String
        get() = when (this) {
            is GuestsInPark -> "$count guests in the park at once"
            is GuestsAdmitted -> "$count guests through the gate"
            is ParkRating -> "Park rating of ${value.toInt()} (${starsFor(value)} stars)"
            is Cash -> "${CurrencyFormatter.short(value)} in the bank"
            is Rides -> "$count rides built"
            is Happiness -> "Guests ${value.toInt()}% happy on average"
            is Build -> {
                val name = nameOf(definitionID)
                if (count == 1) "Build a $name" else "Build $count of the $name"
            }
            is CoasterLength -> "$count tiles of your own coaster track"
            is ThrillRide -> "A ride rated ${value.toInt()} for excitement"
            is Shops -> "$count shops and booths"
            is Scenery -> "$count pieces of scenery"
            is Staff -> "$count staff on the payroll"
            is Improvements -> "$count upgrades and improvements bought"
            is Prizes -> "$count prizes won at your booths"
        }

    /** A short label for a chip. */
    val shortTitle: String
        get() = when (this) {
            is GuestsInPark -> "In park"
            is GuestsAdmitted -> "Admitted"
            is ParkRating -> "Rating"
            is Cash -> "Bank"
            is Rides -> "Rides"
            is Happiness -> "Happy"
            is Build -> "Built"
            is CoasterLength -> "Track"
            is ThrillRide -> "Thrill"
            is Shops -> "Shops"
            is Scenery -> "Scenery"
            is Staff -> "Staff"
            is Improvements -> "Upgrades"
            is Prizes -> "Prizes"
        }

    val symbolName: String
        get() = when (this) {
            is GuestsInPark -> "person.3.fill"
            is GuestsAdmitted -> "ticket.fill"
            is ParkRating -> "star.fill"
            is Cash -> "banknote.fill"
            is Rides -> "sparkles"
            is Happiness -> "face.smiling"
            is Build -> "hammer.fill"
            is CoasterLength -> "point.topleft.down.curvedto.point.bottomright.up"
            is ThrillRide -> "bolt.fill"
            is Shops -> "cart.fill"
            is Scenery -> "tree.fill"
            is Staff -> "person.2.badge.gearshape.fill"
            is Improvements -> "star.circle.fill"
            is Prizes -> "gift.fill"
        }

    fun format(value: Double): String = when (this) {
        is Cash -> CurrencyFormatter.compact(value)
        is Happiness -> "${value.toInt()}%"
        else -> "${value.toInt()}"
    }

    companion object {
        /** How many of one catalogue entry stand in the park, wherever it lives. */
        private fun countOf(definitionID: String, state: GameState): Int =
            state.attractions.count { it.definitionID == definitionID } +
                state.facilities.count { it.definitionID == definitionID } +
                state.scenery.count { it.definitionID == definitionID }

        /** What the catalogue calls it, for the goal to read as a sentence. */
        fun nameOf(definitionID: String): String =
            GameContent.attraction(definitionID)?.displayName
                ?: GameContent.facility(definitionID)?.displayName
                ?: GameContent.scenery(definitionID)?.displayName
                ?: "it"

        /** Mirrors GameState.starRating. */
        private fun starsFor(rating: Double): Int = when {
            rating < 20 -> 1
            rating < 40 -> 2
            rating < 60 -> 3
            rating < 80 -> 4
            else -> 5
        }
    }
}

/** What finishing a trial earns. */
data class TrialMedal(val name: String, val symbolName: String)

/** One rung of the ladder. */
data class TrialDefinition(
    val id: String,
    /** Position on the ladder, from 1. */
    val number: Int,
    val title: String,
    val briefing: String,
    val mapID: String,
    val startingCash: Double,
    /** Every goal has to be met, all at once, by the end of this day. */
    val dayLimit: Int,
    val goals: List<TrialGoal>,
    /** The most the gate may charge, when the trial caps it. */
    val maxAdmission: Double? = null,
    val medal: TrialMedal,
) {
    val map: MapBlueprint get() = MapCatalogue.blueprint(mapID) ?: MapCatalogue.openMeadow
}

/** The ladder. Numbers here are a first pass at difficulty and the one place to retune it. */
object TrialContent {

    fun definition(id: String): TrialDefinition? = all.firstOrNull { it.id == id }

    val all: List<TrialDefinition> = listOf(
        TrialDefinition("trial.01", 1, "Opening Day",
            "An empty meadow and a gate. Get three rides running and a crowd through the door before the week is out.",
            MapCatalogue.openMeadowID, 25_000.0, 5,
            listOf(TrialGoal.Rides(3), TrialGoal.GuestsInPark(30)),
            medal = TrialMedal("Ribbon Cutter", "scissors")),

        TrialDefinition("trial.02", 2, "In the Black",
            "Less to start with, and the owners want their money back. Build cheaply, charge sensibly, and grow the balance.",
            MapCatalogue.openMeadowID, 20_000.0, 7,
            listOf(TrialGoal.Cash(30_000.0), TrialGoal.Shops(3)),
            medal = TrialMedal("Bookkeeper", "banknote.fill")),

        TrialDefinition("trial.03", 3, "Three Stars in the Pines",
            "The land comes in clearings between the trees. Link them up and give guests a park worth three stars.",
            "map.pinewood", 22_000.0, 8,
            listOf(TrialGoal.ParkRating(40.0), TrialGoal.GuestsAdmitted(150), TrialGoal.Scenery(12)),
            medal = TrialMedal("Three-Star Host", "star.circle.fill")),

        TrialDefinition("trial.04", 4, "Island Hopping",
            "The best ground is out on the islands. Bridge the lake and fill them with rides.",
            "map.willowlake", 25_000.0, 10,
            listOf(TrialGoal.Rides(6), TrialGoal.GuestsInPark(50), TrialGoal.Build("ride.ferriswheel", 1)),
            medal = TrialMedal("Bridge Builder", "water.waves")),

        TrialDefinition("trial.05", 5, "The Long Pier",
            "Five tiles wide and a long walk to the end. Every square counts, and so does every step a guest takes.",
            "map.longpier", 20_000.0, 10,
            listOf(TrialGoal.Cash(35_000.0), TrialGoal.ParkRating(45.0), TrialGoal.Staff(5)),
            medal = TrialMedal("Pier Master", "sailboat.fill")),

        TrialDefinition("trial.06", 6, "Shoestring",
            "Ten thousand and a river in the way. Keep costs down and keep the crowd happy while it grows.",
            "map.riverbend", 10_000.0, 10,
            listOf(TrialGoal.GuestsAdmitted(400), TrialGoal.Happiness(65.0), TrialGoal.Prizes(60)),
            medal = TrialMedal("Penny Pincher", "dollarsign.circle.fill")),

        TrialDefinition("trial.07", 7, "Canyon Run",
            "Sheer rock either side and a stream down the middle. Make the valley worth four stars.",
            "map.canyon", 22_000.0, 12,
            listOf(TrialGoal.ParkRating(60.0), TrialGoal.GuestsInPark(60), TrialGoal.CoasterLength(40)),
            medal = TrialMedal("Canyon Runner", "mountain.2.fill")),

        TrialDefinition("trial.08", 8, "Crowd Control",
            "Two plateaus and one narrow pass between them. Hold a big crowd without letting the queues sour it.",
            "map.twinplateaus", 22_000.0, 12,
            listOf(TrialGoal.GuestsInPark(80), TrialGoal.Happiness(72.0), TrialGoal.Improvements(8)),
            medal = TrialMedal("Crowd Tamer", "person.3.fill")),

        TrialDefinition("trial.09", 9, "Harbour Lights",
            "The council caps the gate at twenty dollars. The money has to come from inside the park.",
            "map.harbour", 18_000.0, 14,
            listOf(TrialGoal.Cash(60_000.0), TrialGoal.ParkRating(65.0), TrialGoal.Build("ride.wavepool", 1)),
            maxAdmission = 20.0,
            medal = TrialMedal("Harbour Master", "light.beacon.max.fill")),

        TrialDefinition("trial.10", 10, "Wonder of the World",
            "A lake, a small budget and the bar only the best parks reach. Five stars, a full park and a fortune in the bank.",
            "map.willowlake", 12_000.0, 18,
            listOf(TrialGoal.ParkRating(80.0), TrialGoal.GuestsInPark(90), TrialGoal.Cash(80_000.0),
                TrialGoal.Build("ride.bigcoaster", 1)),
            medal = TrialMedal("Wonder Maker", "crown.fill")),

        // The back five. Each asks for everything the one before it did and
        // takes something away as well: land, budget, the gate, or time.

        TrialDefinition("trial.11", 11, "Archipelago",
            "The Wonder of the World again, only now the land is a scatter of islands. Every bridge comes out of the budget.",
            "map.archipelago", 12_000.0, 18,
            listOf(TrialGoal.ParkRating(80.0), TrialGoal.GuestsInPark(90), TrialGoal.Cash(90_000.0),
                TrialGoal.Build("ride.logflume", 2)),
            medal = TrialMedal("Island Magnate", "beach.umbrella.fill")),

        TrialDefinition("trial.12", 12, "Pay What You Can",
            "The gate is capped at ten dollars, so the park has to earn its keep from food, shops and games. Keep people happy enough to spend.",
            "map.pinewood", 10_000.0, 18,
            listOf(TrialGoal.Cash(70_000.0), TrialGoal.ParkRating(82.0), TrialGoal.Happiness(75.0), TrialGoal.Improvements(20)),
            maxAdmission = 10.0,
            medal = TrialMedal("Open Door", "door.left.hand.open")),

        TrialDefinition("trial.13", 13, "The Long Haul",
            "Back on the pier with less money and a far bigger crowd to move. Fifteen hundred people have to make that walk.",
            "map.longpier", 10_000.0, 20,
            listOf(TrialGoal.GuestsAdmitted(1_500), TrialGoal.ParkRating(84.0), TrialGoal.Cash(100_000.0),
                TrialGoal.Build("transport.station", 2)),
            medal = TrialMedal("Marathon Maker", "figure.walk")),

        TrialDefinition("trial.14", 14, "Switchback",
            "One valley doubling back through solid rock, a capped gate and eight thousand to start. Pack the bends without souring the crowd.",
            "map.switchback", 8_000.0, 20,
            listOf(TrialGoal.ParkRating(86.0), TrialGoal.GuestsInPark(92), TrialGoal.Happiness(78.0),
                TrialGoal.Cash(100_000.0), TrialGoal.ThrillRide(85.0)),
            maxAdmission = 25.0,
            medal = TrialMedal("Ridge Runner", "arrow.triangle.turn.up.right.diamond.fill")),

        TrialDefinition("trial.15", 15, "The Grand Finale",
            "Everything at once, in a canyon, on six thousand dollars and a twenty dollar gate. The last rung, and the park that proves you have learned all fourteen before it.",
            "map.canyon", 6_000.0, 24,
            listOf(TrialGoal.ParkRating(88.0), TrialGoal.GuestsInPark(95), TrialGoal.Happiness(80.0),
                TrialGoal.Cash(120_000.0), TrialGoal.Rides(12), TrialGoal.CoasterLength(70)),
            maxAdmission = 20.0,
            medal = TrialMedal("Legend of the Lot", "trophy.fill")),
    )
}

/** How a trial stands. */
@Serializable
enum class TrialOutcome { inProgress, won, lost }

/** The end of a trial, waiting to be shown to the player. */
@Serializable
data class TrialResult(
    val id: UUID = UUID.randomUUID(),
    val trialID: String = "",
    val won: Boolean = false,
    /** The day it was decided on. */
    val day: Int = 1,
) {
    val trial: TrialDefinition? get() = TrialContent.definition(trialID)
}

/** A result together with what it means for the ladder, which only the controller knows. */
data class TrialResultReport(val result: TrialResult, val isFirstWin: Boolean, val nextTrial: TrialDefinition?) {
    val id: UUID get() = result.id
}

/**
 * Watches a trial park for the moment it is won, or runs out of time. A trial
 * is won the first moment every goal is met together; it is lost once the last
 * day has closed with any goal still short. After either, the park carries on.
 */
object TrialSystem {
    /** Seconds between checks. */
    const val checkInterval = 2.0

    fun update(state: GameState) {
        val trial = state.trial ?: return
        if (state.trialOutcome != TrialOutcome.inProgress) return
        if (state.clock.simTime < state.nextTrialCheck) return
        state.nextTrialCheck = state.clock.simTime + checkInterval

        if (trial.goals.all { it.isMet(state) }) {
            finish(trial, true, state)
        } else if (state.clock.day > trial.dayLimit) {
            finish(trial, false, state)
        }
    }

    private fun finish(trial: TrialDefinition, won: Boolean, state: GameState) {
        state.trialOutcome = if (won) TrialOutcome.won else TrialOutcome.lost
        val day = minOf(state.clock.day, trial.dayLimit)
        state.trialDecidedDay = day
        state.pendingTrialResult = TrialResult(trialID = trial.id, won = won, day = day)
        state.postAlert(
            if (won) "${trial.title} complete on day $day."
            else "Time is up on ${trial.title}. The park is yours to keep playing.",
            if (won) AlertSeverity.info else AlertSeverity.warning, "trial.result", cooldown = 0.0,
        )
    }
}
