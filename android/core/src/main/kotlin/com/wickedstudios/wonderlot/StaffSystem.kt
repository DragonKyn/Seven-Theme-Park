package com.wickedstudios.wonderlot

import java.util.UUID
import kotlin.math.abs

/**
 * Employees: wages, choosing their own work, walking to it, and doing it. Job
 * search runs a single breadth-first sweep outwards from the staff member's own
 * tile and reads every candidate's distance out of it.
 */
class StaffSystem(private val pathfinder: PathfindingSystem) {

    /** Which stretches of walkway join, worked out once per change to the map. */
    private var islandCacheGeneration = -1
    private var islandCache: IntArray? = null

    private fun islandLabels(map: ParkMap): IntArray {
        val cached = islandCache
        if (cached != null && islandCacheGeneration == map.generation) return cached
        val labels = StaffTransit.islands(map)
        islandCache = labels
        islandCacheGeneration = map.generation
        return labels
    }

    fun update(state: GameState, dt: Double) {
        chargeWages(state, dt)
        releaseAbandonedCleaning(state)
        if (state.staff.isEmpty()) return

        val map = state.map
        val now = state.clock.simTime
        val claimed = claimedJobs(state)

        for (member in state.staff.toList()) {
            when (val activity = member.activity) {
                is StaffActivity.Idle -> {
                    if (now < member.nextJobSearchAt) continue
                    member.nextJobSearchAt = now + Balance.staffJobSearchInterval

                    // What the player asked for comes before anything the employee would have picked.
                    val ordered = member.orders
                    member.orders = null
                    val job = ordered ?: findJob(member, state, map, claimed)

                    if (job != null && beginTravel(job, member, state, map)) {
                        claimed.add(job)
                    } else if (ordered != null) {
                        stand(member, ordered, state, map)
                    }
                }
                is StaffActivity.Travelling -> travel(member, activity.job, state, map, dt, now)
                is StaffActivity.Working -> work(member, activity.job, state, dt, now)
            }
        }
    }

    // region Restrooms being cleaned

    /** A restroom reopens if whoever was cleaning it stops: dismissed, or reassigned. */
    private fun releaseAbandonedCleaning(state: GameState) {
        for (facility in state.facilities) {
            if (!facility.isBeingCleaned) continue
            val id = facility.id
            val attended = state.staff.any { member ->
                val activity = member.activity
                activity is StaffActivity.Working &&
                    (activity.job as? StaffJob.ServiceFacility)?.id == id
            }
            if (!attended) {
                facility.cleaningRemaining = 0.0
                facility.cleaningTotal = 0.0
            }
        }
    }

    /** Shuts a restroom and sends away anybody waiting for it; whoever is inside finishes. */
    private fun beginCleaning(facilityID: UUID, state: GameState) {
        val facility = state.facility(facilityID) ?: return
        val definition = facility.definition ?: return
        if (definition.cleaningMinutes <= 0) return

        val dirt = facility.soiling / 100
        val total = definition.cleaningMinutes * (1 + Balance.cleaningDirtExtra * dirt)
        facility.cleaningTotal = total
        facility.cleaningRemaining = total

        val now = state.clock.simTime
        for (guestID in facility.queue) {
            val guest = state.guest(guestID) ?: continue
            guest.activity = GuestActivity.Exploring
            guest.queueWaitEstimate = 0.0
            guest.nextDecisionAt = now
        }
        facility.queue.clear()
    }

    private fun cleanRestroom(member: Staff, facility: Facility, state: GameState, dt: Double, now: Double) {
        // Wait for the last user to come out.
        if (facility.slots.isNotEmpty()) return

        facility.cleaningRemaining -= member.workRate * dt
        if (facility.cleaningRemaining > 0) return

        facility.cleaningRemaining = 0.0
        facility.cleaningTotal = 0.0
        facility.soiling = 0.0
        facility.timesServiced += 1
        finish(member, now)
    }

    // endregion

    private fun chargeWages(state: GameState, dt: Double) {
        if (state.staff.isEmpty()) return
        val perSecond = state.staff.sumOf { it.wagePerSecond }
        state.ledger.spend(perSecond * state.perks.wageFactor * dt, ExpenseCategory.wages)
    }

