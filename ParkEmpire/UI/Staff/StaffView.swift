import SwiftUI

/// Hiring, firing and the wage bill.
struct StaffView: View {
    @ObservedObject var controller: GameController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Payroll") {
                    LabeledContent("Employees", value: "\(controller.state.staff.count)")
                    LabeledContent("Wages per day",
                                   value: CurrencyFormatter.short(controller.state.dailyPayroll))
                    Text("Wages are charged continuously through the day, whether or not there is work to do.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Hire") {
                    ForEach(StaffContent.all) { definition in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: definition.symbolName)
                                .font(.title3)
                                .frame(width: 28)
                                .foregroundStyle(.tint)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(definition.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text(definition.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(CurrencyFormatter.short(definition.hiringCost)) to hire · \(CurrencyFormatter.short(definition.dailyWage))/day")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(spacing: 4) {
                                Text("\(controller.state.staffCount(role: definition.role))")
                                    .font(.system(.body, design: .rounded).weight(.bold))
                                Button("Hire") {
                                    controller.hireStaff(role: definition.role)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(!controller.canHire(role: definition.role))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("On the payroll") {
                    if controller.state.staff.isEmpty {
                        Text("Nobody hired yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(controller.state.staff) { member in
                            HStack {
                                Image(systemName: member.definition?.symbolName ?? "person.fill")
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(member.name)
                                        .font(.subheadline)
                                    Text(StaffDetail.describe(member.activity, state: controller.state))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(member.tasksCompleted) done")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Button(role: .destructive) {
                                    controller.fireStaff(id: member.id)
                                } label: {
                                    Image(systemName: "person.badge.minus")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
