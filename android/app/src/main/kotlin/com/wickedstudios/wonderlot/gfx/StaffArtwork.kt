package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.EntertainerAct
import com.wickedstudios.wonderlot.GuestAppearance
import com.wickedstudios.wonderlot.MascotCostume
import com.wickedstudios.wonderlot.ParkColour
import com.wickedstudios.wonderlot.StaffLook
import com.wickedstudios.wonderlot.StaffRole
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Draws employees. Everyone wears the park's uniform colour, so the crowd reads as "these people work here" at a
 * glance. What separates the roles is what is on their head and what is in their hands, which stays readable when
 * the uniform is changed to something the roles were never designed around.
 */
object StaffArtwork {

    /** Wider than a guest, because an employee is carrying something and the tool has to fit alongside them. */
    const val aspect = 1.05

    /** A costume is a head taller than a person, and drawn that way. */
    const val mascotScale = 1.45

    /**
     * An entertainer with something held up over their head is drawn on a bigger canvas, with the figure the same
     * size inside it, so there is room above them for balloons and balls.
     */
    const val propScale = 1.45

    private val cache = HashMap<String, Bitmap>()

    fun clearCache() = cache.clear()

    fun sizeScale(look: StaffLook): Double = when (look.role) {
        StaffRole.mascot -> mascotScale
        StaffRole.entertainer -> if (look.act == EntertainerAct.mime) 1.0 else propScale
        StaffRole.janitor, StaffRole.mechanic, StaffRole.security -> 1.0
    }

    /** How big the person is inside that canvas: the reverse of how much bigger the canvas is. */
    fun figureScale(look: StaffLook): Double = 1 / sizeScale(look)

    /** What a drawing is filed under. Only the parts of the look that show are in it. */
    fun cacheKey(look: StaffLook, uniform: ParkColour): String = when {
        look.role == StaffRole.mascot ->
            "mascot-${look.costume.name}-${look.primary.name}-${look.secondary.name}-${look.trim.name}"
        look.role == StaffRole.entertainer && look.act != EntertainerAct.classic -> "act-${look.act.name}-${look.primary.name}"
        else -> "staff-${look.role.name}-${uniform.name}"
    }

    fun texture(look: StaffLook, uniform: ParkColour, height: Double): Bitmap {
        val scale = sizeScale(look)
        val size = CGSize(height * scale * aspect * PersonArtwork.supersample, height * scale * PersonArtwork.supersample)
        val key = cacheKey(look, uniform) + "-${size.height.toInt()}"
        cache[key]?.let { return it }
        val bitmap = SpriteFactory.render(size) { context, drawSize -> draw(look, uniform, context, drawSize) }
        cache[key] = bitmap
        return bitmap
    }

    /** The same drawing as an image, for the hiring screen and the staff panel. */
    fun previewImage(look: StaffLook, uniform: ParkColour, size: CGSize): Bitmap {
        val key = "preview-" + cacheKey(look, uniform) + "-${size.width.toInt()}x${size.height.toInt()}"
        cache[key]?.let { return it }
        val bitmap = SpriteFactory.render(size) { context, drawSize -> draw(look, uniform, context, drawSize) }
        cache[key] = bitmap
        return bitmap
    }

    private fun draw(look: StaffLook, uniform: ParkColour, context: CGContext, size: CGSize) {
        if (look.role == StaffRole.mascot) {
            drawMascot(look, size)
            return
        }

        val shirt = shirtColour(look, uniform)
        if (look.role == StaffRole.entertainer && look.act == EntertainerAct.magician) {
            drawCapeBehind(ParkPalette.colour(look.primary), size, figureScale(look))
        }

        val layout = PersonArtwork.draw(personLook(look, shirt), ParkPalette.colour(look.role), context, size)

        when (look.role) {
            StaffRole.janitor -> {
                drawOveralls(layout)
                drawBroom(layout, size)
            }
            StaffRole.mechanic -> drawWrench(layout, size, context)
            StaffRole.entertainer -> when (look.act) {
                EntertainerAct.classic -> drawMegaphone(layout)
                EntertainerAct.clown -> {
                    drawClownCollar(layout)
                    drawHorn(layout)
                }
                EntertainerAct.balloonArtist -> drawBalloonBunch(layout)
                // The balls are not painted: they are sprites of their own, so they can be thrown.
                EntertainerAct.mime, EntertainerAct.juggler -> {}
                EntertainerAct.magician -> drawWand(layout)
            }
            StaffRole.security -> drawSecurityMarkings(layout)
            StaffRole.mascot -> {}
        }
    }

    /** The uniform for everybody but the entertainers who have an act of their own. */
    private fun shirtColour(look: StaffLook, uniform: ParkColour): UIColor {
        if (look.role != StaffRole.entertainer) return ParkPalette.colour(uniform)
        return when (look.act) {
            EntertainerAct.classic -> ParkPalette.colour(uniform)
            EntertainerAct.magician -> ParkPalette.colour(ParkColour.cream)
            EntertainerAct.clown, EntertainerAct.balloonArtist, EntertainerAct.mime, EntertainerAct.juggler ->
                ParkPalette.colour(look.primary)
        }
    }

