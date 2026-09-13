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
    /// Security stand at a spot and keep an eye on it.
    case patrol(GridCoord)
    /// Security walk down a particular guest and see them off the premises.
    /// The only job whose destination moves while it is being travelled to.
    case escort(UUID)
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
    /// 0 to `StaffTrainingDefinition.maxLevel`. One track rather than a skill
    /// tree: the decision is how many people to train, not which skill.
    var trainingLevel: Int = 0

    var definition: StaffDefinition? { StaffContent.definition(for: role) }

    /// Training makes an employee both quicker on their feet and quicker at
    /// the job itself, and their wage follows.
    var effectiveWalkSpeed: Double {
        walkSpeed * (1 + UpgradeContent.staffTraining.walkSpeedPerLevel * Double(trainingLevel))
    }

    var workRate: Double {
        1 + UpgradeContent.staffTraining.workRatePerLevel * Double(trainingLevel)
    }

    var dailyWage: Double {
        (definition?.dailyWage ?? 0)
            * (1 + UpgradeContent.staffTraining.wagePerLevel * Double(trainingLevel))
    }

    var wagePerSecond: Double { dailyWage / Balance.dayLength }

    var trainingTitle: String {
        UpgradeContent.staffTraining.title(forLevel: trainingLevel)
    }

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

extension Staff {
    /// Lenient decoding so a save written before training existed still loads
    /// with everybody untrained rather than failing outright.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        name = container.value(.name, or: "Employee")
        role = container.value(.role, or: .janitor)
        position = container.value(.position, or: .zero)
        tile = container.value(.tile, or: GridCoord.zero)
        route = container.value(.route, or: [])
        walkSpeed = container.value(.walkSpeed, or: Balance.staffWalkSpeed)
        activity = container.value(.activity, or: .idle)
        workTimer = container.value(.workTimer, or: 0)
        nextJobSearchAt = container.value(.nextJobSearchAt, or: 0)
        tasksCompleted = container.value(.tasksCompleted, or: 0)
        trainingLevel = container.value(.trainingLevel, or: 0)
    }
}
