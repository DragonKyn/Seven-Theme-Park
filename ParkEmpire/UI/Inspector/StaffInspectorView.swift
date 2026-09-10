import SwiftUI

struct StaffInspectorView: View {
    let member: StaffDetail
    @ObservedObject var controller: GameController

    var body: some View {
        VStack(spacing: 10) {
            SectionCard(title: "Right now") {
                HStack(spacing: 10) {
                    Image(systemName: member.symbolName)
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.roleName)
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(member.activityText)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
            }

            SectionCard(title: "Record") {
                VStack(spacing: 5) {
                    StatRow(label: "Tasks completed", value: "\(member.tasksCompleted)")
                    StatRow(label: "Wage", value: "\(CurrencyFormatter.short(member.dailyWage)) per day")
                }
            }

            SectionCard(title: "Training") {
                UpgradeRowView(title: member.trainingTitle,
                               summary: "Walks faster, works faster, and costs more to keep.",
                               symbolName: "graduationcap.fill",
                               level: member.trainingLevel,
                               maxLevel: member.maxTrainingLevel,
                               cost: member.trainingCost,
                               affordable: controller.hud.cash >= (member.trainingCost ?? 0)) {
                    controller.trainStaff(id: member.id)
                }
            }

            Button(role: .destructive) {
                controller.fireStaff(id: member.id)
            } label: {
                Label("Dismiss employee", systemImage: "person.badge.minus")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.danger.opacity(0.85))
                    )
                    .foregroundStyle(.black)
            }
        }
    }
}
