import SwiftUI

/// The park's notice board.
///
/// Deliberately not a system list. Everything else the player looks at while
/// the park is running is dark and rounded, and a white table of grey rows in
/// the middle of that reads as a different app. It is also the one screen a
/// player opens when something is wrong, so the severity of a line has to be
/// legible before any of the words are.
struct AlertListView: View {
    let alerts: [ParkAlert]
    let onSelect: (ParkTarget) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingProblemsOnly = false

    private var visible: [ParkAlert] {
        showingProblemsOnly ? alerts.filter { $0.severity != .info } : alerts
    }

    private var problemCount: Int {
        alerts.filter { $0.severity != .info }.count
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                filter
                content
            }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(problemCount > 0 ? Theme.danger.opacity(0.22) : Theme.control)
                    .frame(width: 34, height: 34)
                Image(systemName: problemCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(problemCount > 0 ? Theme.danger : Theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Notices")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(summary)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(9)
                    .background(Circle().fill(Theme.control))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var summary: String {
        if alerts.isEmpty { return "Nothing to report" }
        if problemCount == 0 { return "\(alerts.count) recent, all routine" }
        return "\(problemCount) need\(problemCount == 1 ? "s" : "") attention"
    }

    private var filter: some View {
        HStack(spacing: 6) {
            chip("Everything", active: !showingProblemsOnly, count: alerts.count) {
                showingProblemsOnly = false
            }
            chip("Needs attention", active: showingProblemsOnly, count: problemCount) {
                showingProblemsOnly = true
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func chip(_ title: String,
                      active: Bool,
                      count: Int,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("\(count)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.black.opacity(active ? 0.22 : 0.28)))
            }
            .foregroundStyle(active ? Color.black.opacity(0.85) : Theme.textSecondary)
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(Capsule().fill(active ? Theme.accentWarm : Theme.control))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        if visible.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(visible) { alert in
                        row(alert)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: showingProblemsOnly ? "checkmark.seal.fill" : "bell.slash.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(showingProblemsOnly ? Theme.accent : Theme.textSecondary)
            Text(showingProblemsOnly ? "Nothing needs you" : "No notices yet")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(showingProblemsOnly
                 ? "The park is running itself for the moment."
                 : "Breakdowns, queues and anything else worth knowing will appear here.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 40)
    }

    private func row(_ alert: ParkAlert) -> some View {
        Button {
            if let target = alert.target { onSelect(target) }
        } label: {
            HStack(alignment: .top, spacing: 0) {
                // A full-height rail in the severity colour. It is the part
                // that reads from across the room, before any of the words do.
                Rectangle()
                    .fill(colour(for: alert.severity))
                    .frame(width: 4)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: alert.severity.symbolName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(colour(for: alert.severity))
                        .frame(width: 20)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(alert.message)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            Text(alert.timeLabel)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                            if alert.target != nil {
                                Text("TAP TO SHOW ME")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .tracking(0.8)
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    if alert.target != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 10)
            }
            .background(Color.white.opacity(alert.severity == .info ? 0.07 : 0.11))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(alert.target == nil)
    }

    private func colour(for severity: AlertSeverity) -> Color {
        switch severity {
        case .info: return Theme.accent
        case .warning: return Theme.accentWarm
        case .critical: return Theme.danger
        }
    }
}
