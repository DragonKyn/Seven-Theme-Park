package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
enum class TerrainType {
    grass, path, entrance,

    /** Decorative water. Nothing walks on it or is built over it. */
    water,

    /** Railway: trains run along it between stations. */
    track,

    /** Coaster track: belongs to one station rather than a network. */
    coasterTrack,

    /** Legacy one-tile coaster elements; behave as ordinary coaster track. */
    coasterLoop, coasterHill, coasterHelix, coasterJump,

    /** A deck over water. Walkable like a path. */
    bridge,

    /** Bare rock that came with the map. */
    rock,

    /** Standing forest that came with the map. */
    forest;

    val isWalkableTerrain: Boolean get() = this == path || this == entrance || this == bridge
    val isWalkway: Boolean get() = isWalkableTerrain
    val isCoasterTrack: Boolean get() = this in coasterPieces

    companion object {
        val coasterPieces = setOf(coasterTrack, coasterLoop, coasterHill, coasterHelix, coasterJump)
    }
}

@Serializable
class Tile(
    var terrain: TerrainType = TerrainType.grass,
    /** Which finish this terrain is laid in (paving, brick, boardwalk, tarmac; water colour). */
    var style: Int = 0,
    @Serializable(with = UUIDSerializer::class)
    var buildingID: UUID? = null,
    /** Whether whatever is here stops guests walking through. */
    var blocksMovement: Boolean = true,
    /** Rubbish on the ground, 0-100. */
    var litter: Double = 0.0,
    /** Prettiness from nearby scenery, 0-100. */
    var beauty: Double = 0.0,
) {
    val isWalkable: Boolean get() = (buildingID == null || !blocksMovement) && terrain.isWalkableTerrain
    val isOccupied: Boolean get() = buildingID != null
    val hasLitter: Boolean get() = litter > 0.5
}
