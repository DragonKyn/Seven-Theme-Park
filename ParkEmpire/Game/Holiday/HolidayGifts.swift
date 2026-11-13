import Foundation

/// What a daily gift turned out to be.
enum HolidayGift {
    /// Hours of a boost, free, so there is no advert to watch for it.
    case boost(BoostKind, hours: Int)
    /// One of the rides the twelve days hand out, opened without having to win the trial.
    case ride(HolidayReward)
}

/// A present for every day from 20 to 26 December: either ten hours of a
/// boost or one of the three rides the twelve days hand out. A player who
/// already has all three rides is given a boost instead, so a gift is never
/// wasted.
enum HolidayGifts {
    static let boostHours = 10
    static let rideChance = 0.40
    private static let firstDay = 20
    private static let lastDay = 26

    /// The rides a gift can unlock: the ones locked behind a trial.
    static let rideRewardIDs = ["reward.ride.candycoaster", "reward.ride.startopper", "reward.ride.starburst"]

    static func inWindow(_ date: CalendarDate) -> Bool {
        date.month == 12 && (firstDay...lastDay).contains(date.day)
    }

    /// Whether there is a gift to take right now: the window is open and
    /// today's has not been taken.
    static func isAvailable(store: HolidayStore = HolidayStore(), on date: CalendarDate = HolidaySeason.clock()) -> Bool {
        let open = HolidaySeason.override ?? (HolidaySeason.previewBuild ? true : inWindow(date))
        return open && !store.giftClaimed(on: date)
    }

    /// Opens today's gift. Returns nil when there is none to take.
    @MainActor
    static func claim(store: HolidayStore = HolidayStore(),
                      boosts: BoostCenter = .shared,
                      on date: CalendarDate = HolidaySeason.clock()) -> HolidayGift? {
        guard isAvailable(store: store, on: date) else { return nil }
        let locked = rideRewardIDs.filter { !store.isUnlocked($0) }
        let gift: HolidayGift
        if !locked.isEmpty, Double.random(in: 0..<1) < rideChance,
           let id = locked.randomElement(), let reward = HolidayRewards.definition(id) {
            store.unlock(id)
            gift = .ride(reward)
        } else {
            let kind = BoostKind.allCases.randomElement() ?? .bigSpenders
            boosts.grantFor(kind, minutes: Double(boostHours) * 60)
            gift = .boost(kind, hours: boostHours)
        }
        store.markGiftClaimed(on: date)
        return gift
    }
}
