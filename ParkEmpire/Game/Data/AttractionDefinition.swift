import Foundation

/// Static, immutable configuration for one kind of ride.
///
/// Adding a ride should mean adding one of these to `GameContent` — the
/// simulation systems never branch on a specific attraction id.
/// How a ride is filed in the build menu.
///
/// The list of rides only gets longer, and "everything with a queue" stops
/// being a useful heading somewhere around a dozen. Grouping is presentation
/// only: nothing in the simulation reads it.
enum RideGroup: String, Codable, CaseIterable, Identifiable {
    case gentle
    case family
    case thrill
    case water

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gentle: return "Gentle"
        case .family: return "Family"
        case .thrill: return "Thrill"
        case .water: return "Water"
        }
    }

    var symbolName: String {
        switch self {
        case .gentle: return "leaf.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .thrill: return "bolt.fill"
        case .water: return "drop.fill"
        }
    }
}

/// What a boardable building actually does with the guests it takes on.
enum AttractionKind: String, Codable {
    /// Guests get on, enjoy themselves, and get off where they started.
    case ride
    /// Guests get on and are set down at another station on the same railway.
    case transport
}

struct AttractionDefinition: BuildableDefinition, Codable, Identifiable {
    let id: String
    let displayName: String
    let summary: String
    let purchasePrice: Double
    /// Guests carried per cycle.
    let capacity: Int
    /// Sim-seconds the ride runs for once loaded.
    let rideDuration: Double
    /// Sim-seconds spent loading and unloading between cycles.
    let loadDuration: Double
    /// 0-100. Drives how well the ride matches a guest's thrill preference.
    let excitement: Double
    /// 0-100. Nausea inflicted on riders.
    let nausea: Double
    /// Condition percentage lost per sim-second of operation.
    let maintenanceRate: Double
    /// Charged each time the ride completes a cycle.
    let operatingCostPerCycle: Double
    let footprint: GridSize
    let unlockLevel: Int
    /// How the placed building is drawn.
    let appearance: BuildingAppearance
    /// What the building is for. Declared last and defaulted, so every ride in
    /// the catalogue reads exactly as it did before transport existed.
    var kind: AttractionKind = .ride
    /// Which shelf of the build menu it sits on.
    var group: RideGroup = .family
    /// Whether it has to sit against water to work.
    var needsWater = false

    var category: BuildCategory {
        kind == .transport ? .transport : .attraction
    }

    /// A station with no railway against it has nowhere to send anybody.
    var requiresTrackAccess: Bool { kind == .transport }

    var requiresWaterAccess: Bool { needsWater }

    /// The same ride with its purchased upgrades folded in. Returning a
    /// definition rather than a separate stats type means every system that
    /// already reads a definition picks up upgrades without being told.
    func applying(_ upgrades: [String: Int]) -> AttractionDefinition {
        guard !upgrades.isEmpty else { return self }
        func level(_ kind: RideUpgradeKind) -> Int { upgrades[kind.rawValue] ?? 0 }

        return AttractionDefinition(
            id: id,
            displayName: displayName,
            summary: summary,
            purchasePrice: purchasePrice,
            capacity: Int((Double(capacity) * UpgradeContent.capacityFactor(level: level(.capacity))).rounded()),
            rideDuration: rideDuration,
            loadDuration: loadDuration * UpgradeContent.loadingFactor(level: level(.loading)),
            excitement: SimMath.clamp(excitement + UpgradeContent.themingExcitement(level: level(.theming))),
            nausea: nausea,
            maintenanceRate: maintenanceRate * UpgradeContent.wearFactor(level: level(.reliability)),
            operatingCostPerCycle: operatingCostPerCycle,
            footprint: footprint,
            unlockLevel: unlockLevel,
            appearance: appearance,
            kind: kind,
            group: group,
            needsWater: needsWater
        )
    }

    var previewAppearance: BuildingAppearance? { appearance }

    /// Coarse label used in the build menu and ride inspector.
    var thrillLabel: String {
        switch excitement {
        case ..<25: return "Gentle"
        case ..<50: return "Family"
        case ..<75: return "Thrilling"
        default: return "Extreme"
        }
    }
}
