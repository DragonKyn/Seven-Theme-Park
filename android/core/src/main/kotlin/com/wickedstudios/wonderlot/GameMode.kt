package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable

/** Which rules a park runs under. Chosen when the park is created. */
@Serializable
enum class GameMode(val displayName: String, val summary: String, val symbolName: String) {
    /** A starting balance, and everything has to pay for itself. */
    normal("Normal",
        "Start with a fixed balance and make the park pay for itself. Achievements count.",
        "chart.line.uptrend.xyaxis"),

    /** Unlimited money, for building without the accounting. */
    freeBuild("Free Build",
        "Unlimited money. Build whatever you like. Achievements are switched off.",
        "infinity"),

    /** A park built against a deadline, as one rung of the Park Trials ladder. */
    trial("Park Trial",
        "A set map, a set budget and a deadline. Meet every goal to earn the medal.",
        "flag.checkered");

    val hasUnlimitedMoney: Boolean get() = this == freeBuild

    /** Achievements are earned against the constraint of a budget. */
    val earnsAchievements: Boolean get() = this != freeBuild

    companion object {
        /** The modes chosen on the new park screen. */
        val sandboxModes = listOf(normal, freeBuild)
    }
}
