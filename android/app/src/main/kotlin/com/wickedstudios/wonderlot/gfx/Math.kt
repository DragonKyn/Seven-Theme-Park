package com.wickedstudios.wonderlot.gfx

/*
 * Swift lets integer literals stand in for CGFloat, so the artwork freely
 * mixes them (`max(1, size.width * 0.02)`). Kotlin's min/max do not mix Int
 * and Double, so these overloads live in the artwork's own package, where they
 * are found before anything else.
 */

fun max(a: Double, b: Double): Double = if (a >= b) a else b
fun max(a: Double, b: Int): Double = max(a, b.toDouble())
fun max(a: Int, b: Double): Double = max(a.toDouble(), b)
fun max(a: Int, b: Int): Int = if (a >= b) a else b
fun max(a: Double, b: Double, c: Double): Double = max(max(a, b), c)

fun min(a: Double, b: Double): Double = if (a <= b) a else b
fun min(a: Double, b: Int): Double = min(a, b.toDouble())
fun min(a: Int, b: Double): Double = min(a.toDouble(), b)
fun min(a: Int, b: Int): Int = if (a <= b) a else b
fun min(a: Double, b: Double, c: Double): Double = min(min(a, b), c)

fun abs(a: Double): Double = if (a < 0) -a else a
fun abs(a: Int): Int = if (a < 0) -a else a

fun cos(a: Double): Double = kotlin.math.cos(a)
fun sin(a: Double): Double = kotlin.math.sin(a)
fun tan(a: Double): Double = kotlin.math.tan(a)
fun atan2(y: Double, x: Double): Double = kotlin.math.atan2(y, x)
fun sqrt(a: Double): Double = kotlin.math.sqrt(a)
fun pow(a: Double, b: Double): Double = Math.pow(a, b)
fun floor(a: Double): Double = kotlin.math.floor(a)
fun ceil(a: Double): Double = kotlin.math.ceil(a)
fun round(a: Double): Double = Math.floor(a + 0.5)

const val PI = Math.PI

operator fun Int.times(other: Double): Double = this.toDouble() * other
operator fun Int.plus(other: Double): Double = this.toDouble() + other
operator fun Int.minus(other: Double): Double = this.toDouble() - other
operator fun Int.div(other: Double): Double = this.toDouble() / other

/** A pair of points, as the artwork's cables and wires are described. */
class Segment(val start: CGPoint, val end: CGPoint)

/** The two wires of a chairlift, out and back. */
class CablePair(val out: List<CGPoint>, val back: List<CGPoint>)
