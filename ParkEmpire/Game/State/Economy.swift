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
    var today = LedgerPeriod()
    var yesterday: LedgerPeriod?
    var lifetime = LedgerPeriod()

    init(startingCash: Double) {
        self.cash = startingCash
    }

    func canAfford(_ amount: Double) -> Bool { cash >= amount }

    mutating func receive(_ amount: Double, as category: RevenueCategory) {
        guard amount > 0 else { return }
        cash += amount
        today.add(revenue: category, amount)
        lifetime.add(revenue: category, amount)
    }

    mutating func spend(_ amount: Double, on category: ExpenseCategory) {
        guard amount > 0 else { return }
        cash -= amount
        today.add(expense: category, amount)
        lifetime.add(expense: category, amount)
    }

    mutating func rollOverDay() {
        yesterday = today
        today = LedgerPeriod()
    }
}
