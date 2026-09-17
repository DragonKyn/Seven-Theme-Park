import Foundation

/// What the boosts a player has switched on are worth to the park in front of
/// them, as plain numbers the simulation can multiply by.
///
/// The same shape as `ParkPerks`, and for the same reason: the boost centre
/// works the numbers out, the controller hands them to the park once a
/// refresh, and each system reads the one it cares about without knowing that
/// adverts exist.
///
/// Codable only because the park it rides along on is. What lands in a save
/// is ignored on load and replaced with whatever is running now.
struct AdBoostEffects: Codable, Equatable {
    /// Extra arrivals, as a share.
    var extraArrivals: Double = 0
    /// How much readier guests are to part with their money.
    var spendWillingness: Double = 0
    /// How much more slowly rides wear, as a share.
    var wearReduction: Double = 0
    /// How much less likely a breakdown is, as a share.
    var breakdownReduction: Double = 0
    /// How much less rubbish ends up on the ground, as a share.
    var litterReduction: Double = 0

    var spendFactor: Double { 1 + spendWillingness }
    var wearFactor: Double { max(0, 1 - wearReduction) }
    var breakdownFactor: Double { max(0, 1 - breakdownReduction) }
    var litterFactor: Double { max(0, 1 - litterReduction) }

    /// Worked out from whatever the player has running.
    init(active: (BoostKind) -> Bool) {
        if active(.extraVisitors) { extraArrivals = Balance.adVisitorBoost }
        if active(.bigSpenders) { spendWillingness = Balance.adSpendBoost }
        if active(.smoothRunning) {
            wearReduction = Balance.adWearReduction
            breakdownReduction = Balance.adBreakdownReduction
        }
        if active(.spotless) { litterReduction = Balance.adLitterReduction }
    }

    init() {}
}
