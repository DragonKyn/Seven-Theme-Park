package com.wickedstudios.wonderlot

import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale
import kotlin.math.abs

enum class DepartureReason(val text: String) {
    satisfied("Had a full day"),
    unhappy("Unhappy with the park"),
    tired("Too tired, nowhere to sit"),
    brokeAndBored("Ran out of money"),
    noBathroom("Could not find a restroom"),
    queuesTooLong("Queues were too long"),
    tooDirty("The park was filthy"),
}

object CurrencyFormatter {
    private fun digits(value: Double, decimals: Int): String {
        val pattern = if (decimals == 0) "#,##0" else "#,##0." + "0".repeat(decimals)
        return DecimalFormat(pattern, DecimalFormatSymbols(Locale.US)).format(abs(value))
    }

    private fun money(value: Double, decimals: Int): String {
        val text = digits(value, decimals)
        return if (value < 0) "-$$text" else "$$text"
    }

    /** Rounded, for headline figures like cash and construction costs. */
    fun short(value: Double): String = money(value, 0)

    /** Two decimal places, for prices and per-sale figures. */
    fun exact(value: Double): String = money(value, 2)

    /** Shortened for places with no room to grow. */
    fun compact(value: Double): String {
        val magnitude = abs(value)
        val sign = if (value < 0) "-" else ""
        return when {
            magnitude >= 1_000_000_000 -> sign + String.format(Locale.US, "$%.1fB", magnitude / 1_000_000_000)
            magnitude >= 1_000_000 -> sign + String.format(Locale.US, "$%.1fM", magnitude / 1_000_000)
            magnitude >= 100_000 -> sign + String.format(Locale.US, "$%.0fK", magnitude / 1_000)
            magnitude >= 10_000 -> sign + String.format(Locale.US, "$%.1fK", magnitude / 1_000)
            else -> short(value)
        }
    }

    /** Always signed, including a plus. */
    fun delta(value: Double): String {
        val magnitude = short(abs(value))
        return if (value < 0) "-$magnitude" else "+$magnitude"
    }

    /** Signed, for profit and loss. */
    fun signed(value: Double): String {
        val magnitude = short(abs(value))
        return if (value < 0) "-$magnitude" else magnitude
    }
}

/** Generic given/family name pools used to make guests feel individual. */
object GuestNames {
    private val given = listOf(
        "Ada", "Bo", "Cleo", "Dev", "Elin", "Fabi", "Gus", "Hana", "Ivo", "Jo",
        "Kai", "Lena", "Mila", "Nils", "Ola", "Pia", "Quin", "Rafa", "Sami", "Tova",
        "Uma", "Vik", "Wren", "Xan", "Yara", "Zeke", "Ines", "Otto", "Nora", "Theo",
    )

    private val family = listOf(
        "Alder", "Brook", "Calder", "Dunn", "Ember", "Frost", "Garrow", "Hollis",
        "Ingram", "Jessup", "Kerr", "Lowry", "Marsh", "Nyland", "Orrick", "Pike",
        "Quist", "Rowe", "Sable", "Thorne", "Vance", "Wilde", "Yates", "Zell",
    )

    private val tourGroups = listOf(
        "Alderbrook Primary", "The Hollis Day Centre", "Marsh Lane Scouts",
        "Pike Street Youth Club", "The Rowe Family Reunion", "Thorne Valley School",
        "Kerr Road Nursery", "The Wilde Society", "Vance College", "Sable Park Guides",
        "Frost Hill Juniors", "The Ingram Walking Club",
    )

    fun tourGroup(rng: SeededGenerator): String = rng.pick(tourGroups) ?: "A day out"

    fun random(rng: SeededGenerator): String {
        val first = rng.pick(given) ?: "Guest"
        val last = rng.pick(family) ?: "Visitor"
        return "$first $last"
    }
}

/** Guest thoughts are generated from simulation state, so reading them explains what the park is doing to them. */
object ThoughtCatalog {
    data class Thought(val text: String, val mood: ThoughtMood, val icon: ThoughtIcon = ThoughtIcon.general)