    // region Job assignment

    private fun claimedJobs(state: GameState): MutableSet<StaffJob> {
        val claimed = HashSet<StaffJob>()
        for (member in state.staff) member.currentJob?.let { claimed.add(it) }
        return claimed
    }

    private fun findJob(member: Staff, state: GameState, map: ParkMap, claimed: Set<StaffJob>): StaffJob? {
        if (!map.isWalkable(member.tile)) return null

        // Distances from this employee to everywhere, in one sweep.
        val field = pathfinder.distanceField(listOf(member.tile), map)

        // Somewhere only reachable by train still counts.
        val transit = StaffTransit.create(state, field, islandLabels(map))

        fun walkingDistance(coord: GridCoord): Int? {
            if (!map.isWalkable(coord)) return null
            val value = field[map.linearIndex(coord)]
            return if (value == PathfindingSystem.unreachable) null else value
        }

        fun distance(coord: GridCoord): Int? {
            walkingDistance(coord)?.let { return it }
            if (!map.isWalkable(coord)) return null
            return transit?.plan(listOf(coord))?.cost
        }

        fun nearestAccess(rect: GridRect): Int? {
            val tiles = map.accessTiles(rect)
            tiles.mapNotNull { walkingDistance(it) }.minOrNull()?.let { return it }
            return transit?.plan(tiles)?.cost
        }

        when (member.role) {
            StaffRole.janitor -> {
                var bestJob: StaffJob? = null
                var bestScore = -Double.MAX_VALUE

                // Bins and restrooms first: they are the cause, litter is the symptom.
                for (facility in state.facilities) {
                    val priority = facility.servicingPriority ?: continue
                    val job = StaffJob.ServiceFacility(facility.id)
                    if (job in claimed) continue
                    val steps = nearestAccess(facility.rect) ?: continue
                    val score = priority * 4 - steps
                    if (score > bestScore) {
                        bestScore = score
                        bestJob = job
                    }
                }

                for (coord in map.litteredTiles) {
                    val job = StaffJob.CleanLitter(coord)
                    if (job in claimed) continue
                    val steps = distance(coord) ?: continue
                    val score = map.litter(coord) - steps * 3
                    if (score > bestScore) {
                        bestScore = score
                        bestJob = job
                    }
                }

                return bestJob
            }

            StaffRole.mechanic -> {
                var bestJob: StaffJob? = null
                var bestScore = -Double.MAX_VALUE
                for (attraction in state.attractions) {
                    val priority = attraction.maintenancePriority ?: continue
                    // A ride an inspector shut needs putting right, not looking over.
                    val job = if (attraction.isBroken || attraction.isImpounded) StaffJob.RepairRide(attraction.id)
                    else StaffJob.InspectRide(attraction.id)
                    if (job in claimed) continue
                    val steps = nearestAccess(attraction.rect) ?: continue
                    val score = priority - steps
                    if (score > bestScore) {
                        bestScore = score
                        bestJob = job
                    }
                }
                return bestJob
            }

            StaffRole.entertainer, StaffRole.mascot -> {
                // Head for whichever queue is longest; failing that, wander.
                val busiest = state.attractions.filter { it.queue.isNotEmpty() }.maxByOrNull { it.queue.size }

                if (busiest != null) {
                    val spot = map.accessTiles(busiest.rect).firstOrNull { distance(it) != null }
                    if (spot != null) {
                        val job = StaffJob.Entertain(spot)
                        if (job !in claimed) return job
                    }
                }

                // A mascot goes where the people are, which is what it is for.
                if (member.role == StaffRole.mascot) {
                    crowdedSpot(map, field, state)?.let { return StaffJob.Entertain(it) }
                }

                randomReachableTile(map, field, state)?.let { return StaffJob.Entertain(it) }
                return null
            }

            StaffRole.security -> {
                // A troublemaker outranks any post.
                val now = state.clock.simTime
                val target = state.guests.firstOrNull {
                    it.isActive && it.isTroublemaker && TroublemakerSystem.isNoticed(it, now) &&
                        StaffJob.Escort(it.id) !in claimed
                }
                if (target != null && walkingDistance(target.tile) != null) return StaffJob.Escort(target.id)

                // The gate most of the time; a lap of the park the rest of the time.
                if (!state.rng.chance(Balance.securityPatrolChance)) {
                    gatePost(map, state, claimed, ::distance)?.let { return StaffJob.Patrol(it) }
                }
                randomReachableTile(map, field, state)?.let { return StaffJob.Patrol(it) }
                gatePost(map, state, claimed, ::distance)?.let { return StaffJob.Patrol(it) }
                return null
            }
        }
    }

