import SwiftUI

/// The end of a trial. Not timed and not dismissed by tapping the park: this
/// is the one card that asks the player what they want to do next.
struct TrialResultView: View {
    let report: TrialResultReport
    let onKeepPlaying: () -> Void
    let onLeave: () -> Void

    @State private var shown = false

    private var presentation: TrialResultPresentation {
        TrialResultPresentation(report: report)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.55 : 0)
                .ignoresSafeArea()

            card
                .scaleEffect(shown ? 1 : 0.8)
                .opacity(shown ? 1 : 0)
                .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.66)) { shown = true }
        }
    }

    private var card: some View {
        VStack(spacing: 12) {
            medal

            Text(presentation.won ? "TRIAL \(presentation.number) COMPLETE" : "TRIAL \(presentation.number) · OUT OF TIME")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(presentation.won ? Theme.money : Theme.danger)

            Text(presentation.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(presentation.detail)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let medalLine = presentation.medalLine {
                Label(medalLine, systemImage: "rosette")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.moneyGradient))
            }

            if let unlockLine = presentation.unlockLine {
                Label(unlockLine, systemImage: "lock.open.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: 8) {
                Button(action: onLeave) {
                    Text(presentation.won ? "Back to the ladder" : "Back to the menu")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(.black.opacity(0.88))
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.moneyGradient))
                }
                .buttonStyle(.plain)

                Button(action: onKeepPlaying) {
                    Text("Keep playing this park")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                                     startPoint: .top,
                                     endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder((presentation.won ? Theme.money : Theme.danger).opacity(0.6),
                                      lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        )
    }

    private var medal: some View {
        ZStack {
            Circle()
                .fill(presentation.won
                      ? AnyShapeStyle(Theme.moneyGradient)
                      : AnyShapeStyle(Color.white.opacity(0.12)))
                .frame(width: 84, height: 84)
                .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2))
                .shadow(color: presentation.won ? Theme.moneyDeep.opacity(0.6) : .clear,
                        radius: 14, y: 4)
            Image(systemName: presentation.won ? presentation.medalSymbol : "hourglass.bottomhalf.filled")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(presentation.won ? Color.black.opacity(0.8) : Theme.danger)
        }
    }
}

/// Everything the result card says, worked out from the report.
struct TrialResultPresentation {
    let number: Int
    let title: String
    let won: Bool
    let detail: String
    let medalSymbol: String
    let medalLine: String?
    let unlockLine: String?

    init(report: TrialResultReport) {
        let trial = report.result.trial
        number = trial?.number ?? 0
        title = trial?.title ?? "Trial"
        won = report.result.won
        medalSymbol = trial?.medal.symbolName ?? "rosette"

        if report.result.won {
            let limit = trial?.dayLimit ?? report.result.day
            let spare = max(0, limit - report.result.day)
            detail = spare > 0
                ? "Every goal met on day \(report.result.day), with \(spare) day\(spare == 1 ? "" : "s") to spare."
                : "Every goal met on day \(report.result.day), right at the wire."
            medalLine = report.isFirstWin ? trial.map { "Achievement: \($0.medal.name)" } : nil
            unlockLine = report.isFirstWin ? report.nextTrial.map { "Unlocked: Trial \($0.number), \($0.title)" } : nil
        } else {
            detail = "Day \(report.result.day) closed with goals still short. Try again from the ladder, or keep this park as a sandbox."
            medalLine = nil
            unlockLine = nil
        }
    }
}
