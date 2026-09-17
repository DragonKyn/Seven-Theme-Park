import SwiftUI

/// The park's money over time.
///
/// Profit is the line that matters, so it is the thick green one with the
/// ground shaded under it; revenue and costs sit behind it for context. The
/// individual costs — wages, repairs, stock, building, upkeep — are off until
/// asked for, because five extra lines on a phone answer nothing.
///
/// Swift Charts draws it from iOS 16. Below that the same graph is drawn by
/// hand into a `Canvas`; both read `FinanceChartPalette`, so they agree.
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

    @ViewBuilder
    private var chart: some View {
        if #available(iOS 16.0, *) {
            FinanceMarksChart(points: points, visible: visible)
        } else {
            FinanceCanvasChart(points: points, visible: visible)
        }
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
                                .fill(FinanceChartPalette.colour(for: option))
                                .frame(width: 7, height: 7)
                            Text(option.displayName)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 9)
                        .frame(height: 26)
                        .foregroundStyle(visible.contains(option) ? Color.primary : Color.secondary)
                        .background(
                            Capsule().fill(visible.contains(option)
                                           ? FinanceChartPalette.colour(for: option).opacity(0.20)
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
}
