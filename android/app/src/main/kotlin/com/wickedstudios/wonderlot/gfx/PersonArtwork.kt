package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.GuestAppearance
import com.wickedstudios.wonderlot.GuestPrize
import com.wickedstudios.wonderlot.ParkColour

/**
 * Draws the little figures that walk around the park. Guests and staff are
 * the same body with different clothes and different things in their hands,
 * so the body lives here and the two callers add what makes them recognisable.
 *
 * A figure is about nineteen points tall on the map. What has to survive that
 * size, in order: the silhouette, the shirt colour, the face, and only then
 * the details somebody who zooms in will find.
 */
object PersonArtwork {

    /** How much bigger a figure is drawn than the sprite it fills, so it survives being zoomed in on. */
    const val supersample = 3.0

    /** Width of a figure as a share of its height. */
    const val aspect = 0.72

    enum class Headwear {
        none, cap, sunHat, visor, bobbleBand, hood, hardHat, partyHat, beret, topHat, jesterHat, clownWig
    }

    enum class Expression { happy, neutral, sad }

    class Look(
        val skin: GuestAppearance.SkinTone,
        val hair: GuestAppearance.HairColour,
        val shirt: UIColor,
        val headwear: Headwear,
        val headwearColour: UIColor,
        /** 1.0 is an adult. Children and seniors are drawn shorter rather than drawn again. */
        val heightScale: Double,
        /** Trousers, shorts or a skirt. */
        val bottoms: UIColor = UIColor(0.32, 0.35, 0.42, 1.0),
        val pattern: GuestAppearance.ShirtPattern = GuestAppearance.ShirtPattern.plain,
        val accessory: GuestAppearance.Accessory = GuestAppearance.Accessory.none,
        val expression: Expression = Expression.neutral,
        /** Something won at a carnival booth, carried under the arm or hugged in front. */
        val prize: GuestPrize? = null,
        /** A bag of popcorn in the hand they are not carrying a prize in. */
        val popcorn: Boolean = false,
        /** A balloon held on a string, in the colour they were given it. */
        val balloon: ParkColour? = null,
        /** White face paint, which replaces the skin. */
        val facePaint: UIColor? = null,
        /** Gloves, which replace the skin on the hands. */
        val handColour: UIColor? = null,
        /** A red nose and a painted smile. */
        val clownFace: Boolean = false,
    )

    /** Where the parts of a drawn figure ended up, so a caller can hang a broom or a wrench off it. */
    class Layout(val head: CGRect, val body: CGRect, val bottom: Double)

    /**
     * Draws one figure and reports where its parts landed. [tint] is kept for
     * callers that colour the ground under the figure; the figure itself now
     * carries only a faint shadow.
     */
    fun draw(look: Look, @Suppress("UNUSED_PARAMETER") tint: UIColor, context: CGContext, size: CGSize): Layout {
        val figureHeight = size.height * look.heightScale
        val bottom = size.height - (size.height - figureHeight) * 0.20
        val centreX = size.width / 2
        val headSize = figureHeight * 0.42

        // A faint shadow, not a coloured disc: the face already shows the mood.
        val padWidth = figureHeight * 0.46
        val pad = CGRect(centreX - padWidth / 2, bottom - figureHeight * 0.075, padWidth, figureHeight * 0.085)
        UIColor.black.withAlphaComponent(0.13).setFill()
        UIBezierPath(ovalIn = pad).fill()

        val bodyWidth = figureHeight * 0.43
        val body = CGRect(centreX - bodyWidth / 2, bottom - figureHeight * 0.58, bodyWidth, figureHeight * 0.50)
        val head = CGRect(centreX - headSize / 2, bottom - figureHeight * 0.58 - headSize * 0.76, headSize, headSize)

        // A dark hairline around body and head is what stops a small figure dissolving into the grass.
        val outline = UIColor.black.withAlphaComponent(0.32)
        val outlineWidth = max(1, figureHeight * 0.04)

        drawPack(look, body, figureHeight, outline)
        drawLegs(look, body, bottom, figureHeight)

        // Torso: shirt, then whatever is printed on it, then the legwear showing below the hem.
        val bodyPath = UIBezierPath(body, bodyWidth * 0.30)
        look.shirt.setFill()
        bodyPath.fill()

        context.saveGState()
        bodyPath.addClip()
        drawShirtPattern(look, body)
        val hem = CGRect(body.minX, body.maxY - body.height * 0.30, body.width, body.height * 0.30)
        look.bottoms.setFill()
        UIBezierPath(hem).fill()
        context.restoreGState()

        outline.setStroke()
        bodyPath.lineWidth = outlineWidth
        bodyPath.stroke()

        drawArms(look, body, figureHeight, outline)
        drawStrap(look, body, figureHeight, outline)

        val headPath = UIBezierPath(ovalIn = head)
        (look.facePaint ?: skinColour(look.skin)).setFill()
        headPath.fill()
        outline.setStroke()
        headPath.lineWidth = outlineWidth
        headPath.stroke()

        // Hair sits as a cap over the top half of the head, which reads at this size where strands would not.
        val hair = UIBezierPath()
        hair.addArc(CGPoint(head.midX, head.midY), head.width / 2, PI, 0.0, true)
        hair.close()
        hairColour(look.hair).setFill()
        hair.fill()

        drawFace(look, head)
        drawClownFace(look, head)
        drawHeadwear(look, head)
        drawPrize(look, body)
        drawPopcornBag(look, body)
        drawHeldBalloon(look, head, body)

        return Layout(head, body, bottom)
    }

