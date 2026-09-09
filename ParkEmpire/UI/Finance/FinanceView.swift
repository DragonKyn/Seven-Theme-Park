import SwiftUI

struct FinanceView: View {
    @ObservedObject var controller: GameController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let snapshot = controller.makeFinanceSnapshot()

        NavigationStack {
            List {
                Section("Today") {
                    summaryRow(label: "Revenue", value: snapshot.todayTotalRevenue, tint: .green)
                    summaryRow(label: "Expenses", value: snapshot.todayTotalExpenses, tint: .red)
                    summaryRow(label: "Profit", value: snapshot.todayProfit,
                               tint: snapshot.todayProfit >= 0 ? .green : .red)
                    if let yesterday = snapshot.yesterdayProfit {
                        summaryRow(label: "Yesterday", value: yesterday,
                                   tint: yesterday >= 0 ? .green : .red)
                    }
                }

                Section("Today - revenue") {
                    ForEach(snapshot.todayRevenue) { line in
                        LabeledContent(line.label, value: CurrencyFormatter.exact(line.amount))
                    }
                }

                Section("Today - expenses") {
                    ForEach(snapshot.todayExpenses) { line in
                        LabeledContent(line.label, value: CurrencyFormatter.exact(line.amount))
                    }
                }

                Section("Lifetime") {
                    summaryRow(label: "Total revenue", value: snapshot.lifetimeTotalRevenue, tint: .green)
                    summaryRow(label: "Total expenses", value: snapshot.lifetimeTotalExpenses, tint: .red)
                    summaryRow(label: "Total profit", value: snapshot.lifetimeProfit,
                               tint: snapshot.lifetimeProfit >= 0 ? .green : .red)
                }

                Section("Lifetime breakdown") {
                    ForEach(snapshot.lifetimeRevenue) { line in
                        LabeledContent(line.label, value: CurrencyFormatter.short(line.amount))
                    }
                    ForEach(snapshot.lifetimeExpenses) { line in
                        LabeledContent(line.label, value: CurrencyFormatter.short(line.amount))
                    }
                }
            }
            .navigationTitle("Finances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func summaryRow(label: String, value: Double, tint: Color) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(CurrencyFormatter.signed(value))
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(tint)
        }
    }
}
