import SwiftUI

/// Wraps whichever inspector matches the current selection.
struct InspectorHostView: View {
    let selection: SelectionDetail
    @ObservedObject var controller: GameController

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    controller.clearSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView {
                content
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            .frame(maxHeight: 280)
        }
        .panelBackground()
    }

    private var title: String {
        switch selection {
        case .guest(let detail): return detail.name
        case .attraction(let detail): return detail.name
        case .facility(let detail): return detail.name
        case .staff(let detail): return detail.name
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .guest(let detail):
            GuestInspectorView(guest: detail)
        case .attraction(let detail):
            AttractionInspectorView(attraction: detail, controller: controller)
        case .facility(let detail):
            FacilityInspectorView(facility: detail, controller: controller)
        case .staff(let detail):
            StaffInspectorView(member: detail, controller: controller)
        }
    }
}
