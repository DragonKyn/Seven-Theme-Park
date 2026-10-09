package com.wickedstudios.wonderlot

class PlacementCheck(val isValid: Boolean, val reason: String?) {
    companion object {
        val valid = PlacementCheck(true, null)
        fun invalid(reason: String) = PlacementCheck(false, reason)
    }
}

/**
 * Pure placement rules, kept out of [GameState] so the build preview can call
 * them every time the ghost moves without touching game state.
 */
object PlacementValidator {

    /** [price] is what it costs here once the player's discount is applied; null is list price. */
    fun check(
        definition: BuildableDefinition,
        origin: GridCoord,
        rotation: Int = 0,
        map: ParkMap,
        cash: Double,
        price: Double? = null,
    ): PlacementCheck {
        val rect = GridRect(origin, definition.footprint(rotation))

        for (coord in rect.coords) {
            if (!map.isInside(coord)) return PlacementCheck.invalid("Outside the park")
        }

        if (definition is TerrainDefinition) {
            val tile = map.tile(origin) ?: return PlacementCheck.invalid("Outside the park")
            if (tile.terrain == definition.terrain && tile.style == definition.style) {
                return PlacementCheck.invalid("Already ${definition.displayName.lowercase()}")
            }
            if (tile.terrain == TerrainType.entrance) return PlacementCheck.invalid("That is the entrance")
            if (tile.terrain !in definition.placeableOn) {
                if (definition.terrain == TerrainType.bridge) return PlacementCheck.invalid("Bridges go over water")
                return PlacementCheck.invalid("Clear the ground here first")
            }
            if (tile.buildingID != null) return PlacementCheck.invalid("Something is in the way")
        } else if (definition.laysCoasterTrack) {
            for (coord in rect.coords) {
                val tile = map.tile(coord) ?: return PlacementCheck.invalid("Outside the park")
                if (!(tile.terrain == TerrainType.grass || tile.terrain.isCoasterTrack)) {
                    return PlacementCheck.invalid("Needs clear ground or coaster track")
                }
                if (tile.isOccupied) return PlacementCheck.invalid("Something is already here")
            }
        } else if (definition.bedTerrain != null) {
            val bed = definition.bedTerrain!!
            for (coord in rect.coords) {
                val tile = map.tile(coord) ?: return PlacementCheck.invalid("Outside the park")
                if (tile.isOccupied) return PlacementCheck.invalid("Something is already here")
            }

            val onBed = rect.coords.all { coord ->
                val tile = map.tile(coord) ?: return@all false
                if (bed == TerrainType.coasterTrack) tile.terrain.isCoasterTrack else tile.terrain == bed
            }

            if (onBed) {
                if (definition.requiresPathAccess && map.accessTiles(rect).isEmpty()) {
                    return PlacementCheck.invalid("Needs to touch a walkway")
                }
            } else if (definition.maySitBesideBed) {
                // Off the path is allowed, so long as somebody standing on the
                // path can still reach it.
                if (!map.isAreaBuildable(rect)) return PlacementCheck.invalid("Something is in the way")
                if (map.accessTiles(rect).isEmpty()) {
                    return PlacementCheck.invalid("Put it on a walkway, or on the ground beside one")
                }
            } else {
                return when (bed) {
                    TerrainType.water -> PlacementCheck.invalid("Needs to sit on water")
                    TerrainType.path -> PlacementCheck.invalid("Goes on a walkway")
                    else -> PlacementCheck.invalid("Lay coaster track here first")
                }
            }
        } else if (definition.mayStandOnWalkway && map.isWalkwayArea(rect)) {
            for (coord in rect.coords) {
                if (map.tile(coord)?.isOccupied != false) return PlacementCheck.invalid("Something is already here")
            }
        } else {
            // Bare grass, or pavement to be built over.
            if (!map.isAreaClearGround(rect)) return PlacementCheck.invalid("Something is in the way")
            if (!definition.leavesWalkwayOpen && map.wouldStrandWalkways(rect)) {
                return PlacementCheck.invalid("That would cut the walkway in two")
            }
            if (definition.requiresPathAccess && map.accessTiles(rect).isEmpty()) {
                return PlacementCheck.invalid("Needs to touch a walkway")
            }
            if (definition.requiresTrackAccess && !map.touchesTerrain(TerrainType.track, rect)) {
                return PlacementCheck.invalid("Needs to touch a track")
            }
            if (definition.requiresCoasterTrackAccess && !map.touchesTerrain(TerrainType.coasterTrack, rect)) {
                return PlacementCheck.invalid("Needs to touch coaster track")
            }
        }

        if (cash < (price ?: definition.purchasePrice)) return PlacementCheck.invalid("Not enough cash")

        return PlacementCheck.valid
    }
}
