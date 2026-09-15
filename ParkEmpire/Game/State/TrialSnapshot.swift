import Foundation

/// A trial park's progress, worked out once per refresh for the interface.
struct TrialSnapshot: Equatable {
    struct Goal: Identifiable, Equatable {
        let id: Int
        let title: String
        let shortTitle: String
        let symbolName: String
        let currentText: String
        let targetText: String
        /// 0...1, how far there.
        let fraction: Double
        let isMet: Bool
    }

    let number: Int
    let title: String
    let day: Int
    let dayLimit: Int
    let outcome: TrialOutcome
    let decidedDay: Int
    let goals: [Goal]

    var daysLeft: Int { max(0, dayLimit - day) }
    var metCount: Int { goals.filter(\.isMet).count }

    init?(state: GameState) {
        guard let trial = state.trial else { return nil }
        number = trial.number
        title = trial.title
        day = state.clock.day
        dayLimit = trial.dayLimit
        outcome = state.trialOutcome
        decidedDay = state.trialDecidedDay
        goals = trial.goals.enumerated().map { index, goal in
            let current = goal.current(in: state)
            return Goal(id: index,
                        title: goal.title,
                        shortTitle: goal.shortTitle,
                        symbolName: goal.symbolName,
                        currentText: goal.format(current),
                        targetText: goal.format(goal.target),
                        fraction: goal.target > 0 ? max(0, min(1, current / goal.target)) : 1,
                        isMet: goal.isMet(in: state))
        }
    }
}
