package com.wickedstudios.wonderlot

import kotlin.random.Random

/** What a daily gift turned out to be. */
sealed class HolidayGift {
    /** Hours of a boost, free, so there is no advert to watch for it. */
    data class Boost(val kind: BoostKind, val hours: Int) : HolidayGift()

    /** One of the rides the twelve days hand out, opened without having to win the trial. */
    data class Ride(val reward: HolidayReward) : HolidayGift()
}

/**
 * A present for every day from 20 to 26 December: either ten hours of a boost or one of the three rides the twelve
 * days hand out. A player who already has all three rides is given a boost instead, so a gift is never wasted.
 */
object HolidayGifts {
    const val boostHours = 10
    const val rideChance = 0.40
    private const val firstDay = 20
    private const val lastDay = 26

    /** The rides a gift can unlock: the ones locked behind a trial. */
    val rideRewardIDs = listOf("reward.ride.candycoaster", "reward.ride.startopper", "reward.ride.starburst")

    fun inWindow(date: CalendarDate): Boolean = date.month == 12 && date.day in firstDay..lastDay

    /** Whether there is a gift to take right now: the window is open and today's has not been taken. */
    fun isAvailable(store: HolidayStore, date: CalendarDate = HolidaySeason.clock()): Boolean {
        val open = HolidaySeason.override ?: inWindow(date)
        return open && !store.giftClaimed(date)
    }

    /** Opens today's gift. Returns null when there is none to take. */
    fun claim(store: HolidayStore, boosts: BoostCenter, rng: Random = Random.Default, date: CalendarDate = HolidaySeason.clock()): HolidayGift? {
        if (!isAvailable(store, date)) return null
        val locked = rideRewardIDs.filter { !store.isUnlocked(it) }
        val gift: HolidayGift
        if (locked.isNotEmpty() && rng.nextDouble() < rideChance) {
            val id = locked[rng.nextInt(locked.size)]
            store.unlock(id)
            gift = HolidayGift.Ride(HolidayRewards.definition(id)!!)
        } else {
            val kind = BoostKind.entries[rng.nextInt(BoostKind.entries.size)]
            boosts.grantFor(kind, boostHours * 60.0)
            gift = HolidayGift.Boost(kind, boostHours)
        }
        store.markGiftClaimed(date)
        return gift
    }
}
