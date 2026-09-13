import Foundation

enum AlertSeverity: String, Codable {
    case info
    case warning
    case critical

    var symbolName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

struct ParkAlert: Codable, Identifiable, Equatable {
    var id = UUID()
    var message: String
    var severity: AlertSeverity
    var simTime: Double
    /// Optional object the alert refers to, so tapping it can focus the map.
    var target: ParkTarget?
    /// Key used to suppress duplicate alerts while the condition persists.
    var dedupeKey: String

    /// When it happened, in the park's own clock. Same mapping the HUD uses,
    /// so a notice and the clock above it never disagree.
    var timeLabel: String {
        let day = Int(simTime / Balance.dayLength) + 1
        let progress = simTime.truncatingRemainder(dividingBy: Balance.dayLength)
            / Balance.dayLength
        let hour = 9.0 + progress * 12.0
        let whole = Int(hour)
        let minutes = Int((hour - Double(whole)) * 60)
        return String(format: "Day %d, %02d:%02d", day, whole, minutes)
    }
}
