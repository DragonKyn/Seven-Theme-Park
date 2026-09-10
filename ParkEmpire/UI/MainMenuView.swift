import SpriteKit
import SwiftUI

/// The title screen, over a live park running the real simulation.
///
/// The park behind it is the best thing on the screen, so the menu keeps out
/// of its way: a masthead at the top, the controls in a single column low
/// enough to leave the middle of the park visible, and scrims only where text
/// actually sits.
struct MainMenuView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var showingNewGame = false
    @State private var demo: DemoParkBackdrop?
    /// The slot the player has asked to delete, held until they confirm.
    @State private var slotToDelete: Int?

    var body: some View {
        ZStack {
            backdrop
                .ignoresSafeArea()

            LinearGradient(stops: [
                .init(color: .black.opacity(0.70), location: 0.00),
                .init(color: .black.opacity(0.20), location: 0.30),
                .init(color: .black.opacity(0.12), location: 0.46),
                .init(color: .black.opacity(0.78), location: 1.00)
            ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                masthead
                    .padding(.top, 22)

                Spacer(minLength: 12)

                VStack(spacing: 14) {
                    primaryActions
                    savedParks
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 22)
            }
        }
        .sheet(isPresented: $showingNewGame) {
            NewParkSheet(summaries: router.slotSummaries,
                         suggestedSlot: firstEmptySlot()) { name, mode, slot in
                router.startNewGame(named: name, mode: mode, in: slot)
                showingNewGame = false
            }
            .presentationDetents([.large])
        }
        .confirmationDialog("Delete this park?",
                            isPresented: Binding(get: { slotToDelete != nil },
                                                 set: { if !$0 { slotToDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let slot = slotToDelete { router.deleteSave(in: slot) }
                slotToDelete = nil
            }
            Button("Keep it", role: .cancel) { slotToDelete = nil }
        } message: {
            if let slot = slotToDelete, let summary = router.slotSummaries[slot] {
                Text("\(summary.parkName) is on day \(summary.day). This cannot be undone.")
            } else {
                Text("This cannot be undone.")
            }
        }
        .onAppear {
            router.refreshSlots()
            if demo == nil { demo = DemoParkBackdrop() }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(spacing: 7) {
            Text(AppInfo.gameName)
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.money, Theme.moneyDeep],
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.55), radius: 10, y: 3)

            TaglineView(taglines: AppInfo.taglines)

            // A hairline under the title, brightest in the middle, which is
            // enough to make the masthead read as a unit.
            LinearGradient(colors: [.clear, .white.opacity(0.55), .clear],
                           startPoint: .leading,
                           endPoint: .trailing)
                .frame(width: 190, height: 1)
                .padding(.top, 3)
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var primaryActions: some View {
        if let slot = router.mostRecentSlot, let summary = router.slotSummaries[slot] {
            Button {
                router.loadGame(from: slot)
            } label: {
                MenuButtonLabel(title: "Continue",
                                subtitle: "\(summary.parkName), day \(summary.day)",
                                symbol: "play.fill",
                                prominent: true)
            }
        }

        Button {
            showingNewGame = true
        } label: {
            MenuButtonLabel(title: "New Park",
                            subtitle: "Normal or free build",
                            symbol: "plus",
                            prominent: router.slotSummaries.isEmpty)
        }
    }

    private var savedParks: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("SAVED PARKS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.62))
                .padding(.leading, 4)

            ForEach(0..<SaveGameService.slotCount, id: \.self) { slot in
                SaveSlotRow(slot: slot,
                            summary: router.slotSummaries[slot],
                            onLoad: { router.loadGame(from: slot) },
                            onDelete: { slotToDelete = slot })
            }
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let demo {
            SpriteView(scene: demo.scene, options: [.ignoresSiblingOrder])
                .allowsHitTesting(false)
        } else {
            LinearGradient(colors: [Color(red: 0.20, green: 0.44, blue: 0.62),
                                    Color(red: 0.36, green: 0.66, blue: 0.45)],
                           startPoint: .top,
                           endPoint: .bottom)
        }
    }

    private func firstEmptySlot() -> Int {
        for slot in 0..<SaveGameService.slotCount where router.slotSummaries[slot] == nil {
            return slot
        }
        return 0
    }
}

// MARK: - Buttons

private struct MenuButtonLabel: View {
    let title: String
    let subtitle: String
    let symbol: String
    let prominent: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .heavy))
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(prominent ? Color.black.opacity(0.14) : Color.white.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.72)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .opacity(0.45)
        }
        .foregroundStyle(prominent ? Color.black.opacity(0.88) : .white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(background)
        .shadow(color: .black.opacity(prominent ? 0.35 : 0.25), radius: 8, y: 3)
    }

    @ViewBuilder
    private var background: some View {
        if prominent {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.moneyGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.45), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panelTop.opacity(0.92),
                                              Theme.panelBottom.opacity(0.92)],
                                     startPoint: .top,
                                     endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )
        }
    }
}

