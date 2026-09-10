import SwiftUI

/// One upgrade track: what it does, how far it has been taken, and a button
/// to take it one step further.
///
/// Shared by the ride inspector and staff training so the two read the same
/// way, because to the player they are the same decision: spend now to run
/// better later.
struct UpgradeRowView: View {
    let title: String
    let summary: String
    let symbolName: String
    let level: Int
    let maxLevel: Int
    /// Nil once there is nothing left to buy.
    let cost: Double?
    let affordable: Bool
    let onBuy: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(level > 0 ? Theme.accentWarm : Theme.textSecondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    LevelPips(level: level, maxLevel: maxLevel)
                }
                Text(summary)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            if let cost {
                Button(action: onBuy) {
                    Text(CurrencyFormatter.short(cost))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(affordable ? Theme.accent : Theme.control)
                        )
                        .foregroundStyle(affordable ? Color.black : Theme.danger)
                }
                .disabled(!affordable)
            } else {
                Text("Maxed")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.accentWarm)
                    .frame(height: 28)
            }
        }
    }
}

/// Filled dots for levels bought, hollow for what is left.
struct LevelPips: View {
    let level: Int
    let maxLevel: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max(maxLevel, 1), id: \.self) { index in
                Circle()
                    .fill(index < level ? Theme.accentWarm : Color.white.opacity(0.18))
                    .frame(width: 5, height: 5)
            }
        }
    }
}