    /** A spot to stand near the front gate that nobody else has taken. */
    private fun gatePost(map: ParkMap, state: GameState, claimed: Set<StaffJob>, distance: (GridCoord) -> Int?): GridCoord? {
        val gate = map.entranceCoord
        val reach = Balance.securityGateRadius
        val posts = ArrayList<GridCoord>()

        for (dx in -reach..reach) {
            for (dy in 0..reach) {
                val coord = GridCoord(gate.x + dx, gate.y + dy)
                if (!map.isWalkable(coord) || distance(coord) == null) continue
                if (StaffJob.Patrol(coord) in claimed) continue
                posts.add(coord)
            }
        }

        if (posts.isEmpty()) return null
        return posts[state.rng.int(0..(posts.size - 1))]
    }

    private fun randomReachableTile(map: ParkMap, field: IntArray, state: GameState): GridCoord? {
        for (attempt in 0 until 8) {
            val index = state.rng.int(0..(map.tileCount - 1))
            val coord = map.coordAt(index)
            if (!map.isWalkable(coord) || field[index] == PathfindingSystem.unreachable || field[index] <= 2) continue
            return coord
        }
        return null
    }

    // endregion

    // region Travel

    private fun beginTravel(job: StaffJob, member: Staff, state: GameState, map: ParkMap): Boolean {
        val destinations = destinationTiles(job, state, map)
        if (destinations.isEmpty()) return false

        val tile = member.tile
        if (destinations.contains(tile)) {
            member.route = mutableListOf()
            member.transfer = null
            startWork(member, job, state)
            return true
        }

        val route = pathfinder.route(tile, destinations, map)
        if (route.isEmpty()) {
            // Not on foot. By train, if there is one that goes there.
            val field = pathfinder.distanceField(listOf(tile), map)
            val transit = StaffTransit.create(state, field, islandLabels(map)) ?: return false
            val hop = transit.plan(destinations) ?: return false

            val toPlatform = if (hop.boarding.contains(tile)) mutableListOf() else pathfinder.route(tile, hop.boarding, map)
            if (!(hop.boarding.contains(tile) || toPlatform.isNotEmpty())) return false

            member.transfer = hop.transfer
            member.route = toPlatform
            member.activity = StaffActivity.Travelling(job)
            return true
        }

        member.transfer = null
        member.route = route
        member.activity = StaffActivity.Travelling(job)
        return true
    }

    /**
     * An order that could not be carried out by walking or riding: the employee
     * is put on the spot, which is also how an employee stranded somewhere is got out.
     */
    private fun stand(member: Staff, order: StaffJob, state: GameState, map: ParkMap) {
        val goTo = order as? StaffJob.GoTo ?: return
        if (!map.isWalkable(goTo.spot)) return
        member.tile = goTo.spot
        member.position = goTo.spot.centre
        member.route = mutableListOf()
        member.transfer = null
        startWork(member, order, state)
    }

    private fun destinationTiles(job: StaffJob, state: GameState, map: ParkMap): List<GridCoord> = when (job) {
        is StaffJob.CleanLitter -> if (map.isWalkable(job.tile)) listOf(job.tile) else emptyList()
        is StaffJob.Entertain -> if (map.isWalkable(job.spot)) listOf(job.spot) else emptyList()
        is StaffJob.Patrol -> if (map.isWalkable(job.spot)) listOf(job.spot) else emptyList()
        is StaffJob.GoTo -> if (map.isWalkable(job.spot)) listOf(job.spot) else emptyList()
        is StaffJob.ServiceFacility -> state.facility(job.id)?.let { map.accessTiles(it.rect) } ?: emptyList()
        is StaffJob.RepairRide -> state.attraction(job.id)?.let { map.accessTiles(it.rect) } ?: emptyList()
        is StaffJob.InspectRide -> state.attraction(job.id)?.let { map.accessTiles(it.rect) } ?: emptyList()
        is StaffJob.Escort -> {
            val guest = state.guest(job.guestID)
            if (guest != null && map.isWalkable(guest.tile)) listOf(guest.tile) else emptyList()
        }
    }

