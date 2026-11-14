package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingMotif
import kotlin.math.max
import kotlin.math.min

/**
 * The fences and the cash machine. A fence is drawn from a post at the middle of its tile with an arm running out to
 * each side that has another fence against it, so a row of them reads as one continuous fence. [mask] carries those
 * sides: 1 up the screen, 2 right, 4 down, 8 left, the same bits the walkway uses. Texture space runs y downward.
 */
object BuildingArtFences {

    private fun fill(path: UIBezierPath, colour: UIColor) = BuildingArtwork.fill(path, colour)
    private fun withShadow(context: CGContext, body: () -> Unit) = BuildingArtwork.withShadow(context, body)
    private fun box(x: Double, y: Double, w: Double, h: Double) = UIBezierPath(rect = CGRect(x, y, w, h))
    private fun rounded(x: Double, y: Double, w: Double, h: Double, corner: Double) =
        UIBezierPath(roundedRect = CGRect(x, y, w, h), cornerRadius = corner)
    private fun oval(x: Double, y: Double, w: Double, h: Double) = UIBezierPath(ovalIn = CGRect(x, y, w, h))

    /** A fence on its own is drawn as a short run left to right, so it still looks like a fence. */
    private fun sides(mask: Int): Int = if (mask and 15 == 0) 2 or 8 else mask and 15

    private class Arm(val rect: CGRect, val horizontal: Boolean)

    /** The strip from the middle of the tile to one edge, [thickness] across. */
    private fun arms(size: CGSize, mask: Int, thickness: Double): List<Arm> {
        val cx = size.width / 2
        val cy = size.height / 2
        val t = size.width * thickness
        val result = ArrayList<Arm>()
        val s = sides(mask)
        if (s and 1 != 0) result.add(Arm(CGRect(cx - t / 2, 0.0, t, cy + t / 2), false))
        if (s and 4 != 0) result.add(Arm(CGRect(cx - t / 2, cy - t / 2, t, size.height - (cy - t / 2)), false))
        if (s and 2 != 0) result.add(Arm(CGRect(cx - t / 2, cy - t / 2, size.width - (cx - t / 2), t), true))
        if (s and 8 != 0) result.add(Arm(CGRect(0.0, cy - t / 2, cx + t / 2, t), true))
        return result
    }

    fun drawFence(context: CGContext, size: CGSize, motif: BuildingMotif, primary: UIColor, secondary: UIColor, accent: UIColor, mask: Int) {
        when (motif) {
            BuildingMotif.picketFence -> picket(context, size, primary, secondary, accent, mask)
            BuildingMotif.rusticFence -> rustic(context, size, primary, secondary, accent, mask)
            BuildingMotif.ironFence -> iron(context, size, primary, secondary, accent, mask)
            else -> stone(context, size, primary, secondary, accent, mask)
        }
    }

    private fun picket(context: CGContext, size: CGSize, white: UIColor, cream: UIColor, wood: UIColor, mask: Int) {
        val w = size.width
        val h = size.height
        val strips = arms(size, mask, 0.12)
        withShadow(context) {
            for (arm in strips) fill(UIBezierPath(rect = arm.rect), white)
        }
        // The pickets stand across the rail, a point on top of each.
        for (arm in strips) {
            val r = arm.rect
            val count = 4
            for (index in 0 until count) {
                val t = (index + 0.5) / count
                if (arm.horizontal) {
                    val x = r.minX + r.width * t - w * 0.035
                    fill(rounded(x, r.minY - h * 0.10, w * 0.07, r.height + h * 0.20, w * 0.03), white)
                    fill(box(x + w * 0.01, r.minY - h * 0.10, w * 0.02, r.height + h * 0.20), cream)
                } else {
                    val y = r.minY + r.height * t - h * 0.035
                    fill(rounded(r.minX - w * 0.10, y, r.width + w * 0.20, h * 0.07, h * 0.03), white)
                    fill(box(r.minX - w * 0.10, y + h * 0.01, r.width + w * 0.20, h * 0.02), cream)
                }
            }
        }
        // The post, with a cap.
        withShadow(context) { fill(rounded(w * 0.40, h * 0.40, w * 0.20, h * 0.20, w * 0.04), white) }
        fill(rounded(w * 0.37, h * 0.37, w * 0.26, h * 0.26, w * 0.05), cream)
        fill(rounded(w * 0.42, h * 0.42, w * 0.16, h * 0.16, w * 0.03), wood)
    }

