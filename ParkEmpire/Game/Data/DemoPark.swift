import Foundation

/// Builds the small park that runs behind the main menu.
///
/// It is an ordinary `GameState` driven by the ordinary simulation, so the
/// menu shows the real game rather than an illustration of it. Nothing here
/// is ever saved: the controller that owns it runs in demo mode.
enum DemoPark {

    /// A laid-out park with a crowd already in it.
    static func makeState() -> GameState {
        let state = GameState(parkName: AppInfo.gameName, seed: 20_260_909)

        // Placement refuses anything the park cannot afford, and the demo
        // layout costs close to the starting balance. Fund it generously so a
        // price change never silently drops the last few pieces, then put the
        // balance back to normal once everything is standing.
        state.ledger.cash = 1_000_000

        layOutPaths(state)
        placeBuildings(state)
        placeScenery(state)

        // Free entry and a good reputation, so the park fills quickly and
        // stays full while somebody sits on the menu.
        state.admissionPrice = 0
        state.parkRating = 82
        state.clock.speed = .normal

        warmUp(state)
        return state
    }

    // MARK: - Layout

    private static func layOutPaths(_ state: GameState) {
        let entrance = state.map.entranceCoord
        let spine = entrance.x

        // A spine up the middle from the entrance, with two side streets.
        for y in 1...18 {
            state.map.setTerrain(.path, at: GridCoord(spine, y))
        }
        for x in (spine - 7)...(spine + 7) {
            state.map.setTerrain(.path, at: GridCoord(x, 7))
            state.map.setTerrain(.path, at: GridCoord(x, 14))
        }
    }

    private static func placeBuildings(_ state: GameState) {
        let spine = state.map.entranceCoord.x

        place(state, "ride.carousel", at: GridCoord(spine - 5, 8))
        place(state, "ride.pirateship", at: GridCoord(spine + 2, 8))
        place(state, "ride.droptower", at: GridCoord(spine - 5, 15))
        place(state, "ride.minicoaster", at: GridCoord(spine + 1, 15))

        place(state, "shop.burger", at: GridCoord(spine - 3, 5))
        place(state, "shop.drinks", at: GridCoord(spine + 2, 5))
        place(state, "shop.icecream", at: GridCoord(spine - 3, 12))
        place(state, "facility.bathroom", at: GridCoord(spine + 2, 12))

        place(state, "facility.bench", at: GridCoord(spine - 1, 4))
        place(state, "facility.bench", at: GridCoord(spine + 1, 4))
        place(state, "facility.bin", at: GridCoord(spine - 1, 6))
        place(state, "facility.bin", at: GridCoord(spine + 1, 13))
    }

    private static func placeScenery(_ state: GameState) {
        let spine = state.map.entranceCoord.x

        place(state, "scenery.fountain", at: GridCoord(spine - 1, 9))

        for y in [2, 4, 6, 10, 12, 16, 18] {
            place(state, "scenery.tree", at: GridCoord(spine - 2, y))
            place(state, "scenery.tree", at: GridCoord(spine + 2, y))
        }
        for x in [spine - 6, spine + 5] {
            place(state, "scenery.conifer", at: GridCoord(x, 6))
            place(state, "scenery.conifer", at: GridCoord(x, 13))
        }
        place(state, "scenery.flowerbed", at: GridCoord(spine - 1, 2))
        place(state, "scenery.flowerbed", at: GridCoord(spine + 1, 2))
        place(state, "scenery.statue", at: GridCoord(spine + 1, 11))
        place(state, "scenery.lamp", at: GridCoord(spine - 1, 16))
        place(state, "scenery.lamp", at: GridCoord(spine + 1, 16))
    }

    /// Places by definition id, ignoring anything that will not fit. The demo
    /// layout is hand-written, so a piece that collides is a layout mistake
    /// rather than something to report at runtime.
    private static func place(_ state: GameState, _ definitionID: String, at coord: GridCoord) {
        guard let definition = GameContent.allBuildables.first(where: { $0.id == definitionID })
        else { return }
        state.place(definition, at: coord)
    }

    // MARK: - Warm-up

    /// Runs the simulation forward before the menu appears, so the park opens
    /// with a crowd in it rather than filling up while the player watches.
    /// Fills the park before the menu appears, so it opens with a crowd in it.
    ///
    /// Guests are seeded directly rather than waited for: at the real arrival
    /// rate a crowd this size takes ten simulated minutes, and simulating that
    /// on the main thread would stall the menu for seconds. A short run
    /// afterwards is enough to spread everyone out from the gate.
    private static func warmUp(_ state: GameState) {
        DemandSystem().seed(count: 45, state: state)

        let engine = SimulationEngine()
        // One tick per call: the engine caps how many ticks a single call may
        // run and drops the remainder, so asking for the whole span at once
        // would quietly simulate a fraction of it.
        let ticks = Int(25.0 / Balance.tickDuration)
        for _ in 0..<ticks {
            engine.advance(state: state, realDelta: Balance.tickDuration)
        }

        // Money is meaningless here, and a demo park that visibly goes broke
        // would be a strange first impression.
        state.ledger.cash = Balance.startingCash
    }
}
