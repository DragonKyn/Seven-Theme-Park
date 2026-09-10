import SwiftUI

/// The management dashboard: everything the player needs to diagnose why the
/// park is doing well or badly, in one place.
struct ManagementView: View {
    @ObservedObject var controller: GameController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let snapshot = controller.makeDashboardSnapshot()

        NavigationStack {
            List {
                Section("Overview") {
                    LabeledContent("Cash", value: CurrencyFormatter.short(snapshot.cash))
                    LabeledContent("Guests in park", value: "\(snapshot.guestCount)")
                    LabeledContent("Park rating",
                                   value: "\(Int(snapshot.parkRating)) / 100  (\(snapshot.starRating) stars)")
                    LabeledContent("Profit today", value: CurrencyFormatter.signed(snapshot.todayProfit))
                    LabeledContent("Arrivals", value: String(format: "%.1f per minute", snapshot.arrivalsPerMinute))
                }

                Section("Guests") {
                    LabeledContent("Average happiness", value: "\(Int(snapshot.averageHappiness))%")
                    LabeledContent("Average hunger", value: "\(Int(snapshot.averageHunger))")
                    LabeledContent("Average thirst", value: "\(Int(snapshot.averageThirst))")
                    LabeledContent("Average energy", value: "\(Int(snapshot.averageEnergy))")
                    LabeledContent("Common complaint", value: snapshot.commonComplaint ?? "None yet")
                }

                Section("Attractions") {
                    LabeledContent("Total rides", value: "\(snapshot.attractionCount)")
                    LabeledContent("Closed rides", value: "\(snapshot.closedAttractions)")
                    LabeledContent("Average queue", value: String(format: "%.1f", snapshot.averageQueueLength))
                    LabeledContent("Most popular", value: snapshot.mostPopular ?? "No data")
                    if let least = snapshot.leastPopular {
                        LabeledContent("Least popular", value: least)
                    }
                    LabeledContent("Facilities", value: "\(snapshot.facilityCount)")
                }

                Section("Upkeep and looks") {
                    LabeledContent("Park cleanliness", value: "\(Int(snapshot.cleanliness * 100))%")
                    LabeledContent("Littered tiles", value: "\(snapshot.litteredTiles)")
                    LabeledContent("Decoration", value: "\(Int(snapshot.beauty * 100))%")
                    LabeledContent("Scenery placed", value: "\(snapshot.sceneryCount)")
                    LabeledContent("Broken rides", value: "\(snapshot.brokenRides)")
                }

                Section("Staff") {
                    LabeledContent("Employees", value: "\(snapshot.staffCount)")
                    LabeledContent("Wages per day", value: CurrencyFormatter.short(snapshot.dailyPayroll))
                    LabeledContent("Currently on a task", value: "\(snapshot.staffOnTask)")
                    ForEach(snapshot.staffByRole) { entry in
                        LabeledContent(entry.id, value: "\(entry.count)")
                    }
                }

                Section("Rating breakdown") {
                    ForEach(snapshot.ratingLines) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(line.id)
                                Spacer()
                                Text("\(Int(line.value * 100))%")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            }
                            ProgressView(value: line.value)
                                .tint(line.value > 0.6 ? .green : (line.value > 0.35 ? .orange : .red))
                            Text("Weight \(Int(line.weight * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Weights are normalised over the components listed, so the score always spans the full 0-100 range.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Finance") {
                    LabeledContent("Revenue today",
                                   value: CurrencyFormatter.short(snapshot.finance.todayTotalRevenue))
                    LabeledContent("Expenses today",
                                   value: CurrencyFormatter.short(snapshot.finance.todayTotalExpenses))
                    LabeledContent("Lifetime profit",
                                   value: CurrencyFormatter.signed(snapshot.finance.lifetimeProfit))
                }
            }
            .navigationTitle("Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
