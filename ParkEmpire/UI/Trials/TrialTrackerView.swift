import SwiftUI

/// The trial's goals, under the HUD, while a trial park is running.
///
/// Opens showing every goal, and folds to a single line with one tap,
/// because once the goals are known the park is what the player wants to
/// look at. The dots on the folded line still show how many are met.
struct TrialTrackerView: View {
    let trial: TrialSnapshot
    @Binding var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                header
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 6) {
                    ForEach(trial.goals) { goal in
                        goalRow(goal)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .panelBackground()
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: statusSymbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(statusColour)
                .frame(width: 24, height: 24)
                .background(Circle().fill(statusColour.opacity(0.18)))

            VStack(alignment: .leading, spacing: 1) {
                Text("TRIAL \(trial.number)  ·  \(trial.title.uppercased())")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                Text(statusLine)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // The goals as dots, so progress reads even while collapsed.
            HStack(spacing: 3) {
                ForEach(trial.goals) { goal in
                    Circle()
                        .fill(goal.isMet ? Theme.accent : Color.white.opacity(0.22))
                        .frame(width: 7, height: 7)
                }
            }

            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
        }
        .contentShape(Rectangle())
    }

    private func goalRow(_ goal: TrialSnapshot.Goal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: goal.isMet ? "checkmark.circle.fill" : goal.symbolName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(goal.isMet ? Theme.accent : Theme.textSecondary)
                    .frame(width: 16)
                Text(goal.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Text("\(goal.currentText) / \(goal.targetText)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(goal.isMet ? Theme.accent : Theme.textPrimary)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(goal.isMet ? Theme.accent : Theme.accentWarm)
                        .frame(width: geometry.size.width * goal.fraction)
                }
            }
            .frame(height: 4)
        }
    }

    private var statusLine: String {
        switch trial.outcome {
        case .won:
            return "Complete on day \(trial.decidedDay). Keep building."
        case .lost:
            return "Out of time. The park is yours to keep."
        case .inProgress:
            let days = trial.daysLeft == 0
                ? "Last day"
                : "\(trial.daysLeft) day\(trial.daysLeft == 1 ? "" : "s") left"
            return "\(days)  ·  \(trial.metCount) of \(trial.goals.count) goals met"
        }
    }

    private var statusSymbol: String {
        switch trial.outcome {
        case .won: return "rosette"
        case .lost: return "hourglass.bottomhalf.filled"
        case .inProgress: return "flag.checkered"
        }
    }

    private var statusColour: Color {
        switch trial.outcome {
        case .won: return Theme.money
        case .lost: return Theme.danger
        case .inProgress: return trial.daysLeft <= 1 ? Theme.accentWarm : Theme.accent
        }
    }
}
