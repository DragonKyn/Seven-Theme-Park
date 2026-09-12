import Foundation

/// Read-only views of the simulation, built for SwiftUI.
///
/// Keeping these separate means views never hold on to live entities and never
/// mutate the park by accident.

// MARK: - HUD

struct HUDSnapshot {
    var parkName = AppInfo.gameName
    var cash: Double = 0
    var guestCount = 0
    var averageHappiness: Double = 0
    var parkRating: Double = 0
    var starRating = 1
    var clockLabel = "09:00"
    var day = 1
    var speed: GameSpeed = .normal
    var admissionPrice: Double = Balance.defaultAdmissionPrice
    var arrivalsPerMinute: Double = 0
    var todayProfit: Double = 0
    var mode: GameMode = .normal

    init() {}

    init(state: GameState) {
        parkName = state.parkName
        cash = state.ledger.cash
        guestCount = state.guestCount
        averageHappiness = state.averageHappiness
        parkRating = state.parkRating
        starRating = state.starRating
        clockLabel = state.clock.clockLabel
        day = state.clock.day
        speed = state.clock.speed
        admissionPrice = state.admissionPrice
        arrivalsPerMinute = state.currentArrivalsPerMinute
        todayProfit = state.ledger.today.profit
        mode = state.mode
    }
}

// MARK: - Guest inspector

struct GuestDetail: Identifiable {
    let id: UUID
    let name: String
    let ageCategory: String
    let happiness: Double
    let cash: Double
    let hunger: Double
    let thirst: Double
    let energy: Double
    let bathroomNeed: Double
    let nausea: Double
    let activityText: String
    let thoughts: [GuestThought]
    let ridesRidden: Int
    let purchases: Int
    let moneySpent: Double
    let timeInPark: Double
    let thrillPreference: Double
    let patience: Double
    let spending: Double
    /// What they are carrying home from the midway, if anything.
    let prizeName: String?
    let prizesWon: Int

    init(guest: Guest, state: GameState) {
        id = guest.id
        name = guest.name
        ageCategory = guest.ageCategory.displayName
        happiness = guest.happiness
        cash = guest.cash
        hunger = guest.hunger
        thirst = guest.thirst
        energy = guest.energy
        bathroomNeed = guest.bathroomNeed
        nausea = guest.nausea
        thoughts = Array(guest.thoughts.reversed())
        ridesRidden = guest.ridesRidden
        purchases = guest.purchases
        moneySpent = guest.moneySpent
        timeInPark = guest.timeInPark
        thrillPreference = guest.personality.thrillPreference
        patience = guest.personality.patience
        spending = guest.personality.spending
        prizeName = guest.prize?.displayName
        prizesWon = guest.prizesWon
        activityText = GuestDetail.describe(activity: guest.activity, state: state)
    }

    private static func describe(activity: GuestActivity, state: GameState) -> String {
        switch activity {
        case .arriving:
            return "Arriving at the park"
        case .exploring:
            return "Looking for something to do"
        case .walking(let target):
            switch target {
            case .exit: return "Heading for the exit"
            case .wanderSpot: return "Wandering the paths"
            default: return "Walking to \(state.displayName(of: target))"
            }
        case .queueing(let target):
            return "Queueing for \(state.displayName(of: target))"
        case .engaged(let target):
            return "Enjoying \(state.displayName(of: target))"
        case .departed:
            return "Left the park"
        }
    }

