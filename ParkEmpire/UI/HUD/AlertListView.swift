import SwiftUI

struct AlertListView: View {
    let alerts: [ParkAlert]
    let onSelect: (ParkTarget) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if alerts.isEmpty {
                    ContentUnavailableView("No alerts",
                                           systemImage: "bell.slash",
                                           description: Text("Problems in the park will show up here."))
                } else {
                    List(alerts) { alert in
                        Button {
                            if let target = alert.target { onSelect(target) }
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: alert.severity.symbolName)
                                    .foregroundStyle(colour(for: alert.severity))
                                Text(alert.message)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if alert.target != nil {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(alert.target == nil)
                    }
                }
            }
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func colour(for severity: AlertSeverity) -> Color {
        switch severity {
        case .info: return Theme.accent
        case .warning: return Theme.accentWarm
        case .critical: return Theme.danger
        }
    }
}
