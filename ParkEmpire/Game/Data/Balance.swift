import Foundation

/// Every tuning number the simulation uses. Keeping them here rather than
/// inline makes balancing a single-file job and keeps systems readable.
enum Balance {

    // MARK: - World

    /// A new park's grid. Parks saved at an older size keep it: the map
    /// decodes its own dimensions, so a 30x30 park stays 30x30.
    static let mapWidth = 60
    static let mapHeight = 60
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

    static let maxGuests = 420
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
    /// Happiness gained per second on a perfectly decorated tile, scaled down
    /// by how pretty the tile actually is. Comparable to the drift rate, so
    /// pleasant surroundings roughly double the rate a guest cheers up.
    static let happinessBeautyPerSecond: Double = 0.06
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
    /// A maxed-out park will happily take several hundred at the gate, so the
    /// slider has to go somewhere worth going. What guests will actually pay
    /// is decided by `GuestEconomics`, not by this.
    static let admissionPriceMax: Double = 500
    /// Fixed park overhead charged per sim-second (utilities and upkeep).
    static let utilitiesPerSecond: Double = 0.35

    // MARK: - Demand

    /// Upper bound on arrivals per sim-minute at a perfect park.
    static let maxArrivalsPerMinute: Double = 11
    /// Arrivals a brand-new park with one gentle ride can expect.
    static let baseArrivalsPerMinute: Double = 1.6
    /// How much admission guests tolerate before demand collapses, per ride.
    static let acceptablePricePerAttraction: Double = 12
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

    // MARK: - Social media

    /// A park with fewer rides than this has nothing worth filming.
    static let influencerMinimumRides = 2
    /// Park days between one famous visitor and the next. Rare on purpose:
    /// the post is worth noticing, and something that turns up every other
    /// day stops being an event and becomes part of the income.
    static let influencerGapDays: ClosedRange<Double> = 5.0...9.0
    /// What a post is worth, as extra arrivals. The floor is what any post
    /// gets; the range on top of it is decided by the ride they chose.
    static let promotionBoostFloor: Double = 0.18
    static let promotionBoostRange: Double = 0.35
    /// Park minutes a post keeps working for. Sim-seconds are park minutes,
    /// so three hours of a twelve hour day. Long enough that the queues
    /// visibly fill, short enough that the park is your own again by closing.
    static let promotionMinutes: Double = 180

    // MARK: - Carnival games

    /// Happiness a guest gains from winning a prize, and loses from a go that
    /// came to nothing. Winning is worth far more than losing costs, which is
    /// why a midway is a good thing to own.
    static let happinessGameWin: Double = 16
    static let happinessGameLoss: Double = 3

    // MARK: - Staff

    static let staffWalkSpeed: Double = 1.9
    /// Sim-seconds between an idle staff member looking for work.
    static let staffJobSearchInterval: Double = 2.5
    /// Radius in tiles over which an entertainer lifts guest happiness.
    static let entertainerRadius: Double = 4.5
    static let entertainerHappinessPerSecond: Double = 0.55
    /// Radius in tiles over which a security guard reassures guests.
    static let securityRadius: Double = 5.0
    static let securityHappinessPerSecond: Double = 0.30
    /// How much less likely a guest is to drop rubbish with a guard in sight.
    static let securityLitterDeterrence: Double = 0.35
    /// Sim-seconds a guard stands at a post before moving on.
    static let securityPostDuration: Double = 55
    static let securityPatrolDuration: Double = 18
    /// How often a guard picks somewhere other than the gate to stand.
    static let securityPatrolChance: Double = 0.30
    /// How far from the gate a guard's post can be.
    static let securityGateRadius: Int = 5
    /// Maximum staff of all roles.
    static let maxStaff = 40

    // MARK: - Mystery critics

    /// A park with nothing to review is not worth reviewing.
    static let criticMinimumRides = 2
    /// Park days between one anonymous reviewer and the next.
    static let criticGapDays: ClosedRange<Double> = 4.0...7.0
    /// Happiness at which a review turns from lukewarm to warm, and the point
    /// below which it turns hostile. Between the two the review runs and
    /// changes nothing, which is a real verdict and should read as one.
    static let criticPraiseHappiness: Double = 70
    static let criticComplaintHappiness: Double = 45
    /// Rating points a five star review adds, scaled down for four, and the
    /// points a one star review takes off. Ratings ease at a tenth every ten
    /// seconds, so these move the live number by a little less than they say.
    static let criticPraiseRating: Double = 7
    static let criticComplaintRating: Double = 8
    /// Extra arrivals a warm review brings, as a share.
    static let criticPraiseArrivals: Double = 0.20
    /// Park minutes a review keeps working for, good or bad. Half a day.
    static let criticEffectMinutes: Double = 360

