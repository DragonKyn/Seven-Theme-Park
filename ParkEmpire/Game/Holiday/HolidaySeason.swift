import Foundation

/// A calendar day, without a time or a time zone attached.
struct CalendarDate: Equatable {
    let year: Int
    let month: Int
    let day: Int

    static var today: CalendarDate {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return CalendarDate(year: parts.year ?? 2000, month: parts.month ?? 1, day: parts.day ?? 1)
    }
}

/// The holiday event: 25 November to 5 January, every year, by the player's
/// own date.
///
/// Everything seasonal asks this one place whether it is on. A park that is
/// part-way through a holiday trial keeps the season on for itself even if the
/// calendar rolls over, so a trial begun in time can always be finished.
enum HolidaySeason {
    static let startMonth = 11
    static let startDay = 25
    static let endMonth = 1
    static let endDay = 5

    /// Developer-only: forces the season on or off. Nil follows the calendar.
    /// Never set from the game's own screens. A build made for sideloading
    /// can switch it on at compile time (see `previewBuild`).
    static var override: Bool?

    /// Where today's date comes from; replaced in tests.
    static var clock: () -> CalendarDate = { CalendarDate.today }

    /// True only in a build made for trying the event out of season. The App
    /// Store build never sets it.
    static var previewBuild: Bool {
        #if HOLIDAY_PREVIEW
        return true
        #else
        return false
        #endif
    }

    static func inWindow(_ date: CalendarDate) -> Bool {
        switch date.month {
        case 11: return date.day >= startDay
        case 12: return true
        case 1: return date.day <= endDay
        default: return false
        }
    }

    static func isActive(on date: CalendarDate = clock()) -> Bool {
        if let override { return override }
        if previewBuild { return true }
        return inWindow(date)
    }

    /// Whether a park should treat the season as on: the calendar, or a
    /// holiday trial it is part-way through.
    static func isActive(for state: GameState) -> Bool {
        isActive() || state.trial?.series == .holiday
    }

    /// The year the event began in, so 1 to 5 January belongs to the year before.
    static func eventYear(on date: CalendarDate = clock()) -> Int {
        date.month <= endMonth ? date.year - 1 : date.year
    }

    /// Whole days left in the event including today, or 0 outside it.
    static func daysLeft(on date: CalendarDate = clock()) -> Int {
        guard isActive(on: date) else { return 0 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let endYear = date.month == 1 ? date.year : date.year + 1
        guard let end = calendar.date(from: DateComponents(year: endYear, month: endMonth, day: endDay)),
              let today = calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day)) else {
            return 1
        }
        let days = Int((end.timeIntervalSince(today) / 86_400).rounded()) + 1
        return max(1, days)
    }

    static let datesLabel = "25 November to 5 January"
    static let shortDatesLabel = "Nov 25 to Jan 5"
}

/// What kind of thing a holiday trial hands over.
enum HolidayRewardKind: String {
    case decoration
    case makeover
    case ride
    case performer
}

/// One thing a holiday trial unlocks. Earned once, kept for good, and usable
/// whenever the event is on.
struct HolidayReward: Identifiable, Equatable {
    let id: String
    let kind: HolidayRewardKind
    let title: String
    let detail: String
    let symbolName: String
    /// The catalogue ids (rides, decorations) or act this opens.
    let opens: [String]
}

