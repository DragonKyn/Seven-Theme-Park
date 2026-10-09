package com.wickedstudios.wonderlot

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class SimulationTests {

    @Test
    fun demoParkBuildsWithRidesShopsAndStaff() {
        val state = DemoPark.makeState()
        assertTrue(state.attractions.size >= 7, "rides: ${state.attractions.size}")
        assertTrue(state.facilities.size >= 8, "facilities: ${state.facilities.size}")
        assertTrue(state.staff.size >= 6, "staff: ${state.staff.size}")
        assertTrue(state.guestCount > 20, "guests: ${state.guestCount}")
    }

    @Test
    fun parkRunsForSeveralDaysWithoutBreaking() {
        val state = DemoPark.makeState()
        val engine = SimulationEngine()
        state.clock.speed = GameSpeed.fast

        var maxGuests = 0
        // Three park days at 2x, in 1/30s frames.
        val frames = (Balance.dayLength * 3 / 2 * 30).toInt()
        for (frame in 0 until frames) {
            engine.advance(state, 1.0 / 30)
            maxGuests = maxOf(maxGuests, state.guestCount)
        }

        println("days=${state.clock.day} guests=$maxGuests rating=${state.parkRating.toInt()} " +
            "cash=${state.ledger.cash.toInt()} rides=${state.statistics.ridesGivenTotal} " +
            "sold=${state.statistics.itemsSoldTotal} admitted=${state.statistics.guestsAdmittedTotal}")

        assertTrue(state.clock.day >= 3, "clock moved: ${state.clock.day}")
        assertTrue(state.statistics.ridesGivenTotal > 0, "rides were given")
        assertTrue(state.statistics.guestsAdmittedTotal > 0, "guests were admitted")
        assertTrue(maxGuests <= Balance.maxGuests, "crowd stayed capped")
    }

    @Test
    fun savesRoundTrip() {
        val state = DemoPark.makeState()
        val dir = File.createTempFile("wonderlot", "").let { it.delete(); it.mkdirs(); it }
        val service = SaveGameService(dir)

        service.save(state, SaveLocation.Slot(1))
        val summary = service.summary(SaveLocation.Slot(1))
        assertNotNull(summary)
        assertEquals(1, summary.slot)

        val loaded = service.load(SaveLocation.Slot(1))
        assertEquals(state.attractions.size, loaded.attractions.size)
        assertEquals(state.facilities.size, loaded.facilities.size)
        assertEquals(state.guestCount, loaded.guestCount)
        assertEquals(state.map.walkableTileCount, loaded.map.walkableTileCount)
        dir.deleteRecursively()
    }

    @Test
    fun buildingAndDemolishingRefunds() {
        val state = newGameState("Test")
        val x = state.map.entranceCoord.x
        val ride = GameContent.attraction("ride.carousel")!!
        val before = state.ledger.cash

        // Beside the starting walkway, so guests can reach it.
        val check = state.placementCheck(ride, GridCoord(x + 1, 3))
        assertTrue(check.isValid, "placement: ${check.reason}")
        assertTrue(state.place(ride, GridCoord(x + 1, 3)))
        assertTrue(state.ledger.cash < before)
        assertEquals(1, state.attractions.size)
        assertTrue(state.demolish(GridCoord(x + 1, 3)))
        assertEquals(0, state.attractions.size)
    }

    @Test
    fun ridesAndShopsNeverTurnUpsideDown() {
        val ride = GameContent.attraction("ride.carousel")!!
        assertEquals(listOf(0, 1, 3), ride.allowedTurns)
        assertEquals(1, ride.nextTurn(0))
        assertEquals(3, ride.nextTurn(1))
        assertEquals(0, ride.nextTurn(3))
    }

    @Test
    fun catalogueIsComplete() {
        assertTrue(GameContent.attractions.size >= 28, "rides ${GameContent.attractions.size}")
        assertTrue(GameContent.facilities.size >= 15, "facilities ${GameContent.facilities.size}")
        assertTrue(GameContent.scenery.size >= 16, "scenery ${GameContent.scenery.size}")
        assertNotNull(GameContent.facility("shop.popcorn"))
        assertEquals(10, MapCatalogue.all.size)
        assertEquals(15, TrialContent.all.size)
    }
}
