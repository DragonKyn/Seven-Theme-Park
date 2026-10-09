package com.wickedstudios.wonderlot

/**
 * Something a player can switch on for a while by watching an advert. Every
 * one of them is a convenience rather than an advantage you cannot earn.
 */
enum class BoostKind(val title: String, val summary: String, val symbolName: String) {
    turboSpeed("5x Speed",
        "Adds a fifth notch to the speed control, so a park day passes in a couple of minutes.", "hare.fill"),
    extraVisitors("Busier Gate",
        "${(Balance.adVisitorBoost * 100).toInt()}% more arrivals while it lasts, on top of whatever the park has earned.",
        "person.3.sequence.fill"),
    bigSpenders("Big Spenders",
        "Guests are ${(Balance.adSpendBoost * 100).toInt()}% readier to buy, so shops and booths take more at the same prices.",
        "creditcard.fill"),
    smoothRunning("Smooth Running",
        "Rides barely wear and almost never fail. A good hour to run a tired park while a mechanic catches up.",
        "gearshape.2.fill"),
    spotless("Spotless",
        "Guests hold on to their rubbish instead of dropping it, so one janitor goes a great deal further.",
        "sparkles");
}

/**
 * How long each boost has left to run. Kept against the wall clock rather than
 * park time, and outside any save: a boost belongs to the player.
 */
class BoostCenter(
    private val store: KeyValueStore,
    private val now: () -> Long = { System.currentTimeMillis() },
) {
    /** Bumped whenever a boost is granted or lapses, so views watching this redraw. */
    var generation = 0
        private set

    private fun key(kind: BoostKind) = "boost.until.${kind.name}"

    /** Epoch milliseconds the boost runs until, or null. */
    fun expiry(kind: BoostKind): Long? {
        val stamp = store.getString(key(kind))?.toLongOrNull() ?: return null
        return if (stamp > 0) stamp else null
    }

    fun isActive(kind: BoostKind): Boolean = remaining(kind) > 0

    /** Seconds left, or zero. */
    fun remaining(kind: BoostKind): Double {
        val expiry = expiry(kind) ?: return 0.0
        return maxOf(0.0, (expiry - now()) / 1000.0)
    }

    /** "9:58", or null when it is not running. */
    fun remainingLabel(kind: BoostKind): String? {
        val seconds = remaining(kind)
        if (seconds <= 0) return null
        return String.format("%d:%02d", seconds.toInt() / 60, seconds.toInt() % 60)
    }

    /**
     * Adds one advert's worth of time. Time stacks, up to a ceiling, so nobody
     * sits through twenty adverts to bank a day of it.
     */
    fun grant(kind: BoostKind) {
        val current = now()
        val from = maxOf(current, expiry(kind) ?: current)
        val ceiling = current + (Balance.adBoostMaximumMinutes * 60_000).toLong()
        val until = minOf(from + (Balance.adBoostMinutes * 60_000).toLong(), ceiling)
        store.putString(key(kind), until.toString())
        generation += 1
    }

    /** Lets views know a boost has run out. */
    fun refresh() {
        generation += 1
    }
}