    private fun travel(member: Staff, job: StaffJob, state: GameState, map: ParkMap, dt: Double, now: Double) {
        // The only job whose destination walks away while it is being walked to.
        if (job is StaffJob.Escort) {
            chase(member, job.guestID, state, map, dt, now)
            return
        }

        // Part of the way by train.
        if (member.transfer != null) {
            travelByTrain(member, job, state, map, dt, now)
            return
        }

        if (member.route.isEmpty()) {
            startWork(member, job, state)
            return
        }

        when (Locomotion.advance(member, member.effectiveWalkSpeed, dt, map)) {
            Locomotion.StepResult.moving -> {}
            Locomotion.StepResult.arrived -> startWork(member, job, state)
            Locomotion.StepResult.blocked -> {
                member.activity = StaffActivity.Idle
                member.nextJobSearchAt = now
            }
        }
    }

    // endregion

    // region By train

    private fun travelByTrain(member: Staff, job: StaffJob, state: GameState, map: ParkMap, dt: Double, now: Double) {
        val transfer = member.transfer ?: return

        // The train has to be running to be caught.
        val station = state.attraction(transfer.stationID)
        if (station == null || !station.isOperational) {
            abandonJourney(member, now)
            return
        }

        if (!transfer.boarded) {
            if (member.route.isNotEmpty()) {
                if (Locomotion.advance(member, member.effectiveWalkSpeed, dt, map) == Locomotion.StepResult.blocked) {
                    abandonJourney(member, now)
                }
                return
            }

            transfer.waiting -= dt
            if (transfer.waiting <= 0) transfer.boarded = true
            return
        }

        transfer.riding -= dt
        if (transfer.riding > 0) return

        // Off the train, and on with the job.
        member.tile = transfer.landing
        member.position = transfer.landing.centre
        member.transfer = null
        member.route = mutableListOf()

        val destinations = destinationTiles(job, state, map)
        if (destinations.contains(transfer.landing)) {
            startWork(member, job, state)
            return
        }

        val route = pathfinder.route(transfer.landing, destinations, map)
        if (route.isEmpty()) abandonJourney(member, now) else member.route = route
    }

    private fun abandonJourney(member: Staff, now: Double) {
        member.transfer = null
        member.route = mutableListOf()
        member.activity = StaffActivity.Idle
        member.nextJobSearchAt = now
    }

    // endregion

    // region Doing the work

    private fun startWork(member: Staff, job: StaffJob, state: GameState) {
        if (!isStillNeeded(job, state)) {
            member.activity = StaffActivity.Idle
            return
        }

        when (job) {
            is StaffJob.RepairRide -> {
                // An impound takes longer to lift than a breakdown takes to fix.
                val work = if (state.attraction(job.id)?.isImpounded == true) Balance.impoundRepairDuration
                else Balance.repairDuration
                member.workTimer = work / member.workRate
            }
            is StaffJob.InspectRide -> member.workTimer = Balance.inspectionDuration / member.workRate
            is StaffJob.Entertain -> member.workTimer = 25.0
            is StaffJob.Patrol -> {
                // A post at the gate is held far longer than a spot out in the park.
                val gate = state.map.entranceCoord
                val atGate = abs(job.spot.x - gate.x) <= Balance.securityGateRadius &&
                    abs(job.spot.y - gate.y) <= Balance.securityGateRadius
                member.workTimer = if (atGate) Balance.securityPostDuration else Balance.securityPatrolDuration
            }
            is StaffJob.ServiceFacility -> {
                member.workTimer = 0.0
                beginCleaning(job.id, state)
            }
            is StaffJob.GoTo -> member.workTimer = Balance.staffPostHold
            is StaffJob.CleanLitter, is StaffJob.Escort -> member.workTimer = 0.0
        }

        member.activity = StaffActivity.Working(job)
    }

