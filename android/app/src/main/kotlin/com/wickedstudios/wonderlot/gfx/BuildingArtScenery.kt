package com.wickedstudios.wonderlot.gfx

import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin


// Scenery: the things a park is decorated with rather than the things guests
// queue for.
//
// Most of these are drawn several ways. One catalogue entry called "Shade
// Tree" produces four different trees, so an avenue of them looks planted
// rather than stamped, and the player picks a style or leaves it mixed.
internal object BuildingArtScenery {

    // region Planting

    internal fun drawTree(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        when (variant % 4) {
        1 -> {
            // Tall and narrow, for lining a walkway.
            trunk(size, accent, 0.10, 0.52)
            BuildingArtwork.withShadow(context) {
                BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.22, size.height * 0.06,
                                                 size.width * 0.56,
                                                 size.height * 0.62)), primary)
            }
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.30, size.height * 0.12,
                                             size.width * 0.24,
                                             size.height * 0.30)), secondary)

        }
        2 -> {
            // Three overlapping clumps, which reads as a broad old tree.
            trunk(size, accent, 0.13, 0.60)
            BuildingArtwork.withShadow(context) {
                val clumps = listOf(
                    Triple(0.30, 0.34, 0.42), Triple(0.66, 0.32, 0.38), Triple(0.48, 0.22, 0.46))
                for (clump in clumps) {
                    val side = size.width * clump.third
                    BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * clump.first - side / 2,
                                                     size.height * clump.second - side / 2,
                                                     side, side)), primary)
                }
            }
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.34, size.height * 0.18,
                                             size.width * 0.22,
                                             size.height * 0.22)), secondary)

        }
        3 -> {
            // Flat-topped, like a parasol pine.
            trunk(size, accent, 0.11, 0.44)
            BuildingArtwork.withShadow(context) {
                val canopy = CGRect(size.width * 0.08, size.height * 0.20,
                                    size.width * 0.84, size.height * 0.30)
                BuildingArtwork.fill(UIBezierPath(canopy, canopy.height * 0.5), primary)
            }
            BuildingArtwork.fill(UIBezierPath(CGRect(size.width * 0.18, size.height * 0.24,
                                                  size.width * 0.30,
                                                  size.height * 0.12),
                              size.height * 0.06), secondary)

        }
        else -> {
            trunk(size, accent, 0.12, 0.58)
            BuildingArtwork.withShadow(context) {
                BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.12, size.height * 0.14,
                                                 size.width * 0.76,
                                                 size.height * 0.56)), primary)
            }
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.20, size.height * 0.18,
                                             size.width * 0.34,
                                             size.height * 0.34)), secondary)
        }
        }
    }

    internal fun trunk(size: CGSize, colour: UIColor, width: Double, top: Double) {
        val rect = CGRect(size.width * (0.5 - width / 2), size.height * top,
                          size.width * width, size.height * (0.94 - top))
        BuildingArtwork.fill(UIBezierPath(rect, rect.width * 0.4), colour)
    }

    internal fun drawConifer(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        trunk(size, accent, 0.10, 0.72)

        // How many tiers, and how wide they get: a young fir, a tall one and a
        // squat one from the same drawing.
        val tiers = listOf(
            listOf(Triple(0.10, 0.55, 0.62), Triple(0.32, 0.78, 0.78)),
            listOf(Triple(0.04, 0.36, 0.44), Triple(0.22, 0.58, 0.62), Triple(0.42, 0.80, 0.80)),
            listOf(Triple(0.22, 0.62, 0.74), Triple(0.44, 0.82, 0.92))
        )

        BuildingArtwork.withShadow(context) {
            for (tier in tiers[variant % tiers.size]) {
                val cone = UIBezierPath()
                cone.move(CGPoint(size.width * 0.5, size.height * tier.first))
                cone.addLine(CGPoint(size.width * (0.5 + tier.third / 2), size.height * tier.second))
                cone.addLine(CGPoint(size.width * (0.5 - tier.third / 2), size.height * tier.second))
                cone.close()
                BuildingArtwork.fill(cone, primary)
            }
        }
    }

    internal fun drawFlowerBed(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val bed = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.10, size.height * 0.22)
        val shape = (if (variant % 3 == 1) UIBezierPath(ovalIn =  bed) else UIBezierPath(bed, bed.height * 0.3))
        BuildingArtwork.fill(shape, accent)

        // Scattered, in rows, or a ring round a centrepiece.
        val layouts = listOf(
            listOf(Pair(0.26, 0.36), Pair(0.50, 0.28), Pair(0.74, 0.38), Pair(0.34, 0.62), Pair(0.62, 0.66), Pair(0.50, 0.50)),
            listOf(Pair(0.24, 0.38), Pair(0.44, 0.38), Pair(0.64, 0.38), Pair(0.34, 0.62), Pair(0.54, 0.62), Pair(0.74, 0.62)),
            listOf(Pair(0.50, 0.28), Pair(0.72, 0.42), Pair(0.66, 0.66), Pair(0.34, 0.66), Pair(0.28, 0.42), Pair(0.50, 0.50))
        )

        for ((index, spot) in layouts[variant % layouts.size].withIndex()) {
            val diameter = size.width * ( (if (index == 5 && variant % 3 == 2) 0.22 else 0.17))
            val rect = CGRect(spot.first * size.width - diameter / 2,
                              spot.second * size.height - diameter / 2,
                              diameter, diameter)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  rect), (if (index % 2 == 0) primary else secondary))
        }
    }

    internal fun drawTopiary(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val planter = CGRect(size.width * 0.26, size.height * 0.66,
                             size.width * 0.48, size.height * 0.26)
        BuildingArtwork.fill(UIBezierPath(planter, planter.height * 0.22), accent)

        BuildingArtwork.withShadow(context) {
            when (variant % 3) {
            1 -> {
                // Two balls stacked, clipped into a lollipop.
                for ((y, side) in listOf(Pair(0.46, 0.44), Pair(0.20, 0.34))) {
                    val width = size.width * side
                    BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.5 - width / 2,
                                                     size.height * y - width / 2,
                                                     width, width)), primary)
                }
            }
            2 -> {
                // A cone, clipped to a point.
                val cone = UIBezierPath()
                cone.move(CGPoint(size.width * 0.5, size.height * 0.08))
                cone.addLine(CGPoint(size.width * 0.80, size.height * 0.70))
                cone.addLine(CGPoint(size.width * 0.20, size.height * 0.70))
                cone.close()
                BuildingArtwork.fill(cone, primary)
            }
            else -> {
                val bush = CGRect(size.width * 0.16, size.height * 0.14,
                                  size.width * 0.68, size.height * 0.58)
                BuildingArtwork.fill(UIBezierPath(bush, bush.width * 0.34), primary)
            }
            }
        }

        val sheen = CGRect(size.width * 0.26, size.height * 0.22,
                           size.width * 0.26, size.height * 0.22)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  sheen), secondary)
    }

    internal fun drawHedge(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val hedge = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.04, size.height * 0.24)

        BuildingArtwork.withShadow(context) {
            when (variant % 3) {
            1 -> {
                // Clipped square, the formal cut.
                BuildingArtwork.fill(UIBezierPath(hedge, size.width * 0.06), primary)
            }
            2 -> {
                // Scalloped along the top, which reads as an untrimmed run.
                val path = UIBezierPath(hedge, size.width * 0.10)
                BuildingArtwork.fill(path, primary)
                val bumps = 3
                for (index in 0 until bumps) {
                    val side = size.width / (bumps).toDouble()
                    BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(side * (index).toDouble() + side * 0.08,
                                                     hedge.minY - side * 0.22,
                                                     side * 0.84, side * 0.60)),
                         primary)
                }
            }
            else -> {
                BuildingArtwork.fill(UIBezierPath(hedge, hedge.height * 0.34), primary)
            }
            }
        }

        // A lighter band along the top, so the run has a lit face.
        BuildingArtwork.fill(UIBezierPath(CGRect(hedge.minX + hedge.width * 0.06,
                                              hedge.minY + hedge.height * 0.10,
                                              hedge.width * 0.88,
                                              hedge.height * 0.22),
                          hedge.height * 0.12), secondary)
    }

    // region Furniture

    internal fun drawLamp(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val base = CGRect(size.width * 0.34, size.height * 0.80,
                          size.width * 0.32, size.height * 0.12)
        BuildingArtwork.fill(UIBezierPath(base, base.height * 0.4), accent)

        val post = CGRect(size.width * 0.45, size.height * 0.30,
                          size.width * 0.10, size.height * 0.54)
        BuildingArtwork.fill(UIBezierPath(post), accent)

        BuildingArtwork.withShadow(context) {
            if (variant % 2 == 1) {
                // A lantern: four panes in a frame, the old-fashioned cut.
                val lantern = CGRect(size.width * 0.32, size.height * 0.10,
                                     size.width * 0.36, size.height * 0.28)
                BuildingArtwork.fill(UIBezierPath(lantern, size.width * 0.05), primary)
                val cap = UIBezierPath()
                cap.move(CGPoint(size.width * 0.5, size.height * 0.02))
                cap.addLine(CGPoint(lantern.maxX, lantern.minY))
                cap.addLine(CGPoint(lantern.minX, lantern.minY))
                cap.close()
                BuildingArtwork.fill(cap, accent)
            } else {
                val head = CGRect(size.width * 0.30, size.height * 0.12,
                                  size.width * 0.40, size.height * 0.26)
                BuildingArtwork.fill(UIBezierPath(ovalIn =  head), primary)
            }
        }

        val glow = CGRect(size.width * 0.38, size.height * 0.18,
                          size.width * 0.24, size.height * 0.14)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  glow), secondary)
    }

    internal fun drawPicnicTable(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        // Two benches with the table between them, seen from above.
        for (y in listOf(0.20, 0.66)) {
            val bench = CGRect(size.width * 0.12, size.height * y,
                               size.width * 0.76, size.height * 0.14)
            BuildingArtwork.fill(UIBezierPath(bench, bench.height * 0.4), accent)
        }

        BuildingArtwork.withShadow(context) {
            val table = CGRect(size.width * 0.18, size.height * 0.36,
                               size.width * 0.64, size.height * 0.28)
            BuildingArtwork.fill(UIBezierPath(table, size.width * 0.05), primary)
        }

        if (variant % 2 == 1) {
            // With a parasol through the middle of it.
            val shade = min(size.width, size.height) * 0.46
            val centre = CGPoint(size.width * 0.5, size.height * 0.5)
            BuildingArtwork.withShadow(context) {
                BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - shade / 2, centre.y - shade / 2,
                                                 shade, shade)), secondary)
            }
            // Panels, so it reads as a parasol rather than a plate.
            for (index in 0 until 4) {
                val wedge = UIBezierPath()
                val from = (index).toDouble() * PI / 2
                wedge.move(centre)
                wedge.addArc(centre, shade / 2,
                             from, from + PI / 4, true)
                wedge.close()
                BuildingArtwork.fill(wedge, primary)
            }
            val pole = min(size.width, size.height) * 0.10
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(centre.x - pole / 2, centre.y - pole / 2,
                                             pole, pole)), accent)
        } else {
            // Or with the grain of the boards showing.
            for (index in 0 until 3) {
                val line = CGRect(size.width * 0.20,
                                  size.height * (0.40 + 0.08 * (index).toDouble()),
                                  size.width * 0.60,
                                  max(1, size.height * 0.02))
                BuildingArtwork.fill(UIBezierPath(line), secondary.withAlphaComponent(0.55))
            }
        }
    }

    internal fun drawFlagPole(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val base = CGRect(size.width * 0.36, size.height * 0.78,
                          size.width * 0.28, size.height * 0.16)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(ovalIn =  base), accent)
        }

        val pole = CGRect(size.width * 0.47, size.height * 0.08,
                          size.width * 0.06, size.height * 0.76)
        BuildingArtwork.fill(UIBezierPath(pole, pole.width * 0.5), accent)

        val flag = UIBezierPath()
        val top = size.height * 0.12
        when (variant % 3) {
        1 -> {
            // Swallowtail.
            flag.move(CGPoint(pole.maxX, top))
            flag.addLine(CGPoint(size.width * 0.94, top + size.height * 0.06))
            flag.addLine(CGPoint(size.width * 0.78, top + size.height * 0.13))
            flag.addLine(CGPoint(size.width * 0.94, top + size.height * 0.20))
            flag.addLine(CGPoint(pole.maxX, top + size.height * 0.26))
        }
        2 -> {
            // A long pennant, tapering to a point.
            flag.move(CGPoint(pole.maxX, top))
            flag.addLine(CGPoint(size.width * 0.96, top + size.height * 0.09))
            flag.addLine(CGPoint(pole.maxX, top + size.height * 0.18))
        }
        else -> {
            // A plain rectangle, rippling along its free edge.
            flag.move(CGPoint(pole.maxX, top))
            flag.addLine(CGPoint(size.width * 0.90, top))
            flag.addQuadCurve(CGPoint(size.width * 0.90, top + size.height * 0.24),
                              CGPoint(size.width * 0.78,
                                                    top + size.height * 0.12))
            flag.addLine(CGPoint(pole.maxX, top + size.height * 0.24))
        }
        }
        flag.close()
        BuildingArtwork.withShadow(context) { BuildingArtwork.fill(flag, primary) }

        // A band across the flag, in the park's trim.
        val band = CGRect(pole.maxX, top + size.height * 0.10,
                          size.width * 0.30, max(1, size.height * 0.04))
        BuildingArtwork.fill(UIBezierPath(band), secondary)
    }

    internal fun drawGardenArch(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val thickness = max(2, size.width * 0.09)

        val arch = UIBezierPath()
        arch.move(CGPoint(size.width * 0.16, size.height * 0.90))
        arch.addLine(CGPoint(size.width * 0.16, size.height * 0.46))
        arch.addQuadCurve(CGPoint(size.width * 0.84, size.height * 0.46),
                          CGPoint(size.width * 0.50, size.height * 0.02))
        arch.addLine(CGPoint(size.width * 0.84, size.height * 0.90))
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.stroke(arch, primary, thickness)
        }

        if (variant % 2 == 1) {
            // Trained with climbing flowers up both legs.
            for (x in listOf(0.16, 0.84)) {
                for (index in 0 until 3) {
                    val dot = size.width * 0.11
                    BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * x - dot / 2,
                                                     size.height * (0.52 + 0.13 * (index).toDouble()),
                                                     dot, dot)), secondary)
                }
            }
            val crown = size.width * 0.14
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.5 - crown / 2,
                                             size.height * 0.14,
                                             crown, crown)), secondary)
        } else {
            // Or with cross-bracing between the legs.
            for (index in 0 until 2) {
                val rung = UIBezierPath()
                val y = size.height * (0.58 + 0.16 * (index).toDouble())
                rung.move(CGPoint(size.width * 0.16, y))
                rung.addLine(CGPoint(size.width * 0.84, y))
                BuildingArtwork.stroke(rung, secondary, max(1, thickness * 0.45))
            }
        }
    }

    internal fun drawClockTower(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val shaft = CGRect(size.width * 0.28, size.height * 0.26,
                           size.width * 0.44, size.height * 0.66)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(shaft, size.width * 0.04), primary)
        }

        // Roof: a spire or a dome.
        if (variant % 2 == 1) {
            val dome = CGRect(size.width * 0.24, size.height * 0.06,
                              size.width * 0.52, size.height * 0.30)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  dome), accent)
        } else {
            val spire = UIBezierPath()
            spire.move(CGPoint(size.width * 0.50, size.height * 0.02))
            spire.addLine(CGPoint(size.width * 0.78, size.height * 0.28))
            spire.addLine(CGPoint(size.width * 0.22, size.height * 0.28))
            spire.close()
            BuildingArtwork.fill(spire, accent)
        }

        // The face, with hands at ten past ten because that is how every
        // clock in every advertisement is set.
        val face = CGRect(size.width * 0.34, size.height * 0.36,
                          size.width * 0.32, size.height * 0.32)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  face), ParkPalette.colour(ParkColour.cream))
        BuildingArtwork.stroke(UIBezierPath(ovalIn =  face), secondary, max(1, size.width * 0.025))

        val hands = UIBezierPath()
        hands.move(CGPoint(face.midX, face.midY))
        hands.addLine(CGPoint(face.midX - face.width * 0.26, face.midY - face.height * 0.20))
        hands.move(CGPoint(face.midX, face.midY))
        hands.addLine(CGPoint(face.midX + face.width * 0.22, face.midY - face.height * 0.30))
        BuildingArtwork.stroke(hands, ParkPalette.colour(ParkColour.charcoal), max(1, size.width * 0.022))

        // Base course, so the tower sits on something.
        val base = CGRect(size.width * 0.20, size.height * 0.84,
                          size.width * 0.60, size.height * 0.12)
        BuildingArtwork.fill(UIBezierPath(base, size.width * 0.03), secondary)
    }

    internal fun drawStatue(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val plinth = CGRect(size.width * 0.22, size.height * 0.64,
                            size.width * 0.56, size.height * 0.28)
        BuildingArtwork.withShadow(context) {
            BuildingArtwork.fill(UIBezierPath(plinth, plinth.height * 0.16), accent)
        }

        when (variant % 3) {
        1 -> {
            // An urn rather than a figure.
            val urn = UIBezierPath()
            urn.move(CGPoint(size.width * 0.36, size.height * 0.62))
            urn.addQuadCurve(CGPoint(size.width * 0.36, size.height * 0.26),
                             CGPoint(size.width * 0.22, size.height * 0.44))
            urn.addLine(CGPoint(size.width * 0.64, size.height * 0.26))
            urn.addQuadCurve(CGPoint(size.width * 0.64, size.height * 0.62),
                             CGPoint(size.width * 0.78, size.height * 0.44))
            urn.close()
            BuildingArtwork.fill(urn, primary)
            BuildingArtwork.fill(UIBezierPath(CGRect(size.width * 0.30, size.height * 0.20,
                                                  size.width * 0.40,
                                                  size.height * 0.08),
                              size.height * 0.04), secondary)

        }
        2 -> {
            // A rearing horse, which at this size is a body and a neck.
            val body = CGRect(size.width * 0.30, size.height * 0.38,
                              size.width * 0.40, size.height * 0.26)
            BuildingArtwork.fill(UIBezierPath(body, body.height * 0.4), primary)
            val neck = UIBezierPath()
            neck.move(CGPoint(size.width * 0.58, size.height * 0.46))
            neck.addLine(CGPoint(size.width * 0.72, size.height * 0.16))
            neck.addLine(CGPoint(size.width * 0.58, size.height * 0.14))
            neck.addLine(CGPoint(size.width * 0.46, size.height * 0.42))
            neck.close()
            BuildingArtwork.fill(neck, primary)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.60, size.height * 0.10,
                                             size.width * 0.18,
                                             size.height * 0.12)), secondary)

        }
        else -> {
            val torso = CGRect(size.width * 0.38, size.height * 0.28,
                               size.width * 0.24, size.height * 0.40)
            BuildingArtwork.fill(UIBezierPath(torso, torso.width * 0.4), primary)

            val head = CGRect(size.width * 0.41, size.height * 0.14,
                              size.width * 0.18, size.height * 0.18)
            BuildingArtwork.fill(UIBezierPath(ovalIn =  head), primary)

            val sash = CGRect(torso.minX, torso.minY + torso.height * 0.30,
                              torso.width, max(1, size.height * 0.04))
            BuildingArtwork.fill(UIBezierPath(sash), secondary)
        }
        }
    }

    // region Water

    internal fun drawFountainBasin(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor, variant: Int) {
        val basin = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.08, size.height * 0.08)

        BuildingArtwork.withShadow(context) {
            if (variant % 2 == 1) {
                // Square basin, for a formal garden.
                BuildingArtwork.fill(UIBezierPath(basin, size.width * 0.06), accent)
            } else {
                BuildingArtwork.fill(UIBezierPath(ovalIn =  basin), accent)
            }
        }

        val water = basin.insetBy(basin.width * 0.14, basin.height * 0.14)
        val waterPath = (if (variant % 2 == 1) UIBezierPath(water, size.width * 0.04) else UIBezierPath(ovalIn =  water))
        BuildingArtwork.fill(waterPath, ParkPalette.water)

        val inner = water.insetBy(water.width * 0.26, water.height * 0.26)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  inner), secondary)
    }

    // The water, drawn separately so it can pulse.
    internal fun drawFountainJet(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val column = CGRect(size.width * 0.38, size.height * 0.18,
                            size.width * 0.24, size.height * 0.72)
        BuildingArtwork.fill(UIBezierPath(column, column.width / 2),
             ParkPalette.colour(ParkColour.white).withAlphaComponent(0.85))

        val crown = CGRect(size.width * 0.20, 0,
                           size.width * 0.60, size.height * 0.30)
        BuildingArtwork.fill(UIBezierPath(ovalIn =  crown),
             ParkPalette.colour(ParkColour.white).withAlphaComponent(0.70))
    }
}
