import SwiftUI

/// The colours the money graph is drawn in, shared by both of the things that
/// draw it: Swift Charts on iOS 16 and later, and the hand-drawn canvas below
/// that. One list, so the two cannot drift apart.
///
/// Deeper than the park's own palette: these are read against a white sheet
/// rather than against grass.
enum FinanceChartPalette {

    static func colour(for series: FinanceSeriesKind) -> Color {
        switch series {
        case .profit: return Color(red: 0.13, green: 0.64, blue: 0.36)
        case .revenue: return Color(red: 0.82, green: 0.58, blue: 0.10)
        case .expenses: return Color(red: 0.85, green: 0.29, blue: 0.26)
        case .wages: return Color(red: 0.55, green: 0.62, blue: 0.95)
        case .maintenance: return Color(red: 0.98, green: 0.62, blue: 0.30)
        case .inventory: return Color(red: 0.45, green: 0.82, blue: 0.85)
        case .construction: return Color(red: 0.83, green: 0.60, blue: 0.95)
        case .utilities: return Color(red: 0.75, green: 0.78, blue: 0.82)
        }
    }

    /// The shading under the profit line, which is what makes a losing day
    /// read as a losing day at a glance.
    static var profitFill: LinearGradient {
        LinearGradient(colors: [colour(for: .profit).opacity(0.28),
                                colour(for: .profit).opacity(0.02)],
                       startPoint: .top,
                       endPoint: .bottom)
    }

    /// Profit last, so its thicker line is drawn over the rest.
    static func ordered(_ visible: Set<FinanceSeriesKind>) -> [FinanceSeriesKind] {
        FinanceSeriesKind.allCases
            .filter { visible.contains($0) }
            .sorted { lhs, rhs in
                if lhs == .profit { return false }
                if rhs == .profit { return true }
                return lhs.rawValue < rhs.rawValue
            }
    }

    /// At most six labels along the bottom, however many columns there are.
    static func axisIndices(_ points: [FinancePoint]) -> [Int] {
        guard points.count > 1 else { return points.map(\.id) }
        let step = max(1, points.count / 6)
        return points.map(\.id).filter { $0 % step == 0 }
    }

    static func lineWidth(for series: FinanceSeriesKind) -> CGFloat {
        series == .profit ? 2.8 : 1.6
    }
}
