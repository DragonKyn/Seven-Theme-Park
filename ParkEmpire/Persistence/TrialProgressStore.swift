import Foundation

/// Which trials the player has beaten, across every park they have played.
///
/// Kept apart from the saves on purpose. The ladder belongs to the player,
/// not to a park: deleting the park a trial was won in must not take the
/// medal back or lock the next rung again.
struct TrialProgressStore {

    private let defaults: UserDefaults
    private static let completedKey = "trials.completed"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Trial id to the earliest day it has been won on.
    var completed: [String: Int] {
        (defaults.dictionary(forKey: Self.completedKey) as? [String: Int]) ?? [:]
    }

    func isCompleted(_ trial: TrialDefinition) -> Bool {
        completed[trial.id] != nil
    }

    func bestDay(for trial: TrialDefinition) -> Int? {
        completed[trial.id]
    }

    /// The first rung is always open; each one after opens when the one
    /// before it has been beaten.
    func isUnlocked(_ trial: TrialDefinition) -> Bool {
        guard trial.number > 1 else { return true }
        guard let previous = TrialContent.all.first(where: { $0.number == trial.number - 1 }) else {
            return true
        }
        return isCompleted(previous)
    }

    /// Records a win. Returns true when it is the first time, which is when a
    /// medal is earned and the next rung opens.
    @discardableResult
    func recordWin(_ trial: TrialDefinition, day: Int) -> Bool {
        var updated = completed
        let isFirst = updated[trial.id] == nil
        updated[trial.id] = min(day, updated[trial.id] ?? day)
        defaults.set(updated, forKey: Self.completedKey)
        return isFirst
    }

    var medalCount: Int { completed.count }
}
