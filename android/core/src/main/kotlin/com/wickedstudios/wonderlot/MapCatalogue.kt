package com.wickedstudios.wonderlot

import kotlin.math.sin

/** A map a park can be built on: a name, a line about what makes it what it is, and the land itself. */
data class MapBlueprint(
    val id: String,
    val name: String,
    val summary: String,
    /** How much the land fights the player, 1 to 5. */
    val difficulty: Int,
    val layout: MapLayout,
    /** False for the maps that ship with the game. */
    val isCustom: Boolean = false,
)

/** The maps that ship with the game. The seed is fixed per map, so a map is the same every time. */
object MapCatalogue {

    const val openMeadowID = "map.meadow"

    private fun p(x: Int, y: Int) = Pair(x.toDouble(), y.toDouble())

    /** Almost all of it is open grass, with a few copses round the edge. */
    val openMeadow: MapBlueprint by lazy {
        val painter = MapPainter(seed = 11uL)
        painter.scatter(MapGround.forest, 0..59, 50..59, 0.35)
        painter.blob(MapGround.forest, 6.0, 30.0, 4.0, 6.0)
        painter.blob(MapGround.forest, 54.0, 22.0, 3.5, 5.0)
        MapBlueprint(openMeadowID, "Open Meadow", "Flat, open grass as far as the fence. Room for anything.", 1, painter.finish())
    }

    /** A lake in the middle of the lot with two islands in it. */
    val willowLake: MapBlueprint by lazy {
        val painter = MapPainter(seed = 23uL)
        painter.blob(MapGround.water, 30.0, 34.0, 19.0, 15.0, 0.14)
        painter.blob(MapGround.grass, 22.0, 38.0, 6.0, 5.0)
        painter.blob(MapGround.grass, 38.0, 30.0, 5.0, 6.0)
        painter.scatter(MapGround.forest, 0..59, 54..59, 0.30)
        MapBlueprint("map.willowlake", "Willow Lake",
            "A lake fills the middle with two islands in it. Bridges get you there.", 2, painter.finish())
    }

    /** A strip of land five tiles wide running out into the sea. */
    val longPier: MapBlueprint by lazy {
        val painter = MapPainter(fill = MapGround.water, entranceX = 30, seed = 37uL)
        painter.rect(MapGround.grass, 28..32, 0..44)
        painter.blob(MapGround.grass, 30.0, 50.0, 9.0, 6.0, 0.10)
        // A couple of jetties off the side, to reward thinking sideways.
        painter.rect(MapGround.grass, 18..27, 16..19)
        painter.rect(MapGround.grass, 33..42, 30..33)
        painter.rect(MapGround.rock, 0..59, 57..59)
        MapBlueprint("map.longpier", "The Long Pier",
            "A strip five tiles wide out into the sea. Nothing is wasted here.", 4, painter.finish())
    }

    /** A river crosses the whole map in a loose S. */
    val riverbend: MapBlueprint by lazy {
        val painter = MapPainter(seed = 41uL)
        painter.band(MapGround.water, listOf(p(-2, 16), p(14, 22), p(28, 14), p(42, 26), p(50, 40), p(62, 44)), 5.0)
        painter.scatter(MapGround.forest, 0..59, 48..59, 0.28)
        painter.blob(MapGround.forest, 8.0, 44.0, 5.0, 4.0)
        MapBlueprint("map.riverbend", "Riverbend",
            "A river winds right across the lot. Stay on one bank, or pay to cross.", 3, painter.finish())
    }

    /** Thick pine forest with a chain of clearings through it. */
    val pinewoodClearing: MapBlueprint by lazy {
        val painter = MapPainter(fill = MapGround.forest, seed = 53uL)
        painter.blob(MapGround.grass, 30.0, 9.0, 11.0, 8.0)
        painter.blob(MapGround.grass, 18.0, 27.0, 10.0, 8.0)
        painter.blob(MapGround.grass, 41.0, 33.0, 11.0, 9.0)
        painter.blob(MapGround.grass, 27.0, 49.0, 12.0, 7.0)
        painter.band(MapGround.grass, listOf(p(30, 9), p(18, 27), p(41, 33), p(27, 49)), 4.0)
        MapBlueprint("map.pinewood", "Pinewood Clearing",
            "Dense pines with a chain of clearings through them. Build in pockets.", 3, painter.finish())
    }

