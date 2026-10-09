package com.wickedstudios.wonderlot

/**
 * What the park looks like right now, flattened into the handful of numbers the
 * tips actually ask about. Built once per interface refresh.
 */
class TutorialSignals(
    var day: Int = 1,
    var minutesPlayed: Double = 0.0,
    var guestCount: Int = 0,
    var cash: Double = 0.0,
    var averageHappiness: Double = 100.0,
    var rideCount: Int = 0,
    var shopCount: Int = 0,
    var boothCount: Int = 0,
    var benchCount: Int = 0,
    var hasRestroom: Boolean = false,
    var hasBin: Boolean = false,
    var staffCount: Int = 0,
    var mechanicCount: Int = 0,
    var janitorCount: Int = 0,
    var litteredTiles: Int = 0,
    var brokenRides: Int = 0,
    var longestQueue: Int = 0,
    var securityCount: Int = 0,
    var sceneryCount: Int = 0,
    var impoundedRides: Int = 0,
    /** Shops and booths standing at nothing but their opening spec. */
    var unimprovedShops: Int = 0,
    var isBuilding: Boolean = false,
    var isPlacing: Boolean = false,
    var isFreeBuild: Boolean = false,
    /** A trial has its own goals screen and its own save. */
    var isTrial: Boolean = false,
)

/** One thing the game explains, once. */
class TutorialTip(
    val id: String,
    val title: String,
    val message: String,
    val symbolName: String,
    /** Shown first when several are eligible at once. */
    val priority: Int,
    /** When this tip is worth showing. */
    val condition: (TutorialSignals) -> Boolean,
)