    var timeInParkText: String {
        let minutes = Int(timeInPark) / 60
        let seconds = Int(timeInPark) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Attraction inspector

struct AttractionDetail: Identifiable {
    /// One upgrade track on one ride, with what it would cost to take the
    /// next step. A nil cost means it is already at its maximum.
    struct UpgradeLine: Identifiable {
        let id: String
        let kind: RideUpgradeKind
        let displayName: String
        let summary: String
        let symbolName: String
        let level: Int
        let maxLevel: Int
        let cost: Double?
    }

    let id: UUID
    let name: String
    let typeName: String
    let status: String
    let isOpen: Bool
    let condition: Double
    let queueLength: Int
    let estimatedWait: Double
    let capacity: Int
    let rideDuration: Double
    let excitement: Double
    let nauseaRating: Double
    let guestsToday: Int
    let totalGuests: Int
    let satisfaction: Double?
    let operatingCostPerCycle: Double
    let upgrades: [UpgradeLine]
    /// Set for a ride the player laid their own track for, which is the only
    /// kind that can be repainted.
    let isCustomCoaster: Bool
    let livery: ParkColour
    let carStyle: CoasterCarStyle
    let trackLength: Int

    init(attraction: Attraction) {
        isCustomCoaster = attraction.baseDefinition?.kind == .custom
        livery = attraction.livery
        carStyle = attraction.carStyle
        trackLength = attraction.trackLength
        let ridePrice = attraction.baseDefinition?.purchasePrice ?? 0
        upgrades = UpgradeContent.rideUpgrades.map { upgrade in
            let level = attraction.upgradeLevel(upgrade.kind)
            let next = level + 1
            return UpgradeLine(
                id: upgrade.kind.rawValue,
                kind: upgrade.kind,
                displayName: upgrade.displayName,
                summary: upgrade.summary,
                symbolName: upgrade.symbolName,
                level: level,
                maxLevel: upgrade.maxLevel,
                cost: next <= upgrade.maxLevel
                    ? upgrade.cost(forLevel: next, ridePrice: ridePrice)
                    : nil)
        }

        id = attraction.id
        name = attraction.name
        isOpen = attraction.isOpen
        status = attraction.statusDescription
        condition = attraction.condition
        queueLength = attraction.queue.count
        guestsToday = attraction.guestsToday
        totalGuests = attraction.totalGuests
        satisfaction = attraction.averageSatisfaction

        if let definition = attraction.definition {
            typeName = definition.displayName
            capacity = definition.capacity
            rideDuration = definition.rideDuration
            excitement = definition.excitement
            nauseaRating = definition.nausea
            operatingCostPerCycle = definition.operatingCostPerCycle
            estimatedWait = attraction.estimatedWait(definition: definition)
        } else {
            typeName = "Unknown"
            capacity = 0
            rideDuration = 0
            excitement = 0
            nauseaRating = 0
            operatingCostPerCycle = 0
            estimatedWait = 0
        }
    }

    var waitText: String {
        let minutes = Int(estimatedWait) / 60
        let seconds = Int(estimatedWait) % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }

    var satisfactionText: String {
        guard let satisfaction else { return "No data yet" }
        return String(format: "%.0f%%", SimMath.clamp(satisfaction / 20 * 100))
    }
}

// MARK: - Facility inspector

struct FacilityDetail: Identifiable {
    let id: UUID
    let name: String
    let typeName: String
    let sellsGoods: Bool
    let isOpen: Bool
    let price: Double
    let unitCost: Double
    let referencePrice: Double
    let queueLength: Int
    let customersToday: Int
    let totalCustomers: Int
    /// Prizes handed over, which is the only thing a booth's owner watches.
    let prizesGiven: Int
    let isGame: Bool
    let revenueToday: Double
    let totalRevenue: Double
    let totalCost: Double
    let sentiment: Double?

    init(facility: Facility) {
        id = facility.id
        name = facility.name
        isOpen = facility.isOpen
        price = facility.price
        queueLength = facility.queue.count
        customersToday = facility.customersToday
        totalCustomers = facility.totalCustomers
        prizesGiven = facility.prizesGiven
        revenueToday = facility.revenueToday
        totalRevenue = facility.totalRevenue
        totalCost = facility.totalCost
        sentiment = facility.priceSentiment

        if let definition = facility.definition {
            typeName = definition.displayName
            isGame = definition.kind == .game
            sellsGoods = definition.kind.sellsGoods
            unitCost = definition.unitCost
            referencePrice = definition.referencePrice
        } else {
            typeName = "Unknown"
            isGame = false
            sellsGoods = false
            unitCost = 0
            referencePrice = 0
        }
    }

    var profitPerSale: Double { price - unitCost }

    var sentimentText: String {
        guard let sentiment else { return "No sales yet" }
        return GuestEconomics.sentimentLabel(sentiment)
    }
}

// MARK: - Staff inspector

struct StaffDetail: Identifiable {
    let id: UUID
    let name: String
    let roleName: String
    let symbolName: String
    let activityText: String
    let tasksCompleted: Int
    let dailyWage: Double
    let trainingLevel: Int
    let maxTrainingLevel: Int
    let trainingTitle: String
    /// Nil once the employee has had all the training there is.
    let trainingCost: Double?

    init(staff: Staff, state: GameState) {
        trainingLevel = staff.trainingLevel
        maxTrainingLevel = UpgradeContent.staffTraining.maxLevel
        trainingTitle = staff.trainingTitle
        let nextLevel = staff.trainingLevel + 1
        trainingCost = nextLevel <= UpgradeContent.staffTraining.maxLevel
            ? UpgradeContent.staffTraining.cost(forLevel: nextLevel,
                                                hiringCost: staff.definition?.hiringCost ?? 0)
            : nil

        id = staff.id
        name = staff.name
        roleName = staff.definition?.displayName ?? staff.role.rawValue.capitalized
        symbolName = staff.definition?.symbolName ?? "person.fill"
        tasksCompleted = staff.tasksCompleted
        dailyWage = staff.dailyWage
        activityText = StaffDetail.describe(staff.activity, state: state)
    }

    static func describe(_ activity: StaffActivity, state: GameState) -> String {
        switch activity {
        case .idle:
            return "Looking for something to do"
        case .travelling(let job):
            return "On the way to \(describe(job: job, state: state))"
        case .working(let job):
            let text = describe(job: job, state: state)
            return text.prefix(1).uppercased() + String(text.dropFirst())
        }
    }

    private static func describe(job: StaffJob, state: GameState) -> String {
        switch job {
        case .cleanLitter:
            return "sweeping up litter"
        case .serviceFacility(let id):
            guard let facility = state.facility(id: id) else { return "servicing a facility" }
            let verb = facility.definition?.kind.servicingVerb.lowercased() ?? "cleaning"
            return "\(verb) \(facility.name)"
        case .repairRide(let id):
            return "repairing \(state.attraction(id: id)?.name ?? "a ride")"
        case .inspectRide(let id):
            return "inspecting \(state.attraction(id: id)?.name ?? "a ride")"
        case .entertain:
            return "entertaining the crowd"
        case .patrol:
            return "keeping an eye on things"
        }
    }
}

// MARK: - Finance

struct FinanceSnapshot {
    struct Line: Identifiable {
        let id: String
        let label: String
        let amount: Double
    }

    let todayRevenue: [Line]
    let todayExpenses: [Line]
    let lifetimeRevenue: [Line]
    let lifetimeExpenses: [Line]
    let todayTotalRevenue: Double
    let todayTotalExpenses: Double
    let todayProfit: Double
    let lifetimeTotalRevenue: Double
    let lifetimeTotalExpenses: Double
    let lifetimeProfit: Double
    let yesterdayProfit: Double?

    init(ledger: Ledger) {
        todayRevenue = FinanceSnapshot.revenueLines(ledger.today)
        todayExpenses = FinanceSnapshot.expenseLines(ledger.today)
        lifetimeRevenue = FinanceSnapshot.revenueLines(ledger.lifetime)
        lifetimeExpenses = FinanceSnapshot.expenseLines(ledger.lifetime)
        todayTotalRevenue = ledger.today.totalRevenue
        todayTotalExpenses = ledger.today.totalExpenses
        todayProfit = ledger.today.profit
        lifetimeTotalRevenue = ledger.lifetime.totalRevenue
        lifetimeTotalExpenses = ledger.lifetime.totalExpenses
        lifetimeProfit = ledger.lifetime.profit
        yesterdayProfit = ledger.yesterday?.profit
    }

    private static func revenueLines(_ period: LedgerPeriod) -> [Line] {
        RevenueCategory.allCases.map {
            Line(id: $0.rawValue, label: $0.displayName, amount: period.amount(for: $0))
        }
    }

    private static func expenseLines(_ period: LedgerPeriod) -> [Line] {
        ExpenseCategory.allCases.map {
            Line(id: $0.rawValue, label: $0.displayName, amount: period.amount(for: $0))
        }
    }
}

// MARK: - Management dashboard

struct DashboardSnapshot {
    struct RatingLine: Identifiable {
        let id: String
        let weight: Double
        let value: Double
    }

    struct RoleCount: Identifiable {
        let id: String
        let count: Int
    }

    let cash: Double
    let guestCount: Int
    let parkRating: Double
    let starRating: Int
    let todayProfit: Double
    let averageHappiness: Double
    let averageHunger: Double
    let averageThirst: Double
    let averageEnergy: Double
    let commonComplaint: String?
    let arrivalsPerMinute: Double

    let attractionCount: Int
    let averageQueueLength: Double
    let closedAttractions: Int
    let mostPopular: String?
    let leastPopular: String?

    let facilityCount: Int
    let brokenRides: Int
    let cleanliness: Double
    let litteredTiles: Int
    let beauty: Double
    let sceneryCount: Int

    let staffCount: Int
    let dailyPayroll: Double
    let staffOnTask: Int
    let staffByRole: [RoleCount]

    let ratingLines: [RatingLine]
    let finance: FinanceSnapshot

    init(state: GameState, ratingComponents: [RatingSystem.Component]) {
        cash = state.ledger.cash
        guestCount = state.guestCount
        parkRating = state.parkRating
        starRating = state.starRating
        todayProfit = state.ledger.today.profit
        averageHappiness = state.averageHappiness
        averageHunger = state.averageGuestValue(\.hunger)
        averageThirst = state.averageGuestValue(\.thirst)
        averageEnergy = state.averageGuestValue(\.energy)
        commonComplaint = state.statistics.commonComplaint
        arrivalsPerMinute = state.currentArrivalsPerMinute

        attractionCount = state.attractions.count
        closedAttractions = state.attractions.filter { !$0.isOpen }.count
        let queueTotal = state.attractions.reduce(0) { $0 + $1.queue.count }
        averageQueueLength = state.attractions.isEmpty
            ? 0
            : Double(queueTotal) / Double(state.attractions.count)

        let ranked = state.attractions.sorted { $0.totalGuests > $1.totalGuests }
        mostPopular = ranked.first.map { "\($0.name) (\($0.totalGuests))" }
        leastPopular = ranked.count > 1 ? ranked.last.map { "\($0.name) (\($0.totalGuests))" } : nil

        facilityCount = state.facilities.count
        brokenRides = state.attractions.reduce(0) { $0 + ($1.isBroken ? 1 : 0) }
        cleanliness = state.map.cleanlinessScore
        litteredTiles = state.map.litteredTiles.count
        beauty = state.map.beautyScore
        sceneryCount = state.scenery.count

        staffCount = state.staff.count
        dailyPayroll = state.dailyPayroll
        staffOnTask = state.staff.reduce(0) { $0 + ($1.isIdle ? 0 : 1) }
        staffByRole = StaffRole.allCases.map { role in
            RoleCount(id: StaffContent.definition(for: role)?.displayName ?? role.rawValue,
                      count: state.staffCount(role: role))
        }

        ratingLines = ratingComponents.map {
            RatingLine(id: $0.name, weight: $0.weight, value: $0.value)
        }
        finance = FinanceSnapshot(ledger: state.ledger)
    }
}
