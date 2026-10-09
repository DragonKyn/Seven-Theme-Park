package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable

@Serializable
enum class RideUpgradeKind { capacity, reliability, theming, loading }

class RideUpgradeDefinition(
    val kind: RideUpgradeKind,
    val displayName: String,
    val summary: String,
    val symbolName: String,
    val maxLevel: Int,
    /** Price of the first level as a share of the ride's purchase price. */
    val costShare: Double,
) {
    val id: String get() = kind.name

    fun cost(level: Int, ridePrice: Double): Double = (ridePrice * costShare * level * 1.15).rounded()
}

/** The three levers that matter to a counter: capacity, quality, signage. */
@Serializable
enum class ShopUpgradeKind {
    service, quality, signage;

    fun displayName(kind: FacilityKind): String = when (this) {
        service -> if (kind == FacilityKind.game) "Second Booth" else "Extra Till"
        quality -> if (kind == FacilityKind.game) "Better Prizes" else "Better Stock"
        signage -> "Lit Signage"
    }

    fun summary(kind: FacilityKind): String = when (this) {
        service -> if (kind == FacilityKind.game) "Another set of stalls, so twice as many can play at once."
        else "Another till, so the queue moves at twice the rate."
        quality -> if (kind == FacilityKind.game) "Bigger prizes and better odds. Winners leave far happier."
        else "Better ingredients. Guests judge the price against what they get."
        signage -> "Lights and a painted board. Guests notice it from further down the path."
    }

    val symbolName: String
        get() = when (this) {
            service -> "person.2.badge.plus"
            quality -> "star.circle.fill"
            signage -> "lightbulb.fill"
        }

    val maxLevel: Int
        get() = when (this) {
            service -> 2
            quality -> 3
            signage -> 2
        }

    val costShare: Double
        get() = when (this) {
            service -> 0.55
            quality -> 0.40
            signage -> 0.32
        }

    fun cost(level: Int, shopPrice: Double): Double = (shopPrice * costShare * level * 1.15).rounded()
}

/** Training makes an employee faster on their feet and quicker at the job. */
class StaffTrainingDefinition(
    val maxLevel: Int,
    val costShare: Double,
    val walkSpeedPerLevel: Double,
    val workRatePerLevel: Double,
    val wagePerLevel: Double,
) {
    fun cost(level: Int, hiringCost: Double): Double = (hiringCost * costShare * level * 1.2).rounded()

    fun title(level: Int): String = when (level) {
        0 -> "Untrained"
        1 -> "Trained"
        2 -> "Experienced"
        else -> "Veteran"
    }
}

object UpgradeContent {
    val rideUpgrades: List<RideUpgradeDefinition> = listOf(
        RideUpgradeDefinition(RideUpgradeKind.capacity, "Extra Cars",
            "Carries more guests per cycle, which is the only real cure for a long queue.",
            "person.3.fill", 3, 0.30),
        RideUpgradeDefinition(RideUpgradeKind.loading, "Faster Loading",
            "Shorter turnaround between cycles. Cheap, and it compounds all day.",
            "timer", 3, 0.20),
        RideUpgradeDefinition(RideUpgradeKind.reliability, "Reinforced Parts",
            "Wears out far more slowly, so a mechanic goes further.",
            "wrench.and.screwdriver.fill", 3, 0.26),
        RideUpgradeDefinition(RideUpgradeKind.theming, "Theming",
            "More exciting to ride, and it makes the ground around it pretty.",
            "sparkles", 3, 0.34),
    )

    val staffTraining = StaffTrainingDefinition(
        maxLevel = 3, costShare = 0.55, walkSpeedPerLevel = 0.16, workRatePerLevel = 0.32, wagePerLevel = 0.24,
    )

    private val byKind = rideUpgrades.associateBy { it.kind }
    fun rideUpgrade(kind: RideUpgradeKind): RideUpgradeDefinition? = byKind[kind]

    fun capacityFactor(level: Int): Double = 1 + 0.30 * level
    fun loadingFactor(level: Int): Double = maxOf(0.35, 1 - 0.22 * level)
    fun wearFactor(level: Int): Double = maxOf(0.25, 1 - 0.28 * level)
    fun themingExcitement(level: Int): Double = 7.0 * level
    fun themingBeauty(level: Int): Double = 22.0 * level
    const val themingBeautyRadius = 2
}
