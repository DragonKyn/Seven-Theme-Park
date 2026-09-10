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
    @Published var errorMessage: String?

    private let saveService = SaveGameService()

    init() {
        refreshSlots()
    }

    func refreshSlots() {
        slotSummaries = saveService.allSummaries()
    }

    var mostRecentSlot: Int? {
        saveService.mostRecentSlot
    }

    func startNewGame(named name: String, mode: GameMode, in slot: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parkName = trimmed.isEmpty ? "New Park" : trimmed
        let controller = GameController(newParkNamed: parkName,
                                        mode: mode,
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
