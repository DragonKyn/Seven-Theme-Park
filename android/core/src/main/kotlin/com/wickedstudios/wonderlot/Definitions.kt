package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlin.math.pow

/** Swift-style rounding: half away from zero (Kotlin's round() goes to even). */
fun Double.rounded(): Double = if (this < 0) -Math.floor(-this + 0.5) else Math.floor(this + 0.5)

/** Categories shown as tabs in the build menu. */
@Serializable
enum class BuildCategory(val displayName: String, val shortName: String, val symbolName: String) {
    path("Paths", "Paths", "square.grid.3x3"),
    attraction("Rides", "Rides", "sparkles"),
    shop("Food & Retail", "Food", "cart"),
    games("Games", "Games", "target"),
    facility("Guest Services", "Guests", "figure.stand"),
    coaster("Coaster Builder", "Coaster Kit", "point.topleft.down.curvedto.point.bottomright.up"),
    transport("Transport", "Transit", "tram.fill"),
    scenery("Scenery", "Scenery", "tree.fill"),
}

/**
 * Everything the build menu can place shares this surface, so the menu and
 * the placement validator never need to know about concrete types.
 */
interface BuildableDefinition {
    val id: String
    val displayName: String
    val summary: String
    val category: BuildCategory
    val purchasePrice: Double
    val footprint: GridSize
    val unlockLevel: Int

    /** Whether the placed object must touch a walkable tile to function. */
    val requiresPathAccess: Boolean get() = true
    val requiresTrackAccess: Boolean get() = false
    val requiresCoasterTrackAccess: Boolean get() = false

    /** Terrain this is built on top of rather than beside. */
    val bedTerrain: TerrainType? get() = null
    val maySitBesideBed: Boolean get() = false
    val mayStandOnWalkway: Boolean get() = false
    val leavesWalkwayOpen: Boolean get() = false

    /** Quarter turns this can be put at, in the order they are cycled through. */
    val allowedTurns: List<Int> get() = listOf(0, 1, 2, 3)
    val laysCoasterTrack: Boolean get() = false
    val previewAppearance: BuildingAppearance? get() = null

    fun footprint(rotatedBy: Int): GridSize = footprint.rotated(rotatedBy)

    /** Everything but terrain can be turned; coaster pieces only when not square. */
    val canRotate: Boolean
        get() {
            if (this is TerrainDefinition) return false
            if (laysCoasterTrack) return footprint.width != footprint.height
            return true
        }

    /** The next turn after [current]. */
    fun nextTurn(current: Int): Int {
        val turns = allowedTurns
        val index = turns.indexOf(((current % 4) + 4) % 4)
        if (index < 0) return turns.firstOrNull() ?: 0
        return turns[(index + 1) % turns.size]
    }

    /** [current] if this can stand at it, otherwise the nearest it can. */
    fun settledTurn(current: Int): Int =
        if (allowedTurns.contains(((current % 4) + 4) % 4)) current else (allowedTurns.firstOrNull() ?: 0)
}

/** Terrain rather than an object: placing one repaints a tile. */
data class TerrainDefinition(
    override val id: String,
    override val displayName: String,
    override val summary: String,
    override val purchasePrice: Double,
    val refundValue: Double,
    val terrain: TerrainType,
    val style: Int = 0,
    val placeableOn: Set<TerrainType> = setOf(TerrainType.grass),
    override val category: BuildCategory,
    val beauty: Double,
    val beautyRadius: Int,
) : BuildableDefinition {
    override val footprint: GridSize get() = GridSize.single
    override val unlockLevel: Int get() = 1
    override val requiresPathAccess: Boolean get() = false
}

// region Colours and appearance

@Serializable
enum class ParkColour {
    red, orange, amber, yellow, lime, green, teal, cyan, blue, indigo, violet, pink,
    cream, sand, brown, slate, charcoal, white;

