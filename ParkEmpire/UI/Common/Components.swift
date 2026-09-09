import SwiftUI

/// Compact labelled value used across the HUD.
struct StatPill: View {
    let symbol: String
    let value: String
    var tint: Color = Theme.textPrimary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.caption2)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
    }
}

/// Label on the left, value on the right.
struct StatRow: View {
    let label: String
    let value: String
    var tint: Color = Theme.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(tint)
        }
    }
}

/// Horizontal 0-100 bar for guest needs.
struct MeterBar: View {
    let label: String
    let value: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(value))")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(2, geometry.size.width * value / 100))
                }
            }
            .frame(height: 6)
        }
    }
}

struct StarRatingView: View {
    let stars: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: 9))
                    .foregroundStyle(index <= stars ? Theme.accentWarm : Theme.textSecondary)
            }
        }
    }
}

/// Titled card used inside the inspectors and dashboards.
struct SectionCard<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}