    // region The body

    /** Two legs and two shoes below the hem. */
    private fun drawLegs(look: Look, body: CGRect, bottom: Double, figureHeight: Double) {
        val legWidth = figureHeight * 0.075
        val legTop = body.maxY - figureHeight * 0.02
        val footY = bottom - figureHeight * 0.02

        for (dx in listOf(-figureHeight * 0.085, figureHeight * 0.085)) {
            val leg = CGRect(body.midX + dx - legWidth / 2, legTop, legWidth, footY - legTop)
            skinColour(look.skin).setFill()
            UIBezierPath(leg).fill()

            val shoe = CGRect(leg.minX - legWidth * 0.25, footY - figureHeight * 0.035, legWidth * 1.5, figureHeight * 0.05)
            ParkPalette.colour(ParkColour.charcoal).setFill()
            UIBezierPath(ovalIn = shoe).fill()
        }
    }

    /** Arms down the sides of the torso. */
    private fun drawArms(look: Look, body: CGRect, figureHeight: Double, outline: UIColor) {
        val armWidth = figureHeight * 0.065
        val armTop = body.minY + body.height * 0.26

        for (x in listOf(body.minX - armWidth * 0.45, body.maxX - armWidth * 0.55)) {
            val arm = CGRect(x, armTop, armWidth, body.height * 0.62)
            val path = UIBezierPath(arm, armWidth / 2)
            look.shirt.setFill()
            path.fill()
            // The forearm shows below a short sleeve.
            val hand = CGRect(arm.minX, arm.maxY - arm.height * 0.34, armWidth, arm.height * 0.34)
            (look.handColour ?: skinColour(look.skin)).setFill()
            UIBezierPath(hand, armWidth / 2).fill()
            outline.setStroke()
            path.lineWidth = max(0.5, figureHeight * 0.022)
            path.stroke()
        }
    }

    /** Stripes or an open jacket, drawn inside the torso's own outline. */
    private fun drawShirtPattern(look: Look, body: CGRect) {
        when (look.pattern) {
            GuestAppearance.ShirtPattern.plain -> return
            GuestAppearance.ShirtPattern.stripes -> {
                UIColor.white.withAlphaComponent(0.55).setFill()
                for (index in 0 until 2) {
                    val band = CGRect(body.minX, body.minY + body.height * (0.20 + 0.24 * index), body.width, body.height * 0.12)
                    UIBezierPath(band).fill()
                }
            }
            GuestAppearance.ShirtPattern.vest -> {
                UIColor.black.withAlphaComponent(0.22).setFill()
                val panel = CGRect(body.midX - body.width * 0.16, body.minY, body.width * 0.32, body.height)
                UIBezierPath(panel).fill()
            }
        }
    }

