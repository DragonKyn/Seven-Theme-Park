import SwiftUI

/// Owns which screen is on show and the lifetime of the running park.
@MainActor
final class AppRouter: ObservableObject {

    enum Screen {
        case menu
        case game(GameController)
    }

    @Published private(set) var screen: Screen = .menu
    @Published private(set) var slotSummaries: [Int: SaveSlotSummary] = [:]
    @Published private(set) var customMaps: [CustomMap] = []
    @Published var errorMessage: String?

    private let saveService = SaveGameService()
    private let mapStore = CustomMapStore()

    init() {
        refreshSlots()
        customMaps = mapStore.load()
    }

    // MARK: - Maps

    /// Every map a park can be started on: the ones that ship, then the
    /// player's own, newest first.
    var availableMaps: [MapBlueprint] {
        MapCatalogue.all + customMaps.map(\.blueprint)
    }

    func customMap(forBlueprintID id: String) -> CustomMap? {
        customMaps.first { $0.blueprint.id == id }
    }

    func saveCustomMap(_ map: CustomMap) {
        var updated = customMaps.filter { $0.id != map.id }
        updated.insert(map, at: 0)
        persistMaps(updated)
    }

    func deleteCustomMap(id: UUID) {
        persistMaps(customMaps.filter { $0.id != id })
    }

    private func persistMaps(_ maps: [CustomMap]) {
        do {
            try mapStore.save(maps)
            customMaps = maps
        } catch {
            errorMessage = "The map could not be saved: \(error.localizedDescription)"
        }
    }

    func refreshSlots() {
        slotSummaries = saveService.allSummaries()
    }

    var mostRecentSlot: Int? {
        saveService.mostRecentSlot
    }

    func startNewGame(named name: String, mode: GameMode, map: MapBlueprint, in slot: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parkName = trimmed.isEmpty ? "New Park" : trimmed
        let controller = GameController(newParkNamed: parkName,
                                        mode: mode,
                                        layout: map.layout,
                                        slot: slot,
                                        saveService: saveService)
        controller.save()
        refreshSlots()
        screen = .game(controller)
    }

    func loadGame(from slot: Int) {
        do {
            let state = try saveService.load(from: slot)
            screen = .game(GameController(state: state, slot: slot, saveService: saveService))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSave(in slot: Int) {
        saveService.delete(slot: slot)
        refreshSlots()
    }

    /// Saves and returns to the menu.
    func exitToMenu() {
        if case .game(let controller) = screen {
            controller.save()
        }
        refreshSlots()
        screen = .menu
    }

    func saveActiveGame() {
        if case .game(let controller) = screen {
            controller.saveOnBackground()
        }
    }
}
