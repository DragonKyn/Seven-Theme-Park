package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.FacilityKind
import com.wickedstudios.wonderlot.ParkColour
import com.wickedstudios.wonderlot.StaffRole
import com.wickedstudios.wonderlot.TerrainType

/** Colours for the map. Bright, flat and high-contrast so the park stays readable on a phone at a glance. */
object ParkPalette {
    val grass = UIColor(0.55, 0.78, 0.45, 1.0)
    val rock = UIColor(0.56, 0.53, 0.50, 1.0)
    val rockShade = UIColor(0.42, 0.40, 0.38, 1.0)
    val rockLight = UIColor(0.70, 0.67, 0.63, 1.0)
    val forest = UIColor(0.20, 0.42, 0.24, 1.0)
    val forestDeep = UIColor(0.14, 0.32, 0.18, 1.0)
    val forestCanopy = UIColor(0.27, 0.53, 0.29, 1.0)
    val grassAlt = UIColor(0.51, 0.74, 0.42, 1.0)
    val path = UIColor(0.87, 0.84, 0.76, 1.0)
    val entrance = UIColor(0.96, 0.74, 0.30, 1.0)
    val grassTuft = UIColor(0.44, 0.68, 0.36, 0.75)
    val pathJoint = UIColor(0.72, 0.68, 0.60, 0.55)
    val waterRipple = UIColor(1.00, 1.00, 1.00, 0.20)
    val waterShore = UIColor(0.62, 0.80, 0.92, 0.55)

    val water = UIColor(0.35, 0.63, 0.86, 1.0)
    val waterAlt = UIColor(0.31, 0.58, 0.83, 1.0)

    val ride = UIColor(0.36, 0.55, 0.92, 1.0)
    val food = UIColor(0.94, 0.51, 0.35, 1.0)
    val drink = UIColor(0.36, 0.75, 0.82, 1.0)
    val bathroom = UIColor(0.63, 0.53, 0.86, 1.0)
    val bench = UIColor(0.68, 0.52, 0.36, 1.0)
    val shop = UIColor(0.92, 0.62, 0.78, 1.0)
    val game = UIColor(0.95, 0.45, 0.20, 1.0)

    val ghostValid = UIColor(0.30, 0.85, 0.45, 0.55)

    /** Round a placement that is lined up and legal. Brighter than the plain ghost fill. */
    val previewValid = UIColor(0.36, 1.00, 0.58, 1.0)
    val ghostInvalid = UIColor(0.92, 0.30, 0.30, 0.55)

    val guestHappy = UIColor(0.20, 0.72, 0.35, 1.0)
    val guestNeutral = UIColor(0.97, 0.78, 0.24, 1.0)
    val guestUnhappy = UIColor(0.90, 0.32, 0.28, 1.0)

    val ballast = UIColor(0.44, 0.41, 0.37, 1.0)
    val coasterBed = UIColor(0.30, 0.33, 0.40, 1.0)
    val coasterSupport = UIColor(0.55, 0.58, 0.64, 0.95)
    val coasterRail = UIColor(0.98, 0.72, 0.28, 1.0)

    /** The rail colour the player has chosen for their coasters, or the stock orange. */
    fun coasterRail(colour: ParkColour?): UIColor = if (colour == null) coasterRail else colour(colour)
    val coasterTie = UIColor(0.20, 0.22, 0.28, 1.0)

    val rail = UIColor(0.72, 0.73, 0.75, 1.0)
    val sleeper = UIColor(0.32, 0.24, 0.18, 1.0)

    val asphalt = UIColor(0.34, 0.35, 0.38, 1.0)
    val bayLine = UIColor(0.86, 0.86, 0.83, 0.85)

    /** The car park darkens as it is paved: loose gravel to fresh tarmac. */
    fun carParkSurface(level: Int): UIColor {
        val paved = minOf(maxOf(level.toDouble(), 0.0), 5.0) / 5
        return UIColor(0.52 - 0.20 * paved, 0.50 - 0.17 * paved, 0.46 - 0.11 * paved, 1.0)
    }

    /** Darker than plain brown, so a flume trough reads against grass and against the logs riding in it. */
    val flumeTimber = UIColor(0.38, 0.26, 0.19, 1.0)

    val signPost = UIColor(0.47, 0.33, 0.22, 1.0)
    val signFace = UIColor(0.98, 0.94, 0.84, 1.0)
    val signFrame = UIColor(0.90, 0.55, 0.20, 1.0)
    val signText = UIColor(0.32, 0.21, 0.12, 1.0)

