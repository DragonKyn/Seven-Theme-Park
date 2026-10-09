@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.util.UUID

@Serializable
enum class RidePhase {
    /** Doors open, taking guests from the queue. */
    loading,

    /** Cycle in progress. */
    running
}

/** A placed ride. Static numbers live in [AttractionDefinition]; this holds what changes while the park runs. */
@Serializable
class Attraction(
    val id: UUID = UUID.randomUUID(),
    val definitionID: String = "",
    var name: String = "Ride",
    var origin: GridCoord = GridCoord.zero,
    var size: GridSize = GridSize.single,
    /** Quarter turns clockwise, 0 to 3. [size] is already the turned footprint. */
    var rotation: Int = 0,
    /** Player-controlled. A closed ride keeps its guests but takes no new ones. */
    var isOpen: Boolean = true,
    /** 0-100. Falls as the ride operates and is restored by a mechanic. */
    var condition: Double = 100.0,
    /** Set when the ride fails. Only a mechanic clears it. */
    var isBroken: Boolean = false,
    /** Shut by a safety inspector. Kept apart from [isOpen], which belongs to the player. */
    var isImpounded: Boolean = false,
    /** Sim-seconds since a mechanic last inspected it. */
    var timeSinceInspection: Double = 0.0,
    var totalBreakdowns: Int = 0,
    /** Purchased upgrade levels, keyed by [RideUpgradeKind] name. */
    var upgrades: MutableMap<String, Int> = mutableMapOf(),
    /** Tiles of the player's own track this station runs on. */
    var trackLength: Int = 0,
    /** What the special pieces on that track are worth. */
    var trackThrill: Double = 0.0,
    /** How the circuit judges as a whole. Null until the simulation has looked at it. */
    var coaster: CoasterRating? = null,
    var livery: ParkColour = ParkColour.red,
    var carStyle: CoasterCarStyle = CoasterCarStyle.classic,
    /** A colour the player chose for this one building. */
    var tint: ParkColour? = null,
    var phase: RidePhase = RidePhase.loading,
    var phaseTimer: Double = 0.0,
    var queue: MutableList<UUID> = mutableListOf(),
    var riders: MutableList<UUID> = mutableListOf(),
    var guestsToday: Int = 0,
    var totalGuests: Int = 0,
    /** Running sum/count of rider happiness deltas, for a satisfaction score. */
    var satisfactionSum: Double = 0.0,
    var satisfactionCount: Int = 0,
) {
    val rect: GridRect get() = GridRect(origin, size)

    /** The ride as the catalogue describes it, before anything was bought for it. */
    val baseDefinition: AttractionDefinition? get() = GameContent.attraction(definitionID)

    /** The ride as it actually runs, upgrades included. */
    val definition: AttractionDefinition?
        get() = baseDefinition?.applying(upgrades, trackLength, trackThrill, coaster)

    fun upgradeLevel(kind: RideUpgradeKind): Int = upgrades[kind.name] ?: 0

    /** Open for business: not closed, not broken, not shut by an inspector. */
    val isOperational: Boolean get() = isOpen && !isBroken && !isImpounded

    val isInspectionOverdue: Boolean get() = timeSinceInspection > Balance.inspectionInterval

    val averageSatisfaction: Double?
        get() = if (satisfactionCount > 0) satisfactionSum / satisfactionCount else null

    /** Sim-seconds a guest joining the back of the queue should expect to wait. */
    fun estimatedWait(definition: AttractionDefinition): Double {
        val cycleTime = definition.loadDuration + definition.rideDuration
        val batchesAhead = ((queue.size + definition.capacity - 1) / definition.capacity).toDouble()
        val currentCycleRemaining =
            if (phase == RidePhase.running) maxOf(0.0, definition.rideDuration - phaseTimer) else 0.0
        return batchesAhead * cycleTime + currentCycleRemaining
    }

    val statusDescription: String
        get() = when {
            isImpounded -> "Shut by the inspector"
            isBroken -> "Broken down"
            !isOpen -> "Closed"
            phase == RidePhase.running -> "Running"
            else -> "Loading"
        }

    /** How urgently a mechanic should attend, or null when nothing is needed. */
    val maintenancePriority: Double?
        get() = when {
            isBroken -> 1000.0
            isImpounded -> 900.0
            isInspectionOverdue -> 100 + (100 - condition)
            else -> null
        }
}

/** One guest currently occupying a service slot (a till, a stall, a seat). */
@Serializable
class ServiceSlot(var guestID: UUID, var remaining: Double)

