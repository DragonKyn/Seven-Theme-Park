import SwiftUI

/// The money graph drawn by hand, for the phones that never got Swift Charts.
///
/// Same data, same colours, same reading: profit thick with the ground shaded
/// under it, the other series behind it, a dashed line at break-even. Drawn
/// into a `Canvas`, which is one drawing pass rather than a view per point, so
/// it costs an old phone almost nothing.
struct FinanceCanvasChart: View {
    let points: [FinancePoint]
    let visible: Set<FinanceSeriesKind>

    /// Room for the money labels down the left and the dates along the bottom.
    private static let leftGutter: CGFloat = 40
    private static let bottomGutter: CGFloat = 16
    private static let topInset: CGFloat = 6

    var body: some View {
        Canvas { context, size in
            let plot = CGRect(x: Self.leftGutter,
                              y: Self.topInset,
                              width: max(1, size.width - Self.leftGutter - 4),
                              height: max(1, size.height - Self.topInset - Self.bottomGutter))
            let range = valueRange
            draw(grid: context, plot: plot, range: range)
            draw(series: context, plot: plot, range: range)
            draw(labels: context, plot: plot, range: range)
        }
    }

    // MARK: - Scales

    /// Every visible number, and always zero, so break-even is on the chart
    /// even on a park that has never lost money.
    private var valueRange: ClosedRange<Double> {
        var lowest = 0.0
        var highest = 0.0
        for series in FinanceChartPalette.ordered(visible) {
            for point in points {
                let value = series.amount(in: point)
                lowest = min(lowest, value)
                highest = max(highest, value)
            }
        }
        // A flat park would otherwise divide by nothing.
        if highest - lowest < 1 { highest = lowest + 1 }
        let padding = (highest - lowest) * 0.08
        return (lowest - padding)...(highest + padding)
    }

    private func x(for index: Int, in plot: CGRect) -> CGFloat {
        guard points.count > 1 else { return plot.midX }
        let step = plot.width / CGFloat(points.count - 1)
        return plot.minX + CGFloat(index) * step
    }

    private func y(for value: Double, in plot: CGRect, range: ClosedRange<Double>) -> CGFloat {
        let span = range.upperBound - range.lowerBound
        let fraction = (value - range.lowerBound) / span
        return plot.maxY - CGFloat(fraction) * plot.height
    }

    // MARK: - Drawing

    private func draw(grid context: GraphicsContext, plot: CGRect, range: ClosedRange<Double>) {
        let line = Color.secondary.opacity(0.18)
        for step in 0...4 {
            let value = range.lowerBound + (range.upperBound - range.lowerBound) * Double(step) / 4
            let position = y(for: value, in: plot, range: range)
            var path = Path()
            path.move(to: CGPoint(x: plot.minX, y: position))
            path.addLine(to: CGPoint(x: plot.maxX, y: position))
            context.stroke(path, with: .color(line), lineWidth: 1)
        }

        // Break-even, so a line below it is unmistakably a loss.
        var zero = Path()
        let zeroY = y(for: 0, in: plot, range: range)
        zero.move(to: CGPoint(x: plot.minX, y: zeroY))
        zero.addLine(to: CGPoint(x: plot.maxX, y: zeroY))
        context.stroke(zero,
                       with: .color(Color.secondary.opacity(0.5)),
                       style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
    }

    private func draw(series context: GraphicsContext, plot: CGRect, range: ClosedRange<Double>) {
        guard points.count > 1 else { return }

        if visible.contains(.profit) {
            var area = Path()
            area.move(to: CGPoint(x: x(for: 0, in: plot), y: y(for: 0, in: plot, range: range)))
            for (index, point) in points.enumerated() {
                area.addLine(to: CGPoint(x: x(for: index, in: plot),
                                         y: y(for: point.profit, in: plot, range: range)))
            }
            area.addLine(to: CGPoint(x: x(for: points.count - 1, in: plot),
                                     y: y(for: 0, in: plot, range: range)))
            area.closeSubpath()
            context.fill(area, with: .linearGradient(
                Gradient(colors: [FinanceChartPalette.colour(for: .profit).opacity(0.28),
                                  FinanceChartPalette.colour(for: .profit).opacity(0.02)]),
                startPoint: CGPoint(x: plot.midX, y: plot.minY),
                endPoint: CGPoint(x: plot.midX, y: plot.maxY)))
        }

        for series in FinanceChartPalette.ordered(visible) {
            var path = Path()
            for (index, point) in points.enumerated() {
                let position = CGPoint(x: x(for: index, in: plot),
                                       y: y(for: series.amount(in: point), in: plot, range: range))
                if index == 0 {
                    path.move(to: position)
                } else {
                    path.addLine(to: position)
                }
            }
            context.stroke(path,
                           with: .color(FinanceChartPalette.colour(for: series)),
                           style: StrokeStyle(lineWidth: FinanceChartPalette.lineWidth(for: series),
                                              lineCap: .round,
                                              lineJoin: .round))
        }
    }

    private func draw(labels context: GraphicsContext, plot: CGRect, range: ClosedRange<Double>) {
        for step in 0...4 {
            let value = range.lowerBound + (range.upperBound - range.lowerBound) * Double(step) / 4
            let position = y(for: value, in: plot, range: range)
            context.draw(label(CurrencyFormatter.compact(value), in: context),
                         at: CGPoint(x: plot.minX - 5, y: position),
                         anchor: .trailing)
        }

        let wanted = Set(FinanceChartPalette.axisIndices(points))
        for (index, point) in points.enumerated() where wanted.contains(point.id) {
            context.draw(label(point.shortLabel, in: context),
                         at: CGPoint(x: x(for: index, in: plot), y: plot.maxY + 8),
                         anchor: .center)
        }
    }

    /// Resolved rather than styled inline: `Text.foregroundStyle` only arrived
    /// in iOS 17, and a resolved run takes its colour from the shading.
    private func label(_ string: String, in context: GraphicsContext) -> GraphicsContext.ResolvedText {
        var resolved = context.resolve(Text(string).font(.system(size: 9, design: .rounded)))
        resolved.shading = .color(Color.secondary)
        return resolved
    }
}
