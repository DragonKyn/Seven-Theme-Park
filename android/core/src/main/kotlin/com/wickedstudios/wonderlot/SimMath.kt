package com.wickedstudios.wonderlot

import kotlin.random.Random

object SimMath {
    fun clamp(value: Double, lower: Double = 0.0, upper: Double = 100.0): Double =
        minOf(maxOf(value, lower), upper)

    /** Maps [value] from the range to 0..1, clamped. */
    fun normalise(value: Double, lower: Double, upper: Double): Double {
        if (upper <= lower) return 0.0
        return clamp((value - lower) / (upper - lower), 0.0, 1.0)
    }

    fun distance(a: Vec2, b: Vec2): Double = a.distanceTo(b)

    /** Picks an index with probability proportional to weight; null when all are zero. */
    fun weightedChoice(weights: List<Double>, rng: Random): Int? {
        val total = weights.sum()
        if (total <= 0) return null
        var roll = rng.nextDouble() * total
        for ((index, weight) in weights.withIndex()) {
            roll -= weight
            if (roll <= 0) return index
        }
        return weights.lastIndex
    }
}
