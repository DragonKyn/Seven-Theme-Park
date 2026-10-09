@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.UseSerializers
import java.util.UUID

/**
 * Read-only views of the simulation, built for the interface. Keeping these
 * separate means views never hold on to live entities and never mutate the
 * park by accident.
 */

// region HUD

/** A trial park's progress, worked out once per refresh for the interface. */
class TrialSnapshot private constructor(
    val number: Int,
    val title: String,
    val day: Int,
    val dayLimit: Int,
    val outcome: TrialOutcome,
    val decidedDay: Int,
    val goals: List<Goal>,
) {
    class Goal(
        val id: Int,
        val title: String,
        val shortTitle: String,
        val symbolName: String,
        val currentText: String,
        val targetText: String,
        /** 0..1, how far there. */
        val fraction: Double,
        val isMet: Boolean,
    )

    val daysLeft: Int get() = maxOf(0, dayLimit - day)
    val metCount: Int get() = goals.count { it.isMet }

    companion object {
        fun of(state: GameState): TrialSnapshot? {
            val trial = state.trial ?: return null
            return TrialSnapshot(
                trial.number, trial.title, state.clock.day, trial.dayLimit, state.trialOutcome, state.trialDecidedDay,
                trial.goals.mapIndexed { index, goal ->
                    val current = goal.current(state)
                    Goal(index, goal.title, goal.shortTitle, goal.symbolName, goal.format(current),
                        goal.format(goal.target),
                        if (goal.target > 0) maxOf(0.0, minOf(1.0, current / goal.target)) else 1.0,
                        goal.isMet(state))
                },
            )
        }
    }
}

class HUDSnapshot(
    val parkName: String = AppInfo.gameName,
    val cash: Double = 0.0,
    val guestCount: Int = 0,
    val averageHappiness: Double = 0.0,
    val parkRating: Double = 0.0,
    val starRating: Int = 1,
    val clockLabel: String = "09:00",
    val day: Int = 1,
    val speed: GameSpeed = GameSpeed.normal,
    val admissionPrice: Double = Balance.defaultAdmissionPrice,
    val arrivalsPerMinute: Double = 0.0,
    val todayProfit: Double = 0.0,
    val mode: GameMode = GameMode.normal,
    val trial: TrialSnapshot? = null,
) {
    companion object {
        fun of(state: GameState) = HUDSnapshot(
            state.parkName, state.ledger.cash, state.guestCount, state.averageHappiness, state.parkRating,
            state.starRating, state.clock.clockLabel, state.clock.day, state.clock.speed, state.admissionPrice,
            state.currentArrivalsPerMinute, state.ledger.today.profit, state.mode, TrialSnapshot.of(state),
        )
    }
}

// endregion

// region Guest inspector

class GuestDetail(guest: Guest, state: GameState) {
    val id: UUID = guest.id
    val name: String = guest.name
    val ageCategory: String = guest.ageCategory.displayName
    val happiness: Double = guest.happiness
    val cash: Double = guest.cash
    val hunger: Double = guest.hunger
    val thirst: Double = guest.thirst
    val energy: Double = guest.energy
    val bathroomNeed: Double = guest.bathroomNeed
    val nausea: Double = guest.nausea
    val thoughts: List<GuestThought> = guest.thoughts.reversed()
    val ridesRidden: Int = guest.ridesRidden
    val purchases: Int = guest.purchases
    val moneySpent: Double = guest.moneySpent
    val timeInPark: Double = guest.timeInPark
    val thrillPreference: Double = guest.personality.thrillPreference
    val patience: Double = guest.personality.patience
    val spending: Double = guest.personality.spending

    /** What they are carrying home from the midway, if anything. */
    val prizeName: String? = guest.prize?.displayName
    val prizesWon: Int = guest.prizesWon
    val activityText: String = describe(guest.activity, state)

    val timeInParkText: String
        get() = String.format("%d:%02d", timeInPark.toInt() / 60, timeInPark.toInt() % 60)

    private fun describe(activity: GuestActivity, state: GameState): String = when (activity) {
        is GuestActivity.Arriving -> "Arriving at the park"
        is GuestActivity.Exploring -> "Looking for something to do"
        is GuestActivity.Walking -> when (activity.target) {
            is ParkTarget.Exit -> "Heading for the exit"
            is ParkTarget.Wander -> "Wandering the paths"
            else -> "Walking to ${state.displayName(activity.target)}"
        }
        is GuestActivity.Queueing -> "Queueing for ${state.displayName(activity.target)}"
        is GuestActivity.Engaged -> "Enjoying ${state.displayName(activity.target)}"
        is GuestActivity.Departed -> "Left the park"
    }
}

// endregion

// region Attraction inspector

