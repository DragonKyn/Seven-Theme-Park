package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable

/**
 * What the land is like before anybody builds on it. Grass is where the park
 * goes; water can be bridged, rock and forest cannot be built on at all.
 */
@Serializable
enum class MapGround(val displayName: String, val terrain: TerrainType) {
    grass("Grass", TerrainType.grass),
    water("Water", TerrainType.water),
    rock("Rock", TerrainType.rock),
    forest("Forest", TerrainType.forest);
}

/**
 * The ground of a whole map, and where its gate is. The gate is always on the
 * bottom edge.
 */
@Serializable
data class MapLayout(
    val width: Int = Balance.mapWidth,
    val height: Int = Balance.mapHeight,
    var ground: MutableList<MapGround> = MutableList(width * height) { MapGround.grass },
    /** Column of the gate on the bottom row. */
    var entranceX: Int = width / 2,
) {
    constructor(fill: MapGround, entranceX: Int? = null) :
        this(Balance.mapWidth, Balance.mapHeight,
            MutableList(Balance.mapWidth * Balance.mapHeight) { fill },
            entranceX ?: (Balance.mapWidth / 2))

    /** A copy that shares nothing with the original. */
    fun copy(): MapLayout = MapLayout(width, height, ground.toMutableList(), entranceX)

    fun index(x: Int, y: Int): Int? =
        if (x < 0 || x >= width || y < 0 || y >= height) null else y * width + x

    fun ground(x: Int, y: Int): MapGround {
        val index = index(x, y) ?: return MapGround.rock
        return ground[index]
    }

    fun set(value: MapGround, x: Int, y: Int) {
        val index = index(x, y) ?: return
        ground[index] = value
    }

    /** Tiles a park could be built on. */
    val buildableCount: Int get() = ground.count { it == MapGround.grass }

    /** Forces the land in front of the gate to grass. */
    fun clearGateApproach() {
        entranceX = maxOf(1, minOf(width - 2, entranceX))
        for (y in 0..clearance) for (dx in -1..1) set(MapGround.grass, entranceX + dx, y)
    }

    companion object {
        /** How many tiles in front of the gate are kept clear. */
        const val clearance = 4
    }
}

/**
 * Draws the shapes premade maps are made of. Edges are roughened with a fixed
 * noise so the same map always comes out the same.
 */
class MapPainter(fill: MapGround = MapGround.grass, entranceX: Int? = null, private val seed: ULong) {
    var layout: MapLayout = MapLayout(fill, entranceX)
        private set

    /** A stable pseudo-random number in 0..1 for one tile. */
    fun noise(x: Int, y: Int, salt: ULong = 0uL): Double {
        var value: ULong = seed + salt * 0x9E3779B97F4A7C15uL
        value = value xor (x.toLong().toULong() * 0xBF58476D1CE4E5B9uL)
        value = value xor (y.toLong().toULong() * 0x94D049BB133111EBuL)
        value = value xor (value shr 31)
        value *= 0xD6E8FEB86659FD93uL
        value = value xor (value shr 29)
        return (value % 10_000uL).toDouble() / 10_000
    }

    /** Every tile in a rectangle, inclusive of both corners. */
    fun rect(ground: MapGround, x: IntRange, y: IntRange) {
        for (row in y) for (column in x) layout.set(ground, column, row)
    }

    /** A blob: an ellipse whose edge wanders by up to [rough] of its radius. */
    fun blob(ground: MapGround, centreX: Double, centreY: Double,
             radiusX: Double, radiusY: Double, rough: Double = 0.18) {
        val reachX = (radiusX * (1 + rough)).toInt() + 1
        val reachY = (radiusY * (1 + rough)).toInt() + 1
        for (y in (centreY.toInt() - reachY)..(centreY.toInt() + reachY)) {
            for (x in (centreX.toInt() - reachX)..(centreX.toInt() + reachX)) {
                val dx = (x - centreX) / radiusX
                val dy = (y - centreY) / radiusY
                val wobble = 1 + (noise(x, y) - 0.5) * 2 * rough
                if (dx * dx + dy * dy <= wobble * wobble) layout.set(ground, x, y)
            }
        }
    }

    /** A band following a line through a list of points, [width] tiles across. */
    fun band(ground: MapGround, points: List<Pair<Double, Double>>, width: Double) {
        if (points.size <= 1) return
        for (index in 0 until points.size - 1) {
            val (x0, y0) = points[index]
            val (x1, y1) = points[index + 1]
            val length = maxOf(1.0, Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)))
            val steps = (length * 2).toInt()
            for (step in 0..steps) {
                val t = step.toDouble() / steps
                val x = x0 + (x1 - x0) * t
                val y = y0 + (y1 - y0) * t
                val wander = (noise(x.toInt(), y.toInt(), 7uL) - 0.5) * 1.2
                blob(ground, x, y, width / 2 + wander, width / 2 + wander, 0.05)
            }
        }
    }

    /** A ragged edge of [ground] around the whole map, [depth] tiles deep. */
    fun border(ground: MapGround, depth: Int, ragged: Int = 2) {
        val width = layout.width
        val height = layout.height
        for (y in 0 until height) for (x in 0 until width) {
            val edge = minOf(x, y, width - 1 - x, height - 1 - y)
            val reach = depth + (noise(x, y, 3uL) * (ragged + 1)).toInt()
            if (edge < reach) layout.set(ground, x, y)
        }
    }

    /** Scatters [ground] over grass in a region, at roughly [density]. */
    fun scatter(ground: MapGround, x: IntRange, y: IntRange, density: Double) {
        for (row in y) for (column in x) {
            if (layout.ground(column, row) == MapGround.grass && noise(column, row, 11uL) < density) {
                layout.set(ground, column, row)
            }
        }
    }

    /** The finished map, with the gate approach guaranteed clear. */
    fun finish(): MapLayout {
        val result = layout.copy()
        result.clearGateApproach()
        return result
    }
}
