package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin


// The crazy golf course.
//
// Drawn as a course rather than as a building: a lawn cut into fairways by
// low kerbs, with a hole and a flag on each, a hazard or two, and a hut at
// the front where the putters are handed out. Nothing else in the park is
// laid out on the ground like this, which is most of what makes it read as
// golf at a glance rather than as another shed.
internal object BuildingArtMiniGolf {

    internal fun drawMiniGolf(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val course = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.05, size.height * 0.05)

        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(course, course.height * 0.07), primary)
        }

        // Mown stripes. Fairways are the one place in the park where a flat
        // green would look wrong.
        val stripes = 7
        for (index in 0 until stripes step 2) {
            val band = CGRect(course.minX,
                              course.minY + course.height * ((index).toDouble() / (stripes).toDouble()),
                              course.width,
                              course.height / (stripes).toDouble())
            BuildingArtwork.fill(UIBezierPath(band), UIColor.white.withAlphaComponent(0.07))
        }

        val kerb = ParkPalette.colour(ParkColour.cream)
        val kerbWidth = max(1, size.width * 0.010)

        // Three fairways of different shapes, divided by low kerbs. Each gets
        // a hole and a flag, so the count of flags is the count of holes.
        val lane = course.width / 3
        for (index in 0 until 3) {
            val fairway = CGRect(course.minX + lane * (index).toDouble(),
                                 course.minY,
                                 lane,
                                 course.height)
                .insetBy(lane * 0.10, course.height * 0.07)

            val outline = UIBezierPath(fairway,
                                       fairway.width * 0.30)
            BuildingArtwork.fill(outline, UIColor.black.withAlphaComponent(0.05))
            BuildingArtwork.stroke(outline, kerb, kerbWidth)

            // A dog-leg across the middle of the fairway, which is what makes
            // it a course rather than three rectangles.
            val bend = UIBezierPath()
            bend.move(CGPoint(fairway.minX + fairway.width * 0.15,
                                  fairway.midY + fairway.height * 0.06))
            bend.addLine(CGPoint(fairway.maxX - fairway.width * 0.15,
                                     fairway.midY - fairway.height * 0.04))
            BuildingArtwork.stroke(bend, kerb.withAlphaComponent(0.75), kerbWidth)

            drawHole(context,
                     CGPoint(fairway.midX, fairway.minY + fairway.height * 0.18),
                     fairway.width * 0.11,
 (if (index == 1) accent else secondary),
                     fairway.height * 0.30)

            // The ball, waiting on the mat at the far end.
            val ball = fairway.width * 0.13
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(fairway.midX - ball / 2,
                                             fairway.maxY - fairway.height * 0.20,
                                             ball, ball)),
                 ParkPalette.colour(ParkColour.white))
        }

        drawWindmill(context,
                     CGPoint(course.minX + course.width * 0.18,
                                     course.minY + course.height * 0.62),
                     course.width * 0.15,
                     secondary,
                     ParkPalette.colour(ParkColour.cream))

        drawPondHazard(context,
                       CGRect(course.maxX - course.width * 0.26,
                                  course.minY + course.height * 0.54,
                                  course.width * 0.17,
                                  course.height * 0.16))

        drawClubhouse(context,
                      CGRect(course.midX - course.width * 0.17,
                                 course.maxY - course.height * 0.15,
                                 course.width * 0.34,
                                 course.height * 0.13),
                      secondary,
                      accent)
    }

    // region Pieces

    // A cup with a flagstick in it. The flag is the tallest thing on the
    // course and the only part visible when the park is zoomed out.
    internal fun drawHole(context: CGContext, centre: CGPoint, radius: Double, flag: UIColor, height: Double) {
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius, centre.y - radius * 0.62,
                                         radius * 2, radius * 1.24)),
             UIColor.black.withAlphaComponent(0.62))

        val stick = UIBezierPath()
        stick.move(centre)
        stick.addLine(CGPoint(centre.x, centre.y - height))
        BuildingArtwork.stroke(stick, ParkPalette.colour(ParkColour.white), max(1, radius * 0.42))

        val pennant = UIBezierPath()
        pennant.move(CGPoint(centre.x, centre.y - height))
        pennant.addLine(CGPoint(centre.x + radius * 1.9, centre.y - height * 0.84))
        pennant.addLine(CGPoint(centre.x, centre.y - height * 0.68))
        pennant.close()
        BuildingArtwork.fill(pennant, flag)
    }

    // The obstacle everybody pictures when they hear crazy golf.
    internal fun drawWindmill(context: CGContext, centre: CGPoint, span: Double, body: UIColor, sails: UIColor) {
        val tower = CGRect(centre.x - span * 0.26, centre.y - span * 0.30,
                           span * 0.52, span * 0.80)
        BuildingArtwork.fill(UIBezierPath(tower, tower.width * 0.22), body)

        val cap = UIBezierPath()
        cap.move(CGPoint(tower.minX - span * 0.08, tower.minY))
        cap.addLine(CGPoint(tower.maxX + span * 0.08, tower.minY))
        cap.addLine(CGPoint(tower.midX, tower.minY - span * 0.26))
        cap.close()
        BuildingArtwork.fill(cap, sails)

        // Four sails, drawn as one cross so the shape survives being small.
        val hub = CGPoint(tower.midX, tower.minY + span * 0.10)
        val arm = span * 0.46
        val blades = UIBezierPath()
        blades.move(CGPoint(hub.x - arm, hub.y - arm * 0.36))
        blades.addLine(CGPoint(hub.x + arm, hub.y + arm * 0.36))
        blades.move(CGPoint(hub.x - arm * 0.36, hub.y + arm))
        blades.addLine(CGPoint(hub.x + arm * 0.36, hub.y - arm))
        BuildingArtwork.stroke(blades, sails, max(1, span * 0.13))
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(hub.x - span * 0.07, hub.y - span * 0.07,
                                         span * 0.14, span * 0.14)),
             ParkPalette.colour(ParkColour.charcoal))
    }

    // A water hazard, which on a course this size is a puddle with a rim.
    internal fun drawPondHazard(context: CGContext, rect: CGRect) {
        val pond = UIBezierPath(ovalIn =  rect)
        BuildingArtwork.fill(pond, ParkPalette.colour(ParkColour.cyan).withAlphaComponent(0.85))
        BuildingArtwork.stroke(pond, ParkPalette.colour(ParkColour.sand), max(1, rect.width * 0.10))

        val glint = UIBezierPath()
        glint.move(CGPoint(rect.minX + rect.width * 0.24, rect.midY))
        glint.addLine(CGPoint(rect.minX + rect.width * 0.52, rect.midY))
        BuildingArtwork.stroke(glint, UIColor.white.withAlphaComponent(0.55), max(0.5, rect.height * 0.10))
    }

    // Where the putters are handed out, at the front so it faces the path.
    internal fun drawClubhouse(context: CGContext, rect: CGRect, body: UIColor, roof: UIColor) {
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(rect, rect.height * 0.25), body)
        }
        val awning = CGRect(rect.minX, rect.minY,
                            rect.width, rect.height * 0.42)
        BuildingArtwork.fill(UIBezierPath(awning, awning.height * 0.4), roof)

        // A rack of putters leaning against the counter.
        val clubs = UIBezierPath()
        for (index in 0 until 3) {
            val x = rect.minX + rect.width * (0.24 + 0.22 * (index).toDouble())
            clubs.move(CGPoint(x, rect.maxY - rect.height * 0.10))
            clubs.addLine(CGPoint(x + rect.width * 0.05, rect.minY + rect.height * 0.50))
        }
        BuildingArtwork.stroke(clubs, ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.7),
               max(0.5, rect.height * 0.08))
    }
}
