@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.util.UUID

/** Anything a guest can decide to walk towards. */
@Serializable
sealed class ParkTarget {
    @Serializable data class Ride(val id: UUID) : ParkTarget()
    @Serializable data class Shop(val id: UUID) : ParkTarget()
    @Serializable data object Exit : ParkTarget()
    @Serializable data class Wander(val spot: GridCoord) : ParkTarget()
}

@Serializable
sealed class GuestActivity {
    /** Walking in from the entrance before the first decision. */
    @Serializable data object Arriving : GuestActivity()

    /** Walking somewhere with no particular goal. */
    @Serializable data object Exploring : GuestActivity()
    @Serializable data class Walking(val target: ParkTarget) : GuestActivity()
    @Serializable data class Queueing(val target: ParkTarget) : GuestActivity()

    /** Riding, being served, or sitting. */
    @Serializable data class Engaged(val target: ParkTarget) : GuestActivity()
    @Serializable data object Departed : GuestActivity()
}

@Serializable
enum class AgeCategory(val displayName: String) {
    child("Child"), adult("Adult"), senior("Senior")
}

@Serializable
enum class ThoughtMood { positive, neutral, negative }

/** What a thought is about, so a bubble over a guest's head can say it without words. */
@Serializable
enum class ThoughtIcon(val symbolName: String) {
    general("bubble.left.fill"),
    food("fork.knife"),
    drink("cup.and.saucer.fill"),
    restroom("figure.stand"),
    ride("sparkles"),
    money("dollarsign.circle.fill"),
    tired("figure.seated.side"),
    dirty("trash.fill"),
    queue("clock.fill"),
}

@Serializable
data class GuestThought(
    val id: UUID = UUID.randomUUID(),
    val text: String,
    val mood: ThoughtMood,
    /** Sim time the thought occurred, used to age thoughts out of the panel. */
    val simTime: Double,
    val icon: ThoughtIcon = ThoughtIcon.general,
)

/** Randomised traits that make two guests in identical circumstances behave differently. All 0-100. */
@Serializable
data class GuestPersonality(
    var thrillPreference: Double = 50.0,
    var patience: Double = 50.0,
    var spending: Double = 50.0,
    var cleanlinessSensitivity: Double = 50.0,
) {
    companion object {
        fun random(age: AgeCategory, rng: SeededGenerator): GuestPersonality {
            val thrillCentre = when (age) {
                AgeCategory.child -> 45.0
                AgeCategory.adult -> 60.0
                AgeCategory.senior -> 30.0
            }
            return GuestPersonality(
                thrillPreference = SimMath.clamp(rng.double((thrillCentre - 35)..(thrillCentre + 35))),
                patience = rng.double(10.0..95.0),
                spending = rng.double(15.0..95.0),
                cleanlinessSensitivity = rng.double(10.0..95.0),
            )
        }
    }
}

