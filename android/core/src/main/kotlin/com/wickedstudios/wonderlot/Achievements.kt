@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale
import java.util.UUID
import kotlin.math.pow

/** What an achievement measures: a counter the simulation keeps or a value read off the park. */
@Serializable
enum class AchievementMetric(val pastTense: String) {
    guestsAdmitted("guests admitted"),
    ridesGiven("rides given"),
    foodSold("meals served"),
    drinksSold("drinks poured"),
    souvenirsSold("souvenirs sold"),
    litterCleaned("pieces of litter swept"),
    repairsCompleted("rides repaired"),
    upgradesBought("upgrades bought"),
    transportTrips("train journeys"),
    attractionCount("rides standing at once"),
    sceneryCount("decorations placed"),
    staffCount("staff on the payroll"),
    guestsInPark("guests in the park at once"),
    parkRating("park rating reached"),
    lifetimeProfit("lifetime profit"),
    cashOnHand("in the bank"),
    daysOperated("days open"),
}

/** One achievement, with a ladder of thresholds rather than a single target. */
class AchievementDefinition(
    val id: String,
    val name: String,
    val summary: String,
    val symbolName: String,
    val metric: AchievementMetric,
    /** One threshold per tier, ascending. */
    val tiers: List<Double>,
    /** Paid for the first tier. Later tiers pay more, steeply. */
    val baseReward: Double,
) {
    val tierCount: Int get() = tiers.size

    fun threshold(tier: Int): Double? = if (tier < 1 || tier > tiers.size) null else tiers[tier - 1]

    fun reward(tier: Int): Double = (baseReward * 2.4.pow(tier - 1) / 50).rounded() * 50

    val isCurrency: Boolean get() = metric == AchievementMetric.lifetimeProfit || metric == AchievementMetric.cashOnHand

    fun formatted(value: Double): String =
        if (isCurrency) CurrencyFormatter.short(value)
        else DecimalFormat("#,##0", DecimalFormatSymbols(Locale.US)).format(value.toLong())

    /** What reaching a tier means in words. */
    fun accomplishment(tier: Int): String {
        val threshold = threshold(tier) ?: return summary
        return "${formatted(threshold)} ${metric.pastTense}"
    }

    companion object {
        /** Roman numerals read as ranks rather than as quantities. */
        fun tierName(tier: Int): String {
            val numerals = listOf("I", "II", "III", "IV", "V", "VI", "VII", "VIII")
            if (tier < 1 || tier > numerals.size) return "$tier"
            return numerals[tier - 1]
        }
    }
}

object AchievementContent {
    private fun a(id: String, name: String, summary: String, symbol: String, metric: AchievementMetric,
                  base: Double, vararg tiers: Double) =
        AchievementDefinition(id, name, summary, symbol, metric, tiers.toList(), base)