class AttractionDetail(attraction: Attraction) {
    /** One upgrade track on one ride. A null cost means it is already at its maximum. */
    class UpgradeLine(
        val id: String,
        val kind: RideUpgradeKind,
        val displayName: String,
        val summary: String,
        val symbolName: String,
        val level: Int,
        val maxLevel: Int,
        val cost: Double?,
    )

    val id: UUID = attraction.id
    val name: String = attraction.name
    val isOpen: Boolean = attraction.isOpen

    /** Shut by an inspector. Separate from [isOpen], which is the player's own switch. */
    val isImpounded: Boolean = attraction.isImpounded
    val status: String = attraction.statusDescription
    val condition: Double = attraction.condition
    val queueLength: Int = attraction.queue.size
    val guestsToday: Int = attraction.guestsToday
    val totalGuests: Int = attraction.totalGuests
    val satisfaction: Double? = attraction.averageSatisfaction

    /** Set for a ride the player laid their own track for, which is the only kind that can be repainted. */
    val isCustomCoaster: Boolean = attraction.baseDefinition?.kind == AttractionKind.custom
    val livery: ParkColour = attraction.livery
    val carStyle: CoasterCarStyle = attraction.carStyle

    /** The colour the player picked for this one ride, if any. */
    val tint: ParkColour? = attraction.tint
    val trackLength: Int = attraction.trackLength
    val coaster: CoasterRating? = attraction.coaster
    val intensityText: String = intensityLabel(attraction.coaster?.intensity ?: 0.0)

    val upgrades: List<UpgradeLine>
    val typeName: String
    val capacity: Int
    val rideDuration: Double
    val excitement: Double
    val nauseaRating: Double
    val operatingCostPerCycle: Double
    val estimatedWait: Double

    init {
        val ridePrice = attraction.baseDefinition?.purchasePrice ?: 0.0
        upgrades = UpgradeContent.rideUpgrades.map { upgrade ->
            val level = attraction.upgradeLevel(upgrade.kind)
            val next = level + 1
            UpgradeLine(upgrade.kind.name, upgrade.kind, upgrade.displayName, upgrade.summary, upgrade.symbolName,
                level, upgrade.maxLevel, if (next <= upgrade.maxLevel) upgrade.cost(next, ridePrice) else null)
        }

        val definition = attraction.definition
        if (definition != null) {
            typeName = definition.displayName
            capacity = definition.capacity
            rideDuration = definition.rideDuration
            excitement = definition.excitement
            nauseaRating = definition.nausea
            operatingCostPerCycle = definition.operatingCostPerCycle
            estimatedWait = attraction.estimatedWait(definition)
        } else {
            typeName = "Unknown"
            capacity = 0
            rideDuration = 0.0
            excitement = 0.0
            nauseaRating = 0.0
            operatingCostPerCycle = 0.0
            estimatedWait = 0.0
        }
    }

    val waitText: String
        get() {
            val minutes = estimatedWait.toInt() / 60
            val seconds = estimatedWait.toInt() % 60
            return if (minutes > 0) "${minutes}m ${seconds}s" else "${seconds}s"
        }

    val satisfactionText: String
        get() = satisfaction?.let { String.format("%.0f%%", SimMath.clamp(it / 20 * 100)) } ?: "No data yet"

    companion object {
        private fun intensityLabel(intensity: Double): String = when {
            intensity < 15 -> "Gentle"
            intensity < 40 -> "Moderate"
            intensity < 65 -> "Strong"
            else -> "Extreme"
        }
    }
}

// endregion

// region Facility inspector

class FacilityDetail(facility: Facility) {
    class ShopUpgradeLine(
        val id: String,
        val kind: ShopUpgradeKind,
        val displayName: String,
        val summary: String,
        val symbolName: String,
        val level: Int,
        val maxLevel: Int,
        val cost: Double?,
    )

    val id: UUID = facility.id
    val name: String = facility.name
    val isOpen: Boolean = facility.isOpen
    val price: Double = facility.price
    val queueLength: Int = facility.queue.size
    val customersToday: Int = facility.customersToday
    val totalCustomers: Int = facility.totalCustomers

    /** Prizes handed over, which is the only thing a booth's owner watches. */
    val prizesGiven: Int = facility.prizesGiven
    val revenueToday: Double = facility.revenueToday
    val totalRevenue: Double = facility.totalRevenue
    val totalCost: Double = facility.totalCost
    val sentiment: Double? = facility.priceSentiment

    /** How far through being cleaned it is, 0 to 1, or null when it is not. */
    val cleaningProgress: Double? = facility.cleaningProgress

    /** How dirty or full it is, 0-100, for the kinds a janitor looks after. */
    val soiling: Double? = if (facility.definition?.kind?.needsServicing == true) facility.soiling else null