object TutorialContent {
    /** In rough order of when a new player meets them. Priority, not order, decides what is shown. */
    val all: List<TutorialTip> = listOf(
        TutorialTip("tip.welcome", "Welcome to your lot",
            "You have an empty field, a gate, and some money. Tap Build to lay a walkway out from the entrance, then put something at the end of it worth walking to.",
            "hand.wave.fill", 100) { true },
        TutorialTip("tip.paths", "Guests only walk on walkways",
            "Everything you build has to touch one. Pick Paths, turn on Draw, and drag out a route; rides and shops go beside it, not on it.",
            "square.grid.3x3", 90) { it.isBuilding },
        TutorialTip("tip.placing", "Line it up before you pay",
            "Nothing is bought until you confirm it. Drag it around the map with one finger, nudge it a tile at a time with the arrows, turn it until it faces the way you want, then tap Build it.",
            "rotate.right.fill", 95) { it.isPlacing },
        TutorialTip("tip.firstride", "Give them something to ride",
            "Guests are arriving to an empty park and will leave again. Open Build, choose Rides, and put a gentle one near the gate where everybody walks past it.",
            "sparkles", 88) { it.guestCount >= 3 && it.rideCount == 0 },
        TutorialTip("tip.inspect", "Tap anything to inspect it",
            "A ride shows its queue, its takings and what it can be improved with. A guest shows what they want and what they are thinking, which is usually how you find out what your park is missing.",
            "hand.tap.fill", 80) { it.rideCount >= 1 && it.guestCount >= 5 },
        TutorialTip("tip.food", "Hungry guests spend money",
            "Food and drink stalls are the steadiest income in the park, and a guest who cannot find one goes home early. Build one where the queues are.",
            "fork.knife", 78) { it.guestCount >= 8 && it.shopCount == 0 },
        TutorialTip("tip.restroom", "They will need a restroom",
            "Nothing empties a park faster than nowhere to go. Restrooms earn nothing directly and pay for themselves in guests who stay all day.",
            "figure.stand", 85) { it.guestCount >= 10 && !it.hasRestroom },
        TutorialTip("tip.staff", "Hire somebody",
            "Open Staff to take somebody on. Janitors sweep litter and clean restrooms, mechanics fix rides before they break, entertainers lift the mood of a queue, and security keep an eye on the gate.",
            "person.2.badge.gearshape.fill", 84) { it.guestCount >= 12 && it.staffCount == 0 },
        TutorialTip("tip.litter", "The park is getting dirty",
            "Guests drop rubbish when there is no bin to hand, and litter drags your rating down. Bins go straight on the walkway; a janitor deals with the rest.",
            "trash.fill", 82) { it.litteredTiles >= 4 && it.janitorCount == 0 },
        TutorialTip("tip.breakdown", "A ride has broken down",
            "It earns nothing until somebody fixes it. Hire a mechanic and they will inspect rides on their own, which is what stops the next breakdown.",
            "wrench.and.screwdriver.fill", 92) { it.brokenRides >= 1 },
        TutorialTip("tip.queues", "That queue is getting long",
            "Guests give up when they have waited longer than they think it is worth. Upgrade the ride's capacity from its panel, or build a second thing to do nearby.",
            "clock.fill", 76) { it.longestQueue >= 9 },
        TutorialTip("tip.money", "Money is getting tight",
            "Wages and upkeep run whether the park is busy or not. Check Money for where it is going, and remember you get most of a building's cost back if you remove it.",
            "dollarsign.circle.fill", 94) { !it.isFreeBuild && it.cash < 1_200 },
        TutorialTip("tip.admission", "What to charge at the gate",
            "Park Settings sets the admission price. Guests weigh it against how much there is to do, so raise it after you add rides rather than before, and watch arrivals when you do.",
            "ticket.fill", 70) { it.day >= 2 },
        TutorialTip("tip.unhappy", "Your guests are unhappy",
            "Tap a miserable one and read their thoughts. They will tell you whether it is the queues, the prices, the litter or the walk, and that is faster than guessing.",
            "face.dashed", 86) { it.guestCount >= 10 && it.averageHappiness < 45 },
        TutorialTip("tip.booths", "Carnival booths pull a crowd",
            "A booth is cheap, quick to play and the winners carry a prize round the park all day. The harder the game, the bigger the prize.",
            "target", 68) { it.rideCount >= 2 && it.boothCount == 0 && it.guestCount >= 10 },
        TutorialTip("tip.coaster", "Build your own coaster",
            "Coaster Builder is a box of parts rather than a shelf of rides. Lay your own track, put a station beside it, and bolt on loops, corkscrews and a jump. The train runs whatever you build, but it is judged as a design: close the circuit, keep it long, mix different elements and leave room between them. Tap the station to see what it makes of yours.",
            "point.topleft.down.curvedto.point.bottomright.up", 66) { it.rideCount >= 4 },
        TutorialTip("tip.benches", "Somewhere to sit",
            "Benches go on the walkway. Tired guests sit down instead of going home, and a guest who feels sick will recover on one rather than leave in a bad mood.",
            "chair.lounge.fill", 64) { it.guestCount >= 14 && it.benchCount == 0 },
        TutorialTip("tip.inspector", "An inspector has shut a ride",
            "It stays shut, and it cannot take anybody, until a mechanic has been out to it. Hire one if you have not, and expect the repair to take a while.",
            "xmark.seal.fill", 97) { it.impoundedRides > 0 },
        TutorialTip("tip.shopupgrades", "Shops can be improved",
            "Tap a stall or a booth and look under Improvements. Another till moves the queue, better stock lets you charge more without complaints, and lit signage pulls people in from further down the path.",
            "star.circle.fill", 72) { it.unimprovedShops >= 1 && it.day >= 2 && it.cash >= 2_000 },
        TutorialTip("tip.security", "Somebody to keep an eye on things",
            "A guard makes the crowd around them feel looked after, and they are the only ones who can see a troublemaker off the premises. Without one, a troublemaker has the run of the park all afternoon.",
            "shield.lefthalf.filled", 63) { it.guestCount >= 25 && it.securityCount == 0 },
        TutorialTip("tip.alerts", "The bell knows before you do",
            "Breakdowns, long queues, litter and empty tills all end up under the bell at the top. Tapping a notice takes you straight to whatever it is about.",
            "bell.badge.fill", 76) { it.brokenRides > 0 || it.litteredTiles >= 10 },
        TutorialTip("tip.scenery", "A park people want to look at",
            "Trees, flowers, lamps and fountains raise how pretty the ground around them is, and the rating counts it. Scenery in Build has several styles of each, and Park settings paints the benches and lamps in your own colours.",
            "tree.fill", 58) { it.rideCount >= 3 && it.sceneryCount == 0 },
        TutorialTip("tip.boosts", "A fifth gear, if you want it",
            "The greyed-out 5x on the speed control, and a busier gate, can each be switched on for ten minutes by watching a short advert. Nothing in the game needs them, and nothing will ever interrupt your park to ask.",
            "hare.fill", 52) { it.day >= 3 && it.minutesPlayed >= 25 },
        TutorialTip("tip.trials", "Fifteen parks against the clock",
            "Park Trials on the main menu is a ladder of parks built to a deadline on harder and harder land. Every one you beat earns a medal and a point to spend on a permanent bonus that applies to every park you build.",
            "flag.checkered", 50) { !it.isTrial && it.day >= 4 && it.rideCount >= 3 },
        TutorialTip("tip.saving", "Your park saves itself",
            "Progress is written as you play. Menu has Save park if you want it now, and leaving through Menu asks first and saves before it goes.",
            "externaldrive.fill", 60) { it.day >= 2 && it.minutesPlayed >= 6 },
    )
}

