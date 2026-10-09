package com.wickedstudios.wonderlot

object Balance {

    // Every tuning number the simulation uses. Keeping them here rather than
    // inline makes balancing a single-file job and keeps systems readable.

    // MARK: - World

    // A new park's grid. Parks saved at an older size keep it: the map
    // decodes its own dimensions, so a 30x30 park stays 30x30.
    const val mapWidth = 60
    const val mapHeight = 60
    const val startingPathLength = 4
    const val startingCash = 25000.0

    // MARK: - Clock

    // Sim-seconds advanced per simulation tick. 10 ticks == 1 sim-second.
    const val tickDuration = 0.1
    // Sim-seconds in one park day (12 minutes of real time at 1x).
    const val dayLength = 720.0
    // Ceiling on catch-up ticks per frame so a stall cannot spiral.
    const val maxTicksPerFrame = 40

    // MARK: - Guests

    // The most guests the park will hold at once. The crowd a park actually
    // reaches is arrivals times how long they stay, so this is the ceiling
    // and `maxArrivalsPerMinute` is what sets the usual size: at 24 a minute
    // and a ten minute visit, a park at its best sits near this number.
    const val maxGuests = 250
    // Tiles per sim-second.
    const val guestWalkSpeed = 1.6
    const val guestWalkSpeedVariance = 0.25
    // Sim-seconds between a guest re-evaluating what to do next.
    const val decisionInterval = 4.0
    const val decisionIntervalJitter = 2.0
    // Sim-seconds after which even a happy guest starts thinking about home.
    const val visitLengthBase = 620.0
    const val visitLengthVariance = 260.0

    // UNHANDLED: // Need rates, per sim-second.
    const val hungerRate = 0.15
    const val thirstRate = 0.18
    const val bathroomRate = 0.10
    const val energyDrainWalking = 0.10
    const val energyDrainIdle = 0.04
    const val nauseaDecay = 0.55

    // UNHANDLED: // Thresholds that shape decisions.
    const val hungerUrgent = 75.0
    const val thirstUrgent = 72.0
    const val bathroomUrgent = 85.0
    const val energyLow = 20.0
    const val nauseaRefuseRide = 65.0
    const val unhappyLeaveThreshold = 22.0

    // UNHANDLED: // Happiness drift and event deltas.
    const val happinessDriftPerSecond = 0.05
    const val happinessUnmetNeedPenalty = 0.09
    const val happinessQueueBoredomPerSecond = 0.035
    // Happiness gained per second on a perfectly decorated tile, scaled down
    // by how pretty the tile actually is. Comparable to the drift rate, so
    // pleasant surroundings roughly double the rate a guest cheers up.
    const val happinessBeautyPerSecond = 0.06
    const val happinessRideBase = 9.0
    const val happinessThrillMatchBonus = 9.0
    const val happinessOverpricedPenalty = 7.0
    const val happinessQueueAbandonPenalty = 8.0

    // MARK: - Queues

    // Guests refuse to join a queue estimated longer than this many
    // sim-seconds, scaled by their own patience.
    const val baseTolerableWait = 90.0
    const val patienceWaitScale = 2.4
    // Extra grace beyond the estimate before a queuing guest gives up.
    const val queueAbandonGrace = 1.8

    // MARK: - Economy

    const val defaultAdmissionPrice = 25.0
    // A maxed-out park will happily take several hundred at the gate, so the
    // slider has to go somewhere worth going. What guests will actually pay
    // is decided by `GuestEconomics`, not by this.
    const val admissionPriceMax = 500.0
    // Fixed park overhead charged per sim-second (utilities and upkeep).
    const val utilitiesPerSecond = 0.35

    // MARK: - Demand

    // Upper bound on arrivals per sim-minute at a perfect park.
    const val maxArrivalsPerMinute = 24.0
    // How many rides' worth of appeal count towards demand. Parks are large,
    // and a park with a dozen rides should draw more than one with seven.
    const val maxAttractionAppeal = 10.0
    // Arrivals a brand-new park with one gentle ride can expect.
    const val baseArrivalsPerMinute = 1.6
    // How much admission guests tolerate before demand collapses, per ride.
    const val acceptablePricePerAttraction = 12.0
    const val acceptablePriceFloor = 15.0

    // MARK: - Rating

    // Sim-seconds between park rating recalculations.
    const val ratingInterval = 10.0
    // Fraction of the gap to the target closed per recalculation, so the
    // rating eases toward reality instead of snapping to it.
    const val ratingSmoothing = 0.10
    // Facilities considered "enough" per 20 guests, for the facility score.
    const val facilitiesPerTwentyGuests = 1.0