// MARK: - Save slots

private struct SaveSlotRow: View {
    let slot: Int
    let summary: SaveSlotSummary?
    let onLoad: () -> Void
    let onDelete: () -> Void

    var body: some View {
        if let summary {
            filled(summary)
        } else {
            empty
        }
    }

    private func filled(_ summary: SaveSlotSummary) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(summary.parkName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if summary.mode == .freeBuild {
                        Label("Free build", systemImage: "infinity")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.accent.opacity(0.35)))
                            .foregroundStyle(.white)
                    }
                }

                HStack(spacing: 6) {
                    StarRatingView(stars: stars(for: summary.parkRating))
                    Text("Day \(summary.day)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                    Text("\(summary.guestCount) guests")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .lineLimit(1)

                // The balance gets its own chip on its own line. A park doing
                // well can carry a lot of digits, and sharing a row with the
                // rest of the numbers pushed it onto a second line.
                Text(summary.mode == .freeBuild
                     ? "Unlimited"
                     : CurrencyFormatter.compact(summary.cash))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.moneyGradient))
            }

            Spacer(minLength: 0)

            Button(action: onLoad) {
                Text("Load")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Capsule().fill(.white.opacity(0.92)))
                    .foregroundStyle(.black)
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.white.opacity(0.12)))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.34))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var empty: some View {
        HStack {
            Text("Slot \(slot + 1)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Text("Empty")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }

    /// Mirrors `GameState.starRating`. The summary stores the raw rating so
    /// the menu never has to open a save to draw a row.
    private func stars(for rating: Double) -> Int {
        switch rating {
        case ..<20: return 1
        case ..<40: return 2
        case ..<60: return 3
        case ..<80: return 4
        default: return 5
        }
    }
}

// MARK: - New park

private struct NewParkSheet: View {
    let summaries: [Int: SaveSlotSummary]
    let suggestedSlot: Int
    let onStart: (String, GameMode, Int) -> Void

    @State private var parkName = ""
    @State private var mode: GameMode = .normal
    @State private var slot = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Park name") {
                    TextField("New Park", text: $parkName)
                }

                Section("Mode") {
                    ForEach(GameMode.allCases) { option in
                        Button {
                            mode = option
                        } label: {
                            HStack(alignment: .top, spacing: 11) {
                                Image(systemName: option.symbolName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(width: 24)
                                    .foregroundStyle(mode == option ? Color.accentColor : .secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    Text(option.summary)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)

                                if mode == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Save slot") {
                    Picker("Slot", selection: $slot) {
                        ForEach(0..<SaveGameService.slotCount, id: \.self) { index in
                            Text(slotLabel(index)).tag(index)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Text(footnote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Park")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { onStart(parkName, mode, slot) }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { slot = suggestedSlot }
        }
    }

    private var footnote: String {
        switch mode {
        case .normal:
            return "You start with \(CurrencyFormatter.short(Balance.startingCash)), a park entrance and a short walkway. Everything else is up to you."
        case .freeBuild:
            return "Build without paying for any of it. The books still record what everything would have cost, so the finance screen still tells you whether the park could support itself."
        }
    }

    private func slotLabel(_ index: Int) -> String {
        if let summary = summaries[index] {
            return "Slot \(index + 1), overwrite \(summary.parkName)"
        }
        return "Slot \(index + 1), empty"
    }
}