    private fun personLook(look: StaffLook, shirt: UIColor): PersonArtwork.Look {
        val headwear: PersonArtwork.Headwear
        val headwearColour: UIColor
        var pattern = GuestAppearance.ShirtPattern.plain
        var facePaint: UIColor? = null
        var handColour: UIColor? = null
        var clownFace = false
        var bottoms = ParkPalette.colour(ParkColour.charcoal)

        when (look.role) {
            StaffRole.janitor -> {
                headwear = PersonArtwork.Headwear.cap
                headwearColour = shirt
            }
            // Amber whatever the uniform is: a hard hat that blends in is not doing its job.
            StaffRole.mechanic -> {
                headwear = PersonArtwork.Headwear.hardHat
                headwearColour = ParkPalette.colour(ParkColour.amber)
            }
            StaffRole.entertainer -> when (look.act) {
                EntertainerAct.classic -> {
                    headwear = PersonArtwork.Headwear.partyHat
                    headwearColour = ParkPalette.colour(ParkColour.red)
                }
                EntertainerAct.clown -> {
                    headwear = PersonArtwork.Headwear.clownWig
                    headwearColour = ParkPalette.colour(ParkColour.orange)
                    pattern = GuestAppearance.ShirtPattern.vest
                    facePaint = ParkPalette.colour(ParkColour.white)
                    handColour = ParkPalette.colour(ParkColour.white)
                    clownFace = true
                    bottoms = ParkPalette.colour(ParkColour.yellow)
                }
                EntertainerAct.balloonArtist -> {
                    headwear = PersonArtwork.Headwear.cap
                    headwearColour = ParkPalette.colour(ParkColour.white)
                }
                EntertainerAct.mime -> {
                    headwear = PersonArtwork.Headwear.beret
                    headwearColour = ParkPalette.colour(ParkColour.charcoal)
                    pattern = GuestAppearance.ShirtPattern.stripes
                    facePaint = ParkPalette.colour(ParkColour.white)
                    handColour = ParkPalette.colour(ParkColour.white)
                }
                EntertainerAct.juggler -> {
                    headwear = PersonArtwork.Headwear.jesterHat
                    headwearColour = ParkPalette.colour(look.primary)
                }
                EntertainerAct.magician -> {
                    headwear = PersonArtwork.Headwear.topHat
                    headwearColour = ParkPalette.colour(ParkColour.charcoal)
                }
            }
            // A dark peaked cap whatever the park's colours are. A guard in a pink cap is not a guard.
            StaffRole.security -> {
                headwear = PersonArtwork.Headwear.cap
                headwearColour = ParkPalette.colour(ParkColour.charcoal)
            }
            StaffRole.mascot -> {
                headwear = PersonArtwork.Headwear.none
                headwearColour = shirt
            }
        }

        return PersonArtwork.Look(
            skin = GuestAppearance.SkinTone.tan,
            hair = GuestAppearance.HairColour.dark,
            shirt = shirt,
            headwear = headwear,
            headwearColour = headwearColour,
            heightScale = figureScale(look),
            bottoms = bottoms,
            pattern = pattern,
            accessory = if (look.role == StaffRole.security) GuestAppearance.Accessory.sunglasses else GuestAppearance.Accessory.none,
            expression = if (look.role == StaffRole.entertainer) PersonArtwork.Expression.happy else PersonArtwork.Expression.neutral,
            facePaint = facePaint,
            handColour = handColour,
            clownFace = clownFace,
        )
    }

    // region Tools

    // What makes a guard read as a guard at this size: a dark peaked cap,
    // sunglasses and a badge. The cap and the glasses come from the figure
    // itself; the badge is the part only a guard has.
    //
    // The word SECURITY was here first and it did not work — squeezed across
    // a shirt a few pixels wide it was a smudge. A shield says the same thing
    // in one shape.
    internal fun drawSecurityMarkings(layout: PersonArtwork.Layout) {
        drawBadge(layout.body)
    }

    // A shield on the left breast, with a star punched into it.
    internal fun drawBadge(body: CGRect) {
        val width = body.width * 0.34
        val height = width * 1.15
        val centre = CGPoint(body.minX + body.width * 0.30,
                             body.minY + body.height * 0.34)

        val shield = UIBezierPath()
        shield.move(CGPoint(centre.x - width / 2, centre.y - height / 2))
        shield.addLine(CGPoint(centre.x + width / 2, centre.y - height / 2))
        shield.addLine(CGPoint(centre.x + width / 2, centre.y + height * 0.12))
        shield.addQuadCurve(CGPoint(centre.x, centre.y + height / 2),
                            CGPoint(centre.x + width * 0.42,
                                                  centre.y + height * 0.44))
        shield.addQuadCurve(CGPoint(centre.x - width / 2, centre.y + height * 0.12),
                            CGPoint(centre.x - width * 0.42,
                                                  centre.y + height * 0.44))
        shield.close()

        fillPath(shield, ParkPalette.colour(ParkColour.amber))
        ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.75).setStroke()
        shield.lineWidth = max(0.5, width * 0.16)
        shield.stroke()

