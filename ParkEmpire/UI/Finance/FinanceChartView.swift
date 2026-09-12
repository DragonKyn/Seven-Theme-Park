import Charts
import SwiftUI

/// The park's money over time.
///
/// Profit is the line that matters, so it is the thick green one with the
/// ground shaded under it; revenue and costs sit behind it for context. The
/// individual costs — wages, repairs, stock, building, upkeep — are off until
/// asked for, because five extra lines on a phone answer nothing.
struct FinanceChartView: View {
    let points: [FinancePoint]
    @Binding var range: FinanceRange
    @Binding var visible: Set<FinanceSeriesKind>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Range", selection: $range) {
                ForEach(FinanceRange.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)

            if points.count < 2 {
                waitingForData
            } else {
                chart
                    .frame(height: 190)
            }

            legend
        }
    }

    // MARK: - The chart

    private var chart: some View {
        Chart {
            // The shaded ground under profit, which is what makes a losing
            // day read as a losing day at a glance.
            if visible.contains(.profit) {
                ForEach(points) { point in
                    AreaMark(x: .value("When", point.id),
                             y: .value("Profit", point.profit))
                        .foregroundStyle(profitFill)
                        .interpolationMethod(.catmullRom)
                }
            }

            ForEach(orderedSeries, id: \.self) { series in
                ForEach(points) { point in
                    LineMark(x: .value("When", point.id),
                             y: .value("Amount", series.amount(in: point)),
                             series: .value("Series", series.displayName))
                        .foregroundStyle(colour(for: series))
                        .lineStyle(StrokeStyle(lineWidth: series == .profit ? 2.8 : 1.6,
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
            AxisMarks(values: axisIndices) { value in
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

    /// Profit last, so its thicker line is drawn over the rest.
    private var orderedSeries: [FinanceSeriesKind] {
        FinanceSeriesKind.allCases
            .filter { visible.contains($0) }
            .sorted { lhs, rhs in
                if lhs == .profit { return false }
                if rhs == .profit { return true }
                return lhs.rawValue < rhs.rawValue
            }
    }

    /// At most six labels, however many columns there are.
    private var axisIndices: [Int] {
        guard points.count > 1 else { return points.map(\.id) }
        let step = max(1, points.count / 6)
        return points.map(\.id).filter { $0 % step == 0 }
    }

    private var profitFill: LinearGradient {
        LinearGradient(colors: [colour(for: .profit).opacity(0.28),
                                colour(for: .profit).opacity(0.02)],
                       startPoint: .top,
                       endPoint: .bottom)
    }

    // MARK: - Legend, which is also the switchboard

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            row(FinanceSeriesKind.allCases.filter(\.isHeadline))
            row(FinanceSeriesKind.allCases.filter { !$0.isHeadline })
        }
    }

    private func row(_ series: [FinanceSeriesKind]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(series) { option in
                    Button {
                        toggle(option)
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colour(for: option))
                                .frame(width: 7, height: 7)
                            Text(option.displayName)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 9)
                        .frame(height: 26)
                        .foregroundStyle(visible.contains(option) ? Color.primary : Color.secondary)
                        .background(
                            Capsule().fill(visible.contains(option)
                                           ? colour(for: option).opacity(0.20)
                                           : Color.secondary.opacity(0.10))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func toggle(_ series: FinanceSeriesKind) {
        if visible.contains(series) {
            visible.remove(series)
        } else {
            visible.insert(series)
        }
    }

    private var waitingForData: some View {
        VStack(spacing: 5) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("The books are filed once an hour. Come back after the park has been open a while.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
    }

    // MARK: - Colours

    /// Deeper than the park's own palette: these are read against a white
    /// sheet rather than against grass.
    private func colour(for series: FinanceSeriesKind) -> Color {
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
}
