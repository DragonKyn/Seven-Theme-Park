import Foundation

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

    private func saveURL(slot: Int) -> URL {
        savesDirectory.appendingPathComponent("slot-\(slot).json")
    }

    private func summaryURL(slot: Int) -> URL {
        savesDirectory.appendingPathComponent("slot-\(slot).summary.json")
    }

    private func ensureDirectory() throws {
        if !fileManager.fileExists(atPath: savesDirectory.path) {
            try fileManager.createDirectory(at: savesDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Writing

    func save(_ state: GameState, to slot: Int) throws {
        try ensureDirectory()

        let save = SaveGame(state: state)
        let data = try encoder.encode(save)
        try data.write(to: saveURL(slot: slot), options: .atomic)

        var summary = save.summary
        summary.slot = slot
        let summaryData = try encoder.encode(summary)
        try summaryData.write(to: summaryURL(slot: slot), options: .atomic)
    }

    // MARK: - Reading

    func load(from slot: Int) throws -> GameState {
        let url = saveURL(slot: slot)
        guard fileManager.fileExists(atPath: url.path) else { throw SaveError.notFound }

        let data = try Data(contentsOf: url)
        let save = try decoder.decode(SaveGame.self, from: data)

        guard save.version <= SaveGame.currentVersion else {
            throw SaveError.unsupportedVersion(save.version)
        }

        return migrate(save)
    }

    /// Hook for save-format upgrades. Version 1 needs no work; later versions
    /// adjust the decoded state here rather than at every call site.
    private func migrate(_ save: SaveGame) -> GameState {
        save.state
    }

    func summary(for slot: Int) -> SaveSlotSummary? {
        let url = summaryURL(slot: slot)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(SaveSlotSummary.self, from: data)
    }

    func allSummaries() -> [Int: SaveSlotSummary] {
        var result: [Int: SaveSlotSummary] = [:]
        for slot in 0..<Self.slotCount {
            if let summary = summary(for: slot) {
                result[slot] = summary
            }
        }
        return result
    }

    func hasSave(in slot: Int) -> Bool {
        fileManager.fileExists(atPath: saveURL(slot: slot).path)
    }

    var mostRecentSlot: Int? {
        allSummaries()
            .max(by: { $0.value.savedAt < $1.value.savedAt })?
            .key
    }

    // MARK: - Deleting

    func delete(slot: Int) {
        try? fileManager.removeItem(at: saveURL(slot: slot))
        try? fileManager.removeItem(at: summaryURL(slot: slot))
    }
}
