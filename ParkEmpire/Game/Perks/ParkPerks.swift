import Foundation

/// What the player's spent trial points are worth to the park in front of
/// them, as plain numbers the simulation can multiply by.
///
/// Deliberately a value with no behaviour: the store works out the numbers
/// once, the controller hands them to the park, and every system reads the
/// one it cares about without knowing that perks or trials exist.
/// Codable only because the park it rides along on is. The values written
/// into a save are ignored on load and replaced with whatever the player's
/// perk tree says now, which is what makes moving a point take effect in an
/// old park straight away.
struct ParkPerks: Codable, Equatable {
    /// Extra arrivals, as a share.
    var extraArrivals: Double = 0
    /// Points of happiness a guest walks in with, on top of the usual roll.
    var guestHappiness: Double = 0
    /// Extra spending money, as a share.
    var guestSpending: Double = 0
    /// Taken off anything built, as a share.
    var buildDiscount: Double = 0
    /// Taken off wages, as a share.
    var wageDiscount: Double = 0
    /// Taken off what a sale costs to stock, as a share.
    var stockDiscount: Double = 0
    /// How much more slowly rides wear, as a share.
    var wearReduction: Double = 0
    /// How much less likely a breakdown is, as a share.
    var breakdownReduction: Double = 0
    /// Points added to the park rating.
    var ratingBonus: Double = 0

    /// Multipliers, clamped so a future perk cannot make something free.
    var buildCostFactor: Double { max(0.3, 1 - buildDiscount) }
    var wageFactor: Double { max(0.3, 1 - wageDiscount) }
    var stockFactor: Double { max(0.3, 1 - stockDiscount) }
    var wearFactor: Double { max(0.3, 1 - wearReduction) }
    var breakdownFactor: Double { max(0.3, 1 - breakdownReduction) }
}
