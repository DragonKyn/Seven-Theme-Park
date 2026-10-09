package com.wickedstudios.wonderlot

/** Which side of the park an improvement belongs to. */
enum class PerkBranch(val displayName: String, val summary: String, val symbolName: String) {
    guests("Guests", "More people, in a better mood, with more to spend.", "person.2.fill"),
    money("Money", "Everything the park buys costs less.", "banknote.fill"),
    operations("Operations", "Rides that last, and a park people speak well of.", "wrench.and.screwdriver.fill"),
}

/** One permanent improvement, bought with the points trials pay out. */
class PerkDefinition(
    val id: String,
    val branch: PerkBranch,
    val displayName: String,
    val symbolName: String,
    /** How many points can be put into it. */
    val maxRank: Int,
    /** What one rank is worth, in whatever unit the perk deals in. */
    val perRank: Double,
    /** Points that must already be spent in this branch before it opens. */
    val requires: Int,
    /** Written with the value of a single rank in it. */
    val detail: String,
) {
    fun summary(rank: Int): String =
        detail.replace("{v}", format(perRank)) + (if (rank > 0) "  Now: ${format(perRank * rank)}." else "")

    private fun format(value: Double): String =
        if (value < 1) "${(value * 100).rounded().toInt()}%" else "${value.rounded().toInt()}"
}

/** The tree itself. */
object PerkContent {
    val all: List<PerkDefinition> = listOf(
        PerkDefinition("perk.arrivals", PerkBranch.guests, "Warm Welcome", "hand.wave.fill", 3, 0.04, 0,
            "{v} more arrivals at the gate, in every park you build."),
        PerkDefinition("perk.mood", PerkBranch.guests, "Good First Impression", "face.smiling.inverse", 2, 5.0, 2,
            "Guests walk in {v} points happier than they otherwise would."),
        PerkDefinition("perk.spending", PerkBranch.guests, "Deep Pockets", "wallet.bifold.fill", 3, 0.07, 3,
            "Guests arrive with {v} more money to spend."),

        PerkDefinition("perk.building", PerkBranch.money, "Shrewd Buyer", "hammer.fill", 3, 0.05, 0,
            "{v} off everything you build."),
        PerkDefinition("perk.wages", PerkBranch.money, "Lean Payroll", "person.badge.clock.fill", 2, 0.08, 2,
            "{v} off the wage bill, without anybody working less."),
        PerkDefinition("perk.stock", PerkBranch.money, "Bulk Supplier", "shippingbox.fill", 2, 0.12, 3,
            "{v} off what every sale costs the park to stock."),

        PerkDefinition("perk.wear", PerkBranch.operations, "Hard Wearing", "shield.lefthalf.filled", 3, 0.10, 0,
            "Rides wear out {v} more slowly."),
        PerkDefinition("perk.safety", PerkBranch.operations, "Safety First", "checkmark.seal.fill", 2, 0.12, 2,
            "{v} less likely to break down at any given condition."),
        PerkDefinition("perk.reputation", PerkBranch.operations, "Good Name", "star.fill", 2, 2.0, 3,
            "{v} points of park rating, for nothing."),
    )

    fun definition(id: String): PerkDefinition? = all.firstOrNull { it.id == id }
    fun inBranch(branch: PerkBranch): List<PerkDefinition> = all.filter { it.branch == branch }

    /** Every point that could ever be spent. */
    val totalRanks: Int get() = all.sumOf { it.maxRank }
}
