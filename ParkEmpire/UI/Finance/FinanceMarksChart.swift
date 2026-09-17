import Charts
import SwiftUI

/// The money graph as Swift Charts draws it.
///
/// Kept in a file of its own because Swift Charts only exists from iOS 16, and
/// the game runs back to iOS 15. Everything that decides how the graph looks —
/// colours, ordering, line weights, how many labels fit along the bottom —
/// lives in `FinanceChartPalette`, so the hand-drawn version below iOS 16 is
/// the same graph rather than a second design.
@available(iOS 16.0, *)
struct FinanceMarksChart: View {
    let points: [FinancePoint]
    let visible: Set<FinanceSeriesKind>

    var body: some View {
        Chart {
            // The shaded ground under profit.
            if visible.contains(.profit) {
                ForEach(points) { point in
                    AreaMark(x: .value("When", point.id),
                             y: .value("Profit", point.profit))
                        .foregroundStyle(FinanceChartPalette.profitFill)
                        .interpolationMethod(.catmullRom)
                }
            }

            ForEach(FinanceChartPalette.ordered(visible), id: \.self) { series in
                ForEach(points) { point in
                    LineMark(x: .value("When", point.id),
                             y: .value("Amount", series.amount(in: point)),
                             series: .value("Series", series.displayName))
                        .foregroundStyle(FinanceChartPalette.colour(for: series))
                        .lineStyle(StrokeStyle(lineWidth: FinanceChartPalette.lineWidth(for: series),
                                               lineCap: .round))
                        .interpolationMethod(.catmullRom)
                }
            }

            // Break-even, so a line below it is unmistakably a loss.
            RuleMark(y: .value("Break even", 0))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
        .chartXAxis {
            AxisMarks(values: FinanceChartPalette.axisIndices(points)) { value in
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.18))
                AxisValueLabel {
                    if let index = value.as(Int.self), let point = points.first(where: { $0.id == index }) {
                        Text(point.shortLabel)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.18))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(CurrencyFormatter.compact(amount))
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
