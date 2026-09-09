import CoreGraphics
import Foundation

/// A unit of work a staff member can be assigned.
enum StaffJob: Codable, Hashable {
    /// Sweep a specific tile.
    case cleanLitter(GridCoord)
    /// Empty a bin or clean a restroom.
    case serviceFacility(UUID)
    case repairRide(UUID)
    case inspectRide(UUID)
    /// Entertainers head towards a spot and perform there.
    case entertain(GridCoord)
}

enum StaffActivity: Codable, Hashable {
    case idle
    case travelling(StaffJob)
    case working(StaffJob)
}

/// An employee. Staff walk on the same paths as guests and pick their own work.
struct Staff: Codable, Identifiable {
    let id: UUID
    var name: String
    var role: StaffRole

    var position: CGPoint
    var tile: GridCoord
    var route: [GridCoord] = []
    var walkSpeed: Double = Balance.staffWalkSpeed

    var activity: StaffActivity = .idle
    /// Counts down while performing a job.
    var workTimer: Double = 0
    var nextJobSearchAt: Double = 0
    var tasksCompleted: Int = 0

    var definition: StaffDefinition? { StaffContent.definition(for: role) }

    /// The job currently being travelled to or performed.
    var currentJob: StaffJob? {
        switch activity {
        case .idle: return nil
        case .travelling(let job), .working(let job): return job
        }
    }

    var isIdle: Bool {
        if case .idle = activity { return true }
        return false
    }
}