        val pip = width * 0.30
        fillPath(UIBezierPath(ovalIn =  CGRect(centre.x - pip / 2, centre.y - pip / 2,
                                             pip, pip)),
                 ParkPalette.colour(ParkColour.charcoal))
    }

    internal fun fillPath(path: UIBezierPath, colour: UIColor) {
        colour.setFill()
        path.fill()
    }

    // Bib and brace over the uniform shirt.
    //
    // A fixed workwear blue whatever the park's colours are, for the same
    // reason the mechanic's hard hat is always amber: the point of the
    // garment is that it is recognisable, and a bib in the park's pastel of
    // the week is not. The shirt still shows at the shoulders and sleeves,
    // so the employee is plainly one of yours.
    internal fun drawOveralls(layout: PersonArtwork.Layout) {
        val body = layout.body
        val denim = ParkPalette.colour(ParkColour.indigo)
        val stitch = ParkPalette.colour(ParkColour.cream).withAlphaComponent(0.55)

        // The bib: a panel up the middle of the chest, narrower than the body
        // so the shirt reads as a shirt either side of it.
        val bib = CGRect(body.minX + body.width * 0.20,
                         body.minY + body.height * 0.26,
                         body.width * 0.60,
                         body.height * 0.78)
        denim.setFill()
        UIBezierPath(bib, body.width * 0.10).fill()

        // Braces over each shoulder, angled in towards the bib.
        val braceWidth = max(0.6, body.width * 0.13)
        denim.setStroke()
        for (side in listOf(-1.0, 1.0)) {
            val brace = UIBezierPath()
            brace.move(CGPoint(body.midX + side * body.width * 0.34,
                                   body.minY + body.height * 0.02))
            brace.addLine(CGPoint(body.midX + side * body.width * 0.20,
                                      bib.minY + braceWidth * 0.5))
            brace.lineWidth = braceWidth
            brace.lineCapStyle = LineCap.round
            brace.stroke()
        }

        // A pocket on the bib, which is the detail that says workwear rather
        // than apron at a glance.
        val pocket = CGRect(bib.midX - bib.width * 0.22,
                            bib.minY + bib.height * 0.16,
                            bib.width * 0.44,
                            bib.height * 0.24)
        stitch.setStroke()
        val outline = UIBezierPath(pocket, pocket.height * 0.25)
        outline.lineWidth = max(0.4, body.width * 0.06)
        outline.stroke()
    }

    // A broom held out at an angle, bristles on the ground.
    //
    // Held at a slant rather than upright: a vertical pole beside somebody
    // reads as a flag or a railing, and only the angle says they are using
    // it. The bristle block is wide because at this size it is most of what
    // anybody can actually see.
    internal fun drawBroom(layout: PersonArtwork.Layout, size: CGSize) {
        val unit = layout.body.width
        val grip = CGPoint(layout.body.maxX + unit * 0.16,
                           layout.body.minY + layout.body.height * 0.30)
        val foot = CGPoint(layout.body.maxX + unit * 0.86,
                           layout.bottom - unit * 0.16)

        val handle = UIBezierPath()
        handle.move(grip)
        handle.addLine(foot)
        ParkPalette.colour(ParkColour.brown).setStroke()
        handle.lineWidth = max(1, unit * 0.20)
        handle.lineCapStyle = LineCap.round
        handle.stroke()

        // The head, square to the ground rather than to the handle, because
        // that is how a broom actually sits when somebody is sweeping with it.
        val head = CGRect(foot.x - unit * 0.46,
                          foot.y - unit * 0.04,
                          unit * 0.92,
                          unit * 0.34)
        ParkPalette.colour(ParkColour.charcoal).setFill()
        UIBezierPath(CGRect(head.minX, head.minY,
                                         head.width, head.height * 0.42),
                     head.height * 0.18).fill()

        ParkPalette.colour(ParkColour.sand).setFill()
        UIBezierPath(CGRect(head.minX, head.minY + head.height * 0.34,
                                  head.width, head.height * 0.66)).fill()

        // A few bristle gaps, which is what stops it reading as a block.
        ParkPalette.colour(ParkColour.brown).withAlphaComponent(0.45).setStroke()
        val bristle = UIBezierPath()
        for (step in 1..3) {
            val x = head.minX + head.width * ((step).toDouble() / 4)
            bristle.move(CGPoint(x, head.minY + head.height * 0.40))
            bristle.addLine(CGPoint(x, head.maxY))
        }
        bristle.lineWidth = max(0.4, unit * 0.05)
        bristle.stroke()
    }

    // A stubby spanner held out from the body, open jaw uppermost.
    internal fun drawWrench(layout: PersonArtwork.Layout, size: CGSize, context: CGContext) {
        val unit = layout.body.width
        val shaft = CGRect(layout.body.maxX + unit * 0.16,
                           layout.body.midY - unit * 0.06,
                           unit * 0.18,
                           unit * 0.62)
        ParkPalette.colour(ParkColour.slate).setFill()
        UIBezierPath(shaft, shaft.width * 0.4).fill()

        val jaw = CGRect(shaft.midX - unit * 0.22,
                         shaft.minY - unit * 0.24,
                         unit * 0.44,
                         unit * 0.30)
        UIBezierPath(ovalIn =  jaw).fill()

        // Bite out of the jaw, which is what makes it a spanner and not a
        // mallet. Punched through to transparency so whatever the employee is
        // standing on shows through it.
        context.saveGState()
        context.setBlendMode(BlendMode.clear)
        UIColor.black.setFill()
        UIBezierPath(ovalIn =  jaw.insetBy(jaw.width * 0.30, jaw.height * 0.26)).fill()
        context.restoreGState()
    }

    // region Acts


    // A red megaphone held up and out to one side, with the sound coming out of
    // it. Something that reads at a glance at this size: a cone, a bright
    // colour, and a few arcs in front of it.
    internal fun drawMegaphone(layout: PersonArtwork.Layout) {
        val unit = layout.body.width
        val grip = CGPoint(layout.body.maxX + unit * 0.10,
                           layout.body.minY + layout.body.height * 0.48)
        val run = unit * 0.62
        val rise = -unit * 0.50
        val length = (run * run + rise * rise).let { sqrt(it) }
        val direction = CGPoint(run / length, rise / length)
        val across = CGPoint(-direction.y, direction.x)
        val mouth = CGPoint(grip.x + run, grip.y + rise)

        val narrow = unit * 0.07
        val wide = unit * 0.25
        val cone = UIBezierPath()
        cone.move(CGPoint(grip.x + across.x * narrow, grip.y + across.y * narrow))
        cone.addLine(CGPoint(mouth.x + across.x * wide, mouth.y + across.y * wide))
        cone.addLine(CGPoint(mouth.x - across.x * wide, mouth.y - across.y * wide))
        cone.addLine(CGPoint(grip.x - across.x * narrow, grip.y - across.y * narrow))
        cone.close()
        ParkPalette.colour(ParkColour.red).setFill()
        cone.fill()
        UIColor.black.withAlphaComponent(0.32).setStroke()
        cone.lineWidth = max(0.6, unit * 0.05)
        cone.stroke()

        // A white band near the wide end.
        val bandAt = CGPoint(mouth.x - direction.x * unit * 0.16, mouth.y - direction.y * unit * 0.16)
        val band = UIBezierPath()
        band.move(CGPoint(bandAt.x + across.x * wide * 0.80, bandAt.y + across.y * wide * 0.80))
        band.addLine(CGPoint(bandAt.x - across.x * wide * 0.80, bandAt.y - across.y * wide * 0.80))
        UIColor.white.setStroke()
        band.lineWidth = max(1, unit * 0.10)
        band.stroke()

        // The opening, seen end on.
        val opening = UIBezierPath(ovalIn =  CGRect(-wide, -unit * 0.07,
                                                  wide * 2, unit * 0.14))
        opening.apply(CGAffineTransform.rotation(atan2(across.y, across.x)))
        opening.apply(CGAffineTransform(mouth.x, mouth.y))
        ParkPalette.colour(ParkColour.charcoal).setFill()
        opening.fill()

        // The handle in the hand.
        val handle = UIBezierPath(ovalIn =  CGRect(grip.x - unit * 0.08, grip.y - unit * 0.08,
                                                 unit * 0.16, unit * 0.16))
        ParkPalette.colour(ParkColour.charcoal).setFill()
        handle.fill()

        // Sound, as two arcs coming off the mouth.
        val heading = atan2(direction.y, direction.x)
        val centre = CGPoint(mouth.x + direction.x * unit * 0.06, mouth.y + direction.y * unit * 0.06)
        UIColor.white.withAlphaComponent(0.9).setStroke()
        for (radius in listOf(unit * 0.26, unit * 0.42)) {
            val arc = UIBezierPath(centre, radius,
                                   heading - 0.55, heading + 0.55,
                                   true)
            arc.lineCapStyle = LineCap.round
            arc.lineWidth = max(0.8, unit * 0.06)
            arc.stroke()
        }
    }

    // A ruff of white scallops round the neck, which is most of what makes a
    // clown a clown from a distance.
    internal fun drawClownCollar(layout: PersonArtwork.Layout) {
        val unit = layout.body.width
        val diameter = unit * 0.26
        for (step in -2..2) {
            val x = layout.body.midX + (step).toDouble() * unit * 0.17
            val y = layout.body.minY + unit * 0.02 + (abs(step)).toDouble() * unit * 0.025
            val rect = CGRect(x - diameter / 2, y - diameter / 2, diameter, diameter)
            UIColor.white.setFill()
            UIBezierPath(ovalIn =  rect).fill()
            UIColor.black.withAlphaComponent(0.25).setStroke()
            val outline = UIBezierPath(ovalIn =  rect)
            outline.lineWidth = max(0.5, unit * 0.04)
            outline.stroke()
        }
    }

    // A squeaky horn: a black rubber bulb and a gold bell.
    internal fun drawHorn(layout: PersonArtwork.Layout) {
        val unit = layout.body.width
        val grip = CGPoint(layout.body.maxX + unit * 0.08, layout.body.midY + unit * 0.12)
        val tip = CGPoint(grip.x + unit * 0.52, grip.y - unit * 0.20)

        val bell = UIBezierPath()
        bell.move(CGPoint(grip.x, grip.y - unit * 0.06))
        bell.addLine(CGPoint(tip.x, tip.y - unit * 0.22))
        bell.addLine(CGPoint(tip.x, tip.y + unit * 0.22))
        bell.addLine(CGPoint(grip.x, grip.y + unit * 0.06))
        bell.close()
        ParkPalette.colour(ParkColour.amber).setFill()
        bell.fill()
        UIColor.black.withAlphaComponent(0.32).setStroke()
        bell.lineWidth = max(0.6, unit * 0.05)
        bell.stroke()

        val bulb = CGRect(grip.x - unit * 0.17, grip.y - unit * 0.12,
                          unit * 0.26, unit * 0.24)
        ParkPalette.colour(ParkColour.charcoal).setFill()
        UIBezierPath(ovalIn =  bulb).fill()
    }

    private class Balloon(val dx: Double, val dy: Double, val colour: ParkColour)

    // A bunch of balloons in four colours on strings, held up off the shoulder.
    internal fun drawBalloonBunch(layout: PersonArtwork.Layout) {
        val unit = layout.body.width
        val anchor = CGPoint(layout.body.maxX + unit * 0.06, layout.body.midY)
        val bunch = listOf(
            Balloon(0.22, 0.78, ParkColour.red),
            Balloon(0.52, 0.52, ParkColour.yellow),
            Balloon(0.20, 0.36, ParkColour.green),
            Balloon(0.56, 0.96, ParkColour.blue))

        for (balloon in bunch) {
            val centre = CGPoint(anchor.x + unit * balloon.dx,
                                 layout.head.minY - unit * (balloon.dy - 0.30))

            val string = UIBezierPath()
            string.move(anchor)
            string.addQuadCurve(centre,
                                CGPoint(anchor.x + unit * balloon.dx * 0.2,
                                                      centre.y + unit * 0.2))
            UIColor.white.withAlphaComponent(0.8).setStroke()
            string.lineWidth = max(0.5, unit * 0.04)
            string.stroke()

            val side = unit * 0.46
            val rect = CGRect(centre.x - side / 2, centre.y - side * 0.58,
                              side, side * 1.16)
            ParkPalette.colour(balloon.colour).setFill()
            UIBezierPath(ovalIn =  rect).fill()
            UIColor.white.withAlphaComponent(0.55).setFill()
            UIBezierPath(ovalIn =  CGRect(rect.minX + side * 0.18, rect.minY + side * 0.14,
                                        side * 0.16, side * 0.22)).fill()
        }
    }

    // A short black wand with a white tip, held out to the side, and a spark
    // of gold where the magic comes out.
    internal fun drawWand(layout: PersonArtwork.Layout) {
        val unit = layout.body.width
        val grip = CGPoint(layout.body.maxX + unit * 0.04, layout.body.midY + unit * 0.10)
        val tip = CGPoint(layout.body.maxX + unit * 0.62, layout.body.minY - unit * 0.06)

        val wand = UIBezierPath()
        wand.move(grip)
        wand.addLine(tip)
        wand.lineCapStyle = LineCap.round
        ParkPalette.colour(ParkColour.charcoal).setStroke()
        wand.lineWidth = max(1, unit * 0.12)
        wand.stroke()

        val end = UIBezierPath()
        end.move(CGPoint(tip.x - (tip.x - grip.x) * 0.16, tip.y - (tip.y - grip.y) * 0.16))
        end.addLine(tip)
        end.lineCapStyle = LineCap.round
        UIColor.white.setStroke()
        end.lineWidth = max(1, unit * 0.12)
        end.stroke()

        // A four-pointed spark.
        val spark = UIBezierPath()
        val reach = unit * 0.26
        val waist = unit * 0.06
        val centre = CGPoint(tip.x + unit * 0.06, tip.y - unit * 0.10)
        spark.move(CGPoint(centre.x, centre.y - reach))
        spark.addLine(CGPoint(centre.x + waist, centre.y - waist))
        spark.addLine(CGPoint(centre.x + reach, centre.y))
        spark.addLine(CGPoint(centre.x + waist, centre.y + waist))
        spark.addLine(CGPoint(centre.x, centre.y + reach))
        spark.addLine(CGPoint(centre.x - waist, centre.y + waist))
        spark.addLine(CGPoint(centre.x - reach, centre.y))
        spark.addLine(CGPoint(centre.x - waist, centre.y - waist))
        spark.close()
        ParkPalette.colour(ParkColour.yellow).setFill()
        spark.fill()
    }

    // The cape, drawn before the figure so it hangs behind the shoulders and
    // shows either side of the body. Placed with the same proportions the
    // figure is drawn to, since the figure has not been drawn yet.
    internal fun drawCapeBehind(colour: UIColor, size: CGSize, figureScale: Double) {
        val figure = size.height * figureScale
        val centreX = size.width / 2
        val bottom = size.height - (size.height - figure) * 0.20
        val top = bottom - figure * 0.58
        val hem = bottom - figure * 0.06

        val cape = UIBezierPath()
        cape.move(CGPoint(centreX - figure * 0.20, top))
        cape.addLine(CGPoint(centreX + figure * 0.20, top))
        cape.addQuadCurve(CGPoint(centreX + figure * 0.40, hem),
                          CGPoint(centreX + figure * 0.34, top + figure * 0.20))
        cape.addQuadCurve(CGPoint(centreX - figure * 0.40, hem),
                          CGPoint(centreX, hem + figure * 0.04))
        cape.addQuadCurve(CGPoint(centreX - figure * 0.20, top),
                          CGPoint(centreX - figure * 0.34, top + figure * 0.20))
        cape.close()

        colour.setFill()
        cape.fill()
        UIColor.black.withAlphaComponent(0.32).setStroke()
        cape.lineWidth = max(1, figure * 0.03)
        cape.stroke()

        // A pale lining just showing at the hem.
        val lining = UIBezierPath()
        lining.move(CGPoint(centreX - figure * 0.38, hem - figure * 0.01))
        lining.addQuadCurve(CGPoint(centreX + figure * 0.38, hem - figure * 0.01),
                            CGPoint(centreX, hem + figure * 0.03))
        UIColor.white.withAlphaComponent(0.6).setStroke()
        lining.lineWidth = max(1, figure * 0.025)
        lining.stroke()
    }

    // region Mascots


    // region Drawing kit

    internal class Pen(val ink: UIColor, val line: Double) {

        fun fill(path: UIBezierPath, colour: UIColor, outlined: Boolean = true) {
            colour.setFill()
            path.fill()
            if (outlined) {
                ink.setStroke()
                path.lineWidth = line
                path.stroke()
            }
        }

        fun oval(centre: CGPoint, width: Double, height: Double, colour: UIColor, outlined: Boolean) = oval(centre, width, height, colour, 0.0, outlined)

        fun oval(centre: CGPoint, width: Double, height: Double, colour: UIColor, angle: Double = 0.0, outlined: Boolean = true) {
            val path = UIBezierPath(ovalIn =  CGRect(-width / 2, -height / 2,
                                                   width, height))
            path.apply(CGAffineTransform.rotation(angle))
            path.apply(CGAffineTransform(centre.x, centre.y))
            fill(path, colour, outlined)
        }

        fun polygon(points: List<CGPoint>, colour: UIColor, outlined: Boolean = true) {
            val first = points.firstOrNull() ?: return
            val path = UIBezierPath()
            path.move(first)
            for (point in points.drop(1)) { path.addLine(point) }
            path.close()
            path.lineJoinStyle = LineJoin.round
            fill(path, colour, outlined)
        }

        // A fat curved line with an outline round it, for tails and trunks.
        fun tube(path: UIBezierPath, colour: UIColor, width: Double) {
            path.lineCapStyle = LineCap.round
            path.lineJoinStyle = LineJoin.round
            ink.setStroke()
            path.lineWidth = width + line * 2
            path.stroke()
            colour.setStroke()
            path.lineWidth = width
            path.stroke()
        }

        fun stroke(path: UIBezierPath, colour: UIColor, width: Double) {
            path.lineCapStyle = LineCap.round
            colour.setStroke()
            path.lineWidth = width
            path.stroke()
        }
    }

    // Where things go. `m` is the costume's own unit: nearly all the
    // measurements below are fractions of it.
    internal class Costume(
        val look: StaffLook, val primary: UIColor, val secondary: UIColor, val trim: UIColor,
        val cx: Double, val floor: Double, val m: Double, val pen: Pen,
    ) {
        val headCentre: CGPoint get() = CGPoint(cx, floor - 0.70 * m)

        // A point measured from the middle of the head, in units of `m`.
        fun head(dx: Number, dy: Number): CGPoint {
            return CGPoint(cx + dx.toDouble() * m, headCentre.y + dy.toDouble() * m)
        }

        // A point measured from the floor in the middle, up and across.
        fun low(dx: Number, up: Number): CGPoint {
            return CGPoint(cx + dx.toDouble() * m, floor - up.toDouble() * m)
        }

        val gloves: Boolean
            get() = when (look.costume) {
                MascotCostume.duck, MascotCostume.owl, MascotCostume.penguin -> false
                else -> true
            }
    }

    // region Entry point

    internal fun drawMascot(look: StaffLook, size: CGSize) {
        val u = size.height
        val costume = Costume(look,
                              ParkPalette.colour(look.primary),
                              ParkPalette.colour(look.secondary),
                              ParkPalette.colour(look.trim),
                              size.width / 2,
                              u * 0.97,
                              u * 0.76,
                              Pen(UIColor.black.withAlphaComponent(0.34),
                                       max(1, u * 0.017)))

        // A faint shadow to stand on, the same as everybody else.
        UIColor.black.withAlphaComponent(0.13).setFill()
        val pad = CGRect(costume.cx - costume.m * 0.30, costume.floor - costume.m * 0.05,
                         costume.m * 0.60, costume.m * 0.09)
        UIBezierPath(ovalIn =  pad).fill()

        drawBackdrop(costume)
        drawFeet(costume)
        drawBody(costume)
        drawArms(costume)
        drawNeckwear(costume)
        drawHead(costume)
        drawFace(costume)
    }

    // region Behind everything: tails, wings, manes, ears

    internal fun drawBackdrop(c: Costume) {
        val pen = c.pen
        when (c.look.costume) {
        MascotCostume.bear -> {
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.25, -0.24), c.m * 0.21, c.m * 0.21, c.primary)
                pen.oval(c.head(side * 0.25, -0.24), c.m * 0.11, c.m * 0.11, c.secondary, false)
            }

        }
        MascotCostume.bunny -> {
            for (side in listOf(-1.0, 1.0)) {
                val centre = c.head(side * 0.14, -0.42)
                pen.oval(centre, c.m * 0.15, c.m * 0.34, c.primary, side * 0.14)
                pen.oval(centre, c.m * 0.08, c.m * 0.24, c.secondary, side * 0.14, false)
            }

        }
        MascotCostume.cat -> {
            for (side in listOf(-1.0, 1.0)) {
                pen.polygon(listOf(c.head(side * 0.31, -0.06), c.head(side * 0.29, -0.40),
                             c.head(side * 0.08, -0.26)), c.primary)
                pen.polygon(listOf(c.head(side * 0.27, -0.12), c.head(side * 0.26, -0.32),
                             c.head(side * 0.13, -0.24)), c.secondary, false)
            }
            val tail = UIBezierPath()
            tail.move(c.low(0.22, 0.14))
            tail.addQuadCurve(c.low(0.52, 0.52), c.low(0.56, 0.10))
            pen.tube(tail, c.primary, c.m * 0.09)

        }
        MascotCostume.owl -> {
            for (side in listOf(-1.0, 1.0)) {
                pen.polygon(listOf(c.head(side * 0.30, -0.02), c.head(side * 0.26, -0.40),
                             c.head(side * 0.08, -0.24)), c.primary)
            }

        }
        MascotCostume.dragon -> {
            // Wings, bat-like, behind the shoulders.
            for (side in listOf(-1.0, 1.0)) {
                pen.polygon(listOf(c.low(side * 0.20, 0.48), c.low(side * 0.58, 0.82),
                             c.low(side * 0.50, 0.50), c.low(side * 0.60, 0.36),
                             c.low(side * 0.38, 0.40), c.low(side * 0.26, 0.20)),
                            c.secondary)
            }
            val tail = UIBezierPath()
            tail.move(c.low(0.20, 0.12))
            tail.addQuadCurve(c.low(0.54, 0.40), c.low(0.56, 0.06))
            pen.tube(tail, c.primary, c.m * 0.10)
            pen.polygon(listOf(c.low(0.54, 0.50), c.low(0.62, 0.38), c.low(0.46, 0.38)), c.secondary)

        }
        MascotCostume.lion -> {
            // The mane: a ring of tufts, then the disc they stand round.
            val centre = c.head(0, 0.0)
            for (index in 0 until 12) {
                val angle = (index).toDouble() / 12 * PI * 2
                val spot = CGPoint(centre.x + cos(angle) * c.m * 0.34,
                                   centre.y + sin(angle) * c.m * 0.32)
                pen.oval(spot, c.m * 0.22, c.m * 0.22, c.secondary)
            }
            pen.oval(centre, c.m * 0.70, c.m * 0.66, c.secondary, false)
            val tail = UIBezierPath()
            tail.move(c.low(0.22, 0.14))
            tail.addQuadCurve(c.low(0.50, 0.44), c.low(0.54, 0.08))
            pen.tube(tail, c.primary, c.m * 0.07)
            pen.oval(c.low(0.52, 0.48), c.m * 0.16, c.m * 0.18, c.secondary)

        }
        MascotCostume.elephant -> {
            for (side in listOf(-1.0, 1.0)) {
                val centre = c.head(side * 0.40, 0.02)
                pen.oval(centre, c.m * 0.32, c.m * 0.40, c.primary, side * -0.12)
                pen.oval(centre, c.m * 0.21, c.m * 0.29, c.secondary, side * -0.12, false)
            }

        }
        MascotCostume.frog, MascotCostume.duck, MascotCostume.penguin -> {}
        }
    }

    // region Feet

    internal fun drawFeet(c: Costume) {
        val colour: UIColor
        when (c.look.costume) {
        MascotCostume.duck -> {
            colour = c.secondary
        }
        MascotCostume.penguin -> {
            colour = ParkPalette.colour(ParkColour.amber)
        }
        else -> {
            colour = c.trim
        }
        }
        val width = (if (c.look.costume == MascotCostume.frog || c.look.costume == MascotCostume.duck) 0.27 else 0.22)

        for (side in listOf(-1.0, 1.0)) {
            c.pen.oval(c.low(side * 0.14, 0.05), c.m * width, c.m * 0.11, colour)
        }
    }

    // region Body

    internal fun drawBody(c: Costume) {
        val pen = c.pen
        pen.oval(c.low(0, 0.30), c.m * 0.54, c.m * 0.48, c.primary)

        // Belly.
        val belly = c.low(0, 0.27)
        when (c.look.costume) {
        MascotCostume.penguin -> {
            pen.oval(belly, c.m * 0.38, c.m * 0.40, c.secondary, false)
        }
        MascotCostume.lion -> {
            pen.oval(belly, c.m * 0.32, c.m * 0.30,
                     UIColor.white.withAlphaComponent(0.30), false)
        }
        MascotCostume.owl -> {
            pen.oval(belly, c.m * 0.36, c.m * 0.36, c.secondary, false)
            // Feathers: little scallops down the chest.
            for (row in 0 until 3) {
                for (column in 0 until (row + 2)) {
                    val offset = ((column).toDouble() - (row + 1).toDouble() / 2) * 0.12
                    val spot = c.low(offset, 0.36 - (row).toDouble() * 0.09)
                    val scallop = UIBezierPath()
                    scallop.addArc(spot, c.m * 0.05,
                                   0, PI, true)
                    pen.stroke(scallop, c.primary.withAlphaComponent(0.7), c.m * 0.02)
                }
            }
        }
        MascotCostume.dragon -> {
            pen.oval(belly, c.m * 0.32, c.m * 0.34, c.secondary, false)
            for (row in 0 until 4) {
                val band = UIBezierPath()
                val y = c.floor - c.m * (0.16 + 0.07 * (row).toDouble())
                band.move(CGPoint(c.cx - c.m * 0.12, y))
                band.addLine(CGPoint(c.cx + c.m * 0.12, y))
                pen.stroke(band, c.primary.withAlphaComponent(0.45), c.m * 0.02)
            }
        }
        else -> {
            pen.oval(belly, c.m * 0.32, c.m * 0.30, c.secondary, false)
        }
        }
    }

    // region Arms and gloves

    internal fun drawArms(c: Costume) {
        val pen = c.pen
        for (side in listOf(-1.0, 1.0)) {
            val angle = side * -0.32
            val shoulder = c.low(side * 0.31, 0.32)
            val width: Double = (if (c.look.costume == MascotCostume.penguin) 0.11 else 0.15)
            pen.oval(shoulder, c.m * width, c.m * 0.31, c.primary, angle)

            if (!(c.gloves)) continue
            // The hand, at the far end of the arm.
            val reach = c.m * 0.15
            val hand = CGPoint(shoulder.x - sin(angle) * reach,
                               shoulder.y + cos(angle) * reach)
            pen.oval(hand, c.m * 0.17, c.m * 0.14, UIColor.white)
        }
    }

    // region Bow tie, or a scarf

    internal fun drawNeckwear(c: Costume) {
        val pen = c.pen
        val neck = c.low(0, 0.53)

        if (c.look.costume == MascotCostume.penguin) {
            // A scarf: a band round the neck and a tail hanging down the front.
            pen.oval(neck, c.m * 0.40, c.m * 0.11, c.trim)
            pen.polygon(listOf(CGPoint(neck.x + c.m * 0.07, neck.y),
                         CGPoint(neck.x + c.m * 0.17, neck.y + c.m * 0.02),
                         CGPoint(neck.x + c.m * 0.15, neck.y + c.m * 0.22),
                         CGPoint(neck.x + c.m * 0.06, neck.y + c.m * 0.20)), c.trim)
            return
        }

        pen.polygon(listOf(neck,
                     CGPoint(neck.x - c.m * 0.14, neck.y - c.m * 0.07),
                     CGPoint(neck.x - c.m * 0.14, neck.y + c.m * 0.07)), c.trim)
        pen.polygon(listOf(neck,
                     CGPoint(neck.x + c.m * 0.14, neck.y - c.m * 0.07),
                     CGPoint(neck.x + c.m * 0.14, neck.y + c.m * 0.07)), c.trim)
        pen.oval(neck, c.m * 0.07, c.m * 0.07, c.trim)
    }

    // region Head

    internal fun drawHead(c: Costume) {
        val wide: Double = (if (c.look.costume == MascotCostume.frog) 0.70 else 0.62)
        val tall: Double = (if (c.look.costume == MascotCostume.frog) 0.50 else 0.56)
        c.pen.oval(c.head(0, 0), c.m * wide, c.m * tall, c.primary)
    }

    // region Faces

    internal fun drawFace(c: Costume) {
        val pen = c.pen
        val dark = ParkPalette.colour(ParkColour.charcoal)

        when (c.look.costume) {
        MascotCostume.bear -> {
            pen.oval(c.head(0, 0.10), c.m * 0.31, c.m * 0.22, c.secondary)
            pen.oval(c.head(0, 0.03), c.m * 0.11, c.m * 0.07, dark, false)
            smile(c, c.head(0, 0.09), 0.12)
            eyes(c, 0.14, -0.07, 0.15)

        }
        MascotCostume.frog -> {
            // The eyes sit up on top of the head, which is the whole frog.
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.20, -0.28), c.m * 0.25, c.m * 0.25, c.primary)
            }
            eyes(c, 0.20, -0.28, 0.17)
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.26, 0.08), c.m * 0.12, c.m * 0.08,
                         ParkPalette.colour(ParkColour.pink).withAlphaComponent(0.55), false)
                pen.oval(c.head(side * 0.05, -0.04), c.m * 0.03, c.m * 0.03, dark, false)
            }
            val mouth = UIBezierPath()
            mouth.move(c.head(-0.25, 0.06))
            mouth.addQuadCurve(c.head(0.25, 0.06), c.head(0, 0.22))
            pen.stroke(mouth, dark, c.m * 0.03)

        }
        MascotCostume.bunny -> {
            pen.oval(c.head(0, 0.10), c.m * 0.28, c.m * 0.19, UIColor.white)
            pen.oval(c.head(0, 0.04), c.m * 0.08, c.m * 0.055, c.secondary, false)
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.26, 0.08), c.m * 0.11, c.m * 0.08,
                         c.secondary.withAlphaComponent(0.45), false)
            }
            val teeth = CGRect(c.head(0, 0).x - c.m * 0.045, c.head(0, 0.13).y,
                               c.m * 0.09, c.m * 0.08)
            pen.fill(UIBezierPath(teeth, c.m * 0.02), UIColor.white)
            val split = UIBezierPath()
            split.move(CGPoint(teeth.midX, teeth.minY))
            split.addLine(CGPoint(teeth.midX, teeth.maxY))
            pen.stroke(split, (if (c.look.primary == ParkColour.white) dark.withAlphaComponent(0.4) else c.primary), c.m * 0.01)
            eyes(c, 0.14, -0.08, 0.15)

        }
        MascotCostume.duck -> {
            // Three tufts on top, and a broad flat beak.
            for (dx in listOf(-0.07, 0.0, 0.07)) {
                pen.oval(c.head(dx, -0.30), c.m * 0.07, c.m * 0.14, c.primary, dx * 3)
            }
            eyes(c, 0.14, -0.10, 0.14)
            pen.oval(c.head(0, 0.10), c.m * 0.40, c.m * 0.17, c.secondary)
            val seam = UIBezierPath()
            seam.move(c.head(-0.17, 0.10))
            seam.addLine(c.head(0.17, 0.10))
            pen.stroke(seam, UIColor.black.withAlphaComponent(0.28), c.m * 0.015)

        }
        MascotCostume.cat -> {
            val stripes = UIBezierPath()
            for (dx in listOf(-0.08, 0.0, 0.08)) {
                stripes.move(c.head(dx, -0.27))
                stripes.addLine(c.head(dx * 0.8, -0.17))
            }
            pen.stroke(stripes, UIColor.black.withAlphaComponent(0.25), c.m * 0.025)
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.07, 0.10), c.m * 0.16, c.m * 0.14, c.secondary, false)
            }
            pen.polygon(listOf(c.head(-0.04, 0.04), c.head(0.04, 0.04), c.head(0, 0.09)),
                        ParkPalette.colour(ParkColour.pink), false)
            val whiskers = UIBezierPath()
            for (side in listOf(-1.0, 1.0)) {
                for (tilt in listOf(-0.04, 0.0, 0.04)) {
                    whiskers.move(c.head(side * 0.14, 0.10 + tilt * 0.5))
                    whiskers.addLine(c.head(side * 0.36, 0.10 + tilt * 2))
                }
            }
            pen.stroke(whiskers, UIColor.white.withAlphaComponent(0.9), c.m * 0.012)
            eyes(c, 0.14, -0.07, 0.15)

        }
        MascotCostume.owl -> {
            // Two big round faces with the eyes in them, and a small beak.
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.15, -0.03), c.m * 0.30, c.m * 0.30, c.secondary)
            }
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.15, -0.03), c.m * 0.21, c.m * 0.21, UIColor.white)
                pen.oval(c.head(side * 0.15, -0.03), c.m * 0.13, c.m * 0.13,
                         ParkPalette.colour(ParkColour.amber), false)
                pen.oval(c.head(side * 0.15, -0.03), c.m * 0.07, c.m * 0.07, dark, false)
            }
            pen.polygon(listOf(c.head(-0.045, 0.06), c.head(0.045, 0.06), c.head(0, 0.17)),
                        ParkPalette.colour(ParkColour.amber))

        }
        MascotCostume.penguin -> {
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.10, 0.03), c.m * 0.23, c.m * 0.28, c.secondary, false)
            }
            eyes(c, 0.12, -0.04, 0.13)
            pen.polygon(listOf(c.head(-0.07, 0.07), c.head(0.07, 0.07), c.head(0, 0.17)),
                        ParkPalette.colour(ParkColour.amber))

        }
        MascotCostume.dragon -> {
            // Horns and a crest, a long snout with nostrils and a few teeth.
            for (side in listOf(-1.0, 1.0)) {
                pen.polygon(listOf(c.head(side * 0.22, -0.20), c.head(side * 0.30, -0.44),
                             c.head(side * 0.12, -0.26)), c.secondary)
            }
            for (dx in listOf(-0.09, 0.0, 0.09)) {
                pen.polygon(listOf(c.head(dx - 0.04, -0.27), c.head(dx, -0.38),
                             c.head(dx + 0.04, -0.27)), c.secondary, false)
            }
            pen.oval(c.head(0, 0.10), c.m * 0.34, c.m * 0.22, UIColor.white.withAlphaComponent(0.28),
                     false)
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.06, 0.04), c.m * 0.035, c.m * 0.03, dark, false)
                pen.polygon(listOf(c.head(side * 0.13, 0.17), c.head(side * 0.10, 0.17),
                             c.head(side * 0.115, 0.21)), UIColor.white, false)
            }
            // Eyes with a slit for a pupil.
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.14, -0.08), c.m * 0.15, c.m * 0.15,
                         ParkPalette.colour(ParkColour.amber))
                pen.oval(c.head(side * 0.14, -0.08), c.m * 0.04, c.m * 0.11, dark, false)
            }

        }
        MascotCostume.lion -> {
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.22, -0.25), c.m * 0.14, c.m * 0.14, c.primary)
            }
            pen.oval(c.head(0, 0.10), c.m * 0.28, c.m * 0.20, UIColor.white.withAlphaComponent(0.55),
                     false)
            pen.polygon(listOf(c.head(-0.05, 0.03), c.head(0.05, 0.03), c.head(0, 0.09)),
                        ParkPalette.colour(ParkColour.brown), false)
            smile(c, c.head(0, 0.10), 0.14)
            eyes(c, 0.14, -0.07, 0.14)

        }
        MascotCostume.elephant -> {
            // The trunk, curling down and a little to one side, with tusks.
            for (side in listOf(-1.0, 1.0)) {
                pen.oval(c.head(side * 0.11, 0.20), c.m * 0.06, c.m * 0.13,
                         UIColor.white, side * 0.25)
            }
            val trunk = UIBezierPath()
            trunk.move(c.head(0, 0.02))
            trunk.addQuadCurve(c.head(0.07, 0.40), c.head(-0.04, 0.26))
            pen.tube(trunk, c.primary, c.m * 0.13)
            val rings = UIBezierPath()
            for (step in 1..3) {
                val y = 0.10 + (step).toDouble() * 0.08
                rings.move(c.head(-0.05, y))
                rings.addLine(c.head(0.05, y))
            }
            pen.stroke(rings, UIColor.black.withAlphaComponent(0.18), c.m * 0.015)
            eyes(c, 0.14, -0.07, 0.12)
        }
        }
    }

    // region Small parts

    // Two round eyes with a glint, which is what makes a costume look back.
    internal fun eyes(c: Costume, dx: Double, dy: Double, diameter: Double) {
        val dark = ParkPalette.colour(ParkColour.charcoal)
        for (side in listOf(-1.0, 1.0)) {
            val centre = c.head(side * dx, dy)
            c.pen.oval(centre, c.m * diameter, c.m * diameter, UIColor.white)
            c.pen.oval(CGPoint(centre.x, centre.y + c.m * 0.005),
                       c.m * diameter * 0.52, c.m * diameter * 0.58, dark, false)
            c.pen.oval(CGPoint(centre.x - c.m * diameter * 0.10, centre.y - c.m * diameter * 0.12),
                       c.m * diameter * 0.17, c.m * diameter * 0.17, UIColor.white, false)
        }
    }

    // A small curved smile under the nose.
    internal fun smile(c: Costume, point: CGPoint, width: Double) {
        val mouth = UIBezierPath()
        mouth.move(CGPoint(point.x - c.m * width, point.y + c.m * 0.01))
        mouth.addQuadCurve(CGPoint(point.x + c.m * width, point.y + c.m * 0.01),
                           CGPoint(point.x, point.y + c.m * 0.09))
        c.pen.stroke(mouth, ParkPalette.colour(ParkColour.charcoal), c.m * 0.025)
    }

}