    /** The bulk of a backpack, behind the shoulders. */
    private fun drawPack(look: Look, body: CGRect, figureHeight: Double, outline: UIColor) {
        if (look.accessory != GuestAppearance.Accessory.backpack) return
        val pack = CGRect(body.minX - figureHeight * 0.045, body.minY + body.height * 0.10,
            body.width + figureHeight * 0.09, body.height * 0.62)
        val path = UIBezierPath(pack, pack.width * 0.24)
        ParkPalette.colour(ParkColour.brown).setFill()
        path.fill()
        outline.setStroke()
        path.lineWidth = max(0.5, figureHeight * 0.022)
        path.stroke()
    }

    /** What is worn over the shirt: backpack straps, or a camera on its strap. */
    private fun drawStrap(look: Look, body: CGRect, figureHeight: Double, outline: UIColor) {
        when (look.accessory) {
            GuestAppearance.Accessory.none, GuestAppearance.Accessory.sunglasses -> return

            GuestAppearance.Accessory.backpack -> {
                ParkPalette.colour(ParkColour.charcoal).setFill()
                for (dx in listOf(-body.width * 0.24, body.width * 0.24)) {
                    val strap = CGRect(body.midX + dx - body.width * 0.055, body.minY + body.height * 0.06,
                        body.width * 0.11, body.height * 0.52)
                    UIBezierPath(strap, strap.width * 0.4).fill()
                }
            }

            GuestAppearance.Accessory.phone -> {
                // Held up in front of the chest, with a broadcast arc over it.
                val phone = CGRect(body.midX - body.width * 0.20, body.minY - body.height * 0.10,
                    body.width * 0.40, body.height * 0.46)
                val case = UIBezierPath(phone, phone.width * 0.22)
                ParkPalette.colour(ParkColour.charcoal).setFill()
                case.fill()
                outline.setStroke()
                case.lineWidth = max(0.5, figureHeight * 0.022)
                case.stroke()

                ParkPalette.colour(ParkColour.cyan).withAlphaComponent(0.9).setFill()
                UIBezierPath(phone.insetBy(phone.width * 0.14, phone.height * 0.12), phone.width * 0.14).fill()

                val arcs = UIBezierPath()
                for (step in 1..2) {
                    val radius = figureHeight * (0.10 + 0.06 * step)
                    arcs.addArc(CGPoint(phone.midX, phone.minY), radius, PI * 1.15, PI * 1.85, true)
                    arcs.close()
                }
                ParkPalette.colour(ParkColour.pink).withAlphaComponent(0.85).setStroke()
                arcs.lineWidth = max(0.5, figureHeight * 0.022)
                arcs.stroke()
            }

            GuestAppearance.Accessory.camera -> {
                val strap = UIBezierPath()
                strap.move(CGPoint(body.midX - body.width * 0.26, body.minY + body.height * 0.06))
                strap.addLine(CGPoint(body.midX, body.midY))
                strap.addLine(CGPoint(body.midX + body.width * 0.26, body.minY + body.height * 0.06))
                ParkPalette.colour(ParkColour.charcoal).setStroke()
                strap.lineWidth = max(0.5, figureHeight * 0.020)
                strap.stroke()

                val camera = CGRect(body.midX - body.width * 0.20, body.midY - body.height * 0.04,
                    body.width * 0.40, body.height * 0.22)
                ParkPalette.colour(ParkColour.charcoal).setFill()
                UIBezierPath(camera, camera.height * 0.25).fill()
                val lens = min(camera.width, camera.height) * 0.52
                ParkPalette.colour(ParkColour.slate).setFill()
                UIBezierPath(ovalIn = CGRect(camera.midX - lens / 2, camera.midY - lens / 2, lens, lens)).fill()
            }
        }
    }

    // endregion

    // region The face