    /** What the two counts above are counting: customers at a shop, visits to a restroom, guests sat at a bench. */
    val visitorNoun: String = facility.definition?.kind?.visitorNoun ?: "Customers"

    val upgrades: List<ShopUpgradeLine>
    val typeName: String
    val isGame: Boolean
    val sellsGoods: Boolean
    val unitCost: Double
    val referencePrice: Double

    init {
        val shopPrice = facility.baseDefinition?.purchasePrice ?: 0.0
        val definition = facility.definition
        upgrades = if (definition != null && definition.acceptsUpgrades) {
            ShopUpgradeKind.entries.map { upgrade ->
                val level = facility.upgradeLevel(upgrade)
                val next = level + 1
                ShopUpgradeLine(upgrade.name, upgrade, upgrade.displayName(definition.kind),
                    upgrade.summary(definition.kind), upgrade.symbolName, level, upgrade.maxLevel,
                    if (next <= upgrade.maxLevel) upgrade.cost(next, shopPrice) else null)
            }
        } else emptyList()

        if (definition != null) {
            typeName = definition.displayName
            isGame = definition.kind == FacilityKind.game
            sellsGoods = definition.kind.sellsGoods
            unitCost = definition.unitCost
            referencePrice = definition.referencePrice
        } else {
            typeName = "Unknown"
            isGame = false
            sellsGoods = false
            unitCost = 0.0
            referencePrice = 0.0
        }
    }

    val profitPerSale: Double get() = price - unitCost

    val sentimentText: String
        get() = sentiment?.let { GuestEconomics.sentimentLabel(it) } ?: "No sales yet"
}

// endregion

// region Staff inspector

class StaffDetail(staff: Staff, state: GameState) {
    val id: UUID = staff.id
    val name: String = staff.name
    val roleName: String = staff.roleTitle
    val symbolName: String = staff.definition?.symbolName ?: "person.fill"
    val activityText: String = describe(staff, state)
    val tasksCompleted: Int = staff.tasksCompleted
    val dailyWage: Double = staff.dailyWage
    val trainingLevel: Int = staff.trainingLevel
    val maxTrainingLevel: Int = UpgradeContent.staffTraining.maxLevel
    val trainingTitle: String = staff.trainingTitle
    val role: StaffRole = staff.role

    /** How an entertainer or a mascot is dressed, for the panel that changes it. */
    val style: StaffStyle = staff.style

    /** Sent somewhere by the player, for the button that sends them back to work. */
    val isOnOrders: Boolean = staff.isOnOrders

    /** Null once the employee has had all the training there is. */
    val trainingCost: Double? = run {
        val next = staff.trainingLevel + 1
        if (next <= UpgradeContent.staffTraining.maxLevel)
            UpgradeContent.staffTraining.cost(next, staff.definition?.hiringCost ?: 0.0)
        else null
    }

    companion object {
        /** What they are doing, including the parts of a train journey. */
        fun describe(member: Staff, state: GameState): String {
            val transfer = member.transfer
            if (transfer != null) {
                val job = member.currentJob?.let { describeJob(it, state) } ?: "their job"
                return if (transfer.boarded) "Riding the train to $job" else "Waiting for the train to $job"
            }
            val activity = member.activity
            if (activity is StaffActivity.Working && activity.job is StaffJob.GoTo) {
                return "Holding the spot you moved them to"
            }
            return describe(activity, state)
        }

        fun describe(activity: StaffActivity, state: GameState): String = when (activity) {
            is StaffActivity.Idle -> "Looking for something to do"
            is StaffActivity.Travelling -> "On the way to ${describeJob(activity.job, state)}"
            is StaffActivity.Working -> describeJob(activity.job, state).replaceFirstChar { it.uppercase() }
        }

        private fun describeJob(job: StaffJob, state: GameState): String = when (job) {
            is StaffJob.CleanLitter -> "sweeping up litter"
            is StaffJob.ServiceFacility -> {
                val facility = state.facility(job.id)
                if (facility == null) "servicing a facility"
                else "${facility.definition?.kind?.servicingVerb?.lowercase() ?: "cleaning"} ${facility.name}"
            }
            is StaffJob.RepairRide -> "repairing ${state.attraction(job.id)?.name ?: "a ride"}"
            is StaffJob.InspectRide -> "inspecting ${state.attraction(job.id)?.name ?: "a ride"}"
            is StaffJob.GoTo -> "the spot you moved them to"
            is StaffJob.Entertain -> "entertaining the crowd"
            is StaffJob.Patrol -> "keeping an eye on things"
            is StaffJob.Escort -> "escorting ${state.guest(job.guestID)?.name ?: "a troublemaker"} out"
        }
    }
}

// endregion

// region Finance

