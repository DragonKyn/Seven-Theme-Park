import Foundation

/// Something a player can switch on for a while by watching an advert.
///
/// Both are conveniences rather than advantages you cannot earn: the park
/// still has to be built, and nothing here is sold for money.
enum BoostKind: String, CaseIterable, Identifiable {
    /// Unlocks the fifth notch on the speed control.
    case turboSpeed
    /// A few more people through the gate.
    case extraVisitors

    var id: String { rawValue }

    var title: String {
        switch self {
        case .turboSpeed: return "5x Speed"
        case .extraVisitors: return "Busier Gate"
        }
    }

    var summary: String {
        switch self {
        case .turboSpeed:
            return "Adds a fifth notch to the speed control, so a park day passes in a couple of minutes."
        case .extraVisitors:
            return "\(Int(Balance.adVisitorBoost * 100))% more arrivals while it lasts, on top of whatever the park has earned."
        }
    }

    var symbolName: String {
        switch self {
        case .turboSpeed: return "hare.fill"
        case .extraVisitors: return "person.3.sequence.fill"
        }
    }
}

/// How long each boost has left to run.
///
/// Kept against the wall clock rather than park time, and in user defaults
/// rather than in a save: a boost belongs to the player, not to one park, so
/// it carries across every park and keeps running while the app is closed.
@MainActor
final class BoostCenter: ObservableObject {

    static let shared = BoostCenter()

    /// Bumped whenever a boost is granted or lapses, so views watching this
    /// object redraw. The times themselves are read through the methods
    /// below, which compare against the clock as it is now.
    @Published private(set) var generation = 0

    private let defaults: UserDefaults
    private static let keyPrefix = "boost.until."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Reading

    func expiry(_ kind: BoostKind) -> Date? {
        let stamp = defaults.double(forKey: Self.key(kind))
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    func isActive(_ kind: BoostKind) -> Bool {
        remaining(kind) > 0
    }

    /// Seconds left, or zero.
    func remaining(_ kind: BoostKind) -> TimeInterval {
        guard let expiry = expiry(kind) else { return 0 }
        return max(0, expiry.timeIntervalSinceNow)
    }

    /// "9:58", or nil when it is not running.
    func remainingLabel(_ kind: BoostKind) -> String? {
        let seconds = remaining(kind)
        guard seconds > 0 else { return nil }
        return String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }

    // MARK: - Writing

    /// Adds one advert's worth of time.
    ///
    /// Time stacks, so watching two in a row runs the boost for twice as
    /// long, up to a ceiling. The ceiling is there so nobody sits through
    /// twenty adverts to bank a day of it and then never sees the park run at
    /// its own pace again.
    func grant(_ kind: BoostKind) {
        let now = Date()
        let from = max(now, expiry(kind) ?? now)
        let ceiling = now.addingTimeInterval(Balance.adBoostMaximumMinutes * 60)
        let until = min(from.addingTimeInterval(Balance.adBoostMinutes * 60), ceiling)
        defaults.set(until.timeIntervalSince1970, forKey: Self.key(kind))
        generation += 1
    }

    /// Lets views know a boost has run out, so a countdown stops and the
    /// speed control locks itself again.
    func refresh() {
        generation += 1
    }

    private static func key(_ kind: BoostKind) -> String {
        keyPrefix + kind.rawValue
    }
}
