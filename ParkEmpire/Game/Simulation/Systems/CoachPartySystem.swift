import Foundation

/// A group that arrived together, and who they were.
struct CoachPartyReport: Codable, Identifiable, Equatable {
    var id = UUID()
    let groupName: String
    /// How many got off the coach.
    let count: Int
    /// How many of those were children.
    let childCount: Int

    /// The line under the group's name on the card.
    var detail: String {
        childCount * 2 >= count
            ? "are here on a day out, and most of them are children"
            : "are here on a day out"
    }
}

extension CoachPartyReport {
    /// Lenient decoding, like everything else that goes in a save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        groupName = container.value(.groupName, or: "A group")
        count = container.value(.count, or: 0)
        childCount = container.value(.childCount, or: 0)
    }
}

/// Coaches pulling up at the gate.
///
/// The interesting thing about a coach is not the money, which is poor: it is
/// that twenty people arrive in one second rather than over ten minutes. A
/// park that copes with a trickle does not necessarily cope with a crowd, and
/// this is the only thing in the game that asks the question.
enum CoachPartySystem {

    /// Whether one is due. Booked against the clock rather than rolled for, so
    /// the park can be left alone for a day and still see one.
    static func shouldArrive(state: GameState) -> Bool {
        guard state.attractions.count >= Balance.coachPartyMinimumRides else { return false }
        return state.clock.simTime >= state.nextCoachPartyAt
    }

    /// Books the next one.
    static func scheduleNext(state: GameState) {
        let days = state.rng.double(Balance.coachPartyGapDays)
        state.nextCoachPartyAt = state.clock.simTime + days * Balance.dayLength
    }
}
