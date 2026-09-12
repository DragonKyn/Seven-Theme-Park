import Foundation

/// Decides which tip to show, and remembers which ones the player has read.
///
/// Two rules make this feel like help rather than nagging: a tip is shown once
/// ever, and only one is on screen at a time with a pause after each. What has
/// been read is kept with the player rather than with the park, because a
/// second park does not make somebody a beginner again.
@MainActor
final class TutorialDirector {

    private(set) var current: TutorialTip?

    /// Real seconds to wait after a tip is dismissed before offering another,
    /// so finishing one piece of advice does not immediately produce the next.
    private static let pause: TimeInterval = 8
    private var nextOfferAt: Date = .distantPast

    private let store: TutorialStore

    init(store: TutorialStore = TutorialStore()) {
        self.store = store
    }

    var isEnabled: Bool { store.isEnabled }

    /// Offers a tip if one applies. Returns true when what is on screen
    /// changed, so the caller knows whether to publish.
    @discardableResult
    func evaluate(_ signals: TutorialSignals) -> Bool {
        guard store.isEnabled else {
            guard current != nil else { return false }
            current = nil
            return true
        }

        guard current == nil, Date() >= nextOfferAt else { return false }

        let candidate = TutorialContent.all
            .filter { !store.hasSeen($0.id) && $0.condition(signals) }
            .max(by: { $0.priority < $1.priority })

        guard let candidate else { return false }
        current = candidate
        return true
    }

    /// The player has read the tip on screen. It never comes back.
    func dismissCurrent() {
        guard let current else { return }
        store.markSeen(current.id)
        self.current = nil
        nextOfferAt = Date().addingTimeInterval(Self.pause)
    }

    /// Turning tips off also files the one on screen as read, so switching
    /// them back on later does not start with the tip they just refused.
    func setEnabled(_ enabled: Bool) {
        store.isEnabled = enabled
        if !enabled {
            if let current { store.markSeen(current.id) }
            current = nil
        }
    }

    /// Offers every tip again from the beginning.
    func reset() {
        store.forgetAll()
        current = nil
        nextOfferAt = .distantPast
    }

    var tipsRead: Int { store.seenCount }
    var tipsTotal: Int { TutorialContent.all.count }
}

/// Where "I have read this" lives.
///
/// User defaults rather than the save file: tips are about learning the game,
/// and somebody who has learned it should not be taught again by starting a
/// new park.
struct TutorialStore {

    private let defaults: UserDefaults
    private static let enabledKey = "tutorial.enabled"
    private static let seenKey = "tutorial.seen"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// On unless the player has said otherwise.
    var isEnabled: Bool {
        get {
            guard defaults.object(forKey: Self.enabledKey) != nil else { return true }
            return defaults.bool(forKey: Self.enabledKey)
        }
        nonmutating set { defaults.set(newValue, forKey: Self.enabledKey) }
    }

    private var seen: Set<String> {
        Set(defaults.stringArray(forKey: Self.seenKey) ?? [])
    }

    var seenCount: Int { seen.count }

    func hasSeen(_ id: String) -> Bool { seen.contains(id) }

    func markSeen(_ id: String) {
        var updated = seen
        updated.insert(id)
        defaults.set(Array(updated), forKey: Self.seenKey)
    }

    func forgetAll() {
        defaults.removeObject(forKey: Self.seenKey)
    }
}
