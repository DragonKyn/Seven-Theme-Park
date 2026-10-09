package com.wickedstudios.wonderlot

/**
 * The railway the player has laid, worked out from the track tiles on the map.
 * A route is an ordered ring of tiles a train can run without ever jumping,
 * which is also what decides whether two stations are connected.
 */
class TrackNetwork(val routes: List<Route>) {

    /** One connected run of track, ordered so consecutive tiles touch. */
    class Route(val tiles: List<GridCoord>, val isLoop: Boolean)

    val isEmpty: Boolean get() = routes.isEmpty()

    /** Which route, if any, a building's footprint sits against. */
    fun routeIndex(rect: GridRect): Int? {
        val adjacent = rect.adjacentCoords.toSet()
        for ((index, route) in routes.withIndex()) {
            if (route.tiles.any { it in adjacent }) return index
        }
        return null
    }

    companion object {
        val empty = TrackNetwork(emptyList())

        fun build(map: ParkMap, terrains: Set<TerrainType> = setOf(TerrainType.track)): TrackNetwork {
            val remaining = HashSet<GridCoord>()
            for (terrain in terrains) remaining.addAll(map.coords(terrain))
            if (remaining.isEmpty()) return empty

            val routes = ArrayList<Route>()
            while (remaining.isNotEmpty()) {
                val seed = remaining.first()
                val component = flood(seed, remaining)
                // A single tile of track is somebody halfway through drawing a line.
                if (component.size <= 1) continue
                val route = order(component) ?: continue
                routes.add(route)
            }
            return TrackNetwork(routes)
        }

        private fun flood(seed: GridCoord, remaining: MutableSet<GridCoord>): Set<GridCoord> {
            val component = HashSet<GridCoord>()
            val stack = ArrayList<GridCoord>()
            stack.add(seed)
            while (stack.isNotEmpty()) {
                val coord = stack.removeAt(stack.lastIndex)
                if (!remaining.remove(coord)) continue
                component.add(coord)
                for (neighbour in coord.orthogonalNeighbours) {
                    if (neighbour in remaining) stack.add(neighbour)
                }
            }
            return component
        }

        /** Walks a connected clump of track into a driveable order. */
        private fun order(component: Set<GridCoord>): Route? {
            fun neighbours(coord: GridCoord) = coord.orthogonalNeighbours.filter { it in component }

            val endpoint = component.firstOrNull { neighbours(it).size == 1 }
            val start = endpoint ?: component.firstOrNull() ?: return null

            val ordered = ArrayList<GridCoord>()
            val visited = HashSet<GridCoord>()
            var current = start

            while (true) {
                ordered.add(current)
                visited.add(current)
                val next = neighbours(current).firstOrNull { it !in visited } ?: break
                current = next
            }

            if (ordered.size <= 1) return null

            val closes = ordered.first().isOrthogonallyAdjacent(ordered.last())
            return Route(ordered, closes)
        }
    }
}
