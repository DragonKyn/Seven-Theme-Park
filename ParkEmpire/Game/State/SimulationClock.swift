import Foundation

enum GameSpeed: Int, Codable, CaseIterable, Identifiable {
    case paused = 0
    case normal = 1
    case fast = 2
    case veryFast = 4

    var id: Int { rawValue }
    var multiplier: Double { Double(rawValue) }

    var label: String {
        switch self {
        case .paused: return "II"
        case .normal: return "1x"
        case .fast: return "2x"
        case .veryFast: return "4x"
        }
    }
}

/// In-game time. One park day is `Balance.dayLength` sim-seconds, which the
/// clock label maps onto a 09:00-21:00 opening window purely for display.
struct SimulationClock: Codable {
    var simTime: Double = 0
    var day: Int = 1
    var speed: GameSpeed = .normal

    var timeOfDay: Double {
        simTime.truncatingRemainder(dividingBy: Balance.dayLength)
    }

    var dayProgress: Double {
        timeOfDay / Balance.dayLength
    }

    /// Day number implied by elapsed sim time, 1-based.
    var elapsedDayNumber: Int {
        Int(simTime / Balance.dayLength) + 1
    }

    var clockLabel: String {
        let openingHour = 9.0
        let hoursInDay = 12.0
        let hour = openingHour + dayProgress * hoursInDay
        let wholeHour = Int(hour)
        let minutes = Int((hour - Double(wholeHour)) * 60)
        return String(format: "%02d:%02d", wholeHour, minutes)
    }
}
