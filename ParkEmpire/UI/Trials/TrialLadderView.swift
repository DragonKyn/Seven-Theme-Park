import SwiftUI

/// The Park Trials ladder: parks to build under a deadline, each one
/// opening when the one before it is beaten.
struct TrialLadderView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var showingPerks = false

    var body: some View {
        NavigationContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    perksLink

                    ForEach(TrialContent.all) { trial in
                        rung(trial)
                    }
                }
                .padding(16)
            }
            .background(
                LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Park Trials")
            .navigationBarTitleDisplayMode(.inline)
            .darkNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showingPerks) {
            PerkTreeView()
        }
        .onAppear { router.refreshTrials() }
    }

    /// The other half of the ladder: what beating a rung is worth afterwards.
    private var perksLink: some View {
        Button {
            showingPerks = true
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "seal.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black.opacity(0.85))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.moneyGradient))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Park Perks")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(perkPointsLine)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(unspentPoints > 0 ? Theme.money.opacity(0.6) : Color.white.opacity(0.08),
                                  lineWidth: unspentPoints > 0 ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var unspentPoints: Int {
        PerkStore().available(completedTrials: router.completedTrials.count)
    }

    private var perkPointsLine: String {
        let spare = unspentPoints
        if spare == 0 {
            return router.completedTrials.isEmpty
                ? "Every trial you beat is worth a permanent bonus"
                : "Every point is spent. Move them whenever you like."
        }
        return spare == 1 ? "1 point waiting to be spent" : "\(spare) points waiting to be spent"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(TrialContent.all.count) parks, each on a deadline.")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Meet every goal before the last day closes. Each trial you beat earns its medal and opens the next rung.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "rosette")
                    .foregroundStyle(Theme.money)
                Text("\(router.completedTrials.count) of \(TrialContent.all.count) medals")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(Theme.moneyGradient)
                            .frame(width: geometry.size.width
                                   * CGFloat(router.completedTrials.count)
                                   / CGFloat(max(1, TrialContent.all.count)))
                    }
                }
                .frame(height: 6)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func rung(_ trial: TrialDefinition) -> some View {
        let unlocked = router.isTrialUnlocked(trial)
        let bestDay = router.completedTrials[trial.id]
        let run = router.trialRuns[trial.id]

        if unlocked {
            NavigationLink {
                TrialBriefingView(trial: trial)
            } label: {
                TrialRungCard(trial: trial, unlocked: true, bestDay: bestDay, runDay: run?.day)
            }
            .buttonStyle(.plain)
        } else {
            TrialRungCard(trial: trial, unlocked: false, bestDay: nil, runDay: nil)
        }
    }
}

