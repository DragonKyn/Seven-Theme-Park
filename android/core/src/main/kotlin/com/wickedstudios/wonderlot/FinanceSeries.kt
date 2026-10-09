package com.wickedstudios.wonderlot

/** The finance chart's data, and the rules for what a line on it means. */
enum class FinanceSeriesKind(val displayName: String) {
    profit("Profit"),
    revenue("Revenue"),
    expenses("Costs"),
    wages("Wages"),
    maintenance("Repairs"),
    inventory("Stock"),
    construction("Building"),
    utilities("Upkeep");

    /** The three totals are the point of the chart; the rest start hidden. */
    val isHeadline: Boolean get() = this == profit || this == revenue || this == expenses

    val expenseCategory: ExpenseCategory?
        get() = when (this) {
            wages -> ExpenseCategory.wages
            maintenance -> ExpenseCategory.maintenance
            inventory -> ExpenseCategory.inventory
            construction -> ExpenseCategory.construction
            utilities -> ExpenseCategory.utilities
            else -> null
        }

    fun amount(point: FinancePoint): Double = when (this) {
        profit -> point.profit
        revenue -> point.revenue
        expenses -> point.expenses
        else -> expenseCategory?.let { point.expenses(it) } ?: 0.0
    }
}

/** One column of the chart: an hour of the park's day, or a whole day. */
class FinancePoint(val id: Int, val label: String, val shortLabel: String, period: LedgerPeriod) {
    val revenue: Double = period.totalRevenue
    val expenses: Double = period.totalExpenses
    private val expenseBreakdown: Map<String, Double> = period.expenses.toMap()

    val profit: Double get() = revenue - expenses

    fun expenses(category: ExpenseCategory): Double = expenseBreakdown[category.name] ?: 0.0
}

enum class FinanceRange(val displayName: String) {
    /** Every park hour that has been filed, up to the last day's worth. */
    today("By hour"),

    /** One column per day. */
    allDays("By day")
}

object FinanceSeriesBuilder {
    /** Turns the ledger's samples into columns for the chart. */
    fun points(history: List<LedgerSample>, range: FinanceRange): List<FinancePoint> = when (range) {
        FinanceRange.today ->
            history.takeLast(12).mapIndexed { index, sample ->
                FinancePoint(index, sample.label, sample.shortLabel, sample.period)
            }

        FinanceRange.allDays -> {
            val byDay = HashMap<Int, LedgerPeriod>()
            for (sample in history) {
                val period = byDay.getOrPut(sample.day) { LedgerPeriod() }
                for ((key, amount) in sample.period.revenue) period.revenue[key] = (period.revenue[key] ?: 0.0) + amount
                for ((key, amount) in sample.period.expenses) period.expenses[key] = (period.expenses[key] ?: 0.0) + amount
            }
            byDay.keys.sorted().mapIndexed { index, day ->
                FinancePoint(index, "Day $day", "$day", byDay[day] ?: LedgerPeriod())
            }
        }
    }
}
