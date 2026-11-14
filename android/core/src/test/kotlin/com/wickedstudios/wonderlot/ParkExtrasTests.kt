package com.wickedstudios.wonderlot

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/** The cash machine and the fences. */
class ParkExtrasTests {
    private val fenceIDs = listOf("scenery.fence.picket", "scenery.fence.rustic", "scenery.fence.iron", "scenery.fence.stone")

    private fun park(): GameState {
        val state = newGameState("Test")
        state.ledger.cash = 1_000_000.0
        val x = state.map.entranceCoord.x
        for (y in 1..18) state.map.setTerrain(TerrainType.path, GridCoord(x, y))
        return state
    }

    private fun grassBeside(state: GameState, row: Int): GridCoord = GridCoord(state.map.entranceCoord.x + 2, row)

    // region Fences

    @Test
    fun fencesAreInTheCatalogueAndBlockWalking() {
        for (id in fenceIDs + "scenery.xmas.canefence") {
            val definition = assertNotNull(GameContent.scenery(id), id)
            assertTrue(definition.isFence, "$id is a fence")
            assertFalse(definition.leavesWalkwayOpen, "$id blocks the walkway")
        }
    }

    @Test
    fun aFenceOnAWalkwayStopsGuestsAndComesDownAgain() {
        val state = park()
        val coord = GridCoord(state.map.entranceCoord.x, 6)
        assertTrue(state.map.isWalkable(coord))

        for (id in fenceIDs) {
            val fence = GameContent.scenery(id)!!
            assertTrue(state.place(fence, coord), "$id placed on the walkway")
            assertFalse(state.map.isWalkable(coord), "$id blocks the walkway")
            assertTrue(state.demolish(coord), "$id taken down")
            assertTrue(state.map.isWalkable(coord), "$id leaves the walkway open again")
        }
    }

    @Test
    fun aFenceGoesOnGrassWaterAndBridgesButNotOnBlockedGround() {
        val state = park()
        val fence = GameContent.scenery("scenery.fence.picket")!!

        val grass = grassBeside(state, 5)
        assertTrue(state.placementCheck(fence, grass).isValid, "grass")

        val water = grassBeside(state, 8)
        state.map.setTerrain(TerrainType.water, water)
        assertTrue(state.placementCheck(fence, water).isValid, "water")

        val bridge = grassBeside(state, 9)
        state.map.setTerrain(TerrainType.bridge, bridge)
        assertTrue(state.placementCheck(fence, bridge).isValid, "bridge")

        for (blocked in listOf(TerrainType.rock, TerrainType.forest, TerrainType.track, TerrainType.coasterTrack)) {
            val coord = grassBeside(state, 11)
            state.map.setTerrain(blocked, coord)
            assertFalse(state.placementCheck(fence, coord).isValid, "$blocked is blocked")
        }

        assertFalse(state.placementCheck(fence, state.map.entranceCoord).isValid, "the entrance")

        // Something already standing there blocks it too.
        assertTrue(state.place(GameContent.scenery("scenery.hedge")!!, grass))
        assertFalse(state.placementCheck(fence, grass).isValid, "occupied")
    }

    @Test
    fun aFenceMovesAGuestStandingOnItsTile() {
        val state = park()
        val coord = GridCoord(state.map.entranceCoord.x, 6)
        val guest = Guest(name = "Test", position = coord.centre, tile = coord, activity = GuestActivity.Exploring)
        state.guests.add(guest)
        assertTrue(state.place(GameContent.scenery("scenery.fence.iron")!!, coord))
        assertTrue(state.map.isWalkable(guest.tile), "the guest is back on a walkway, not inside the fence: ${guest.tile}")
        assertTrue(guest.tile != coord)
    }

    // endregion

    // region Cash machine

    private fun withMachine(): Pair<GameState, Facility> {
        val state = park()
        val x = state.map.entranceCoord.x
        assertTrue(state.place(GameContent.facility("facility.atm")!!, GridCoord(x + 1, 4)), "machine built")
        return state to state.facilities.single { it.definition?.kind == FacilityKind.atm }
    }

    /** Puts a guest in the queue for the machine and runs the service until they walk away. */
    private fun useMachine(state: GameState, machine: Facility, guest: Guest) {
        state.guests.add(guest)
        guest.activity = GuestActivity.Queueing(ParkTarget.Shop(machine.id))
        machine.queue.add(guest.id)
        val system = FacilitySystem()
        repeat(60) {
            system.update(state, 0.25)
            state.clock.simTime += 0.25
        }
    }

    private fun newGuest(state: GameState, startingCash: Double, cash: Double) =
        Guest(name = "Test", cash = cash, startingCash = startingCash, position = state.map.entranceCoord.centre,
            tile = state.map.entranceCoord)

