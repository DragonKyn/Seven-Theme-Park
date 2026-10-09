package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient
import java.util.UUID

/**
 * The park's tile grid. Owns terrain, building occupancy and litter; the
 * entities that sit on those tiles live in [GameState].
 */
@Serializable
class ParkMap(
    val width: Int = Balance.mapWidth,
    val height: Int = Balance.mapHeight,
    val tiles: MutableList<Tile> = MutableList(width * height) { Tile() },
    /** Bumped whenever walkability changes. Cached routes compare against this. */
    var generation: Int = 0,
    /** Bumped whenever litter changes, so the renderer can skip work. */
    var litterGeneration: Int = 0,
    /** Where guests appear and leave. Always a walkable entrance tile. */
    var entranceCoord: GridCoord = GridCoord(width / 2, 0),
    /** Tiles whose ground came with the map, by linear index. */
    var naturalTiles: MutableSet<Int> = mutableSetOf(),
) {
    @Transient
    val litteredTiles: MutableSet<GridCoord> = HashSet()

    @Transient
    var litterTotal: Double = 0.0

    init {
        // Recomputed rather than trusted, so the index can never drift out of
        // step with the tiles themselves.
        for (index in tiles.indices) {
            if (tiles[index].litter > 0) {
                litteredTiles.add(GridCoord(index % width, index / width))
                litterTotal += tiles[index].litter
            }
        }
    }

    // region Access

    fun isInside(coord: GridCoord): Boolean =
        coord.x >= 0 && coord.x < width && coord.y >= 0 && coord.y < height

    /** Row-major index of a coordinate. Callers must have checked [isInside]. */
    fun linearIndex(coord: GridCoord): Int = coord.y * width + coord.x

    fun coordAt(index: Int): GridCoord = GridCoord(index % width, index / width)

    val tileCount: Int get() = width * height

    fun tile(coord: GridCoord): Tile? = if (isInside(coord)) tiles[linearIndex(coord)] else null

    fun isWalkable(coord: GridCoord): Boolean = isInside(coord) && tiles[linearIndex(coord)].isWalkable

    fun walkableNeighbours(coord: GridCoord): List<GridCoord> =
        coord.orthogonalNeighbours.filter { isWalkable(it) }

    val walkableTileCount: Int get() = tiles.count { it.isWalkable }

    /** True when every tile of [rect] is inside the park, empty and buildable. */
    fun isAreaBuildable(rect: GridRect): Boolean {
        for (coord in rect.coords) {
            val tile = tile(coord) ?: return false
            if (tile.terrain != TerrainType.grass || tile.isOccupied) return false
        }
        return true
    }

    /** Whether every tile of a footprint is walkway of some kind. */
    fun isWalkwayArea(rect: GridRect): Boolean {
        for (coord in rect.coords) {
            val tile = tile(coord) ?: return false
            if (!tile.terrain.isWalkway) return false
        }
        return true
    }

    /** Walkable tiles a guest can stand on to use the given footprint. */
    fun accessTiles(rect: GridRect): List<GridCoord> = rect.adjacentCoords.filter { isWalkable(it) }

    // endregion

    // region Terrain mutation

    fun setTerrain(terrain: TerrainType, coord: GridCoord, style: Int = 0) {
        if (!isInside(coord)) return
        val index = linearIndex(coord)
        // A change of finish counts as a change: repaving a walkway in brick
        // leaves the terrain alone and has to repaint it all the same.
        if (tiles[index].terrain == terrain && tiles[index].style == style) return
        tiles[index].terrain = terrain
        tiles[index].style = style
        generation += 1

        // Rubbish cannot sit on grass a guest can no longer reach.
        if (!tiles[index].isWalkable) clearLitter(coord)
    }

    /** Marks the map as changed without changing it. */
    fun touch() {
        generation += 1
    }

    /**
     * Claims tiles for a building. [blocking] is false for park furniture,
     * which stands on the walkway without closing it.
     */
    fun setBuilding(id: UUID?, coords: List<GridCoord>, blocking: Boolean = true) {
        var changed = false
        for (coord in coords) {
            if (!isInside(coord)) continue
            val index = linearIndex(coord)
            if (tiles[index].buildingID != id) {
                tiles[index].buildingID = id
                changed = true
            }
            // Cleared tiles go back to blocking, so the flag never outlives
            // the thing that set it.
            tiles[index].blocksMovement = if (id == null) true else blocking
        }
        if (changed) generation += 1
    }

    /** Lays down the starting entrance plus a short stub of path leading in. */
    fun applyStartingLayout(pathLength: Int, entranceX: Int? = null) {
        entranceCoord = GridCoord(entranceX ?: (width / 2), 0)
        setTerrain(TerrainType.entrance, entranceCoord)
        for (offset in 1..maxOf(1, pathLength)) {
            setTerrain(TerrainType.path, GridCoord(entranceCoord.x, entranceCoord.y + offset))
        }
    }

    /** Lays a map's ground down, then the gate and the walkway in from it. */
    fun applyLayout(layout: MapLayout, pathLength: Int) {
        val cleared = layout.copy()
        cleared.clearGateApproach()

        val natural = mutableSetOf<Int>()
        for (y in 0 until minOf(height, cleared.height)) {
            for (x in 0 until minOf(width, cleared.width)) {
                val ground = cleared.ground(x, y)
                if (ground == MapGround.grass) continue
                val coord = GridCoord(x, y)
                setTerrain(ground.terrain, coord)
                natural.add(linearIndex(coord))
            }
        }
        naturalTiles = natural
        applyStartingLayout(pathLength, cleared.entranceX)
    }

    fun isNatural(coord: GridCoord): Boolean = isInside(coord) && linearIndex(coord) in naturalTiles

    // endregion

    // region Litter

    fun litter(coord: GridCoord): Double = tile(coord)?.litter ?: 0.0

    fun addLitter(amount: Double, coord: GridCoord) {
        if (!isInside(coord) || amount <= 0) return
        val index = linearIndex(coord)
        if (!tiles[index].isWalkable) return

        val before = tiles[index].litter
        val after = minOf(100.0, before + amount)
        if (after == before) return

        tiles[index].litter = after
        litterTotal += after - before
        litteredTiles.add(coord)
        litterGeneration += 1
    }

    /** Removes up to [amount] of rubbish. Returns what is left on the tile. */
    fun removeLitter(amount: Double, coord: GridCoord): Double {
        if (!isInside(coord)) return 0.0
        val index = linearIndex(coord)
        val before = tiles[index].litter
        if (before <= 0) return 0.0

        val after = maxOf(0.0, before - amount)
        tiles[index].litter = after
        litterTotal -= before - after
        if (after <= 0.5) {
            tiles[index].litter = 0.0
            litteredTiles.remove(coord)
        }
        litterGeneration += 1
        return tiles[index].litter
    }

    fun clearLitter(coord: GridCoord) {
        removeLitter(100.0, coord)
    }

    /**
     * 0-1, where 1 is spotless. Concentrated rubbish reads as much worse than
     * the raw average would suggest, which matches how guests experience it.
     */
    val cleanlinessScore: Double
        get() {
            val walkable = walkableTileCount
            if (walkable <= 0) return 1.0
            val saturation = litterTotal / (walkable * 100.0)
            return SimMath.clamp(1 - saturation * 6, 0.0, 1.0)
        }

    // endregion

    // region Beauty

    fun beauty(coord: GridCoord): Double = if (isInside(coord)) tiles[linearIndex(coord)].beauty else 0.0

    /** Average prettiness of the ground guests can actually stand on. */
    val beautyScore: Double
        get() {
            var total = 0.0
            var count = 0
            for (tile in tiles) {
                if (tile.isWalkable) {
                    total += tile.beauty
                    count += 1
                }
            }
            if (count <= 0) return 0.0
            return SimMath.clamp(total / count / 100, 0.0, 1.0)
        }

    /** One thing that makes the ground around it prettier. */
    class BeautySource(val rect: GridRect, val beauty: Double, val radius: Int) {
        /** Linear falloff is enough: closer is better. */
        fun beautyAt(distance: Int): Double {
            if (distance > radius) return 0.0
            if (radius <= 0) return beauty
            return beauty * (1 - distance.toDouble() / (radius + 1))
        }
    }

    /** Rebuilds the whole beauty field from what is currently placed. */
    fun recomputeBeauty(sources: List<BeautySource>) {
        for (tile in tiles) tile.beauty = 0.0

        for (source in sources) {
            val radius = source.radius
            val area = source.rect
            val minX = area.origin.x - radius
            val maxX = area.origin.x + area.size.width - 1 + radius
            val minY = area.origin.y - radius
            val maxY = area.origin.y + area.size.height - 1 + radius

            for (y in minY..maxY) {
                for (x in minX..maxX) {
                    val coord = GridCoord(x, y)
                    if (!isInside(coord)) continue
                    val distance = area.chebyshevDistance(coord)
                    val contribution = source.beautyAt(distance)
                    if (contribution <= 0) continue

                    // Overlapping sources stack with diminishing returns.
                    val index = linearIndex(coord)
                    val current = tiles[index].beauty
                    tiles[index].beauty = minOf(100.0, current + contribution * (1 - current / 100))
                }
            }
        }
    }

    /** Whether any tile touching this footprint is the given terrain. */
    fun touchesTerrain(terrain: TerrainType, rect: GridRect): Boolean =
        rect.adjacentCoords.any { tile(it)?.terrain == terrain }

    /** Every tile of the given terrain. */
    fun coords(terrain: TerrainType): List<GridCoord> {
        val result = ArrayList<GridCoord>()
        for (index in tiles.indices) if (tiles[index].terrain == terrain) result.add(coordAt(index))
        return result
    }

    // endregion

    // region Placement helpers

    /** True when every tile of [rect] is inside the park, unoccupied, and grass or plain walkway. */
    fun isAreaClearGround(rect: GridRect): Boolean {
        for (coord in rect.coords) {
            val tile = tile(coord) ?: return false
            if (tile.terrain != TerrainType.grass && tile.terrain != TerrainType.path) return false
            if (tile.isOccupied) return false
        }
        return true
    }

    /**
     * Whether putting something that blocks movement on [rect] would leave any
     * walkway cut off from the entrance.
     */
    fun wouldStrandWalkways(rect: GridRect): Boolean {
        val covered = rect.coords.filter { isInside(it) }.map { linearIndex(it) }.toSet()
        if (covered.none { tiles[it].terrain.isWalkableTerrain }) return false

        val before = reachableFromEntrance(emptySet())
        val after = reachableFromEntrance(covered)

        for (index in 0 until tileCount) {
            if (before[index] && index !in covered && !after[index]) return true
        }
        return false
    }

    private fun reachableFromEntrance(blocked: Set<Int>): BooleanArray {
        val reached = BooleanArray(tileCount)
        if (!isInside(entranceCoord)) return reached

        val frontier = ArrayDeque<Int>()
        val start = linearIndex(entranceCoord)
        frontier.add(start)
        reached[start] = true

        while (frontier.isNotEmpty()) {
            val index = frontier.removeLast()
            for (neighbour in coordAt(index).orthogonalNeighbours) {
                if (!isInside(neighbour)) continue
                val next = linearIndex(neighbour)
                if (reached[next] || next in blocked || !tiles[next].isWalkable) continue
                reached[next] = true
                frontier.add(next)
            }
        }
        return reached
    }

    // endregion
}
