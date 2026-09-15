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
    /// Trial id to the earliest day it was beaten on.
    @Published private(set) var completedTrials: [String: Int] = [:]
    /// Trial id to the run the player has on the go for it, if any.
    @Published private(set) var trialRuns: [String: SaveSlotSummary] = [:]
    /// Set when a finished trial sends the player back to the ladder, so the
    /// menu opens straight onto it.
    @Published var opensLadderOnMenu = false
    @Published var errorMessage: String?

    private let saveService = SaveGameService()
    private let mapStore = CustomMapStore()

    init() {
        // Before anything is listed, so a slot a trial was occupying shows as
        // free from the first time the menu appears.
        saveService.moveTrialsOutOfSlots()
        refreshSlots()
        customMaps = mapStore.load()
        refreshTrials()
    }

    // MARK: - Trials

    func refreshTrials() {
        completedTrials = TrialProgressStore().completed
        trialRuns = saveService.trialSummaries()
    }

    func isTrialUnlocked(_ trial: TrialDefinition) -> Bool {
        TrialProgressStore().isUnlocked(trial)
    }

    /// Starts a trial from day one, replacing any run already on the go.
    func startTrial(_ trial: TrialDefinition) {
        let controller = GameController(newParkNamed: trial.title,
                                        mode: .trial,
                                        layout: trial.map.layout,
                                        startingCash: trial.startingCash,
                                        trialID: trial.id,
                                        location: .trial(trial.id),
                                        saveService: saveService)
        if let cap = trial.maxAdmission {
            controller.setAdmissionPrice(min(cap, Balance.defaultAdmissionPrice))
        }
        controller.save()
        refreshTrials()
        screen = .game(controller)
    }

    /// Picks a trial up where the player left it.
    func resumeTrial(_ trial: TrialDefinition) {
        do {
            let state = try saveService.load(from: .trial(trial.id))
            screen = .game(GameController(state: state,
                                          location: .trial(trial.id),
                                          saveService: saveService))
        } catch {
            errorMessage = error.localizedDescription
        }
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
                                        location: .slot(slot),
                                        saveService: saveService)
        controller.save()
        refreshSlots()
        screen = .game(controller)
    }

    func loadGame(from slot: Int) {
        do {
            let state = try saveService.load(from: .slot(slot))
            screen = .game(GameController(state: state,
                                          location: .slot(slot),
                                          saveService: saveService))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSave(in slot: Int) {
        saveService.delete(.slot(slot))
        refreshSlots()
    }

    /// Saves and returns to the menu.
    func exitToMenu() {
        if case .game(let controller) = screen {
            controller.save()
        }
        refreshSlots()
        refreshTrials()
        screen = .menu
    }

    func saveActiveGame() {
        if case .game(let controller) = screen {
            controller.saveOnBackground()
        }
    }
}
