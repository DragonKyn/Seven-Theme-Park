import SwiftUI

struct AttractionInspectorView: View {
    let attraction: AttractionDetail
    @ObservedObject var controller: GameController

    @State private var isRenaming = false
    @State private var draftName = ""

    var body: some View {
        VStack(spacing: 10) {
            SectionCard(title: "Status") {
                VStack(spacing: 5) {
                    StatRow(label: "Type", value: attraction.typeName)
                    StatRow(label: "Status",
                            value: attraction.status,
                            tint: attraction.isOpen ? Theme.accent : Theme.danger)
                    StatRow(label: "Condition",
                            value: "\(Int(attraction.condition))%",
                            tint: Theme.happinessColour(attraction.condition))
                    StatRow(label: "Queue", value: "\(attraction.queueLength) waiting")
                    StatRow(label: "Estimated wait", value: attraction.waitText)
                }
            }

            SectionCard(title: "Performance") {
                VStack(spacing: 5) {
                    StatRow(label: "Guests today", value: "\(attraction.guestsToday)")
                    StatRow(label: "Guests all time", value: "\(attraction.totalGuests)")
                    StatRow(label: "Guest satisfaction", value: attraction.satisfactionText)
                    StatRow(label: "Cost per cycle",
                            value: CurrencyFormatter.exact(attraction.operatingCostPerCycle))
                }
            }

            SectionCard(title: "Ride profile") {
                VStack(spacing: 8) {
                    MeterBar(label: "Excitement", value: attraction.excitement, tint: Theme.accentWarm)
                    MeterBar(label: "Nausea", value: attraction.nauseaRating, tint: Theme.needColour(attraction.nauseaRating))
                    StatRow(label: "Capacity", value: "\(attraction.capacity) per cycle")
                    StatRow(label: "Ride time", value: "\(Int(attraction.rideDuration))s")
                }
            }

            if attraction.isCustomCoaster {
                SectionCard(title: "Your coaster") {
                    VStack(alignment: .leading, spacing: 9) {
                        StatRow(label: "Track laid", value: "\(attraction.trackLength) tiles")

                        Text("LIVERY")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                ForEach(CoasterContent.liveries, id: \.rawValue) { colour in
                                    Button {
                                        controller.setCoasterLivery(colour, attractionID: attraction.id)
                                    } label: {
                                        Circle()
                                            .fill(Color(ParkPalette.colour(colour)))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle().strokeBorder(
                                                    colour == attraction.livery
                                                        ? Color.white
                                                        : Color.black.opacity(0.25),
                                                    lineWidth: colour == attraction.livery ? 3 : 1)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }

                        Text("TRACK")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                ForEach(CoasterContent.liveries, id: \.rawValue) { colour in
                                    Button {
                                        controller.setCoasterTrackColour(colour)
                                    } label: {
                                        Circle()
                                            .fill(Color(ParkPalette.colour(colour)))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle().strokeBorder(
                                                    colour == controller.state.coasterTrackColour
                                                        ? Color.white
                                                        : Color.black.opacity(0.25),
                                                    lineWidth: colour == controller.state.coasterTrackColour ? 3 : 1)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                        Text("Repaints every piece of coaster track in the park.")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)

                        Text("CARS")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(CoasterCarStyle.allCases) { style in
                                    Button {
                                        controller.setCoasterCarStyle(style, attractionID: attraction.id)
                                    } label: {
                                        Text(style.displayName)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 10)
                                            .frame(height: 26)
                                            .foregroundStyle(style == attraction.carStyle
                                                             ? Color.black : Theme.textPrimary)
                                            .background(
                                                Capsule().fill(style == attraction.carStyle
                                                               ? Theme.accent : Theme.control)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }
                }
            }

            SectionCard(title: "Upgrades") {
                VStack(spacing: 10) {
                    ForEach(attraction.upgrades) { upgrade in
                        UpgradeRowView(title: upgrade.displayName,
                                       summary: upgrade.summary,
                                       symbolName: upgrade.symbolName,
                                       level: upgrade.level,
                                       maxLevel: upgrade.maxLevel,
                                       cost: upgrade.cost,
                                       affordable: controller.hud.cash >= (upgrade.cost ?? 0)) {
                            controller.buyUpgrade(upgrade.kind, attractionID: attraction.id)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button {
                    controller.setRideOpen(!attraction.isOpen, attractionID: attraction.id)
                } label: {
                    Label(attraction.isOpen ? "Close ride" : "Open ride",
                          systemImage: attraction.isOpen ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(attraction.isOpen ? Theme.danger.opacity(0.85) : Theme.accent)
                        )
                        .foregroundStyle(.black)
                }

                Button {
                    draftName = attraction.name
                    isRenaming = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.control)
                        )
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .alert("Rename ride", isPresented: $isRenaming) {
            TextField("Name", text: $draftName)
            Button("Save") { controller.rename(attractionID: attraction.id, to: draftName) }
            Button("Cancel", role: .cancel) {}
        }
    }
}
