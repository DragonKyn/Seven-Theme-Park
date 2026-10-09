package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.AgeCategory
import com.wickedstudios.wonderlot.GuestAppearance
import com.wickedstudios.wonderlot.GuestPrize
import com.wickedstudios.wonderlot.ParkColour
import com.wickedstudios.wonderlot.ThoughtIcon
import com.wickedstudios.wonderlot.ThoughtMood

/** The three-step mood a guest is drawn with. Kept coarse on purpose, so the texture cache works. */
enum class GuestMood {
    unhappy, neutral, happy;

    companion object {
        fun of(happiness: Double): GuestMood = when {
            happiness < 40 -> unhappy
            happiness < 70 -> neutral
            else -> happy
        }
    }
}

/** Draws guests and the bubbles that appear over their heads. */
object GuestArtwork {

    /** Width of a guest sprite as a share of its height. */
    const val aspect = PersonArtwork.aspect

    /**
     * Guest sprites have their own cache rather than the shared one. A guest is
     * a shirt, a pattern, legwear, hair, skin, a hat, an accessory, an age, a
     * mood and possibly a prize: there are millions of combinations, so the
     * oldest are dropped once the crowd on screen has been served.
     */
    private val cache = HashMap<String, Bitmap>()
    private val order = ArrayList<String>()
    private const val cacheLimit = 1_200

    fun clearCache() {
        cache.clear()
        order.clear()
    }

    fun texture(
        appearance: GuestAppearance,
        age: AgeCategory,
        mood: GuestMood,
        prize: GuestPrize? = null,
        popcorn: Boolean = false,
        balloon: ParkColour? = null,
        height: Double,
    ): Bitmap {
        val size = CGSize(height * aspect * PersonArtwork.supersample, height * PersonArtwork.supersample)
        val key = "guest-${appearance.shirt.name}-${appearance.hair.name}-${appearance.skin.name}-${appearance.hat.name}" +
            "-${appearance.bottoms.name}-${appearance.pattern.name}-${appearance.accessory.name}" +
            "-${age.name}-${mood.name}-${size.height.toInt()}" +
            "-${prize?.let { "${it.kind.name}${it.colour.name}${it.size.name}" } ?: "none"}" +
            (if (popcorn) "-corn" else "") + (balloon?.let { "-balloon${it.name}" } ?: "")

        cache[key]?.let { return it }

        val bitmap = SpriteFactory.render(size) { context, drawSize ->
            PersonArtwork.draw(look(appearance, age, mood, prize, popcorn, balloon), moodColour(mood), context, drawSize)
        }

        cache[key] = bitmap
        order.add(key)
        if (order.size > cacheLimit) {
            val stale = order.take(cacheLimit / 4)
            for (old in stale) cache.remove(old)
            repeat(stale.size) { order.removeAt(0) }
        }
        return bitmap
    }

    private fun look(
        appearance: GuestAppearance,
        age: AgeCategory,
        mood: GuestMood,
        prize: GuestPrize?,
        popcorn: Boolean,
        balloon: ParkColour?,
    ): PersonArtwork.Look {
        // Children are shorter and seniors slightly stooped, drawn as a scale rather than as separate artwork.
        val heightScale = when (age) {
            AgeCategory.child -> 0.78
            AgeCategory.senior -> 0.92
            AgeCategory.adult -> 1.0
        }

        val headwear = when (appearance.hat) {
            GuestAppearance.HatStyle.none -> PersonArtwork.Headwear.none
            GuestAppearance.HatStyle.cap -> PersonArtwork.Headwear.cap
            GuestAppearance.HatStyle.sunHat -> PersonArtwork.Headwear.sunHat
            GuestAppearance.HatStyle.visor -> PersonArtwork.Headwear.visor
            GuestAppearance.HatStyle.bobbleBand -> PersonArtwork.Headwear.bobbleBand
            GuestAppearance.HatStyle.hood -> PersonArtwork.Headwear.hood
        }

        // A cap matches the shirt, a sun hat is straw whatever they wear, a novelty headband is whatever the stall had left.
        val headwearColour = when (appearance.hat) {
            GuestAppearance.HatStyle.sunHat -> ParkPalette.colour(ParkColour.cream)
            GuestAppearance.HatStyle.bobbleBand -> ParkPalette.colour(ParkColour.pink)
            GuestAppearance.HatStyle.hood -> ParkPalette.colour(ParkColour.charcoal)
            else -> ParkPalette.colour(appearance.shirt)
        }

        val expression = when (mood) {
            GuestMood.happy -> PersonArtwork.Expression.happy
            GuestMood.neutral -> PersonArtwork.Expression.neutral
            GuestMood.unhappy -> PersonArtwork.Expression.sad
        }

        return PersonArtwork.Look(
            skin = appearance.skin,
            hair = appearance.hair,
            shirt = ParkPalette.colour(appearance.shirt),
            headwear = headwear,
            headwearColour = headwearColour,
            heightScale = heightScale,
            bottoms = ParkPalette.colour(appearance.bottoms),
            pattern = appearance.pattern,
            accessory = appearance.accessory,
            expression = expression,
            prize = prize,
            popcorn = popcorn,
            balloon = balloon,
        )
    }

