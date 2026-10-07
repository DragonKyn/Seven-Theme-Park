import SwiftUI

/// The panel shown while the player is choosing where to send an employee:
/// first an instruction, then, once a spot has been tapped, a question.
struct StaffMoveBar: View {
    @ObservedObject var controller: GameController

    private var name: String { controller.movingStaffName ?? "them" }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundStyle(Theme.accent)
                Text(controller.pendingStaffMove == nil
                     ? "Send \(name) where?"
                     : "Send \(name) to the marked spot?")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            Text(controller.pendingStaffMove == nil
                 ? "Tap a walkway on the map. They will walk there, by train if that is the only way, and wait for a while before going back to work."
                 : "Tap somewhere else to change it. They will hold the spot for a while, then go back to choosing their own work.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    controller.cancelStaffMove()
                } label: {
                    Text("Cancel")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.control)
                        )
                        .foregroundStyle(Theme.textPrimary)
                }

                Button {
                    controller.confirmStaffMove()
                } label: {
                    Text("Send")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.accent)
                        )
                        .foregroundStyle(.black)
                }
                .disabled(controller.pendingStaffMove == nil)
                .opacity(controller.pendingStaffMove == nil ? 0.4 : 1)
            }
        }
        .padding(12)
        .panelBackground()
    }
}
