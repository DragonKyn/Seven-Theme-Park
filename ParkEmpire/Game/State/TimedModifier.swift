import Foundation

/// A number that applies to the park for a while and then stops.
///
/// Rare events hand these out: a clean bill of health that lifts the rating
/// for half a day, a good review that does the same. One type rather than a
/// pair of loose fields per event, so the expiry rule is written once and
/// every one of them reads the same way at the point of use.
struct TimedModifier: Codable, Equatable {
    var amount: Double = 0
    /// Sim time it stops applying.
    var endsAt: Double = 0

    /// Not named `none`, which collides confusingly with the optional case
    /// of the same name at every use site.
    static let inactive = TimedModifier()

    /// What it is worth right now, which is nothing once it has run out.
    func value(at simTime: Double) -> Double {
        simTime < endsAt ? amount : 0
    }

    /// Park minutes left, or nil when it is over.
    func minutesLeft(at simTime: Double) -> Double? {
        guard simTime < endsAt else { return nil }
        return endsAt - simTime
    }

    /// Starts one running from now.
    static func lasting(_ minutes: Double, worth amount: Double, from simTime: Double) -> TimedModifier {
        TimedModifier(amount: amount, endsAt: simTime + minutes)
    }
}

extension TimedModifier {
    /// Lenient decoding, like everything else that goes in a save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = container.value(.amount, or: 0)
        endsAt = container.value(.endsAt, or: 0)
    }
}
