import SwiftUI

/// The Park Trials ladder: ten parks to build under a deadline, each one
/// opening when the one before it is beaten.
struct TrialLadderView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header

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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .navigationDestination(for: String.self) { id in
                if let trial = TrialContent.definition(id: id) {
                    TrialBriefingView(trial: trial)
                }
            }
        }
        .onAppear { router.refreshTrials() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ten parks, each on a deadline.")
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
            NavigationLink(value: trial.id) {
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

                Text("\(trial.number)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(unlocked ? AnyShapeStyle(Theme.moneyGradient)
                                                       : AnyShapeStyle(Color.white.opacity(0.5))))
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
                .strokeBorder(bestDay != nil ? Theme.money.opacity(0.55) : Color.white.opacity(0.08),
                              lineWidth: 1)
        )
    }

    @ViewBuilder
    private var status: some View {
        if let bestDay {
            HStack(spacing: 3) {
                Image(systemName: trial.medal.symbolName)
                Text("Day \(bestDay)")
            }
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(.black.opacity(0.85))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.moneyGradient))
        } else if unlocked {
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
        .toolbarColorScheme(.dark, for: .navigationBar)
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
