package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.EntertainerAct
import com.wickedstudios.wonderlot.GuestAppearance
import com.wickedstudios.wonderlot.ParkColour
import com.wickedstudios.wonderlot.StaffLook
import com.wickedstudios.wonderlot.StaffRole

/**
 * Draws park employees: the same body as a guest, dressed for the job. Acts
 * and mascot costumes are ported separately; until then they are drawn as a
 * costumed person in the right colours.
 */
object StaffArtwork {

    private val cache = HashMap<String, Bitmap>()

    fun clearCache() = cache.clear()

    /** Width of a staff sprite as a share of its height. */
    const val aspect = PersonArtwork.aspect

    /** Per-sprite scale factor so a mascot can be bigger than a person. */
    fun figureScale(look: StaffLook): Double = if (look.role == StaffRole.mascot) 1.25 else 1.0

    /** A portrait for the hire and costume screens. */
    fun previewImage(look: StaffLook, uniform: ParkColour, size: CGSize): Bitmap {
        val key = "preview-${look.role.name}-${look.act.name}-${look.costume.name}-${look.primary.name}-" +
            "${look.secondary.name}-${look.trim.name}-${uniform.name}-${size.width.toInt()}x${size.height.toInt()}"
        cache[key]?.let { return it }
        val bitmap = SpriteFactory.render(size) { context, drawSize ->
            PersonArtwork.draw(personLook(look, uniform), ParkPalette.colour(look.role), context, drawSize)
        }
        cache[key] = bitmap
        return bitmap
    }

    fun texture(look: StaffLook, uniform: ParkColour, height: Double): Bitmap {
        val size = CGSize(height * aspect * PersonArtwork.supersample, height * PersonArtwork.supersample)
        val key = "staff-${look.role.name}-${look.act.name}-${look.costume.name}-${look.primary.name}-" +
            "${look.secondary.name}-${look.trim.name}-${uniform.name}-${size.height.toInt()}"
        cache[key]?.let { return it }

        val bitmap = SpriteFactory.render(size) { context, drawSize ->
            PersonArtwork.draw(personLook(look, uniform), ParkPalette.colour(look.role), context, drawSize)
        }
        cache[key] = bitmap
        return bitmap
    }

    private fun personLook(look: StaffLook, uniform: ParkColour): PersonArtwork.Look {
        val shirt = when (look.role) {
            StaffRole.entertainer -> ParkPalette.colour(look.primary)
            StaffRole.mascot -> ParkPalette.colour(look.primary)
            else -> ParkPalette.colour(uniform)
        }
        val hat = when (look.role) {
            StaffRole.mechanic -> PersonArtwork.Headwear.hardHat
            StaffRole.security -> PersonArtwork.Headwear.cap
            StaffRole.entertainer -> when (look.act) {
                EntertainerAct.classic -> PersonArtwork.Headwear.partyHat
                EntertainerAct.clown -> PersonArtwork.Headwear.clownWig
                EntertainerAct.balloonArtist -> PersonArtwork.Headwear.partyHat
                EntertainerAct.mime -> PersonArtwork.Headwear.beret
                EntertainerAct.juggler -> PersonArtwork.Headwear.jesterHat
                EntertainerAct.magician -> PersonArtwork.Headwear.topHat
            }
            StaffRole.mascot -> PersonArtwork.Headwear.none
            StaffRole.janitor -> PersonArtwork.Headwear.none
        }
        val hatColour = when (look.role) {
            StaffRole.mechanic -> ParkPalette.colour(ParkColour.amber)
            StaffRole.security -> ParkPalette.colour(ParkColour.charcoal)
            else -> ParkPalette.colour(look.trim)
        }
        return PersonArtwork.Look(
            skin = GuestAppearance.SkinTone.tan,
            hair = GuestAppearance.HairColour.brown,
            shirt = shirt,
            headwear = hat,
            headwearColour = hatColour,
            heightScale = 1.0,
            bottoms = ParkPalette.colour(ParkColour.charcoal),
            expression = PersonArtwork.Expression.happy,
            facePaint = if (look.act == EntertainerAct.clown || look.act == EntertainerAct.mime) UIColor.white else null,
            clownFace = look.act == EntertainerAct.clown,
        )
    }
}