    /** The colour a flower bed sets against this one. */
    val flowerCompanion: ParkColour
        get() = when (this) {
            red -> white
            orange -> yellow
            yellow -> orange
            violet -> pink
            blue -> white
            white -> pink
            else -> yellow
        }
}

/** The two colours a park paints its own furniture in. */
@Serializable
data class ParkScheme(
    var primary: ParkColour = ParkColour.teal,
    var trim: ParkColour = ParkColour.cream,
)

@Serializable
enum class BuildingMotion { none, spin, swing, rise, circuit, bob, launch, slide, hover, surf, race, bumper, pop, orbit, invert, drift, zip }

/** The silhouette a building is drawn with. */
@Serializable
enum class BuildingMotif {
    carousel, swingBoat, dropTower, coaster, megaCoaster, ferrisWheel, teacups, bumperCars,
    hauntedHouse, goKarts, logFlume, slingshot, carpetSlide, trainStation, bumperBoats,
    fishingBoats, wavePool, skyGliders, mirrorMaze, swingChairs, pendulumArm, riverRapids,
    lanternCruise, zipLine, miniGolf, coasterStation, hedge, picnicTable, flagPole, gardenArch,
    clockTower, stall, kiosk, basketballGame, waterRaceGame, balloonGame, targetGame, moleGame,
    strengthTester, ringTossGame, burgerStall, pizzaStall, drinkKiosk, iceCreamStall,
    souvenirShop, shopFront, restroom, bench, bin, tree, conifer, flowerBed, fountain, lamp,
    topiary, statue, lilyPads, reeds, waterRock, luxuryRestroom, popcornCart, floatingLanterns,
    pondFountain;

    /** Colours the player can pick for this shape. Empty for everything fixed by design. */
    val colourChoices: List<ParkColour>
        get() = when (this) {
            flowerBed -> listOf(ParkColour.pink, ParkColour.red, ParkColour.orange, ParkColour.yellow,
                ParkColour.violet, ParkColour.blue, ParkColour.white)
            else -> emptyList()
        }

    /** How many different ways this shape is drawn. */
    val variantCount: Int
        get() = when (this) {
            tree -> 4
            conifer -> 3
            flowerBed -> 3
            topiary -> 3
            statue -> 3
            lamp -> 2
            fountain -> 2
            lilyPads -> 3
            reeds -> 3
            waterRock -> 3
            floatingLanterns -> 2
            pondFountain -> 2
            hedge -> 3
            picnicTable -> 2
            flagPole -> 3
            gardenArch -> 2
            clockTower -> 2
            else -> 1
        }

    /** Park furniture painted in whatever colours the park has chosen. */
    val followsParkScheme: Boolean
        get() = when (this) {
            lamp, bench, bin, fountain, statue, picnicTable, flagPole, gardenArch, clockTower -> true
            else -> false
        }

    /** What moves once the building is running. */
    val motion: BuildingMotion
        get() = when (this) {
            carousel, ferrisWheel, teacups -> BuildingMotion.spin
            swingBoat -> BuildingMotion.swing
            dropTower -> BuildingMotion.rise
            coaster, megaCoaster, logFlume, fishingBoats, skyGliders, lanternCruise -> BuildingMotion.circuit
            swingChairs -> BuildingMotion.orbit
            pendulumArm -> BuildingMotion.invert
            riverRapids -> BuildingMotion.drift
            zipLine -> BuildingMotion.zip
            goKarts -> BuildingMotion.race
            bumperCars, bumperBoats -> BuildingMotion.bumper
            slingshot -> BuildingMotion.launch
            carpetSlide -> BuildingMotion.slide
            hauntedHouse -> BuildingMotion.hover
            wavePool -> BuildingMotion.surf
            fountain, pondFountain -> BuildingMotion.bob
            moleGame -> BuildingMotion.pop
            strengthTester -> BuildingMotion.rise
            else -> BuildingMotion.none
        }
}

