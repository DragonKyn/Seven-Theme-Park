@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient
import kotlinx.serialization.UseSerializers
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.util.UUID
import kotlin.math.abs

object SeededGeneratorSerializer : KSerializer<SeededGenerator> {
    override val descriptor = PrimitiveSerialDescriptor("SeededGenerator", PrimitiveKind.LONG)
    override fun serialize(encoder: Encoder, value: SeededGenerator) = encoder.encodeLong(value.state)
    override fun deserialize(decoder: Decoder): SeededGenerator = SeededGenerator(decoder.decodeLong())
}

@Serializable
enum class GameSpeed(val rawValue: Int, val label: String) {
    paused(0, "II"),
    normal(1, "1x"),
    fast(2, "2x"),
    veryFast(4, "4x"),

    /** Only selectable while the speed boost is running. */
    turbo(5, "5x");

    /** Whether this notch has to be unlocked before it can be chosen. */
    val needsBoost: Boolean get() = this == turbo
    val multiplier: Double get() = rawValue.toDouble()
}

/** In-game time. One park day is [Balance.dayLength] sim-seconds. */
@Serializable
class SimulationClock(
    var simTime: Double = 0.0,
    var day: Int = 1,
    var speed: GameSpeed = GameSpeed.normal,
) {
    val timeOfDay: Double get() = simTime % Balance.dayLength
    val dayProgress: Double get() = timeOfDay / Balance.dayLength

    /** Day number implied by elapsed sim time, 1-based. */
    val elapsedDayNumber: Int get() = (simTime / Balance.dayLength).toInt() + 1

    /** Clock label mapped onto a 09:00-21:00 opening window, purely for display. */
    val clockLabel: String
        get() {
            val hour = 9.0 + dayProgress * 12.0
            val wholeHour = hour.toInt()
            val minutes = ((hour - wholeHour) * 60).toInt()
            return String.format("%02d:%02d", wholeHour, minutes)
        }
}

/** Aggregate counters that are cheap to keep updated and awkward to recompute. */
@Serializable
class ParkStatistics(
    var guestsAdmittedToday: Int = 0,
    var guestsAdmittedTotal: Int = 0,
    var guestsLeftToday: Int = 0,
    var ridesGivenTotal: Int = 0,
    var itemsSoldTotal: Int = 0,
    var breakdownsTotal: Int = 0,
    var litterCleanedTotal: Int = 0,
    var repairsCompletedTotal: Int = 0,
    var upgradesBoughtTotal: Int = 0,
    var foodSoldTotal: Int = 0,
    var drinksSoldTotal: Int = 0,
    var souvenirsSoldTotal: Int = 0,
    var transportTripsTotal: Int = 0,
    var gamesPlayedTotal: Int = 0,
    var prizesWonTotal: Int = 0,
    var promotionsTotal: Int = 0,
    var goodReviewsTotal: Int = 0,
    var badReviewsTotal: Int = 0,
    var troublemakersEjectedTotal: Int = 0,
    var troublemakersEscapedTotal: Int = 0,
    var safetyInspectionsPassedTotal: Int = 0,
    var safetyInspectionsFailedTotal: Int = 0,
    var tourBusesTotal: Int = 0,
    /** Counts of the reason guests gave for leaving, used for "common complaint". */
    val departureReasons: MutableMap<String, Int> = mutableMapOf(),
) {
    fun recordDeparture(reason: String) {
        guestsLeftToday += 1
        departureReasons[reason] = (departureReasons[reason] ?: 0) + 1
    }

    val commonComplaint: String?
        get() = departureReasons.filter { it.key != DepartureReason.satisfied.text }
            .maxByOrNull { it.value }?.key

    fun rollOverDay() {
        guestsAdmittedToday = 0
        guestsLeftToday = 0
    }
}

@Serializable
enum class AlertSeverity(val symbolName: String) {
    info("info.circle.fill"),
    warning("exclamationmark.triangle.fill"),
    critical("exclamationmark.octagon.fill"),
}

