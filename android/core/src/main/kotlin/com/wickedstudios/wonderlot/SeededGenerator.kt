package com.wickedstudios.wonderlot

import kotlin.random.Random

/** SplitMix64. Deterministic, so a saved park resumes with the stream it had. */
class SeededGenerator(var state: Long) : Random() {
    constructor() : this(Random.nextLong())

    override fun nextLong(): Long {
        state += -0x61c8864680b583ebL // 0x9E3779B97F4A7C15
        var z = state
        z = (z xor (z ushr 30)) * -0x40a7b892e31b1a47L // 0xBF58476D1CE4E5B9
        z = (z xor (z ushr 27)) * -0x6b2fb644ecceee15L // 0x94D049BB133111EB
        return z xor (z ushr 31)
    }

    override fun nextBits(bitCount: Int): Int =
        if (bitCount == 0) 0 else (nextLong() ushr (64 - bitCount)).toInt()

    fun double(range: ClosedFloatingPointRange<Double>): Double =
        range.start + nextDouble() * (range.endInclusive - range.start)

    fun int(range: IntRange): Int = nextInt(range.first, range.last + 1)

    fun chance(probability: Double): Boolean = nextDouble() < probability

    fun <T> pick(elements: List<T>): T? =
        if (elements.isEmpty()) null else elements[nextInt(elements.size)]
}
