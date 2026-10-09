package com.wickedstudios.wonderlot

import kotlin.math.pow

/** How guests judge prices. Drives shop purchases, admission demand and the price sentiment readout. */
object GuestEconomics {

    /**
     * 0-1 willingness to pay [price] for something guests consider worth
     * [reference]. Free at half the fair price, refused at 1.5x it.
     */
    fun purchaseWillingness(price: Double, reference: Double, spending: Double): Double {
        if (reference <= 0) return 1.0
        if (price <= 0) return 1.0
        val ratio = price / reference
        val base = 1.5 - ratio
        val personalityShift = (spending - 50) / 250
        return SimMath.clamp(base + personalityShift, 0.0, 1.0)
    }

    /** The admission price a park of this quality can get away with. */
    fun acceptableAdmission(attractionCount: Int, parkRating: Double): Double =
        Balance.acceptablePriceFloor + attractionCount * Balance.acceptablePricePerAttraction + parkRating * 0.15

    /** 0-1 chance a potential visitor accepts the gate price. */
    fun admissionWillingness(price: Double, acceptable: Double): Double {
        if (acceptable <= 0) return 0.0
        if (price <= 0) return 1.0
        val ratio = price / acceptable
        return SimMath.clamp(1.25 - 0.75 * ratio, 0.0, 1.0)
    }

    /** Wording for a shop's price sentiment readout. */
    fun sentimentLabel(value: Double): String = when {
        value < 0.2 -> "Outrageous"
        value < 0.4 -> "Expensive"
        value < 0.65 -> "Fair"
        value < 0.85 -> "Good value"
        else -> "A bargain"
    }
}

/**
 * Why a guest would, or would not, walk to a shop, a restroom or a booth. The
 * single place that decides how much a guest wants a facility.
 */
object FacilityAppeal {

    sealed class Verdict {
        data object NotOpen : Verdict()
        data object BeingCleaned : Verdict()
        data object Unusable : Verdict()
        data object NoWalkway : Verdict()
        data object Unreachable : Verdict()
        data object QueueTooLong : Verdict()
        data object CannotAfford : Verdict()

        /** Working, reachable, and of no interest to this guest right now. */
        data object NotWanted : Verdict()

        /** How strongly this guest wants it, on the same scale rides use. */
        data class Wants(val score: Double) : Verdict()

        val summary: String
            get() = when (this) {
                NotOpen -> "Closed, so nobody is coming in"
                BeingCleaned -> "Shut while a janitor cleans it"
                Unusable -> "In no state for guests to use"
                NoWalkway -> "No walkway touches it"
                Unreachable -> "Guests cannot walk to it"
                QueueTooLong -> "The queue is longer than guests will wait"
                CannotAfford -> "Guests nearby cannot afford it"
                NotWanted -> "Nobody nearby wants it right now"
                is Wants -> "Guests want this"
            }
    }

    /**
     * [distance] is the walking distance in tiles to the nearest tile a guest
     * can stand on to use it, or null when there is no route. [spendBoost] is
     * what an advert boost is doing to how readily guests part with money.
     */
    fun evaluate(
        facility: Facility,
        definition: FacilityDefinition,
        guest: Guest,
        hasAccess: Boolean,
        distance: Int?,
        spendBoost: Double = 1.0,
    ): Verdict {
        if (!facility.isOpen) return Verdict.NotOpen
        if (facility.isBeingCleaned) return Verdict.BeingCleaned
        if (facility.isUnusable) return Verdict.Unusable
        if (!hasAccess) return Verdict.NoWalkway
        if (distance == null) return Verdict.Unreachable

        val wait = facility.estimatedWait(definition)
        val tolerance = tolerableWait(guest)
        if (wait >= tolerance) return Verdict.QueueTooLong
        val queueFactor = 1 - (wait / tolerance) * 0.6

        if (definition.kind.sellsGoods && guest.cash < facility.price) return Verdict.CannotAfford

        val appeal = desire(guest, facility, definition, spendBoost) * definition.drawFactor
        val score = appeal * proximityFactor(distance) * queueFactor
        return if (score > 0.5) Verdict.Wants(score) else Verdict.NotWanted
    }

    /** How much this guest wants what the facility offers, before distance and queue. */
    private fun desire(guest: Guest, facility: Facility, definition: FacilityDefinition, spendBoost: Double): Double {
        return when (definition.kind) {
            FacilityKind.bathroom -> {
                var score = 430 * (guest.bathroomNeed / 100).pow(3.5)
                // A filthy restroom is a last resort rather than a destination.
                if (facility.isDirty) score *= 0.45
                score
            }

            FacilityKind.bin -> {
                if (guest.carryingTrash <= 0) return 0.0
                val urgency = 0.4 + minOf(1.0, guest.trashCarriedFor / 40) * 0.6
                150 * urgency
            }

            FacilityKind.food -> {
                val hungerDraw = 260 * (guest.hunger / 100).pow(2.2) *
                    willingness(guest, facility, definition, spendBoost)
                if (!definition.carriesSnack) return hungerDraw
                // Somebody already working through a bag does not want another.
                if (guest.popcornRemaining > 0) return 0.0
                val impulse = Balance.snackImpulse * (guest.happiness / 100) *
                    willingness(guest, facility, definition, spendBoost)
                maxOf(hungerDraw, impulse)
            }

            FacilityKind.drink ->
                250 * (guest.thirst / 100).pow(2.2) * willingness(guest, facility, definition, spendBoost)

            FacilityKind.souvenir ->
                90 * (guest.happiness / 100) * willingness(guest, facility, definition, spendBoost)

            FacilityKind.game -> {
                // A booth competes with the rides for the same idle guest.
                var appetite = 0.6 + guest.personality.spending / 150
                appetite *= when (guest.ageCategory) {
                    AgeCategory.child -> 1.9
                    AgeCategory.adult -> 1.0
                    AgeCategory.senior -> 0.7
                }
                // Somebody already carrying a bear is playing for the fun of it.
                if (guest.prize != null) appetite *= 0.45
                240 * appetite * willingness(guest, facility, definition, spendBoost)
            }

            FacilityKind.bench -> {
                val tiredness = SimMath.normalise(45 - guest.energy, 0.0, 45.0)
                var score = 220 * tiredness.pow(2) + guest.nausea * 0.9
                // A table that feeds people is somewhere to eat as well as to rest.
                if (definition.relief.hunger > 0) {
                    score += Balance.picnicMealDraw * (guest.hunger / 100).pow(1.5)
                }
                score
            }
        }
    }

    /** A boost makes guests readier to buy at the price already on the board. */
    fun willingness(guest: Guest, facility: Facility, definition: FacilityDefinition, boost: Double = 1.0): Double =
        GuestEconomics.purchaseWillingness(facility.price, definition.referencePrice, guest.personality.spending) * boost

    fun proximityFactor(tileDistance: Int): Double = 1.0 / (1.0 + tileDistance / 12.0)

    fun tolerableWait(guest: Guest): Double =
        Balance.baseTolerableWait + guest.personality.patience * Balance.patienceWaitScale
}
