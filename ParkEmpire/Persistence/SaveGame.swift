import Foundation

/// Lightweight description of a save, written alongside the save itself so the
/// menu can list slots without decoding a whole park.
struct SaveSlotSummary: Codable, Identifiable, Equatable {
    var slot: Int
    var parkName: String
    var savedAt: Date
    var cash: Double
    var guestCount: Int
    var parkRating: Double
    var day: Int

    var id: Int { slot }
}

/// Versioned envelope around `GameState`.
///
/// `version` is checked on load: unknown future versions are refused rather
/// than decoded into something wrong, and older versions get a migration hook.
struct SaveGame: Codable {
    /// 1: Phase 1 foundation.
    /// 2: Phase 2 adds litter, staff and ride maintenance. Every type that
    ///    gained fields decodes leniently, so a version 1 save still loads.
    /// 3: Phase 3 adds scenery and per-tile beauty. Older saves load with an
    ///    empty scenery list, and the beauty field is rebuilt from it on load.
    static let currentVersion = 4

    var version: Int
    var savedAt: Date
    var state: GameState

    init(state: GameState) {
        self.version = SaveGame.currentVersion
        self.savedAt = Date()
        self.state = state
    }

    var summary: SaveSlotSummary {
        SaveSlotSummary(slot: 0,
                        parkName: state.parkName,
                        savedAt: savedAt,
                        cash: state.ledger.cash,
                        guestCount: state.guestCount,
                        parkRating: state.parkRating,
                        day: state.clock.day)
    }
}

enum SaveError: LocalizedError {
    case unsupportedVersion(Int)
    case notFound

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "This park was saved by a newer version of the game (format \(version))."
        case .notFound:
            return "That save slot is empty."
        }
    }
}
