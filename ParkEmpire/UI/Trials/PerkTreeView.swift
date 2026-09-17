import SwiftUI

/// Where the points trials pay out get spent.
///
/// One point per trial beaten, fifteen in all, against twenty-two ranks on
/// offer. Finishing the whole ladder still leaves choices on the table, which
/// is the point: two players who beat every trial should end up running
/// different parks.
struct PerkTreeView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var store = PerkStore()
    /// Bumped on every change, because the store reads user defaults rather
    /// than holding state of its own.
    @State private var revision = 0
    @State private var confirmingReset = false

    private var medals: Int { router.completedTrials.count }
    private var available: Int { store.available(completedTrials: medals) }

    var body: some View {
        NavigationContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    ForEach(PerkBranch.allCases) { branch in
                        branchSection(branch)
                    }
                    resetButton
                }
                .padding(16)
                .id(revision)
            }
            .background(
                LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Park Perks")
            .navigationBarTitleDisplayMode(.inline)
            .darkNavigationBar()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .confirmationDialog("Take every point back?",
                                isPresented: $confirmingReset,
                                titleVisibility: .visible) {
                Button("Take them all back", role: .destructive) {
                    store.reset()
                    revision += 1
                }
                Button("Leave them", role: .cancel) { }
            } message: {
                Text("Your medals are kept. Only where the points are spent changes.")
            }
        }
        .onAppear { router.refreshTrials() }
    }

    // MARK: - Chrome

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(available > 0 ? AnyShapeStyle(Theme.moneyGradient)
                                            : AnyShapeStyle(Theme.control))
                        .frame(width: 46, height: 46)
                    Text("\(available)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(available > 0 ? .black.opacity(0.85) : Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(available == 1 ? "1 point to spend" : "\(available) points to spend")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(medals) of \(TrialContent.all.count) trials beaten  ·  \(store.spent) spent")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Text(medals == 0
                 ? "Every trial you beat is worth one point. Beat the first one and this fills up."
                 : "These apply to every park you build, in every mode. Move them about as often as you like.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func branchSection(_ branch: PerkBranch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: branch.symbolName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.accentWarm)
                Text(branch.displayName.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Theme.accentWarm)
                Spacer(minLength: 0)
                Text("\(store.spent(in: branch)) spent here")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            Text(branch.summary)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)

            ForEach(PerkContent.inBranch(branch)) { perk in
                row(perk)
            }
        }
    }

    private func row(_ perk: PerkDefinition) -> some View {
        let rank = store.rank(perk)
        let locked = store.spent(in: perk.branch) < perk.requires && rank == 0
        let canBuy = store.canSpend(on: perk, completedTrials: medals)
        let canRefund = store.canRefund(perk)

        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: locked ? "lock.fill" : perk.symbolName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(rank > 0 ? Theme.accent : Theme.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(perk.displayName)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(locked ? Theme.textSecondary : .white)
                    Text(locked
                         ? "Opens once \(perk.requires) points are spent in \(perk.branch.displayName.lowercased())."
                         : perk.summary(atRank: rank))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                pips(rank: rank, of: perk.maxRank)
            }

            if !locked {
                HStack(spacing: 8) {
                    Button {
                        store.spend(on: perk, completedTrials: medals)
                        revision += 1
                    } label: {
                        Label(rank == perk.maxRank ? "Full" : "Spend a point", systemImage: "plus")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .foregroundStyle(canBuy ? .black.opacity(0.85) : Theme.textSecondary)
                            .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(canBuy ? AnyShapeStyle(Theme.moneyGradient)
                                             : AnyShapeStyle(Theme.control)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canBuy)

                    Button {
                        store.refund(perk)
                        revision += 1
                    } label: {
                        Label("Take back", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .foregroundStyle(canRefund ? .white : Theme.textSecondary)
                            .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(canRefund ? 0.14 : 0.06)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canRefund)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(locked ? 0.04 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(rank > 0 ? Theme.accent.opacity(0.55) : Color.white.opacity(0.07),
                              lineWidth: rank > 0 ? 1.5 : 1)
        )
    }

    /// One pip per rank, filled in as points go in. Cheaper to read at a
    /// glance than "2 / 3".
    private func pips(rank: Int, of maxRank: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<maxRank, id: \.self) { index in
                Circle()
                    .fill(index < rank ? AnyShapeStyle(Theme.accent)
                                       : AnyShapeStyle(Color.white.opacity(0.18)))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var resetButton: some View {
        Button {
            confirmingReset = true
        } label: {
            Label("Take every point back", systemImage: "arrow.counterclockwise")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundStyle(store.spent > 0 ? .white : Theme.textSecondary)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.10)))
        }
        .buttonStyle(.plain)
        .disabled(store.spent == 0)
    }
}
