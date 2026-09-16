import SwiftUI

struct SpeedControlView: View {
    let speed: GameSpeed
    /// Whether the boosted notch can be chosen at all.
    let turboUnlocked: Bool
    let onSelect: (GameSpeed) -> Void
    /// Tapping the locked notch offers the advert rather than doing nothing.
    let onLockedTap: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(GameSpeed.allCases) { option in
                Button {
                    if option.needsBoost && !turboUnlocked {
                        onLockedTap()
                    } else {
                        onSelect(option)
                    }
                } label: {
                    label(for: option)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func label(for option: GameSpeed) -> some View {
        let locked = option.needsBoost && !turboUnlocked
        ZStack(alignment: .topTrailing) {
            Text(option.label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .frame(width: 28, height: 32)
                .foregroundStyle(foreground(option, locked: locked))
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(background(option, locked: locked))
                )

            if locked {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Theme.accentWarm)
                    .offset(x: 2, y: -2)
            }
        }
    }

    private func foreground(_ option: GameSpeed, locked: Bool) -> Color {
        if locked { return Theme.textSecondary }
        return option == speed ? Color.black : Theme.textPrimary
    }

    private func background(_ option: GameSpeed, locked: Bool) -> Color {
        if locked { return Theme.control.opacity(0.6) }
        // The boosted notch keeps its own colour while it is running, so it
        // is plain that something is switched on.
        if option == speed { return option.needsBoost ? Theme.accentWarm : Theme.accent }
        return Theme.control
    }
}