    /** Work can become pointless between being assigned and being reached. */
    private fun isStillNeeded(job: StaffJob, state: GameState): Boolean = when (job) {
        is StaffJob.CleanLitter -> state.map.litter(job.tile) > 0
        is StaffJob.ServiceFacility -> (state.facility(job.id)?.soiling ?: 0.0) > 0
        is StaffJob.RepairRide -> state.attraction(job.id)?.let { it.isBroken || it.isImpounded } ?: false
        is StaffJob.InspectRide -> state.attraction(job.id)?.isInspectionOverdue == true
        is StaffJob.Entertain, is StaffJob.Patrol, is StaffJob.GoTo -> true
        is StaffJob.Escort -> state.guest(job.guestID)?.isTroublemaker == true
    }

    private fun work(member: Staff, job: StaffJob, state: GameState, dt: Double, now: Double) {
        when (job) {
            is StaffJob.CleanLitter -> {
                val remaining = state.map.removeLitter(Balance.litterCleanRate * member.workRate * dt, job.tile)
                if (remaining <= 0) {
                    state.statistics.litterCleanedTotal += 1
                    finish(member, now)
                }
            }

            is StaffJob.ServiceFacility -> {
                val facility = state.facility(job.id)
                if (facility == null) {
                    finish(member, now)
                    return
                }
                if ((facility.definition?.cleaningMinutes ?: 0.0) > 0) {
                    cleanRestroom(member, facility, state, dt, now)
                    return
                }
                facility.soiling = maxOf(0.0, facility.soiling - Balance.facilityCleanRate * member.workRate * dt)
                if (facility.soiling <= 0) {
                    facility.timesServiced += 1
                    finish(member, now)
                }
            }

            is StaffJob.RepairRide -> {
                member.workTimer -= dt
                if (member.workTimer > 0) return
                state.attraction(job.id)?.let { MaintenanceSystem.completeRepair(it, state) }
                finish(member, now)
            }

            is StaffJob.InspectRide -> {
                member.workTimer -= dt
                if (member.workTimer > 0) return
                state.attraction(job.id)?.let { MaintenanceSystem.completeInspection(it, state) }
                finish(member, now)
            }

            is StaffJob.Entertain -> {
                member.workTimer -= dt
                perform(member, state, dt, now)
                if (member.workTimer <= 0) finish(member, now)
            }

            is StaffJob.Patrol -> {
                member.workTimer -= dt
                reassureNearbyGuests(member, state, dt)
                // A post is abandoned the moment somebody needs seeing off, but not before security have clocked them.
                val index = state.troublemakerIndex
                val wanted = index != null && TroublemakerSystem.isNoticed(state.guests[index], now)
                if (member.workTimer <= 0 || wanted) finish(member, now)
            }

            is StaffJob.GoTo -> {
                // Holding the spot they were sent to, until they are left to choose their own work again.
                member.workTimer -= dt
                if (member.workTimer <= 0) finish(member, now)
            }

            is StaffJob.Escort -> {
                // Only reached when the guard was already standing on them.
                val guestIndex = state.guestIndex(job.guestID)
                if (guestIndex == null || !state.guests[guestIndex].isTroublemaker) {
                    finish(member, now)
                    return
                }
                TroublemakerSystem.remove(guestIndex, state, member.name)
                finish(member, now)
            }
        }
    }

    /** Security walking down somebody who is walking away. */
    private fun chase(member: Staff, guestID: UUID, state: GameState, map: ParkMap, dt: Double, now: Double) {
        val guestIndex = state.guestIndex(guestID)
        if (guestIndex == null || !state.guests[guestIndex].isTroublemaker) {
            member.route = mutableListOf()
            member.activity = StaffActivity.Idle
            member.nextJobSearchAt = now
            return
        }
        val guest = state.guests[guestIndex]

        // Close enough to have a word.
        if (SimMath.distance(member.position, guest.position) <= Balance.escortCatchRadius) {
            TroublemakerSystem.remove(guestIndex, state, member.name)
            finish(member, now)
            return
        }

        member.workTimer -= dt
        if (member.workTimer <= 0 || member.route.isEmpty()) {
            member.workTimer = Balance.escortRepathInterval
            val route = pathfinder.route(member.tile, listOf(guest.tile), map)
            if (route.isEmpty()) {
                // Nowhere to walk to. Give it up rather than stand there.
                member.activity = StaffActivity.Idle
                member.nextJobSearchAt = now + Balance.staffJobSearchInterval
                return
            }
            member.route = route
        }

        // Arriving where they used to be, and being blocked, mean the same thing: plan again next tick.
        when (Locomotion.advance(member, member.effectiveWalkSpeed, dt, map)) {
            Locomotion.StepResult.moving -> {}
            Locomotion.StepResult.arrived, Locomotion.StepResult.blocked -> {
                member.route = mutableListOf()
                member.workTimer = 0.0
            }
        }
    }

