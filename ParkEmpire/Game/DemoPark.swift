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

    /// Every coordinate here is a gap between the paths and the buildings
    /// placed above. Scenery does not need path access, but it does need bare
    /// grass, so these are chosen rather than generated.
    private static func placeScenery(_ state: GameState) {
        let spine = state.map.entranceCoord.x

        // Centrepiece, beside the main walkway where everyone passes it.
        place(state, "scenery.fountain", at: GridCoord(spine - 2, 10))
        place(state, "scenery.statue", at: GridCoord(spine + 1, 11))

        for coord in [GridCoord(spine - 2, 1), GridCoord(spine + 2, 1),
                      GridCoord(spine - 2, 3), GridCoord(spine + 2, 3),
                      GridCoord(spine - 6, 9), GridCoord(spine + 6, 9),
                      GridCoord(spine - 6, 11), GridCoord(spine + 6, 11),
                      GridCoord(spine - 2, 8), GridCoord(spine + 1, 8),
                      GridCoord(spine - 2, 17), GridCoord(spine - 6, 17)] {
            place(state, "scenery.tree", at: coord)
        }

        for coord in [GridCoord(spine - 6, 6), GridCoord(spine + 6, 6),
                      GridCoord(spine - 6, 13), GridCoord(spine + 6, 13)] {
            place(state, "scenery.conifer", at: coord)
        }

        for coord in [GridCoord(spine - 1, 1), GridCoord(spine + 1, 1),
                      GridCoord(spine - 1, 3), GridCoord(spine + 1, 3)] {
            place(state, "scenery.flowerbed", at: coord)
        }

        for coord in [GridCoord(spine - 1, 13), GridCoord(spine + 1, 12),
                      GridCoord(spine - 1, 16), GridCoord(spine - 1, 18)] {
            place(state, "scenery.lamp", at: coord)
        }

        place(state, "scenery.topiary", at: GridCoord(spine - 1, 5))
        place(state, "scenery.topiary", at: GridCoord(spine + 1, 5))
    }

    /// Places by definition id. The layout is hand-written against a known
    /// empty map, so anything that fails to fit is a mistake in this file; the
    /// assertion catches that in development and compiles out of the shipping
    /// build, where a missing tree is not worth a crash.
    private static func place(_ state: GameState, _ definitionID: String, at coord: GridCoord) {
        guard let definition = GameContent.allBuildables.first(where: { $0.id == definitionID })
        else {
            assertionFailure("Demo park refers to unknown definition \(definitionID)")
            return
        }
        let placed = state.place(definition, at: coord)
        assert(placed, "Demo park could not place \(definitionID) at \(coord.x),\(coord.y)")
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
