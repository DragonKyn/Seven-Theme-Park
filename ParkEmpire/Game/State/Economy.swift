import Foundation

enum RevenueCategory: String, Codable, CaseIterable, Identifiable {
    case admission
    case food
    case drinks
    case souvenirs
    case other

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case construction
    case wages
    case maintenance
    case inventory
    case utilities

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

/// Totals for one accounting period. Stored keyed by raw value so the save
/// file stays readable and new categories decode as absent rather than failing.
struct LedgerPeriod: Codable {
    var revenue: [String: Double] = [:]
    var expenses: [String: Double] = [:]

    mutating func add(revenue category: RevenueCategory, _ amount: Double) {
        revenue[category.rawValue, default: 0] += amount
    }

    mutating func add(expense category: ExpenseCategory, _ amount: Double) {
        expenses[category.rawValue, default: 0] += amount
    }

    func amount(for category: RevenueCategory) -> Double { revenue[category.rawValue] ?? 0 }
    func amount(for category: ExpenseCategory) -> Double { expenses[category.rawValue] ?? 0 }

    var totalRevenue: Double { revenue.values.reduce(0, +) }
    var totalExpenses: Double { expenses.values.reduce(0, +) }
    var profit: Double { totalRevenue - totalExpenses }
}

/// Cash plus the books. Every money movement in the game goes through here so
/// the finance screen can never disagree with the balance.
struct Ledger: Codable {
    var cash: Double
    /// Free build. Costs are still recorded, so the finance screen still shows
    /// what the park would have cost to run, but nothing is ever deducted.
    var isUnlimited = false
    var today = LedgerPeriod()
    var yesterday: LedgerPeriod?
    var lifetime = LedgerPeriod()

    init(startingCash: Double) {
        self.cash = startingCash
    }

    func canAfford(_ amount: Double) -> Bool { isUnlimited || cash >= amount }

    /// What the placement rules should measure a price against.
    var spendableCash: Double { isUnlimited ? .greatestFiniteMagnitude : cash }

    mutating func receive(_ amount: Double, as category: RevenueCategory) {
        guard amount > 0 else { return }
        cash += amount
        today.add(revenue: category, amount)
        lifetime.add(revenue: category, amount)
    }

    mutating func spend(_ amount: Double, on category: ExpenseCategory) {
        guard amount > 0 else { return }
        if !isUnlimited { cash -= amount }
        today.add(expense: category, amount)
        lifetime.add(expense: category, amount)
    }

    mutating func rollOverDay() {
        yesterday = today
        today = LedgerPeriod()
    }
}

extension Ledger {
    /// Lenient decoding so a save written before free build existed still
    /// loads, as a normal game.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cash = container.value(.cash, or: Balance.startingCash)
        isUnlimited = container.value(.isUnlimited, or: false)
        today = container.value(.today, or: LedgerPeriod())
        yesterday = container.optionalValue(.yesterday)
        lifetime = container.value(.lifetime, or: LedgerPeriod())
    }
}