    private fun moodColour(mood: GuestMood): UIColor = when (mood) {
        GuestMood.unhappy -> ParkPalette.guestUnhappy
        GuestMood.neutral -> ParkPalette.guestNeutral
        GuestMood.happy -> ParkPalette.guestHappy
    }

    // region Thought bubbles

    /**
     * A rounded bubble with a tail and a symbol inside it. The bubble is tinted
     * by mood so a park full of red bubbles reads as trouble from across the map.
     */
    fun bubbleTexture(icon: ThoughtIcon, mood: ThoughtMood, side: Double): Bitmap {
        val size = CGSize(side * PersonArtwork.supersample, side * PersonArtwork.supersample)
        val key = "bubble-${icon.name}-${mood.name}-${size.width.toInt()}"

        return SpriteFactory.texture(key, size) { context, drawSize ->
            val tint = bubbleColour(mood)

            // Tail first, so the body of the bubble covers where they join.
            val tail = UIBezierPath()
            tail.move(CGPoint(drawSize.width * 0.40, drawSize.height * 0.72))
            tail.addLine(CGPoint(drawSize.width * 0.34, drawSize.height * 0.98))
            tail.addLine(CGPoint(drawSize.width * 0.60, drawSize.height * 0.76))
            tail.close()
            tint.setFill()
            tail.fill()

            val body = CGRect(0.0, 0.0, drawSize.width, drawSize.height * 0.80)
            context.setShadow(CGSize(0.0, drawSize.height * 0.03), drawSize.height * 0.06,
                UIColor.black.withAlphaComponent(0.25))
            UIBezierPath(body, body.height * 0.34).fill()
            context.setShadow(CGSize.zero, 0, null)

            val inner = body.insetBy(body.width * 0.09, body.height * 0.11)
            UIColor.white.withAlphaComponent(0.92).setFill()
            UIBezierPath(inner, inner.height * 0.32).fill()

            val glyphSide = min(inner.width, inner.height) * 0.78
            val glyph = CGRect(inner.midX - glyphSide / 2, inner.midY - glyphSide / 2, glyphSide, glyphSide)
            drawGlyph(icon, glyph, tint)
        }
    }

