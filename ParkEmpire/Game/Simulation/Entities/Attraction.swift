import Foundation

enum RidePhase: String, Codable {
    /// Doors open, taking guests from the queue.
    case loading
    /// Cycle in progress.
    case running
}

/// A placed ride. Static numbers live in `AttractionDefinition`; this holds
/// only what changes while the park runs.
struct Attraction: Codable, Identifiable {
    let id: UUID
    let definitionID: String
    var name: String
    var origin: GridCoord
    var size: GridSize
    /// Quarter turns clockwise, 0 to 3. `size` is already the turned
    /// footprint, so only the artwork needs to know about this.
    var rotation: Int = 0

    /// Player-controlled. A closed ride keeps its guests but takes no new ones.
    var isOpen: Bool = true
    /// 0-100. Falls as the ride operates and is restored by a mechanic.
    var condition: Double = 100
    /// Set when the ride fails. Only a mechanic clears it.
    var isBroken: Bool = false
    /// Shut by a safety inspector. Kept apart from `isOpen`, which belongs to
    /// the player: an inspector must not silently flip a switch the player
    /// owns, and putting it right is a mechanic's job rather than a tap.
    var isImpounded: Bool = false
    /// Sim-seconds since a mechanic last inspected it. Overdue rides break
    /// noticeably more often.
    var timeSinceInspection: Double = 0
    var totalBreakdowns: Int = 0
    /// Purchased upgrade levels, keyed by `RideUpgradeKind.rawValue`. Stored
    /// by raw string so a build that drops an upgrade kind still decodes.
    var upgrades: [String: Int] = [:]
    /// Tiles of the player's own track this station runs on. Only means
    /// anything for a custom ride, and kept up to date by the simulation
    /// whenever the map changes.
    var trackLength: Int = 0
    /// What the special pieces on that track are worth.
    var trackThrill: Double = 0
    /// What the player painted the train, and what shape they chose for it.
    /// Cosmetic, and only ever read for a custom ride.
    var livery: ParkColour = .red
    var carStyle: CoasterCarStyle = .classic
    /// A colour the player chose for this one building, or nil to leave it in
    /// the colours it was designed in.
    var tint: ParkColour?

    var phase: RidePhase = .loading
    var phaseTimer: Double = 0

    var queue: [UUID] = []
    var riders: [UUID] = []

    var guestsToday: Int = 0
    var totalGuests: Int = 0
    /// Running sum/count of rider happiness deltas, for a satisfaction score.
    var satisfactionSum: Double = 0
    var satisfactionCount: Int = 0

    var rect: GridRect { GridRect(origin: origin, size: size) }

    /// The ride as the catalogue describes it, before anything was bought
    /// for it. Only upgrade pricing should need this.
    var baseDefinition: AttractionDefinition? { GameContent.attraction(definitionID) }

    /// The ride as it actually runs, upgrades included.
    var definition: AttractionDefinition? {
        baseDefinition?.applying(upgrades, trackLength: trackLength, trackThrill: trackThrill)
    }

    func upgradeLevel(_ kind: RideUpgradeKind) -> Int { upgrades[kind.rawValue] ?? 0 }

    /// Open for business: the player has not closed it, it is not broken, and
    /// no inspector has shut it.
    var isOperational: Bool { isOpen && !isBroken && !isImpounded }

    var isInspectionOverdue: Bool { timeSinceInspection > Balance.inspectionInterval }

    var averageSatisfaction: Double? {
        guard satisfactionCount > 0 else { return nil }
        return satisfactionSum / Double(satisfactionCount)
    }

    /// Sim-seconds a guest joining the back of the queue should expect to wait.
    func estimatedWait(definition: AttractionDefinition) -> Double {
        let cycleTime = definition.loadDuration + definition.rideDuration
        let batchesAhead = Double((queue.count + definition.capacity - 1) / definition.capacity)
        let currentCycleRemaining = phase == .running
            ? max(0, definition.rideDuration - phaseTimer)
            : 0
        return batchesAhead * cycleTime + currentCycleRemaining
    }

    var statusDescription: String {
        if isImpounded { return "Shut by the inspector" }
        if isBroken { return "Broken down" }
        if !isOpen { return "Closed" }
        return phase == .running ? "Running" : "Loading"
    }

    /// How urgently a mechanic should attend, or nil when nothing is needed.
    var maintenancePriority: Double? {
        if isBroken { return 1000 }
        if isImpounded { return 900 }
        if isInspectionOverdue { return 100 + (100 - condition) }
        return nil
    }
}

extension Attraction {
    /// Lenient decoding so saves written before maintenance existed still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        definitionID = container.value(.definitionID, or: "")
        name = container.value(.name, or: "Ride")
        origin = container.value(.origin, or: GridCoord.zero)
        size = container.value(.size, or: GridSize.single)
        rotation = container.value(.rotation, or: 0)
        isOpen = container.value(.isOpen, or: true)
        condition = container.value(.condition, or: 100)
        isBroken = container.value(.isBroken, or: false)
        isImpounded = container.value(.isImpounded, or: false)
        timeSinceInspection = container.value(.timeSinceInspection, or: 0)
        totalBreakdowns = container.value(.totalBreakdowns, or: 0)
        upgrades = container.value(.upgrades, or: [:])
        trackLength = container.value(.trackLength, or: 0)
        trackThrill = container.value(.trackThrill, or: 0)
        livery = container.value(.livery, or: .red)
        carStyle = container.value(.carStyle, or: .classic)
        tint = container.optionalValue(.tint)
        phase = container.value(.phase, or: .loading)
        phaseTimer = container.value(.phaseTimer, or: 0)
        queue = container.value(.queue, or: [])
        riders = container.value(.riders, or: [])
        guestsToday = container.value(.guestsToday, or: 0)
        totalGuests = container.value(.totalGuests, or: 0)
        satisfactionSum = container.value(.satisfactionSum, or: 0)
        satisfactionCount = container.value(.satisfactionCount, or: 0)
    }
}