/**
 * How a placed building is drawn: a shape and three colour roles; the
 * rendering layer decides what those mean in pixels.
 */
@Serializable
data class BuildingAppearance(
    val motif: BuildingMotif,
    var primary: ParkColour,
    var secondary: ParkColour,
    var accent: ParkColour,
    var variant: Int = 0,
) {
    fun withVariant(variant: Int): BuildingAppearance =
        copy(variant = if (motif.variantCount > 1) variant % motif.variantCount else 0)

    /** Repaints one building in a colour the player picked for it. */
    fun tinted(colour: ParkColour?): BuildingAppearance {
        if (colour == null) return this
        val copy = copy(primary = colour)
        // A flower bed is two colours set against each other.
        if (motif == BuildingMotif.flowerBed) copy.secondary = colour.flowerCompanion
        return copy
    }

    /** Repaints park furniture in the park's own colours. */
    fun applying(scheme: ParkScheme): BuildingAppearance {
        if (!motif.followsParkScheme) return this
        return copy(primary = scheme.primary, accent = scheme.trim)
    }

    companion object {
        /** Used when a saved building names a definition this build no longer has. */
        val unknown = BuildingAppearance(BuildingMotif.shopFront, ParkColour.slate, ParkColour.charcoal, ParkColour.cream)
    }
}

// endregion

// region Rides

@Serializable
enum class CoasterCarStyle(val displayName: String) {
    classic("Classic"), rocket("Rocket"), mineCart("Mine Cart"), bobsled("Bobsled")
}

object CoasterContent {
    val liveries: List<ParkColour> = listOf(
        ParkColour.red, ParkColour.orange, ParkColour.amber, ParkColour.lime, ParkColour.green,
        ParkColour.teal, ParkColour.cyan, ParkColour.blue, ParkColour.indigo, ParkColour.violet,
        ParkColour.pink, ParkColour.charcoal,
    )
}

/** How a ride is filed in the build menu. */
@Serializable
enum class RideGroup(val displayName: String, val symbolName: String) {
    gentle("Gentle", "leaf.fill"),
    family("Family", "figure.2.and.child.holdinghands"),
    thrill("Thrill", "bolt.fill"),
    water("Water", "drop.fill"),
}

/** What a boardable building actually does with the guests it takes on. */
@Serializable
enum class AttractionKind { ride, transport, custom }