    /** A simple pictogram for each kind of thought, since the iOS symbol set is not available here. */
    private fun drawGlyph(icon: ThoughtIcon, rect: CGRect, tint: UIColor) {
        tint.setFill()
        tint.setStroke()
        val stroke = max(0.8, rect.width * 0.10)

        when (icon) {
            ThoughtIcon.general -> {
                for (index in 0 until 3) {
                    val d = rect.width * 0.20
                    UIBezierPath(ovalIn = CGRect(rect.minX + rect.width * (0.10 + 0.30 * index), rect.midY - d / 2, d, d)).fill()
                }
            }
            ThoughtIcon.food -> {
                // Fork and knife.
                val fork = UIBezierPath()
                fork.move(CGPoint(rect.minX + rect.width * 0.30, rect.minY + rect.height * 0.08))
                fork.addLine(CGPoint(rect.minX + rect.width * 0.30, rect.maxY - rect.height * 0.08))
                fork.move(CGPoint(rect.minX + rect.width * 0.16, rect.minY + rect.height * 0.08))
                fork.addLine(CGPoint(rect.minX + rect.width * 0.16, rect.minY + rect.height * 0.40))
                fork.move(CGPoint(rect.minX + rect.width * 0.44, rect.minY + rect.height * 0.08))
                fork.addLine(CGPoint(rect.minX + rect.width * 0.44, rect.minY + rect.height * 0.40))
                fork.move(CGPoint(rect.minX + rect.width * 0.72, rect.minY + rect.height * 0.08))
                fork.addLine(CGPoint(rect.minX + rect.width * 0.72, rect.maxY - rect.height * 0.08))
                fork.lineWidth = stroke
                fork.lineCapStyle = LineCap.round
                fork.stroke()
                UIBezierPath(CGRect(rect.minX + rect.width * 0.64, rect.minY + rect.height * 0.08, rect.width * 0.16, rect.height * 0.42), 2).fill()
            }
            ThoughtIcon.drink -> {
                val cup = UIBezierPath()
                cup.move(CGPoint(rect.minX + rect.width * 0.18, rect.minY + rect.height * 0.18))
                cup.addLine(CGPoint(rect.maxX - rect.width * 0.18, rect.minY + rect.height * 0.18))
                cup.addLine(CGPoint(rect.maxX - rect.width * 0.28, rect.maxY - rect.height * 0.08))
                cup.addLine(CGPoint(rect.minX + rect.width * 0.28, rect.maxY - rect.height * 0.08))
                cup.close()
                cup.fill()
            }
            ThoughtIcon.restroom -> {
                UIBezierPath(ovalIn = CGRect(rect.midX - rect.width * 0.14, rect.minY + rect.height * 0.04, rect.width * 0.28, rect.width * 0.28)).fill()
                UIBezierPath(CGRect(rect.midX - rect.width * 0.20, rect.minY + rect.height * 0.36, rect.width * 0.40, rect.height * 0.60), rect.width * 0.10).fill()
            }
            ThoughtIcon.ride -> {
                val star = UIBezierPath()
                for (step in 0 until 10) {
                    val radius = (if (step % 2 == 0) rect.width * 0.48 else rect.width * 0.20)
                    val angle = -PI / 2 + step * PI / 5
                    val point = CGPoint(rect.midX + cos(angle) * radius, rect.midY + sin(angle) * radius)
                    if (step == 0) star.move(point) else star.addLine(point)
                }
                star.close()
                star.fill()
            }
            ThoughtIcon.money -> {
                UIBezierPath(ovalIn = rect.insetBy(rect.width * 0.04, rect.height * 0.04)).fill()
                UIColor.white.setStroke()
                val s = UIBezierPath()
                s.move(CGPoint(rect.midX + rect.width * 0.16, rect.minY + rect.height * 0.32))
                s.addQuadCurve(CGPoint(rect.midX, rect.midY), CGPoint(rect.midX - rect.width * 0.2, rect.minY + rect.height * 0.28))
                s.addQuadCurve(CGPoint(rect.midX - rect.width * 0.16, rect.maxY - rect.height * 0.32), CGPoint(rect.midX + rect.width * 0.2, rect.maxY - rect.height * 0.28))
                s.lineWidth = stroke * 0.9
                s.stroke()
            }
            ThoughtIcon.tired -> {
                val z = UIBezierPath()
                z.move(CGPoint(rect.minX + rect.width * 0.14, rect.minY + rect.height * 0.18))
                z.addLine(CGPoint(rect.maxX - rect.width * 0.14, rect.minY + rect.height * 0.18))
                z.addLine(CGPoint(rect.minX + rect.width * 0.14, rect.maxY - rect.height * 0.18))
                z.addLine(CGPoint(rect.maxX - rect.width * 0.14, rect.maxY - rect.height * 0.18))
                z.lineWidth = stroke
                z.lineCapStyle = LineCap.round
                z.stroke()
            }
            ThoughtIcon.dirty -> {
                UIBezierPath(CGRect(rect.minX + rect.width * 0.22, rect.minY + rect.height * 0.28, rect.width * 0.56, rect.height * 0.66), 2).fill()
                UIBezierPath(CGRect(rect.minX + rect.width * 0.14, rect.minY + rect.height * 0.14, rect.width * 0.72, rect.height * 0.12), 2).fill()
            }
            ThoughtIcon.queue -> {
                UIBezierPath(ovalIn = rect.insetBy(rect.width * 0.06, rect.height * 0.06)).also {
                    it.lineWidth = stroke
                    it.stroke()
                }
                val hands = UIBezierPath()
                hands.move(CGPoint(rect.midX, rect.midY - rect.height * 0.28))
                hands.addLine(CGPoint(rect.midX, rect.midY))
                hands.addLine(CGPoint(rect.midX + rect.width * 0.22, rect.midY + rect.height * 0.12))
                hands.lineWidth = stroke
                hands.lineCapStyle = LineCap.round
                hands.stroke()
            }
        }
    }

    private fun bubbleColour(mood: ThoughtMood): UIColor = when (mood) {
        ThoughtMood.positive -> ParkPalette.guestHappy
        ThoughtMood.neutral -> UIColor(0.33, 0.40, 0.52, 1.0)
        ThoughtMood.negative -> ParkPalette.guestUnhappy
    }

    // endregion
}
