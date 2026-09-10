import Foundation

/// The things a player can improve about a ride they already own.
///
/// There is one set of upgrades for every ride rather than a bespoke list per
/// attraction, so adding a ride still means adding one entry to `GameContent`
/// and nothing else. What differs between rides is the price, which is a share
/// of what the ride cost in the first place.
enum RideUpgradeKind: String, Codable, CaseIterable, Identifiable {
    case capacity
    case reliability
    case theming
    case loading

    var id: String { rawValue }
}

struct RideUpgradeDefinition: Identifiable {
    let kind: RideUpgradeKind
    let displayName: String
    let summary: String
    let symbolName: String
    let maxLevel: Int
    /// Price of the first level as a share of the ride's purchase price.
    /// Later levels cost proportionally more.
    let costShare: Double

    var id: String { kind.rawValue }

    /// What the next level costs on a given ride. Levels get dearer, so
    /// spreading money across several rides beats maxing out one.
    func cost(forLevel level: Int, ridePrice: Double) -> Double {
        (ridePrice * costShare * Double(level) * 1.15).rounded()
    }
}

/// Training makes an employee faster on their feet and quicker at the job,
/// and puts their wage up to match. One track, three levels: the decision is
/// how many people to train, not which of five skills to pick.
struct StaffTrainingDefinition {
    let maxLevel: Int
    /// Share of the hiring cost charged for the first level.
    let costShare: Double
    let walkSpeedPerLevel: Double
    let workRatePerLevel: Double
    let wagePerLevel: Double

    func cost(forLevel level: Int, hiringCost: Double) -> Double {
        (hiringCost * costShare * Double(level) * 1.2).rounded()
    }

    func title(forLevel level: Int) -> String {
        switch level {
        case 0: return "Untrained"
        case 1: return "Trained"
        case 2: return "Experienced"
        default: return "Veteran"
        }
    }
}

enum UpgradeContent {

    static let rideUpgrades: [RideUpgradeDefinition] = [
        RideUpgradeDefinition(
            kind: .capacity,
            displayName: "Extra Cars",
            summary: "Carries more guests per cycle, which is the only real cure for a long queue.",
            symbolName: "person.3.fill",
            maxLevel: 3,
            costShare: 0.30
        ),
        RideUpgradeDefinition(
            kind: .loading,
            displayName: "Faster Loading",
            summary: "Shorter turnaround between cycles. Cheap, and it compounds all day.",
            symbolName: "timer",
            maxLevel: 3,
            costShare: 0.20
        ),
        RideUpgradeDefinition(
            kind: .reliability,
            displayName: "Reinforced Parts",
            summary: "Wears out far more slowly, so a mechanic goes further.",
            symbolName: "wrench.and.screwdriver.fill",
            maxLevel: 3,
            costShare: 0.26
        ),
        RideUpgradeDefinition(
            kind: .theming,
            displayName: "Theming",
            summary: "More exciting to ride, and it makes the ground around it pretty.",
            symbolName: "sparkles",
            maxLevel: 3,
            costShare: 0.34
        )
    ]

    static let staffTraining = StaffTrainingDefinition(
        maxLevel: 3,
        costShare: 0.55,
        walkSpeedPerLevel: 0.16,
        workRatePerLevel: 0.32,
        wagePerLevel: 0.24
    )

    private static let byKind: [RideUpgradeKind: RideUpgradeDefinition] =
        Dictionary(uniqueKeysWithValues: rideUpgrades.map { ($0.kind, $0) })

    static func rideUpgrade(_ kind: RideUpgradeKind) -> RideUpgradeDefinition? {
        byKind[kind]
    }

    // MARK: - Effects

    /// Capacity multiplier at a given level.
    static func capacityFactor(level: Int) -> Double { 1 + 0.30 * Double(level) }
    /// Load duration multiplier. Floors well above zero so a maxed ride still
    /// takes a moment to fill.
    static func loadingFactor(level: Int) -> Double { max(0.35, 1 - 0.22 * Double(level)) }
    /// Wear multiplier.
    static func wearFactor(level: Int) -> Double { max(0.25, 1 - 0.28 * Double(level)) }
    /// Excitement added by theming.
    static func themingExcitement(level: Int) -> Double { 7 * Double(level) }
    /// Prettiness a themed ride lends the tiles around it, on the same 0-100
    /// scale scenery uses.
    static func themingBeauty(level: Int) -> Double { 22 * Double(level) }
    static let themingBeautyRadius = 2
}
