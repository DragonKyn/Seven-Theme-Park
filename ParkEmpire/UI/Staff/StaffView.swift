import SwiftUI

/// Hiring, firing and the wage bill.
struct StaffView: View {
    @ObservedObject var controller: GameController
    @Environment(\.dismiss) private var dismiss
    /// The role being hired, while its costume or act is being chosen.
    @State private var hiring: StaffRole?

    var body: some View {
        NavigationContainer {
            List {
                Section("Payroll") {
                    LabelledValue("Employees", value: "\(controller.state.staff.count)")
                    LabelledValue("Wages per day",
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
                                // Mascots and entertainers come in kinds, so hiring one
                                // goes to the screen where the kind is chosen.
                                Button("Hire") {
                                    if definition.role == .mascot || definition.role == .entertainer {
                                        hiring = definition.role
                                    } else {
                                        controller.hireStaff(role: definition.role)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(!controller.canHire(role: definition.role))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section(header: Text("On the payroll"),
                        footer: Text("Tap an employee to go to them in the park.")) {
                    if controller.state.staff.isEmpty {
                        Text("Nobody hired yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(controller.state.staff) { member in
                            HStack {
                                // Everything but the fire button takes you to them.
                                Button {
                                    controller.focusStaff(id: member.id)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: member.definition?.symbolName ?? "person.fill")
                                            .foregroundStyle(.tint)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(member.name)
                                                .font(.subheadline)
                                            Text(member.roleTitle)
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(.tint)
                                            Text(StaffDetail.describe(member.activity, state: controller.state))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(member.tasksCompleted) done")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

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
            .sheet(item: $hiring) { role in
                StaffHireSheet(role: role, controller: controller)
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
