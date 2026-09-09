import Foundation

/// One guest currently occupying a service slot (a till, a stall, a seat).
struct ServiceSlot: Codable {
    var guestID: UUID
    var remaining: Double
}

/// A placed shop, restroom, bench or bin.
struct Facility: Codable, Identifiable {
    let id: UUID
    let definitionID: String
    var name: String
    var origin: GridCoord
    var size: GridSize

    var isOpen: Bool = true
    /// Selling price. Zero for facilities that do not sell anything.
    var price: Double

    var queue: [UUID] = []
    var slots: [ServiceSlot] = []

    /// 0-100. Restrooms get dirty with use, bins fill up with rubbish.
    /// Janitors bring it back down; nothing else does.
    var soiling: Double = 0
    var timesServiced: Int = 0

    var customersToday: Int = 0
    var totalCustomers: Int = 0
    var revenueToday: Double = 0
    var totalRevenue: Double = 0
    var totalCost: Double = 0
    /// Rolling average of how fairly guests judged the price (0-1).
    var sentimentSum: Double = 0
    var sentimentCount: Int = 0

    var rect: GridRect { GridRect(origin: origin, size: size) }

    var definition: FacilityDefinition? { GameContent.facility(definitionID) }

    var priceSentiment: Double? {
        guard sentimentCount > 0 else { return nil }
        return sentimentSum / Double(sentimentCount)
    }

    func estimatedWait(definition: FacilityDefinition) -> Double {
        let capacity = max(1, definition.simultaneousCapacity)
        let batchesAhead = Double((queue.count + capacity - 1) / capacity)
        return batchesAhead * definition.serviceDuration
    }

    var hasFreeSlot: Bool {
        guard let definition else { return false }
        return slots.count < definition.simultaneousCapacity
    }

    /// A bin this full cannot take any more rubbish.
    var isFull: Bool {
        definition?.kind == .bin && soiling >= 100
    }

    /// Unpleasant enough that guests notice.
    var isDirty: Bool {
        soiling > Balance.dirtyFacilityThreshold
    }

    /// Guests will not use a restroom in this state.
    var isUnusable: Bool {
        guard let kind = definition?.kind else { return false }
        switch kind {
        case .bathroom: return soiling > 92
        case .bin: return soiling >= 100
        default: return false
        }
    }

    /// How urgently a janitor should attend to this, or nil when it is fine.
    var servicingPriority: Double? {
        guard definition?.kind.needsServicing == true else { return nil }
        guard soiling > Balance.dirtyFacilityThreshold * 0.6 else { return nil }
        return soiling
    }
}

extension Facility {
    /// Lenient decoding so saves written before cleanliness existed still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        definitionID = container.value(.definitionID, or: "")
        name = container.value(.name, or: "Facility")
        origin = container.value(.origin, or: GridCoord.zero)
        size = container.value(.size, or: GridSize.single)
        isOpen = container.value(.isOpen, or: true)
        price = container.value(.price, or: 0)
        queue = container.value(.queue, or: [])
        slots = container.value(.slots, or: [])
        soiling = container.value(.soiling, or: 0)
        timesServiced = container.value(.timesServiced, or: 0)
        customersToday = container.value(.customersToday, or: 0)
        totalCustomers = container.value(.totalCustomers, or: 0)
        revenueToday = container.value(.revenueToday, or: 0)
        totalRevenue = container.value(.totalRevenue, or: 0)
        totalCost = container.value(.totalCost, or: 0)
        sentimentSum = container.value(.sentimentSum, or: 0)
        sentimentCount = container.value(.sentimentCount, or: 0)
    }
}