    val all: List<AchievementDefinition> = listOf(
        a("achievement.admissions", "Come One, Come All", "Let guests through the gate.",
            "figure.walk.arrival", AchievementMetric.guestsAdmitted, 500.0, 100.0, 500.0, 2_500.0, 10_000.0, 50_000.0, 200_000.0),
        a("achievement.rides", "White Knuckles", "Give guests a ride.",
            "sparkles", AchievementMetric.ridesGiven, 600.0, 100.0, 1_000.0, 5_000.0, 25_000.0, 100_000.0, 400_000.0),
        a("achievement.food", "Everyone Eats", "Serve food from your stalls.",
            "fork.knife", AchievementMetric.foodSold, 450.0, 100.0, 500.0, 2_000.0, 10_000.0, 40_000.0, 150_000.0),
        a("achievement.drinks", "Round of Drinks", "Serve drinks from your kiosks.",
            "cup.and.saucer.fill", AchievementMetric.drinksSold, 400.0, 100.0, 600.0, 2_500.0, 12_000.0, 50_000.0, 180_000.0),
        a("achievement.souvenirs", "Take Me Home", "Sell souvenirs to guests on their way out.",
            "gift.fill", AchievementMetric.souvenirsSold, 550.0, 50.0, 250.0, 1_000.0, 5_000.0, 20_000.0, 75_000.0),
        a("achievement.litter", "Not On My Paths", "Have your janitors sweep up dropped rubbish.",
            "trash.fill", AchievementMetric.litterCleaned, 400.0, 50.0, 300.0, 1_500.0, 7_000.0, 30_000.0, 120_000.0),
        a("achievement.repairs", "Percussive Maintenance", "Get broken rides running again.",
            "wrench.and.screwdriver.fill", AchievementMetric.repairsCompleted, 700.0, 5.0, 25.0, 100.0, 500.0, 2_000.0, 8_000.0),
        a("achievement.upgrades", "Bigger, Faster, Louder", "Buy upgrades for the rides you already own.",
            "arrow.up.circle.fill", AchievementMetric.upgradesBought, 800.0, 3.0, 10.0, 25.0, 60.0, 120.0, 250.0),
        a("achievement.transport", "All Aboard", "Carry guests across the park by train.",
            "tram.fill", AchievementMetric.transportTrips, 700.0, 50.0, 300.0, 1_500.0, 7_000.0, 30_000.0, 120_000.0),
        a("achievement.rides.built", "Ride Empire", "Have rides standing in your park at once.",
            "building.2.fill", AchievementMetric.attractionCount, 900.0, 3.0, 6.0, 10.0, 16.0, 24.0, 32.0),
        a("achievement.scenery", "Landscaper", "Have decorations placed around your park.",
            "tree.fill", AchievementMetric.sceneryCount, 400.0, 10.0, 40.0, 120.0, 300.0, 700.0, 1_500.0),
        a("achievement.staff", "Somebody Has To", "Have employees on the payroll at once.",
            "person.2.badge.gearshape.fill", AchievementMetric.staffCount, 600.0, 3.0, 8.0, 15.0, 25.0, 32.0, 40.0),
        a("achievement.crowd", "Standing Room Only", "Have guests in the park at one time.",
            "person.3.fill", AchievementMetric.guestsInPark, 1_000.0, 25.0, 60.0, 120.0, 190.0, 250.0, 300.0),
        a("achievement.rating", "Worth The Trip", "Push your park rating up.",
            "star.fill", AchievementMetric.parkRating, 1_200.0, 40.0, 55.0, 70.0, 82.0, 90.0, 96.0),
        a("achievement.profit", "In The Black", "Turn a lifetime profit.",
            "chart.line.uptrend.xyaxis", AchievementMetric.lifetimeProfit, 1_000.0, 10_000.0, 50_000.0, 250_000.0, 1_000_000.0, 5_000_000.0, 20_000_000.0),
        a("achievement.cash", "Deep Pockets", "Hold cash in the bank.",
            "banknote.fill", AchievementMetric.cashOnHand, 900.0, 50_000.0, 150_000.0, 500_000.0, 2_000_000.0, 10_000_000.0, 50_000_000.0),
        a("achievement.days", "Season Pass", "Keep the park open, day after day.",
            "calendar", AchievementMetric.daysOperated, 800.0, 5.0, 15.0, 40.0, 100.0, 250.0, 500.0),
    )

    private val byID = all.associateBy { it.id }
    fun definition(id: String): AchievementDefinition? = byID[id]

    /** Every tier of every achievement, for the total shown on the list. */
    val totalTiers: Int get() = all.sumOf { it.tierCount }
}

/** One tier of one achievement, just earned. */
@Serializable
data class AchievementAward(
    val id: UUID = UUID.randomUUID(),
    val definitionID: String,
    val tier: Int,
    val reward: Double,
) {
    val definition: AchievementDefinition? get() = AchievementContent.definition(definitionID)
    val name: String get() = definition?.name ?: "Achievement"
    val symbolName: String get() = definition?.symbolName ?: "rosette"
    val tierName: String get() = AchievementDefinition.tierName(tier)
    val summary: String get() = definition?.summary ?: ""

    /** What this tier actually took, in words. */
    val accomplishment: String get() = definition?.accomplishment(tier) ?: ""

    /** The next rung, so the celebration also points at what to aim for. */
    val nextTarget: String?
        get() {
            val definition = definition ?: return null
            val threshold = definition.threshold(tier + 1) ?: return null
            return "${definition.formatted(threshold)} ${definition.metric.pastTense}"
        }
}