    @Test
    fun theMachineIsAFacilityThatTakesUpgrades() {
        val definition = assertNotNull(GameContent.facility("facility.atm"))
        assertTrue(definition.acceptsUpgrades)
        assertEquals(FacilityKind.atm, definition.kind)
        assertEquals(BuildCategory.facility, definition.category)
        // It is offered the withdrawal limit and nothing else; shops are never offered the limit.
        assertEquals(listOf(ShopUpgradeKind.withdrawal), ShopUpgradeKind.entries.filter { it.offeredFor(FacilityKind.atm) })
        assertFalse(ShopUpgradeKind.withdrawal.offeredFor(FacilityKind.food))
        assertEquals(listOf(0.25, 0.30, 0.50), CashMachine.limits)
        assertEquals(2, ShopUpgradeKind.withdrawal.maxLevel)
    }

    @Test
    fun aGuestWithdrawsAQuarterOfTheirEntryMoneyOnce() {
        val (state, machine) = withMachine()
        val guest = newGuest(state, startingCash = 200.0, cash = 20.0)
        useMachine(state, machine, guest)

        assertEquals(70.0, guest.cash, 0.001, "a quarter of 200 is 50, on top of the 20 left")
        assertTrue(guest.usedCashMachine)
        assertEquals(50.0, machine.totalDispensed, 0.001)
        assertEquals(1, machine.totalCustomers)

        // Only once: a second go changes nothing.
        useMachine(state, machine, guest)
        assertEquals(70.0, guest.cash, 0.001)
        assertEquals(50.0, machine.totalDispensed, 0.001)
    }

    @Test
    fun theLimitRisesToThirtyThenFiftyPerCent() {
        for ((level, expected) in listOf(0 to 50.0, 1 to 60.0, 2 to 100.0)) {
            val (state, machine) = withMachine()
            if (level > 0) machine.upgrades[ShopUpgradeKind.withdrawal.name] = level
            val guest = newGuest(state, startingCash = 200.0, cash = 0.0)
            useMachine(state, machine, guest)
            assertEquals(expected, guest.cash, 0.001, "level $level")
        }
    }

    @Test
    fun theWithdrawalUpgradeIsBoughtThroughTheNormalRoute() {
        val (state, machine) = withMachine()
        val detail = FacilityDetail(machine)
        assertEquals(1, detail.upgrades.size)
        assertEquals(ShopUpgradeKind.withdrawal, detail.upgrades.single().kind)
        assertTrue(detail.isCashMachine)
        assertEquals(0.25, detail.withdrawalLimit, 0.0001)
        assertNotNull(detail.upgrades.single().cost)
        assertTrue(state.ledger.cash > 0)
    }

    @Test
    fun guestsWantTheMachineOnlyOnceTheyHaveSpentASizeablePartOfTheirMoney() {
        val (state, machine) = withMachine()
        val definition = machine.definition!!
        val flush = newGuest(state, startingCash = 100.0, cash = 90.0)
        val spent = newGuest(state, startingCash = 100.0, cash = 10.0)
        val used = newGuest(state, startingCash = 100.0, cash = 10.0).also { it.usedCashMachine = true }

        fun wants(guest: Guest) = FacilityAppeal.evaluate(machine, definition, guest, true, 3) is FacilityAppeal.Verdict.Wants
        assertFalse(wants(flush), "a guest with most of their money left has no reason to")
        assertTrue(wants(spent), "a guest who has spent most of it does")
        assertFalse(wants(used), "and only once")
    }

    @Test
    fun theMachineIsUsedInARealParkAndGuestsGoOnSpending() {
        val state = DemoPark.makeState()
        val x = state.map.entranceCoord.x
        var built = false
        search@ for (y in 1..30) for (dx in -6..6) {
            if (state.place(GameContent.facility("facility.atm")!!, GridCoord(x + dx, y))) { built = true; break@search }
        }
        assertTrue(built, "found room for a machine")

        val engine = SimulationEngine()
        state.clock.speed = GameSpeed.fast
        repeat((Balance.dayLength * 2 / 2 * 30).toInt()) { engine.advance(state, 1.0 / 30) }

        val machine = state.facilities.single { it.definition?.kind == FacilityKind.atm }
        println("withdrawals=${machine.totalCustomers} dispensed=${machine.totalDispensed}")
        assertTrue(machine.totalCustomers > 0, "guests used the machine")
        assertTrue(machine.totalDispensed > 0)
        assertTrue(state.guests.none { it.usedCashMachine && it.cash < 0 })
    }

    // endregion
}