    // MARK: - Cleanliness

    // Litter a single dropped item adds to a tile, on the tile's 0-100 scale.
    const val litterPerPiece = 34.0
    // Litter a janitor removes per sim-second.
    const val litterCleanRate = 55.0
    // Chance a food or drink purchase leaves the guest holding rubbish.
    const val trashChancePerPurchase = 0.85
    // Base per-second chance of dropping rubbish on the ground once a guest
    // has been carrying it for a while. Scaled by carry time, bin
    // availability and how tidy the guest is.
    const val litterDropChancePerSecond = 0.020
    // Sim-seconds of carrying rubbish after which the drop chance is at full
    // strength.
    const val trashPatience = 70.0
    // How full one item makes a bin, on the bin's 0-100 scale.
    const val binFillPerItem = 11.0
    // How much dirtier one visit makes a restroom.
    const val bathroomSoilPerUse = 6.5
    // Soiling a janitor removes per sim-second while servicing.
    const val facilityCleanRate = 14.0
    // Restrooms above this are unpleasant; above 92 guests refuse to use them.
    const val dirtyFacilityThreshold = 62.0

    // How far from a new building, in tiles, anybody it was put on top of is
    // moved to find a walkway to stand on.
    const val buildOverEvictionRadius = 8

    // MARK: - Coaster circuits

    // Furthest apart, in tiles, two events of one drag can be and still be
    // joined up. Further than that and the finger was lifted and put down
    // somewhere else, and filling the space between would be a mistake.
    const val maxPaintGap = 12

    // How much each repeat of the same element is worth compared with the
    // one before it. The second loop is worth sixty per cent of the first.
    const val coasterRepeatDecay = 0.6
    // Extra thrill for each different kind of element beyond the first, up to
    // `coasterVarietyKinds` of them.
    const val coasterVarietyBonus = 4.0
    const val coasterVarietyKinds = 3
    // Elements covering more than this share of the track leave it no straight
    // run between them, and are worth less for it.
    const val coasterCrowdingLimit = 0.6
    const val coasterCrowdingFactor = 0.75
    // A circuit that is not closed rides as a shuttle: this much of what it
    // would otherwise be worth.
    const val coasterOpenLineFactor = 0.65
    // How much each point of an element's intensity above 1 adds up to.
    const val coasterIntensityScale = 40.0
    const val coasterIntenseThreshold = 55.0
    const val coasterNauseaCeiling = 35.0
    // Below this many tiles the player is told the track is too short.
    const val coasterShortLength = 16

    // How much longer a filthy restroom takes to clean than a spotless one,
    // as a share of its base time. A restroom at the point of closing takes a
    // third as long again, which is how fifteen minutes becomes twenty.
    const val cleaningDirtExtra = 0.33

    // Sim-seconds a guest takes to finish a bag of popcorn.
    const val popcornEatSeconds = 40.0
    // How close a bin has to be, in tiles, for an empty bag to be carried to
    // it rather than dropped where the guest stands.
    const val popcornBinRadius = 5
    // Rubbish a dropped bag leaves behind. More than a wrapper: it is a whole
    // bag, and it spills.
    const val popcornLitter = 48.0
    // How strongly a guest in a good mood is drawn to a snack cart, on the
    // same scale as every other facility's appeal.
    const val snackImpulse = 85.0

    // How strongly a hungry guest is drawn to a picnic table, on the same
    // scale as every other facility's appeal.
    const val picnicMealDraw = 70.0
    // Happiness lost per sim-second standing on completely littered ground,
    // for a maximally fussy guest.
    const val happinessLitterPenalty = 0.11
    const val happinessDirtyBathroomPenalty = 6.0

    // MARK: - Maintenance

    // Sim-seconds before a ride is due another inspection.
    const val inspectionInterval = 320.0
    // Breakdown chance per completed cycle at zero condition. Scales with
    // missing condition, so a well-kept ride effectively never breaks.
    const val breakdownChanceAtZeroCondition = 0.060
    // Multiplier applied when a ride is overdue an inspection.
    const val overdueInspectionPenalty = 2.0
    const val repairDuration = 48.0
    const val inspectionDuration = 22.0
    // Condition a completed repair restores.
    const val repairedCondition = 92.0
    // Condition an inspection tops up.
    const val inspectionConditionBonus = 8.0
    const val happinessRideBrokeDown = 14.0

    // MARK: - Social media