    /** Two eyes and a mouth that follows the mood. */
    private fun drawFace(look: Look, head: CGRect) {
        val eye = head.width * 0.10
        val eyeY = head.midY + head.height * 0.04

        if (look.accessory == GuestAppearance.Accessory.sunglasses) {
            val lensWidth = head.width * 0.30
            val lensHeight = head.height * 0.20
            ParkPalette.colour(ParkColour.charcoal).setFill()
            for (dx in listOf(-head.width * 0.18, head.width * 0.18)) {
                val lens = CGRect(head.midX + dx - lensWidth / 2, eyeY - lensHeight * 0.45, lensWidth, lensHeight)
                UIBezierPath(lens, lensHeight * 0.4).fill()
            }
            UIBezierPath(CGRect(head.midX - head.width * 0.07, eyeY - lensHeight * 0.10, head.width * 0.14, lensHeight * 0.20)).fill()
        } else {
            ParkPalette.colour(ParkColour.charcoal).setFill()
            for (dx in listOf(-head.width * 0.17, head.width * 0.17)) {
                UIBezierPath(ovalIn = CGRect(head.midX + dx - eye / 2, eyeY - eye / 2, eye, eye * 1.15)).fill()
            }
        }

        val mouth = UIBezierPath()
        val mouthY = head.midY + head.height * 0.24
        val halfWidth = head.width * 0.16

        when (look.expression) {
            Expression.happy -> {
                mouth.move(CGPoint(head.midX - halfWidth, mouthY - head.height * 0.03))
                mouth.addQuadCurve(CGPoint(head.midX + halfWidth, mouthY - head.height * 0.03),
                    CGPoint(head.midX, mouthY + head.height * 0.12))
            }
            Expression.neutral -> {
                mouth.move(CGPoint(head.midX - halfWidth * 0.7, mouthY))
                mouth.addLine(CGPoint(head.midX + halfWidth * 0.7, mouthY))
            }
            Expression.sad -> {
                mouth.move(CGPoint(head.midX - halfWidth, mouthY + head.height * 0.05))
                mouth.addQuadCurve(CGPoint(head.midX + halfWidth, mouthY + head.height * 0.05),
                    CGPoint(head.midX, mouthY - head.height * 0.09))
            }
        }

        ParkPalette.colour(ParkColour.charcoal).setStroke()
        mouth.lineWidth = max(0.5, head.width * 0.075)
        mouth.lineCapStyle = LineCap.round
        mouth.stroke()
    }

    /** A round red nose and a wide painted smile, over whatever the face already had. */
    private fun drawClownFace(look: Look, head: CGRect) {
        if (!look.clownFace) return
        val red = ParkPalette.colour(ParkColour.red)

        val smile = UIBezierPath()
        smile.move(CGPoint(head.midX - head.width * 0.30, head.minY + head.height * 0.68))
        smile.addQuadCurve(CGPoint(head.midX + head.width * 0.30, head.minY + head.height * 0.68),
            CGPoint(head.midX, head.minY + head.height * 1.02))
        smile.lineCapStyle = LineCap.round
        red.setStroke()
        smile.lineWidth = max(0.8, head.width * 0.10)
        smile.stroke()

        val nose = head.width * 0.26
        val spot = CGRect(head.midX - nose / 2, head.minY + head.height * 0.46, nose, nose)
        red.setFill()
        UIBezierPath(ovalIn = spot).fill()
        UIColor.white.withAlphaComponent(0.65).setFill()
        UIBezierPath(ovalIn = CGRect(spot.minX + nose * 0.18, spot.minY + nose * 0.14, nose * 0.26, nose * 0.26)).fill()
    }

    // endregion

    // region Balloons and popcorn

