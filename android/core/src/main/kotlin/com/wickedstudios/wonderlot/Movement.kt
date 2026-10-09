package com.wickedstudios.wonderlot

/** Anything that walks along a route over the park's tiles. */
interface Walker {
    var position: Vec2
    var tile: GridCoord
    var route: MutableList<GridCoord>
}

/**
 * Walking along a route. Shared by guests and staff so there is exactly one
 * implementation of "move towards the next tile".
 */
object Locomotion {
    enum class StepResult {
        /** Still travelling. */
        moving,

        /** The route is finished; the walker is standing on its goal. */
        arrived,

        /** The next tile is no longer walkable, so the route was discarded. */
        blocked
    }

    fun advance(walker: Walker, speed: Double, dt: Double, map: ParkMap): StepResult {
        val next = walker.route.firstOrNull() ?: return StepResult.arrived

        // The layout can change under a walker; let the caller re-plan.
        if (!map.isWalkable(next)) {
            walker.route.clear()
            return StepResult.blocked
        }

        val destination = next.centre
        val dx = destination.x - walker.position.x
        val dy = destination.y - walker.position.y
        val remaining = Math.sqrt(dx * dx + dy * dy)
        val travel = speed * dt

        if (remaining <= travel || remaining < 0.0001) {
            walker.position = destination
            walker.tile = next
            walker.route.removeAt(0)
            return if (walker.route.isEmpty()) StepResult.arrived else StepResult.moving
        }

        val scale = travel / remaining
        walker.position = Vec2(walker.position.x + dx * scale, walker.position.y + dy * scale)
        return StepResult.moving
    }
}

/**
 * Routing over walkable tiles. One breadth-first distance field per
 * destination, cached until the map changes, so hundreds of guests stay
 * affordable.
 */
class PathfindingSystem {
    companion object {
        /** Marks tiles with no route. */
        const val unreachable = Int.MAX_VALUE
    }

    private val cache = HashMap<List<GridCoord>, IntArray>()
    private var cachedGeneration = -1
    private val maxCachedFields = 160

    private fun invalidateIfNeeded(map: ParkMap) {
        if (map.generation == cachedGeneration) return
        cache.clear()
        cachedGeneration = map.generation
    }

    fun clearCache() {
        cache.clear()
        cachedGeneration = -1
    }

    /** Distance field to the nearest of [goals]. */
    fun distanceField(goals: List<GridCoord>, map: ParkMap): IntArray {
        invalidateIfNeeded(map)

        val key = goals.sortedWith(compareBy({ it.y }, { it.x }))
        cache[key]?.let { return it }

        val distances = IntArray(map.tileCount) { unreachable }
        val frontier = ArrayList<GridCoord>()

        for (goal in goals) {
            if (!map.isWalkable(goal)) continue
            val index = map.linearIndex(goal)
            if (distances[index] != 0) {
                distances[index] = 0
                frontier.add(goal)
            }
        }

        var head = 0
        while (head < frontier.size) {
            val coord = frontier[head]
            head += 1
            val distance = distances[map.linearIndex(coord)]
            for (neighbour in coord.orthogonalNeighbours) {
                if (!map.isWalkable(neighbour)) continue
                val index = map.linearIndex(neighbour)
                if (distances[index] > distance + 1) {
                    distances[index] = distance + 1
                    frontier.add(neighbour)
                }
            }
        }

        if (cache.size >= maxCachedFields) cache.clear()
        cache[key] = distances
        return distances
    }

    /** Tile distance from [start] to the nearest goal, or null when unreachable. */
    fun distance(start: GridCoord, goals: List<GridCoord>, map: ParkMap): Int? {
        if (!map.isWalkable(start) || goals.isEmpty()) return null
        val field = distanceField(goals, map)
        val value = field[map.linearIndex(start)]
        return if (value == unreachable) null else value
    }

    /** Step-by-step route from [start] to the nearest goal, excluding the starting tile. */
    fun route(start: GridCoord, goals: List<GridCoord>, map: ParkMap): MutableList<GridCoord> {
        val steps = ArrayList<GridCoord>()
        if (!map.isWalkable(start) || goals.isEmpty()) return steps
        val field = distanceField(goals, map)
        var current = start
        var currentDistance = field[map.linearIndex(current)]
        if (currentDistance == unreachable) return steps

        while (currentDistance > 0) {
            var best: GridCoord? = null
            var bestDistance = currentDistance
            for (neighbour in current.orthogonalNeighbours) {
                if (!map.isWalkable(neighbour)) continue
                val distance = field[map.linearIndex(neighbour)]
                if (distance < bestDistance) {
                    bestDistance = distance
                    best = neighbour
                }
            }
            val next = best ?: break
            steps.add(next)
            current = next
            currentDistance = bestDistance
            if (steps.size > map.tileCount) break
        }
        return steps
    }
}