    // A park with fewer rides than this has nothing worth filming.
    const val influencerMinimumRides = 2
    // Park days between one famous visitor and the next. Rare on purpose:
    // the post is worth noticing, and something that turns up every other
    // day stops being an event and becomes part of the income.
    val influencerGapDays = 5.0..9.0
    // What a post is worth, as extra arrivals. The floor is what any post
    // gets; the range on top of it is decided by the ride they chose.
    const val promotionBoostFloor = 0.18
    const val promotionBoostRange = 0.35
    // Park minutes a post keeps working for. Sim-seconds are park minutes,
    // so three hours of a twelve hour day. Long enough that the queues
    // visibly fill, short enough that the park is your own again by closing.
    const val promotionMinutes = 180.0

    // MARK: - Carnival games

    // Happiness a guest gains from winning a prize, and loses from a go that
    // came to nothing. Winning is worth far more than losing costs, which is
    // why a midway is a good thing to own.
    const val happinessGameWin = 16.0
    const val happinessGameLoss = 3.0

    // MARK: - Staff

    const val staffWalkSpeed = 1.9
    // Sim-seconds between an idle staff member looking for work.
    const val staffJobSearchInterval = 2.5
    // MARK: - Staff and the train

    // What a train journey is worth when comparing it with a walk, in tiles,
    // on top of the walking at either end.
    const val staffTrainTiles = 30
    // Sim-seconds on the platform, then on the train.
    const val staffTrainWait = 6.0
    const val staffTrainRide = 10.0
    // Sim-seconds an employee holds a spot they were sent to, before they go
    // back to choosing their own work.
    const val staffPostHold = 90.0

    // MARK: - Performers

    // A mascot works a wider circle, harder, and is a hit with children.
    const val mascotRadiusFactor = 1.25
    const val mascotHappinessFactor = 1.5
    const val mascotChildFactor = 1.8
    // How many places a mascot weighs up when choosing where the crowd is.
    const val mascotSpotSamples = 8
    // Balloons a balloon artist gives out per second of work, and what each
    // is worth to the person who gets it.
    const val balloonHandoutPerSecond = 0.35
    const val balloonHappiness = 5.0
    // Sim-seconds between a magician's tricks on average, and what one is
    // worth to whoever is amazed.
    const val magicTrickInterval = 7.0
    const val magicTrickHappiness = 10.0

    // Radius in tiles over which an entertainer lifts guest happiness.
    const val entertainerRadius = 4.5
    const val entertainerHappinessPerSecond = 0.55
    // Radius in tiles over which a security guard reassures guests.
    const val securityRadius = 5.0
    const val securityHappinessPerSecond = 0.30
    // How much less likely a guest is to drop rubbish with a guard in sight.
    const val securityLitterDeterrence = 0.35
    // Sim-seconds a guard stands at a post before moving on.
    const val securityPostDuration = 55.0
    const val securityPatrolDuration = 18.0
    // How often a guard picks somewhere other than the gate to stand.
    const val securityPatrolChance = 0.30
    // How far from the gate a guard's post can be.
    const val securityGateRadius = 5
    // Maximum staff of all roles.
    const val maxStaff = 40

    // MARK: - Mystery critics

    // A park with nothing to review is not worth reviewing.
    const val criticMinimumRides = 2
    // Park days between one anonymous reviewer and the next.
    val criticGapDays = 4.0..7.0
    // Happiness at which a review turns from lukewarm to warm, and the point
    // below which it turns hostile. Between the two the review runs and
    // changes nothing, which is a real verdict and should read as one.
    const val criticPraiseHappiness = 70.0
    const val criticComplaintHappiness = 45.0
    // Rating points a five star review adds, scaled down for four, and the
    // points a one star review takes off. Ratings ease at a tenth every ten
    // seconds, so these move the live number by a little less than they say.
    const val criticPraiseRating = 7.0
    const val criticComplaintRating = 8.0
    // Extra arrivals a warm review brings, as a share.
    const val criticPraiseArrivals = 0.20
    // Park minutes a review keeps working for, good or bad. Half a day.
    const val criticEffectMinutes = 360.0

    // MARK: - Troublemakers

