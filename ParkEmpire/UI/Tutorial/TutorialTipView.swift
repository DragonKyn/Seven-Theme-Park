import SwiftUI

/// A piece of advice, shown once, under the readouts at the top of the screen.
///
/// Deliberately not a modal: the park keeps running behind it and every
/// control stays live, so a tip about the build menu can be read with the
/// build menu open. It stays until it is dismissed rather than timing out,
/// because a tip nobody finished reading has taught nobody anything.
struct TutorialTipView: View {
    let tip: TutorialTip
    let onDismiss: () -> Void
    let onTurnOff: () -> Void

    @State private var shown = false

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: tip.symbolName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.black.opacity(0.82))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.moneyGradient))
                .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 5) {
                Text("TIP")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .tracking(2.2)
                    .foregroundStyle(Theme.accentWarm)

                Text(tip.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tip.message)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button(action: dismiss) {
                        Text("Got it")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .frame(height: 30)
                            .background(Capsule().fill(Theme.accent))
                    }

                    Button(action: turnOff) {
                        Text("Turn tips off")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(Capsule().fill(Theme.control))
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .panelBackground()
        // The gold edge is what separates a tip from the panels it sits
        // among: those are the park, this is the game talking to the player.
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.accentWarm.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        .scaleEffect(shown ? 1 : 0.94)
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) { shown = true }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.14)) { shown = false }
        onDismiss()
    }

    private func turnOff() {
        withAnimation(.easeIn(duration: 0.14)) { shown = false }
        onTurnOff()
    }
}
