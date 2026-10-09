package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable

@Serializable
enum class StaffRole(val pluralName: String) {
    janitor("Janitors"),
    mechanic("Mechanics"),
    entertainer("Entertainers"),
    security("Security"),

    /** A person in a big costume. Wanders the park being loved. */
    mascot("Mascots");
}

class StaffDefinition(
    val role: StaffRole,
    val displayName: String,
    val summary: String,
    val hiringCost: Double,
    /** Charged continuously, spread across the park day. */
    val dailyWage: Double,
    val symbolName: String,
) {
    val id: String get() = role.name
    val wagePerSecond: Double get() = dailyWage / Balance.dayLength
}

object StaffContent {
    val all: List<StaffDefinition> = listOf(
        StaffDefinition(StaffRole.janitor, "Janitor",
            "Sweeps up litter, empties bins and cleans restrooms.", 500.0, 60.0, "trash.fill"),
        StaffDefinition(StaffRole.mechanic, "Mechanic",
            "Inspects rides and repairs them when they break down.", 900.0, 95.0, "wrench.and.screwdriver.fill"),
        StaffDefinition(StaffRole.security, "Security Guard",
            "Stands at the gate and walks the park. Guests behave better, and feel safer, where one is stood.",
            750.0, 85.0, "shield.fill"),
        StaffDefinition(StaffRole.entertainer, "Entertainer",
            "Wanders the park lifting the mood of nearby guests. Choose an act: balloons, mime, juggling or magic.",
            600.0, 70.0, "theatermasks.fill"),
        StaffDefinition(StaffRole.mascot, "Park Mascot",
            "A big costumed favourite who wanders the crowds, and is a hit with the children. Pick the costume and paint it any colours you like.",
            1_100.0, 110.0, "pawprint.fill"),
    )

    private val byRole = all.associateBy { it.role }
    fun definition(role: StaffRole): StaffDefinition? = byRole[role]
}
