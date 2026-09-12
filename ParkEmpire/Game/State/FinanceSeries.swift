import Foundation

/// The finance chart's data, and the rules for what a line on it means.
///
/// Built from the ledger's own samples rather than from anything the chart
/// keeps for itself, so a line on the graph and a figure in the table can
/// never disagree.
enum FinanceSeriesKind: String, CaseIterable, Identifiable {
    case profit
    case revenue
    case expenses
    case wages
    case maintenance
    case inventory
    case construction
    case utilities

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .profit: return "Profit"
        case .revenue: return "Revenue"
        case .expenses: return "Costs"
        case .wages: return "Wages"
        case .maintenance: return "Repairs"
        case .inventory: return "Stock"
        case .construction: return "Building"
        case .utilities: return "Upkeep"
        }
    }

    /// The three totals are the point of the chart; the rest break the costs
    /// down and start hidden so the first look at it is readable.
    var isHeadline: Bool {
        self == .profit || self == .revenue || self == .expenses
    }

    var expenseCategory: ExpenseCategory? {
        switch self {
        case .wages: return .wages
        case .maintenance: return .maintenance
        case .inventory: return .inventory
        case .construction: return .construction
        case .utilities: return .utilities
        default: return nil
        }
    }

    func amount(in point: FinancePoint) -> Double {
        switch self {
        case .profit: return point.profit
        case .revenue: return point.revenue
        case .expenses: return point.expenses
        default: return expenseCategory.map { point.expenses(for: $0) } ?? 0
        }
    }
}

/// One column of the chart: an hour of the park's day, or a whole day.
struct FinancePoint: Identifiable {
    let id: Int
    let label: String
    let shortLabel: String
    let revenue: Double
    let expenses: Double
    private let expenseBreakdown: [String: Double]

    var profit: Double { revenue - expenses }

    func expenses(for category: ExpenseCategory) -> Double {
        expenseBreakdown[category.rawValue] ?? 0
    }

    init(id: Int, label: String, shortLabel: String, period: LedgerPeriod) {
        self.id = id
        self.label = label
        self.shortLabel = shortLabel
        self.revenue = period.totalRevenue
        self.expenses = period.totalExpenses
        self.expenseBreakdown = period.expenses
    }
}

/// How much of the park's history the chart covers.
enum FinanceRange: String, CaseIterable, Identifiable {
    /// Every park hour that has been filed, up to the last day's worth.
    case today
    /// One column per day.
    case allDays

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .today: return "By hour"
        case .allDays: return "By day"
        }
    }
}

enum FinanceSeriesBuilder {

    /// Turns the ledger's samples into columns for the chart.
    static func points(from history: [LedgerSample], range: FinanceRange) -> [FinancePoint] {
        switch range {
        case .today:
            // The last day's worth of hours, so the chart shows the shape of a
            // day rather than a week squeezed into a phone's width.
            let recent = history.suffix(12)
            return recent.enumerated().map { index, sample in
                FinancePoint(id: index,
                             label: sample.label,
                             shortLabel: sample.shortLabel,
                             period: sample.period)
            }

        case .allDays:
            var byDay: [Int: LedgerPeriod] = [:]
            for sample in history {
                var period = byDay[sample.day] ?? LedgerPeriod()
                for (key, amount) in sample.period.revenue {
                    period.revenue[key, default: 0] += amount
                }
                for (key, amount) in sample.period.expenses {
                    period.expenses[key, default: 0] += amount
                }
                byDay[sample.day] = period
            }

            return byDay.keys.sorted().enumerated().map { index, day in
                FinancePoint(id: index,
                             label: "Day \(day)",
                             shortLabel: "\(day)",
                             period: byDay[day] ?? LedgerPeriod())
            }
        }
    }
}