@Serializable
class ParkAlert(
    val id: UUID = UUID.randomUUID(),
    val message: String,
    val severity: AlertSeverity,
    val simTime: Double,
    /** Optional object the alert refers to, so tapping it can focus the map. */
    val target: ParkTarget? = null,
    /** Key used to suppress duplicate alerts while the condition persists. */
    val dedupeKey: String,
) {
    /** When it happened, in the park's own clock. */
    val timeLabel: String
        get() {
            val day = (simTime / Balance.dayLength).toInt() + 1
            val progress = (simTime % Balance.dayLength) / Balance.dayLength
            val hour = 9.0 + progress * 12.0
            val whole = hour.toInt()
            val minutes = ((hour - whole) * 60).toInt()
            return String.format("Day %d, %02d:%02d", day, whole, minutes)
        }
}

/** Something that happened in the park without the player causing it. */
sealed class ParkEvent {
    abstract val id: UUID

    data class Promotion(val post: PromotionPost) : ParkEvent() { override val id: UUID get() = post.id }
    data class TourBus(val report: TourBusReport) : ParkEvent() { override val id: UUID get() = report.id }
    data class Inspection(val report: InspectionReport) : ParkEvent() { override val id: UUID get() = report.id }
    data class Review(val review: CriticReview) : ParkEvent() { override val id: UUID get() = review.id }
    data class Ejection(val report: EjectionReport) : ParkEvent() { override val id: UUID get() = report.id }
}

/** What the player's spent trial points are worth to the park in front of them. */
@Serializable
data class ParkPerks(
    val extraArrivals: Double = 0.0,
    val guestHappiness: Double = 0.0,
    val guestSpending: Double = 0.0,
    val buildDiscount: Double = 0.0,
    val wageDiscount: Double = 0.0,
    val stockDiscount: Double = 0.0,
    val wearReduction: Double = 0.0,
    val breakdownReduction: Double = 0.0,
    val ratingBonus: Double = 0.0,
) {
    val buildCostFactor: Double get() = maxOf(0.3, 1 - buildDiscount)
    val wageFactor: Double get() = maxOf(0.3, 1 - wageDiscount)
    val stockFactor: Double get() = maxOf(0.3, 1 - stockDiscount)
    val wearFactor: Double get() = maxOf(0.3, 1 - wearReduction)
    val breakdownFactor: Double get() = maxOf(0.3, 1 - breakdownReduction)
}

/** What the boosts a player has switched on are worth to the park in front of them. */
@Serializable
data class AdBoostEffects(
    val extraArrivals: Double = 0.0,
    val spendWillingness: Double = 0.0,
    val wearReduction: Double = 0.0,
    val breakdownReduction: Double = 0.0,
    val litterReduction: Double = 0.0,
) {
    val spendFactor: Double get() = 1 + spendWillingness
    val wearFactor: Double get() = maxOf(0.0, 1 - wearReduction)
    val breakdownFactor: Double get() = maxOf(0.0, 1 - breakdownReduction)
    val litterFactor: Double get() = maxOf(0.0, 1 - litterReduction)

    companion object {
        /** Worked out from whatever the player has running. */
        fun from(active: (BoostKind) -> Boolean): AdBoostEffects = AdBoostEffects(
            extraArrivals = if (active(BoostKind.extraVisitors)) Balance.adVisitorBoost else 0.0,
            spendWillingness = if (active(BoostKind.bigSpenders)) Balance.adSpendBoost else 0.0,
            wearReduction = if (active(BoostKind.smoothRunning)) Balance.adWearReduction else 0.0,
            breakdownReduction = if (active(BoostKind.smoothRunning)) Balance.adBreakdownReduction else 0.0,
            litterReduction = if (active(BoostKind.spotless)) Balance.adLitterReduction else 0.0,
        )
    }
}

/**
 * The authoritative state of one park. Simulation systems mutate this;
 * rendering and UI only read from it (or send commands through the controller).
 */
