package com.wickedstudios.wonderlot

import java.util.UUID

/** Single source of truth for product naming. */
object AppInfo {
    const val gameName = "Wonder Lot"

    /** Shown one at a time under the title, in order. */
    val taglines = listOf(
        "From empty lot to endless fun.",
        "Your land. Your rides. Your wonder.",
        "Build big. Dream bigger.",
        "Every great park starts with a lot.",
        "Turn a little lot into a lot of wonder.",
    )

    val tagline: String get() = taglines[0]
}

/**
 * Builds the small park that runs behind the main menu. It is an ordinary
 * [GameState] driven by the ordinary simulation, so the menu shows the real game.
 */
object DemoPark {

    /** A laid-out park with a crowd already in it. */
    fun makeState(): GameState {
        val state = newGameState(AppInfo.gameName, seed = 20_260_909L)

        // Fund the layout generously so a price change never silently drops the
        // last few pieces, then put the balance back once everything is standing.
        state.ledger.cash = 1_000_000.0

        layOutPaths(state)
        placeBuildings(state)
        placeScenery(state)
        hireStaff(state)

        // Free entry and a good reputation, so the park fills quickly and stays full.
        state.admissionPrice = 0.0
        state.parkRating = 82.0
        state.clock.speed = GameSpeed.normal

        warmUp(state)
        return state
    }

    private fun layOutPaths(state: GameState) {
        val spine = state.map.entranceCoord.x

        // A spine up the middle from the entrance, with two side streets.
        for (y in 1..18) state.map.setTerrain(TerrainType.path, GridCoord(spine, y))
        for (x in (spine - 7)..(spine + 7)) {
            state.map.setTerrain(TerrainType.path, GridCoord(x, 7))
            state.map.setTerrain(TerrainType.path, GridCoord(x, 14))
        }

        // A third street along the bottom, which is what the station platforms open on to.
        for (y in 19..20) state.map.setTerrain(TerrainType.path, GridCoord(spine, y))
        for (x in (spine - 7)..(spine + 7)) state.map.setTerrain(TerrainType.path, GridCoord(x, 20))
    }

    private fun placeBuildings(state: GameState) {
        val spine = state.map.entranceCoord.x

        place(state, "ride.carousel", GridCoord(spine - 5, 8))
        place(state, "ride.pirateship", GridCoord(spine + 2, 8))
        place(state, "ride.droptower", GridCoord(spine - 5, 15))
        place(state, "ride.minicoaster", GridCoord(spine + 1, 15))
        place(state, "ride.ferriswheel", GridCoord(spine - 10, 8))
        place(state, "ride.hauntedhouse", GridCoord(spine - 10, 15))
        place(state, "ride.gokarts.small", GridCoord(spine + 7, 8))

        layOutRailway(state)
        place(state, "transport.station", GridCoord(spine - 5, 21))
        place(state, "transport.station", GridCoord(spine + 2, 21))

        place(state, "shop.burger", GridCoord(spine - 3, 5))
        place(state, "shop.drinks", GridCoord(spine + 2, 5))
        place(state, "shop.icecream", GridCoord(spine - 3, 12))
        place(state, "facility.bathroom", GridCoord(spine + 2, 12))

        place(state, "facility.bench", GridCoord(spine - 1, 4))
        place(state, "facility.bench", GridCoord(spine + 1, 4))
        place(state, "facility.bin", GridCoord(spine - 1, 6))
        place(state, "facility.bin", GridCoord(spine + 1, 13))
    }

    /** A loop of track below the park with a two-tile gap between it and the bottom street. */
    private fun layOutRailway(state: GameState) {
        val spine = state.map.entranceCoord.x
        val left = spine - 7
        val right = spine + 7

        for (x in left..right) {
            state.map.setTerrain(TerrainType.track, GridCoord(x, 23))
            state.map.setTerrain(TerrainType.track, GridCoord(x, 28))
        }
        for (y in 24..27) {
            state.map.setTerrain(TerrainType.track, GridCoord(left, y))
            state.map.setTerrain(TerrainType.track, GridCoord(right, y))
        }
    }

    private fun placeScenery(state: GameState) {
        val spine = state.map.entranceCoord.x

        // Centrepiece, beside the main walkway where everyone passes it.
        place(state, "scenery.fountain", GridCoord(spine - 2, 10))
        place(state, "scenery.statue", GridCoord(spine + 1, 11))

        for (coord in listOf(
            GridCoord(spine - 2, 1), GridCoord(spine + 2, 1), GridCoord(spine - 2, 3), GridCoord(spine + 2, 3),
            GridCoord(spine - 6, 9), GridCoord(spine + 6, 9), GridCoord(spine - 6, 11), GridCoord(spine + 6, 11),
            GridCoord(spine - 2, 8), GridCoord(spine + 1, 8), GridCoord(spine - 2, 17), GridCoord(spine - 6, 17),
        )) place(state, "scenery.tree", coord)

        for (coord in listOf(
            GridCoord(spine - 6, 6), GridCoord(spine + 6, 6), GridCoord(spine - 6, 13), GridCoord(spine + 6, 13),
        )) place(state, "scenery.conifer", coord)

        for (coord in listOf(
            GridCoord(spine - 1, 1), GridCoord(spine + 1, 1), GridCoord(spine - 1, 3), GridCoord(spine + 1, 3),
        )) place(state, "scenery.flowerbed", coord)

        for (coord in listOf(
            GridCoord(spine - 1, 13), GridCoord(spine + 1, 12), GridCoord(spine - 1, 16), GridCoord(spine - 1, 18),
        )) place(state, "scenery.lamp", coord)

        place(state, "scenery.topiary", GridCoord(spine - 1, 5))
        place(state, "scenery.topiary", GridCoord(spine + 1, 5))

        // A pond beside the entrance walk.
        for (x in (spine + 3)..(spine + 5)) for (y in 1..3) place(state, "terrain.water", GridCoord(x, y))
    }

    /** One employee of each role, plus a second performer. Appended directly: there is nobody to charge. */
    private fun hireStaff(state: GameState) {
        val entrance = state.map.entranceCoord
        for (role in StaffRole.entries) {
            val member = Staff(id = UUID.randomUUID(), name = GuestNames.random(state.rng), role = role,
                position = entrance.centre, tile = entrance)
            if (role == StaffRole.mascot) {
                member.costume = MascotCostume.frog
                member.name = MascotCostume.frog.name(state.rng)
            }
            state.staff.add(member)
        }

        val artist = Staff(id = UUID.randomUUID(), name = GuestNames.random(state.rng), role = StaffRole.entertainer,
            position = entrance.centre, tile = entrance)
        artist.act = EntertainerAct.balloonArtist
        state.staff.add(artist)
    }

    /** Places by definition id. A thing that fails to fit is a mistake in this file, and a missing tree is not worth a crash. */
    private fun place(state: GameState, definitionID: String, coord: GridCoord) {
        val definition = GameContent.allBuildables.firstOrNull { it.id == definitionID } ?: return
        state.place(definition, coord)
    }

    /**
     * Fills the park before the menu appears. Guests are seeded directly rather
     * than waited for; a short run afterwards spreads everyone out from the gate.
     */
    private fun warmUp(state: GameState) {
        val engine = SimulationEngine()
        engine.seedGuests(45, state)

        // One tick per call: the engine caps how many ticks a single call may run.
        val ticks = (25.0 / Balance.tickDuration).toInt()
        for (i in 0 until ticks) engine.advance(state, Balance.tickDuration)

        // Money is meaningless here.
        state.ledger.cash = Balance.startingCash
    }
}
