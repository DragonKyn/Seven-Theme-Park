package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin


// The carnival booths.
//
// Every one of them is the same shell — a striped valance, a back board and a
// counter — with a different game painted on the board. That is deliberate:
// a row of booths along a walkway should read as a midway at a glance, and
// what separates one from the next is the game, not the architecture.
//
// Kept out of `BuildingArtwork` because that file is already the longest in
// the project, and a booth is a self-contained piece of drawing.
internal object BuildingArtGameBooths {

    // region The shell every booth shares

    // Draws the booth and hands back the board the game goes on.
    internal fun boothShell(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor): CGRect {
        val body = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.07, size.height * 0.07)

        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(body, body.width * 0.10), primary)
        }

        // Striped valance across the top, scalloped along its lower edge.
        val valance = CGRect(body.minX, body.minY,
                             body.width, body.height * 0.20)
        context.saveGState()
        UIBezierPath(body, body.width * 0.10).addClip()
        val stripes = 7
        for (index in 0 until stripes) {
            val stripe = CGRect(valance.minX + valance.width * (index).toDouble() / (stripes).toDouble(),
                                valance.minY,
                                valance.width / (stripes).toDouble(),
                                valance.height)
            BuildingArtwork.fill(UIBezierPath(stripe),
 (if (index % 2 == 0) secondary else ParkPalette.colour(ParkColour.cream)))
        }
        context.restoreGState()

        val scallops = 7
        val radius = valance.width / (scallops).toDouble() / 2
        for (index in 0 until scallops) {
            val centre = CGPoint(valance.minX + radius * (index * 2 + 1).toDouble(),
                                 valance.maxY)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius, centre.y - radius * 0.7,
                                             radius * 2, radius * 1.4)),
 (if (index % 2 == 0) secondary else ParkPalette.colour(ParkColour.cream)))
        }

        // Back board: the dark face the game is painted on.
        val board = CGRect(body.minX + body.width * 0.10,
                           body.minY + body.height * 0.28,
                           body.width * 0.80,
                           body.height * 0.42)
        BuildingArtwork.fill(UIBezierPath(board, board.height * 0.10),
             ParkPalette.colour(ParkColour.charcoal))
        BuildingArtwork.stroke(UIBezierPath(board, board.height * 0.10),
               accent, max(1, size.width * 0.016))

        // Counter across the front, with a lip so it reads as a surface.
        val counter = CGRect(body.minX + body.width * 0.06,
                             body.maxY - body.height * 0.22,
                             body.width * 0.88,
                             body.height * 0.14)
        BuildingArtwork.fill(UIBezierPath(counter, counter.height * 0.3), accent)
        BuildingArtwork.fill(UIBezierPath(CGRect(counter.minX, counter.minY,
                                       counter.width, counter.height * 0.32)),
             UIColor.white.withAlphaComponent(0.22))

        hangPrizes(size, body)
        return board
    }

    // Plush prizes strung along the top corners. They are what tells a guest
    // walking past that there is something to win here.
    internal fun hangPrizes(size: CGSize, body: CGRect) {
        val colours = listOf(ParkColour.pink, ParkColour.cyan, ParkColour.yellow, ParkColour.lime)
        // The big one hangs in the middle of the run, where everybody walking
        // past looks. That is how a midway sells a game.
        val sizes = listOf(0.09, 0.15, 0.08, 0.11)

        for ((index, x) in listOf(0.08, 0.92, 0.20, 0.80).withIndex()) {
            val side = body.width * sizes[index % sizes.size]
            val centre = CGPoint(body.minX + body.width * (x).toDouble(),
                                 body.minY + body.height * ( (if (index < 2) 0.30 else 0.26)))
            val colour = ParkPalette.colour(colours[index % colours.size])

            val string = UIBezierPath()
            string.move(CGPoint(centre.x, body.minY + body.height * 0.18))
            string.addLine(centre)
            BuildingArtwork.stroke(string, ParkPalette.colour(ParkColour.cream).withAlphaComponent(0.7),
                   max(0.5, size.width * 0.006))

            // Body, head and two ears: enough for a plush at this size.
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - side / 2, centre.y,
                                             side, side * 1.1)), colour)
            val head = side * 0.72
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - head / 2, centre.y - head * 0.62,
                                             head, head)), colour)
            val ear = head * 0.42
            for (dx in listOf(-head * 0.34, head * 0.34)) {
                BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x + dx - ear / 2,
                                                 centre.y - head * 0.78,
                                                 ear, ear)), colour)
            }
        }
    }

    // Somewhere to put the thing the guest picks up: a ball, a mallet, a gun.
    internal fun counterLine(size: CGSize): Double {
        return size.height * 0.78
    }

    // region The games

    internal fun drawBasketballGame(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val board = boothShell(context, size, primary, secondary, accent)

        // Two backboards with a hoop and a net under each.
        for (x in listOf(0.32, 0.68)) {
            val centre = CGPoint(board.minX + board.width * x,
                                 board.minY + board.height * 0.38)
            val backboard = CGRect(centre.x - board.width * 0.13,
                                   centre.y - board.height * 0.26,
                                   board.width * 0.26,
                                   board.height * 0.40)
            BuildingArtwork.fill(UIBezierPath(backboard, backboard.height * 0.12),
                 ParkPalette.colour(ParkColour.cream))
            BuildingArtwork.stroke(UIBezierPath(backboard.insetBy(backboard.width * 0.22,
                                                        backboard.height * 0.24)),
                   ParkPalette.colour(ParkColour.red), max(1, size.width * 0.010))

            val hoop = CGRect(centre.x - board.width * 0.08,
                              backboard.maxY - board.height * 0.03,
                              board.width * 0.16,
                              board.height * 0.09)
            BuildingArtwork.stroke(UIBezierPath(ovalIn =  hoop), ParkPalette.colour(ParkColour.orange),
                   max(1, size.width * 0.014))

            val net = UIBezierPath()
            for (step in 0..3) {
                val top = CGPoint(hoop.minX + hoop.width * (step).toDouble() / 3, hoop.midY)
                net.move(top)
                net.addLine(CGPoint(hoop.midX + (top.x - hoop.midX) * 0.4,
                                        hoop.maxY + board.height * 0.14))
            }
            BuildingArtwork.stroke(net, ParkPalette.colour(ParkColour.cream).withAlphaComponent(0.85),
                   max(0.5, size.width * 0.006))
        }

        // A ball waiting on the counter.
        val ball = size.width * 0.10
        val centre = CGPoint(size.width * 0.50, counterLine(size))
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - ball / 2, centre.y - ball / 2,
                                         ball, ball)),
             ParkPalette.colour(ParkColour.orange))
        val seam = UIBezierPath()
        seam.move(CGPoint(centre.x - ball / 2, centre.y))
        seam.addLine(CGPoint(centre.x + ball / 2, centre.y))
        BuildingArtwork.stroke(seam, ParkPalette.colour(ParkColour.charcoal), max(0.5, size.width * 0.006))
    }

    internal fun drawWaterRaceGame(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val board = boothShell(context, size, primary, secondary, accent)

        // Five lanes, each with a target at the bottom and a runner part way
        // up: the whole point of the game is that they are not level.
        val lanes = 5
        val heights = listOf(0.62, 0.34, 0.78, 0.46, 0.22)
        for (lane in 0 until lanes) {
            val x = board.minX + board.width * (0.14 + 0.18 * (lane).toDouble())

            val rail = UIBezierPath()
            rail.move(CGPoint(x, board.maxY - board.height * 0.12))
            rail.addLine(CGPoint(x, board.minY + board.height * 0.12))
            BuildingArtwork.stroke(rail, ParkPalette.colour(ParkColour.slate), max(1, size.width * 0.008))

            val runner = CGRect(x - board.width * 0.045,
                                board.maxY - board.height * (0.12 + 0.68 * heights[lane]),
                                board.width * 0.09,
                                board.height * 0.13)
            BuildingArtwork.fill(UIBezierPath(runner, runner.height * 0.3),
                 ParkPalette.colour(listOf(ParkColour.red, ParkColour.yellow, ParkColour.lime, ParkColour.cyan, ParkColour.violet)[lane]))

            val target = board.width * 0.07
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(x - target / 2,
                                             board.maxY - board.height * 0.18,
                                             target, target)),
                 ParkPalette.colour(ParkColour.cream))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(x - target * 0.18,
                                             board.maxY - board.height * 0.18 + target * 0.32,
                                             target * 0.36, target * 0.36)),
                 ParkPalette.colour(ParkColour.red))
        }

        // Water guns bolted to the counter, muzzles up at the board.
        for (x in listOf(0.30, 0.50, 0.70)) {
            val foot = CGPoint(size.width * x, counterLine(size))
            val gun = UIBezierPath()
            gun.move(CGPoint(foot.x, foot.y + size.height * 0.02))
            gun.addLine(CGPoint(foot.x, foot.y - size.height * 0.05))
            BuildingArtwork.stroke(gun, ParkPalette.colour(ParkColour.charcoal), max(1, size.width * 0.018))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(foot.x - size.width * 0.016,
                                             foot.y - size.height * 0.07,
                                             size.width * 0.032,
                                             size.height * 0.03)),
                 ParkPalette.colour(ParkColour.cyan))
        }
    }

    internal fun drawBalloonGame(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val board = boothShell(context, size, primary, secondary, accent)

        // A wall of balloons, one row already burst.
        val columns = 6
        val rows = 3
        val palette = listOf(ParkColour.red, ParkColour.yellow, ParkColour.cyan, ParkColour.lime, ParkColour.violet, ParkColour.orange)
        val width = board.width / (columns).toDouble()
        val height = board.height / (rows).toDouble()

        for (row in 0 until rows) {
            for (column in 0 until columns) {
                val centre = CGPoint(board.minX + width * ((column).toDouble() + 0.5),
                                     board.minY + height * ((row).toDouble() + 0.5))
                // One gap, so the wall reads as a game in progress.
                if (row == 1 && column == 3) {
                    BuildingArtwork.stroke(UIBezierPath(ovalIn =  CGRect(centre.x - width * 0.26,
                                                       centre.y - height * 0.26,
                                                       width * 0.52, height * 0.52)),
                           ParkPalette.colour(ParkColour.slate), max(0.5, size.width * 0.005))
                    continue
                }
                val colour = ParkPalette.colour(palette[(row * columns + column) % palette.size])
                BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - width * 0.30,
                                                 centre.y - height * 0.32,
                                                 width * 0.60, height * 0.64)),
                     colour)
            }
        }

        // Darts on the counter, points inward.
        for (x in listOf(0.38, 0.50, 0.62)) {
            val dart = UIBezierPath()
            val foot = CGPoint(size.width * x, counterLine(size))
            dart.move(CGPoint(foot.x, foot.y + size.height * 0.03))
            dart.addLine(CGPoint(foot.x, foot.y - size.height * 0.04))
            BuildingArtwork.stroke(dart, ParkPalette.colour(ParkColour.cream), max(1, size.width * 0.010))
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(foot.x - size.width * 0.012,
                                             foot.y - size.height * 0.055,
                                             size.width * 0.024,
                                             size.height * 0.022)),
                 ParkPalette.colour(ParkColour.red))
        }
    }

    internal fun drawTargetGame(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val board = boothShell(context, size, primary, secondary, accent)

        // Three targets, ringed, on stands.
        for (x in listOf(0.22, 0.50, 0.78)) {
            val centre = CGPoint(board.minX + board.width * x,
                                 board.minY + board.height * 0.42)
            val outer = min(board.width * 0.22, board.height * 0.60)

            val stand = UIBezierPath()
            stand.move(centre)
            stand.addLine(CGPoint(centre.x, board.maxY - board.height * 0.06))
            BuildingArtwork.stroke(stand, ParkPalette.colour(ParkColour.slate), max(1, size.width * 0.010))

            val rings = listOf(Pair(1.0, ParkColour.cream), Pair(0.68, ParkColour.red), Pair(0.34, ParkColour.cream))
            for ((scale, colour) in rings) {
                val side = outer * scale
                BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - side / 2, centre.y - side / 2,
                                                 side, side)),
                     ParkPalette.colour(colour))
            }
            val pip = outer * 0.16
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - pip / 2, centre.y - pip / 2,
                                             pip, pip)),
                 ParkPalette.colour(ParkColour.red))
        }

        // A rifle lying across the counter.
        val rifle = CGRect(size.width * 0.34, counterLine(size) - size.height * 0.012,
                           size.width * 0.32, size.height * 0.024)
        BuildingArtwork.fill(UIBezierPath(rifle, rifle.height / 2),
             ParkPalette.colour(ParkColour.charcoal))
        BuildingArtwork.fill(UIBezierPath(CGRect(rifle.minX, rifle.minY - rifle.height * 0.6,
                                              rifle.width * 0.26,
                                              rifle.height * 2.2),
                          rifle.height * 0.6),
             ParkPalette.colour(ParkColour.brown))
    }

    internal fun drawMoleGame(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val board = boothShell(context, size, primary, secondary, accent)

        // A green field with holes in it. The moles themselves are the moving
        // parts and are drawn over the top of this.
        val field = board.insetBy(board.width * 0.05, board.height * 0.10)
        BuildingArtwork.fill(UIBezierPath(field, field.height * 0.18),
             ParkPalette.colour(ParkColour.green))

        for (x in listOf(0.20, 0.50, 0.80)) {
            for (y in listOf(0.34, 0.72)) {
                val hole = CGRect(field.minX + field.width * x - field.width * 0.09,
                                  field.minY + field.height * y - field.height * 0.09,
                                  field.width * 0.18,
                                  field.height * 0.18)
                BuildingArtwork.fill(UIBezierPath(ovalIn =  hole), ParkPalette.colour(ParkColour.charcoal))
                BuildingArtwork.fill(UIBezierPath(ovalIn =  hole.insetBy(hole.width * 0.14,
                                                       hole.height * 0.14)),
                     UIColor.black.withAlphaComponent(0.55))
            }
        }

        // Mallet on the counter.
        val handle = UIBezierPath()
        handle.move(CGPoint(size.width * 0.42, counterLine(size) + size.height * 0.02))
        handle.addLine(CGPoint(size.width * 0.58, counterLine(size) - size.height * 0.03))
        BuildingArtwork.stroke(handle, ParkPalette.colour(ParkColour.brown), max(1, size.width * 0.014))
        val head = CGRect(size.width * 0.56, counterLine(size) - size.height * 0.055,
                          size.width * 0.09, size.height * 0.045)
        BuildingArtwork.fill(UIBezierPath(head, head.height * 0.3),
             ParkPalette.colour(ParkColour.red))
    }

    internal fun drawStrengthTester(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val board = boothShell(context, size, primary, secondary, accent)

        // A column up the middle of the board, banded from green to red, with
        // a bell on top. The puck that climbs it is the moving part.
        val column = CGRect(board.midX - board.width * 0.07,
                            board.minY + board.height * 0.08,
                            board.width * 0.14,
                            board.height * 0.84)
        BuildingArtwork.fill(UIBezierPath(column, column.width * 0.3),
             ParkPalette.colour(ParkColour.charcoal))

        val bands = listOf(ParkColour.red, ParkColour.orange, ParkColour.amber, ParkColour.lime, ParkColour.green)
        for ((index, colour) in bands.withIndex()) {
            val slice = CGRect(column.minX + column.width * 0.18,
                               column.minY + column.height * (index).toDouble() / (bands.size).toDouble(),
                               column.width * 0.64,
                               column.height / (bands.size).toDouble() * 0.82)
            BuildingArtwork.fill(UIBezierPath(slice, slice.height * 0.2),
                 ParkPalette.colour(colour))
        }

        val bell = min(board.width * 0.16, board.height * 0.28)
        val bellPath = UIBezierPath(CGPoint(column.midX, column.minY),
                                    bell / 2,
                                    PI, 0, true)
        bellPath.close()
        BuildingArtwork.fill(bellPath, ParkPalette.colour(ParkColour.amber))

        // Sledgehammer resting against the counter.
        val shaft = UIBezierPath()
        shaft.move(CGPoint(size.width * 0.26, counterLine(size) + size.height * 0.04))
        shaft.addLine(CGPoint(size.width * 0.34, counterLine(size) - size.height * 0.08))
        BuildingArtwork.stroke(shaft, ParkPalette.colour(ParkColour.brown), max(1, size.width * 0.016))
        val head = CGRect(size.width * 0.30, counterLine(size) - size.height * 0.11,
                          size.width * 0.09, size.height * 0.04)
        BuildingArtwork.fill(UIBezierPath(head, head.height * 0.25),
             ParkPalette.colour(ParkColour.slate))
    }

    internal fun drawRingTossGame(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val board = boothShell(context, size, primary, secondary, accent)

        // Rows of bottles, a couple of them already ringed.
        val columns = 5
        val rows = 2
        for (row in 0 until rows) {
            for (column in 0 until columns) {
                val x = board.minX + board.width * (0.12 + 0.19 * (column).toDouble())
                val base = board.minY + board.height * (0.52 + 0.40 * (row).toDouble())

                val bottle = UIBezierPath()
                val bodyWidth = board.width * 0.075
                bottle.move(CGPoint(x - bodyWidth / 2, base))
                bottle.addLine(CGPoint(x - bodyWidth / 2, base - board.height * 0.20))
                bottle.addLine(CGPoint(x - bodyWidth * 0.18, base - board.height * 0.32))
                bottle.addLine(CGPoint(x + bodyWidth * 0.18, base - board.height * 0.32))
                bottle.addLine(CGPoint(x + bodyWidth / 2, base - board.height * 0.20))
                bottle.addLine(CGPoint(x + bodyWidth / 2, base))
                bottle.close()
                BuildingArtwork.fill(bottle, ParkPalette.colour( (if (row == 0) ParkColour.green else ParkColour.teal)))

                if (!((row + column) % 4 == 1)) continue
                val ring = CGRect(x - bodyWidth * 0.70, base - board.height * 0.24,
                                  bodyWidth * 1.40, board.height * 0.09)
                BuildingArtwork.stroke(UIBezierPath(ovalIn =  ring), ParkPalette.colour(ParkColour.red),
                       max(1, size.width * 0.009))
            }
        }

        // Spare rings stacked on the counter.
        for (x in listOf(0.40, 0.52, 0.64)) {
            val ring = CGRect(size.width * x - size.width * 0.045,
                              counterLine(size) - size.height * 0.016,
                              size.width * 0.09, size.height * 0.032)
            BuildingArtwork.stroke(UIBezierPath(ovalIn =  ring), ParkPalette.colour(ParkColour.yellow),
                   max(1, size.width * 0.010))
        }
    }

    // region Moving parts

    // A mole, drawn from its shoulders up, because that is all a hole shows.
    internal fun drawMole(context: CGContext, size: CGSize, variant: Int) {
        val fur = ParkPalette.colour(ParkColour.brown)
        val body = CGRect(CGPoint.zero, size).insetBy(size.width * 0.08, 0)
        BuildingArtwork.fill(UIBezierPath(body, body.width * 0.44), fur)

        val snout = CGRect(body.midX - body.width * 0.22,
                           body.midY,
                           body.width * 0.44,
                           body.height * 0.30)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  snout), ParkPalette.colour(ParkColour.sand))
        BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(snout.midX - snout.width * 0.12,
                                         snout.midY - snout.height * 0.10,
                                         snout.width * 0.24,
                                         snout.height * 0.24)),
             ParkPalette.colour(ParkColour.charcoal))

        val eye = body.width * 0.13
        for (dx in listOf(-body.width * 0.20, body.width * 0.20)) {
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(body.midX + dx - eye / 2,
                                             body.minY + body.height * 0.24,
                                             eye, eye)),
                 ParkPalette.colour(ParkColour.charcoal))
        }

        // Every third mole wears the hat, so the board is not three of one thing.
        if (!(variant % 3 == 2)) return
        BuildingArtwork.fill(UIBezierPath(CGRect(body.minX, body.minY,
                                              body.width, body.height * 0.18),
                          body.height * 0.08),
             ParkPalette.colour(ParkColour.red))
    }

    // The puck that climbs the strength tester.
    internal fun drawStrikerPuck(context: CGContext, size: CGSize, accent: UIColor) {
        val body = CGRect(CGPoint.zero, size)
        BuildingArtwork.fill(UIBezierPath(body, body.height * 0.4),
             ParkPalette.colour(ParkColour.cream))
        BuildingArtwork.fill(UIBezierPath(body.insetBy(body.width * 0.18,
                                                    body.height * 0.28),
                          body.height * 0.2),
             accent)
    }
}
