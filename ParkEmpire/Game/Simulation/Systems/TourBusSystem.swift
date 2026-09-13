import Foundation

/// A group that arrived together, and who they were.
struct TourBusReport: Codable, Identifiable, Equatable {
    var id = UUID()
    let groupName: String
    /// How many got off the bus.
    let count: Int
    /// How many of those were children.
    let childCount: Int

    /// The line on the card, and the line under it.
    var headline: String {
        "\(count) arrivals in one go"
    }

    var detail: String {
        childCount * 2 >= count
            ? "A school party is through the gate. Your queues are about to find out."
            : "A day trip is through the gate. Your queues are about to find out."
    }
}

extension TourBusReport {
    /// Lenient decoding, like everything else that goes in a save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        groupName = container.value(.groupName, or: "A group")
        count = container.value(.count, or: 0)
        childCount = container.value(.childCount, or: 0)
    }
}

/// Tour buses pulling up at the gate.
///
/// The interesting thing about a busload is not the money, which is poor: it is
/// that twenty people arrive in one second rather than over ten minutes. A
/// park that copes with a trickle does not necessarily cope with a crowd, and
/// this is the only thing in the game that asks the question.
enum TourBusSystem {

    /// Whether one is due. Booked against the clock rather than rolled for, so
    /// the park can be left alone for a day and still see one.
    static func shouldArrive(state: GameState) -> Bool {
        guard state.attractions.count >= Balance.tourBusMinimumRides else { return false }
        return state.clock.simTime >= state.nextTourBusAt
    }

    /// Books the next one.
    static func scheduleNext(state: GameState) {
        let days = state.rng.double(Balance.tourBusGapDays)
        state.nextTourBusAt = state.clock.simTime + days * Balance.dayLength
    }
}
