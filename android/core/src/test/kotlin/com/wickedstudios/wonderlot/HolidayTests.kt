package com.wickedstudios.wonderlot

import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class HolidayTests {
    @BeforeTest
    fun fixCalendar() {
        HolidaySeason.override = null
        HolidaySeason.clock = { CalendarDate(2026, 12, 10) }
    }

    @AfterTest
    fun restore() {
        HolidaySeason.override = false
        HolidaySeason.clock = { CalendarDate.today() }
    }

    // region Calendar

    @Test
    fun seasonRunsFromTheTwentyFifthOfNovemberToTheFifthOfJanuary() {
        fun on(y: Int, m: Int, d: Int) = HolidaySeason.inWindow(CalendarDate(y, m, d))
        assertFalse(on(2026, 11, 24))
        assertTrue(on(2026, 11, 25))
        assertTrue(on(2026, 12, 25))
        assertTrue(on(2026, 12, 31))
        assertTrue(on(2027, 1, 1))
        assertTrue(on(2027, 1, 5))
        assertFalse(on(2027, 1, 6))
        assertFalse(on(2027, 7, 4))
        assertFalse(on(2027, 11, 1))
    }

    @Test
    fun earlyJanuaryBelongsToTheYearTheEventBeganIn() {
        assertEquals(2026, HolidaySeason.eventYear(CalendarDate(2026, 11, 25)))
        assertEquals(2026, HolidaySeason.eventYear(CalendarDate(2026, 12, 31)))
        assertEquals(2026, HolidaySeason.eventYear(CalendarDate(2027, 1, 3)))
    }

    @Test
    fun daysLeftCountsDownAndStopsAtTheEnd() {
        assertEquals(42, HolidaySeason.daysLeft(CalendarDate(2026, 11, 25)))
        assertEquals(1, HolidaySeason.daysLeft(CalendarDate(2027, 1, 5)))
        assertEquals(0, HolidaySeason.daysLeft(CalendarDate(2027, 2, 1)))
    }

    @Test
    fun theOverrideBeatsTheCalendar() {
        HolidaySeason.clock = { CalendarDate(2027, 6, 1) }
        assertFalse(HolidaySeason.isActive())
        HolidaySeason.override = true
        assertTrue(HolidaySeason.isActive())
        HolidaySeason.override = false
        HolidaySeason.clock = { CalendarDate(2026, 12, 10) }
        assertFalse(HolidaySeason.isActive())
    }

    // endregion

    // region Store

    @Test
    fun theAnnouncementIsPutAwayForTheYearAndReturnsTheNext() {
        val store = HolidayStore(MemoryStore())
        val inSeason = CalendarDate(2026, 12, 1)
        assertTrue(store.shouldAnnounce(inSeason))
        store.hideAnnouncement(inSeason)
        assertFalse(store.shouldAnnounce(inSeason))
        // Still put away in January, which is the same event.
        assertFalse(store.shouldAnnounce(CalendarDate(2027, 1, 2)))
        // And back the following year.
        assertTrue(store.shouldAnnounce(CalendarDate(2027, 11, 30)))
        // Never shown outside the event.
        assertFalse(store.shouldAnnounce(CalendarDate(2027, 3, 1)))
    }

    @Test
    fun rewardsAreEarnedOnceAndKept() {
        val store = HolidayStore(MemoryStore())
        val trial = TrialContent.holiday.first { it.id == "holiday.02" }
        assertFalse(store.canUse("scenery.xmas.gifts"))
        val first = store.recordWin(trial, 2026)
        assertEquals(listOf("reward.giftstack"), first.map { it.id })
        assertTrue(store.canUse("scenery.xmas.gifts"))
        // Winning it again hands over nothing new.
        assertTrue(store.recordWin(trial, 2026).isEmpty())
        assertTrue(store.isCompleted(trial, 2026))
        assertFalse(store.isCompleted(trial, 2027))
        // The reward outlasts the year.
        assertTrue(store.canUse("scenery.xmas.gifts"))
    }

    @Test
    fun trialsThatNeedARewardStayShutUntilItIsHeld() {
        val store = HolidayStore(MemoryStore())
        val seven = TrialContent.holiday.first { it.id == "holiday.07" }
        assertFalse(store.isOpen(seven))
        store.recordWin(TrialContent.holiday.first { it.id == "holiday.01" }, 2026)
        assertTrue(store.isOpen(seven))
    }

    // endregion

    // region Content

    @Test
    fun theEventHasTheContentItPromised() {
        assertEquals(11, HolidayContent.attractions.size)
        assertEquals(7, HolidayContent.attractions.count { it.id.startsWith("ride.xmas.") })
        assertEquals(4, HolidayContent.attractions.count { it.id.startsWith("ride.newyear.") })
        assertEquals(12, TrialContent.holiday.size)
        assertEquals(300, Balance.maxGuests)
        assertTrue(HolidayContent.attractions.all { it.seasonal && it.group == RideGroup.holiday })
        assertTrue(HolidayContent.scenery.all { it.seasonal })
    }

    @Test
    fun everyHolidayTrialIsWellFormed() {
        val rewardIDs = HolidayRewards.all.map { it.id }.toSet()
        for (trial in TrialContent.holiday) {
            assertEquals(TrialSeries.holiday, trial.series)
            assertTrue(trial.rewardIDs.isNotEmpty(), "${trial.id} has a reward")
            assertTrue(trial.rewardIDs.all { it in rewardIDs }, "${trial.id} rewards exist")
            trial.needsRewardID?.let { assertTrue(it in rewardIDs, "${trial.id} needs a real reward") }
            assertNotNull(MapCatalogue.blueprint(trial.mapID), "${trial.id} map")
            for (goal in trial.goals) {
                if (goal is TrialGoal.Build) assertNotNull(GameContent.attraction(goal.definitionID) ?: GameContent.facility(goal.definitionID), "${trial.id} builds a real thing")
            }
        }
        // Every reward is handed out by exactly one trial.
        for (id in rewardIDs) assertEquals(1, TrialContent.holiday.count { id in it.rewardIDs }, "$id is awarded once")
    }

    @Test
    fun noTrialGoalNeedsSomethingThatIsLocked() {
        // A goal that builds a thing must not be one a trial reward has to open first.
        val locked = HolidayRewards.all.flatMap { it.opens }.toSet()
        for (trial in TrialContent.holiday) {
            for (goal in trial.goals) {
                if (goal is TrialGoal.Build) assertFalse(goal.definitionID in locked, "${trial.id} builds ${goal.definitionID}")
            }
        }
    }

    @Test
    fun lockedItemsNeedTheirReward() {
        val store = HolidayStore(MemoryStore())
        val candy = GameContent.attraction("ride.xmas.candycoaster")!!
        val reindeer = GameContent.attraction("ride.xmas.reindeercarousel")!!
        assertFalse(HolidayContent.canBuild(candy, true, store), "candy locked before")
        assertTrue(HolidayContent.canBuild(reindeer, true, store), "reindeer free: req=${HolidayRewards.requiredFor(reindeer.id)} seasonal=${reindeer.seasonal} canUse=${store.canUse(reindeer.id)}")
        // Nothing seasonal is on offer outside the event.
        assertFalse(HolidayContent.canBuild(reindeer, false, store), "nothing out of season")
        store.recordWin(TrialContent.holiday.first { it.id == "holiday.06" }, 2026)
        assertTrue(store.isUnlocked("reward.ride.candycoaster"), "reward held: ${store.unlocked}")
        assertTrue(HolidayContent.canBuild(candy, true, store), "candy open after")
        // Ordinary rides are never affected.
        assertTrue(HolidayContent.canBuild(GameContent.attraction("ride.carousel")!!, false, store), "ordinary rides")
    }

    @Test
    fun theHolidayPerformersAreSeasonalAndMrsClausIsEarned() {
        val store = HolidayStore(MemoryStore())
        assertTrue(HolidayContent.canHire(EntertainerAct.santa, true, store))
        assertFalse(HolidayContent.canHire(EntertainerAct.santa, false, store))
        assertFalse(HolidayContent.canHire(EntertainerAct.missus, true, store))
        store.recordWin(TrialContent.holiday.first { it.id == "holiday.04" }, 2026)
        assertTrue(HolidayContent.canHire(EntertainerAct.missus, true, store))
        assertTrue(HolidayContent.canHire(EntertainerAct.clown, false, store))
    }

    @Test
    fun makeoversCoverEveryOrdinaryRideAndNoHolidayOne() {
        val covered = HolidayMakeovers.run { MakeoverSet.entries.flatMap { idsFor(it) } }.toSet()
        for (ride in GameContent.attractions.filter { it.kind != AttractionKind.transport }) {
            assertTrue(ride.id in covered, "${ride.id} has a makeover")
        }
        for (ride in HolidayContent.attractions) assertNull(HolidayMakeovers.rewardFor(ride.id))
    }

    // endregion

    // region Simulation

    private fun parkWithRides(trialID: String? = null): GameState {
        val state = newGameState("Test", trialID = trialID)
        state.ledger.cash = 1_000_000.0
        val x = state.map.entranceCoord.x
        // A spine up from the gate for the rides to stand beside.
        for (y in 1..18) state.map.setTerrain(TerrainType.path, GridCoord(x, y))
        state.place(GameContent.attraction("ride.carousel")!!, GridCoord(x + 1, 3))
        state.place(GameContent.attraction("ride.teacups")!!, GridCoord(x + 1, 7))
        return state
    }

    @Test
    fun snowFallsInSeasonAndNeverOutOfIt() {
        HolidaySeason.override = true
        val state = parkWithRides()
        WeatherSystem.update(state)
        assertTrue(state.snowing, "the first spell is snow")
        assertTrue(state.nextWeatherChangeAt > state.clock.simTime)

        // The weather turns once the spell is over, and keeps turning.
        state.clock.simTime = state.nextWeatherChangeAt + 1
        WeatherSystem.update(state)
        assertFalse(state.snowing, "a clear spell follows")
        state.clock.simTime = state.nextWeatherChangeAt + 1
        WeatherSystem.update(state)
        assertTrue(state.snowing)

        // And it stops the moment the event is over.
        HolidaySeason.override = false
        WeatherSystem.update(state)
        assertFalse(state.snowing, "the snow stops when the event ends")
        assertEquals(0.0, state.nextWeatherChangeAt)
    }

    @Test
    fun aHolidayPartyArrivesBigAndRich() {
        HolidaySeason.override = true
        val state = parkWithRides()
        val demand = DemandSystem()
        // Force one due and certain.
        state.nextTourBusAt = 0.0
        var party: TourBusReport? = null
        var attempt = 0
        while (party == null && attempt < 40) {
            attempt += 1
            state.pendingTourBuses.clear()
            state.guests.clear()
            demand.admitTourBus(state)
            party = state.pendingTourBuses.firstOrNull { it.isHolidayParty }
        }
        assertNotNull(party, "a party arrived")
        assertTrue(party.count >= Balance.holidayPartyMinimumSize, "bigger than an ordinary bus: ${party.count}")
        assertTrue(state.statistics.holidayPartiesTotal >= 1)
    }

    @Test
    fun partyGuestsCarryFiveTimesTheMoney() {
        HolidaySeason.override = true
        val rich = parkWithRides()
        val ordinary = parkWithRides()
        val demand = DemandSystem()
        // Same seed on both, so the only difference is the scale.
        rich.rng = SeededGenerator(77L)
        ordinary.rng = SeededGenerator(77L)
        // Admit a party, then compare typical wallets against an ordinary arrival.
        var partyCash = 0.0
        var partyCount = 0
        var attempt = 0
        while (partyCount == 0 && attempt < 40) {
            attempt += 1
            rich.guests.clear()
            rich.pendingTourBuses.clear()
            demand.admitTourBus(rich)
            if (rich.pendingTourBuses.any { it.isHolidayParty }) {
                partyCount = rich.guests.size
                partyCash = rich.guests.sumOf { it.cash - rich.admissionPrice } / partyCount
            }
        }
        assertTrue(partyCount > 0)

        HolidaySeason.override = false
        demand.seed(30, ordinary)
        val normalCash = ordinary.guests.sumOf { it.cash - ordinary.admissionPrice } / ordinary.guests.size
        assertTrue(partyCash > normalCash * 3.5, "party wallets $partyCash against $normalCash")
    }

    @Test
    fun noPartiesOutOfSeason() {
        HolidaySeason.override = false
        val state = parkWithRides()
        val demand = DemandSystem()
        repeat(30) {
            state.guests.clear()
            state.pendingTourBuses.clear()
            demand.admitTourBus(state)
            assertTrue(state.pendingTourBuses.none { it.isHolidayParty })
        }
        assertEquals(0, state.statistics.holidayPartiesTotal)
    }

    @Test
    fun aHolidayTrialAlwaysGetsItsFirstParty() {
        // Out of season by the calendar, but a holiday trial keeps its own season.
        HolidaySeason.override = null
        HolidaySeason.clock = { CalendarDate(2027, 3, 1) }
        val state = parkWithRides(trialID = "holiday.04")
        assertTrue(HolidaySeason.isActive(state))
        val demand = DemandSystem()
        state.guests.clear()
        demand.admitTourBus(state)
        assertTrue(state.pendingTourBuses.any { it.isHolidayParty })
    }

    @Test
    fun theGuestCapIsThreeHundred() {
        HolidaySeason.override = false
        val state = parkWithRides()
        DemandSystem().seed(400, state)
        assertEquals(300, state.guestCount)
    }

    @Test
    fun theMakeoverBuildsInAndCounts() {
        HolidaySeason.override = true
        val state = parkWithRides()
        val ride = GameContent.attraction("ride.pirateship")!!
        val x = state.map.entranceCoord.x
        val before = state.attractions.size
        assertTrue(state.place(ride, GridCoord(x + 1, 11), makeover = true))
        val placed = state.attractions.last()
        assertEquals(before + 1, state.attractions.size)
        assertEquals(1, placed.upgradeLevel(RideUpgradeKind.holiday))
        // A little more exciting than the plain ride.
        assertEquals(ride.excitement + Balance.holidayMakeoverExcitement, placed.definition!!.excitement)
        assertEquals(1.0, TrialGoal.Makeovers(1).current(state))
    }

    @Test
    fun santaCheersGuestsAndMrsClausFeedsThem() {
        HolidaySeason.override = true
        for (act in listOf(EntertainerAct.santa, EntertainerAct.missus)) {
            val state = parkWithRides()
            val engine = SimulationEngine()
            state.guests.clear()
            DemandSystem().seed(25, state)
            val performer = Staff(name = "Test", role = StaffRole.entertainer, act = act,
                position = state.map.entranceCoord.centre, tile = state.map.entranceCoord)
            state.staff.add(performer)
            for (guest in state.guests) {
                guest.position = performer.position
                guest.tile = performer.tile
                guest.hunger = 60.0
            }
            state.clock.speed = GameSpeed.fast
            repeat(30 * 20) { engine.advance(state, 1.0 / 30) }
            val near = state.guests.filter { it.isActive }
            assertTrue(near.isNotEmpty())
            when (act) {
                EntertainerAct.santa -> assertTrue(near.any { it.cheerUntil > 0.0 }, "Santa's cheer reached someone")
                EntertainerAct.missus -> assertTrue(near.count { it.hunger < 60.0 } > near.size / 2, "Mrs. Claus fed the crowd")
                else -> {}
            }
        }
    }

    @Test
    fun savesKeepTheHolidayFields() {
        HolidaySeason.override = true
        val state = parkWithRides()
        state.snowing = true
        state.statistics.holidayPartiesTotal = 3
        val dir = java.io.File.createTempFile("wonderlot", "").let { it.delete(); it.mkdirs(); it }
        val service = SaveGameService(dir)
        service.save(state, SaveLocation.Slot(2))
        val loaded = service.load(SaveLocation.Slot(2))
        assertTrue(loaded.snowing)
        assertEquals(3, loaded.statistics.holidayPartiesTotal)
        dir.deleteRecursively()
    }

    // endregion
}
