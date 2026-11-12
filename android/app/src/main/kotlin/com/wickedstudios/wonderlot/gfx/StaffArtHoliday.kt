package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.max

/** The two holiday performers: the ordinary entertainer figure with the costume drawn over it. */
object StaffArtHoliday {

    private fun oval(x: Double, y: Double, w: Double, h: Double) = UIBezierPath(ovalIn = CGRect(x, y, w, h))

    /** Santa: a white band on the red hat, a full white beard, and a black belt with a gold buckle. */
    fun drawSantaExtras(layout: PersonArtwork.Layout) {
        val head = layout.head
        val body = layout.body
        val white = UIColor(0.97, 0.97, 0.99, 1.0)

        // Fur band where the hat meets the head.
        val band = CGRect(head.minX - head.width * 0.04, head.minY + head.height * 0.10, head.width * 1.08, head.height * 0.20)
        white.setFill()
        UIBezierPath(roundedRect = band, cornerRadius = band.height * 0.5).fill()

        // Beard: a rounded shape over the lower half of the face.
        val beard = UIBezierPath()
        beard.move(CGPoint(head.minX + head.width * 0.02, head.midY - head.height * 0.04))
        beard.addQuadCurve(CGPoint(head.midX, head.maxY + head.height * 0.26),
            CGPoint(head.minX - head.width * 0.04, head.maxY + head.height * 0.20))
        beard.addQuadCurve(CGPoint(head.maxX - head.width * 0.02, head.midY - head.height * 0.04),
            CGPoint(head.maxX + head.width * 0.04, head.maxY + head.height * 0.20))
        beard.addQuadCurve(CGPoint(head.minX + head.width * 0.02, head.midY - head.height * 0.04),
            CGPoint(head.midX, head.midY + head.height * 0.10))
        beard.close()
        white.setFill()
        beard.fill()

        // A touch of rosy cheek above it.
        UIColor(0.95, 0.55, 0.52, 0.7).setFill()
        for (side in listOf(-1.0, 1.0)) {
            val r = head.width * 0.10
            oval(head.midX + side * head.width * 0.26 - r, head.midY - head.height * 0.08, r * 2, r * 1.4).fill()
        }

        // Belt and buckle.
        val belt = CGRect(body.minX, body.midY + body.height * 0.06, body.width, body.height * 0.16)
        ParkPalette.colour(ParkColour.charcoal).setFill()
        UIBezierPath(rect = belt).fill()
        val buckle = CGRect(body.midX - belt.height * 0.55, belt.minY - belt.height * 0.05, belt.height * 1.1, belt.height * 1.1)
        UIColor(1.0, 0.82, 0.28, 1.0).setFill()
        UIBezierPath(rect = buckle).fill()

        // White trim down the front of the coat.
        white.setFill()
        UIBezierPath(rect = CGRect(body.midX - body.width * 0.05, body.minY, body.width * 0.10, belt.minY - body.minY)).fill()
    }

    /** Mrs. Claus: white hair in a bun with a red bow, small round glasses, a white apron and a tray of cookies. */
    fun drawMrsClausExtras(layout: PersonArtwork.Layout) {
        val head = layout.head
        val body = layout.body
        val white = UIColor(0.97, 0.97, 0.99, 1.0)

        val bun = head.width * 0.40
        white.setFill()
        oval(head.midX - bun / 2, head.minY - bun * 0.62, bun, bun).fill()
        val red = UIColor(0.86, 0.16, 0.20, 1.0)
        red.setFill()
        for (side in listOf(-1.0, 1.0)) {
            oval(head.midX + side * bun * 0.30 - bun * 0.20, head.minY - bun * 0.08, bun * 0.40, bun * 0.26).fill()
        }

        UIColor(0.2, 1.0).setStroke()
        for (side in listOf(-1.0, 1.0)) {
            val r = head.width * 0.14
            val lens = oval(head.midX + side * head.width * 0.20 - r, head.midY - r * 0.9, r * 2, r * 2)
            lens.lineWidth = max(0.6, head.width * 0.03)
            lens.stroke()
        }

        val apron = CGRect(body.minX + body.width * 0.12, body.minY + body.height * 0.12, body.width * 0.76, body.height * 0.88)
        white.setFill()
        UIBezierPath(roundedRect = apron, cornerRadius = apron.width * 0.14).fill()
        red.setFill()
        UIBezierPath(rect = CGRect(apron.minX, apron.minY, apron.width, apron.height * 0.10)).fill()

        val tray = CGRect(body.maxX - body.width * 0.05, body.midY, body.width * 0.62, body.width * 0.12)
        UIColor(0.74, 0.76, 0.80, 1.0).setFill()
        UIBezierPath(roundedRect = tray, cornerRadius = tray.height * 0.4).fill()
        UIColor(0.74, 0.46, 0.22, 1.0).setFill()
        for (index in 0 until 3) {
            val r = tray.height * 0.9
            oval(tray.minX + tray.width * (0.12 + 0.28 * index), tray.minY - r * 0.8, r, r).fill()
        }
    }
}