enum HolidayRewards {
    static let all: [HolidayReward] = [
        HolidayReward(id: "reward.giftstack", kind: .decoration, title: "Gift Stack",
                      detail: "A pile of wrapped presents for the walkway.",
                      symbolName: "gift.fill", opens: ["scenery.xmas.gifts"]),
        HolidayReward(id: "reward.lightpole", kind: .decoration, title: "String-Light Pole",
                      detail: "A tall pole hung with warm lights.",
                      symbolName: "lightbulb.fill", opens: ["scenery.xmas.lights"]),
        HolidayReward(id: "reward.candycane", kind: .decoration, title: "Candy Cane Post",
                      detail: "A giant striped cane to mark a corner.",
                      symbolName: "heart.fill", opens: ["scenery.xmas.candycane"]),
        HolidayReward(id: "reward.fireworks", kind: .decoration, title: "Fireworks Stand",
                      detail: "A rack of rockets that never quite goes off.",
                      symbolName: "sparkles", opens: ["scenery.newyear.fireworks"]),
        HolidayReward(id: "reward.countdown", kind: .decoration, title: "Countdown Clock",
                      detail: "A tall clock counting down to midnight.",
                      symbolName: "clock.fill", opens: ["scenery.newyear.clock"]),

        HolidayReward(id: "reward.makeover.gentle", kind: .makeover, title: "Gentle Rides Makeover",
                      detail: "Snow, ribbon and fairy lights for the Carousel, Wonder Putt, Haunted Manor and the slow rides.",
                      symbolName: "paintbrush.fill", opens: HolidayMakeovers.ids(for: .gentle)),
        HolidayReward(id: "reward.makeover.family", kind: .makeover, title: "Family Rides Makeover",
                      detail: "A festive coat for the Teacups, Bumper Cars, Carpet Slide, Go Karts and the family rides.",
                      symbolName: "paintbrush.fill", opens: HolidayMakeovers.ids(for: .family)),
        HolidayReward(id: "reward.makeover.thrill", kind: .makeover, title: "Thrill Rides Makeover",
                      detail: "Frosted towers and tinsel track for the Galleon, Sky Plunge, Sapling Coaster and the big thrills.",
                      symbolName: "paintbrush.fill", opens: HolidayMakeovers.ids(for: .thrill)),
        HolidayReward(id: "reward.makeover.water", kind: .makeover, title: "Water Rides Makeover",
                      detail: "Icicles and lanterns for the flume, the rapids, the cruises and the pool.",
                      symbolName: "paintbrush.fill", opens: HolidayMakeovers.ids(for: .water)),

        HolidayReward(id: "reward.ride.candycoaster", kind: .ride, title: "Candy Cane Coaster",
                      detail: "A coaster on candy-striped track.",
                      symbolName: "figure.walk", opens: ["ride.xmas.candycoaster"]),
        HolidayReward(id: "reward.ride.startopper", kind: .ride, title: "Star Topper Drop",
                      detail: "A drop tower dressed as a tree, with a star on top.",
                      symbolName: "star.fill", opens: ["ride.xmas.startopper"]),
        HolidayReward(id: "reward.ride.starburst", kind: .ride, title: "Starburst Coaster",
                      detail: "The New Year finale: a coaster that ends in fireworks.",
                      symbolName: "sparkle", opens: ["ride.newyear.starburst"]),

        HolidayReward(id: "reward.snowcone", kind: .decoration, title: "Snow Cone Cart",
                      detail: "A cart that sells cones of shaved ice with a choice of syrups. Takes the usual shop upgrades.",
                      symbolName: "snowflake", opens: ["shop.xmas.snowcone"]),
        HolidayReward(id: "reward.snowfamily", kind: .decoration, title: "Snow Family",
                      detail: "A whole family of snowmen in matching scarves.",
                      symbolName: "person.3.fill", opens: ["scenery.xmas.snowfamily"]),

        HolidayReward(id: "reward.performer.missus", kind: .performer, title: "Mrs. Claus",
                      detail: "A new entertainer: bakes cookies for anybody who looks hungry.",
                      symbolName: "person.fill", opens: ["act.missus"])
    ]

    private static let byID: [String: HolidayReward] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func definition(_ id: String) -> HolidayReward? { byID[id] }

    /// Which reward, if any, is needed before this catalogue entry or act can be used.
    static func requiredFor(_ opens: String) -> String? {
        all.first { $0.opens.contains(opens) }?.id
    }
}

/// Which family of existing rides a makeover reward covers.
enum MakeoverSet: String, CaseIterable {
    case gentle
    case family
    case thrill
    case water
}

enum HolidayMakeovers {
    private static let sets: [MakeoverSet: [String]] = [
        .gentle: ["ride.carousel", "ride.minigolf", "ride.hauntedhouse", "ride.ferriswheel", "ride.mirrormaze",
                  "ride.skygliders", "ride.lanterncruise"],
        .family: ["ride.teacups", "ride.bumpercars", "ride.carpetslide", "ride.gokarts.small", "ride.skyswings"],
        .thrill: ["ride.pirateship", "ride.droptower", "ride.minicoaster", "ride.gokarts.medium", "ride.gokarts.large",
                  "ride.slingshot", "ride.bigcoaster", "ride.treetopzip", "ride.gravityhammer", "coaster.station"],
        .water: ["ride.logflume", "ride.fishingboats", "ride.bumperboats", "ride.wavepool", "ride.riverrapids"]
    ]

    static func ids(for set: MakeoverSet) -> [String] { sets[set] ?? [] }

