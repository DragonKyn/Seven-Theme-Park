import Foundation

/// The authoritative state of one park.
///
/// Simulation systems mutate this; rendering and UI only read from it (or send
/// commands through `GameController`). It is `Codable` in one piece, which is
/// what the save system persists.
final class GameState: Codable {

    // MARK: - Identity

    var parkName: String
    /// Which rules the park runs under. Fixed when the park is created: a
    /// free-build park cannot be turned into a normal one, because a park
    /// built for nothing would make nonsense of the achievements.
    var mode: GameMode = .normal

    // MARK: - World and entities

    var map: ParkMap
    var guests: [Guest] = []
    var attractions: [Attraction] = []
    var facilities: [Facility] = []
    var staff: [Staff] = []
    var scenery: [SceneryItem] = []
    /// Loops, corkscrews and jumps sitting on the player's own track.
    var trackElements: [TrackElement] = []

    // MARK: - Park-level state

    var ledger: Ledger
    var clock = SimulationClock()
    var statistics = ParkStatistics()
    var alerts: [ParkAlert] = []
    var admissionPrice: Double = Balance.defaultAdmissionPrice
    /// The colour every employee's uniform is drawn in. Park-wide rather than
    /// per-employee: it is a decision about the park, not about a person.
    var uniformColour: ParkColour = .teal
    /// The two colours the park paints its own furniture in: lamps, benches,
    /// bins, flags, arches and the clock tower.
    var scheme = ParkScheme()
    /// The colour every piece of coaster track is painted. Park-wide, like the
    /// uniform: repainting one circuit and not the next looked like a mistake
    /// rather than a choice.
    var coasterTrackColour: ParkColour = .amber
    /// How much of the car park outside the gate has been paved, 0 to
    /// `CarParkContent.maxLevel`.
    var carParkLevel: Int = 0
    /// Sim time the next famous visitor may turn up, the boost their post is
    /// currently giving the park, and when it runs out.
    var nextInfluencerAt: Double = Balance.dayLength * 2.5
    var promotionBoost: Double = 0
    var promotionEndsAt: Double = 0
    /// Posts that have happened but not yet been shown to the player. Kept in
    /// the save so one made as the app goes to the background is not lost.
    var pendingPromotions: [PromotionPost] = []
    /// 0-100, eased towards the value `RatingSystem` computes.
    var parkRating: Double = 0
    /// Gates the build menu. Phase 3 will drive this from objectives; for now
    /// everything designed so far is available.
    var unlockLevel: Int = 4
    var rng: SeededGenerator
    /// Highest tier earned for each achievement, keyed by definition id.
    var achievements: [String: Int] = [:]
    /// Tiers earned but not yet celebrated on screen. Persisted so an award
    /// earned as the app goes to the background is not lost.
    var pendingAwards: [AchievementAward] = []

    // MARK: - Scheduling scratch

    /// Fractional guests waiting to be spawned.
    var spawnAccumulator: Double = 0
    var currentArrivalsPerMinute: Double = 0
    var nextRatingUpdate: Double = 0
    /// Which park hour the books were last filed for.
    var lastLedgerSampleIndex: Int = 0
    var nextAchievementCheck: Double = 0
    /// Map generation the tracked rides were last measured against.
    var trackedRideGeneration: Int = -1
    /// Last computed rating breakdown, for the management dashboard.
    var ratingComponents: [String: Double] = [:]
    var lastAlertTimes: [String: Double] = [:]

    // MARK: - Init

