import Foundation

/// Which side of the park an improvement belongs to.
///
/// Three branches so that fifteen points cannot buy everything: with
/// twenty-two ranks on offer, finishing the ladder still leaves choices on
/// the table, and two players who beat every trial can end up running very
/// different parks.
enum PerkBranch: String, CaseIterable, Identifiable, Codable {
    case guests
    case money
    case operations

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .guests: return "Guests"
        case .money: return "Money"
        case .operations: return "Operations"
        }
    }

    var summary: String {
        switch self {
        case .guests: return "More people, in a better mood, with more to spend."
        case .money: return "Everything the park buys costs less."
        case .operations: return "Rides that last, and a park people speak well of."
        }
    }

    var symbolName: String {
        switch self {
        case .guests: return "person.2.fill"
        case .money: return "banknote.fill"
        case .operations: return "wrench.and.screwdriver.fill"
        }
    }
}

/// One permanent improvement, bought with the points trials pay out.
struct PerkDefinition: Identifiable {
    let id: String
    let branch: PerkBranch
    let displayName: String
    let symbolName: String
    /// How many points can be put into it.
    let maxRank: Int
    /// What one rank is worth, in whatever unit the perk deals in.
    let perRank: Double
    /// Points that must already be spent in this branch before it opens.
    /// Keeps the strong ones at the end of a road rather than on day one.
    let requires: Int
    /// Written with the value of a single rank in it.
    let detail: String

    func summary(atRank rank: Int) -> String {
        detail.replacingOccurrences(of: "{v}", with: format(perRank))
            + (rank > 0 ? "  Now: \(format(perRank * Double(rank)))." : "")
    }

    private func format(_ value: Double) -> String {
        value < 1
            ? "\(Int((value * 100).rounded()))%"
            : "\(Int(value.rounded()))"
    }
}

/// The tree itself.
enum PerkContent {

    static let all: [PerkDefinition] = [

        // MARK: Guests

        PerkDefinition(
            id: "perk.arrivals",
            branch: .guests,
            displayName: "Warm Welcome",
            symbolName: "hand.wave.fill",
            maxRank: 3,
            perRank: 0.04,
            requires: 0,
            detail: "{v} more arrivals at the gate, in every park you build."),

        PerkDefinition(
            id: "perk.mood",
            branch: .guests,
            displayName: "Good First Impression",
            symbolName: "face.smiling.inverse",
            maxRank: 2,
            perRank: 5,
            requires: 2,
            detail: "Guests walk in {v} points happier than they otherwise would."),

        PerkDefinition(
            id: "perk.spending",
            branch: .guests,
            displayName: "Deep Pockets",
            symbolName: "wallet.bifold.fill",
            maxRank: 3,
            perRank: 0.07,
            requires: 3,
            detail: "Guests arrive with {v} more money to spend."),

        // MARK: Money

        PerkDefinition(
            id: "perk.building",
            branch: .money,
            displayName: "Shrewd Buyer",
            symbolName: "hammer.fill",
            maxRank: 3,
            perRank: 0.05,
            requires: 0,
            detail: "{v} off everything you build."),

        PerkDefinition(
            id: "perk.wages",
            branch: .money,
            displayName: "Lean Payroll",
            symbolName: "person.badge.clock.fill",
            maxRank: 2,
            perRank: 0.08,
            requires: 2,
            detail: "{v} off the wage bill, without anybody working less."),

        PerkDefinition(
            id: "perk.stock",
            branch: .money,
            displayName: "Bulk Supplier",
            symbolName: "shippingbox.fill",
            maxRank: 2,
            perRank: 0.12,
            requires: 3,
            detail: "{v} off what every sale costs the park to stock."),

        // MARK: Operations

        PerkDefinition(
            id: "perk.wear",
            branch: .operations,
            displayName: "Hard Wearing",
            symbolName: "shield.lefthalf.filled",
            maxRank: 3,
            perRank: 0.10,
            requires: 0,
            detail: "Rides wear out {v} more slowly."),

        PerkDefinition(
            id: "perk.safety",
            branch: .operations,
            displayName: "Safety First",
            symbolName: "checkmark.seal.fill",
            maxRank: 2,
            perRank: 0.12,
            requires: 2,
            detail: "{v} less likely to break down at any given condition."),

        PerkDefinition(
            id: "perk.reputation",
            branch: .operations,
            displayName: "Good Name",
            symbolName: "star.fill",
            maxRank: 2,
            perRank: 2,
            requires: 3,
            detail: "{v} points of park rating, for nothing.")
    ]

    static func definition(id: String) -> PerkDefinition? {
        all.first { $0.id == id }
    }

    static func inBranch(_ branch: PerkBranch) -> [PerkDefinition] {
        all.filter { $0.branch == branch }
    }

    /// Every point that could ever be spent. More than the ladder pays out,
    /// on purpose.
    static var totalRanks: Int {
        all.reduce(0) { $0 + $1.maxRank }
    }
}