/** What one guest looks like: colours and a handful of choices. */
@Serializable
data class GuestAppearance(
    val shirt: ParkColour = ParkColour.blue,
    val hair: HairColour = HairColour.brown,
    val skin: SkinTone = SkinTone.tan,
    val hat: HatStyle = HatStyle.none,
    /** Trousers, shorts or a skirt, kept to a muted range. */
    val bottoms: ParkColour = ParkColour.slate,
    val pattern: ShirtPattern = ShirtPattern.plain,
    /** What they brought with them for the day. */
    val accessory: Accessory = Accessory.none,
) {
    @Serializable enum class HairColour { dark, brown, sandy, ginger, grey }
    @Serializable enum class SkinTone { deep, tan, olive, fair }

    @Serializable
    enum class HatStyle {
        none, cap, sunHat, visor,

        /** Novelty headband with two pom-poms, bought inside the park. */
        bobbleBand,

        /** Kept for the park's occasional nuisance. */
        hood
    }

    @Serializable enum class ShirtPattern { plain, stripes, vest }

    @Serializable
    enum class Accessory {
        none, sunglasses, backpack, camera,

        /** Held up in front of them, filming. Only the park's occasional famous visitor carries one. */
        phone
    }

    companion object {
        /** Shirt colours guests actually wear. */
        val shirtColours = listOf(
            ParkColour.red, ParkColour.orange, ParkColour.yellow, ParkColour.lime, ParkColour.teal,
            ParkColour.cyan, ParkColour.blue, ParkColour.violet, ParkColour.pink, ParkColour.cream,
        )

        /** Legwear. Denim, khaki and dark, plus two brighter ones for children. */
        val bottomsColours = listOf(
            ParkColour.indigo, ParkColour.slate, ParkColour.charcoal, ParkColour.brown,
            ParkColour.sand, ParkColour.blue,
        )

        val unknown = GuestAppearance(ParkColour.blue, HairColour.brown, SkinTone.tan, HatStyle.none)

        fun random(age: AgeCategory, rng: SeededGenerator): GuestAppearance {
            val shirt = shirtColours[rng.int(0..(shirtColours.size - 1))]
            val bottoms = bottomsColours[rng.int(0..(bottomsColours.size - 1))]

            // Older guests grey; children almost never do.
            var hairChoices = HairColour.entries.filter { it != HairColour.grey }
            if (age == AgeCategory.senior) {
                hairChoices = listOf(HairColour.grey, HairColour.grey, HairColour.dark, HairColour.sandy)
            }
            val hair = hairChoices[rng.int(0..(hairChoices.size - 1))]

            val skin = SkinTone.entries[rng.int(0..(SkinTone.entries.size - 1))]

            val roll = rng.double(0.0..1.0)
            val hat = when (age) {
                AgeCategory.senior -> if (roll < 0.32) HatStyle.sunHat else if (roll < 0.48) HatStyle.cap
                else if (roll < 0.58) HatStyle.visor else HatStyle.none
                AgeCategory.child -> if (roll < 0.26) HatStyle.cap else if (roll < 0.46) HatStyle.bobbleBand
                else if (roll < 0.54) HatStyle.visor else HatStyle.none
                AgeCategory.adult -> if (roll < 0.24) HatStyle.cap else if (roll < 0.36) HatStyle.sunHat
                else if (roll < 0.48) HatStyle.visor else HatStyle.none
            }

            val patternRoll = rng.double(0.0..1.0)
            val pattern = if (patternRoll < 0.58) ShirtPattern.plain
            else if (patternRoll < 0.82) ShirtPattern.stripes else ShirtPattern.vest

            val accessoryRoll = rng.double(0.0..1.0)
            val accessory = when (age) {
                AgeCategory.child -> if (accessoryRoll < 0.30) Accessory.backpack else Accessory.none
                AgeCategory.adult -> if (accessoryRoll < 0.20) Accessory.camera
                else if (accessoryRoll < 0.38) Accessory.backpack
                else if (accessoryRoll < 0.52) Accessory.sunglasses else Accessory.none
                AgeCategory.senior -> if (accessoryRoll < 0.22) Accessory.camera
                else if (accessoryRoll < 0.40) Accessory.sunglasses else Accessory.none
            }

            return GuestAppearance(shirt, hair, skin, hat, bottoms, pattern, accessory)
        }
    }
}

/** Something a guest won at a carnival booth and is now carrying around. */
@Serializable
data class GuestPrize(
    val kind: Kind,
    val colour: ParkColour,
    val size: Size = Size.small,
) {
    @Serializable
    enum class Size(val scale: Double, val adjective: String?) {
        small(0.85, null), big(1.25, "big"), giant(1.60, "giant");

        /** A giant prize is too big to tuck under an arm, so it is carried with both arms round it. */
        val isHugged: Boolean get() = this == giant
    }

    @Serializable
    enum class Kind(val displayName: String) {
        bear("bear"), dog("dog"), bunny("bunny"), duck("duck"), star("star"), ball("beach ball")
    }

    /** "giant pink bear", for the thought a guest has on winning it. */
    val displayName: String
        get() {
            val adjective = size.adjective ?: return "$colourName ${kind.displayName}"
            return "$adjective $colourName ${kind.displayName}"
        }

    private val colourName: String
        get() = when (colour) {
            ParkColour.cyan -> "blue"
            ParkColour.lime -> "green"
            ParkColour.violet -> "purple"
            ParkColour.amber -> "gold"
            else -> colour.name
        }

    companion object {
        /** Prize colours: the loud end of the palette. */
        val colours = listOf(
            ParkColour.pink, ParkColour.cyan, ParkColour.yellow, ParkColour.lime,
            ParkColour.violet, ParkColour.red, ParkColour.orange, ParkColour.teal,
        )

        /** [winChance] is how easy the booth is: hard booths hand out the big prizes. */
        fun random(rng: SeededGenerator, winChance: Double): GuestPrize {
            val kinds = Kind.entries
            val kind = kinds[rng.int(0..(kinds.size - 1))]
            val colour = colours[rng.int(0..(colours.size - 1))]

            val difficulty = 1 - minOf(maxOf(winChance, 0.0), 1.0)
            val roll = rng.double(0.0..1.0)
            val size = if (roll < difficulty * difficulty * 0.8) Size.giant
            else if (roll < difficulty) Size.big else Size.small

            return GuestPrize(kind, colour, size)
        }
    }
}

