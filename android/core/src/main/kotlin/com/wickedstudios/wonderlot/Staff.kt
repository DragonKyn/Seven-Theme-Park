@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import java.util.UUID

/** A unit of work a staff member can be assigned. */
@Serializable
sealed class StaffJob {
    /** Sweep a specific tile. */
    @Serializable data class CleanLitter(val tile: GridCoord) : StaffJob()

    /** Empty a bin or clean a restroom. */
    @Serializable data class ServiceFacility(val id: UUID) : StaffJob()
    @Serializable data class RepairRide(val id: UUID) : StaffJob()
    @Serializable data class InspectRide(val id: UUID) : StaffJob()

    /** Entertainers head towards a spot and perform there. */
    @Serializable data class Entertain(val spot: GridCoord) : StaffJob()

    /** Security stand at a spot and keep an eye on it. */
    @Serializable data class Patrol(val spot: GridCoord) : StaffJob()

    /** Go somewhere the player chose and stay there for a while. */
    @Serializable data class GoTo(val spot: GridCoord) : StaffJob()

    /** Security walk down a particular guest and see them off the premises. */
    @Serializable data class Escort(val guestID: UUID) : StaffJob()
}

@Serializable
sealed class StaffActivity {
    @Serializable data object Idle : StaffActivity()
    @Serializable data class Travelling(val job: StaffJob) : StaffActivity()
    @Serializable data class Working(val job: StaffJob) : StaffActivity()
}

/** Where an employee is up to on a journey that includes the park railway. */
@Serializable
data class StaffTransfer(
    /** The station they board at. */
    val stationID: UUID,
    /** The walkway tile they step off onto. */
    val landing: GridCoord,
    /** Sim-seconds of waiting on the platform, then of riding. */
    var waiting: Double,
    var riding: Double,
    var boarded: Boolean = false,
)

/** An employee. Staff walk on the same paths as guests and pick their own work. */
@Serializable
class Staff(
    val id: UUID = UUID.randomUUID(),
    var name: String = "Employee",
    var role: StaffRole = StaffRole.janitor,
    override var position: Vec2 = Vec2(0.0, 0.0),
    override var tile: GridCoord = GridCoord.zero,
    override var route: MutableList<GridCoord> = mutableListOf(),
    var walkSpeed: Double = Balance.staffWalkSpeed,
    var activity: StaffActivity = StaffActivity.Idle,
    /** Counts down while performing a job. */
    var workTimer: Double = 0.0,
    var nextJobSearchAt: Double = 0.0,
    var tasksCompleted: Int = 0,
    /** 0 to the training definition's max level. */
    var trainingLevel: Int = 0,
    /** How an entertainer or a mascot looks. Null for everybody else. */
    var act: EntertainerAct? = null,
    var costume: MascotCostume? = null,
    var primaryColour: ParkColour? = null,
    var secondaryColour: ParkColour? = null,
    var trimColour: ParkColour? = null,
    /** Part way through a journey that includes the train, or null. */
    var transfer: StaffTransfer? = null,
    /** Something the player told them to do, which they do before choosing anything for themselves. */
    var orders: StaffJob? = null,
) : Walker {
    /** Hidden from the map while on the train. */
    val isOnTrain: Boolean get() = transfer?.boarded == true

    /** Sent somewhere by the player, and still on the way or holding there. */
    val isOnOrders: Boolean
        get() {
            if (orders != null) return true
            return currentJob is StaffJob.GoTo
        }

    val resolvedAct: EntertainerAct get() = act ?: EntertainerAct.classic

    /** What to call them: the job, and for the two jobs that come in kinds, which kind. */
    val roleTitle: String
        get() {
            val base = definition?.displayName ?: role.name.replaceFirstChar { it.uppercase() }
            return when (role) {
                StaffRole.entertainer -> {
                    val kind = if (resolvedAct == EntertainerAct.classic) "Classic" else resolvedAct.displayName
                    "$base · $kind"
                }
                StaffRole.mascot -> "$base · ${(costume ?: MascotCostume.bear).displayName}"
                else -> base
            }
        }

    val style: StaffStyle get() = StaffStyle(act, costume, primaryColour, secondaryColour, trimColour)

    /** What the artwork is drawn from. */
    val look: StaffLook get() = style.look(role)

    val definition: StaffDefinition? get() = StaffContent.definition(role)

    val effectiveWalkSpeed: Double
        get() = walkSpeed * (1 + UpgradeContent.staffTraining.walkSpeedPerLevel * trainingLevel)

    val workRate: Double get() = 1 + UpgradeContent.staffTraining.workRatePerLevel * trainingLevel

    val dailyWage: Double
        get() = (definition?.dailyWage ?: 0.0) * (1 + UpgradeContent.staffTraining.wagePerLevel * trainingLevel)

    val wagePerSecond: Double get() = dailyWage / Balance.dayLength

    val trainingTitle: String get() = UpgradeContent.staffTraining.title(trainingLevel)

    /** The job currently being travelled to or performed. */
    val currentJob: StaffJob?
        get() = when (val a = activity) {
            is StaffActivity.Idle -> null
            is StaffActivity.Travelling -> a.job
            is StaffActivity.Working -> a.job
        }

    val isIdle: Boolean get() = activity is StaffActivity.Idle
}
