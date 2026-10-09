package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin


// The two newest guest amenities: a washroom with marble and attendants, and
// a cart that sells popcorn.
internal object BuildingArtAmenities {

    // region Luxury washroom

    // A small marble hall: gold roof band, columns, and a tall arched door
    // between two ordinary ones. Wider than the plain restroom, and dressed up
    // enough that nobody mistakes the two at a glance.
    internal fun drawLuxuryRestroom(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.05, size.height * 0.10)
        val outline = UIBezierPath(body, body.height * 0.10)

        BuildingArtwork.withShadow(context) { BuildingArtwork.fill(outline, primary) }

        // Gold roof band, clipped to the building so it follows the corners.
        context.saveGState()
        outline.addClip()
        val band = CGRect(body.minX, body.minY,
                          body.width, body.height * 0.22)
        BuildingArtwork.fill(UIBezierPath(band), secondary)
        val rule = CGRect(body.minX, band.maxY,
                          body.width, body.height * 0.035)
        BuildingArtwork.fill(UIBezierPath(rule), secondary.withAlphaComponent(0.7))
        context.restoreGState()

        // Columns either side of the middle, in pale stone.
        val columnWidth = body.width * 0.05
        val columnTop = band.maxY + body.height * 0.05
        val columnHeight = body.maxY - columnTop - body.height * 0.05
        for (fraction in listOf(0.31, 0.69)) {
            val column = CGRect(body.minX + body.width * fraction - columnWidth / 2,
                                columnTop, columnWidth, columnHeight)
            BuildingArtwork.fill(UIBezierPath(column, columnWidth * 0.4),
                 secondary.withAlphaComponent(0.85))
        }

        // The tall arched door in the middle, framed in gold.
        val doorWidth = body.width * 0.20
        val door = CGRect(body.midX - doorWidth / 2,
                          columnTop,
                          doorWidth,
                          columnHeight)
        val arch = CGSize(doorWidth / 2, doorWidth / 2)
        val frame = door.insetBy(-doorWidth * 0.08, -doorWidth * 0.08)
        BuildingArtwork.fill(UIBezierPath(frame,
                          listOf(UIRectCorner.topLeft, UIRectCorner.topRight),
                          arch), secondary)
        BuildingArtwork.fill(UIBezierPath(door,
                          listOf(UIRectCorner.topLeft, UIRectCorner.topRight),
                          arch), accent)

        // An ordinary door at each end.
        val sideWidth = body.width * 0.13
        for (fraction in listOf(0.14, 0.86)) {
            val side = CGRect(body.minX + body.width * fraction - sideWidth / 2,
                              columnTop + columnHeight * 0.22,
                              sideWidth, columnHeight * 0.78)
            BuildingArtwork.fill(UIBezierPath(side, sideWidth * 0.25), accent)
        }

        // Planters flanking the entrance.
        val planter = body.height * 0.13
        for (fraction in listOf(0.43, 0.57)) {
            val spot = CGRect(body.minX + body.width * fraction - planter / 2,
                              body.maxY - planter * 0.9,
                              planter, planter)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  spot), ParkPalette.colour(ParkColour.green))
        }
    }

    // region Popcorn cart

    // A striped awning over a glass case of popcorn, on two wheels.
    internal fun drawPopcornCart(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val wheel = size.width * 0.17
        for (fraction in listOf(0.28, 0.72)) {
            val rim = CGRect(size.width * fraction - wheel / 2,
                             size.height * 0.80, wheel, wheel)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  rim), ParkPalette.colour(ParkColour.charcoal))
        }

        // The cart itself.
        val cart = CGRect(size.width * 0.14, size.height * 0.52,
                          size.width * 0.72, size.height * 0.32)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(cart, cart.height * 0.2), primary)
        }

        // The glass case, with the popcorn heaped in it.
        val glass = CGRect(size.width * 0.20, size.height * 0.28,
                           size.width * 0.60, size.height * 0.26)
        BuildingArtwork.fill(UIBezierPath(glass, glass.height * 0.15),
             UIColor.white.withAlphaComponent(0.78))
        val puff = glass.height * 0.46
        for (index in 0 until 5) {
            val x = glass.minX + glass.width * (0.12 + 0.19 * (index).toDouble())
            val y = glass.minY + glass.height * ( (if (index % 2 == 0) 0.08 else 0.22))
            val kernel = CGRect(x - puff / 2, y, puff, puff)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  kernel), (if (index % 2 == 0) secondary else accent))
        }

        // The awning, in stripes, wider than the cart.
        val awning = UIBezierPath()
        awning.move(CGPoint(size.width * 0.08, size.height * 0.30))
        awning.addLine(CGPoint(size.width * 0.20, size.height * 0.08))
        awning.addLine(CGPoint(size.width * 0.80, size.height * 0.08))
        awning.addLine(CGPoint(size.width * 0.92, size.height * 0.30))
        awning.close()

        context.saveGState()
        awning.addClip()
        val stripes = 6
        val stripeWidth = size.width * 0.84 / (stripes).toDouble()
        for (index in 0 until stripes) {
            val stripe = CGRect(size.width * 0.08 + stripeWidth * (index).toDouble(),
                                size.height * 0.06,
                                stripeWidth, size.height * 0.26)
            BuildingArtwork.fill(UIBezierPath(stripe), (if (index % 2 == 0) primary else secondary))
        }
        context.restoreGState()
    }
}