    /// The reward that has to be earned before this ride can be given the makeover.
    static func rewardFor(rideID: String) -> String? {
        for set in MakeoverSet.allCases where ids(for: set).contains(rideID) {
            return "reward.makeover.\(set.rawValue)"
        }
        return nil
    }
}

/// What the player has earned from the holiday event, and whether they have
/// seen this year's announcement. Kept in `UserDefaults` with the rest of what
/// outlives a single park, so it is shared by every park.
struct HolidayStore {
    private let defaults: UserDefaults
    private static let unlockKey = "holiday.unlocks"
    private static let doneKey = "holiday.done"
    private static let hiddenKey = "holiday.hideYear"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Reward ids earned, ever.
    var unlocked: Set<String> {
        Set((defaults.stringArray(forKey: Self.unlockKey)) ?? [])
    }

    func isUnlocked(_ rewardID: String) -> Bool {
        unlocked.contains(rewardID)
    }

    /// Whether the player may use a catalogue entry or act: free ones always,
    /// locked ones once earned.
    func canUse(_ opens: String) -> Bool {
        guard let needed = HolidayRewards.requiredFor(opens) else { return true }
        return isUnlocked(needed)
    }

    private var completedYears: [String: Int] {
        (defaults.dictionary(forKey: Self.doneKey) as? [String: Int]) ?? [:]
    }

    /// Whether this holiday trial was beaten during this year's event.
    func isCompleted(_ trial: TrialDefinition, year: Int = HolidaySeason.eventYear()) -> Bool {
        completedYears[trial.id] == year
    }

    func completedCount(year: Int = HolidaySeason.eventYear()) -> Int {
        TrialContent.holiday.filter { isCompleted($0, year: year) }.count
    }

    /// Records a win and hands over the rewards. Returns only the ones earned
    /// for the first time, so the result card can announce them once.
    @discardableResult
    func recordWin(_ trial: TrialDefinition, year: Int = HolidaySeason.eventYear()) -> [HolidayReward] {
        var done = completedYears
        done[trial.id] = year
        defaults.set(done, forKey: Self.doneKey)

        let fresh = trial.rewardIDs.compactMap { HolidayRewards.definition($0) }.filter { !isUnlocked($0.id) }
        if !fresh.isEmpty {
            defaults.set(Array(unlocked.union(fresh.map { $0.id })).sorted(), forKey: Self.unlockKey)
        }
        return fresh
    }

    /// Whether a holiday trial can be started: any reward it needs is held.
    func isOpen(_ trial: TrialDefinition) -> Bool {
        guard let needed = trial.needsRewardID else { return true }
        return isUnlocked(needed)
    }

    // MARK: - Daily gifts

    private static let giftDayKey = "holiday.giftDay"
    private static let giftCountKey = "holiday.giftCount"

    private func dayStamp(_ date: CalendarDate) -> String { "\(date.year)-\(date.month)-\(date.day)" }

    /// Whether today's gift has been taken.
    func giftClaimed(on date: CalendarDate = HolidaySeason.clock()) -> Bool {
        defaults.string(forKey: Self.giftDayKey) == dayStamp(date)
    }

    /// How many daily gifts the player has taken, over the years.
    var giftsTaken: Int { defaults.integer(forKey: Self.giftCountKey) }

    func markGiftClaimed(on date: CalendarDate) {
        defaults.set(dayStamp(date), forKey: Self.giftDayKey)
        defaults.set(giftsTaken + 1, forKey: Self.giftCountKey)
    }

    /// Hands over a reward outright, outside any trial. Returns false if it was already held.
    @discardableResult
    func unlock(_ rewardID: String) -> Bool {
        guard !isUnlocked(rewardID) else { return false }
        defaults.set(Array(unlocked.union([rewardID])).sorted(), forKey: Self.unlockKey)
        return true
    }

    /// The year the announcement was last put away for, or nil.
    private var hiddenYear: Int? {
        defaults.object(forKey: Self.hiddenKey) as? Int
    }

    /// Whether the main menu should show the announcement: in season, and not
    /// put away for this year's event.
    func shouldAnnounce(on date: CalendarDate = HolidaySeason.clock()) -> Bool {
        HolidaySeason.isActive(on: date) && hiddenYear != HolidaySeason.eventYear(on: date)
    }

    func hideAnnouncement(on date: CalendarDate = HolidaySeason.clock()) {
        defaults.set(HolidaySeason.eventYear(on: date), forKey: Self.hiddenKey)
    }
}
