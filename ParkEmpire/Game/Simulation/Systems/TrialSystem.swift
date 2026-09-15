import Foundation

/// How a trial stands.
enum TrialOutcome: String, Codable {
    case inProgress
    case won
    case lost
}

/// The end of a trial, waiting to be shown to the player.
struct TrialResult: Codable, Identifiable, Equatable {
    var id = UUID()
    let trialID: String
    let won: Bool
    /// The day it was decided on.
    let day: Int

    var trial: TrialDefinition? { TrialContent.definition(id: trialID) }
}

extension TrialResult {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        trialID = container.value(.trialID, or: "")
        won = container.value(.won, or: false)
        day = container.value(.day, or: 1)
    }
}

/// A result together with what it means for the ladder, which only the
/// controller knows: the simulation never reads the player's progress.
struct TrialResultReport: Identifiable, Equatable {
    let result: TrialResult
    /// Whether this is the first time the trial has been beaten, which is when
    /// the medal is earned and the next rung opens.
    let isFirstWin: Bool
    let nextTrial: TrialDefinition?

    var id: UUID { result.id }
}

/// Watches a trial park for the moment it is won, or runs out of time.
///
/// A trial is won the first moment every goal is met together, not at the
/// deadline. Waiting for the last day would make a player who finished early
/// sit through days of a park that has already done what was asked. It is
/// lost once the last day has closed with any goal still short.
///
/// After either, the park carries on as an ordinary park: nobody should lose
/// the thing they built because a clock ran out.
enum TrialSystem {

    /// Seconds between checks. Every goal reads a live number, so a few
    /// seconds late costs nothing.
    static let checkInterval: Double = 2

    static func update(state: GameState) {
        guard let trial = state.trial, state.trialOutcome == .inProgress else { return }
        guard state.clock.simTime >= state.nextTrialCheck else { return }
        state.nextTrialCheck = state.clock.simTime + checkInterval

        if trial.goals.allSatisfy({ $0.isMet(in: state) }) {
            finish(trial: trial, won: true, state: state)
        } else if state.clock.day > trial.dayLimit {
            finish(trial: trial, won: false, state: state)
        }
    }

    private static func finish(trial: TrialDefinition, won: Bool, state: GameState) {
        state.trialOutcome = won ? .won : .lost
        let day = min(state.clock.day, trial.dayLimit)
        state.trialDecidedDay = day
        state.pendingTrialResult = TrialResult(trialID: trial.id, won: won, day: day)
        state.postAlert(won
                        ? "\(trial.title) complete on day \(day)."
                        : "Time is up on \(trial.title). The park is yours to keep playing.",
                        severity: won ? .info : .warning,
                        key: "trial.result",
                        cooldown: 0)
    }
}