    private fun rustic(context: CGContext, size: CGSize, bark: UIColor, light: UIColor, shade: UIColor, mask: Int) {
        val w = size.width
        val h = size.height
        // Two rails, side by side along each arm.
        for (arm in arms(size, mask, 0.22)) {
            val r = arm.rect
            val rail = if (arm.horizontal) r.height * 0.34 else r.width * 0.34
            withShadow(context) {
                if (arm.horizontal) {
                    fill(rounded(r.minX, r.minY, r.width, rail, rail * 0.5), bark)
                    fill(rounded(r.minX, r.maxY - rail, r.width, rail, rail * 0.5), bark)
                } else {
                    fill(rounded(r.minX, r.minY, rail, r.height, rail * 0.5), bark)
                    fill(rounded(r.maxX - rail, r.minY, rail, r.height, rail * 0.5), bark)
                }
            }
            // A lit edge on each rail.
            if (arm.horizontal) {
                fill(rounded(r.minX, r.minY, r.width, rail * 0.4, rail * 0.2), light)
                fill(rounded(r.minX, r.maxY - rail, r.width, rail * 0.4, rail * 0.2), light)
            } else {
                fill(rounded(r.minX, r.minY, rail * 0.4, r.height, rail * 0.2), light)
                fill(rounded(r.maxX - rail, r.minY, rail * 0.4, r.height, rail * 0.2), light)
            }
        }
        // A log post with a cut end.
        withShadow(context) { fill(oval(w * 0.36, h * 0.36, w * 0.28, h * 0.28), bark) }
        fill(oval(w * 0.40, h * 0.40, w * 0.20, h * 0.20), light)
        fill(oval(w * 0.46, h * 0.46, w * 0.08, h * 0.08), shade)
    }

    private fun iron(context: CGContext, size: CGSize, iron: UIColor, sheen: UIColor, gold: UIColor, mask: Int) {
        val w = size.width
        val h = size.height
        val strips = arms(size, mask, 0.20)
        for (arm in strips) {
            val r = arm.rect
            val bars = 4
            withShadow(context) {
                if (arm.horizontal) {
                    fill(box(r.minX, r.minY + r.height * 0.18, r.width, r.height * 0.10), iron)
                    fill(box(r.minX, r.maxY - r.height * 0.28, r.width, r.height * 0.10), iron)
                } else {
                    fill(box(r.minX + r.width * 0.18, r.minY, r.width * 0.10, r.height), iron)
                    fill(box(r.maxX - r.width * 0.28, r.minY, r.width * 0.10, r.height), iron)
                }
            }
            for (index in 0 until bars) {
                val t = (index + 0.5) / bars
                if (arm.horizontal) {
                    val x = r.minX + r.width * t - w * 0.016
                    fill(box(x, r.minY, w * 0.032, r.height), iron)
                    // Spear tip.
                    val tip = UIBezierPath()
                    tip.move(CGPoint(x - w * 0.02, r.minY))
                    tip.addLine(CGPoint(x + w * 0.016, r.minY - h * 0.07))
                    tip.addLine(CGPoint(x + w * 0.052, r.minY))
                    tip.close()
                    fill(tip, iron)
                } else {
                    val y = r.minY + r.height * t - h * 0.016
                    fill(box(r.minX, y, r.width, h * 0.032), iron)
                    val tip = UIBezierPath()
                    tip.move(CGPoint(r.minX, y - h * 0.02))
                    tip.addLine(CGPoint(r.minX - w * 0.07, y + h * 0.016))
                    tip.addLine(CGPoint(r.minX, y + h * 0.052))
                    tip.close()
                    fill(tip, iron)
                }
            }
            // A glint along the top rail.
            if (arm.horizontal) fill(box(r.minX, r.minY + r.height * 0.18, r.width, r.height * 0.03), sheen)
            else fill(box(r.minX + r.width * 0.18, r.minY, r.width * 0.03, r.height), sheen)
        }
        // Heavy post with a gilded ball.
        withShadow(context) { fill(rounded(w * 0.38, h * 0.38, w * 0.24, h * 0.24, w * 0.03), iron) }
        fill(rounded(w * 0.42, h * 0.42, w * 0.16, h * 0.16, w * 0.02), sheen)
        fill(oval(w * 0.43, h * 0.43, w * 0.14, h * 0.14), gold)
    }