    // MARK: - Troublemakers

    /// A park with fewer guests than this has nobody to annoy, and the event
    /// would go unwitnessed.
    static let troublemakerMinimumGuests = 25
    /// Park days between one and the next. More often than a famous visitor,
    /// because the lesson it teaches is one the player needs sooner.
    static let troublemakerGapDays: ClosedRange<Double> = 2.5...5.0
    /// Park minutes they stay if nobody removes them. Four hours of a twelve
    /// hour day: long enough that the damage is real, short of a disaster.
    static let troublemakerStayLength: Double = 240
    /// Park minutes before security so much as notices them.
    ///
    /// Without this a guard breaks off their post the instant one walks in and
    /// the whole event is over in seconds, which is neither satisfying nor
    /// instructive. The grace period is what gives them time to make a mess
    /// worth clearing up, and what makes the escort feel like a rescue.
    static let troublemakerGracePeriod: Double = 40
    /// Tiles over which their presence sours the mood.
    static let troublemakerRadius: Double = 4.0
    /// Happiness drained per sim-second from everybody inside that circle.
    /// Deliberately larger than an entertainer's lift.
    static let troublemakerHappinessPerSecond: Double = 0.85
    /// Chance per sim-second of dropping a piece of rubbish. Roughly one every
    /// eight seconds, so even the shortest visit leaves a trail somebody has
    /// to walk past.
    static let troublemakerLitterChancePerSecond: Double = 0.120
    /// Chance per sim-second of shoving somebody out of a nearby queue, how
    /// far they reach to do it, and what it costs the person shoved.
    static let troublemakerQueueChancePerSecond: Double = 0.045
    static let troublemakerQueueRadius: Double = 3.5
    static let troublemakerQueuePenalty: Double = 10

    // MARK: - Security escorts

    /// How close a guard has to get before they have them.
    static let escortCatchRadius: Double = 0.9
    /// Sim-seconds between a guard re-planning towards a moving target. Every
    /// tick would make route finding the most expensive thing in the game,
    /// and a guard a second behind still catches somebody slower than they are.
    static let escortRepathInterval: Double = 1.5
    /// One-off relief to everybody who watched it happen, and how far that
    /// reaches.
    static let escortHappinessRelief: Double = 9
    static let escortReliefRadius: Double = 6.0

    // MARK: - Safety inspections

    static let safetyInspectionMinimumRides = 1
    /// Park days between visits from the regulator.
    static let safetyInspectionGapDays: ClosedRange<Double> = 2.5...4.5
    /// Park minutes of notice before the verdict lands, so a mechanic sent
    /// the moment the alert arrives can still save the ride.
    static let safetyInspectionWarning: Double = 60
    /// Condition at or above which a ride passes. Well below `repairedCondition`
    /// so a ride a mechanic has just touched cannot fail.
    static let safetyInspectionPassCondition: Double = 55
    /// The fine, charged to maintenance. Comparable to the cost of the mechanic
    /// the park should have hired instead.
    static let safetyInspectionFine: Double = 1_200
    /// Rating points a clean bill of health adds, and the park minutes it lasts.
    static let safetyInspectionRatingBonus: Double = 6
    static let safetyInspectionBonusMinutes: Double = 360

    // MARK: - Tour buses

    static let tourBusMinimumRides = 1
    /// Park days between tour buses. Still the most common of the rare
    /// events, but a bus every other day stops being an arrival and starts
    /// being the way the park fills up.
    static let tourBusGapDays: ClosedRange<Double> = 4.0...7.0
    /// How many get off the bus, and the point below which a full park
    /// simply turns it round at the gate.
    static let tourBusSize: ClosedRange<Int> = 12...22
    static let tourBusMinimumSize = 6
    /// Share of the party that are children, and what each of them has to
    /// spend against an ordinary guest.
    static let tourBusChildShare: Double = 0.62
    static let tourBusSpendScale: Double = 0.55

    // MARK: - Achievements

    /// Sim-seconds between achievement checks. Every metric is a running total
    /// or a live reading, so nothing is missed by looking a few seconds later.
    static let achievementCheckInterval: Double = 5

    // MARK: - Autosave

    static let autosaveInterval: Double = 60
}