    // A park with fewer guests than this has nobody to annoy, and the event
    // would go unwitnessed.
    const val troublemakerMinimumGuests = 25
    // Park days between one and the next. More often than a famous visitor,
    // because the lesson it teaches is one the player needs sooner.
    val troublemakerGapDays = 2.5..5.0
    // Park minutes they stay if nobody removes them. Four hours of a twelve
    // hour day: long enough that the damage is real, short of a disaster.
    const val troublemakerStayLength = 240.0
    // Park minutes before security so much as notices them.
    //
    // Without this a guard breaks off their post the instant one walks in and
    // the whole event is over in seconds, which is neither satisfying nor
    // instructive. The grace period is what gives them time to make a mess
    // worth clearing up, and what makes the escort feel like a rescue.
    const val troublemakerGracePeriod = 40.0
    // Tiles over which their presence sours the mood.
    const val troublemakerRadius = 4.0
    // Happiness drained per sim-second from everybody inside that circle.
    // Deliberately larger than an entertainer's lift.
    const val troublemakerHappinessPerSecond = 0.85
    // Chance per sim-second of dropping a piece of rubbish. Roughly one every
    // eight seconds, so even the shortest visit leaves a trail somebody has
    // to walk past.
    const val troublemakerLitterChancePerSecond = 0.120
    // Chance per sim-second of shoving somebody out of a nearby queue, how
    // far they reach to do it, and what it costs the person shoved.
    const val troublemakerQueueChancePerSecond = 0.045
    const val troublemakerQueueRadius = 3.5
    const val troublemakerQueuePenalty = 10.0

    // MARK: - Security escorts

    // How close a guard has to get before they have them.
    const val escortCatchRadius = 0.9
    // Sim-seconds between a guard re-planning towards a moving target. Every
    // tick would make route finding the most expensive thing in the game,
    // and a guard a second behind still catches somebody slower than they are.
    const val escortRepathInterval = 1.5
    // One-off relief to everybody who watched it happen, and how far that
    // reaches.
    const val escortHappinessRelief = 9.0
    const val escortReliefRadius = 6.0

    // MARK: - Safety inspections

    const val safetyInspectionMinimumRides = 1
    // Park days between visits from the regulator.
    val safetyInspectionGapDays = 2.5..4.5
    // Park minutes of notice before the verdict lands, so a mechanic sent
    // the moment the alert arrives can still save the ride.
    const val safetyInspectionWarning = 60.0
    // Condition at or above which a ride passes. Well below `repairedCondition`
    // so a ride a mechanic has just touched cannot fail.
    const val safetyInspectionPassCondition = 55.0
    // What a failed ride's condition is knocked down to.
    //
    // A notice that shuts a ride while the ride still reads as nearly new is
    // a confusing thing to be handed. Failing an inspection means the
    // inspector found something, so the ride is left in the state the notice
    // describes and a mechanic has real work to do putting it right.
    const val safetyInspectionFailedCondition = 20.0
    // Sim-seconds a mechanic spends lifting an impound, against
    // `repairDuration` for an ordinary breakdown. Longer on purpose: an
    // impound the player never sees because it was cleared in twelve seconds
    // teaches nothing.
    const val impoundRepairDuration = 130.0
    // The fine, charged to maintenance. Comparable to the cost of the mechanic
    // the park should have hired instead.
    const val safetyInspectionFine = 1200.0
    // Rating points a clean bill of health adds, and the park minutes it lasts.
    const val safetyInspectionRatingBonus = 6.0
    const val safetyInspectionBonusMinutes = 360.0

    // MARK: - Tour buses

    const val tourBusMinimumRides = 1
    // Park days between tour buses. Still the most common of the rare
    // events, but a bus every other day stops being an arrival and starts
    // being the way the park fills up.
    val tourBusGapDays = 4.0..7.0
    // How many get off the bus, and the point below which a full park
    // simply turns it round at the gate.
    val tourBusSize = 12..22
    const val tourBusMinimumSize = 6
    // Share of the party that are children, and what each of them has to
    // spend against an ordinary guest.
    const val tourBusChildShare = 0.62
    const val tourBusSpendScale = 0.55

    // MARK: - Achievements

    // Sim-seconds between achievement checks. Every metric is a running total
    // or a live reading, so nothing is missed by looking a few seconds later.
    const val achievementCheckInterval = 5.0

    // MARK: - Boosts

    // Real minutes one advert is worth, and the most that can be banked at
    // once. The ceiling is there so nobody sits through twenty adverts and
    // then never sees the park run at its own pace again.
    const val adBoostMinutes = 10.0
    const val adBoostMaximumMinutes = 60.0
    // Extra arrivals the gate boost brings, as a share.
    const val adVisitorBoost = 0.05
    // How much readier guests are to buy while the spending boost runs.
    const val adSpendBoost = 0.25
    // What a spell of smooth running is worth: rides barely wear, and are
    // far less likely to fail while it lasts.
    const val adWearReduction = 0.85
    const val adBreakdownReduction = 0.75
    // How much less rubbish reaches the ground while the tidy boost runs.
    const val adLitterReduction = 0.80

    // MARK: - Autosave

    const val autosaveInterval = 60.0
}