    private fun stone(context: CGContext, size: CGSize, stone: UIColor, mortar: UIColor, shade: UIColor, mask: Int) {
        val w = size.width
        val h = size.height
        val strips = arms(size, mask, 0.30)
        withShadow(context) {
            for (arm in strips) fill(rounded(arm.rect.minX, arm.rect.minY, arm.rect.width, arm.rect.height, w * 0.04), stone)
            fill(rounded(w * 0.33, h * 0.33, w * 0.34, h * 0.34, w * 0.05), stone)
        }
        // A pale cap on top, and the joints between blocks.
        for (arm in strips) {
            val r = arm.rect
            fill(rounded(r.minX + w * 0.015, r.minY + h * 0.015, r.width - w * 0.03, r.height - h * 0.03, w * 0.03), mortar.withAlphaComponent(0.55))
            val blocks = 3
            for (index in 1 until blocks) {
                val t = index.toDouble() / blocks
                if (arm.horizontal) fill(box(r.minX + r.width * t, r.minY + h * 0.02, w * 0.014, r.height - h * 0.04), shade.withAlphaComponent(0.7))
                else fill(box(r.minX + w * 0.02, r.minY + r.height * t, r.width - w * 0.04, h * 0.014), shade.withAlphaComponent(0.7))
            }
        }
        fill(rounded(w * 0.355, h * 0.355, w * 0.29, h * 0.29, w * 0.04), mortar.withAlphaComponent(0.6))
        fill(box(w * 0.40, h * 0.49, w * 0.20, h * 0.014), shade.withAlphaComponent(0.7))
    }

    /** A free-standing cash machine: a steel kiosk with a lit screen, a keypad and a slot. */
    fun drawAtm(context: CGContext, size: CGSize, body: UIColor, panel: UIColor, glow: UIColor) {
        val w = size.width
        val h = size.height
        fill(oval(w * 0.12, h * 0.84, w * 0.76, h * 0.12), UIColor.black.withAlphaComponent(0.18))
        withShadow(context) { fill(rounded(w * 0.20, h * 0.08, w * 0.60, h * 0.80, w * 0.06), body) }
        // Header sign.
        fill(rounded(w * 0.24, h * 0.11, w * 0.52, h * 0.12, w * 0.03), glow)
        fill(rounded(w * 0.30, h * 0.145, w * 0.40, h * 0.04, w * 0.015), UIColor.white.withAlphaComponent(0.85))
        // Screen.
        fill(rounded(w * 0.28, h * 0.27, w * 0.44, h * 0.22, w * 0.03), UIColor(0.07, 0.12, 0.16, 1.0))
        fill(rounded(w * 0.31, h * 0.30, w * 0.38, h * 0.16, w * 0.02), panel)
        fill(rounded(w * 0.34, h * 0.33, w * 0.20, h * 0.03, w * 0.01), UIColor.white.withAlphaComponent(0.7))
        // Keypad.
        for (row in 0 until 3) {
            for (column in 0 until 3) {
                fill(rounded(w * (0.30 + column * 0.085), h * (0.54 + row * 0.060), w * 0.07, h * 0.045, w * 0.01),
                    UIColor.white.withAlphaComponent(0.78))
            }
        }
        // Cash slot, with notes poking out.
        fill(rounded(w * 0.30, h * 0.74, w * 0.40, h * 0.05, w * 0.015), UIColor(0.05, 0.07, 0.09, 1.0))
        fill(rounded(w * 0.36, h * 0.72, w * 0.28, h * 0.04, w * 0.01), UIColor(0.55, 0.84, 0.56, 1.0))
    }
}