/** A placed shop, restroom, bench or bin. */
@Serializable
class Facility(
    val id: UUID = UUID.randomUUID(),
    val definitionID: String = "",
    var name: String = "Facility",
    var origin: GridCoord = GridCoord.zero,
    var size: GridSize = GridSize.single,
    /** Quarter turns clockwise, 0 to 3. */
    var rotation: Int = 0,
    /** Which cut of the shape was built. Picked when placed and kept. */
    var variant: Int = 0,
    var isOpen: Boolean = true,
    /** Selling price. Zero for facilities that do not sell anything. */
    var price: Double = 0.0,
    var queue: MutableList<UUID> = mutableListOf(),
    var slots: MutableList<ServiceSlot> = mutableListOf(),
    /** 0-100. Restrooms get dirty with use, bins fill up with rubbish. */
    var soiling: Double = 0.0,
    var timesServiced: Int = 0,
    /** Park minutes of cleaning still to do, and how many there were when it began. */
    var cleaningRemaining: Double = 0.0,
    var cleaningTotal: Double = 0.0,
    var upgrades: MutableMap<String, Int> = mutableMapOf(),
    /** Prizes handed out, for carnival booths. */
    var prizesGiven: Int = 0,
    var customersToday: Int = 0,
    var totalCustomers: Int = 0,
    var revenueToday: Double = 0.0,
    var totalRevenue: Double = 0.0,
    var totalCost: Double = 0.0,
    /** Rolling average of how fairly guests judged the price (0-1). */
    var sentimentSum: Double = 0.0,
    var sentimentCount: Int = 0,
) {
    val rect: GridRect get() = GridRect(origin, size)

    /** Shut while a janitor works through it. */
    val isBeingCleaned: Boolean get() = cleaningTotal > 0

    /** Open, and not in the middle of being cleaned. */
    val isAcceptingGuests: Boolean get() = isOpen && !isBeingCleaned

    /** How far through the cleaning it is, 0 to 1. */
    val cleaningProgress: Double?
        get() = if (cleaningTotal > 0) SimMath.clamp(1 - cleaningRemaining / cleaningTotal, 0.0, 1.0) else null

    /** Straight out of the catalogue, without anything the player has bought. */
    val baseDefinition: FacilityDefinition? get() = GameContent.facility(definitionID)

    /** What the shop actually is now, upgrades and all. */
    val definition: FacilityDefinition? get() = baseDefinition?.applying(upgrades)

    fun upgradeLevel(kind: ShopUpgradeKind): Int = upgrades[kind.name] ?: 0

    val priceSentiment: Double?
        get() = if (sentimentCount > 0) sentimentSum / sentimentCount else null

    fun estimatedWait(definition: FacilityDefinition): Double {
        val capacity = maxOf(1, definition.simultaneousCapacity)
        val batchesAhead = ((queue.size + capacity - 1) / capacity).toDouble()
        return batchesAhead * definition.serviceDuration
    }

    val hasFreeSlot: Boolean
        get() {
            val definition = definition ?: return false
            return slots.size < definition.simultaneousCapacity
        }

    /** A bin this full cannot take any more rubbish. */
    val isFull: Boolean get() = definition?.kind == FacilityKind.bin && soiling >= 100

    /** Unpleasant enough that guests notice. */
    val isDirty: Boolean get() = soiling > Balance.dirtyFacilityThreshold

    /** Guests will not use a restroom in this state. */
    val isUnusable: Boolean
        get() {
            val kind = definition?.kind ?: return false
            return when (kind) {
                FacilityKind.bathroom -> soiling > 92
                FacilityKind.bin -> soiling >= 100
                else -> false
            }
        }

    /** How urgently a janitor should attend to this, or null when it is fine. */
    val servicingPriority: Double?
        get() {
            if (definition?.kind?.needsServicing != true) return null
            if (soiling <= Balance.dirtyFacilityThreshold * 0.6) return null
            return soiling
        }
}

/** A placed decoration. It occupies tiles and makes the ground around it prettier. */
@Serializable
class SceneryItem(
    val id: UUID = UUID.randomUUID(),
    val definitionID: String = "",
    var origin: GridCoord = GridCoord.zero,
    var size: GridSize = GridSize.single,
    /** Quarter turns clockwise, 0 to 3. */
    var rotation: Int = 0,
    /** Which cut of this shape was planted. */
    var variant: Int = 0,
    /** A colour the player chose for it, or null for the one it was designed in. */
    var colour: ParkColour? = null,
) {
    val rect: GridRect get() = GridRect(origin, size)
    val definition: SceneryDefinition? get() = GameContent.scenery(definitionID)
}

/** A placed coaster element: a loop, a corkscrew, a jump. */
@Serializable
class TrackElement(
    val id: UUID = UUID.randomUUID(),
    val definitionID: String = "",
    var origin: GridCoord = GridCoord.zero,
    var size: GridSize = GridSize.single,
    /** Quarter turns clockwise, 0 to 3. */
    var rotation: Int = 0,
) {
    val rect: GridRect get() = GridRect(origin, size)
    val definition: CoasterElementDefinition? get() = CoasterElementContent.definition(definitionID)
}