/** Walks guests along the routes the AI gave them and handles what happens the moment they arrive. */
class MovementSystem(private val pathfinder: PathfindingSystem) {

    fun update(state: GameState, dt: Double) {
        val map = state.map
        val now = state.clock.simTime

        for (index in state.guests.indices) {
            val guest = state.guests[index]
            if (!guest.isActive) continue

            val target: ParkTarget? = when (val activity = guest.activity) {
                is GuestActivity.Walking -> activity.target
                is GuestActivity.Arriving, is GuestActivity.Exploring -> null
                else -> continue
            }

            if (guest.route.isEmpty()) {
                if (target != null) beginActivity(target, index, state, now)
                continue
            }

            when (Locomotion.advance(guest, guest.walkSpeed, dt, map)) {
                Locomotion.StepResult.moving -> {}
                Locomotion.StepResult.arrived -> {
                    if (target != null) beginActivity(target, index, state, now)
                    else guest.activity = GuestActivity.Exploring
                }
                Locomotion.StepResult.blocked -> replan(index, target, state, map, now)
            }
        }
    }

    /** Something was built or demolished across the guest's path. */
    private fun replan(guestIndex: Int, target: ParkTarget?, state: GameState, map: ParkMap, now: Double) {
        val guest = state.guests[guestIndex]
        if (target == null) {
            guest.activity = GuestActivity.Exploring
            guest.nextDecisionAt = now
            return
        }

        val access = state.accessTiles(target)
        val route = pathfinder.route(guest.tile, access, map)
        if (route.isEmpty()) {
            guest.activity = GuestActivity.Exploring
            guest.nextDecisionAt = now
        } else {
            guest.route = route
        }
    }

    companion object {
        /** What a guest does the instant it reaches its goal: join a queue, take a seat, leave, or look around. */
        fun beginActivity(target: ParkTarget, guestIndex: Int, state: GameState, now: Double) {
            val guest = state.guests[guestIndex]
            when (target) {
                is ParkTarget.Ride -> {
                    val attraction = state.attraction(target.id)
                    val definition = attraction?.definition
                    if (attraction == null || definition == null || !attraction.isOperational) {
                        sendExploring(guestIndex, state, now)
                        return
                    }

                    val queueCapacity = definition.capacity * 6
                    if (attraction.queue.size >= queueCapacity) {
                        guest.think(ThoughtCatalog.queueTooLong(attraction.name), ThoughtMood.negative, now, ThoughtIcon.queue)
                        sendExploring(guestIndex, state, now)
                        return
                    }

                    val wait = attraction.estimatedWait(definition)
                    attraction.queue.add(guest.id)
                    guest.activity = GuestActivity.Queueing(target)
                    guest.queueJoinedAt = now
                    guest.queueWaitEstimate = wait
                    guest.queueSlot = attraction.queue.size - 1
                }

                is ParkTarget.Shop -> {
                    val facility = state.facility(target.id)
                    val definition = facility?.definition
                    if (facility == null || definition == null || !facility.isAcceptingGuests || facility.isUnusable) {
                        if (facility != null && facility.isUnusable) {
                            guest.think(unusableThought(facility), ThoughtMood.negative, now)
                        }
                        sendExploring(guestIndex, state, now)
                        return
                    }

                    if (facility.queue.size >= definition.queueCapacity) {
                        guest.think(ThoughtCatalog.queueTooLong(facility.name), ThoughtMood.negative, now, ThoughtIcon.queue)
                        sendExploring(guestIndex, state, now)
                        return
                    }

                    val wait = facility.estimatedWait(definition)
                    facility.queue.add(guest.id)
                    guest.activity = GuestActivity.Queueing(target)
                    guest.queueJoinedAt = now
                    guest.queueWaitEstimate = wait
                    guest.queueSlot = facility.queue.size - 1
                }

                is ParkTarget.Exit -> depart(guestIndex, state)

                is ParkTarget.Wander -> {
                    guest.activity = GuestActivity.Exploring
                    guest.nextDecisionAt = now
                }
            }
        }

        private fun unusableThought(facility: Facility): String =
            if (facility.definition?.kind == FacilityKind.bin) "That bin is overflowing."
            else "That restroom is in a disgusting state."

        private fun sendExploring(guestIndex: Int, state: GameState, now: Double) {
            val guest = state.guests[guestIndex]
            guest.activity = GuestActivity.Exploring
            guest.route = mutableListOf()
            guest.nextDecisionAt = now + 2
        }

        /** Removes the guest from play and books the statistics for its visit. */
        fun depart(guestIndex: Int, state: GameState) {
            val guest = state.guests[guestIndex]
            val reason = guest.departureReason ?: DepartureReason.satisfied.text
            state.statistics.recordDeparture(reason)

            // A reviewer's opinion is only complete on the way out.
            if (guest.isCritic) CriticSystem.publish(guestIndex, state)

            guest.activity = GuestActivity.Departed
            guest.route = mutableListOf()
        }
    }
}
