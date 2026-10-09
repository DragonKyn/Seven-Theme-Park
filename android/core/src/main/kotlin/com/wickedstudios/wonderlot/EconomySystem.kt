package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlin.math.abs

/** Recurring costs, the daily accounting rollover, and money-related alerts. */
class EconomySystem {

    fun update(state: GameState, dt: Double) {
        chargeUtilities(state, dt)
        sampleLedger(state)
        checkDayRollover(state)
        checkWarnings(state)
    }

    /** Files the books once every park hour, which is what the finance chart is drawn from. */
    private fun sampleLedger(state: GameState) {
        val interval = Balance.dayLength / 12
        val index = (state.clock.simTime / interval).toInt()
        if (index <= state.lastLedgerSampleIndex) return

        // Catching up after a long pause would file a dozen empty hours, so
        // only the hour just finished is recorded.
        state.lastLedgerSampleIndex = index
        val hour = 9 + (index % 12)
        state.ledger.takeSample(state.clock.elapsedDayNumber, hour)
    }

    /** Running the park costs money whether or not anyone visits. */
    private fun chargeUtilities(state: GameState, dt: Double) {
        val buildingCount = (state.attractions.size + state.facilities.size).toDouble()
        val perSecond = Balance.utilitiesPerSecond + buildingCount * 0.02
        state.ledger.spend(perSecond * dt, ExpenseCategory.utilities)
    }

    private fun checkDayRollover(state: GameState) {
        val currentDay = state.clock.elapsedDayNumber
        if (currentDay == state.clock.day) return

        val closingProfit = state.ledger.today.profit
        state.ledger.rollOverDay()
        state.statistics.rollOverDay()
        state.clock.day = currentDay

        for (attraction in state.attractions) attraction.guestsToday = 0
        for (facility in state.facilities) {
            facility.customersToday = 0
            facility.revenueToday = 0.0
        }

        val verb = if (closingProfit >= 0) "profit" else "loss"
        state.postAlert(
            "Day ${currentDay - 1} closed with a ${CurrencyFormatter.short(abs(closingProfit))} $verb.",
            if (closingProfit >= 0) AlertSeverity.info else AlertSeverity.warning,
            "day.summary", cooldown = 30.0,
        )
    }

    private fun checkWarnings(state: GameState) {
        if (state.ledger.cash < 1_000) {
            state.postAlert("Your park is running low on cash.", AlertSeverity.critical, "cash.low", cooldown = 240.0)
        }

        // Long queues are the most common reason a park with good rides has unhappy guests.
        for (attraction in state.attractions) {
            val definition = attraction.definition ?: continue
            if (attraction.estimatedWait(definition) > Balance.baseTolerableWait * 2) {
                state.postAlert("${attraction.name} has an extremely long queue.", AlertSeverity.warning,
                    "queue.${attraction.id}", ParkTarget.Ride(attraction.id), 300.0)
            }
        }

        if (state.guestCount > 12 && state.facilities.none { it.definition?.kind == FacilityKind.bathroom }) {
            state.postAlert("Guests are complaining about restroom availability.", AlertSeverity.warning,
                "facility.bathroom.missing", cooldown = 300.0)
        }

        val cleanliness = state.map.cleanlinessScore
        if (cleanliness < 0.5) {
            if (state.staffCount(StaffRole.janitor) == 0) {
                state.postAlert("Litter is piling up and you have no janitors.", AlertSeverity.critical,
                    "staff.janitor.missing", cooldown = 240.0)
            } else {
                state.postAlert("Guests are complaining about litter in the park.", AlertSeverity.warning,
                    "cleanliness.low", cooldown = 240.0)
            }
        }

        if (state.facilities.any { it.isFull }) {
            state.postAlert("Some bins are overflowing.", AlertSeverity.warning, "bins.full", cooldown = 240.0)
        }

        if (state.attractions.any { it.isBroken } && state.staffCount(StaffRole.mechanic) == 0) {
            state.postAlert("A ride is broken and there is no mechanic to fix it.", AlertSeverity.critical,
                "staff.mechanic.needed", cooldown = 180.0)
        }
    }
}

