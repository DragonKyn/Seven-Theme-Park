import Foundation

/// What an achievement measures. Every metric is either a counter the
/// simulation already keeps or something readable straight off the park, so
/// awarding one never needs its own bookkeeping.
enum AchievementMetric: String, Codable {
    case guestsAdmitted
    case ridesGiven
    case foodSold
    case drinksSold
    case souvenirsSold
    case litterCleaned
    case repairsCompleted
    case upgradesBought
    case transportTrips
    case attractionCount
    case sceneryCount
    case staffCount
    case guestsInPark
    case parkRating
    case lifetimeProfit
    case cashOnHand
    case daysOperated

    /// Reads after a number: "2,000 meals served".
    var pastTense: String {
        switch self {
        case .guestsAdmitted: return "guests admitted"
        case .ridesGiven: return "rides given"
        case .foodSold: return "meals served"
        case .drinksSold: return "drinks poured"
        case .souvenirsSold: return "souvenirs sold"
        case .litterCleaned: return "pieces of litter swept"
        case .repairsCompleted: return "rides repaired"
        case .upgradesBought: return "upgrades bought"
        case .transportTrips: return "train journeys"
        case .attractionCount: return "rides standing at once"
        case .sceneryCount: return "decorations placed"
        case .staffCount: return "staff on the payroll"
        case .guestsInPark: return "guests in the park at once"
        case .parkRating: return "park rating reached"
        case .lifetimeProfit: return "lifetime profit"
        case .cashOnHand: return "in the bank"
        case .daysOperated: return "days open"
        }
    }
}

/// One achievement, with a ladder of thresholds rather than a single target.
///
/// Tiers are what make a counter interesting for the whole life of a park: the
/// first is reachable in an afternoon, the last is a project.
struct AchievementDefinition: Identifiable {
    let id: String
    /// The name the player sees. Short, and about the thing rather than the
    /// number, because the number changes every tier.
    let name: String
    let summary: String
    let symbolName: String
    let metric: AchievementMetric
    /// One threshold per tier, ascending.
    let tiers: [Double]
    /// Paid for the first tier. Later tiers pay more, steeply, because they
    /// take much longer and the park they belong to is much bigger.
    let baseReward: Double

    var tierCount: Int { tiers.count }

    func threshold(forTier tier: Int) -> Double? {
        guard tier >= 1, tier <= tiers.count else { return nil }
        return tiers[tier - 1]
    }

    func reward(forTier tier: Int) -> Double {
        (baseReward * pow(2.4, Double(tier - 1)) / 50).rounded() * 50
    }

    /// How a tier is described. Roman numerals read as ranks rather than as
    /// quantities, which is what a tier is.
    static func tierName(_ tier: Int) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
        guard tier >= 1, tier <= numerals.count else { return "\(tier)" }
        return numerals[tier - 1]
    }

    /// Whether the metric is money, so it can be formatted properly.
    var isCurrency: Bool {
        metric == .lifetimeProfit || metric == .cashOnHand
    }

    func formatted(_ value: Double) -> String {
        isCurrency
            ? CurrencyFormatter.short(value)
            : Self.countFormatter.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))"
    }

    /// What reaching a tier means in words: the threshold and the metric it
    /// counts. A name on its own does not tell the player what they did.
    func accomplishment(forTier tier: Int) -> String {
        guard let threshold = threshold(forTier: tier) else { return summary }
        return "\(formatted(threshold)) \(metric.pastTense)"
    }

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