    /** Rock walls either side of a winding valley. */
    val canyonFloor: MapBlueprint by lazy {
        val painter = MapPainter(fill = MapGround.rock, entranceX = 24, seed = 67uL)
        painter.band(MapGround.grass, listOf(p(24, -2), p(22, 14), p(34, 26), p(30, 40), p(38, 52), p(36, 62)), 12.0)
        // A stream down the middle of it, because it is a canyon.
        painter.band(MapGround.water, listOf(p(31, 20), p(34, 26), p(31, 36), p(33, 44)), 2.0)
        MapBlueprint("map.canyon", "Canyon Floor",
            "Sheer rock either side of a winding valley. The valley is all you get.", 4, painter.finish())
    }

    /** Two blocks of land split by a rocky ridge, joined by a single narrow pass. */
    val twinPlateaus: MapBlueprint by lazy {
        val painter = MapPainter(seed = 79uL)
        painter.band(MapGround.rock, listOf(p(-2, 30), p(20, 28), p(40, 32), p(62, 30)), 7.0)
        painter.rect(MapGround.grass, 28..31, 22..38)
        painter.border(MapGround.forest, 1, 2)
        MapBlueprint("map.twinplateaus", "Twin Plateaus",
            "A rocky ridge splits the land in two, with one narrow pass between.", 3, painter.finish())
    }

    /** A point of land narrowing into the sea, water on three sides. */
    val harbourPoint: MapBlueprint by lazy {
        val painter = MapPainter(fill = MapGround.water, entranceX = 30, seed = 97uL)
        for (y in 0 until 60) {
            val halfWidth = maxOf(3.0, 28 - y * 0.42)
            val centre = 30 + sin(y / 9.0) * 3
            for (x in (centre - halfWidth).toInt()..(centre + halfWidth).toInt()) {
                painter.rect(MapGround.grass, x..x, y..y)
            }
        }
        painter.blob(MapGround.rock, 30.0, 56.0, 3.0, 3.0)
        MapBlueprint("map.harbour", "Harbour Point",
            "A headland narrowing into the sea. Roomy at the gate, tight at the tip.", 3, painter.finish())
    }

    /** Open sea with a scatter of islands, the gate on the largest. */
    val archipelago: MapBlueprint by lazy {
        val painter = MapPainter(fill = MapGround.water, entranceX = 30, seed = 131uL)
        painter.blob(MapGround.grass, 30.0, 6.0, 11.0, 8.0, 0.12)
        painter.blob(MapGround.grass, 12.0, 20.0, 7.0, 6.0)
        painter.blob(MapGround.grass, 47.0, 19.0, 7.0, 5.0)
        painter.blob(MapGround.grass, 27.0, 30.0, 6.0, 5.0)
        painter.blob(MapGround.grass, 9.0, 42.0, 6.0, 7.0)
        painter.blob(MapGround.grass, 42.0, 40.0, 8.0, 6.0)
        painter.blob(MapGround.grass, 25.0, 52.0, 9.0, 5.0)
        painter.blob(MapGround.forest, 42.0, 42.0, 2.5, 2.0)
        painter.blob(MapGround.rock, 9.0, 45.0, 2.0, 2.0)
        MapBlueprint("map.archipelago", "Archipelago",
            "Open sea and a scatter of islands. No one island holds a park.", 5, painter.finish())
    }

    /** Solid rock with one valley doubling back on itself up the map. */
    val switchbackRidge: MapBlueprint by lazy {
        val painter = MapPainter(fill = MapGround.rock, entranceX = 30, seed = 149uL)
        painter.band(MapGround.grass,
            listOf(p(30, -2), p(30, 10), p(12, 16), p(12, 26), p(47, 32), p(47, 42), p(18, 48), p(18, 62)), 8.0)
        // Wider shelves at two of the bends, the only places a big ride fits.
        painter.blob(MapGround.grass, 12.0, 21.0, 7.0, 6.0, 0.10)
        painter.blob(MapGround.grass, 47.0, 37.0, 7.0, 6.0, 0.10)
        painter.blob(MapGround.water, 47.0, 38.0, 2.0, 2.0)
        MapBlueprint("map.switchback", "Switchback Ridge",
            "A single valley zig-zags up through solid rock. Every bend is a squeeze.", 5, painter.finish())
    }

    val all: List<MapBlueprint> by lazy {
        listOf(openMeadow, willowLake, longPier, riverbend, pinewoodClearing, canyonFloor,
            twinPlateaus, harbourPoint, archipelago, switchbackRidge)
    }

    fun blueprint(id: String): MapBlueprint? = all.firstOrNull { it.id == id }
}