@Serializable
data class AttractionDefinition(
    override val id: String,
    override val displayName: String,
    override val summary: String,
    override val purchasePrice: Double,
    /** Guests carried per cycle. */
    val capacity: Int,
    /** Sim-seconds the ride runs for once loaded. */
    val rideDuration: Double,
    /** Sim-seconds spent loading and unloading between cycles. */
    val loadDuration: Double,
    /** 0-100. Drives how well the ride matches a guest's thrill preference. */
    val excitement: Double,
    /** 0-100. Nausea inflicted on riders. */
    val nausea: Double,
    /** Condition percentage lost per sim-second of operation. */
    val maintenanceRate: Double,
    /** Charged each time the ride completes a cycle. */
    val operatingCostPerCycle: Double,
    override val footprint: GridSize,
    override val unlockLevel: Int,
    val appearance: BuildingAppearance,
    val kind: AttractionKind = AttractionKind.ride,
    val group: RideGroup = RideGroup.family,
    val needsWater: Boolean = false,
) : BuildableDefinition {

    override val category: BuildCategory
        get() = when (kind) {
            AttractionKind.ride -> BuildCategory.attraction
            AttractionKind.custom -> BuildCategory.coaster
            AttractionKind.transport -> BuildCategory.transport
        }

    override val requiresTrackAccess: Boolean get() = kind == AttractionKind.transport
    override val requiresCoasterTrackAccess: Boolean get() = kind == AttractionKind.custom
    override val bedTerrain: TerrainType? get() = if (needsWater) TerrainType.water else null

    /** Never upside down: a quarter turn either way is the whole of what turning is for. */
    override val allowedTurns: List<Int> get() = listOf(0, 1, 3)
    override val previewAppearance: BuildingAppearance? get() = appearance

    /** The same ride with its purchased upgrades folded in. */
    fun applying(
        upgrades: Map<String, Int>,
        trackLength: Int = 0,
        trackThrill: Double = 0.0,
        coaster: CoasterRating? = null,
    ): AttractionDefinition {
        if (upgrades.isEmpty() && kind != AttractionKind.custom) return this
        fun level(kind: RideUpgradeKind): Int = upgrades[kind.name] ?: 0

        val track = if (kind == AttractionKind.custom) trackLength.toDouble() else 0.0
        val thrill = if (kind == AttractionKind.custom) trackThrill else 0.0
        val trackExcitement = coaster?.excitementBonus ?: (minOf(30.0, track * 0.7) + minOf(35.0, thrill))
        val trackDuration = coaster?.duration ?: minOf(150.0, track * 1.6)

        return copy(
            capacity = (capacity * UpgradeContent.capacityFactor(level(RideUpgradeKind.capacity))).rounded().toInt(),
            rideDuration = rideDuration + trackDuration,
            loadDuration = loadDuration * UpgradeContent.loadingFactor(level(RideUpgradeKind.loading)),
            excitement = SimMath.clamp(excitement + trackExcitement +
                UpgradeContent.themingExcitement(level(RideUpgradeKind.theming))),
            nausea = minOf(100.0, nausea + (coaster?.nauseaBonus ?: 0.0)),
            maintenanceRate = maintenanceRate * UpgradeContent.wearFactor(level(RideUpgradeKind.reliability)) *
                (coaster?.wearFactor ?: 1.0),
            operatingCostPerCycle = operatingCostPerCycle + (coaster?.runningCost ?: 0.0),
        )
    }

    /** Coarse label used in the build menu and ride inspector. */
    val thrillLabel: String
        get() = when {
            excitement < 25 -> "Gentle"
            excitement < 50 -> "Family"
            excitement < 75 -> "Thrilling"
            else -> "Extreme"
        }
}

// endregion

// region Facilities

@Serializable
enum class FacilityKind {
    food, drink, souvenir,

    /** A carnival booth: pay, play, and maybe walk away with a prize. */
    game,
    bathroom, bench, bin;

    /** Kinds that take the guest's money and therefore expose a price control. */
    val sellsGoods: Boolean get() = this == food || this == drink || this == souvenir || this == game

    /** Park furniture: it stands on the walkway and guests walk round it. */
    val isFurniture: Boolean get() = this == bench || this == bin

    /** Kinds whose visits are counted as they begin. */
    val countsVisits: Boolean get() = this == bathroom || this == bench

    val visitorNoun: String
        get() = when (this) {
            bathroom -> "Visits"
            bench -> "Guests seated"
            else -> "Customers"
        }

    /** Kinds that get dirty or fill up and need a janitor's attention. */
    val needsServicing: Boolean get() = this == bathroom || this == bin

    val servicingVerb: String get() = if (this == bin) "Emptying" else "Cleaning"
}

/**
 * How much a single use of a facility moves a guest's needs. Positive values
 * on hunger/thirst/bathroom mean the need is *reduced* by that amount.
 */
@Serializable
data class NeedRelief(
    var hunger: Double = 0.0,
    var thirst: Double = 0.0,
    var bathroom: Double = 0.0,
    var energy: Double = 0.0,
    var happiness: Double = 0.0,
    var nausea: Double = 0.0,
)

