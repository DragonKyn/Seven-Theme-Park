import Foundation

/// Where a park lives on disk.
///
/// The three slots are for parks the player started. A trial is not one of
/// them: each rung of the ladder keeps its own run in a file of its own, so
/// working through the trials never costs the player a slot.
enum SaveLocation: Equatable {
    case slot(Int)
    case trial(String)

    fileprivate var fileStem: String {
        switch self {
        case .slot(let number): return "slot-\(number)"
        case .trial(let id): return "trial-\(id)"
        }
    }
}

/// Reads and writes parks to the app's Documents directory as JSON.
///
/// Each slot is two files: the park itself and a small summary sidecar, so the
/// main menu can list slots without decoding every guest.
final class SaveGameService {

    static let slotCount = 3

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Locations

    private var savesDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Saves", isDirectory: true)
    }

    private func saveURL(_ location: SaveLocation) -> URL {
        savesDirectory.appendingPathComponent("\(location.fileStem).json")
    }

    private func summaryURL(_ location: SaveLocation) -> URL {
        savesDirectory.appendingPathComponent("\(location.fileStem).summary.json")
    }

    private func ensureDirectory() throws {
        if !fileManager.fileExists(atPath: savesDirectory.path) {
            try fileManager.createDirectory(at: savesDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Writing

    func save(_ state: GameState, to location: SaveLocation) throws {
        try ensureDirectory()

        let save = SaveGame(state: state)
        let data = try encoder.encode(save)
        try data.write(to: saveURL(location), options: .atomic)

        var summary = save.summary
        if case .slot(let number) = location { summary.slot = number }
        let summaryData = try encoder.encode(summary)
        try summaryData.write(to: summaryURL(location), options: .atomic)
    }

    // MARK: - Reading

    func load(from location: SaveLocation) throws -> GameState {
        let url = saveURL(location)
        guard fileManager.fileExists(atPath: url.path) else { throw SaveError.notFound }

        let data = try Data(contentsOf: url)
        let save = try decoder.decode(SaveGame.self, from: data)

        guard save.version <= SaveGame.currentVersion else {
            throw SaveError.unsupportedVersion(save.version)
        }

        return migrate(save)
    }

    /// Hook for save-format upgrades. Adjusting the decoded state here rather
    /// than at every call site.
    private func migrate(_ save: SaveGame) -> GameState {
        let state = save.state
        // Rebuilt rather than trusted, so retuning a decoration's beauty in a
        // later build takes effect on parks that were saved before the change.
        state.refreshBeauty()
        return state
    }

    func summary(for location: SaveLocation) -> SaveSlotSummary? {
        let url = summaryURL(location)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(SaveSlotSummary.self, from: data)
    }

    func allSummaries() -> [Int: SaveSlotSummary] {
        var result: [Int: SaveSlotSummary] = [:]
        for slot in 0..<Self.slotCount {
            if let summary = summary(for: .slot(slot)) {
                result[slot] = summary
            }
        }
        return result
    }

    /// The run in progress for each trial that has one, by trial id.
    func trialSummaries() -> [String: SaveSlotSummary] {
        var result: [String: SaveSlotSummary] = [:]
        for trial in TrialContent.all {
            if let summary = summary(for: .trial(trial.id)) {
                result[trial.id] = summary
            }
        }
        return result
    }

    func hasSave(at location: SaveLocation) -> Bool {
        fileManager.fileExists(atPath: saveURL(location).path)
    }

    /// Moves any trial that was started in a save slot, by the build that put
    /// trials in slots, out to the trial's own file, and frees the slot.
    /// A run already in the trial's own file is newer and wins.
    func moveTrialsOutOfSlots() {
        for (slot, summary) in allSummaries() where summary.mode == .trial {
            guard let state = try? load(from: .slot(slot)),
                  let trialID = state.trialID else { continue }
            if !hasSave(at: .trial(trialID)) {
                guard (try? save(state, to: .trial(trialID))) != nil else { continue }
            }
            delete(.slot(slot))
        }
    }

    var mostRecentSlot: Int? {
        allSummaries()
            .max(by: { $0.value.savedAt < $1.value.savedAt })?
            .key
    }

    // MARK: - Deleting

    func delete(_ location: SaveLocation) {
        try? fileManager.removeItem(at: saveURL(location))
        try? fileManager.removeItem(at: summaryURL(location))
    }
}