    /** A balloon on a string from the hand, bobbing beside the head. */
    private fun drawHeldBalloon(look: Look, head: CGRect, body: CGRect) {
        val colour = look.balloon ?: return

        // Sized so its right edge stays inside the sprite.
        val radius = head.width * 0.24
        val centre = CGPoint(head.maxX + head.width * 0.04, head.minY + head.height * 0.12)
        val hand = CGPoint(body.maxX, body.midY)

        val string = UIBezierPath()
        string.move(CGPoint(centre.x, centre.y + radius * 1.1))
        string.addQuadCurve(hand, CGPoint(centre.x + radius * 0.5, (centre.y + hand.y) / 2))
        UIColor.white.withAlphaComponent(0.8).setStroke()
        string.lineWidth = max(0.5, body.width * 0.04)
        string.stroke()

        val rect = CGRect(centre.x - radius, centre.y - radius * 1.1, radius * 2, radius * 2.2)
        ParkPalette.colour(colour).setFill()
        UIBezierPath(ovalIn = rect).fill()
        UIColor.black.withAlphaComponent(0.25).setStroke()
        val outline = UIBezierPath(ovalIn = rect)
        outline.lineWidth = max(0.5, body.width * 0.04)
        outline.stroke()
        UIColor.white.withAlphaComponent(0.6).setFill()
        UIBezierPath(ovalIn = CGRect(rect.minX + radius * 0.34, rect.minY + radius * 0.30, radius * 0.32, radius * 0.44)).fill()
    }

    /** A striped paper bag held out to the right, with the popcorn heaped over its top. */
    private fun drawPopcornBag(look: Look, body: CGRect) {
        if (!look.popcorn) return

        val width = body.width * 0.40
        val height = body.width * 0.46
        val left = body.maxX - width * 0.70
        val top = body.midY - height * 0.05

        val bag = UIBezierPath()
        bag.move(CGPoint(left, top))
        bag.addLine(CGPoint(left + width, top))
        bag.addLine(CGPoint(left + width * 0.86, top + height))
        bag.addLine(CGPoint(left + width * 0.14, top + height))
        bag.close()

        // The popcorn first, so the rim of the bag sits in front of it.
        val kernel = width * 0.40
        val cream = ParkPalette.colour(ParkColour.cream)
        val gold = ParkPalette.colour(ParkColour.yellow)
        for (index in 0 until 3) {
            val spot = CGRect(left + width * (0.04 + 0.28 * index), top - kernel * (if (index == 1) 0.78 else 0.48), kernel, kernel)
            (if (index == 1) gold else cream).setFill()
            UIBezierPath(ovalIn = spot).fill()
        }

        UIColor.white.setFill()
        bag.fill()

        val red = ParkPalette.colour(ParkColour.red)
        val stripeWidth = width * 0.22
        val context = Gfx.context
        for (fraction in listOf(0.24, 0.56)) {
            val stripe = UIBezierPath(CGRect(left + width * fraction, top, stripeWidth, height))
            context.saveGState()
            bag.addClip()
            red.setFill()
            stripe.fill()
            context.restoreGState()
        }

        UIColor.black.withAlphaComponent(0.32).setStroke()
        bag.lineWidth = max(0.5, body.width * 0.05)
        bag.stroke()
    }

    // endregion

    // region Prizes

