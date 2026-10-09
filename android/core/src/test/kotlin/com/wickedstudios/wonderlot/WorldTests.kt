package com.wickedstudios.wonderlot

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class WorldTests {
    private fun newMap(): ParkMap {
        val map = ParkMap()
        map.applyStartingLayout(Balance.startingPathLength)
        return map
    }

    @Test
    fun startingLayoutHasGateAndPath() {
        val map = newMap()
        assertEquals(TerrainType.entrance, map.tile(map.entranceCoord)?.terrain)
        assertTrue(map.isWalkable(GridCoord(map.entranceCoord.x, 1)))
        assertEquals(Balance.startingPathLength + 1, map.walkableTileCount)
    }

    @Test
    fun cannotBuildOverTheOnlyPath() {
        val map = newMap()
        val x = map.entranceCoord.x
        // Covering the middle of the starting path would strand the tiles beyond it.
        assertTrue(map.wouldStrandWalkways(GridRect(GridCoord(x, 2), GridSize(1, 1))))
        // The last tile of the path can be covered without stranding anything.
        assertFalse(map.wouldStrandWalkways(GridRect(GridCoord(x, Balance.startingPathLength), GridSize(1, 1))))
    }

    @Test
    fun rotationSwapsSidesOnQuarterTurns() {
        assertEquals(GridSize(1, 3), GridSize(3, 1).rotated(1))
        assertEquals(GridSize(3, 1), GridSize(3, 1).rotated(2))
        assertEquals(GridSize(1, 3), GridSize(3, 1).rotated(-1))
    }

    @Test
    fun rideTurnsNeverGoUpsideDown() {
        val ride = CoasterElementContent.all.first()
        assertEquals(listOf(0, 1, 2, 3), ride.allowedTurns)
    }

    @Test
    fun seededGeneratorIsDeterministic() {
        val a = SeededGenerator(42)
        val b = SeededGenerator(42)
        repeat(20) { assertEquals(a.nextLong(), b.nextLong()) }
    }

    @Test
    fun mapPainterIsStable() {
        val one = MapPainter(seed = 7uL).also { it.blob(MapGround.water, 30.0, 30.0, 8.0, 6.0) }.finish()
        val two = MapPainter(seed = 7uL).also { it.blob(MapGround.water, 30.0, 30.0, 8.0, 6.0) }.finish()
        assertEquals(one.ground, two.ground)
        assertTrue(one.ground.any { it == MapGround.water })
    }
}