    private val balloonColours = listOf(
        ParkColour.red, ParkColour.yellow, ParkColour.green, ParkColour.blue,
        ParkColour.pink, ParkColour.orange, ParkColour.violet,
    )

    /**
     * Everything an entertainer or a mascot does while performing: lift the
     * mood of whoever is in range, and whatever else the act adds to that.
     */
    private fun perform(member: Staff, state: GameState, dt: Double, now: Double) {
        val profile = PerformerProfile.of(member)
        val base = Balance.entertainerHappinessPerSecond * profile.happinessFactor * member.workRate * dt

        val audience = ArrayList<Guest>()
        for (guest in state.guests) {
            if (!guest.isActive) continue
            if (SimMath.distance(guest.position, member.position) > profile.radius) continue

            var lift = base
            if (guest.ageCategory == AgeCategory.child) lift *= profile.childFactor
            if (guest.activity is GuestActivity.Queueing) lift *= profile.queueFactor
            guest.adjustHappiness(lift)
            audience.add(guest)
        }
        if (audience.isEmpty()) return

        if (profile.handsOutBalloons && state.rng.chance(Balance.balloonHandoutPerSecond * member.workRate * dt)) {
            handOutBalloon(audience, state, now)
        }
        if (profile.doesTricks && state.rng.chance(dt / Balance.magicTrickInterval)) {
            amaze(audience, state, now)
        }
    }

    /** A balloon for somebody who has not got one, a child if there is one. */
    private fun handOutBalloon(audience: List<Guest>, state: GameState, now: Double) {
        val without = audience.filter { it.balloon == null }
        if (without.isEmpty()) return
        val children = without.filter { it.ageCategory == AgeCategory.child }
        val pool = if (children.isEmpty()) without else children

        val guest = pool[state.rng.int(0..(pool.size - 1))]
        guest.balloon = balloonColours[state.rng.int(0..(balloonColours.size - 1))]
        guest.adjustHappiness(Balance.balloonHappiness)
        guest.think("A balloon! For me?", ThoughtMood.positive, now)
    }

    private fun amaze(audience: List<Guest>, state: GameState, now: Double) {
        val guest = audience[state.rng.int(0..(audience.size - 1))]
        guest.adjustHappiness(Balance.magicTrickHappiness)
        guest.think("How did they do that?!", ThoughtMood.positive, now)
    }

    /** Where the people are: the best of a few places picked at random. */
    private fun crowdedSpot(map: ParkMap, field: IntArray, state: GameState): GridCoord? {
        var best: GridCoord? = null
        var bestCount = 0
        for (sample in 0 until Balance.mascotSpotSamples) {
            val coord = randomReachableTile(map, field, state) ?: continue
            var nearby = 0
            for (guest in state.guests) {
                if (guest.isActive && SimMath.distance(guest.position, coord.centre) <= Balance.entertainerRadius) nearby += 1
            }
            if (nearby > bestCount) {
                bestCount = nearby
                best = coord
            }
        }
        return best
    }

    /** A guard on a post makes the people around them feel looked after. */
    private fun reassureNearbyGuests(member: Staff, state: GameState, dt: Double) {
        val centre = member.position
        val radius = Balance.securityRadius
        val boost = Balance.securityHappinessPerSecond * dt

        for (guest in state.guests) {
            if (!guest.isActive) continue
            if (SimMath.distance(guest.position, centre) > radius) continue
            guest.adjustHappiness(boost)
        }
    }

    private fun finish(member: Staff, now: Double) {
        member.tasksCompleted += 1
        member.activity = StaffActivity.Idle
        member.workTimer = 0.0
        member.nextJobSearchAt = now
    }

    // endregion
}
