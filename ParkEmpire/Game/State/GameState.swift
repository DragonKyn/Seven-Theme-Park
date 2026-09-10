import Foundation

/// The authoritative state of one park.
///
/// Simulation systems mutate this; rendering and UI only read from it (or send
/// commands through `GameController`). It is `Codable` in one piece, which is
/// what the save system persists.
final class GameState: Codable {

    // MARK: - Identity

    var parkName: String

    // MARK: - World and entities

    var map: ParkMap
    var guests: [Guest] = []
    var attractions: [Attraction] = []
    var facilities: [Facility] = []
    var staff: [Staff] = []
    var scenery: [SceneryItem] = []

    // MARK: - Park-level state

    var ledger: Ledger
    var clock = SimulationClock()
    var statistics = ParkStatistics()
    var alerts: [ParkAlert] = []
    var admissionPrice: Double = Balance.defaultAdmissionPrice
    /// 0-100, eased towards the value `RatingSystem` computes.
    var parkRating: Double = 0
    /// Gates the build menu. Phase 3 will drive this from objectives; for now
    /// everything designed so far is available.
    var unlockLevel: Int = 4
    var rng: SeededGenerator

    // MARK: - Scheduling scratch

    /// Fractional guests waiting to be spawned.
    var spawnAccumulator: Double = 0
    var currentArrivalsPerMinute: Double = 0
    var nextRatingUpdate: Double = 0
    /// Last computed rating breakdown, for the management dashboard.
    var ratingComponents: [String: Double] = [:]
    var lastAlertTimes: [String: Double] = [:]

    // MARK: - Init

    init(parkName: String, seed: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)) {
        self.parkName = parkName
        self.map = ParkMap(width: Balance.mapWidth, height: Balance.mapHeight)
        self.ledger = Ledger(startingCash: Balance.startingCash)
        self.rng = SeededGenerator(seed: seed)
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
        map = container.value(.map, or: ParkMap(width: Balance.mapWidth, height: Balance.mapHeight))
        guests = container.value(.guests, or: [])
        attractions = container.value(.attractions, or: [])
        facilities = container.value(.facilities, or: [])
        staff = container.value(.staff, or: [])
        scenery = container.value(.scenery, or: [])
        ledger = container.value(.ledger, or: Ledger(startingCash: Balance.startingCash))
        clock = container.value(.clock, or: SimulationClock())
        statistics = container.value(.statistics, or: ParkStatistics())
        alerts = container.value(.alerts, or: [])
        admissionPrice = container.value(.admissionPrice, or: Balance.defaultAdmissionPrice)
        parkRating = container.value(.parkRating, or: 0)
        unlockLevel = container.value(.unlockLevel, or: 4)
        rng = container.value(.rng, or: SeededGenerator())
        spawnAccumulator = container.value(.spawnAccumulator, or: 0)
        currentArrivalsPerMinute = container.value(.currentArrivalsPerMinute, or: 0)
        nextRatingUpdate = container.value(.nextRatingUpdate, or: 0)
        ratingComponents = container.value(.ratingComponents, or: [:])
        lastAlertTimes = container.value(.lastAlertTimes, or: [:])
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
        staff.reduce(0.0) { $0 + ($1.definition?.dailyWage ?? 0) }
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
