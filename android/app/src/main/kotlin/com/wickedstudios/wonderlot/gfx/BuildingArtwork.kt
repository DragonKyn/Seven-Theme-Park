package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif

/**
 * Draws the per-motif building artwork. Every shape is generated with paths
 * and cached as a bitmap, so the project stays free of image assets.
 *
 * Motifs are ported across one family at a time; any that has not been is
 * drawn as a plain coloured block in its own colours, so the park is always
 * playable.
 */
object BuildingArtwork {

    private val previewCache = HashMap<String, Bitmap>()

    /** The building itself, without whatever moves on top of it. */
    fun bodyTexture(appearance: BuildingAppearance, size: CGSize): Bitmap =
        SpriteFactory.texture(key(appearance, "body", size), size) { context, drawSize ->
            drawBody(appearance, context, drawSize)
        }

    /** The same artwork as a plain image, for the build menu. */
    fun previewImage(appearance: BuildingAppearance, size: CGSize): Bitmap {
        val cacheKey = key(appearance, "preview", size)
        previewCache[cacheKey]?.let { return it }
        val image = SpriteFactory.render(size) { context, drawSize -> drawBody(appearance, context, drawSize) }
        previewCache[cacheKey] = image
        return image
    }

    private fun key(appearance: BuildingAppearance, prefix: String, size: CGSize): String =
        "$prefix-${appearance.motif.name}-${appearance.primary.name}-${appearance.secondary.name}" +
            "-${appearance.accent.name}-v${appearance.variant}-${size.width.toInt()}x${size.height.toInt()}"

    /** Shared by the map texture and the menu preview, so the two can never show different artwork. */
    private fun drawBody(appearance: BuildingAppearance, context: CGContext, size: CGSize) {
        val primary = ParkPalette.colour(appearance.primary)
        val secondary = ParkPalette.colour(appearance.secondary)
        val accent = ParkPalette.colour(appearance.accent)
        drawFallback(appearance.motif, context, size, primary, secondary, accent)
    }

    /** A rounded block with a striped roof band and a door, in the building's own colours. */
    private fun drawFallback(motif: BuildingMotif, context: CGContext, size: CGSize,
                             primary: UIColor, secondary: UIColor, accent: UIColor) {
        val inset = min(size.width, size.height) * 0.07
        val rect = CGRect(CGPoint.zero, size).insetBy(inset, inset)
        val radius = min(rect.width, rect.height) * 0.18

        context.setShadow(CGSize(0.0, 2.0), 4, UIColor.black.withAlphaComponent(0.28))
        primary.setFill()
        UIBezierPath(rect, radius).fill()
        context.setShadow(CGSize.zero, 0, null)

        // Roof band.
        val band = CGRect(rect.minX, rect.minY, rect.width, rect.height * 0.30)
        context.saveGState()
        UIBezierPath(rect, radius).addClip()
        secondary.setFill()
        UIBezierPath(band).fill()
        accent.setFill()
        val stripes = max(3, (rect.width / (size.width / 6)).toInt() * 2)
        val stripeWidth = rect.width / stripes
        for (index in 0 until stripes step 2) {
            UIBezierPath(CGRect(rect.minX + stripeWidth * index, band.minY, stripeWidth, band.height)).fill()
        }
        context.restoreGState()

        // A door, so it has a front.
        val door = CGRect(rect.midX - rect.width * 0.09, rect.maxY - rect.height * 0.30, rect.width * 0.18, rect.height * 0.30)
        UIColor.black.withAlphaComponent(0.30).setFill()
        UIBezierPath(door, door.width * 0.3).fill()

        UIColor.white.withAlphaComponent(0.20).setFill()
        UIBezierPath(CGRect(rect.minX + rect.width * 0.1, rect.midY - rect.height * 0.04, rect.width * 0.8, rect.height * 0.12),
            rect.height * 0.05).fill()
    }

    /**
     * The moving part of a building, drawn in its own bitmap so it can be
     * animated independently. Null for anything that does not move.
     */
    fun motionTexture(appearance: BuildingAppearance, size: CGSize, variant: Int = 0): Bitmap? = null

    /** How many moving parts a motif has. */
    fun motionPartCount(motif: BuildingMotif): Int = when (motif) {
        BuildingMotif.goKarts -> 4
        BuildingMotif.bumperCars -> 5
        BuildingMotif.megaCoaster -> 4
        BuildingMotif.coaster -> 3
        BuildingMotif.logFlume -> 2
        BuildingMotif.bumperBoats -> 4
        BuildingMotif.fishingBoats -> 3
        BuildingMotif.wavePool -> 2
        BuildingMotif.skyGliders -> 5
        BuildingMotif.swingChairs -> 6
        BuildingMotif.riverRapids -> 3
        BuildingMotif.lanternCruise -> 3
        BuildingMotif.zipLine -> 2
        BuildingMotif.carpetSlide -> 4
        BuildingMotif.moleGame -> 3
        else -> 1
    }
}
