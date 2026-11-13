package com.wickedstudios.wonderlot

import java.util.Calendar

/** A calendar day. Kept apart from java.time, which older Android versions do not have. */
data class CalendarDate(val year: Int, val month: Int, val day: Int) {
    companion object {
        private var cached: CalendarDate? = null
        private var cachedAt = 0L

        /** Today's date. Asked for on every frame by the renderer, so the calendar is only read every few seconds. */
        fun today(): CalendarDate {
            val stamp = System.nanoTime()
            cached?.let { if (stamp - cachedAt < 5_000_000_000L) return it }
            val now = Calendar.getInstance()
            val date = CalendarDate(now.get(Calendar.YEAR), now.get(Calendar.MONTH) + 1, now.get(Calendar.DAY_OF_MONTH))
            cached = date
            cachedAt = stamp
            return date
        }
    }
}

/**
 * The holiday event: 25 November to 5 January, every year, by the player's own date.
 *
 * Everything seasonal asks this one place whether it is on. A park that is part-way through a holiday trial keeps
 * the season on for itself even if the calendar rolls over, so a trial begun in time can always be finished.
 */
object HolidaySeason {
    const val startMonth = 11
    const val startDay = 25
    const val endMonth = 1
    const val endDay = 5

    /** Developer-only: forces the season on or off. Null follows the calendar. Never set from the game's own screens. */
    @Volatile
    var override: Boolean? = null

    /** Where today's date comes from; replaced in tests. */
    @Volatile
    var clock: () -> CalendarDate = { CalendarDate.today() }

    fun inWindow(date: CalendarDate): Boolean = when (date.month) {
        11 -> date.day >= startDay
        12 -> true
        1 -> date.day <= endDay
        else -> false
    }

    fun isActive(date: CalendarDate = clock()): Boolean = override ?: inWindow(date)

    /** Whether a park should treat the season as on: the calendar, or a holiday trial it is part-way through. */
    fun isActive(state: GameState): Boolean = isActive() || state.trial?.series == TrialSeries.holiday

    /** The year the event began in, so 1 to 5 January belongs to the year before. */
    fun eventYear(date: CalendarDate = clock()): Int = if (date.month <= endMonth) date.year - 1 else date.year

    /** Whole days left in the event including today, or 0 outside it. */
    fun daysLeft(date: CalendarDate = clock()): Int {
        if (!isActive(date)) return 0
        val end = Calendar.getInstance().apply {
            clear()
            val year = if (date.month == 1) date.year else date.year + 1
            set(year, Calendar.JANUARY, endDay)
        }
        val today = Calendar.getInstance().apply { clear(); set(date.year, date.month - 1, date.day) }
        val days = ((end.timeInMillis - today.timeInMillis) / 86_400_000L).toInt() + 1
        return maxOf(1, days)
    }

    const val datesLabel = "25 November to 5 January"
    const val shortDatesLabel = "Nov 25 to Jan 5"
}

/** What kind of thing a holiday trial hands over. */
enum class HolidayRewardKind { decoration, makeover, ride, performer }

/** One thing a holiday trial unlocks. Earned once, kept for good, and usable whenever the event is on. */
class HolidayReward(
    val id: String,
    val kind: HolidayRewardKind,
    val title: String,
    val detail: String,
    val symbolName: String,
    /** The catalogue ids (rides, decorations) or performer name this opens. */
    val opens: List<String>,
)