    init(parkName: String,
         mode: GameMode = .normal,
         seed: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)) {
        self.parkName = parkName
        self.mode = mode
        self.map = ParkMap(width: Balance.mapWidth, height: Balance.mapHeight)
        self.ledger = Ledger(startingCash: Balance.startingCash)
        self.rng = SeededGenerator(seed: seed)
        self.ledger.isUnlimited = mode.hasUnlimitedMoney
        self.map.applyStartingLayout(pathLength: Balance.startingPathLength)
    }

    /// Lenient decoding: every field falls back to a default, so a save written
    /// by an older build loads with the new systems switched on rather than
    /// failing outright. New phases add a line here and nothing else.
    /// Not marked `required`: `GameState` is final, so there is nothing to
    /// inherit the requirement.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parkName = container.value(.parkName, or: "Park")
        mode = container.value(.mode, or: .normal)
        map = container.value(.map, or: ParkMap(width: Balance.mapWidth, height: Balance.mapHeight))
        guests = container.value(.guests, or: [])
        attractions = container.value(.attractions, or: [])
        facilities = container.value(.facilities, or: [])
        staff = container.value(.staff, or: [])
        scenery = container.value(.scenery, or: [])
        trackElements = container.value(.trackElements, or: [])
        ledger = container.value(.ledger, or: Ledger(startingCash: Balance.startingCash))
        clock = container.value(.clock, or: SimulationClock())
        statistics = container.value(.statistics, or: ParkStatistics())
        alerts = container.value(.alerts, or: [])
        admissionPrice = container.value(.admissionPrice, or: Balance.defaultAdmissionPrice)
        uniformColour = container.value(.uniformColour, or: .teal)
        scheme = container.value(.scheme, or: ParkScheme())
        coasterTrackColour = container.value(.coasterTrackColour, or: .amber)
        carParkLevel = container.value(.carParkLevel, or: 0)
        nextInfluencerAt = container.value(.nextInfluencerAt, or: Balance.dayLength * 2.5)
        promotionBoost = container.value(.promotionBoost, or: 0)
        promotionEndsAt = container.value(.promotionEndsAt, or: 0)
        pendingPromotions = container.value(.pendingPromotions, or: [])
        parkRating = container.value(.parkRating, or: 0)
        unlockLevel = container.value(.unlockLevel, or: 4)
        rng = container.value(.rng, or: SeededGenerator())
        achievements = container.value(.achievements, or: [:])
        pendingAwards = container.value(.pendingAwards, or: [])
        spawnAccumulator = container.value(.spawnAccumulator, or: 0)
        currentArrivalsPerMinute = container.value(.currentArrivalsPerMinute, or: 0)
        nextRatingUpdate = container.value(.nextRatingUpdate, or: 0)
        lastLedgerSampleIndex = container.value(.lastLedgerSampleIndex, or: 0)
        nextAchievementCheck = container.value(.nextAchievementCheck, or: 0)
        trackedRideGeneration = container.value(.trackedRideGeneration, or: -1)
        ratingComponents = container.value(.ratingComponents, or: [:])
        lastAlertTimes = container.value(.lastAlertTimes, or: [:])
        // The mode is the authority; the ledger flag follows it, so a save
        // that predates free build cannot end up half in it.
        ledger.isUnlimited = mode.hasUnlimitedMoney
    }

    /// The railway as it currently stands, derived from the track tiles.
    ///
    /// Built on demand rather than cached: it is wanted when a train unloads
    /// and when the map changes, neither of which is per tick, and a stored
    /// copy would be one more thing that could fall out of step with the map.
    var trackNetwork: TrackNetwork { TrackNetwork.build(map: map, terrains: [.track]) }

    /// The coaster circuits the player has laid. Separate from the railway
    /// because the two never join: a coaster station belongs to its own
    /// circuit rather than to a network of stations.
    var coasterNetwork: TrackNetwork {
        TrackNetwork.build(map: map, terrains: TerrainType.coasterPieces)
    }

    /// Re-measures how much track each custom ride has to run on.
    ///
    /// Called when the map changes rather than every tick. A station with no
    /// circuit reads as zero, which leaves it as the dull shuttle its base
    /// numbers describe until somebody lays it some track.
    /// Nudges the map generation so the renderer rebuilds things derived from
    /// it. Repainting a coaster changes nothing about the park, but the train
    /// is built from the track and has to be made again to pick it up.
    func bumpDecor() {
        map.touch()
    }

    func refreshTrackedRides() {
        guard attractions.contains(where: { $0.baseDefinition?.kind == .custom }) else { return }
        let network = coasterNetwork
        for index in attractions.indices where attractions[index].baseDefinition?.kind == .custom {
            guard let routeIndex = network.routeIndex(touching: attractions[index].rect) else {
                attractions[index].trackLength = 0
                attractions[index].trackThrill = 0
                continue
            }
            let tiles = Set(network.routes[routeIndex].tiles)
            attractions[index].trackLength = tiles.count
            // Elements count for far more than the ground they cover, which is
            // the whole reason to pay for one. An element counts once, however
            // many tiles of the circuit it happens to sit on.
            attractions[index].trackThrill = trackElements.reduce(0) { total, element in
                guard element.rect.coords.contains(where: { tiles.contains($0) }) else {
                    return total
                }
                return total + (element.definition?.thrill ?? 0)
            }
        }
    }

    /// Where a guest riding this station's train should be set down: another
    /// station on the same railway, chosen at random so a network of three is
    /// not just two shuttles. Nil when the station has nowhere to send anyone.
    func transportDestination(from stationID: UUID) -> Attraction? {
        let network = trackNetwork
        guard let station = attraction(id: stationID),
              let route = network.routeIndex(touching: station.rect) else { return nil }

        let others = attractions.filter { candidate in
            candidate.id != stationID
                && candidate.definition?.kind == .transport
                && candidate.isOperational
                && network.routeIndex(touching: candidate.rect) == route
        }
        guard !others.isEmpty else { return nil }
        return others[rng.int(0...(others.count - 1))]
    }

    // MARK: - Lookup

    func attraction(id: UUID) -> Attraction? {
        attractions.first { $0.id == id }
    }

    func facility(id: UUID) -> Facility? {
        facilities.first { $0.id == id }
    }

    func guest(id: UUID) -> Guest? {
        guests.first { $0.id == id }
    }

    func staffMember(id: UUID) -> Staff? {
        staff.first { $0.id == id }
    }

    func staffIndex(id: UUID) -> Int? {
        staff.firstIndex { $0.id == id }
    }

    func attractionIndex(id: UUID) -> Int? {
        attractions.firstIndex { $0.id == id }
    }

    func facilityIndex(id: UUID) -> Int? {
        facilities.firstIndex { $0.id == id }
    }

    func sceneryIndex(id: UUID) -> Int? {
        scenery.firstIndex { $0.id == id }
    }

    func guestIndex(id: UUID) -> Int? {
        guests.firstIndex { $0.id == id }
    }

    /// Name of whatever the target refers to, for thoughts and inspectors.
    func displayName(of target: ParkTarget) -> String {
        switch target {
        case .attraction(let id): return attraction(id: id)?.name ?? "a ride"
        case .facility(let id): return facility(id: id)?.name ?? "a stall"
        case .exit: return "the exit"
        case .wanderSpot: return "the park"
        }
    }

    /// Tiles a guest can stand on to use the target.
    func accessTiles(for target: ParkTarget) -> [GridCoord] {
        switch target {
        case .attraction(let id):
            guard let attraction = attraction(id: id) else { return [] }
            return map.accessTiles(for: attraction.rect)
        case .facility(let id):
            guard let facility = facility(id: id) else { return [] }
            return map.accessTiles(for: facility.rect)
        case .exit:
            return [map.entranceCoord]
        case .wanderSpot(let coord):
            return map.isWalkable(coord) ? [coord] : []
        }
    }

    // MARK: - Alerts

    /// Posts an alert unless one with the same key fired recently.
    func postAlert(_ message: String,
                   severity: AlertSeverity,
                   key: String,
                   target: ParkTarget? = nil,
                   cooldown: Double = 120) {
        if let last = lastAlertTimes[key], clock.simTime - last < cooldown { return }
        lastAlertTimes[key] = clock.simTime
        alerts.append(ParkAlert(message: message,
                                severity: severity,
                                simTime: clock.simTime,
                                target: target,
                                dedupeKey: key))
        if alerts.count > 40 {
            alerts.removeFirst(alerts.count - 40)
        }
    }

    // MARK: - Derived summaries

    var activeGuests: [Guest] {
        guests.filter { $0.isActive }
    }

    /// Extra arrivals a social media post is currently bringing in, as a
    /// share. Zero once it has run its course.
    var activePromotionBoost: Double {
        clock.simTime < promotionEndsAt ? promotionBoost : 0
    }

    /// Park minutes left on the current post, or nil when there is none.
    var promotionMinutesLeft: Double? {
        guard clock.simTime < promotionEndsAt else { return nil }
        return (promotionEndsAt - clock.simTime) / 60
    }

    var guestCount: Int {
        guests.reduce(0) { $0 + ($1.isActive ? 1 : 0) }
    }

    func averageGuestValue(_ keyPath: KeyPath<Guest, Double>) -> Double {
        var total = 0.0
        var count = 0
        for guest in guests where guest.isActive {
            total += guest[keyPath: keyPath]
            count += 1
        }
        guard count > 0 else { return 0 }
        return total / Double(count)
    }

    var averageHappiness: Double {
        averageGuestValue(\.happiness)
    }

    /// Total wages per park day across every employee.
    var dailyPayroll: Double {
        staff.reduce(0.0) { $0 + $1.dailyWage }
    }

    func staffCount(role: StaffRole) -> Int {
        staff.reduce(0) { $0 + ($1.role == role ? 1 : 0) }
    }

    var starRating: Int {
        switch parkRating {
        case ..<20: return 1
        case ..<40: return 2
        case ..<60: return 3
        case ..<80: return 4
        default: return 5
        }
    }
}
