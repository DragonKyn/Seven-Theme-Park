import SwiftUI

/// The party popper that goes off when an achievement tier is earned.
///
/// Everything is driven from one `phase` value rather than from a timer per
/// piece, so the whole celebration is one animation the view can be trusted to
/// finish and then dismiss itself.
struct CelebrationView: View {
    let award: AchievementAward
    let onDismiss: () -> Void

    @State private var burst = false
    @State private var cardIn = false

    /// How long the whole thing is on screen. Long enough to read three lines
    /// without hurrying; a tap dismisses it sooner.
    private static let dwell: TimeInterval = 7.0

    var body: some View {
        ZStack {
            // Catches taps so the player can dismiss it early, and dims the
            // park just enough that the card reads.
            Color.black.opacity(cardIn ? 0.28 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: finish)

            ConfettiBurst(active: burst)
                .allowsHitTesting(false)

            card
                .scaleEffect(cardIn ? 1 : 0.7)
                .opacity(cardIn ? 1 : 0)
                .onTapGesture(perform: finish)
        }
        .task {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) { cardIn = true }
            withAnimation(.easeOut(duration: 1.9)) { burst = true }
            try? await Task.sleep(nanoseconds: UInt64(Self.dwell * 1_000_000_000))
            finish()
        }
    }

    private var card: some View {
        VStack(spacing: 9) {
            Image(systemName: award.symbolName)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.black.opacity(0.82))
                .frame(width: 62, height: 62)
                .background(Circle().fill(Theme.moneyGradient))
                .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 2))

            Text("ACHIEVEMENT UNLOCKED")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2.4)
                .foregroundStyle(Theme.accentWarm)

            Text(award.name)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Tier \(award.tierName)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
                .padding(.horizontal, 9)
                .padding(.vertical, 2)
                .background(Capsule().fill(.white.opacity(0.12)))

            // What was actually achieved. The name alone does not say.
            Text(award.accomplishment)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .multilineTextAlignment(.center)

            Text(award.summary)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let next = award.nextTarget {
                Text("Next: \(next)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Text("\(CurrencyFormatter.short(award.reward)) awarded")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.moneyGradient))
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                                     startPoint: .top,
                                     endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Theme.accentWarm.opacity(0.55), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.5), radius: 18, y: 6)
        )
        .padding(.horizontal, 40)
    }

    private func finish() {
        withAnimation(.easeIn(duration: 0.2)) { cardIn = false }
        onDismiss()
    }
}

/// Paper thrown up and out from behind the card, then falling.
///
/// The pieces are fixed rather than random so the burst is the same every
/// time and nothing has to be generated while the animation is running.
private struct ConfettiBurst: View {
    let active: Bool

    private static let pieces: [Piece] = (0..<44).map { index in
        // Deterministic spread: a golden-angle fan gives an even scatter
        // without needing a random number generator or a stored seed.
        let angle = Double(index) * 2.39996
        let reach = 120.0 + Double((index * 37) % 130)
        return Piece(id: index,
                     dx: cos(angle) * reach,
                     dy: sin(angle) * reach * 0.75 + Double((index * 53) % 180),
                     spin: Double((index * 71) % 720) - 360,
                     size: 5 + Double(index % 4) * 2.5,
                     delay: Double(index % 7) * 0.035,
                     colour: Piece.palette[index % Piece.palette.count])
    }

    var body: some View {
        ZStack {
            ForEach(Self.pieces) { piece in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(piece.colour)
                    .frame(width: piece.size, height: piece.size * 1.7)
                    .rotationEffect(.degrees(active ? piece.spin : 0))
                    .offset(x: active ? piece.dx : 0,
                            y: active ? piece.dy : 0)
                    .opacity(active ? 0 : 1)
                    .animation(.easeOut(duration: 1.9).delay(piece.delay), value: active)
            }
        }
    }

    struct Piece: Identifiable {
        let id: Int
        let dx: Double
        let dy: Double
        let spin: Double
        let size: Double
        let delay: Double
        let colour: Color

        static let palette: [Color] = [
            Theme.money, Theme.accent, Theme.accentWarm, Theme.danger,
            Color(red: 0.45, green: 0.70, blue: 0.98),
            Color(red: 0.80, green: 0.55, blue: 0.95)
        ]
    }
}
