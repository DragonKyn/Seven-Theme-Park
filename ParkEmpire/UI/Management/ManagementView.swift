import SwiftUI

/// The management dashboard: everything the player needs to diagnose why the
/// park is doing well or badly, in one place.
struct ManagementView: View {
    @ObservedObject var controller: GameController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let snapshot = controller.makeDashboardSnapshot()

        NavigationContainer {
            List {
                Section("Overview") {
                    LabelledValue("Cash", value: CurrencyFormatter.short(snapshot.cash))
                    LabelledValue("Guests in park", value: "\(snapshot.guestCount)")
                    LabelledValue("Park rating",
                                   value: "\(Int(snapshot.parkRating)) / 100  (\(snapshot.starRating) stars)")
                    LabelledValue("Profit today", value: CurrencyFormatter.signed(snapshot.todayProfit))
                    LabelledValue("Arrivals", value: String(format: "%.1f per minute", snapshot.arrivalsPerMinute))
                }

                Section("Guests") {
                    LabelledValue("Average happiness", value: "\(Int(snapshot.averageHappiness))%")
                    LabelledValue("Average hunger", value: "\(Int(snapshot.averageHunger))")
                    LabelledValue("Average thirst", value: "\(Int(snapshot.averageThirst))")
                    LabelledValue("Average energy", value: "\(Int(snapshot.averageEnergy))")
                    LabelledValue("Common complaint", value: snapshot.commonComplaint ?? "None yet")
                }

                Section("Attractions") {
                    LabelledValue("Total rides", value: "\(snapshot.attractionCount)")
                    LabelledValue("Closed rides", value: "\(snapshot.closedAttractions)")
                    LabelledValue("Average queue", value: String(format: "%.1f", snapshot.averageQueueLength))
                    LabelledValue("Most popular", value: snapshot.mostPopular ?? "No data")
                    if let least = snapshot.leastPopular {
                        LabelledValue("Least popular", value: least)
                    }
                    LabelledValue("Facilities", value: "\(snapshot.facilityCount)")
                }

                Section("Upkeep and looks") {
                    LabelledValue("Park cleanliness", value: "\(Int(snapshot.cleanliness * 100))%")
                    LabelledValue("Littered tiles", value: "\(snapshot.litteredTiles)")
                    LabelledValue("Decoration", value: "\(Int(snapshot.beauty * 100))%")
                    LabelledValue("Scenery placed", value: "\(snapshot.sceneryCount)")
                    LabelledValue("Broken rides", value: "\(snapshot.brokenRides)")
                }

                Section("Staff") {
                    LabelledValue("Employees", value: "\(snapshot.staffCount)")
                    LabelledValue("Wages per day", value: CurrencyFormatter.short(snapshot.dailyPayroll))
                    LabelledValue("Currently on a task", value: "\(snapshot.staffOnTask)")
                    ForEach(snapshot.staffByRole) { entry in
                        LabelledValue(entry.id, value: "\(entry.count)")
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
                    LabelledValue("Revenue today",
                                   value: CurrencyFormatter.short(snapshot.finance.todayTotalRevenue))
                    LabelledValue("Expenses today",
                                   value: CurrencyFormatter.short(snapshot.finance.todayTotalExpenses))
                    LabelledValue("Lifetime profit",
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