    /**
     * A prize the guest won, carried where its size allows. A small one is
     * tucked under the near arm; a giant one is held in front with both arms.
     */
    private fun drawPrize(look: Look, body: CGRect) {
        val prize = look.prize ?: return

        val unit = body.width * prize.size.scale
        val colour = ParkPalette.colour(prize.colour)
        val outline = UIColor.black.withAlphaComponent(0.32)
        val outlineWidth = max(0.5, body.width * 0.07)

        val centre = if (prize.size.isHugged) CGPoint(body.midX, body.midY + body.width * 0.30)
        else CGPoint(body.minX + body.width * 0.06, body.midY + body.width * 0.10)

        fun blob(rect: CGRect, fill: UIColor, oval: Boolean = true) {
            val path = if (oval) UIBezierPath(ovalIn = rect) else UIBezierPath(rect, rect.height * 0.3)
            fill.setFill()
            path.fill()
            outline.setStroke()
            path.lineWidth = outlineWidth
            path.stroke()
        }

        val torso = unit * 0.46
        val head = unit * 0.34

        when (prize.kind) {
            GuestPrize.Kind.star -> {
                val points = 5
                val outer = unit * 0.30
                val star = UIBezierPath()
                for (step in 0 until points * 2) {
                    val radius = if (step % 2 == 0) outer else outer * 0.44
                    val angle = -PI / 2 + step * PI / points
                    val point = CGPoint(centre.x + cos(angle) * radius, centre.y + sin(angle) * radius)
                    if (step == 0) star.move(point) else star.addLine(point)
                }
                star.close()
                colour.setFill()
                star.fill()
                outline.setStroke()
                star.lineWidth = outlineWidth
                star.stroke()
            }

            GuestPrize.Kind.ball -> {
                val side = unit * 0.56
                val ball = CGRect(centre.x - side / 2, centre.y - side / 2, side, side)
                blob(ball, colour)
                val stripe = UIBezierPath()
                stripe.move(CGPoint(ball.minX + side * 0.12, ball.midY))
                stripe.addQuadCurve(CGPoint(ball.maxX - side * 0.12, ball.midY), CGPoint(ball.midX, ball.minY))
                UIColor.white.withAlphaComponent(0.85).setStroke()
                stripe.lineWidth = max(0.5, unit * 0.10)
                stripe.stroke()
            }

            GuestPrize.Kind.duck -> {
                blob(CGRect(centre.x - torso / 2, centre.y - torso * 0.20, torso, torso * 0.80), colour)
                blob(CGRect(centre.x - head * 0.20, centre.y - head * 0.72, head, head), colour)
                blob(CGRect(centre.x + head * 0.52, centre.y - head * 0.34, head * 0.44, head * 0.28),
                    ParkPalette.colour(ParkColour.orange), oval = false)
            }

            GuestPrize.Kind.bear, GuestPrize.Kind.dog, GuestPrize.Kind.bunny -> {
                blob(CGRect(centre.x - torso / 2, centre.y - torso * 0.10, torso, torso * 0.92), colour)
                blob(CGRect(centre.x - head / 2, centre.y - head * 0.74, head, head), colour)

                // The ears are the whole difference between the three of them.
                val ear = head * 0.44
                when (prize.kind) {
                    GuestPrize.Kind.bunny ->
                        for (dx in listOf(-head * 0.22, head * 0.22)) {
                            blob(CGRect(centre.x + dx - ear * 0.26, centre.y - head * 1.28, ear * 0.52, ear * 1.30), colour)
                        }
                    GuestPrize.Kind.dog ->
                        for (dx in listOf(-head * 0.46, head * 0.46)) {
                            blob(CGRect(centre.x + dx - ear * 0.30, centre.y - head * 0.66, ear * 0.60, ear * 1.00), colour)
                        }
                    else ->
                        for (dx in listOf(-head * 0.38, head * 0.38)) {
                            blob(CGRect(centre.x + dx - ear / 2, centre.y - head * 0.92, ear, ear), colour)
                        }
                }
            }
        }

        // Two arms round a giant one, so it reads as held rather than as a second person.
        if (!prize.size.isHugged) return
        val armWidth = body.width * 0.16
        for (dx in listOf(-torso * 0.52, torso * 0.52)) {
            val arm = CGRect(centre.x + dx - armWidth / 2, centre.y + torso * 0.10, armWidth, torso * 0.46)
            val path = UIBezierPath(arm, armWidth / 2)
            look.shirt.setFill()
            path.fill()
            outline.setStroke()
            path.lineWidth = outlineWidth
            path.stroke()
        }
    }

    // endregion

    // region Hats