@Serializable
enum class RevenueCategory {
    admission, food, drinks, souvenirs, other;

    val displayName: String get() = name.replaceFirstChar { it.uppercase() }
}

@Serializable
enum class ExpenseCategory {
    construction, wages, maintenance, inventory, utilities;

    val displayName: String get() = name.replaceFirstChar { it.uppercase() }
}

/** Totals for one accounting period, keyed by category name. */
@Serializable
class LedgerPeriod(
    val revenue: MutableMap<String, Double> = mutableMapOf(),
    val expenses: MutableMap<String, Double> = mutableMapOf(),
) {
    fun add(category: RevenueCategory, amount: Double) {
        revenue[category.name] = (revenue[category.name] ?: 0.0) + amount
    }

    fun add(category: ExpenseCategory, amount: Double) {
        expenses[category.name] = (expenses[category.name] ?: 0.0) + amount
    }

    fun amount(category: RevenueCategory): Double = revenue[category.name] ?: 0.0
    fun amount(category: ExpenseCategory): Double = expenses[category.name] ?: 0.0

    val totalRevenue: Double get() = revenue.values.sum()
    val totalExpenses: Double get() = expenses.values.sum()
    val profit: Double get() = totalRevenue - totalExpenses
}

/** One period's takings, stamped with when it was taken. */
@Serializable
class LedgerSample(val day: Int, val hour: Int, val period: LedgerPeriod) {
    val id: String get() = "$day-$hour"
    val totalRevenue: Double get() = period.totalRevenue
    val totalExpenses: Double get() = period.totalExpenses
    val profit: Double get() = period.profit

    /** "Day 3, 14:00", for a chart axis and a tooltip. */
    val label: String get() = String.format("Day %d, %02d:00", day, hour)
    val shortLabel: String get() = String.format("%02d:00", hour)
}

/** Cash plus the books. Every money movement goes through here. */
@Serializable
class Ledger(
    var cash: Double = Balance.startingCash,
    /** Free build: costs are recorded but nothing is ever deducted. */
    var isUnlimited: Boolean = false,
    var today: LedgerPeriod = LedgerPeriod(),
    var yesterday: LedgerPeriod? = null,
    var lifetime: LedgerPeriod = LedgerPeriod(),
    /** Takings since the last sample was taken, and the samples themselves. */
    var sinceSample: LedgerPeriod = LedgerPeriod(),
    val history: MutableList<LedgerSample> = mutableListOf(),
) {
    fun canAfford(amount: Double): Boolean = isUnlimited || cash >= amount

    /** What the placement rules should measure a price against. */
    val spendableCash: Double get() = if (isUnlimited) Double.MAX_VALUE else cash

    fun receive(amount: Double, category: RevenueCategory) {
        if (amount <= 0) return
        cash += amount
        today.add(category, amount)
        lifetime.add(category, amount)
        sinceSample.add(category, amount)
    }

    fun spend(amount: Double, category: ExpenseCategory) {
        if (amount <= 0) return
        if (!isUnlimited) cash -= amount
        today.add(category, amount)
        lifetime.add(category, amount)
        sinceSample.add(category, amount)
    }

    fun rollOverDay() {
        yesterday = today
        today = LedgerPeriod()
    }

    /** Files everything earned and spent since the last sample. */
    fun takeSample(day: Int, hour: Int) {
        history.add(LedgerSample(day, hour, sinceSample))
        sinceSample = LedgerPeriod()
        if (history.size > historyLimit) {
            val excess = history.size - historyLimit
            repeat(excess) { history.removeAt(0) }
        }
    }

    companion object {
        /** A week and a bit at twelve samples a day. */
        const val historyLimit = 96
    }
}
