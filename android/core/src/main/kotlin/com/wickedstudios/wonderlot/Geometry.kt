package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sqrt

/** A point in tile space (1 unit == 1 tile). */
@Serializable
data class Vec2(val x: Double, val y: Double) {
    fun distanceTo(other: Vec2): Double {
        val dx = x - other.x
        val dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

/** Integer tile coordinate. Origin is the bottom-left of the park; +y is north. */
@Serializable
data class GridCoord(val x: Int, val y: Int) {
    /** True when the two tiles share an edge. Diagonals do not count. */
    fun isOrthogonallyAdjacent(other: GridCoord): Boolean = abs(x - other.x) + abs(y - other.y) == 1

    val orthogonalNeighbours: List<GridCoord>
        get() = listOf(GridCoord(x + 1, y), GridCoord(x - 1, y), GridCoord(x, y + 1), GridCoord(x, y - 1))

    fun manhattanDistance(other: GridCoord): Int = abs(x - other.x) + abs(y - other.y)

    /** Centre of the tile expressed in tile-space. */
    val centre: Vec2 get() = Vec2(x + 0.5, y + 0.5)

    companion object {
        val zero = GridCoord(0, 0)
    }
}

/** Footprint size in tiles. */
@Serializable
data class GridSize(val width: Int, val height: Int) {
    val tileCount: Int get() = width * height

    /** The footprint after turning it a quarter turn at a time. */
    fun rotated(quarterTurns: Int): GridSize =
        if (((quarterTurns % 4) + 4) % 4 % 2 == 0) this else GridSize(height, width)

    companion object {
        val single = GridSize(1, 1)
    }
}

/** An axis-aligned block of tiles: a building footprint or a selection. */
@Serializable
data class GridRect(val origin: GridCoord, val size: GridSize) {
    val coords: List<GridCoord>
        get() {
            val result = ArrayList<GridCoord>(size.tileCount)
            for (dy in 0 until size.height) for (dx in 0 until size.width) {
                result.add(GridCoord(origin.x + dx, origin.y + dy))
            }
            return result
        }

    fun contains(coord: GridCoord): Boolean =
        coord.x >= origin.x && coord.x < origin.x + size.width &&
            coord.y >= origin.y && coord.y < origin.y + size.height

    /** Tiles orthogonally touching the rect. */
    val adjacentCoords: List<GridCoord>
        get() {
            val result = ArrayList<GridCoord>()
            for (dx in 0 until size.width) {
                result.add(GridCoord(origin.x + dx, origin.y - 1))
                result.add(GridCoord(origin.x + dx, origin.y + size.height))
            }
            for (dy in 0 until size.height) {
                result.add(GridCoord(origin.x - 1, origin.y + dy))
                result.add(GridCoord(origin.x + size.width, origin.y + dy))
            }
            return result
        }

    /** Tiles away from the nearest tile of this rect, a diagonal step counting one. */
    fun chebyshevDistance(coord: GridCoord): Int {
        val dx = maxOf(origin.x - coord.x, coord.x - (origin.x + size.width - 1), 0)
        val dy = maxOf(origin.y - coord.y, coord.y - (origin.y + size.height - 1), 0)
        return max(dx, dy)
    }

    val centre: Vec2
        get() = Vec2(origin.x + size.width / 2.0, origin.y + size.height / 2.0)
}
