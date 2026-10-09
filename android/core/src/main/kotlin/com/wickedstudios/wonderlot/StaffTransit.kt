package com.wickedstudios.wonderlot

import java.util.UUID

/** A way to get somewhere on foot and by train, and what it is worth. */
class TrainHop(
    /** Where on the platform to stand. */
    val boarding: List<GridCoord>,
    val transfer: StaffTransfer,
    /** Tiles-equivalent length of the whole trip, for comparing it with jobs reachable on foot. */
    val cost: Int,
)

/**
 * Works out whether, and how, an employee can reach somewhere by train. Built
 * once per job search; the expensive part, finding which stretches of walkway
 * join, is shared.
 */
class StaffTransit private constructor(
    private val map: ParkMap,
    private val stations: List<Station>,
    private val labels: IntArray,
    private val field: IntArray,
) {
    class Station(val id: UUID, val route: Int, /** Tiles an employee can stand on to use it. */ val platforms: List<GridCoord>)

    private fun walkingDistance(coord: GridCoord): Int? {
        if (!map.isInside(coord)) return null
        val value = field[map.linearIndex(coord)]
        return if (value == PathfindingSystem.unreachable) null else value
    }

    /** The best way to reach any of [destinations], or null when no train gets there. */
    fun plan(destinations: List<GridCoord>): TrainHop? {
        val wanted = destinations.mapNotNull { label(it) }.toSet()
        if (wanted.isEmpty()) return null

        var best: TrainHop? = null
        for (from in stations) {
            // The nearest platform the employee can actually walk to.
            var walk: Int? = null
            for (tile in from.platforms) {
                val distance = walkingDistance(tile) ?: continue
                if (distance < (walk ?: Int.MAX_VALUE)) walk = distance
            }
            val walkToPlatform = walk ?: continue

            for (to in stations) {
                if (to.id == from.id || to.route != from.route) continue
                for (landing in to.platforms) {
                    val island = label(landing) ?: continue
                    if (island !in wanted) continue
                    val onward = destinations.minOfOrNull { landing.manhattanDistance(it) } ?: 0
                    val cost = walkToPlatform + Balance.staffTrainTiles + onward
                    if (cost >= (best?.cost ?: Int.MAX_VALUE)) continue

                    best = TrainHop(
                        from.platforms,
                        StaffTransfer(from.id, landing, Balance.staffTrainWait, Balance.staffTrainRide),
                        cost,
                    )
                }
            }
        }
        return best
    }

    private fun label(coord: GridCoord): Int? {
        if (!map.isInside(coord)) return null
        val value = labels[map.linearIndex(coord)]
        return if (value >= 0) value else null
    }

    companion object {
        /** Null when there is nothing to ride: fewer than two working stations on the same railway. */
        fun create(state: GameState, field: IntArray, labels: IntArray): StaffTransit? {
            val map = state.map
            val network = state.trackNetwork
            if (network.isEmpty) return null

            val stations = ArrayList<Station>()
            for (attraction in state.attractions) {
                if (!attraction.isOperational) continue
                if (attraction.definition?.kind != AttractionKind.transport) continue
                val route = network.routeIndex(attraction.rect) ?: continue
                val platforms = map.accessTiles(attraction.rect)
                if (platforms.isEmpty()) continue
                stations.add(Station(attraction.id, route, platforms))
            }
            if (stations.size <= 1) return null

            return StaffTransit(map, stations, labels, field)
        }

        /**
         * Numbers every stretch of walkway that joins up, by tile, with -1 for
         * anything not walkable. Two tiles with the same number can be walked between.
         */
        fun islands(map: ParkMap): IntArray {
            val labels = IntArray(map.tileCount) { -1 }
            var next = 0

            for (start in 0 until map.tileCount) {
                if (labels[start] >= 0) continue
                val origin = map.coordAt(start)
                if (!map.isWalkable(origin)) continue

                labels[start] = next
                val frontier = ArrayList<GridCoord>()
                frontier.add(origin)
                while (frontier.isNotEmpty()) {
                    val coord = frontier.removeAt(frontier.lastIndex)
                    for (neighbour in coord.orthogonalNeighbours) {
                        if (!map.isWalkable(neighbour)) continue
                        val index = map.linearIndex(neighbour)
                        if (labels[index] >= 0) continue
                        labels[index] = next
                        frontier.add(neighbour)
                    }
                }
                next += 1
            }
            return labels
        }
    }
}