object HolidayRewards {
    val all: List<HolidayReward> = listOf(
        HolidayReward("reward.giftstack", HolidayRewardKind.decoration, "Gift Stack",
            "A pile of wrapped presents for the walkway.", "gift.fill", listOf("scenery.xmas.gifts")),
        HolidayReward("reward.lightpole", HolidayRewardKind.decoration, "String-Light Pole",
            "A tall pole hung with warm lights.", "lightbulb.fill", listOf("scenery.xmas.lights")),
        HolidayReward("reward.candycane", HolidayRewardKind.decoration, "Candy Cane Post",
            "A giant striped cane to mark a corner.", "heart.fill", listOf("scenery.xmas.candycane")),
        HolidayReward("reward.fireworks", HolidayRewardKind.decoration, "Fireworks Stand",
            "A rack of rockets that never quite goes off.", "sparkles", listOf("scenery.newyear.fireworks")),
        HolidayReward("reward.countdown", HolidayRewardKind.decoration, "Countdown Clock",
            "A tall clock counting down to midnight.", "clock.fill", listOf("scenery.newyear.clock")),

        HolidayReward("reward.makeover.gentle", HolidayRewardKind.makeover, "Gentle Rides Makeover",
            "Snow, ribbon and fairy lights for the Carousel, Wonder Putt, Haunted Manor and the slow rides.",
            "paintbrush.fill", HolidayMakeovers.idsFor(MakeoverSet.gentle)),
        HolidayReward("reward.makeover.family", HolidayRewardKind.makeover, "Family Rides Makeover",
            "A festive coat for the Teacups, Bumper Cars, Carpet Slide, Go Karts and the family rides.",
            "paintbrush.fill", HolidayMakeovers.idsFor(MakeoverSet.family)),
        HolidayReward("reward.makeover.thrill", HolidayRewardKind.makeover, "Thrill Rides Makeover",
            "Frosted towers and tinsel track for the Galleon, Sky Plunge, Sapling Coaster and the big thrills.",
            "paintbrush.fill", HolidayMakeovers.idsFor(MakeoverSet.thrill)),
        HolidayReward("reward.makeover.water", HolidayRewardKind.makeover, "Water Rides Makeover",
            "Icicles and lanterns for the flume, the rapids, the cruises and the pool.",
            "paintbrush.fill", HolidayMakeovers.idsFor(MakeoverSet.water)),

        HolidayReward("reward.ride.candycoaster", HolidayRewardKind.ride, "Candy Cane Coaster",
            "A coaster on candy-striped track.", "figure.walk", listOf("ride.xmas.candycoaster")),
        HolidayReward("reward.ride.startopper", HolidayRewardKind.ride, "Star Topper Drop",
            "A drop tower dressed as a tree, with a star on top.", "star.fill", listOf("ride.xmas.startopper")),
        HolidayReward("reward.ride.starburst", HolidayRewardKind.ride, "Starburst Coaster",
            "The New Year finale: a coaster that ends in fireworks.", "sparkle", listOf("ride.newyear.starburst")),

        HolidayReward("reward.snowcone", HolidayRewardKind.decoration, "Snow Cone Cart",
            "A cart that sells cones of shaved ice with a choice of syrups. Takes the usual shop upgrades.", "snowflake", listOf("shop.xmas.snowcone")),
        HolidayReward("reward.snowfamily", HolidayRewardKind.decoration, "Snow Family",
            "A whole family of snowmen in matching scarves.", "person.3.fill", listOf("scenery.xmas.snowfamily")),

        HolidayReward("reward.performer.missus", HolidayRewardKind.performer, "Mrs. Claus",
            "A new entertainer: bakes cookies for anybody who looks hungry.", "person.fill", listOf("act.missus")),
    )

    private val byID = all.associateBy { it.id }
    fun definition(id: String): HolidayReward? = byID[id]

    /** Which reward, if any, is needed before this catalogue entry or act can be used. */
    fun requiredFor(opens: String): String? = all.firstOrNull { opens in it.opens }?.id
}

/** Which family of existing rides a makeover reward covers. */
enum class MakeoverSet { gentle, family, thrill, water }

object HolidayMakeovers {
    private val sets: Map<MakeoverSet, List<String>> = mapOf(
        MakeoverSet.gentle to listOf(
            "ride.carousel", "ride.minigolf", "ride.hauntedhouse", "ride.ferriswheel", "ride.mirrormaze",
            "ride.skygliders", "ride.lanterncruise"),
        MakeoverSet.family to listOf(
            "ride.teacups", "ride.bumpercars", "ride.carpetslide", "ride.gokarts.small", "ride.skyswings"),
        MakeoverSet.thrill to listOf(
            "ride.pirateship", "ride.droptower", "ride.minicoaster", "ride.gokarts.medium", "ride.gokarts.large",
            "ride.slingshot", "ride.bigcoaster", "ride.treetopzip", "ride.gravityhammer", "coaster.station"),
        MakeoverSet.water to listOf(
            "ride.logflume", "ride.fishingboats", "ride.bumperboats", "ride.wavepool", "ride.riverrapids"),
    )

    fun idsFor(set: MakeoverSet): List<String> = sets.getValue(set)

