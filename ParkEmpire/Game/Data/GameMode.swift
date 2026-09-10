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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .freeBuild: return "Free Build"
        }
    }

    var summary: String {
        switch self {
        case .normal:
            return "Start with a fixed balance and make the park pay for itself. Achievements count."
        case .freeBuild:
            return "Unlimited money. Build whatever you like. Achievements are switched off."
        }
    }

    var symbolName: String {
        switch self {
        case .normal: return "chart.line.uptrend.xyaxis"
        case .freeBuild: return "infinity"
        }
    }

    var hasUnlimitedMoney: Bool { self == .freeBuild }

    /// Achievements are earned against the constraint of a budget. Without one
    /// they measure nothing, so they are not awarded at all.
    var earnsAchievements: Bool { self == .normal }
}