    fun need(hunger: Double, thirst: Double, bathroom: Double, energy: Double): Thought? {
        if (bathroom > 90) return Thought("I really need a restroom.", ThoughtMood.negative, ThoughtIcon.restroom)
        if (thirst > 85) return Thought("I'm so thirsty.", ThoughtMood.negative, ThoughtIcon.drink)
        if (hunger > 85) return Thought("I'm starving.", ThoughtMood.negative, ThoughtIcon.food)
        if (energy < 18) return Thought("My feet are killing me.", ThoughtMood.negative, ThoughtIcon.tired)
        if (bathroom > 70) return Thought("I should find a restroom soon.", ThoughtMood.neutral, ThoughtIcon.restroom)
        if (hunger > 70) return Thought("I'm getting hungry.", ThoughtMood.neutral, ThoughtIcon.food)
        if (thirst > 70) return Thought("I could go for a drink.", ThoughtMood.neutral, ThoughtIcon.drink)
        if (energy < 32) return Thought("I need somewhere to sit.", ThoughtMood.neutral, ThoughtIcon.tired)
        return null
    }

    fun cannotFind(what: String): String = "I can't find a $what anywhere."

    fun queueTooLong(rideName: String): String = "The line for $rideName is way too long."

    fun abandonedQueue(rideName: String): String = "I gave up waiting for $rideName."

    fun joinedQueue(rideName: String, wait: Double): Thought {
        if (wait < 30) return Thought("$rideName has barely any line!", ThoughtMood.positive)
        if (wait < 90) return Thought("I'll wait for $rideName.", ThoughtMood.neutral)
        return Thought("Hope $rideName is worth this wait.", ThoughtMood.neutral)
    }

    fun afterRide(rideName: String, satisfaction: Double): Thought {
        if (satisfaction > 12) return Thought("$rideName was amazing!", ThoughtMood.positive)
        if (satisfaction > 4) return Thought("$rideName was pretty fun.", ThoughtMood.positive)
        if (satisfaction > 0) return Thought("$rideName was alright.", ThoughtMood.neutral)
        return Thought("$rideName wasn't really for me.", ThoughtMood.negative)
    }

    fun priceReaction(item: String, price: Double, willingness: Double): Thought {
        val formatted = CurrencyFormatter.short(price)
        if (willingness < 0.15) return Thought("$formatted for $item? You have to be kidding.", ThoughtMood.negative)
        if (willingness < 0.4) return Thought("$formatted for $item? That's expensive.", ThoughtMood.negative)
        if (willingness > 0.85) return Thought("$formatted for $item is a great deal.", ThoughtMood.positive)
        return Thought("$formatted for $item seems fair.", ThoughtMood.neutral)
    }

    fun admission(price: Double, willingness: Double): Thought {
        val formatted = CurrencyFormatter.short(price)
        if (willingness < 0.35) return Thought("$formatted just to get in? This had better be good.", ThoughtMood.negative)
        if (willingness > 0.8) return Thought("Only $formatted to get in — worth it.", ThoughtMood.positive)
        return Thought("$formatted to get in seems reasonable.", ThoughtMood.neutral)
    }

    fun gameWon(prize: String) = Thought("I won a $prize!", ThoughtMood.positive)

    fun gameLost(game: String) = Thought("So close at $game. One more go.", ThoughtMood.neutral)

    fun outOfMoney() = Thought("I'm out of money.", ThoughtMood.negative)

    fun leaving(reason: DepartureReason): Thought = when (reason) {
        DepartureReason.satisfied -> Thought("What a great day. Time to head home.", ThoughtMood.positive)
        DepartureReason.unhappy -> Thought("I'm not enjoying this. I'm going home.", ThoughtMood.negative)
        DepartureReason.tired -> Thought("I'm exhausted and there's nowhere to sit.", ThoughtMood.negative)
        DepartureReason.brokeAndBored -> Thought("Nothing left to spend. I'll head out.", ThoughtMood.neutral)
        DepartureReason.noBathroom -> Thought("No restrooms anywhere. I'm leaving.", ThoughtMood.negative)
        DepartureReason.queuesTooLong -> Thought("Every line is enormous. I'm done.", ThoughtMood.negative)
        DepartureReason.tooDirty -> Thought("This place is filthy. I'm not staying.", ThoughtMood.negative)
    }

    fun enjoyment(happiness: Double): Thought? {
        if (happiness > 88) return Thought("I'm having an amazing day!", ThoughtMood.positive)
        if (happiness < 25) return Thought("This park is a letdown.", ThoughtMood.negative)
        return null
    }
}