enum AchievementContent {

    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "achievement.admissions",
            name: "Come One, Come All",
            summary: "Let guests through the gate.",
            symbolName: "figure.walk.arrival",
            metric: .guestsAdmitted,
            tiers: [100, 500, 2_500, 10_000, 50_000, 200_000],
            baseReward: 500
        ),
        AchievementDefinition(
            id: "achievement.rides",
            name: "White Knuckles",
            summary: "Give guests a ride.",
            symbolName: "sparkles",
            metric: .ridesGiven,
            tiers: [100, 1_000, 5_000, 25_000, 100_000, 400_000],
            baseReward: 600
        ),
        AchievementDefinition(
            id: "achievement.food",
            name: "Everyone Eats",
            summary: "Serve food from your stalls.",
            symbolName: "fork.knife",
            metric: .foodSold,
            tiers: [100, 500, 2_000, 10_000, 40_000, 150_000],
            baseReward: 450
        ),
        AchievementDefinition(
            id: "achievement.drinks",
            name: "Round of Drinks",
            summary: "Serve drinks from your kiosks.",
            symbolName: "cup.and.saucer.fill",
            metric: .drinksSold,
            tiers: [100, 600, 2_500, 12_000, 50_000, 180_000],
            baseReward: 400
        ),
        AchievementDefinition(
            id: "achievement.souvenirs",
            name: "Take Me Home",
            summary: "Sell souvenirs to guests on their way out.",
            symbolName: "gift.fill",
            metric: .souvenirsSold,
            tiers: [50, 250, 1_000, 5_000, 20_000, 75_000],
            baseReward: 550
        ),
        AchievementDefinition(
            id: "achievement.litter",
            name: "Not On My Paths",
            summary: "Have your janitors sweep up dropped rubbish.",
            symbolName: "trash.fill",
            metric: .litterCleaned,
            tiers: [50, 300, 1_500, 7_000, 30_000, 120_000],
            baseReward: 400
        ),
        AchievementDefinition(
            id: "achievement.repairs",
            name: "Percussive Maintenance",
            summary: "Get broken rides running again.",
            symbolName: "wrench.and.screwdriver.fill",
            metric: .repairsCompleted,
            tiers: [5, 25, 100, 500, 2_000, 8_000],
            baseReward: 700
        ),
        AchievementDefinition(
            id: "achievement.upgrades",
            name: "Bigger, Faster, Louder",
            summary: "Buy upgrades for the rides you already own.",
            symbolName: "arrow.up.circle.fill",
            metric: .upgradesBought,
            tiers: [3, 10, 25, 60, 120, 250],
            baseReward: 800
        ),
        AchievementDefinition(
            id: "achievement.transport",
            name: "All Aboard",
            summary: "Carry guests across the park by train.",
            symbolName: "tram.fill",
            metric: .transportTrips,
            tiers: [50, 300, 1_500, 7_000, 30_000, 120_000],
            baseReward: 700
        ),
        AchievementDefinition(
            id: "achievement.rides.built",
            name: "Ride Empire",
            summary: "Have rides standing in your park at once.",
            symbolName: "building.2.fill",
            metric: .attractionCount,
            tiers: [3, 6, 10, 16, 24, 32],
            baseReward: 900
        ),
        AchievementDefinition(
            id: "achievement.scenery",
            name: "Landscaper",
            summary: "Have decorations placed around your park.",
            symbolName: "tree.fill",
            metric: .sceneryCount,
            tiers: [10, 40, 120, 300, 700, 1_500],
            baseReward: 400
        ),
        AchievementDefinition(
            id: "achievement.staff",
            name: "Somebody Has To",
            summary: "Have employees on the payroll at once.",
            symbolName: "person.2.badge.gearshape.fill",
            metric: .staffCount,
            tiers: [3, 8, 15, 25, 32, 40],
            baseReward: 600
        ),
        AchievementDefinition(
            id: "achievement.crowd",
            name: "Standing Room Only",
            summary: "Have guests in the park at one time.",
            symbolName: "person.3.fill",
            metric: .guestsInPark,
            tiers: [25, 60, 120, 190, 250, 300],
            baseReward: 1_000
        ),
        AchievementDefinition(
            id: "achievement.rating",
            name: "Worth The Trip",
            summary: "Push your park rating up.",
            symbolName: "star.fill",
            metric: .parkRating,
            tiers: [40, 55, 70, 82, 90, 96],
            baseReward: 1_200
        ),
        AchievementDefinition(
            id: "achievement.profit",
            name: "In The Black",
            summary: "Turn a lifetime profit.",
            symbolName: "chart.line.uptrend.xyaxis",
            metric: .lifetimeProfit,
            tiers: [10_000, 50_000, 250_000, 1_000_000, 5_000_000, 20_000_000],
            baseReward: 1_000
        ),
        AchievementDefinition(
            id: "achievement.cash",
            name: "Deep Pockets",
            summary: "Hold cash in the bank.",
            symbolName: "banknote.fill",
            metric: .cashOnHand,
            tiers: [50_000, 150_000, 500_000, 2_000_000, 10_000_000, 50_000_000],
            baseReward: 900
        ),
        AchievementDefinition(
            id: "achievement.days",
            name: "Season Pass",
            summary: "Keep the park open, day after day.",
            symbolName: "calendar",
            metric: .daysOperated,
            tiers: [5, 15, 40, 100, 250, 500],
            baseReward: 800
        )
    ]

    private static let byID: [String: AchievementDefinition] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func definition(_ id: String) -> AchievementDefinition? { byID[id] }

    /// Every tier of every achievement, for the total shown on the list.
    static var totalTiers: Int {
        all.reduce(0) { $0 + $1.tierCount }
    }
}

/// One tier of one achievement, just earned. Persisted rather than kept in
/// memory so an award earned as the app goes to the background still gets its
/// celebration when the player comes back.
struct AchievementAward: Codable, Identifiable, Equatable {
    var id = UUID()
    let definitionID: String
    let tier: Int
    let reward: Double

    var definition: AchievementDefinition? { AchievementContent.definition(definitionID) }
    var name: String { definition?.name ?? "Achievement" }
    var symbolName: String { definition?.symbolName ?? "rosette" }
    var tierName: String { AchievementDefinition.tierName(tier) }
    var summary: String { definition?.summary ?? "" }

    /// What this tier actually took, in words.
    var accomplishment: String {
        definition?.accomplishment(forTier: tier) ?? ""
    }

    /// The next rung, so the celebration also points at what to aim for.
    var nextTarget: String? {
        guard let definition, let threshold = definition.threshold(forTier: tier + 1) else { return nil }
        return "\(definition.formatted(threshold)) \(definition.metric.pastTense)"
    }
}
