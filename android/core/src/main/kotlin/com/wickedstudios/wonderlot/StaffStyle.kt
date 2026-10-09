package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable

/** What an entertainer does for a living. */
@Serializable
enum class EntertainerAct(
    val displayName: String,
    val summary: String,
    /** What the colour is on this act, for the label on the picker. */
    val colourLabel: String,
    val defaultColour: ParkColour,
    /** How wide a circle it works, as a share of the usual one. */
    val radiusFactor: Double,
    /** How hard it lifts the mood, as a share of the usual lift. */
    val happinessFactor: Double,
) {
    classic("Entertainer",
        "The all-rounder, with a megaphone and a party hat. Lifts the mood of everyone nearby.",
        "", ParkColour.red, 1.0, 1.0),
    clown("Clown",
        "Honks, pratfalls and a very red nose. Children cannot resist, and the lift for them is the biggest of any act.",
        "Suit", ParkColour.blue, 0.95, 0.8),
    balloonArtist("Balloon Artist",
        "Hands out balloons, children first. Guests carry them round for the rest of the visit.",
        "Vest", ParkColour.yellow, 0.9, 0.6),
    mime("Mime",
        "Hardly lifts anyone passing, but is brilliant to a queue. Put one where the waiting is.",
        "Stripes", ParkColour.charcoal, 0.8, 0.9),
    juggler("Juggler",
        "A wider circle and a bigger lift than the all-rounder. Hard to walk past.",
        "Costume", ParkColour.green, 1.15, 1.2),
    magician("Magician",
        "A modest lift all round, and now and then somebody is amazed enough to remember the whole day.",
        "Cape", ParkColour.violet, 1.0, 0.7);

    /** Whether the act has a colour of its own to choose. */
    val usesColour: Boolean get() = this != classic

    /** Multiplies the lift for a child. A clown is for them. */
    val childFactor: Double get() = if (this == clown) 2.0 else 1.0

    /** Multiplies the lift for somebody standing in a queue. */
    val queueFactor: Double get() = if (this == mime) 2.4 else 1.0

    val handsOutBalloons: Boolean get() = this == balloonArtist
    val doesTricks: Boolean get() = this == magician
}

/** The costumes a park mascot can be hired in. */
@Serializable
enum class MascotCostume(
    val displayName: String,
    val defaultPrimary: ParkColour,
    val defaultSecondary: ParkColour,
    val defaultTrim: ParkColour,
    /** What each costume's secondary colour is, for the picker. */
    val secondaryLabel: String,
    private val names: List<String>,
) {
    bear("Bear", ParkColour.brown, ParkColour.sand, ParkColour.red, "Muzzle and belly",
        listOf("Barnaby", "Bruno", "Honey")),
    frog("Frog", ParkColour.green, ParkColour.lime, ParkColour.red, "Belly",
        listOf("Freddy", "Ribbit", "Lily")),
    bunny("Bunny", ParkColour.white, ParkColour.pink, ParkColour.teal, "Ears and nose",
        listOf("Clover", "Hopper", "Bunbun")),
    duck("Duck", ParkColour.yellow, ParkColour.orange, ParkColour.blue, "Beak and feet",
        listOf("Waddles", "Dilly", "Quackers")),
    cat("Cat", ParkColour.orange, ParkColour.cream, ParkColour.indigo, "Muzzle and belly",
        listOf("Whiskers", "Mitzi", "Tango")),
    owl("Owl", ParkColour.brown, ParkColour.cream, ParkColour.amber, "Face and chest",
        listOf("Hoot", "Wisp", "Sage")),
    penguin("Penguin", ParkColour.charcoal, ParkColour.white, ParkColour.red, "Belly",
        listOf("Pip", "Gus", "Flipper")),
    dragon("Dragon", ParkColour.teal, ParkColour.amber, ParkColour.red, "Horns and belly",
        listOf("Ember", "Spark", "Draco")),
    lion("Lion", ParkColour.amber, ParkColour.brown, ParkColour.red, "Mane",
        listOf("Rory", "Goldie", "Marigold")),
    elephant("Elephant", ParkColour.slate, ParkColour.pink, ParkColour.amber, "Inner ears",
        listOf("Ellie", "Tusker", "Peanut"));

    fun name(rng: SeededGenerator): String = rng.pick(names) ?: displayName
}

/** What the player chose when hiring, or when changing an employee's look. Null means the default. */
data class StaffStyle(
    val act: EntertainerAct? = null,
    val costume: MascotCostume? = null,
    val primary: ParkColour? = null,
    val secondary: ParkColour? = null,
    val trim: ParkColour? = null,
) {
    /** The finished look, with every default filled in. */
    fun look(role: StaffRole): StaffLook {
        val costume = this.costume ?: MascotCostume.bear
        val act = this.act ?: EntertainerAct.classic

        return when (role) {
            StaffRole.mascot -> StaffLook(role, EntertainerAct.classic, costume,
                primary ?: costume.defaultPrimary,
                secondary ?: costume.defaultSecondary,
                trim ?: costume.defaultTrim)
            StaffRole.entertainer -> StaffLook(role, act, MascotCostume.bear,
                primary ?: act.defaultColour, secondary ?: ParkColour.cream, trim ?: ParkColour.red)
            else -> StaffLook(role, EntertainerAct.classic, MascotCostume.bear,
                ParkColour.teal, ParkColour.cream, ParkColour.red)
        }
    }

    companion object {
        val standard = StaffStyle()
    }
}

/** Everything the artwork needs to draw an employee, with every default filled in. */
data class StaffLook(
    val role: StaffRole,
    val act: EntertainerAct,
    val costume: MascotCostume,
    val primary: ParkColour,
    val secondary: ParkColour,
    val trim: ParkColour,
)

/** How an employee who performs affects the guests around them. */
class PerformerProfile(
    val radius: Double,
    /** Multiplies the base entertainer happiness rate. */
    val happinessFactor: Double,
    val queueFactor: Double,
    val childFactor: Double,
    val handsOutBalloons: Boolean,
    val doesTricks: Boolean,
) {
    companion object {
        fun of(member: Staff): PerformerProfile {
            if (member.role == StaffRole.mascot) {
                return PerformerProfile(
                    Balance.entertainerRadius * Balance.mascotRadiusFactor,
                    Balance.mascotHappinessFactor, 1.4, Balance.mascotChildFactor, false, false)
            }
            val act = member.resolvedAct
            return PerformerProfile(Balance.entertainerRadius * act.radiusFactor, act.happinessFactor,
                act.queueFactor, act.childFactor, act.handsOutBalloons, act.doesTricks)
        }
    }
}