@Serializable
class GameState(
    var parkName: String = "Park",
    /** Which rules the park runs under. Fixed when the park is created. */
    var mode: GameMode = GameMode.normal,
    var map: ParkMap = ParkMap(),
    val guests: MutableList<Guest> = mutableListOf(),
    val attractions: MutableList<Attraction> = mutableListOf(),
    val facilities: MutableList<Facility> = mutableListOf(),
    val staff: MutableList<Staff> = mutableListOf(),
    val scenery: MutableList<SceneryItem> = mutableListOf(),
    /** Loops, corkscrews and jumps sitting on the player's own track. */
    val trackElements: MutableList<TrackElement> = mutableListOf(),
    var ledger: Ledger = Ledger(),
    var clock: SimulationClock = SimulationClock(),
    var statistics: ParkStatistics = ParkStatistics(),
    val alerts: MutableList<ParkAlert> = mutableListOf(),
    var admissionPrice: Double = Balance.defaultAdmissionPrice,
    /** The colour every employee's uniform is drawn in. */
    var uniformColour: ParkColour = ParkColour.teal,
    /** The two colours the park paints its own furniture in. */
    var scheme: ParkScheme = ParkScheme(),
    /** The colour every piece of coaster track is painted. */
    var coasterTrackColour: ParkColour = ParkColour.amber,
    /** How much of the car park outside the gate has been paved. */
    var carParkLevel: Int = 0,
    var nextInfluencerAt: Double = Balance.dayLength * 2.5,
    var promotionBoost: Double = 0.0,
    var promotionEndsAt: Double = 0.0,
    val pendingPromotions: MutableList<PromotionPost> = mutableListOf(),
    var nextTourBusAt: Double = Balance.dayLength * 0.6,
    val pendingTourBuses: MutableList<TourBusReport> = mutableListOf(),
    var nextSafetyInspectionAt: Double = Balance.dayLength * 2.0,
    var inspectingRideID: UUID? = null,
    var inspectionVerdictAt: Double = 0.0,
    var inspectionBonus: TimedModifier = TimedModifier.inactive,
    val pendingInspections: MutableList<InspectionReport> = mutableListOf(),
    var nextCriticAt: Double = Balance.dayLength * 1.5,
    var reviewRating: TimedModifier = TimedModifier.inactive,
    var reviewArrivals: TimedModifier = TimedModifier.inactive,
    val pendingReviews: MutableList<CriticReview> = mutableListOf(),
    var nextTroublemakerAt: Double = Balance.dayLength * 2.0,
    val pendingEjections: MutableList<EjectionReport> = mutableListOf(),
    /** The rung of the Park Trials ladder this park is, if it is one. */
    var trialID: String? = null,
    var trialOutcome: TrialOutcome = TrialOutcome.inProgress,
    var trialDecidedDay: Int = 0,
    var nextTrialCheck: Double = 0.0,
    var pendingTrialResult: TrialResult? = null,
    /** 0-100, eased towards the value the rating system computes. */
    var parkRating: Double = 0.0,
    /** Gates the build menu. Everything designed so far is available. */
    var unlockLevel: Int = 4,
    @Serializable(with = SeededGeneratorSerializer::class)
    var rng: SeededGenerator = SeededGenerator(),
    /** Highest tier earned for each achievement, keyed by definition id. */
    val achievements: MutableMap<String, Int> = mutableMapOf(),
    val pendingAwards: MutableList<AchievementAward> = mutableListOf(),
    var spawnAccumulator: Double = 0.0,
    var currentArrivalsPerMinute: Double = 0.0,
    var nextRatingUpdate: Double = 0.0,
    var lastLedgerSampleIndex: Int = 0,
    var nextAchievementCheck: Double = 0.0,
    var trackedRideGeneration: Int = -1,
    var ratingComponents: MutableMap<String, Double> = mutableMapOf(),
    val lastAlertTimes: MutableMap<String, Double> = mutableMapOf(),
) {
    /** What the player's perks are worth here. Written by the controller, never saved. */
    @Transient
    var perks: ParkPerks = ParkPerks()

    /** What the running boosts are doing here. Written by the controller, never saved. */
    @Transient
    var adBoosts: AdBoostEffects = AdBoostEffects()

    init {
        // The mode is the authority; the ledger flag follows it.
        ledger.isUnlimited = mode.hasUnlimitedMoney
    }

    /** The railway as it currently stands, derived from the track tiles. */
    val trackNetwork: TrackNetwork get() = TrackNetwork.build(map, setOf(TerrainType.track))

    /** The coaster circuits the player has laid. */
    val coasterNetwork: TrackNetwork get() = TrackNetwork.build(map, TerrainType.coasterPieces)

    /** Nudges the map generation so the renderer rebuilds things derived from it. */
    fun bumpDecor() {
        map.touch()
    }

    /** Re-measures how much track each custom ride has to run on. */
    fun refreshTrackedRides() {
        if (attractions.none { it.baseDefinition?.kind == AttractionKind.custom }) return
        val network = coasterNetwork
        for (attraction in attractions) {
            if (attraction.baseDefinition?.kind != AttractionKind.custom) continue
            val routeIndex = network.routeIndex(attraction.rect)
            if (routeIndex == null) {
                attraction.trackLength = 0
                attraction.trackThrill = 0.0
                attraction.coaster = null
                continue
            }
            val route = network.routes[routeIndex]
            val tiles = route.tiles.toSet()

            // An element counts once, however many tiles of the circuit it sits on.
            val onCircuit = trackElements.mapNotNull { element ->
                if (element.rect.coords.none { it in tiles }) null else element.definition
            }

            val rating = CoasterRating.rate(tiles.size, route.isLoop, onCircuit)
            attraction.trackLength = tiles.size
            attraction.trackThrill = rating.thrill
            attraction.coaster = rating
        }
    }

    /**
     * Where a guest riding this station's train should be set down: another
     * station on the same railway, chosen at random. Null when there is nowhere to send anyone.
     */
    fun transportDestination(stationID: UUID): Attraction? {
        val network = trackNetwork
        val station = attraction(stationID) ?: return null
        val route = network.routeIndex(station.rect) ?: return null

        val others = attractions.filter { candidate ->
            candidate.id != stationID &&
                candidate.definition?.kind == AttractionKind.transport &&
                candidate.isOperational &&
                network.routeIndex(candidate.rect) == route
        }
        if (others.isEmpty()) return null
        return others[rng.int(0..(others.size - 1))]
    }

    // region Lookup

    fun attraction(id: UUID): Attraction? = attractions.firstOrNull { it.id == id }
    fun facility(id: UUID): Facility? = facilities.firstOrNull { it.id == id }
    fun guest(id: UUID): Guest? = guests.firstOrNull { it.id == id }
    fun staffMember(id: UUID): Staff? = staff.firstOrNull { it.id == id }
    fun staffIndex(id: UUID): Int? = staff.indexOfFirst { it.id == id }.takeIf { it >= 0 }
    fun attractionIndex(id: UUID): Int? = attractions.indexOfFirst { it.id == id }.takeIf { it >= 0 }
    fun facilityIndex(id: UUID): Int? = facilities.indexOfFirst { it.id == id }.takeIf { it >= 0 }
    fun sceneryIndex(id: UUID): Int? = scenery.indexOfFirst { it.id == id }.takeIf { it >= 0 }
    fun guestIndex(id: UUID): Int? = guests.indexOfFirst { it.id == id }.takeIf { it >= 0 }

    /** Name of whatever the target refers to, for thoughts and inspectors. */
    fun displayName(target: ParkTarget): String = when (target) {
        is ParkTarget.Ride -> attraction(target.id)?.name ?: "a ride"
        is ParkTarget.Shop -> facility(target.id)?.name ?: "a stall"
        is ParkTarget.Exit -> "the exit"
        is ParkTarget.Wander -> "the park"
    }

    /** Tiles a guest can stand on to use the target. */
    fun accessTiles(target: ParkTarget): List<GridCoord> = when (target) {
        is ParkTarget.Ride -> attraction(target.id)?.let { map.accessTiles(it.rect) } ?: emptyList()
        is ParkTarget.Shop -> facility(target.id)?.let { map.accessTiles(it.rect) } ?: emptyList()
        is ParkTarget.Exit -> listOf(map.entranceCoord)
        is ParkTarget.Wander -> if (map.isWalkable(target.spot)) listOf(target.spot) else emptyList()
    }

    // endregion

    // region Alerts

    /** Posts an alert unless one with the same key fired recently. */
    fun postAlert(
        message: String,
        severity: AlertSeverity,
        key: String,
        target: ParkTarget? = null,
        cooldown: Double = 120.0,
    ) {
        val last = lastAlertTimes[key]
        if (last != null && clock.simTime - last < cooldown) return
        lastAlertTimes[key] = clock.simTime
        alerts.add(ParkAlert(message = message, severity = severity, simTime = clock.simTime, target = target, dedupeKey = key))
        while (alerts.size > 40) alerts.removeAt(0)
    }

    // endregion

    // region Derived summaries

    val activeGuests: List<Guest> get() = guests.filter { it.isActive }

    /** Extra arrivals a social media post is currently bringing in, as a share. */
    val activePromotionBoost: Double get() = if (clock.simTime < promotionEndsAt) promotionBoost else 0.0

    /** Rating points the park is currently being given or docked by things that happened to it. */
    val activeRatingModifier: Double
        get() = inspectionBonus.value(clock.simTime) + reviewRating.value(clock.simTime)

    /** Extra arrivals a warm review is currently bringing in, as a share. */
    val activeReviewArrivals: Double get() = reviewArrivals.value(clock.simTime)

    /** The trial this park is being played as, if any. */
    val trial: TrialDefinition? get() = trialID?.let { TrialContent.definition(it) }

    /** The disruptive visitor currently in the park, if there is one. */
    val troublemakerIndex: Int? get() = guests.indexOfFirst { it.isActive && it.isTroublemaker }.takeIf { it >= 0 }

    /** Park minutes left on the current post, or null when there is none. */
    val promotionMinutesLeft: Double? get() = if (clock.simTime < promotionEndsAt) promotionEndsAt - clock.simTime else null

    val guestCount: Int get() = guests.count { it.isActive }

    val averageHappiness: Double
        get() {
            var total = 0.0
            var count = 0
            for (guest in guests) {
                if (guest.isActive) {
                    total += guest.happiness
                    count += 1
                }
            }
            return if (count > 0) total / count else 0.0
        }

    /** Total wages per park day across every employee. */
    val dailyPayroll: Double get() = staff.sumOf { it.dailyWage }

    fun staffCount(role: StaffRole): Int = staff.count { it.role == role }

    val starRating: Int
        get() = when {
            parkRating < 20 -> 1
            parkRating < 40 -> 2
            parkRating < 60 -> 3
            parkRating < 80 -> 4
            else -> 5
        }

    // endregion

    // region Building

    fun placementCheck(definition: BuildableDefinition, origin: GridCoord, rotation: Int = 0): PlacementCheck =
        PlacementValidator.check(definition, origin, rotation, map, ledger.spendableCash, price(definition))

    /** What this actually costs to build here, with the player's permanent discount applied. */
    fun price(definition: BuildableDefinition): Double = (definition.purchasePrice * perks.buildCostFactor).rounded()

    /**
     * [variant] picks which cut of a shape is built; null leaves it to chance,
     * which is what makes a row of trees look like a row of trees.
     */
    fun place(
        definition: BuildableDefinition,
        origin: GridCoord,
        rotation: Int = 0,
        variant: Int? = null,
        colour: ParkColour? = null,
    ): Boolean {
        if (!placementCheck(definition, origin, rotation).isValid) return false

        // Money only moves once we know the definition is one we can build.
        when (definition) {
            is TerrainDefinition -> {
                map.setTerrain(definition.terrain, origin, definition.style)
                if (definition.beauty > 0) refreshBeauty()
            }

            is AttractionDefinition -> {
                val attraction = Attraction(
                    id = UUID.randomUUID(),
                    definitionID = definition.id,
                    name = uniqueName(definition.displayName),
                    origin = origin,
                    size = definition.footprint(rotation),
                    rotation = rotation,
                )
                attractions.add(attraction)
                map.setBuilding(attraction.id, attraction.rect.coords)
                clearGround(attraction.rect)
            }

            is FacilityDefinition -> {
                val styles = definition.appearance.motif.variantCount
                val facility = Facility(
                    id = UUID.randomUUID(),
                    definitionID = definition.id,
                    name = uniqueName(definition.displayName),
                    origin = origin,
                    size = definition.footprint(rotation),
                    rotation = rotation,
                    variant = variant ?: (if (styles > 1) rng.int(0..(styles - 1)) else 0),
                    price = definition.defaultPrice,
                )
                facilities.add(facility)
                map.setBuilding(facility.id, facility.rect.coords, !definition.kind.isFurniture)
                if (!definition.kind.isFurniture) clearGround(facility.rect)
            }

            is CoasterElementDefinition -> {
                val element = TrackElement(
                    id = UUID.randomUUID(),
                    definitionID = definition.id,
                    origin = origin,
                    size = definition.footprint(rotation),
                    rotation = rotation,
                )
                // Lays its own rails, so an element can be dropped on bare ground and joined up afterwards.
                for (coord in element.rect.coords) map.setTerrain(TerrainType.coasterTrack, coord)
                trackElements.add(element)
                // Claiming the tiles is what stops two elements being stacked on one another.
                map.setBuilding(element.id, element.rect.coords)
            }

            is SceneryDefinition -> {
                val styles = definition.appearance.motif.variantCount
                val style = variant ?: (if (styles > 1) rng.int(0..(styles - 1)) else 0)
                val item = SceneryItem(
                    id = UUID.randomUUID(),
                    definitionID = definition.id,
                    origin = origin,
                    size = definition.footprint(rotation),
                    rotation = rotation,
                    variant = style,
                    colour = if (definition.appearance.motif.colourChoices.isEmpty()) null else colour,
                )
                scenery.add(item)
                map.setBuilding(item.id, item.rect.coords, !definition.leavesWalkwayOpen)
                refreshBeauty()
            }

            else -> return false
        }

        ledger.spend(price(definition), ExpenseCategory.construction)
        return true
    }

    /**
     * Deals with whatever was on the ground a building has just been put on:
     * a guest inside a wall is stuck, and rubbish nobody can reach is rubbish
     * no janitor will ever clear.
     */
    fun clearGround(rect: GridRect) {
        for (coord in rect.coords) {
            if (map.tile(coord)?.isWalkable == false) map.clearLitter(coord)
        }

        fun nearestWalkway(coord: GridCoord): GridCoord? {
            for (radius in 1..Balance.buildOverEvictionRadius) {
                for (dy in -radius..radius) {
                    for (dx in -radius..radius) {
                        if (maxOf(abs(dx), abs(dy)) != radius) continue
                        val candidate = GridCoord(coord.x + dx, coord.y + dy)
                        if (map.isWalkable(candidate) && !rect.contains(candidate)) return candidate
                    }
                }
            }
            return null
        }

        for (guest in guests) {
            if (!rect.contains(guest.tile)) continue
            val tile = nearestWalkway(guest.tile) ?: continue
            guest.tile = tile
            guest.position = tile.centre
            guest.route = mutableListOf()
            guest.activity = GuestActivity.Exploring
            guest.nextDecisionAt = clock.simTime
        }

        for (member in staff) {
            if (!rect.contains(member.tile)) continue
            val tile = nearestWalkway(member.tile) ?: continue
            member.tile = tile
            member.position = tile.centre
            member.route = mutableListOf()
            member.activity = StaffActivity.Idle
        }
    }

    /** Rebuilds the tile beauty field from everything currently placed. */
    fun refreshBeauty() {
        val sources = ArrayList<ParkMap.BeautySource>()
        for (item in scenery) {
            val definition = item.definition ?: continue
            sources.add(ParkMap.BeautySource(item.rect, definition.beauty, definition.beautyRadius))
        }

        // A themed ride decorates the ground around it.
        for (attraction in attractions) {
            val level = attraction.upgradeLevel(RideUpgradeKind.theming)
            if (level <= 0) continue
            sources.add(ParkMap.BeautySource(attraction.rect, UpgradeContent.themingBeauty(level), UpgradeContent.themingBeautyRadius))
        }

        // Water is terrain rather than an object, so it is folded in a tile at a time.
        for (definition in GameContent.terrains) {
            if (definition.beauty <= 0) continue
            for (coord in map.coords(definition.terrain)) {
                sources.add(ParkMap.BeautySource(GridRect(coord, GridSize.single), definition.beauty, definition.beautyRadius))
            }
        }

        map.recomputeBeauty(sources)
    }

    /** What sits on a tile, if anything. */
    fun target(coord: GridCoord): ParkTarget? {
        val tile = map.tile(coord) ?: return null
        val buildingID = tile.buildingID ?: return null
        if (attractionIndex(buildingID) != null) return ParkTarget.Ride(buildingID)
        if (facilityIndex(buildingID) != null) return ParkTarget.Shop(buildingID)
        return null
    }

    /** Value returned to the player when demolishing. */
    fun demolitionRefund(coord: GridCoord): Double {
        val target = target(coord)
        if (target != null) {
            return when (target) {
                is ParkTarget.Ride -> (attraction(target.id)?.definition?.purchasePrice ?: return 0.0) * 0.5
                is ParkTarget.Shop -> (facility(target.id)?.definition?.purchasePrice ?: return 0.0) * 0.5
                else -> 0.0
            }
        }
        trackElement(coord)?.let { return (it.definition?.purchasePrice ?: 0.0) * 0.5 }
        sceneryItem(coord)?.let { return (it.definition?.purchasePrice ?: 0.0) * 0.5 }
        val tile = map.tile(coord)
        if (tile != null) {
            val definition = GameContent.terrains.firstOrNull { it.terrain == tile.terrain && it.style == tile.style }
                ?: GameContent.terrains.firstOrNull { it.terrain == tile.terrain }
            if (definition != null) return definition.refundValue
        }
        return 0.0
    }

    fun trackElement(coord: GridCoord): TrackElement? {
        val buildingID = map.tile(coord)?.buildingID ?: return null
        return trackElements.firstOrNull { it.id == buildingID }
    }

    fun sceneryItem(coord: GridCoord): SceneryItem? {
        val buildingID = map.tile(coord)?.buildingID ?: return null
        return scenery.firstOrNull { it.id == buildingID }
    }

    fun demolish(coord: GridCoord): Boolean {
        val target = target(coord)
        if (target != null) {
            when (target) {
                is ParkTarget.Ride -> {
                    val index = attractionIndex(target.id) ?: return false
                    val attraction = attractions[index]
                    evictGuests(target)
                    map.setBuilding(null, attraction.rect.coords)
                    attractions.removeAt(index)
                    // A themed ride decorated the ground around it.
                    if (attraction.upgradeLevel(RideUpgradeKind.theming) > 0) refreshBeauty()
                    ledger.receive(refundValue(attraction.definition), RevenueCategory.other)
                    return true
                }
                is ParkTarget.Shop -> {
                    val index = facilityIndex(target.id) ?: return false
                    val facility = facilities[index]
                    evictGuests(target)
                    map.setBuilding(null, facility.rect.coords)
                    facilities.removeAt(index)
                    ledger.receive(refundValue(facility.definition), RevenueCategory.other)
                    return true
                }
                else -> return false
            }
        }

        val element = trackElement(coord)
        if (element != null) {
            val index = trackElements.indexOfFirst { it.id == element.id }
            if (index >= 0) {
                map.setBuilding(null, element.rect.coords)
                trackElements.removeAt(index)
                ledger.receive(refundValue(element.definition), RevenueCategory.other)
                return true
            }
        }

        val item = sceneryItem(coord)
        if (item != null) {
            val index = sceneryIndex(item.id)
            if (index != null) {
                map.setBuilding(null, item.rect.coords)
                scenery.removeAt(index)
                refreshBeauty()
                ledger.receive(refundValue(item.definition), RevenueCategory.other)
                return true
            }
        }

        val tile = map.tile(coord) ?: return false
        // Ground that came with the map stays. A bridge laid over a natural lake can still come up.
        if (map.isNatural(coord) && tile.terrain != TerrainType.bridge) return false
        // Matched on the finish as well as the terrain.
        val terrains = GameContent.terrains
        val definition = terrains.firstOrNull { it.terrain == tile.terrain && it.style == tile.style }
            ?: terrains.firstOrNull { it.terrain == tile.terrain }
            ?: return false

        // Taking a bridge out leaves the water it was crossing, not a hole in the pond.
        map.setTerrain(if (tile.terrain == TerrainType.bridge) TerrainType.water else TerrainType.grass, coord)
        if (definition.beauty > 0) refreshBeauty()
        ledger.receive(definition.refundValue, RevenueCategory.other)
        return true
    }

    private fun refundValue(definition: BuildableDefinition?): Double = (definition?.purchasePrice ?: 0.0) * 0.5

    /** Sends anyone queueing for or using a removed object back onto the paths. */
    fun evictGuests(target: ParkTarget) {
        for (guest in guests) {
            val current = when (val activity = guest.activity) {
                is GuestActivity.Walking -> activity.target
                is GuestActivity.Queueing -> activity.target
                is GuestActivity.Engaged -> activity.target
                else -> continue
            }
            if (current == target) {
                guest.activity = GuestActivity.Exploring
                guest.route = mutableListOf()
                guest.nextDecisionAt = clock.simTime
            }
        }
    }

    private fun uniqueName(base: String): String {
        val existing = attractions.map { it.name }.toSet() + facilities.map { it.name }
        if (base !in existing) return base
        var suffix = 2
        while ("$base $suffix" in existing) suffix += 1
        return "$base $suffix"
    }

    // endregion

    // region Editing

    fun setSceneryStyle(variant: Int, id: UUID) {
        sceneryIndex(id)?.let { scenery[it].variant = variant }
    }

    /** Null puts the colours back to the ones the piece was designed in. */
    fun setSceneryColour(colour: ParkColour?, id: UUID) {
        sceneryIndex(id)?.let { scenery[it].colour = colour }
    }

    /**
     * Turns a decoration a quarter clockwise, if there is room for it to stand
     * that way. A long piece turned on the spot sweeps out different ground.
     */
    fun turnScenery(id: UUID): Boolean {
        val item = sceneryIndex(id)?.let { scenery[it] } ?: return false
        val definition = item.definition ?: return false
        val next = definition.nextTurn(item.rotation)

        if (!refit(definition, id, item.rect, item.origin, next, !definition.leavesWalkwayOpen)) return false

        item.rotation = next
        item.size = definition.footprint(next)
        return true
    }

    fun turnFacility(id: UUID): Boolean {
        val facility = facilityIndex(id)?.let { facilities[it] } ?: return false
        val definition = facility.baseDefinition ?: return false
        val next = definition.nextTurn(facility.rotation)
        val blocking = !definition.kind.isFurniture
        val oldSize = facility.size

        if (!refit(definition, id, facility.rect, facility.origin, next, blocking)) return false

        facility.rotation = next
        facility.size = definition.footprint(next)
        if (blocking) clearGround(facility.rect)
        // It is a different shape of ground that sends people on their way.
        if (facility.size != oldSize) evictGuests(ParkTarget.Shop(id))
        return true
    }

    fun turnAttraction(id: UUID): Boolean {
        val attraction = attractionIndex(id)?.let { attractions[it] } ?: return false
        val definition = GameContent.attraction(attraction.definitionID) ?: return false
        val next = definition.nextTurn(attraction.rotation)
        val oldSize = attraction.size

        if (!refit(definition, id, attraction.rect, attraction.origin, next, true)) return false

        attraction.rotation = next
        attraction.size = definition.footprint(next)
        clearGround(attraction.rect)
        if (attraction.size != oldSize) evictGuests(ParkTarget.Ride(id))
        return true
    }

    /**
     * Moves a building's claim on the map from the ground it held to the ground
     * it would hold once turned, if the placement rules allow it. The old
     * ground is let go first, and taken back if the new one is refused.
     */
    private fun refit(
        definition: BuildableDefinition,
        id: UUID,
        old: GridRect,
        origin: GridCoord,
        rotation: Int,
        blocking: Boolean,
    ): Boolean {
        val new = GridRect(origin, definition.footprint(rotation))

        map.setBuilding(null, old.coords)
        val check = PlacementValidator.check(definition, origin, rotation, map, Double.POSITIVE_INFINITY, 0.0)
        if (!check.isValid) {
            map.setBuilding(id, old.coords, blocking)
            return false
        }
        map.setBuilding(id, new.coords, blocking)
        return true
    }

    // endregion
}

