import Foundation

enum StaffRole: String, Codable, CaseIterable, Identifiable {
    case janitor
    case mechanic
    case entertainer

    var id: String { rawValue }
}

/// Static configuration for one kind of employee.
struct StaffDefinition: Codable, Identifiable {
    let role: StaffRole
    let displayName: String
    let summary: String
    let hiringCost: Double
    /// Charged continuously, spread across the park day.
    let dailyWage: Double
    let symbolName: String

    var id: String { role.rawValue }
    var wagePerSecond: Double { dailyWage / Balance.dayLength }
}

enum StaffContent {
    static let all: [StaffDefinition] = [
        StaffDefinition(
            role: .janitor,
            displayName: "Janitor",
            summary: "Sweeps up litter, empties bins and cleans restrooms.",
            hiringCost: 500,
            dailyWage: 60,
            symbolName: "trash.fill"
        ),
        StaffDefinition(
            role: .mechanic,
            displayName: "Mechanic",
            summary: "Inspects rides and repairs them when they break down.",
            hiringCost: 900,
            dailyWage: 95,
            symbolName: "wrench.and.screwdriver.fill"
        ),
        StaffDefinition(
            role: .entertainer,
            displayName: "Entertainer",
            summary: "Wanders the park lifting the mood of nearby guests.",
            hiringCost: 600,
            dailyWage: 70,
            symbolName: "theatermasks.fill"
        )
    ]

    private static let byRole: [StaffRole: StaffDefinition] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.role, $0) })

    static func definition(for role: StaffRole) -> StaffDefinition? {
        byRole[role]
    }
}
