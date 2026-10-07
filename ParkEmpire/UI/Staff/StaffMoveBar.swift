import SwiftUI

/// Shown while the player is choosing where to send an employee. One line:
/// what to do, and the two ways out of it.
struct StaffMoveBar: View {
    @ObservedObject var controller: GameController

    private var name: String { controller.movingStaffName ?? "them" }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .foregroundStyle(Theme.accent)

            Text(controller.pendingStaffMove == nil
                 ? "Tap a walkway to send \(name)"
                 : "Send \(name) to the marked spot?")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            Button("Cancel") {
                controller.cancelStaffMove()
            }
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .foregroundStyle(Theme.textPrimary)

            Button {
                controller.confirmStaffMove()
            } label: {
                Text("Send")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.accent))
                    .foregroundStyle(.black)
            }
            .disabled(controller.pendingStaffMove == nil)
            .opacity(controller.pendingStaffMove == nil ? 0.4 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .panelBackground()
    }
}
