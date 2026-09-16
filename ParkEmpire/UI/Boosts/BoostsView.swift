import SwiftUI

/// The two things an advert can switch on, and how long each has left.
///
/// Deliberately a quiet screen. Nothing here is sold, nothing is on a timer
/// counting down to a sales pitch, and the player can close it and never come
/// back without missing anything they could not earn by playing.
struct BoostsView: View {
    @ObservedObject var boosts: BoostCenter
    @ObservedObject var ads: RewardedAdCenter
    @Environment(\.dismiss) private var dismiss

    /// Which boost is waiting on an advert, if any.
    @State private var pending: BoostKind?
    /// Ticks once a second so the countdowns move.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    intro
                    ForEach(BoostKind.allCases) { kind in
                        card(kind)
                    }
                    footnote
                }
                .padding(16)
            }
            .background(
                LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Boosts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .onReceive(ticker) { _ in boosts.refresh() }
    }

    // MARK: - Pieces

    private var intro: some View {
        Text("Watch a short advert to switch one of these on for \(Int(Balance.adBoostMinutes)) minutes. Watch another and the time stacks. Neither is needed to finish anything in the game.")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func card(_ kind: BoostKind) -> some View {
        let remaining = boosts.remainingLabel(kind)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: kind.symbolName)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(remaining == nil ? Theme.textSecondary : .black.opacity(0.85))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(remaining == nil
                                              ? AnyShapeStyle(Theme.control)
                                              : AnyShapeStyle(Theme.moneyGradient)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(kind.summary)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let remaining {
                Label("Running, \(remaining) left", systemImage: "clock.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }

            button(for: kind, isRunning: remaining != nil)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(remaining == nil ? Color.white.opacity(0.08) : Theme.money.opacity(0.5),
                              lineWidth: remaining == nil ? 1 : 2)
        )
    }

    @ViewBuilder
    private func button(for kind: BoostKind, isRunning: Bool) -> some View {
        if !ads.isSupported {
            Text("Adverts are not part of this build yet.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        } else {
            Button {
                watch(kind)
            } label: {
                HStack(spacing: 7) {
                    if pending == kind {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "play.rectangle.fill")
                    }
                    Text(pending == kind
                         ? "Loading advert"
                         : (isRunning ? "Watch another, add \(Int(Balance.adBoostMinutes)) minutes"
                                      : "Watch an advert, \(Int(Balance.adBoostMinutes)) minutes"))
                }
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(.black.opacity(0.88))
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.moneyGradient))
            }
            .buttonStyle(.plain)
            .disabled(pending != nil)
            .opacity(pending == nil || pending == kind ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private var footnote: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let error = ads.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("No advert will ever interrupt your park. The only ones in \(AppInfo.gameName) are the ones you choose to watch here.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    private func watch(_ kind: BoostKind) {
        pending = kind
        Task {
            let earned = await ads.show()
            if earned { boosts.grant(kind) }
            pending = nil
        }
    }
}
