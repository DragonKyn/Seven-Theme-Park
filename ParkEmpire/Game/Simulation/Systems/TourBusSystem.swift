import Foundation

/// A group that arrived together, and who they were.
struct TourBusReport: Codable, Identifiable, Equatable {
    var id = UUID()
    let groupName: String
    /// How many got off the bus.
    let count: Int
    /// How many of those were children.
    let childCount: Int
    /// A company holiday party, which arrives bigger and with far more to spend.
    var isHolidayParty = false

    /// The line on the card, and the line under it.
    var headline: String {
        isHolidayParty ? "\(count) revellers in one go" : "\(count) arrivals in one go"
    }

    var detail: String {
        if isHolidayParty {
            return "The office party is through the gate with a company card and a point to prove. They are spending five times what a visitor usually does."
        }
        return childCount * 2 >= count
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
        isHolidayParty = container.value(.isHolidayParty, or: false)
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
        // In season the buses come a little closer together, since some of
        // them are parties.
        let gap = HolidaySeason.isActive(for: state) ? Balance.holidayPartyGapDays : Balance.tourBusGapDays
        let days = state.rng.double(gap)
        state.nextTourBusAt = state.clock.simTime + days * Balance.dayLength
    }
}
