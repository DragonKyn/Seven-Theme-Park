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
                                .fill(Color.white.opacity(0.12))
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