class FinanceSnapshot(ledger: Ledger) {
    class Line(val id: String, val label: String, val amount: Double)

    val todayRevenue = revenueLines(ledger.today)
    val todayExpenses = expenseLines(ledger.today)
    val lifetimeRevenue = revenueLines(ledger.lifetime)
    val lifetimeExpenses = expenseLines(ledger.lifetime)
    val todayTotalRevenue = ledger.today.totalRevenue
    val todayTotalExpenses = ledger.today.totalExpenses
    val todayProfit = ledger.today.profit
    val lifetimeTotalRevenue = ledger.lifetime.totalRevenue
    val lifetimeTotalExpenses = ledger.lifetime.totalExpenses
    val lifetimeProfit = ledger.lifetime.profit
    val yesterdayProfit: Double? = ledger.yesterday?.profit

    companion object {
        private fun revenueLines(period: LedgerPeriod) =
            RevenueCategory.entries.map { Line(it.name, it.displayName, period.amount(it)) }

        private fun expenseLines(period: LedgerPeriod) =
            ExpenseCategory.entries.map { Line(it.name, it.displayName, period.amount(it)) }
    }
}

// endregion

// region Management dashboard

class DashboardSnapshot(state: GameState, ratingComponents: List<RatingSystem.Component>) {
    class RatingLine(val id: String, val weight: Double, val value: Double)
    class RoleCount(val id: String, val count: Int)

    val cash = state.ledger.cash
    val guestCount = state.guestCount
    val parkRating = state.parkRating
    val starRating = state.starRating
    val todayProfit = state.ledger.today.profit
    val averageHappiness = state.averageHappiness
    val averageHunger = average(state) { it.hunger }
    val averageThirst = average(state) { it.thirst }
    val averageEnergy = average(state) { it.energy }
    val commonComplaint: String? = state.statistics.commonComplaint
    val arrivalsPerMinute = state.currentArrivalsPerMinute

    val attractionCount = state.attractions.size
    val closedAttractions = state.attractions.count { !it.isOpen }
    val averageQueueLength: Double =
        if (state.attractions.isEmpty()) 0.0 else state.attractions.sumOf { it.queue.size }.toDouble() / state.attractions.size
    private val ranked = state.attractions.sortedByDescending { it.totalGuests }
    val mostPopular: String? = ranked.firstOrNull()?.let { "${it.name} (${it.totalGuests})" }
    val leastPopular: String? = if (ranked.size > 1) ranked.last().let { "${it.name} (${it.totalGuests})" } else null

    val facilityCount = state.facilities.size
    val brokenRides = state.attractions.count { it.isBroken }
    val cleanliness = state.map.cleanlinessScore
    val litteredTiles = state.map.litteredTiles.size
    val beauty = state.map.beautyScore
    val sceneryCount = state.scenery.size

    val staffCount = state.staff.size
    val dailyPayroll = state.dailyPayroll
    val staffOnTask = state.staff.count { !it.isIdle }
    val staffByRole = StaffRole.entries.map {
        RoleCount(StaffContent.definition(it)?.displayName ?: it.name, state.staffCount(it))
    }

    val ratingLines = ratingComponents.map { RatingLine(it.name, it.weight, it.value) }
    val finance = FinanceSnapshot(state.ledger)

    companion object {
        private fun average(state: GameState, value: (Guest) -> Double): Double {
            var total = 0.0
            var count = 0
            for (guest in state.guests) if (guest.isActive) {
                total += value(guest)
                count += 1
            }
            return if (count > 0) total / count else 0.0
        }
    }
}

// endregion

// region Selection

sealed class SelectionIdentity {
    data class Guest(val id: UUID) : SelectionIdentity()
    data class Attraction(val id: UUID) : SelectionIdentity()
    data class Facility(val id: UUID) : SelectionIdentity()
    data class Staff(val id: UUID) : SelectionIdentity()
    data class Scenery(val id: UUID) : SelectionIdentity()
}

sealed class SelectionDetail {
    abstract val identity: SelectionIdentity

    class OfGuest(val detail: GuestDetail) : SelectionDetail() {
        override val identity get() = SelectionIdentity.Guest(detail.id)
    }

    class OfAttraction(val detail: AttractionDetail) : SelectionDetail() {
        override val identity get() = SelectionIdentity.Attraction(detail.id)
    }

    class OfFacility(val detail: FacilityDetail) : SelectionDetail() {
        override val identity get() = SelectionIdentity.Facility(detail.id)
    }

    class OfStaff(val detail: StaffDetail) : SelectionDetail() {
        override val identity get() = SelectionIdentity.Staff(detail.id)
    }

    class OfScenery(val detail: SceneryDetail) : SelectionDetail() {
        override val identity get() = SelectionIdentity.Scenery(detail.id)
    }
}

// endregion
