import Foundation

/// Aggregate counters that are cheap to keep updated and awkward to recompute.
struct ParkStatistics: Codable {
    var guestsAdmittedToday: Int = 0
    var guestsAdmittedTotal: Int = 0
    var guestsLeftToday: Int = 0
    var ridesGivenTotal: Int = 0
    var itemsSoldTotal: Int = 0
    var breakdownsTotal: Int = 0
    var litterCleanedTotal: Int = 0

    /// Counts of the reason guests gave for leaving, used for "common complaint".
    var departureReasons: [String: Int] = [:]

    mutating func recordDeparture(reason: String) {
        guestsLeftToday += 1
        departureReasons[reason, default: 0] += 1
    }

    var commonComplaint: String? {
        departureReasons
            .filter { $0.key != DepartureReason.satisfied.rawValue }
            .max(by: { $0.value < $1.value })?
            .key
    }

    mutating func rollOverDay() {
        guestsAdmittedToday = 0
        guestsLeftToday = 0
    }
}

extension ParkStatistics {
    /// Lenient decoding: counters added in later phases start at zero rather
    /// than throwing away the whole save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guestsAdmittedToday = container.value(.guestsAdmittedToday, or: 0)
        guestsAdmittedTotal = container.value(.guestsAdmittedTotal, or: 0)
        guestsLeftToday = container.value(.guestsLeftToday, or: 0)
        ridesGivenTotal = container.value(.ridesGivenTotal, or: 0)
        itemsSoldTotal = container.value(.itemsSoldTotal, or: 0)
        breakdownsTotal = container.value(.breakdownsTotal, or: 0)
        litterCleanedTotal = container.value(.litterCleanedTotal, or: 0)
        departureReasons = container.value(.departureReasons, or: [:])
    }
}

enum DepartureReason: String {
    case satisfied = "Had a full day"
    case unhappy = "Unhappy with the park"
    case tired = "Too tired, nowhere to sit"
    case brokeAndBored = "Ran out of money"
    case noBathroom = "Could not find a restroom"
    case queuesTooLong = "Queues were too long"
    case tooDirty = "The park was filthy"
}
