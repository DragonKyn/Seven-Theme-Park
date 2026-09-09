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

    /// Player-controlled. A closed ride keeps its guests but takes no new ones.
    var isOpen: Bool = true
    /// 0-100. Falls as the ride operates and is restored by a mechanic.
    var condition: Double = 100
    /// Set when the ride fails. Only a mechanic clears it.
    var isBroken: Bool = false
    /// Sim-seconds since a mechanic last inspected it. Overdue rides break
    /// noticeably more often.
    var timeSinceInspection: Double = 0
    var totalBreakdowns: Int = 0

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

    var definition: AttractionDefinition? { GameContent.attraction(definitionID) }

    /// Open for business: the player has not closed it and it is not broken.
    var isOperational: Bool { isOpen && !isBroken }

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
        if isBroken { return "Broken down" }
        if !isOpen { return "Closed" }
        return phase == .running ? "Running" : "Loading"
    }

    /// How urgently a mechanic should attend, or nil when nothing is needed.
    var maintenancePriority: Double? {
        if isBroken { return 1000 }
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
        isOpen = container.value(.isOpen, or: true)
        condition = container.value(.condition, or: 100)
        isBroken = container.value(.isBroken, or: false)
        timeSinceInspection = container.value(.timeSinceInspection, or: 0)
        totalBreakdowns = container.value(.totalBreakdowns, or: 0)
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