    private fun drawHeadwear(look: Look, head: CGRect) {
        when (look.headwear) {
            Headwear.none -> return

            Headwear.hood -> {
                // A ring rather than a shape: an outer shell with the opening punched out by the even-odd rule.
                val shell = CGRect(head.minX - head.width * 0.14, head.minY - head.height * 0.16,
                    head.width * 1.28, head.height * 1.16)
                val opening = CGRect(head.minX + head.width * 0.08, head.minY + head.height * 0.18,
                    head.width * 0.84, head.height * 0.88)

                val hood = UIBezierPath(shell, shell.width * 0.46)
                hood.append(UIBezierPath(ovalIn = opening))
                hood.usesEvenOddFillRule = true
                look.headwearColour.setFill()
                hood.fill()

                // A band of shadow under the front edge, which is what sells it as being worn.
                val brow = CGRect(opening.minX + opening.width * 0.06, opening.minY, opening.width * 0.88, head.height * 0.14)
                UIColor.black.withAlphaComponent(0.28).setFill()
                UIBezierPath(brow, brow.height * 0.5).fill()
            }

            Headwear.cap -> {
                val crown = CGRect(head.minX, head.minY - head.height * 0.10, head.width, head.height * 0.46)
                look.headwearColour.setFill()
                UIBezierPath(crown, crown.height * 0.5).fill()
                val peak = CGRect(head.midX, head.minY + head.height * 0.22, head.width * 0.62, head.height * 0.14)
                UIBezierPath(peak, peak.height / 2).fill()
            }

            Headwear.sunHat -> {
                val brim = CGRect(head.minX - head.width * 0.28, head.minY + head.height * 0.16, head.width * 1.56, head.height * 0.20)
                look.headwearColour.setFill()
                UIBezierPath(ovalIn = brim).fill()
                val crown = CGRect(head.minX + head.width * 0.16, head.minY - head.height * 0.08, head.width * 0.68, head.height * 0.38)
                UIBezierPath(ovalIn = crown).fill()
            }

            Headwear.visor -> {
                // Brim and a band, with the top of the head left bare.
                val brim = CGRect(head.minX - head.width * 0.16, head.minY + head.height * 0.20, head.width * 1.32, head.height * 0.16)
                look.headwearColour.setFill()
                UIBezierPath(ovalIn = brim).fill()
                val band = CGRect(head.minX + head.width * 0.04, head.minY + head.height * 0.12, head.width * 0.92, head.height * 0.14)
                UIBezierPath(band, band.height * 0.5).fill()
            }

            Headwear.bobbleBand -> {
                val band = UIBezierPath()
                band.move(CGPoint(head.minX + head.width * 0.10, head.minY + head.height * 0.24))
                band.addQuadCurve(CGPoint(head.maxX - head.width * 0.10, head.minY + head.height * 0.24),
                    CGPoint(head.midX, head.minY - head.height * 0.06))
                look.headwearColour.setStroke()
                band.lineWidth = max(0.5, head.width * 0.09)
                band.stroke()

                val bobble = head.width * 0.26
                look.headwearColour.setFill()
                for (dx in listOf(-head.width * 0.30, head.width * 0.30)) {
                    UIBezierPath(ovalIn = CGRect(head.midX + dx - bobble / 2, head.minY - head.height * 0.26, bobble, bobble)).fill()
                }
            }

            Headwear.hardHat -> {
                val shell = CGRect(head.minX - head.width * 0.10, head.minY - head.height * 0.16, head.width * 1.20, head.height * 0.60)
                look.headwearColour.setFill()
                UIBezierPath(ovalIn = shell).fill()
                // Flat underside, so the shell reads as a helmet rather than a ball.
                val brim = CGRect(shell.minX, shell.midY + shell.height * 0.14, shell.width, shell.height * 0.22)
                UIBezierPath(brim, brim.height * 0.5).fill()
                // Ridge down the middle.
                val ridge = CGRect(shell.midX - shell.width * 0.05, shell.minY + shell.height * 0.06, shell.width * 0.10, shell.height * 0.42)
                UIColor.black.withAlphaComponent(0.18).setFill()
                UIBezierPath(ridge).fill()
            }

            Headwear.partyHat -> {
                val cone = UIBezierPath()
                cone.move(CGPoint(head.midX, head.minY - head.height * 0.56))
                cone.addLine(CGPoint(head.minX + head.width * 0.06, head.minY + head.height * 0.22))
                cone.addLine(CGPoint(head.maxX - head.width * 0.06, head.minY + head.height * 0.22))
                cone.close()
                look.headwearColour.setFill()
                cone.fill()

                val pompom = head.width * 0.26
                ParkPalette.colour(ParkColour.cream).setFill()
                UIBezierPath(ovalIn = CGRect(head.midX - pompom / 2, head.minY - head.height * 0.66, pompom, pompom)).fill()
            }

            Headwear.beret -> {
                val crown = CGRect(head.minX - head.width * 0.10, head.minY - head.height * 0.12, head.width * 1.16, head.height * 0.46)
                look.headwearColour.setFill()
                UIBezierPath(ovalIn = crown).fill()
                val stalk = head.width * 0.12
                UIBezierPath(ovalIn = CGRect(crown.midX + head.width * 0.10, crown.minY - stalk * 0.5, stalk, stalk)).fill()
            }

            Headwear.topHat -> {
                val brim = CGRect(head.minX - head.width * 0.22, head.minY + head.height * 0.10, head.width * 1.44, head.height * 0.18)
                look.headwearColour.setFill()
                UIBezierPath(ovalIn = brim).fill()
                val crown = CGRect(head.minX + head.width * 0.10, head.minY - head.height * 0.52, head.width * 0.80, head.height * 0.66)
                UIBezierPath(crown, head.width * 0.08).fill()
                val band = CGRect(crown.minX, crown.maxY - head.height * 0.18, crown.width, head.height * 0.14)
                ParkPalette.colour(ParkColour.red).setFill()
                UIBezierPath(band).fill()
            }

            Headwear.clownWig -> {
                look.headwearColour.setFill()
                val tuft = head.width * 0.34
                val spots = listOf(0.58 to 0.20, 0.66 to 0.46, 0.52 to -0.02)
                for (side in listOf(-1.0, 1.0)) {
                    for (spot in spots) {
                        UIBezierPath(ovalIn = CGRect(head.midX + side * head.width * spot.first - tuft / 2,
                            head.minY + head.height * spot.second - tuft / 2, tuft, tuft)).fill()
                    }
                }
            }

            Headwear.jesterHat -> {
                for (side in listOf(-1.0, 1.0)) {
                    val point = UIBezierPath()
                    point.move(CGPoint(head.midX + side * head.width * 0.04, head.minY + head.height * 0.20))
                    point.addQuadCurve(CGPoint(head.midX + side * head.width * 0.66, head.minY - head.height * 0.42),
                        CGPoint(head.midX + side * head.width * 0.62, head.minY + head.height * 0.0))
                    point.addLine(CGPoint(head.midX + side * head.width * 0.48, head.minY + head.height * 0.22))
                    point.close()
                    (if (side < 0) look.headwearColour else ParkPalette.colour(ParkColour.cream)).setFill()
                    point.fill()

                    val bell = head.width * 0.20
                    ParkPalette.colour(ParkColour.yellow).setFill()
                    UIBezierPath(ovalIn = CGRect(head.midX + side * head.width * 0.66 - bell / 2,
                        head.minY - head.height * 0.42 - bell / 2, bell, bell)).fill()
                }
            }
        }
    }

    // endregion

    // region Palette

    fun skinColour(tone: GuestAppearance.SkinTone): UIColor = when (tone) {
        GuestAppearance.SkinTone.deep -> UIColor(0.42, 0.28, 0.20, 1.0)
        GuestAppearance.SkinTone.tan -> UIColor(0.68, 0.48, 0.34, 1.0)
        GuestAppearance.SkinTone.olive -> UIColor(0.83, 0.66, 0.48, 1.0)
        GuestAppearance.SkinTone.fair -> UIColor(0.95, 0.81, 0.68, 1.0)
    }

    fun hairColour(colour: GuestAppearance.HairColour): UIColor = when (colour) {
        GuestAppearance.HairColour.dark -> UIColor(0.16, 0.13, 0.12, 1.0)
        GuestAppearance.HairColour.brown -> UIColor(0.40, 0.27, 0.17, 1.0)
        GuestAppearance.HairColour.sandy -> UIColor(0.79, 0.66, 0.39, 1.0)
        GuestAppearance.HairColour.ginger -> UIColor(0.76, 0.40, 0.19, 1.0)
        GuestAppearance.HairColour.grey -> UIColor(0.78, 0.78, 0.79, 1.0)
    }

    // endregion
}
