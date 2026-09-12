import SwiftUI

/// The card that appears when a visitor with an audience posts about the park.
///
/// Shown as its own event rather than buried in the alert list, because it is
/// the one thing that happens in the park that the player did not cause and
/// would otherwise miss: the gate gets busy for three quarters of an hour and
/// nothing on screen says why.
struct PromotionView: View {
    let post: PromotionPost
    let onDismiss: () -> Void

    @State private var shown = false

    /// Long enough to read, and a tap ends it sooner.
    private static let dwell: TimeInterval = 8.0

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.28 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: finish)

            card
                .scaleEffect(shown ? 1 : 0.75)
                .opacity(shown ? 1 : 0)
                .onTapGesture(perform: finish)
        }
        .task {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.64)) { shown = true }
            try? await Task.sleep(nanoseconds: UInt64(Self.dwell * 1_000_000_000))
            finish()
        }
    }

    private var card: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.42, blue: 0.68),
                                                  Color(red: 0.62, green: 0.36, blue: 0.92)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(width: 62, height: 62)
                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2))

            Text("GOING VIRAL")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2.4)
                .foregroundStyle(Color(red: 0.98, green: 0.55, blue: 0.78))

            Text(post.guestName)
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("posted about \(post.rideName)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            HStack(spacing: 14) {
                figure("+\(Int(post.boost * 100))%", caption: "ARRIVALS")
                figure("\(Int(post.minutes)) min", caption: "FOR THE NEXT")
            }
            .padding(.top, 2)

            Text("Tap to carry on")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.top, 2)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                                     startPoint: .top,
                                     endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 0.98, green: 0.55, blue: 0.78).opacity(0.6),
                                      lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
        )
    }

    private func figure(_ value: String, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.accent)
            Text(caption)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(minWidth: 96)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.white.opacity(0.10)))
    }

    private func finish() {
        guard shown else { return }
        withAnimation(.easeIn(duration: 0.16)) { shown = false }
        onDismiss()
    }
}
