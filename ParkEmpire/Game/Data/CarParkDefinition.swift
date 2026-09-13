import Foundation

/// The car park outside the gate, and what paving more of it is worth.
///
/// Each level adds a flat one per cent to how many people turn up. That is
/// deliberately small next to what a good ride does for demand: this is a
/// long-term investment that a park saves up for, not a shortcut. The price
/// doubles at every level for the same reason.
enum CarParkContent {

    static let maxLevel = 5

    /// Extra arrivals per level, as a fraction.
    static let demandPerLevel = 0.01

    /// What the next level costs. Doubling means the last level costs sixteen
    /// times the first, so buying all five is a whole park's ambition rather
    /// than an afternoon's takings.
    static func cost(forLevel level: Int) -> Double? {
        guard level >= 1, level <= maxLevel else { return nil }
        return 15_000 * pow(2, Double(level - 1))
    }

    /// The multiplier applied to arrivals at a given level.
    static func demandMultiplier(level: Int) -> Double {
        1 + demandPerLevel * Double(min(max(level, 0), maxLevel))
    }

    static func name(forLevel level: Int) -> String {
        switch level {
        case 0: return "Gravel Lot"
        case 1: return "Paved Lot"
        case 2: return "Marked Bays"
        case 3: return "Overflow Field"
        case 4: return "Bus Bays"
        default: return "Multi-Storey"
        }
    }

    static let summary = "More parking means more people can get here. Each level adds one per cent to arrivals."
}
