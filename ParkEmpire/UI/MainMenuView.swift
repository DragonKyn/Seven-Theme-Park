import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var showingNewGame = false
    @State private var newParkName = ""
    @State private var selectedSlot = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.20, green: 0.44, blue: 0.62),
                                    Color(red: 0.36, green: 0.66, blue: 0.45)],
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 6) {
                    Text(AppInfo.gameName)
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(AppInfo.tagline)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }

                VStack(spacing: 12) {
                    if let slot = router.mostRecentSlot,
                       let summary = router.slotSummaries[slot] {
                        Button {
                            router.loadGame(from: slot)
                        } label: {
                            MenuButtonLabel(title: "Continue",
                                            subtitle: "\(summary.parkName) · Day \(summary.day)",
                                            symbol: "play.fill",
                                            prominent: true)
                        }
                    }

                    Button {
                        selectedSlot = firstEmptySlot()
                        newParkName = ""
                        showingNewGame = true
                    } label: {
                        MenuButtonLabel(title: "New Park",
                                        subtitle: "Start from empty land",
                                        symbol: "plus",
                                        prominent: router.slotSummaries.isEmpty)
                    }
                }
                .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 10) {
                    Text("SAVED PARKS")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))

                    ForEach(0..<SaveGameService.slotCount, id: \.self) { slot in
                        SaveSlotRow(slot: slot,
                                    summary: router.slotSummaries[slot],
                                    onLoad: { router.loadGame(from: slot) },
                                    onDelete: { router.deleteSave(in: slot) })
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .sheet(isPresented: $showingNewGame) {
            NewParkSheet(parkName: $newParkName,
                         selectedSlot: $selectedSlot,
                         summaries: router.slotSummaries) {
                router.startNewGame(named: newParkName, in: selectedSlot)
                showingNewGame = false
            }
            .presentationDetents([.medium])
        }
        .onAppear { router.refreshSlots() }
    }

    private func firstEmptySlot() -> Int {
        for slot in 0..<SaveGameService.slotCount where router.slotSummaries[slot] == nil {
            return slot
        }
        return 0
    }
}

private struct MenuButtonLabel: View {
    let title: String
    let subtitle: String
    let symbol: String
    let prominent: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.headline)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .opacity(0.75)
            }
            Spacer()
        }
        .foregroundStyle(prominent ? Color.black.opacity(0.85) : .white)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(prominent ? Color.white.opacity(0.92) : Color.black.opacity(0.28))
        )
    }
}

private struct SaveSlotRow: View {
    let slot: Int
    let summary: SaveSlotSummary?
    let onLoad: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(summary?.parkName ?? "Slot \(slot + 1) — empty")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                if let summary {
                    Text("Day \(summary.day) · \(CurrencyFormatter.short(summary.cash)) · \(summary.guestCount) guests")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Spacer()
            if summary != nil {
                Button("Load", action: onLoad)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.9))
                    .foregroundStyle(.black)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .font(.caption)
                .tint(.white)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.22))
        )
    }
}

private struct NewParkSheet: View {
    @Binding var parkName: String
    @Binding var selectedSlot: Int
    let summaries: [Int: SaveSlotSummary]
    let onStart: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Park name") {
                    TextField("New Park", text: $parkName)
                }
                Section("Save slot") {
                    Picker("Slot", selection: $selectedSlot) {
                        ForEach(0..<SaveGameService.slotCount, id: \.self) { slot in
                            Text(slotLabel(slot)).tag(slot)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Text("You start with \(CurrencyFormatter.short(Balance.startingCash)), a park entrance and a short walkway. Everything else is up to you.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Park")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start", action: onStart)
                }
            }
        }
    }

    private func slotLabel(_ slot: Int) -> String {
        if let summary = summaries[slot] {
            return "Slot \(slot + 1) — overwrite \(summary.parkName)"
        }
        return "Slot \(slot + 1) — empty"
    }
}