/** Where "I have read this" lives: with the player, not with the park. */
class TutorialStore(private val store: KeyValueStore) {
    private val enabledKey = "tutorial.enabled"
    private val seenKey = "tutorial.seen"

    /** On unless the player has said otherwise. */
    var isEnabled: Boolean
        get() = store.getString(enabledKey)?.let { it == "true" } ?: true
        set(value) = store.putString(enabledKey, value.toString())

    private val seen: Set<String>
        get() = store.getString(seenKey)?.split(",")?.filter { it.isNotEmpty() }?.toSet() ?: emptySet()

    val seenCount: Int get() = seen.size

    fun hasSeen(id: String): Boolean = id in seen

    fun markSeen(id: String) {
        store.putString(seenKey, (seen + id).joinToString(","))
    }

    fun forgetAll() = store.remove(seenKey)
}

/**
 * Decides which tip to show, and remembers which ones the player has read. A
 * tip is shown once ever, and only one is on screen at a time with a pause
 * after each.
 */
class TutorialDirector(private val store: TutorialStore, private val now: () -> Long = { System.currentTimeMillis() }) {

    var current: TutorialTip? = null
        private set

    /** Real milliseconds to wait after a tip is dismissed before offering another. */
    private val pauseMillis = 8_000L
    private var nextOfferAt = 0L

    val isEnabled: Boolean get() = store.isEnabled

    /** Offers a tip if one applies. Returns true when what is on screen changed. */
    fun evaluate(signals: TutorialSignals): Boolean {
        if (!store.isEnabled) {
            if (current == null) return false
            current = null
            return true
        }

        if (current != null || now() < nextOfferAt) return false

        val candidate = TutorialContent.all
            .filter { !store.hasSeen(it.id) && it.condition(signals) }
            .maxByOrNull { it.priority } ?: return false
        current = candidate
        return true
    }

    /** The player has read the tip on screen. It never comes back. */
    fun dismissCurrent() {
        val tip = current ?: return
        store.markSeen(tip.id)
        current = null
        nextOfferAt = now() + pauseMillis
    }

    fun setEnabled(enabled: Boolean) {
        store.isEnabled = enabled
        if (!enabled) {
            current?.let { store.markSeen(it.id) }
            current = null
        }
    }

    /** Offers every tip again from the beginning. */
    fun reset() {
        store.forgetAll()
        current = null
        nextOfferAt = 0L
    }

    val tipsRead: Int get() = store.seenCount
    val tipsTotal: Int get() = TutorialContent.all.size
}