/** What the scenery panel shows and offers for one placed decoration. */
class SceneryDetail(item: SceneryItem, scheme: ParkScheme) {
    val id: UUID = item.id
    val name: String
    val variant: Int = item.variant
    val styleCount: Int
    val colour: ParkColour? = item.colour
    val colourChoices: List<ParkColour>

    /** How it looks now, so the style buttons can show each alternative in the colours it is painted in. */
    val appearance: BuildingAppearance

    init {
        val definition = item.definition
        val base = definition?.appearance ?: BuildingAppearance.unknown
        name = definition?.displayName ?: "Decoration"
        styleCount = base.motif.variantCount
        colourChoices = base.motif.colourChoices
        appearance = base.tinted(item.colour).applying(scheme)
    }
}

/** Starts a new park on the given ground. */
fun newGameState(
    parkName: String,
    mode: GameMode = GameMode.normal,
    layout: MapLayout? = null,
    startingCash: Double = Balance.startingCash,
    trialID: String? = null,
    seed: Long = java.util.Random().nextLong(),
): GameState {
    val map = ParkMap(Balance.mapWidth, Balance.mapHeight)
    if (layout != null) map.applyLayout(layout, Balance.startingPathLength)
    else map.applyStartingLayout(Balance.startingPathLength)
    return GameState(
        parkName = parkName,
        mode = mode,
        map = map,
        ledger = Ledger(cash = startingCash),
        trialID = trialID,
        rng = SeededGenerator(seed),
    )
}