/** One achievement's standing, for the list screen. */
class AchievementProgress(val definition: AchievementDefinition, val earnedTier: Int, val current: Double) {
    val id: String get() = definition.id
    val isComplete: Boolean get() = earnedTier >= definition.tierCount

    /** The threshold being worked towards, or null when every tier is done. */
    val nextThreshold: Double? get() = definition.threshold(earnedTier + 1)

    /** 0-1 towards the next tier, measured from the previous one. */
    val fraction: Double
        get() {
            val next = nextThreshold ?: return 1.0
            val floorValue = definition.threshold(earnedTier) ?: 0.0
            if (next <= floorValue) return 1.0
            return SimMath.clamp((current - floorValue) / (next - floorValue), 0.0, 1.0)
        }

    fun format(value: Double): String = definition.formatted(value)
}

/** Awards achievement tiers and pays out for them. Checked on a slow timer. */
class AchievementSystem {

    fun update(state: GameState) {
        // A park built for nothing has not achieved anything.
        if (!state.mode.earnsAchievements) return
        if (state.clock.simTime < state.nextAchievementCheck) return
        state.nextAchievementCheck = state.clock.simTime + Balance.achievementCheckInterval

        for (definition in AchievementContent.all) award(definition, state)
    }

    /** Awards one tier at most per check. */
    private fun award(definition: AchievementDefinition, state: GameState) {
        val earned = state.achievements[definition.id] ?: 0
        if (earned >= definition.tierCount) return

        val next = earned + 1
        val threshold = definition.threshold(next) ?: return
        if (value(definition.metric, state) < threshold) return

        state.achievements[definition.id] = next

        val reward = definition.reward(next)
        state.ledger.receive(reward, RevenueCategory.other)
        state.pendingAwards.add(AchievementAward(definitionID = definition.id, tier = next, reward = reward))

        state.postAlert(
            "${definition.name} ${AchievementDefinition.tierName(next)} earned. ${CurrencyFormatter.short(reward)} awarded.",
            AlertSeverity.info, "achievement.${definition.id}.$next", cooldown = 0.0,
        )
    }

    /** Current value of a metric. */
    fun value(metric: AchievementMetric, state: GameState): Double = when (metric) {
        AchievementMetric.guestsAdmitted -> state.statistics.guestsAdmittedTotal.toDouble()
        AchievementMetric.ridesGiven -> state.statistics.ridesGivenTotal.toDouble()
        AchievementMetric.foodSold -> state.statistics.foodSoldTotal.toDouble()
        AchievementMetric.drinksSold -> state.statistics.drinksSoldTotal.toDouble()
        AchievementMetric.souvenirsSold -> state.statistics.souvenirsSoldTotal.toDouble()
        AchievementMetric.litterCleaned -> state.statistics.litterCleanedTotal.toDouble()
        AchievementMetric.repairsCompleted -> state.statistics.repairsCompletedTotal.toDouble()
        AchievementMetric.upgradesBought -> state.statistics.upgradesBoughtTotal.toDouble()
        AchievementMetric.transportTrips -> state.statistics.transportTripsTotal.toDouble()
        AchievementMetric.attractionCount -> state.attractions.size.toDouble()
        AchievementMetric.sceneryCount -> state.scenery.size.toDouble()
        AchievementMetric.staffCount -> state.staff.size.toDouble()
        AchievementMetric.guestsInPark -> state.guestCount.toDouble()
        AchievementMetric.parkRating -> state.parkRating
        AchievementMetric.lifetimeProfit -> state.ledger.lifetime.profit
        AchievementMetric.cashOnHand -> state.ledger.cash
        AchievementMetric.daysOperated -> state.clock.day.toDouble()
    }

    companion object {
        /** Progress towards every achievement, for the list screen. */
        fun progress(state: GameState): List<AchievementProgress> {
            val system = AchievementSystem()
            return AchievementContent.all.map { definition ->
                AchievementProgress(definition, state.achievements[definition.id] ?: 0,
                    system.value(definition.metric, state))
            }
        }
    }
}
