import Foundation

/// Which rules a park runs under. Chosen when the park is created and fixed
/// for its lifetime.
enum GameMode: String, Codable, CaseIterable, Identifiable {
    /// The full game: a starting balance, and everything has to pay for itself.
    case normal
    /// Unlimited money, for building without the accounting. Costs are still
    /// recorded so the finance screen still means something, but nothing is
    /// ever deducted.
    case freeBuild
    /// A park built against a deadline, on a map chosen for it, as one rung
    /// of the Park Trials ladder. Started from the ladder, never from the new
    /// park sheet.
    case trial

    var id: String { rawValue }

    /// The modes chosen on the new park screen.
    static let sandboxModes: [GameMode] = [.normal, .freeBuild]

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .freeBuild: return "Free Build"
        case .trial: return "Park Trial"
        }
    }

    var summary: String {
        switch self {
        case .normal:
            return "Start with a fixed balance and make the park pay for itself. Achievements count."
        case .freeBuild:
            return "Unlimited money. Build whatever you like. Achievements are switched off."
        case .trial:
            return "A set map, a set budget and a deadline. Meet every goal to earn the medal."
        }
    }

    var symbolName: String {
        switch self {
        case .normal: return "chart.line.uptrend.xyaxis"
        case .freeBuild: return "infinity"
        case .trial: return "flag.checkered"
        }
    }

    var hasUnlimitedMoney: Bool { self == .freeBuild }

    /// Achievements are earned against the constraint of a budget. Without one
    /// they measure nothing, so they are not awarded at all.
    var earnsAchievements: Bool { self != .freeBuild }
}