@Serializable
data class FacilityDefinition(
    override val id: String,
    override val displayName: String,
    override val summary: String,
    val kind: FacilityKind,
    override val purchasePrice: Double,
    /** Price the shop opens with; the player can change it afterwards. */
    val defaultPrice: Double,
    /** What each sale costs the park. */
    val unitCost: Double,
    /** The price guests consider fair. */
    val referencePrice: Double,
    /** Sim-seconds one guest occupies a service slot. */
    val serviceDuration: Double,
    val simultaneousCapacity: Int,
    val queueCapacity: Int,
    val relief: NeedRelief,
    override val footprint: GridSize,
    override val unlockLevel: Int,
    val appearance: BuildingAppearance,
    val winChance: Double = 0.0,
    val drawFactor: Double = 1.0,
    /** How long a janitor needs to turn this round, in park minutes. Zero means emptied on the spot. */
    val cleaningMinutes: Double = 0.0,
    val soilingPerUse: Double = Balance.bathroomSoilPerUse,
    val ratingWeight: Double = 1.0,
    val carriesSnack: Boolean = false,
) : BuildableDefinition {

    val acceptsUpgrades: Boolean get() = kind.sellsGoods

    override val category: BuildCategory
        get() = when (kind) {
            FacilityKind.game -> BuildCategory.games
            FacilityKind.food, FacilityKind.drink, FacilityKind.souvenir -> BuildCategory.shop
            FacilityKind.bathroom, FacilityKind.bench, FacilityKind.bin -> BuildCategory.facility
        }

    override val bedTerrain: TerrainType? get() = if (kind.isFurniture) TerrainType.path else null
    override val requiresPathAccess: Boolean get() = !kind.isFurniture
    override val maySitBesideBed: Boolean get() = kind.isFurniture

    /** Never upside down, except park furniture which reads the same any way up. */
    override val allowedTurns: List<Int> get() = if (kind.isFurniture) listOf(0, 1, 2, 3) else listOf(0, 1, 3)
    override val previewAppearance: BuildingAppearance? get() = appearance

    val profitPerSale: Double get() = defaultPrice - unitCost

    /** The same shop with its purchased upgrades folded in. */
    fun applying(upgrades: Map<String, Int>): FacilityDefinition {
        if (upgrades.isEmpty()) return this
        fun level(kind: ShopUpgradeKind): Double = (upgrades[kind.name] ?: 0).toDouble()

        val service = level(ShopUpgradeKind.service)
        val quality = level(ShopUpgradeKind.quality)
        val signage = level(ShopUpgradeKind.signage)

        val improved = relief.copy(happiness = relief.happiness + quality * 3)

        return copy(
            referencePrice = referencePrice * (1 + quality * 0.18),
            simultaneousCapacity = simultaneousCapacity + service.toInt(),
            queueCapacity = queueCapacity + service.toInt() * 2,
            relief = improved,
            winChance = minOf(0.85, if (winChance > 0) winChance + quality * 0.06 else 0.0),
            drawFactor = drawFactor * (1 + signage * 0.18),
        )
    }
}

// endregion

/** Something built purely to look at. */
@Serializable
data class SceneryDefinition(
    override val id: String,
    override val displayName: String,
    override val summary: String,
    override val purchasePrice: Double,
    /** Prettiness this adds to its own tile, 0-100. */
    val beauty: Double,
    /** How many tiles away the effect still reaches. */
    val beautyRadius: Int,
    override val footprint: GridSize,
    override val unlockLevel: Int,
    val appearance: BuildingAppearance,
    /** Whether this is something a guest walks under (an arch). */
    val spansWalkway: Boolean = false,
    /** Whether this belongs on the water rather than the ground. */
    val onWater: Boolean = false,
) : BuildableDefinition {
    override val category: BuildCategory get() = BuildCategory.scenery
    override val bedTerrain: TerrainType? get() = if (onWater) TerrainType.water else null
    override val leavesWalkwayOpen: Boolean get() = true
    override val previewAppearance: BuildingAppearance? get() = appearance
    override val requiresPathAccess: Boolean get() = false
    override val mayStandOnWalkway: Boolean get() = spansWalkway

    fun beautyAt(distance: Int): Double {
        if (distance > beautyRadius) return 0.0
        if (beautyRadius <= 0) return beauty
        val falloff = 1 - distance.toDouble() / (beautyRadius + 1)
        return beauty * falloff
    }
}