    /** The reward that has to be earned before this ride can be given the makeover. */
    fun rewardFor(rideID: String): String? {
        for ((set, ids) in sets) if (rideID in ids) return "reward.makeover.${set.name}"
        return null
    }
}

/**
 * What the player has earned from the holiday event, and whether they have seen this year's announcement.
 * Kept in the same small store as trial progress, so it is shared by every park.
 */
class HolidayStore(private val store: KeyValueStore) {
    private val unlockKey = "holiday.unlocks"
    private val doneKey = "holiday.done"
    private val hiddenKey = "holiday.hideYear"

    private fun readSet(key: String): Set<String> =
        store.getString(key)?.split('\n')?.filter { it.isNotEmpty() }?.toSet() ?: emptySet()

    /** Reward ids earned, ever. */
    val unlocked: Set<String> get() = readSet(unlockKey)

    fun isUnlocked(rewardID: String): Boolean = rewardID in unlocked

    /** Whether the player may use a catalogue entry or act: free ones always, locked ones once earned. */
    fun canUse(opens: String): Boolean {
        val needed = HolidayRewards.requiredFor(opens) ?: return true
        return isUnlocked(needed)
    }

    private val completedYears: Map<String, Int>
        get() = store.getString(doneKey)?.split('\n')?.mapNotNull {
            val parts = it.split('=')
            if (parts.size == 2) parts[1].toIntOrNull()?.let { year -> parts[0] to year } else null
        }?.toMap() ?: emptyMap()

    /** Whether this holiday trial was beaten during this year's event. */
    fun isCompleted(trial: TrialDefinition, year: Int = HolidaySeason.eventYear()): Boolean = completedYears[trial.id] == year

    fun completedCount(year: Int = HolidaySeason.eventYear()): Int =
        TrialContent.holiday.count { isCompleted(it, year) }

    /**
     * Records a win and hands over the rewards. Returns only the ones earned for the first time, so the result
     * card can announce them once.
     */
    fun recordWin(trial: TrialDefinition, year: Int = HolidaySeason.eventYear()): List<HolidayReward> {
        val done = completedYears.toMutableMap()
        done[trial.id] = year
        store.putString(doneKey, done.entries.joinToString("\n") { "${it.key}=${it.value}" })

        val fresh = trial.rewardIDs.mapNotNull { HolidayRewards.definition(it) }.filter { !isUnlocked(it.id) }
        if (fresh.isNotEmpty()) store.putString(unlockKey, (unlocked + fresh.map { it.id }).joinToString("\n"))
        return fresh
    }

    /** Whether a holiday trial can be started: any reward it needs is held. */
    fun isOpen(trial: TrialDefinition): Boolean = trial.needsRewardID?.let { isUnlocked(it) } ?: true

    // region Daily gifts

    private val giftDayKey = "holiday.giftDay"
    private val giftCountKey = "holiday.giftCount"

    private fun dayStamp(date: CalendarDate) = "${date.year}-${date.month}-${date.day}"

    /** Whether today's gift has been taken. */
    fun giftClaimed(date: CalendarDate = HolidaySeason.clock()): Boolean = store.getString(giftDayKey) == dayStamp(date)

    /** How many daily gifts the player has taken, over the years. */
    val giftsTaken: Int get() = store.getString(giftCountKey)?.toIntOrNull() ?: 0

    internal fun markGiftClaimed(date: CalendarDate) {
        store.putString(giftDayKey, dayStamp(date))
        store.putString(giftCountKey, (giftsTaken + 1).toString())
    }

    /** Hands over a reward outright, outside any trial. Returns false if it was already held. */
    fun unlock(rewardID: String): Boolean {
        if (isUnlocked(rewardID)) return false
        store.putString(unlockKey, (unlocked + rewardID).joinToString("\n"))
        return true
    }

    // endregion

    /** The year the announcement was last put away for, or null. */
    private val hiddenYear: Int? get() = store.getString(hiddenKey)?.toIntOrNull()

    /** Whether the main menu should show the announcement: in season, and not put away for this year's event. */
    fun shouldAnnounce(date: CalendarDate = HolidaySeason.clock()): Boolean =
        HolidaySeason.isActive(date) && hiddenYear != HolidaySeason.eventYear(date)

    fun hideAnnouncement(date: CalendarDate = HolidaySeason.clock()) {
        store.putString(hiddenKey, HolidaySeason.eventYear(date).toString())
    }
}
