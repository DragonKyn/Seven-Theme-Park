import SwiftUI

/// The achievement list: what has been earned, what is next, and how far off
/// it is.
struct AchievementsView: View {
    @ObservedObject var controller: GameController
    @Environment(\.dismiss) private var dismiss

    private var progress: [AchievementProgress] {
        controller.makeAchievementProgress()
    }

    var body: some View {
        NavigationStack {
            List {
                if !controller.hud.mode.earnsAchievements {
                    Section {
                        Label("This park is a free build. Achievements are not awarded.",
                              systemImage: "infinity")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    LabeledContent("Tiers earned",
                                   value: "\(earnedTiers) of \(AchievementContent.totalTiers)")
                    LabeledContent("Awards paid", value: CurrencyFormatter.short(totalPaid))
                }

                Section("Achievements") {
                    ForEach(progress) { item in
                        AchievementRow(item: item)
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var earnedTiers: Int {
        progress.reduce(0) { $0 + $1.earnedTier }
    }

    /// What the park has been paid out in achievement money so far. Recomputed
    /// from the tiers earned rather than tracked, so it can never drift.
    private var totalPaid: Double {
        progress.reduce(0.0) { total, item in
            guard item.earnedTier > 0 else { return total }
            return total + (1...item.earnedTier).reduce(0.0) {
                $0 + item.definition.reward(forTier: $1)
            }
        }
    }
}

private struct AchievementRow: View {
    let item: AchievementProgress

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: item.definition.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(item.earnedTier > 0 ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.definition.name)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    if item.earnedTier > 0 {
                        Text(AchievementDefinition.tierName(item.earnedTier))
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.accentColor.opacity(0.22)))
                    }
                    Spacer(minLength: 0)
                    TierPips(earned: item.earnedTier, total: item.definition.tierCount)
                }

                Text(item.definition.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let next = item.nextThreshold {
                    ProgressView(value: item.fraction)
                        .tint(Color.accentColor)
                    HStack {
                        Text("\(item.format(item.current)) of \(item.format(next))")
                        Spacer()
                        Text("\(CurrencyFormatter.short(item.definition.reward(forTier: item.earnedTier + 1))) next")
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                } else {
                    Text("Every tier earned.")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

/// One dot per tier, filled for those earned.
private struct TierPips: View {
    let earned: Int
    let total: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Circle()
                    .fill(index < earned ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: 5, height: 5)
            }
        }
    }
}