/// One rung: its number, its map, what it asks, and whether it is beaten.
private struct TrialRungCard: View {
    let trial: TrialDefinition
    let unlocked: Bool
    let bestDay: Int?
    /// The day an unfinished run of this trial has reached, if there is one.
    let runDay: Int?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .topLeading) {
                Image(uiImage: MapArtwork.thumbnail(for: trial.map.layout, side: 150))
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .saturation(unlocked ? 1 : 0)
                    .opacity(unlocked ? 1 : 0.45)

                numberBadge
                    .offset(x: -6, y: -6)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(trial.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(unlocked ? .white : Theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    status
                }

                Text(trial.map.name)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                if unlocked {
                    ForEach(Array(trial.goals.enumerated()), id: \.offset) { _, goal in
                        Label(goal.title, systemImage: goal.symbolName)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Text("\(trial.dayLimit) days  ·  starts with \(CurrencyFormatter.short(trial.startingCash))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    if let bestDay {
                        Label("Completed on day \(bestDay)  ·  \(trial.medal.name)",
                              systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                    if let runDay {
                        Label("Park in progress, day \(runDay)", systemImage: "play.circle.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                } else {
                    Label("Beat trial \(trial.number - 1) to open", systemImage: "lock.fill")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(unlocked ? 0.09 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(bestDay != nil ? Theme.accent.opacity(0.75) : Color.white.opacity(0.08),
                              lineWidth: bestDay != nil ? 2 : 1)
        )
        .overlay(alignment: .bottomTrailing) {
            if bestDay != nil {
                CompleteStamp()
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
            }
        }
    }

    /// The rung's number, or a tick once it is beaten. The tick replaces the
    /// number rather than sitting beside it, so a finished rung reads as
    /// finished from the far side of the screen.
    @ViewBuilder
    private var numberBadge: some View {
        if bestDay != nil {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Theme.accent))
                .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1.5))
        } else {
            Text("\(trial.number)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.85))
                .frame(width: 22, height: 22)
                .background(Circle().fill(unlocked ? AnyShapeStyle(Theme.moneyGradient)
                                                   : AnyShapeStyle(Color.white.opacity(0.5))))
        }
    }

    /// A chevron on every rung that opens. Whether it is beaten is said by
    /// the tick, the green edge and the stamp, not repeated up here.
    @ViewBuilder
    private var status: some View {
        if unlocked {
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

/// Everything about one trial, and where to play it.
private struct TrialBriefingView: View {
    @EnvironmentObject private var router: AppRouter
    let trial: TrialDefinition

    @State private var confirmingRestart = false

    private var run: SaveSlotSummary? { router.trialRuns[trial.id] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(uiImage: MapArtwork.thumbnail(for: trial.map.layout, side: 400))
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        if router.completedTrials[trial.id] != nil {
                            CompleteStamp(scale: 1.6)
                        }
                    }
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Text("TRIAL \(trial.number)  ·  \(trial.map.name.uppercased())")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(Theme.money)
                    Text(trial.title)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(trial.briefing)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }

                section("GOALS, ALL AT ONCE") {
                    ForEach(Array(trial.goals.enumerated()), id: \.offset) { _, goal in
                        Label(goal.title, systemImage: goal.symbolName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                section("RULES") {
                    rule("calendar", "Finish by the end of day \(trial.dayLimit)")
                    rule("banknote", "Start with \(CurrencyFormatter.short(trial.startingCash))")
                    if let cap = trial.maxAdmission {
                        rule("ticket", "Gate price capped at \(CurrencyFormatter.short(cap))")
                    }
                    rule(trial.medal.symbolName, "Medal: \(trial.medal.name)")
                }

                if let bestDay = router.completedTrials[trial.id] {
                    Label("Medal earned. Best finish: day \(bestDay).", systemImage: trial.medal.symbolName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.money)
                }

                if let run {
                    primaryButton("Resume, day \(run.day)", symbol: "play.fill") {
                        router.resumeTrial(trial)
                    }
                    secondaryButton("Start over from day one") {
                        confirmingRestart = true
                    }
                } else {
                    primaryButton(router.completedTrials[trial.id] == nil ? "Begin trial" : "Play again",
                                  symbol: "flag.checkered") {
                        router.startTrial(trial)
                    }
                }

                Text("Trials keep their own saves. They never use one of your three park slots.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(18)
        }
        .background(
            LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .darkNavigationBar()
        .confirmationDialog("Start this trial over?",
                            isPresented: $confirmingRestart,
                            titleVisibility: .visible) {
            Button("Start over", role: .destructive) { router.startTrial(trial) }
            Button("Keep my park", role: .cancel) { }
        } message: {
            Text("The park you have on day \(run?.day ?? 1) is replaced with a fresh one. Medals you have earned are kept.")
        }
    }

    private func primaryButton(_ title: String,
                               symbol: String,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(.black.opacity(0.88))
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.moneyGradient))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(Theme.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.08)))
    }

    private func rule(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
    }

}

/// A rubber stamp, set at an angle, that says a trial is done.
struct CompleteStamp: View {
    var scale: CGFloat = 1

    var body: some View {
        HStack(spacing: 4 * scale) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 13 * scale, weight: .black))
            Text("COMPLETE")
                .font(.system(size: 12 * scale, weight: .black, design: .rounded))
                .tracking(1.5 * scale)
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 9 * scale)
        .padding(.vertical, 4 * scale)
        .background(
            RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                .fill(Theme.panelBottom.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                .strokeBorder(Theme.accent, lineWidth: 2 * scale)
        )
        .rotationEffect(.degrees(-9))
        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
        .accessibilityLabel("Trial complete")
    }
}

