import SwiftUI

/// Hiring, firing and the wage bill.
struct StaffView: View {
    @ObservedObject var controller: GameController
    @Environment(\.dismiss) private var dismiss
    /// The role being hired, while its costume or act is being chosen.
    @State private var hiring: StaffRole?
    /// Which kind of employee the payroll is narrowed to, or nil for everybody.
    @State private var filter: StaffRole?
    @State private var sort: StaffSort = .name

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

                Section {
                    if controller.state.staff.isEmpty {
                        Text("Nobody hired yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        filterChips
                            .padding(.vertical, 2)
                        Picker("Sort", selection: $sort) {
                            ForEach(StaffSort.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } header: {
                    Text("On the payroll")
                } footer: {
                    if !controller.state.staff.isEmpty {
                        Text("Tap an employee to go to them in the park.")
                    }
                }

                ForEach(shownRoles, id: \.self) { role in
                    let people = members(of: role)
                    Section("\(role.pluralName) · \(people.count)") {
                        ForEach(people) { member in
                            staffRow(member)
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

    // MARK: - The payroll

    /// The roles to list: everyone grouped by job, or just the one that was
    /// picked. A pick with nobody left in it falls back to everybody rather
    /// than showing an empty list.
    private var shownRoles: [StaffRole] {
        let present = StaffRole.allCases.filter { count(of: $0) > 0 }
        if let filter, present.contains(filter) { return [filter] }
        return present
    }

    private func count(of role: StaffRole) -> Int {
        controller.state.staff.filter { $0.role == role }.count
    }

    private func members(of role: StaffRole) -> [Staff] {
        let people = controller.state.staff.filter { $0.role == role }
        switch sort {
        case .name:
            return people.sorted { $0.name < $1.name }
        case .mostTasks:
            return people.sorted { $0.tasksCompleted > $1.tasksCompleted }
        case .idleFirst:
            return people.sorted { lhs, rhs in
                if lhs.isIdle != rhs.isIdle { return lhs.isIdle }
                return lhs.name < rhs.name
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip("All", count: controller.state.staff.count, selected: filter == nil) {
                    filter = nil
                }
                ForEach(StaffRole.allCases.filter { count(of: $0) > 0 }) { role in
                    chip(role.pluralName, count: count(of: role), selected: filter == role) {
                        filter = role
                    }
                }
            }
        }
    }

    private func chip(_ title: String,
                      count: Int,
                      selected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(title) \(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.horizontal, 10)
                .frame(height: 28)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(Capsule().fill(selected ? Color.accentColor : Color.secondary.opacity(0.18)))
        }
        .buttonStyle(.plain)
    }

    private func staffRow(_ member: Staff) -> some View {
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

private enum StaffSort: String, CaseIterable, Identifiable {
    case name
    case mostTasks
    case idleFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: return "Name"
        case .mostTasks: return "Most done"
        case .idleFirst: return "Idle first"
        }
    }
}