/** A piece of coaster that spans several tiles. */
data class CoasterElementDefinition(
    override val id: String,
    override val displayName: String,
    override val summary: String,
    override val purchasePrice: Double,
    /** What this adds to a circuit, on the same scale the ride's excitement uses. */
    val thrill: Double,
    /** How hard the train is thrown as it crosses. 1 is no reaction. */
    val intensity: Double,
    override val footprint: GridSize,
    /** How many tiles tall the drawing is. */
    val visualHeight: Int,
    override val unlockLevel: Int,
    val motif: CoasterElementMotif,
) : BuildableDefinition {
    /** Where the track runs through the drawing. */
    val trackLine: Double
        get() {
            val visual = maxOf(visualHeight, 1).toDouble()
            return (visual - 0.5) / visual
        }

    override val category: BuildCategory get() = BuildCategory.coaster
    override val requiresPathAccess: Boolean get() = false
    override val laysCoasterTrack: Boolean get() = true
    override val previewAppearance: BuildingAppearance? get() = null
}

@Serializable
enum class CoasterElementMotif { verticalLoop, corkscrew, airtimeHills, jump, helixTower }

object CoasterElementContent {
    val all: List<CoasterElementDefinition> = listOf(
        CoasterElementDefinition("element.hills", "Airtime Hills",
            "A run of humps that lifts riders out of their seats. Cheap, and every circuit wants some.",
            1_400.0, 14.0, 1.22, GridSize(3, 1), 2, 1, CoasterElementMotif.airtimeHills),
        CoasterElementDefinition("element.loop", "Vertical Loop",
            "The one everybody photographs. Three tiles of track go in, and the train comes out upside down.",
            3_600.0, 26.0, 1.55, GridSize(3, 1), 3, 1, CoasterElementMotif.verticalLoop),
        CoasterElementDefinition("element.helix", "Helix Tower",
            "A tight climbing spiral. Two tiles of track go in, and a long, heavy turn comes out.",
            4_200.0, 28.0, 1.40, GridSize(2, 1), 3, 2, CoasterElementMotif.helixTower),
        CoasterElementDefinition("element.corkscrew", "Corkscrew",
            "Two barrel rolls back to back, strung out over four tiles.",
            5_000.0, 30.0, 1.45, GridSize(4, 1), 2, 2, CoasterElementMotif.corkscrew),
        CoasterElementDefinition("element.jump", "Jump",
            "A ramp, a gap, and a ramp. The train is launched across it and lands running.",
            6_500.0, 34.0, 1.85, GridSize(3, 1), 2, 3, CoasterElementMotif.jump),
    )

    private val byID = all.associateBy { it.id }
    fun definition(id: String): CoasterElementDefinition? = byID[id]
}

/** The car park outside the gate, and what paving more of it is worth. */
object CarParkContent {
    const val maxLevel = 5
    const val demandPerLevel = 0.01

    /** What the next level costs; doubling at every level. */
    fun cost(level: Int): Double? {
        if (level < 1 || level > maxLevel) return null
        return 15_000 * 2.0.pow(level - 1)
    }

    fun demandMultiplier(level: Int): Double = 1 + demandPerLevel * minOf(maxOf(level, 0), maxLevel)

    fun name(level: Int): String = when (level) {
        0 -> "Gravel Lot"
        1 -> "Paved Lot"
        2 -> "Marked Bays"
        3 -> "Overflow Field"
        4 -> "Bus Bays"
        else -> "Multi-Storey"
    }

    const val summary = "More parking means more people can get here. Each level adds one per cent to arrivals."
}