    val selection = UIColor(1.0, 1.0, 1.0, 0.9)
    val bin = UIColor(0.45, 0.50, 0.55, 1.0)
    val litter = UIColor(0.58, 0.47, 0.30, 1.0)
    val broken = UIColor(0.88, 0.24, 0.22, 1.0)

    /** Behind a building's name. Dark and translucent so a name stays legible over pale artwork. */
    val labelChip = UIColor(0.10, 0.13, 0.19, 0.78)
    val badge = UIColor(0.15, 0.17, 0.22, 0.9)

    val janitor = UIColor(0.30, 0.72, 0.62, 1.0)
    val mechanic = UIColor(0.98, 0.62, 0.15, 1.0)
    val entertainer = UIColor(0.85, 0.36, 0.72, 1.0)
    val security = UIColor(0.24, 0.38, 0.72, 1.0)
    val mascot = UIColor(0.96, 0.74, 0.20, 1.0)

    fun colour(role: StaffRole): UIColor = when (role) {
        StaffRole.janitor -> janitor
        StaffRole.mechanic -> mechanic
        StaffRole.entertainer -> entertainer
        StaffRole.security -> security
        StaffRole.mascot -> mascot
    }

    fun colour(kind: FacilityKind): UIColor = when (kind) {
        FacilityKind.food -> food
        FacilityKind.drink -> drink
        FacilityKind.bathroom -> bathroom
        FacilityKind.bench -> bench
        FacilityKind.souvenir -> shop
        FacilityKind.game -> game
        FacilityKind.bin -> bin
    }

    /** The flat colour of one terrain tile. Checkerboarded terrains take a second shade. */
    fun colour(terrain: TerrainType, alternate: Boolean): UIColor = when (terrain) {
        TerrainType.path -> path
        TerrainType.entrance -> entrance
        TerrainType.bridge -> colour(ParkColour.brown)
        TerrainType.water -> if (alternate) waterAlt else water
        TerrainType.track -> ballast
        TerrainType.coasterTrack, TerrainType.coasterLoop, TerrainType.coasterHill,
        TerrainType.coasterHelix, TerrainType.coasterJump -> coasterBed
        TerrainType.grass -> if (alternate) grassAlt else grass
        TerrainType.rock -> rock
        TerrainType.forest -> forest
    }

    fun guestColour(happiness: Double): UIColor = when {
        happiness < 40 -> guestUnhappy
        happiness < 70 -> guestNeutral
        else -> guestHappy
    }

    /**
     * Resolves the colour names used by the content catalogue. This is the only
     * place a ParkColour becomes pixels, so the whole park can be retinted from here.
     */
    fun colour(colour: ParkColour): UIColor = when (colour) {
        ParkColour.red -> UIColor(0.89, 0.29, 0.28, 1.0)
        ParkColour.orange -> UIColor(0.95, 0.53, 0.26, 1.0)
        ParkColour.amber -> UIColor(0.96, 0.70, 0.24, 1.0)
        ParkColour.yellow -> UIColor(0.98, 0.84, 0.33, 1.0)
        ParkColour.lime -> UIColor(0.66, 0.83, 0.36, 1.0)
        ParkColour.green -> UIColor(0.32, 0.71, 0.42, 1.0)
        ParkColour.teal -> UIColor(0.25, 0.70, 0.64, 1.0)
        ParkColour.cyan -> UIColor(0.38, 0.78, 0.85, 1.0)
        ParkColour.blue -> UIColor(0.33, 0.55, 0.90, 1.0)
        ParkColour.indigo -> UIColor(0.36, 0.40, 0.78, 1.0)
        ParkColour.violet -> UIColor(0.60, 0.45, 0.85, 1.0)
        ParkColour.pink -> UIColor(0.93, 0.55, 0.74, 1.0)
        ParkColour.cream -> UIColor(0.98, 0.95, 0.87, 1.0)
        ParkColour.sand -> UIColor(0.88, 0.80, 0.64, 1.0)
        ParkColour.brown -> UIColor(0.60, 0.44, 0.31, 1.0)
        ParkColour.slate -> UIColor(0.47, 0.53, 0.60, 1.0)
        ParkColour.charcoal -> UIColor(0.24, 0.26, 0.31, 1.0)
        ParkColour.white -> UIColor(0.97, 0.97, 0.97, 1.0)
    }
}