/** One visitor. Systems mutate guests in place. */
@Serializable
class Guest(
    val id: UUID = UUID.randomUUID(),
    var name: String = "Guest",
    var ageCategory: AgeCategory = AgeCategory.adult,
    var personality: GuestPersonality = GuestPersonality(),
    var appearance: GuestAppearance = GuestAppearance.unknown,
    /** A visitor with an audience. */
    var isInfluencer: Boolean = false,
    /** Set once they have posted, so one visit is one post. */
    var hasPosted: Boolean = false,
    /** A visitor quietly scoring the park. */
    var isCritic: Boolean = false,
    /** A visitor here to be a nuisance, until security sees them off. */
    var isTroublemaker: Boolean = false,
    var troublemakerUntil: Double = 0.0,
    /** Rubbish they have dropped, for the report afterwards. */
    var troublemakerLitter: Int = 0,
    /** The party they arrived with, for guests who came in on a tour bus. */
    var groupID: UUID? = null,

    // Money
    var cash: Double = 0.0,
    var moneySpent: Double = 0.0,

    // Needs. 100 means "most urgent" for hunger, thirst, bathroom and nausea;
    // energy and happiness read the other way round.
    var happiness: Double = 70.0,
    var hunger: Double = 0.0,
    var thirst: Double = 0.0,
    var energy: Double = 100.0,
    var bathroomNeed: Double = 0.0,
    var nausea: Double = 0.0,

    // Position and movement, in tile-space (1 unit == 1 tile).
    override var position: Vec2 = Vec2(0.0, 0.0),
    override var tile: GridCoord = GridCoord.zero,
    override var route: MutableList<GridCoord> = mutableListOf(),
    var walkSpeed: Double = Balance.guestWalkSpeed,

    // Behaviour
    var activity: GuestActivity = GuestActivity.Exploring,
    var nextDecisionAt: Double = 0.0,
    var queueJoinedAt: Double = 0.0,
    var queueWaitEstimate: Double = 0.0,
    var queueSlot: Int = 0,
    /** Rides taken recently, so a guest does not loop on one attraction. */
    var recentAttractions: MutableList<UUID> = mutableListOf(),

    // Statistics
    var timeInPark: Double = 0.0,
    var plannedVisitLength: Double = Balance.visitLengthBase,
    var ridesRidden: Int = 0,
    var purchases: Int = 0,
    /** Pieces of rubbish the guest is holding. */
    var carryingTrash: Int = 0,
    var trashCarriedFor: Double = 0.0,
    /** What they won at a carnival booth, if anything. */
    var prize: GuestPrize? = null,
    var prizesWon: Int = 0,
    /** Sim-seconds of popcorn left in the bag they are carrying. */
    var popcornRemaining: Double = 0.0,
    /** A balloon a balloon artist gave them, carried for the rest of the visit. */
    var balloon: ParkColour? = null,
    var thoughts: MutableList<GuestThought> = mutableListOf(),
    /** Set when the guest decides to go home; recorded on departure. */
    var departureReason: String? = null,
) : Walker {
    val isActive: Boolean get() = activity !is GuestActivity.Departed

    /** Adds a thought, keeping only the most recent handful. */
    fun think(text: String, mood: ThoughtMood, simTime: Double, icon: ThoughtIcon = ThoughtIcon.general) {
        // Avoid repeating the same thought back-to-back.
        if (thoughts.lastOrNull()?.text == text) return
        thoughts.add(GuestThought(text = text, mood = mood, simTime = simTime, icon = icon))
        if (thoughts.size > 8) {
            val excess = thoughts.size - 8
            repeat(excess) { thoughts.removeAt(0) }
        }
    }

    fun adjustHappiness(delta: Double) {
        happiness = SimMath.clamp(happiness + delta)
    }
}
