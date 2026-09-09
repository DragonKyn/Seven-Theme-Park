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
}
