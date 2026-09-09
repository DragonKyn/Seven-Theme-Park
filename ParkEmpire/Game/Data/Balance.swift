import Foundation

/// Every tuning number the simulation uses. Keeping them here rather than
/// inline makes balancing a single-file job and keeps systems readable.
enum Balance {

    // MARK: - World

    static let mapWidth = 30
    static let mapHeight = 30
    static let startingPathLength = 4
    static let startingCash: Double = 25_000

    // MARK: - Clock

    /// Sim-seconds advanced per simulation tick. 10 ticks == 1 sim-second.
    static let tickDuration: Double = 0.1
    /// Sim-seconds in one park day (12 minutes of real time at 1x).
    static let dayLength: Double = 720
    /// Ceiling on catch-up ticks per frame so a stall cannot spiral.
    static let maxTicksPerFrame = 40

    // MARK: - Guests

    static let maxGuests = 300
    /// Tiles per sim-second.
    static let guestWalkSpeed: Double = 1.6
    static let guestWalkSpeedVariance: Double = 0.25
    /// Sim-seconds between a guest re-evaluating what to do next.
    static let decisionInterval: Double = 4.0
    static let decisionIntervalJitter: Double = 2.0
    /// Sim-seconds after which even a happy guest starts thinking about home.
    static let visitLengthBase: Double = 620
    static let visitLengthVariance: Double = 260

    // Need rates, per sim-second.
    static let hungerRate: Double = 0.15
    static let thirstRate: Double = 0.18
    static let bathroomRate: Double = 0.10
    static let energyDrainWalking: Double = 0.10
    static let energyDrainIdle: Double = 0.04
    static let nauseaDecay: Double = 0.55

    // Thresholds that shape decisions.
    static let hungerUrgent: Double = 75
    static let thirstUrgent: Double = 72
    static let bathroomUrgent: Double = 85
    static let energyLow: Double = 20
    static let nauseaRefuseRide: Double = 65
    static let unhappyLeaveThreshold: Double = 22

    // Happiness drift and event deltas.
    static let happinessDriftPerSecond: Double = 0.05
    static let happinessUnmetNeedPenalty: Double = 0.09
    static let happinessQueueBoredomPerSecond: Double = 0.035
    static let happinessRideBase: Double = 9
    static let happinessThrillMatchBonus: Double = 9
    static let happinessOverpricedPenalty: Double = 7
    static let happinessQueueAbandonPenalty: Double = 8

    // MARK: - Queues

    /// Guests refuse to join a queue estimated longer than this many
    /// sim-seconds, scaled by their own patience.
    static let baseTolerableWait: Double = 90
    static let patienceWaitScale: Double = 2.4
    /// Extra grace beyond the estimate before a queuing guest gives up.
    static let queueAbandonGrace: Double = 1.8

    // MARK: - Economy

    static let defaultAdmissionPrice: Double = 25
    static let admissionPriceMax: Double = 120
    /// Fixed park overhead charged per sim-second (utilities and upkeep).
    static let utilitiesPerSecond: Double = 0.35

    // MARK: - Demand

    /// Upper bound on arrivals per sim-minute at a perfect park.
    static let maxArrivalsPerMinute: Double = 11
    /// Arrivals a brand-new park with one gentle ride can expect.
    static let baseArrivalsPerMinute: Double = 1.6
    /// How much admission guests tolerate before demand collapses, per ride.
    static let acceptablePricePerAttraction: Double = 10
    static let acceptablePriceFloor: Double = 15

    // MARK: - Rating

    /// Sim-seconds between park rating recalculations.
    static let ratingInterval: Double = 10
    /// Fraction of the gap to the target closed per recalculation, so the
    /// rating eases toward reality instead of snapping to it.
    static let ratingSmoothing: Double = 0.10
    /// Facilities considered "enough" per 20 guests, for the facility score.
    static let facilitiesPerTwentyGuests: Double = 1.0

    // MARK: - Cleanliness

    /// Litter a single dropped item adds to a tile, on the tile's 0-100 scale.
    static let litterPerPiece: Double = 34
    /// Litter a janitor removes per sim-second.
    static let litterCleanRate: Double = 55
    /// Chance a food or drink purchase leaves the guest holding rubbish.
    static let trashChancePerPurchase: Double = 0.85
    /// Base per-second chance of dropping rubbish on the ground once a guest
    /// has been carrying it for a while. Scaled by carry time, bin
    /// availability and how tidy the guest is.
    static let litterDropChancePerSecond: Double = 0.020
    /// Sim-seconds of carrying rubbish after which the drop chance is at full
    /// strength.
    static let trashPatience: Double = 70
    /// How full one item makes a bin, on the bin's 0-100 scale.
    static let binFillPerItem: Double = 11
    /// How much dirtier one visit makes a restroom.
    static let bathroomSoilPerUse: Double = 6.5
    /// Soiling a janitor removes per sim-second while servicing.
    static let facilityCleanRate: Double = 14
    /// Restrooms above this are unpleasant; above 92 guests refuse to use them.
    static let dirtyFacilityThreshold: Double = 62
    /// Happiness lost per sim-second standing on completely littered ground,
    /// for a maximally fussy guest.
    static let happinessLitterPenalty: Double = 0.11
    static let happinessDirtyBathroomPenalty: Double = 6

    // MARK: - Maintenance

    /// Sim-seconds before a ride is due another inspection.
    static let inspectionInterval: Double = 320
    /// Breakdown chance per completed cycle at zero condition. Scales with
    /// missing condition, so a well-kept ride effectively never breaks.
    static let breakdownChanceAtZeroCondition: Double = 0.060
    /// Multiplier applied when a ride is overdue an inspection.
    static let overdueInspectionPenalty: Double = 2.0
    static let repairDuration: Double = 48
    static let inspectionDuration: Double = 22
    /// Condition a completed repair restores.
    static let repairedCondition: Double = 92
    /// Condition an inspection tops up.
    static let inspectionConditionBonus: Double = 8
    static let happinessRideBrokeDown: Double = 14

    // MARK: - Staff

    static let staffWalkSpeed: Double = 1.9
    /// Sim-seconds between an idle staff member looking for work.
    static let staffJobSearchInterval: Double = 2.5
    /// Radius in tiles over which an entertainer lifts guest happiness.
    static let entertainerRadius: Double = 4.5
    static let entertainerHappinessPerSecond: Double = 0.55
    /// Maximum staff of all roles.
    static let maxStaff = 40

    // MARK: - Autosave

    static let autosaveInterval: Double = 60
}
