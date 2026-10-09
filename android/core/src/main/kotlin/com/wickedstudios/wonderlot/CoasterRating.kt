package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable

/**
 * What a coaster the player built is worth, judged from the circuit itself:
 * closed or open, varied or repeated, gentle or brutal.
 */
@Serializable
data class CoasterRating(
    var length: Int = 0,
    var isLoop: Boolean = false,
    var elementCount: Int = 0,
    var kindCount: Int = 0,
    /** What the elements are worth once repeats, variety and crowding have been allowed for. */
    var thrill: Double = 0.0,
    /** How hard the elements throw a train about, 0-100. */
    var intensity: Double = 0.0,
    var isCrowded: Boolean = false,
) {
    /** Added to the station's own excitement. */
    val excitementBonus: Double
        get() {
            val score = minOf(30.0, length * 0.7) + minOf(35.0, thrill)
            return if (isLoop) score else score * Balance.coasterOpenLineFactor
        }

    /** Added to the station's own nausea. */
    val nauseaBonus: Double
        get() = minOf(Balance.coasterNauseaCeiling, intensity * 0.45 + length * 0.15)

    /** Multiplies how fast the ride wears. */
    val wearFactor: Double get() = 1 + intensity / 200

    /** Added to what each run costs. */
    val runningCost: Double get() = length * 0.35

    /** Added to how long a run lasts. */
    val duration: Double get() = minOf(150.0, length * 1.6)

    /** What is holding the coaster back, most important first. Never empty. */
    val advice: List<String>
        get() {
            val notes = ArrayList<String>()
            if (length < Balance.coasterShortLength) {
                notes.add("Short track: a ride this short is over before it starts. Aim for ${Balance.coasterShortLength} tiles or more.")
            }
            if (!isLoop) {
                notes.add("The circuit is not closed, so the train shuttles up and down it. Join the ends up for a full-strength ride.")
            }
            if (elementCount == 0) {
                notes.add("No elements yet. A loop or a run of hills lifts a coaster a long way.")
            } else if (kindCount == 1 && elementCount > 1) {
                notes.add("Every element is the same kind. A different one is worth more than another copy.")
            }
            if (isCrowded) notes.add("The elements are crammed together. Leave straight track between them.")
            if (intensity > Balance.coasterIntenseThreshold) {
                notes.add("Very intense: riders will come off queasy and the ride will wear faster.")
            }
            if (notes.isEmpty()) {
                notes.add("Well balanced. A longer circuit or a new kind of element is the way up from here.")
            }
            return notes
        }

    companion object {
        /** [elements] is one entry per element placed on the circuit. */
        fun rate(length: Int, isLoop: Boolean, elements: List<CoasterElementDefinition>): CoasterRating {
            val grouped = elements.groupBy { it.id }

            var thrill = 0.0
            var pull = 0.0
            for (copies in grouped.values) {
                val first = copies.firstOrNull() ?: continue
                var weight = 1.0
                for (ignored in copies) {
                    thrill += first.thrill * weight
                    pull += (first.intensity - 1) * Balance.coasterIntensityScale * weight
                    weight *= Balance.coasterRepeatDecay
                }
            }

            val kinds = grouped.size
            thrill += minOf(maxOf(0, kinds - 1), Balance.coasterVarietyKinds) * Balance.coasterVarietyBonus

            val covered = elements.sumOf { it.footprint.tileCount }
            val crowded = length > 0 && covered.toDouble() / length > Balance.coasterCrowdingLimit
            if (crowded) thrill *= Balance.coasterCrowdingFactor

            return CoasterRating(length, isLoop, elements.size, kinds, thrill,
                SimMath.clamp(pull, 0.0, 100.0), crowded)
        }
    }
}
