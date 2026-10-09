package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.BuildingMotif
import com.wickedstudios.wonderlot.BuildingMotion
import com.wickedstudios.wonderlot.ParkColour
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

/**
 * Draws the per-motif building artwork. Every shape is generated with paths
 * and cached as a bitmap, so the project stays free of image assets. Each
 * motif produces two textures: the static body, and optionally the part that
 * moves.
 */
object BuildingArtwork {

    private val previewCache = HashMap<String, Bitmap>()

    /** The building itself, without whatever moves on top of it. */
    fun bodyTexture(appearance: BuildingAppearance, size: CGSize): Bitmap =
        SpriteFactory.texture(key(appearance, "body", size), size) { context, drawSize ->
            drawBody(appearance, context, drawSize)
        }

    /** The same artwork as a plain image, for the build menu. */
    fun previewImage(appearance: BuildingAppearance, size: CGSize): Bitmap {
        val cacheKey = key(appearance, "preview", size)
        previewCache[cacheKey]?.let { return it }
        val image = SpriteFactory.render(size) { context, drawSize -> drawBody(appearance, context, drawSize) }
        previewCache[cacheKey] = image
        return image
    }

    private fun key(appearance: BuildingAppearance, prefix: String, size: CGSize): String =
        "$prefix-${appearance.motif.name}-${appearance.primary.name}-${appearance.secondary.name}" +
            "-${appearance.accent.name}-v${appearance.variant}-${size.width.toInt()}x${size.height.toInt()}"

    /** Shared by the map texture and the menu preview, so the two can never show different artwork. */
    internal fun drawBody(appearance: BuildingAppearance, context: CGContext, size: CGSize) {
        val primary = ParkPalette.colour(appearance.primary)
        val secondary = ParkPalette.colour(appearance.secondary)
        val accent = ParkPalette.colour(appearance.accent)
        val variant = appearance.variant

        when (appearance.motif) {
        BuildingMotif.carousel -> {
            drawCarouselBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.swingBoat -> {
            drawSwingBoatBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.dropTower -> {
            drawDropTowerBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.coaster -> {
            drawCoasterBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.megaCoaster -> {
            drawMegaCoasterBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.ferrisWheel -> {
            drawFerrisWheelBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.teacups -> {
            drawTeacupsBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.bumperCars -> {
            drawBumperCarsBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.hauntedHouse -> {
            drawHauntedHouse(context, size, primary, secondary, accent)
        }
        BuildingMotif.goKarts -> {
            drawGoKartsBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.logFlume -> {
            drawLogFlumeBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.slingshot -> {
            drawSlingshotBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.carpetSlide -> {
            drawCarpetSlideBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.trainStation -> {
            drawTrainStation(context, size, primary, secondary, accent)
        }
        BuildingMotif.bumperBoats -> {
            drawBumperBoatsBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.fishingBoats -> {
            drawFishingBoatsBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.wavePool -> {
            drawWavePoolBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.skyGliders -> {
            drawSkyGlidersBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.swingChairs -> {
            BuildingArtStructures.drawSwingChairsBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.pendulumArm -> {
            BuildingArtStructures.drawPendulumArmBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.zipLine -> {
            BuildingArtStructures.drawZipLineBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.riverRapids -> {
            BuildingArtWaterCircuits.drawRiverRapidsBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.lanternCruise -> {
            BuildingArtWaterCircuits.drawLanternCruiseBase(context, size, primary, secondary, accent)
        }
        BuildingMotif.mirrorMaze -> {
            drawMirrorMaze(context, size, primary, secondary, accent)
        }
        BuildingMotif.miniGolf -> {
            BuildingArtMiniGolf.drawMiniGolf(context, size, primary, secondary, accent)
        }
        BuildingMotif.coasterStation -> {
            drawCoasterStation(context, size, primary, secondary, accent)
        }
        BuildingMotif.stall -> {
            drawStall(context, size, primary, secondary, accent)
        }
        BuildingMotif.kiosk -> {
            drawKiosk(context, size, primary, secondary, accent)
        }
        BuildingMotif.basketballGame -> {
            BuildingArtGameBooths.drawBasketballGame(context, size, primary, secondary, accent)
        }
        BuildingMotif.waterRaceGame -> {
            BuildingArtGameBooths.drawWaterRaceGame(context, size, primary, secondary, accent)
        }
        BuildingMotif.balloonGame -> {
            BuildingArtGameBooths.drawBalloonGame(context, size, primary, secondary, accent)
        }
        BuildingMotif.targetGame -> {
            BuildingArtGameBooths.drawTargetGame(context, size, primary, secondary, accent)
        }
        BuildingMotif.moleGame -> {
            BuildingArtGameBooths.drawMoleGame(context, size, primary, secondary, accent)
        }
        BuildingMotif.strengthTester -> {
            BuildingArtGameBooths.drawStrengthTester(context, size, primary, secondary, accent)
        }
        BuildingMotif.ringTossGame -> {
            BuildingArtGameBooths.drawRingTossGame(context, size, primary, secondary, accent)
        }
        BuildingMotif.burgerStall -> {
            drawBurgerStall(context, size, primary, secondary, accent)
        }
        BuildingMotif.pizzaStall -> {
            drawPizzaStall(context, size, primary, secondary, accent)
        }
        BuildingMotif.drinkKiosk -> {
            drawDrinkKiosk(context, size, primary, secondary, accent)
        }
        BuildingMotif.iceCreamStall -> {
            drawIceCreamStall(context, size, primary, secondary, accent)
        }
        BuildingMotif.souvenirShop -> {
            drawSouvenirShop(context, size, primary, secondary, accent)
        }
        BuildingMotif.shopFront -> {
            drawShopFront(context, size, primary, secondary, accent)
        }
        BuildingMotif.restroom -> {
            drawRestroom(context, size, primary, secondary, accent)
        }
        BuildingMotif.bench -> {
            drawBench(context, size, primary, secondary, accent)
        }
        BuildingMotif.bin -> {
            drawBin(context, size, primary, secondary, accent)
        }
        BuildingMotif.tree -> {
            BuildingArtScenery.drawTree(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.conifer -> {
            BuildingArtScenery.drawConifer(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.flowerBed -> {
            BuildingArtScenery.drawFlowerBed(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.fountain -> {
            BuildingArtScenery.drawFountainBasin(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.lamp -> {
            BuildingArtScenery.drawLamp(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.topiary -> {
            BuildingArtScenery.drawTopiary(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.statue -> {
            BuildingArtScenery.drawStatue(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.lilyPads -> {
            BuildingArtWaterScenery.drawLilyPads(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.reeds -> {
            BuildingArtWaterScenery.drawReeds(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.waterRock -> {
            BuildingArtWaterScenery.drawWaterRock(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.luxuryRestroom -> {
            BuildingArtAmenities.drawLuxuryRestroom(context, size, primary, secondary, accent)
        }
        BuildingMotif.popcornCart -> {
            BuildingArtAmenities.drawPopcornCart(context, size, primary, secondary, accent)
        }
        BuildingMotif.floatingLanterns -> {
            BuildingArtWaterScenery.drawFloatingLanterns(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.pondFountain -> {
            BuildingArtWaterScenery.drawPondFountainBasin(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.hedge -> {
            BuildingArtScenery.drawHedge(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.picnicTable -> {
            BuildingArtScenery.drawPicnicTable(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.flagPole -> {
            BuildingArtScenery.drawFlagPole(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.gardenArch -> {
            BuildingArtScenery.drawGardenArch(context, size, primary, secondary, accent, variant)
        }
        BuildingMotif.clockTower -> {
            BuildingArtScenery.drawClockTower(context, size, primary, secondary, accent, variant)
        }
        }
    }

    // The moving part, drawn in its own texture so it can be animated
    // independently. Nil for anything that does not move.
    // How many moving parts a motif has. A track with one vehicle on it is a
    // test track; a bumper car arena with one car in it has nothing to bump.
    internal fun motionPartCount(motif: BuildingMotif): Int {
        when (motif) {
        BuildingMotif.goKarts -> {
            return 4
        }
        BuildingMotif.bumperCars -> {
            return 5
        // A coaster train is a string of cars. One car going round on its own
        // is a maintenance vehicle.
        }
        BuildingMotif.megaCoaster -> {
            return 4
        }
        BuildingMotif.coaster -> {
            return 3
        // Two logs on the circuit, so there is always one on the drop or
        // climbing towards it.
        }
        BuildingMotif.logFlume -> {
            return 2
        }
        BuildingMotif.bumperBoats -> {
            return 4
        }
        BuildingMotif.fishingBoats -> {
            return 3
        }
        BuildingMotif.wavePool -> {
            return 2
        }
        BuildingMotif.skyGliders -> {
            return 5
        // Six chairs on the ring. Fewer than that and the gaps between them
        // are wider than the chairs.
        }
        BuildingMotif.swingChairs -> {
            return 6
        // Three rafts on the river, so one is always in the rough water.
        }
        BuildingMotif.riverRapids -> {
            return 3
        }
        BuildingMotif.lanternCruise -> {
            return 3
        // Two riders on the cable, one waiting their turn at the top.
        }
        BuildingMotif.zipLine -> {
            return 2
        // Four lanes, four mats. One mat on a four-lane slide looks like the
        // other three are shut.
        }
        BuildingMotif.carpetSlide -> {
            return 4
        // Three holes on the board, so one is always up.
        }
        BuildingMotif.moleGame -> {
            return 3
        }
        else -> {
            return 1
        }
        }
    }

    //  picks between vehicles where a motif has several, so no two
    // karts in a race are the same colour.
    internal fun motionTexture(appearance: BuildingAppearance, size: CGSize, variant: Int = 0): Bitmap? {
        if (!(appearance.motif.motion != BuildingMotion.none)) return null
        val partSize = motionPartSize(appearance.motif, size)
        val key = "motion-${appearance.motif.name}-${appearance.primary.name}" +
            "-${appearance.secondary.name}-${appearance.accent.name}" +
            "-${variant}-${(partSize.width).toInt()}x${(partSize.height).toInt()}"

        return SpriteFactory.texture(key, partSize) { context, size ->
            val primary = ParkPalette.colour(appearance.primary)
            val secondary = ParkPalette.colour(appearance.secondary)
            val accent = ParkPalette.colour(appearance.accent)

            when (appearance.motif) {
            BuildingMotif.carousel -> {
                drawCanopy(context, size, primary, secondary, accent)
            }
            BuildingMotif.swingBoat -> {
                drawBoat(context, size, primary, secondary, accent)
            }
            BuildingMotif.dropTower -> {
                drawTowerCar(context, size, primary, secondary, accent)
            }
            BuildingMotif.coaster, BuildingMotif.megaCoaster -> {
                drawCoasterCar(context, size, primary, variant)
            }
            BuildingMotif.ferrisWheel -> {
                drawWheel(context, size, primary, secondary, accent)
            }
            BuildingMotif.teacups -> {
                drawCups(context, size, primary, secondary, accent)
            }
            BuildingMotif.goKarts -> {
                drawKart(context, size, variant)
            }
            BuildingMotif.bumperCars -> {
                drawBumperCar(context, size, variant)
            }
            BuildingMotif.logFlume -> {
                drawLog(context, size, primary, secondary, accent)
            }
            BuildingMotif.bumperBoats -> {
                drawBumperBoat(context, size, variant)
            }
            BuildingMotif.fishingBoats -> {
                drawRowBoat(context, size, variant)
            }
            BuildingMotif.wavePool -> {
                drawSurfer(context, size, variant)
            }
            BuildingMotif.skyGliders -> {
                drawGliderChair(context, size, variant)
            }
            BuildingMotif.swingChairs -> {
                BuildingArtStructures.drawSwingChair(context, size, primary, secondary, accent)
            }
            BuildingMotif.pendulumArm -> {
                BuildingArtStructures.drawPendulumGondola(context, size, primary, secondary, accent)
            }
            BuildingMotif.riverRapids -> {
                BuildingArtWaterCircuits.drawRaft(context, size, variant)
            }
            BuildingMotif.lanternCruise -> {
                BuildingArtWaterCircuits.drawCanalBoat(context, size, primary, secondary, accent)
            }
            BuildingMotif.zipLine -> {
                BuildingArtStructures.drawZipRider(context, size, variant)
            }
            BuildingMotif.slingshot -> {
                drawCapsule(context, size, primary, secondary, accent)
            }
            BuildingMotif.carpetSlide -> {
                drawMat(context, size, primary, secondary, accent)
            }
            BuildingMotif.hauntedHouse -> {
                drawGhost(context, size, primary, secondary, accent)
            }
            BuildingMotif.fountain, BuildingMotif.pondFountain -> {
                BuildingArtScenery.drawFountainJet(context, size, primary, secondary, accent)
            }
            BuildingMotif.moleGame -> {
                BuildingArtGameBooths.drawMole(context, size, variant)
            }
            BuildingMotif.strengthTester -> {
                BuildingArtGameBooths.drawStrikerPuck(context, size, accent)
            }
            else -> {}
            }
        }
    }

    // Size of the moving part relative to the building it sits on.
    internal fun motionPartSize(motif: BuildingMotif, buildingSize: CGSize): CGSize {
        val shortest = min(buildingSize.width, buildingSize.height)
        when (motif) {
        BuildingMotif.carousel -> {
            return CGSize(shortest * 0.78, shortest * 0.78)
        }
        BuildingMotif.swingBoat -> {
            return CGSize(buildingSize.width * 0.46, buildingSize.height * 0.52)
        }
        BuildingMotif.dropTower -> {
            return CGSize(shortest * 0.30, shortest * 0.18)
        }
        BuildingMotif.coaster -> {
            return CGSize(shortest * 0.19, shortest * 0.12)
        }
        BuildingMotif.megaCoaster -> {
            // Measured against the building rather than its shorter side: a
            // nine-by-six coaster is wide, and a car scaled off the short side
            // ends up the size of the station.
            return CGSize(buildingSize.width * 0.075,
                          buildingSize.height * 0.055)
        }
        BuildingMotif.ferrisWheel -> {
            return CGSize(shortest * 0.82, shortest * 0.82)
        }
        BuildingMotif.teacups -> {
            return CGSize(shortest * 0.62, shortest * 0.62)
        }
        BuildingMotif.goKarts -> {
            return CGSize(shortest * 0.21, shortest * 0.13)
        }
        BuildingMotif.bumperCars -> {
            return CGSize(shortest * 0.22, shortest * 0.18)
        }
        BuildingMotif.logFlume -> {
            return CGSize(buildingSize.width * 0.115,
                          buildingSize.height * 0.085)
        }
        BuildingMotif.bumperBoats -> {
            return CGSize(shortest * 0.22, shortest * 0.20)
        }
        BuildingMotif.fishingBoats -> {
            return CGSize(shortest * 0.24, shortest * 0.16)
        }
        BuildingMotif.wavePool -> {
            return CGSize(shortest * 0.26, shortest * 0.15)
        }
        BuildingMotif.skyGliders -> {
            return CGSize(shortest * 0.13, shortest * 0.20)
        }
        BuildingMotif.swingChairs -> {
            return CGSize(shortest * 0.16, shortest * 0.22)
        }
        BuildingMotif.pendulumArm -> {
            // The whole arm, pivot to gondola, so it can be hung from the top
            // of the towers and swung about that point.
            return CGSize(shortest * 0.22, shortest * 0.62)
        }
        BuildingMotif.riverRapids -> {
            // A raft has to sit in the channel it is drawn in, so it is
            // measured off the same short side the channel widths are.
            return CGSize(shortest * 0.12, shortest * 0.12)
        }
        BuildingMotif.lanternCruise -> {
            return CGSize(buildingSize.width * 0.13,
                          buildingSize.height * 0.09)
        }
        BuildingMotif.zipLine -> {
            return CGSize(buildingSize.width * 0.075,
                          buildingSize.height * 0.34)
        }
        BuildingMotif.slingshot -> {
            return CGSize(shortest * 0.26, shortest * 0.26)
        }
        BuildingMotif.carpetSlide -> {
            return CGSize(buildingSize.width * 0.16, buildingSize.height * 0.12)
        }
        BuildingMotif.hauntedHouse -> {
            return CGSize(shortest * 0.20, shortest * 0.26)
        }
        BuildingMotif.fountain, BuildingMotif.pondFountain -> {
            return CGSize(shortest * 0.30, shortest * 0.42)
        }
        BuildingMotif.moleGame -> {
            return CGSize(shortest * 0.15, shortest * 0.17)
        }
        BuildingMotif.strengthTester -> {
            return CGSize(shortest * 0.16, shortest * 0.09)
        }
        else -> {
            return CGSize.zero
        }
        }
    }

    // region Shared drawing helpers

    internal fun fill(path: UIBezierPath, colour: UIColor) {
        colour.setFill()
        path.fill()
    }

    internal fun stroke(path: UIBezierPath, colour: UIColor, width: Double) {
        colour.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    // A soft drop shadow so buildings sit above the grass rather than on it.
    internal fun withShadow(context: CGContext, body: () -> Unit) {
        context.saveGState()
        context.setShadow(CGSize(0, 2),
                          4,
                          UIColor.black.withAlphaComponent(0.28))
        body()
        context.restoreGState()
    }

    // region Rides

    internal fun drawCarouselBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val inset = min(size.width, size.height) * 0.08
        val platform = CGRect(CGPoint.zero, size).insetBy(inset, inset)

        withShadow(context) {
            fill(UIBezierPath(ovalIn =  platform), secondary)
        }
        stroke(UIBezierPath(ovalIn =  platform), accent, max(1, size.width * 0.02))

        // Horses read as spokes at this size; a ring of dots is clearer.
        val radius = platform.width * 0.34
        val centre = CGPoint(platform.midX, platform.midY)
        for (index in 0 until 8) {
            val angle = (index).toDouble() / 8 * PI * 2
            val dot = CGSize(platform.width * 0.10, platform.width * 0.10)
            val point = CGPoint(centre.x + cos(angle) * radius - dot.width / 2,
                                centre.y + sin(angle) * radius - dot.height / 2)
            fill(UIBezierPath(ovalIn =  CGRect(point, dot)), primary)
        }
    }

    // The striped conical roof. Drawn square so it can spin about its centre.
    internal fun drawCanopy(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val circle = CGRect(CGPoint.zero, size).insetBy(1, 1)
        val centre = CGPoint(circle.midX, circle.midY)
        val radius = circle.width / 2

        context.saveGState()
        UIBezierPath(ovalIn =  circle).addClip()

        val segments = 12
        for (index in 0 until segments) {
            val start = (index).toDouble() / (segments).toDouble() * PI * 2
            val end = (index + 1).toDouble() / (segments).toDouble() * PI * 2
            val wedge = UIBezierPath()
            wedge.move(centre)
            wedge.addArc(centre, radius,
                         start, end, true)
            wedge.close()
            fill(wedge, (if (index % 2 == 0) primary else ParkPalette.colour(ParkColour.cream)))
        }
        context.restoreGState()

        // Centre pole cap.
        val cap = CGRect(centre.x - radius * 0.16, centre.y - radius * 0.16,
                         radius * 0.32, radius * 0.32)
        fill(UIBezierPath(ovalIn =  cap), accent)
    }

    internal fun drawSwingBoatBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Ground pad.
        val pad = CGRect(size.width * 0.08, size.height * 0.62,
                         size.width * 0.84, size.height * 0.30)
        withShadow(context) {
            fill(UIBezierPath(pad, pad.height * 0.35), secondary)
        }

        // A-frame, drawn as two thick legs meeting near the top.
        val apex = CGPoint(size.width / 2, size.height * 0.14)
        val legWidth = max(2, size.width * 0.045)
        for (direction in listOf((-1).toDouble(), (1).toDouble())) {
            val foot = CGPoint(size.width / 2 + direction * size.width * 0.30,
                               size.height * 0.70)
            val leg = UIBezierPath()
            leg.move(apex)
            leg.addLine(foot)
            stroke(leg, accent, legWidth)
        }

        val hub = CGRect(apex.x - legWidth, apex.y - legWidth,
                         legWidth * 2, legWidth * 2)
        fill(UIBezierPath(ovalIn =  hub), primary)
    }

    // Hull plus its two suspension arms, drawn hanging from the top edge so
    // the sprite can pivot about that point.
    internal fun drawBoat(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val armWidth = max(1.5, size.width * 0.07)
        for (direction in listOf((-1).toDouble(), (1).toDouble())) {
            val arm = UIBezierPath()
            arm.move(CGPoint(size.width / 2, 1))
            arm.addLine(CGPoint(size.width / 2 + direction * size.width * 0.30,
                                    size.height * 0.66))
            stroke(arm, accent, armWidth)
        }

        // Hull: flat deck, curved bottom.
        val hull = UIBezierPath()
        val top = size.height * 0.62
        val bottom = size.height * 0.96
        hull.move(CGPoint(size.width * 0.06, top))
        hull.addLine(CGPoint(size.width * 0.94, top))
        hull.addQuadCurve(CGPoint(size.width * 0.50, bottom),
                          CGPoint(size.width * 0.86, bottom))
        hull.addQuadCurve(CGPoint(size.width * 0.06, top),
                          CGPoint(size.width * 0.14, bottom))
        hull.close()
        fill(hull, primary)

        val stripe = CGRect(size.width * 0.10, top + (bottom - top) * 0.18,
                            size.width * 0.80, max(1, size.height * 0.05))
        fill(UIBezierPath(stripe), ParkPalette.colour(ParkColour.cream))
    }

    internal fun drawDropTowerBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val pad = CGRect(size.width * 0.10, size.height * 0.74,
                         size.width * 0.80, size.height * 0.20)
        withShadow(context) {
            fill(UIBezierPath(pad, pad.height * 0.35), secondary)
        }

        val column = CGRect(size.width * 0.42, size.height * 0.06,
                            size.width * 0.16, size.height * 0.72)
        fill(UIBezierPath(column, column.width * 0.3), accent)

        // Banding up the column gives the drop something to read against.
        val bands = 5
        for (index in 0 until bands) {
            val y = column.minY + column.height * ((index).toDouble() + 0.5) / (bands).toDouble()
            val band = CGRect(column.minX, y, column.width,
                              max(1, size.height * 0.015))
            fill(UIBezierPath(band), ParkPalette.colour(ParkColour.cream))
        }

        val cap = CGRect(size.width * 0.36, size.height * 0.02,
                         size.width * 0.28, size.height * 0.07)
        fill(UIBezierPath(cap, cap.height * 0.4), primary)
    }

    internal fun drawTowerCar(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(CGPoint.zero, size).insetBy(0.5, 0.5)
        fill(UIBezierPath(body, body.height * 0.35), primary)
        val seats = body.insetBy(body.width * 0.14, body.height * 0.30)
        fill(UIBezierPath(seats), ParkPalette.colour(ParkColour.charcoal))
    }

    internal fun drawCoasterBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // No slab. The grass runs under the structure, which is what makes a
        // coaster read as standing in the park rather than on a board.
        val track = trackRect(size)

        // Columns round the outside of the loop, with a rail along their feet.
        val columns = UIBezierPath()
        for (index in 0 until 10) {
            val angle = (index).toDouble() / 10 * PI * 2
            val point = CGPoint(track.midX + cos(angle) * track.width / 2,
                                track.midY + sin(angle) * track.height / 2)
            columns.move(point)
            columns.addLine(CGPoint(point.x, point.y + size.height * 0.07))
        }
        stroke(columns, ParkPalette.coasterSupport, max(1.5, size.width * 0.014))

        // Ties first, then the rail on top, so the rail reads continuous.
        stroke(UIBezierPath(ovalIn =  track), ParkPalette.coasterTie,
               max(2.5, size.height * 0.090))
        stroke(UIBezierPath(ovalIn =  track), accent, max(1.5, size.height * 0.042))

        // Station shed on the near side of the loop.
        val station = CGRect(track.midX - size.width * 0.13,
                             track.maxY - size.height * 0.06,
                             size.width * 0.26,
                             size.height * 0.16)
        fill(UIBezierPath(station, station.height * 0.3), primary)
    }

    // One car of a coaster train, nose to the right. The lead car gets a
    // pointed nose; the rest are plain, which is what makes a string of them
    // read as a train rather than as four identical blocks.
    internal fun drawCoasterCar(context: CGContext, size: CGSize, primary: UIColor, variant: Int) {
        val isLead = variant == 0
        val body = CGRect(CGPoint.zero, size).insetBy(0.5, size.height * 0.12)

        if (isLead) {
            // Wedge nose, which is the whole silhouette at this size.
            val nose = UIBezierPath()
            nose.move(CGPoint(body.minX, body.minY))
            nose.addLine(CGPoint(body.maxX - body.width * 0.20, body.minY))
            nose.addQuadCurve(CGPoint(body.maxX - body.width * 0.20, body.maxY),
                              CGPoint(body.maxX + body.width * 0.16,
                                                    body.midY))
            nose.addLine(CGPoint(body.minX, body.maxY))
            nose.close()
            fill(nose, primary)
        } else {
            fill(UIBezierPath(body, body.height * 0.34), primary)
        }

        // Riders: two pale dots per car, which is what says these are people
        // and not freight.
        val head = size.height * 0.34
        for (offset in listOf((0.26).toDouble(), (0.56).toDouble())) {
            fill(UIBezierPath(ovalIn =  CGRect(body.minX + body.width * offset,
                                             body.midY - head / 2,
                                             head, head)),
                 ParkPalette.colour(ParkColour.cream))
        }

        // Dark strip along the bottom, so the car sits on the rail rather than
        // floating over it.
        fill(UIBezierPath(CGRect(body.minX, body.maxY - size.height * 0.10,
                                       body.width * 0.86, size.height * 0.10)),
             ParkPalette.colour(ParkColour.charcoal))
    }

    // The path a vehicle on a circuit follows, in node space: origin at the
    // middle of the building and y upward, ready to drive a sprite along.
    //
    // Most circuits are the oval below. A full-size coaster has a shape of
    // its own, which is the point of it.
    internal fun motionPath(motif: BuildingMotif, buildingSize: CGSize): List<CGPoint> {
        val texturePoints: List<CGPoint>
        when (motif) {
        BuildingMotif.megaCoaster -> {
            texturePoints = megaCoasterPoints(buildingSize)
        }
        BuildingMotif.logFlume -> {
            texturePoints = logFlumePoints(buildingSize)
        }
        BuildingMotif.lanternCruise -> {
            texturePoints = BuildingArtWaterCircuits.lanternCanalPoints(buildingSize)
        }
        BuildingMotif.zipLine -> {
            // Not a loop: the two ends of the cable, and the rider is sent
            // down it and put back at the top.
            val cable = BuildingArtStructures.zipCable(buildingSize)
            texturePoints = listOf(cable.start, cable.end)
        }
        BuildingMotif.riverRapids -> {
            texturePoints = BuildingArtWaterCircuits.riverRapidsPoints(buildingSize)
        }
        BuildingMotif.skyGliders -> {
            // Out along the upper wire and back along the lower one. Still a
            // loop, but a flat one hugging the cables rather than an orbit of
            // the whole building.
            val cables = skyGliderCables(buildingSize)
            texturePoints = cables.out + cables.back
        }
        else -> {
            val track = trackRect(buildingSize)
            texturePoints = (0 until 36).map { step ->
                val angle = (step).toDouble() / 36 * PI * 2
                CGPoint(track.midX + cos(angle) * track.width / 2,
                        track.midY + sin(angle) * track.height / 2)
            }
        }
        }

        // Texture space runs y downward from the top-left; the scene runs y
        // upward from the middle.
        return texturePoints.map {
            CGPoint(it.x - buildingSize.width / 2,
                    buildingSize.height / 2 - it.y)
        }
    }

    // The oval the coaster train runs, in texture coordinates. Shared so the
    // drawn track and the animation path cannot drift apart.
    internal fun trackRect(size: CGSize): CGRect {
        return CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.16, size.height * 0.20)
    }

    // region Wheel and spinners

    internal fun drawFerrisWheelBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val pad = CGRect(size.width * 0.10, size.height * 0.72,
                         size.width * 0.80, size.height * 0.22)
        withShadow(context) {
            fill(UIBezierPath(pad, pad.height * 0.35), secondary)
        }

        // Two legs leaning in to the hub the wheel turns on.
        val hub = CGPoint(size.width / 2, size.height / 2)
        val legWidth = max(2, size.width * 0.045)
        for (direction in listOf((-1).toDouble(), (1).toDouble())) {
            val leg = UIBezierPath()
            leg.move(hub)
            leg.addLine(CGPoint(hub.x + direction * size.width * 0.26,
                                    size.height * 0.80))
            stroke(leg, accent, legWidth)
        }

        val cap = CGRect(hub.x - legWidth, hub.y - legWidth,
                         legWidth * 2, legWidth * 2)
        fill(UIBezierPath(ovalIn =  cap), primary)
    }

    // The rim, its spokes and the cabins hanging off it.
    internal fun drawWheel(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val centre = CGPoint(size.width / 2, size.height / 2)
        val radius = min(size.width, size.height) / 2 - max(2, size.width * 0.08)

        val spokes = 8
        for (index in 0 until spokes) {
            val angle = (index).toDouble() / (spokes).toDouble() * PI * 2
            val spoke = UIBezierPath()
            spoke.move(centre)
            spoke.addLine(CGPoint(centre.x + cos(angle) * radius,
                                      centre.y + sin(angle) * radius))
            stroke(spoke, accent, max(1, size.width * 0.025))
        }

        val rim = CGRect(centre.x - radius, centre.y - radius,
                         radius * 2, radius * 2)
        stroke(UIBezierPath(ovalIn =  rim), primary, max(1.5, size.width * 0.05))

        val cabin = size.width * 0.13
        for (index in 0 until spokes) {
            val angle = (index).toDouble() / (spokes).toDouble() * PI * 2
            val point = CGPoint(centre.x + cos(angle) * radius - cabin / 2,
                                centre.y + sin(angle) * radius - cabin / 2)
            fill(UIBezierPath(CGRect(point,
                                                  CGSize(cabin, cabin)),
                              cabin * 0.3),
 (if (index % 2 == 0) secondary else ParkPalette.colour(ParkColour.cream)))
        }
    }

    internal fun drawTeacupsBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val floor = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.10, size.height * 0.10)
        withShadow(context) {
            fill(UIBezierPath(ovalIn =  floor), secondary)
        }
        stroke(UIBezierPath(ovalIn =  floor.insetBy(floor.width * 0.14, floor.height * 0.14)),
               accent, max(1, size.width * 0.02))
    }

    // Three cups clustered on a turntable.
    internal fun drawCups(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val centre = CGPoint(size.width / 2, size.height / 2)
        val orbit = size.width * 0.28
        val cup = size.width * 0.36
        val colours = listOf(primary, accent, ParkPalette.colour(ParkColour.cream))

        for (index in 0 until 3) {
            val angle = (index).toDouble() / 3 * PI * 2
            val rect = CGRect(centre.x + cos(angle) * orbit - cup / 2,
                              centre.y + sin(angle) * orbit - cup / 2,
                              cup, cup)
            fill(UIBezierPath(ovalIn =  rect), colours[index])
            stroke(UIBezierPath(ovalIn =  rect.insetBy(cup * 0.24, cup * 0.24)),
                   ParkPalette.colour(ParkColour.charcoal), max(1, size.width * 0.02))
        }
    }

    // region Circuits

    internal fun drawBumperCarsBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val arena = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.06, size.height * 0.07)
        withShadow(context) {
            fill(UIBezierPath(arena, arena.height * 0.18), primary)
        }

        val floor = arena.insetBy(arena.width * 0.07, arena.height * 0.09)
        fill(UIBezierPath(floor, floor.height * 0.15),
             ParkPalette.colour(ParkColour.charcoal))

        // Bulbs around the rail, the one detail that says fairground.
        val bulbs = 10
        for (index in 0 until bulbs) {
            val step = (index).toDouble() / (bulbs).toDouble()
            val x = arena.minX + arena.width * step + arena.width / (bulbs).toDouble() / 2
            val dot = size.width * 0.035
            for (y in listOf(arena.minY + dot, arena.maxY - dot * 2)) {
                fill(UIBezierPath(ovalIn =  CGRect(x - dot / 2, y,
                                                 dot, dot)), accent)
            }
        }
    }

    internal fun drawGoKartsBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val ground = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.04, size.height * 0.05)
        withShadow(context) {
            fill(UIBezierPath(ground, ground.height * 0.12), secondary)
        }

        // Asphalt, then a white edge line on top of it.
        val track = trackRect(size)
        stroke(UIBezierPath(ovalIn =  track), ParkPalette.colour(ParkColour.charcoal),
               max(3, size.height * 0.13))
        stroke(UIBezierPath(ovalIn =  track), ParkPalette.colour(ParkColour.white),
               max(1, size.height * 0.012))

        // Start line across the bottom straight.
        val line = CGRect(track.midX - size.width * 0.01,
                          track.maxY - size.height * 0.065,
                          size.width * 0.02, size.height * 0.13)
        fill(UIBezierPath(line), ParkPalette.colour(ParkColour.white))

        val pit = CGRect(track.midX + size.width * 0.06,
                         track.maxY - size.height * 0.02,
                         size.width * 0.22, size.height * 0.15)
        fill(UIBezierPath(pit, pit.height * 0.3), primary)
        fill(UIBezierPath(CGRect(pit.minX, pit.minY,
                                       pit.width, pit.height * 0.3)), accent)
    }

    // Livery for the vehicles a motif has several of. Fixed rather than taken
    // from the building's own colours, because four karts in four shades of
    // the same colour is not a race.
    val liveries = listOf(ParkColour.red, ParkColour.blue, ParkColour.yellow, ParkColour.green, ParkColour.violet)

    // Not private: the rides drawn in the neighbouring files take their
    // vehicle colours from the same list, so a raft and a kart belong to the
    // same park.
    internal fun livery(variant: Int): UIColor {
        return ParkPalette.colour(liveries[variant % liveries.size])
    }

    // A kart seen from above, nose to the right, because the sprite is turned
    // to face the way it is travelling.
    internal fun drawKart(context: CGContext, size: CGSize, variant: Int) {
        val colour = livery(variant)
        val tyre = ParkPalette.colour(ParkColour.charcoal)

        // Tyres first, so the body sits over their inner edge.
        val tyreWidth = size.width * 0.22
        val tyreHeight = size.height * 0.26
        for (x in listOf(size.width * 0.14, size.width * 0.66)) {
            for (y in listOf(-size.height * 0.02, size.height * 0.76)) {
                fill(UIBezierPath(CGRect(x, y,
                                                      tyreWidth, tyreHeight),
                                  tyreHeight * 0.4), tyre)
            }
        }

        // Chassis: wide at the back, tapering to a point at the nose.
        val body = UIBezierPath()
        body.move(CGPoint(size.width * 0.06, size.height * 0.26))
        body.addLine(CGPoint(size.width * 0.60, size.height * 0.18))
        body.addQuadCurve(CGPoint(size.width * 0.60, size.height * 0.82),
                          CGPoint(size.width * 1.02, size.height * 0.50))
        body.addLine(CGPoint(size.width * 0.06, size.height * 0.74))
        body.close()
        fill(body, colour)

        // Driver, and the roll bar behind them.
        val helmet = size.height * 0.34
        fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.34,
                                         size.height * 0.5 - helmet / 2,
                                         helmet, helmet)),
             ParkPalette.colour(ParkColour.cream))

        val bar = CGRect(size.width * 0.16, size.height * 0.28,
                         size.width * 0.09, size.height * 0.44)
        fill(UIBezierPath(bar, bar.width * 0.4), tyre)
    }

    // A bumper car seen from above: a round shell inside a fat rubber ring,
    // which is the only part of it that ever actually touches anything.
    internal fun drawBumperCar(context: CGContext, size: CGSize, variant: Int) {
        val colour = livery(variant)

        val bumper = CGRect(CGPoint.zero, size).insetBy(0.5, 0.5)
        fill(UIBezierPath(ovalIn =  bumper), ParkPalette.colour(ParkColour.charcoal))

        val shell = bumper.insetBy(bumper.width * 0.16, bumper.height * 0.18)
        fill(UIBezierPath(ovalIn =  shell), colour)

        // Driver, set slightly back from the front.
        val head = min(shell.width, shell.height) * 0.44
        fill(UIBezierPath(ovalIn =  CGRect(shell.midX - head * 0.75,
                                         shell.midY - head / 2,
                                         head, head)),
             ParkPalette.colour(ParkColour.cream))

        // Pole to the ceiling grid, drawn as a bright cap at the back.
        val pole = min(shell.width, shell.height) * 0.20
        fill(UIBezierPath(ovalIn =  CGRect(shell.minX + shell.width * 0.06,
                                         shell.midY - pole / 2,
                                         pole, pole)),
             ParkPalette.colour(ParkColour.amber))
    }

    // region Shop emblems

    // Draws the shared booth, then whatever the shop actually sells on a
    // board above it.
    //
    // The emblems are deliberately blunt: a burger is three stacked bands, a
    // cone is a triangle under a scoop. At this size a drawing of a burger
    // and a drawing of a sandwich look identical, so what matters is that
    // each shop's silhouette is different from its neighbour's.
    internal fun drawBurgerStall(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        drawStall(context, size, primary, secondary, accent)
        val board = signBoard(context, size, accent)

        val width = board.width * 0.62
        val bun = CGRect(board.midX - width / 2, board.midY - board.height * 0.26,
                         width, board.height * 0.52)
        // Top bun.
        val top = UIBezierPath(CGPoint(bun.midX, bun.midY - bun.height * 0.06),
                               width / 2,
                               PI, 0, true)
        top.close()
        fill(top, ParkPalette.colour(ParkColour.amber))
        // Filling and base.
        fill(UIBezierPath(CGRect(bun.minX, bun.midY - bun.height * 0.05,
                                       width, bun.height * 0.20)),
             ParkPalette.colour(ParkColour.brown))
        fill(UIBezierPath(CGRect(bun.minX, bun.midY + bun.height * 0.17,
                                              width, bun.height * 0.22),
                          bun.height * 0.10),
             ParkPalette.colour(ParkColour.amber))
    }

    internal fun drawPizzaStall(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        drawStall(context, size, primary, secondary, accent)
        val board = signBoard(context, size, accent)

        // A single slice, point down.
        val slice = UIBezierPath()
        val width = board.width * 0.52
        slice.move(CGPoint(board.midX - width / 2, board.midY - board.height * 0.24))
        slice.addLine(CGPoint(board.midX + width / 2, board.midY - board.height * 0.24))
        slice.addLine(CGPoint(board.midX, board.midY + board.height * 0.30))
        slice.close()
        fill(slice, ParkPalette.colour(ParkColour.amber))

        // Crust along the top, pepperoni on the face.
        fill(UIBezierPath(CGRect(board.midX - width / 2,
                                              board.midY - board.height * 0.30,
                                              width, board.height * 0.12),
                          board.height * 0.06),
             ParkPalette.colour(ParkColour.brown))
        val dot = board.height * 0.11
        for (offset in listOf(CGPoint(-0.12, -0.08), CGPoint(0.11, -0.06), CGPoint(-0.01, 0.10))) {
            fill(UIBezierPath(ovalIn =  CGRect(board.midX + board.width * offset.x - dot / 2,
                                             board.midY + board.height * offset.y - dot / 2,
                                             dot, dot)),
                 ParkPalette.colour(ParkColour.red))
        }
    }

    internal fun drawDrinkKiosk(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        drawKiosk(context, size, primary, secondary, accent)
        val board = signBoard(context, size, accent)

        // A tapered cup with a lid and a straw.
        val cup = UIBezierPath()
        val top = board.midY - board.height * 0.18
        val bottom = board.midY + board.height * 0.30
        val halfTop = board.width * 0.17
        val halfBottom = board.width * 0.12
        cup.move(CGPoint(board.midX - halfTop, top))
        cup.addLine(CGPoint(board.midX + halfTop, top))
        cup.addLine(CGPoint(board.midX + halfBottom, bottom))
        cup.addLine(CGPoint(board.midX - halfBottom, bottom))
        cup.close()
        // Not cream: the board behind it is cream, and a cream cup on a cream
        // board is an outline of nothing.
        fill(cup, ParkPalette.colour(ParkColour.cyan))
        stroke(cup, ParkPalette.colour(ParkColour.charcoal), max(1, board.width * 0.035))

        fill(UIBezierPath(CGRect(board.midX - halfTop * 1.15,
                                              top - board.height * 0.10,
                                              halfTop * 2.3, board.height * 0.12),
                          board.height * 0.05),
             ParkPalette.colour(ParkColour.red))

        val straw = UIBezierPath()
        straw.move(CGPoint(board.midX + halfTop * 0.35, top - board.height * 0.08))
        straw.addLine(CGPoint(board.midX + halfTop * 0.85, top - board.height * 0.38))
        stroke(straw, ParkPalette.colour(ParkColour.red), max(1, board.width * 0.05))
    }

    internal fun drawIceCreamStall(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        drawKiosk(context, size, primary, secondary, accent)
        val board = signBoard(context, size, accent)

        // Cone, point down, with a scoop on top.
        val cone = UIBezierPath()
        val width = board.width * 0.34
        val top = board.midY - board.height * 0.02
        cone.move(CGPoint(board.midX - width / 2, top))
        cone.addLine(CGPoint(board.midX + width / 2, top))
        cone.addLine(CGPoint(board.midX, board.midY + board.height * 0.34))
        cone.close()
        fill(cone, ParkPalette.colour(ParkColour.sand))

        val scoop = board.height * 0.34
        fill(UIBezierPath(ovalIn =  CGRect(board.midX - scoop / 2,
                                         top - scoop * 0.78,
                                         scoop, scoop)),
             ParkPalette.colour(ParkColour.pink))
        fill(UIBezierPath(ovalIn =  CGRect(board.midX - scoop * 0.30,
                                         top - scoop * 1.10,
                                         scoop * 0.62, scoop * 0.62)),
             ParkPalette.colour(ParkColour.cream))
    }

    internal fun drawSouvenirShop(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        drawShopFront(context, size, primary, secondary, accent)
        val board = signBoard(context, size, accent)

        // A wrapped box with a ribbon over it.
        val box = CGRect(board.midX - board.width * 0.20, board.midY - board.height * 0.16,
                         board.width * 0.40, board.height * 0.44)
        fill(UIBezierPath(box, board.height * 0.05),
             ParkPalette.colour(ParkColour.red))
        fill(UIBezierPath(CGRect(box.midX - box.width * 0.09, box.minY,
                                       box.width * 0.18, box.height)),
             ParkPalette.colour(ParkColour.cream))
        fill(UIBezierPath(CGRect(box.minX, box.midY - box.height * 0.09,
                                       box.width, box.height * 0.18)),
             ParkPalette.colour(ParkColour.cream))
        // Bow.
        val bow = box.height * 0.30
        for (direction in listOf((-1).toDouble(), (1).toDouble())) {
            fill(UIBezierPath(ovalIn =  CGRect(box.midX + direction * bow * 0.5 - bow / 2,
                                             box.minY - bow * 0.55,
                                             bow, bow * 0.8)),
                 ParkPalette.colour(ParkColour.cream))
        }
    }

    // A blank board over the top of a booth, and the space left to draw on.
    // Every shop gets the same board so the row of them reads as a parade.
    internal fun signBoard(context: CGContext, size: CGSize, accent: UIColor): CGRect {
        val board = CGRect(size.width * 0.24, size.height * 0.05,
                           size.width * 0.52, size.height * 0.34)
        withShadow(context) {
            fill(UIBezierPath(board, board.height * 0.22),
                 ParkPalette.colour(ParkColour.cream))
        }
        stroke(UIBezierPath(board, board.height * 0.22),
               accent, max(1, size.width * 0.018))
        return board
    }

    // region On the water

    // A walled pond with boats loose in it. The same idea as the bumper car
    // arena, wet.
    internal fun drawBumperBoatsBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val wall = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.05, size.height * 0.06)
        withShadow(context) {
            fill(UIBezierPath(wall, wall.height * 0.20), primary)
        }

        val pond = wall.insetBy(wall.width * 0.07, wall.height * 0.09)
        fill(UIBezierPath(pond, pond.height * 0.17), ParkPalette.water)

        // Ripples, so still water does not read as a slab of paint.
        for (step in 0 until 3) {
            val inset = pond.height * (0.16 + 0.12 * (step).toDouble())
            stroke(UIBezierPath(pond.insetBy(inset * 1.6, inset),
                                pond.height * 0.14),
                   ParkPalette.colour(ParkColour.white).withAlphaComponent(0.16),
                   max(1, size.height * 0.010))
        }

        // Landing stage on the near edge.
        val jetty = CGRect(pond.midX - pond.width * 0.16, pond.maxY - size.height * 0.02,
                           pond.width * 0.32, size.height * 0.09)
        fill(UIBezierPath(jetty, jetty.height * 0.3), accent)
    }

    // A bumper boat from above: a rounded hull with a rubber ring round it.
    // Named apart from the galleon's hull, which is a different boat.
    internal fun drawBumperBoat(context: CGContext, size: CGSize, variant: Int) {
        val ring = CGRect(CGPoint.zero, size).insetBy(0.5, 0.5)
        fill(UIBezierPath(ovalIn =  ring), ParkPalette.colour(ParkColour.charcoal))

        val hull = ring.insetBy(ring.width * 0.15, ring.height * 0.17)
        fill(UIBezierPath(ovalIn =  hull), livery(variant))

        val head = min(hull.width, hull.height) * 0.46
        fill(UIBezierPath(ovalIn =  CGRect(hull.midX - head * 0.72, hull.midY - head / 2,
                                         head, head)),
             ParkPalette.colour(ParkColour.cream))
    }

    // A jetty on a pond with a rowing boat going round it.
    internal fun drawFishingBoatsBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val bank = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.03, size.height * 0.04)
        withShadow(context) {
            fill(UIBezierPath(bank, bank.height * 0.16), secondary)
        }

        val pond = bank.insetBy(bank.width * 0.10, bank.height * 0.12)
        fill(UIBezierPath(ovalIn =  pond), ParkPalette.water)

        // Reeds round the edge, and lily pads on the water.
        for ((x, y) in listOf(Pair(0.12, 0.30), Pair(0.16, 0.70), Pair(0.86, 0.36), Pair(0.90, 0.66), Pair(0.50, 0.10))) {
            val stem = UIBezierPath()
            val foot = CGPoint(size.width * (x).toDouble(), size.height * (y).toDouble())
            stem.move(foot)
            stem.addLine(CGPoint(foot.x + size.width * 0.012, foot.y - size.height * 0.11))
            stroke(stem, ParkPalette.colour(ParkColour.green), max(1, size.width * 0.012))
        }
        for ((x, y, r) in listOf(Triple(0.34, 0.36, 0.055), Triple(0.62, 0.62, 0.045), Triple(0.44, 0.72, 0.038))) {
            val radius = size.height * (r).toDouble()
            fill(UIBezierPath(ovalIn =  CGRect(size.width * (x).toDouble() - radius,
                                             size.height * (y).toDouble() - radius,
                                             radius * 2, radius * 2)),
                 ParkPalette.colour(ParkColour.lime).withAlphaComponent(0.85))
        }

        // Jetty out from the near bank.
        val jetty = CGRect(pond.midX - size.width * 0.05, pond.maxY - size.height * 0.10,
                           size.width * 0.10, size.height * 0.22)
        fill(UIBezierPath(jetty, jetty.width * 0.3),
             ParkPalette.colour(ParkColour.brown))
        val hut = CGRect(pond.midX - size.width * 0.09, pond.maxY + size.height * 0.02,
                         size.width * 0.18, size.height * 0.12)
        fill(UIBezierPath(hut, hut.height * 0.3), primary)
        fill(UIBezierPath(CGRect(hut.minX, hut.minY,
                                       hut.width, hut.height * 0.34)), accent)
    }

    // A rowing boat with an angler and a rod out over the side.
    internal fun drawRowBoat(context: CGContext, size: CGSize, variant: Int) {
        val hull = UIBezierPath()
        hull.move(CGPoint(size.width * 0.06, size.height * 0.24))
        hull.addLine(CGPoint(size.width * 0.68, size.height * 0.16))
        hull.addQuadCurve(CGPoint(size.width * 0.68, size.height * 0.84),
                          CGPoint(size.width * 1.04, size.height * 0.5))
        hull.addLine(CGPoint(size.width * 0.06, size.height * 0.76))
        hull.close()
        fill(hull, ParkPalette.colour(ParkColour.brown))

        val well = CGRect(size.width * 0.16, size.height * 0.34,
                          size.width * 0.48, size.height * 0.32)
        fill(UIBezierPath(well, well.height * 0.4),
             ParkPalette.colour(ParkColour.sand))

        val head = size.height * 0.30
        fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.26, size.height * 0.5 - head / 2,
                                         head, head)),
             ParkPalette.colour(ParkColour.cream))

        // The rod, which is the whole reason anybody knows what this is.
        val rod = UIBezierPath()
        rod.move(CGPoint(size.width * 0.40, size.height * 0.44))
        rod.addLine(CGPoint(size.width * 0.86, size.height * -0.10))
        stroke(rod, ParkPalette.colour(ParkColour.charcoal), max(1, size.height * 0.055))
    }

    // A rectangular pool with a wave rolling down it and a board on the wave.
    internal fun drawWavePoolBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val deck = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.04, size.height * 0.05)
        withShadow(context) {
            fill(UIBezierPath(deck, deck.height * 0.14), secondary)
        }

        val pool = deck.insetBy(deck.width * 0.08, deck.height * 0.16)
        fill(UIBezierPath(pool, pool.height * 0.12), ParkPalette.water)

        // Standing swell across the pool, drawn as three stacked crests.
        for (step in 0 until 3) {
            val crest = UIBezierPath()
            val y = pool.minY + pool.height * (0.30 + 0.22 * (step).toDouble())
            crest.move(CGPoint(pool.minX, y))
            var x = pool.minX
            var up = true
            while (x < pool.maxX) {
                val next = min(x + pool.width * 0.16, pool.maxX)
                crest.addQuadCurve(CGPoint(next, y),
                                   CGPoint((x + next) / 2,
                                                         y + ( (if (up) -1 else 1)) * pool.height * 0.09))
                x = next
                up = !up
            }
            stroke(crest, ParkPalette.colour(ParkColour.white).withAlphaComponent(0.55 - 0.12 * (step).toDouble()),
                   max(1, size.height * 0.016))
        }

        // Machinery housing along the far end, where the wave comes from.
        val plant = CGRect(deck.minX, deck.minY,
                           deck.width * 0.14, deck.height)
        fill(UIBezierPath(plant, plant.width * 0.25), primary)
        fill(UIBezierPath(CGRect(plant.minX, plant.midY - deck.height * 0.06,
                                       plant.width, deck.height * 0.12)), accent)
    }

    // A board with a rider on it, seen from above.
    internal fun drawSurfer(context: CGContext, size: CGSize, variant: Int) {
        val board = CGRect(CGPoint.zero, size).insetBy(0.5, size.height * 0.22)
        fill(UIBezierPath(board, board.height / 2), livery(variant))

        val head = size.height * 0.44
        fill(UIBezierPath(ovalIn =  CGRect(board.midX - head / 2, size.height / 2 - head / 2,
                                         head, head)),
             ParkPalette.colour(ParkColour.cream))
        // Spray off the tail.
        val wash = UIBezierPath()
        wash.move(CGPoint(board.minX, size.height * 0.5))
        wash.addLine(CGPoint(board.minX - size.width * 0.22, size.height * 0.18))
        wash.move(CGPoint(board.minX, size.height * 0.5))
        wash.addLine(CGPoint(board.minX - size.width * 0.22, size.height * 0.82))
        stroke(wash, ParkPalette.colour(ParkColour.white).withAlphaComponent(0.8),
               max(1, size.height * 0.10))
    }

    // region Sky gliders and the maze

    // The two cables a chairlift runs, out along one and back along the
    // other. Shared with the motion, so the chairs hang off the wire that is
    // actually drawn.
    internal fun skyGliderCables(size: CGSize): CablePair {
        fun curve(sag: Double, from: Double, to: Double): List<CGPoint> {
            val head = size.height * 0.30
            val start = CGPoint(size.width * from, head)
            val end = CGPoint(size.width * to, head)
            val control = CGPoint(size.width * 0.50, head + size.height * sag)
            // Broken into named weights rather than one expression per axis:
            // the type checker gives up on the long form.
            return (0 until 18).map { step ->
                val t = (step).toDouble() / (18).toDouble()
                val inverse: Double = 1 - t
                val startWeight: Double = inverse * inverse
                val controlWeight: Double = 2 * inverse * t
                val endWeight: Double = t * t
                val x: Double = startWeight * start.x + controlWeight * control.x + endWeight * end.x
                val y: Double = startWeight * start.y + controlWeight * control.y + endWeight * end.y
                CGPoint(x, y)
            }
        }
        return CablePair(curve(0.30, 0.14, 0.86),
                curve(0.52, 0.86, 0.14))
    }

    internal fun drawSkyGlidersBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // No slab: a chairlift is two towers and a wire, and the grass runs
        // under it.
        //
        // Two cables between the tower heads: chairs go out along one and come
        // back along the other, the way a chairlift actually works.
        val head = size.height * 0.30
        val cables = skyGliderCables(size)
        for (wire in listOf(cables.out, cables.back)) {
            val path = UIBezierPath()
            path.move(wire[0])
            for (point in wire.drop(1)) { path.addLine(point) }
            stroke(path, ParkPalette.colour(ParkColour.charcoal), max(1, size.height * 0.020))
        }

        // Towers, splayed at the foot like a real lift pylon, with a boarding
        // platform under each.
        for (x in listOf((0.14).toDouble(), (0.86).toDouble())) {
            val top = CGPoint(size.width * x, head - size.height * 0.06)
            val foot = size.height * 0.82

            val legs = UIBezierPath()
            for (spread in listOf((-0.045).toDouble(), (0.045).toDouble())) {
                legs.move(top)
                legs.addLine(CGPoint(size.width * (x + spread), foot))
            }
            // Two rungs across the legs.
            for (height in listOf((0.45).toDouble(), (0.72).toDouble())) {
                val y = top.y + (foot - top.y) * height
                val half = size.width * 0.045 * height
                legs.move(CGPoint(size.width * x - half, y))
                legs.addLine(CGPoint(size.width * x + half, y))
            }
            stroke(legs, accent, max(1.5, size.width * 0.016))

            val platform = CGRect(size.width * x - size.width * 0.10,
                                  size.height * 0.80,
                                  size.width * 0.20, size.height * 0.15)
            withShadow(context) {
                fill(UIBezierPath(platform, platform.height * 0.3),
                     primary)
            }
        }
    }

    // A chair on the cable: a seat, a back and the hanger above it.
    internal fun drawGliderChair(context: CGContext, size: CGSize, variant: Int) {
        val hanger = UIBezierPath()
        hanger.move(CGPoint(size.width * 0.5, 0))
        hanger.addLine(CGPoint(size.width * 0.5, size.height * 0.40))
        stroke(hanger, ParkPalette.colour(ParkColour.charcoal), max(1, size.width * 0.10))

        val seat = CGRect(size.width * 0.12, size.height * 0.38,
                          size.width * 0.76, size.height * 0.44)
        fill(UIBezierPath(seat, seat.height * 0.32), livery(variant))

        val head = size.height * 0.30
        fill(UIBezierPath(ovalIn =  CGRect(seat.midX - head / 2, seat.minY - head * 0.35,
                                         head, head)),
             ParkPalette.colour(ParkColour.cream))
    }

    // A mirrored box: a squat building whose front is all glass panels.
    internal fun drawMirrorMaze(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.08, size.height * 0.10)
        withShadow(context) {
            fill(UIBezierPath(body, body.height * 0.08), primary)
        }

        // Panels, each catching the light at a slightly different angle.
        val columns = 4
        val rows = 3
        for (column in 0 until columns) {
            for (row in 0 until rows) {
                val panel = CGRect(
                    body.minX + body.width * (0.06 + 0.225 * (column).toDouble()),
                    body.minY + body.height * (0.10 + 0.28 * (row).toDouble()),
                    body.width * 0.185,
                    body.height * 0.22)
                val tilt = ((column * 3 + row) % 5).toDouble() / 5
                fill(UIBezierPath(panel, panel.height * 0.12),
                     ParkPalette.colour(ParkColour.cyan).withAlphaComponent(0.35 + 0.45 * tilt))
                // A streak across each pane, which is what says glass.
                val streak = UIBezierPath()
                streak.move(CGPoint(panel.minX + panel.width * 0.15, panel.maxY))
                streak.addLine(CGPoint(panel.maxX, panel.minY + panel.height * 0.25))
                stroke(streak, ParkPalette.colour(ParkColour.white).withAlphaComponent(0.5),
                       max(1, size.width * 0.008))
            }
        }

        // Doorway, off to one side so the front is not symmetrical.
        val door = CGRect(body.minX + body.width * 0.06, body.maxY - body.height * 0.24,
                          body.width * 0.16, body.height * 0.24)
        fill(UIBezierPath(door, door.width * 0.2), accent)
    }

    // A boarding platform with the first few sleepers of a lift hill running
    // off the back of it, so it reads as the start of something rather than
    // as another shed.
    internal fun drawCoasterStation(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val platform = CGRect(size.width * 0.05, size.height * 0.44,
                              size.width * 0.90, size.height * 0.48)
        withShadow(context) {
            fill(UIBezierPath(platform, platform.height * 0.16),
                 secondary)
        }
        fill(UIBezierPath(CGRect(platform.minX, platform.maxY - size.height * 0.07,
                                       platform.width, size.height * 0.05)),
             accent)

        // Canopy over the boarding side.
        val canopy = CGRect(size.width * 0.08, size.height * 0.12,
                            size.width * 0.84, size.height * 0.26)
        fill(UIBezierPath(canopy, canopy.height * 0.30), primary)
        for (x in listOf(size.width * 0.14, size.width * 0.82)) {
            fill(UIBezierPath(CGRect(x, canopy.maxY,
                                           size.width * 0.035,
                                           size.height * 0.10)),
                 ParkPalette.colour(ParkColour.charcoal))
        }

        // Track running out of the station, with a chain up the middle.
        val rails = UIBezierPath()
        for (offset in listOf(-size.width * 0.06, size.width * 0.06)) {
            rails.move(CGPoint(size.width * 0.5 + offset, platform.midY))
            rails.addLine(CGPoint(size.width * 0.5 + offset, size.height))
        }
        stroke(rails, ParkPalette.coasterRail, max(1, size.width * 0.028))

        val chain = UIBezierPath()
        for (step in 0 until 4) {
            val y = platform.midY + (size.height - platform.midY) * (0.2 + 0.24 * (step).toDouble())
            chain.move(CGPoint(size.width * 0.42, y))
            chain.addLine(CGPoint(size.width * 0.58, y))
        }
        stroke(chain, ParkPalette.coasterTie, max(1, size.height * 0.020))
    }

    // region Log flume

    // The channel a log runs, in texture space.
    //
    // Like the big coaster, one list of points is both the trough that gets
    // drawn and the path the log follows. A flume is a lift, a long run at
    // height, one big drop into water, and a slow return, and it should read
    // as all four rather than as a blue oval.
    internal fun logFlumePoints(size: CGSize): List<CGPoint> {
        fun at(x: Double, y: Double): CGPoint {
            return CGPoint(x * size.width, y * size.height)
        }

        val points = ArrayList<CGPoint>()

        fun line(from: CGPoint, to: CGPoint, steps: Int) {
            for (step in 0 until steps) {
                val t = (step).toDouble() / (steps).toDouble()
                points.add(CGPoint(from.x + (to.x - from.x) * t,
                                      from.y + (to.y - from.y) * t))
            }
        }

        fun curve(from: CGPoint, control: CGPoint, to: CGPoint, steps: Int) {
            for (step in 0 until steps) {
                val t = (step).toDouble() / (steps).toDouble()
                val inverse: Double = 1 - t
                val startWeight: Double = inverse * inverse
                val controlWeight: Double = 2 * inverse * t
                val endWeight: Double = t * t
                val x: Double = startWeight * from.x + controlWeight * control.x + endWeight * to.x
                val y: Double = startWeight * from.y + controlWeight * control.y + endWeight * to.y
                points.add(CGPoint(x, y))
            }
        }

        // Out of the loading trough and up the lift.
        line(at(0.07, 0.88), at(0.24, 0.88), 5)
        line(at(0.24, 0.88), at(0.33, 0.17), 13)
        // A gentle run along the top, which is where the queue watches from.
        curve(at(0.33, 0.17), at(0.42, 0.11), at(0.56, 0.15), 8)
        // The drop. Steep, and straight into the water.
        curve(at(0.56, 0.15), at(0.70, 0.28), at(0.73, 0.74), 12)
        // Out of the splash and round the bottom back to the start.
        curve(at(0.73, 0.74), at(0.80, 0.84), at(0.90, 0.82), 6)
        curve(at(0.90, 0.82), at(0.95, 0.86), at(0.93, 0.94), 4)
        line(at(0.93, 0.94), at(0.11, 0.94), 16)
        curve(at(0.11, 0.94), at(0.04, 0.94), at(0.07, 0.88), 4)

        return points
    }

    // Where the drop lands, so the pool and the channel agree.
    internal fun flumeSplash(size: CGSize): CGRect {
        return CGRect(size.width * 0.60, size.height * 0.66,
               size.width * 0.30, size.height * 0.22)
    }

    internal fun drawLogFlumeBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // No slab: the park's own grass runs under the flume, and the planting
        // below sits on it.
        //
        // Fixed positions, so the same flume always looks the same.
        val bushes = listOf(
            Triple(0.10, 0.62, 0.9), Triple(0.17, 0.72, 0.7), Triple(0.44, 0.86, 1.0),
            Triple(0.52, 0.72, 0.7), Triple(0.40, 0.36, 0.8), Triple(0.86, 0.34, 1.0),
            Triple(0.93, 0.48, 0.7), Triple(0.24, 0.36, 0.7), Triple(0.66, 0.88, 0.8))
        for ((x, y, scale) in bushes) {
            val radius = size.height * 0.055 * scale
            val centre = CGPoint(size.width * x, size.height * y)
            fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius, centre.y - radius * 0.85,
                                             radius * 2, radius * 1.7)),
                 ParkPalette.colour(ParkColour.green))
            fill(UIBezierPath(ovalIn =  CGRect(centre.x - radius * 0.55,
                                             centre.y - radius * 1.05,
                                             radius * 1.1, radius * 1.0)),
                 ParkPalette.colour(ParkColour.lime))
        }

        // The splash pool goes down before the channel, so the trough passes
        // over the water rather than stopping at it.
        val pool = flumeSplash(size)
        fill(UIBezierPath(ovalIn =  pool), ParkPalette.water)
        stroke(UIBezierPath(ovalIn =  pool.insetBy(pool.width * 0.10, pool.height * 0.14)),
               ParkPalette.colour(ParkColour.white).withAlphaComponent(0.55),
               max(1, size.height * 0.010))

        val points = logFlumePoints(size)
        if (!(points.size > 2)) return
        // Trestles under the raised sections, which is what makes the height
        // read as height.
        val deck = size.height * 0.95
        val trestles = UIBezierPath()
        for ((index, point) in points.withIndex()) {
            if (!(index % 4 == 0 && point.y < deck - 6)) continue
            trestles.move(point)
            trestles.addLine(CGPoint(point.x, deck))
            // A cross-brace halfway down each leg, which is what timber
            // trestles actually look like and what stops them reading as
            // scratches.
            trestles.move(CGPoint(point.x - size.width * 0.014,
                                      (point.y + deck) / 2))
            trestles.addLine(CGPoint(point.x + size.width * 0.014,
                                         (point.y + deck) / 2))
        }
        stroke(trestles, ParkPalette.flumeTimber.withAlphaComponent(0.75),
               max(1.5, size.width * 0.014))

        val channel = UIBezierPath()
        channel.move(points[0])
        for (point in points.drop(1)) { channel.addLine(point) }
        channel.close()

        // Timber trough, then the water sitting in it.
        stroke(channel, ParkPalette.flumeTimber, max(3, size.height * 0.055))
        stroke(channel, ParkPalette.water, max(1.5, size.height * 0.030))
        stroke(channel, ParkPalette.colour(ParkColour.white).withAlphaComponent(0.35),
               max(1, size.height * 0.008))

        // Spray where the drop meets the pool.
        val spray = UIBezierPath()
        for (step in 0 until 5) {
            val spread = (step).toDouble() / 4 - 0.5
            val origin = CGPoint(pool.midX + spread * pool.width * 0.55,
                                 pool.minY + pool.height * 0.35)
            spray.move(origin)
            spray.addLine(CGPoint(origin.x + spread * size.width * 0.06,
                                      origin.y - size.height * 0.11))
        }
        stroke(spray, ParkPalette.colour(ParkColour.white).withAlphaComponent(0.8),
               max(1, size.width * 0.012))

        // Loading station over the bottom-left straight.
        val station = CGRect(size.width * 0.05, size.height * 0.80,
                             size.width * 0.22, size.height * 0.13)
        fill(UIBezierPath(station, station.height * 0.3), primary)
        fill(UIBezierPath(CGRect(station.minX, station.minY,
                                       station.width, station.height * 0.32)),
             accent)
    }

    // A hollowed log with riders in it, prow to the right.
    internal fun drawLog(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val hull = UIBezierPath()
        val top = size.height * 0.16
        val bottom = size.height * 0.84
        hull.move(CGPoint(size.width * 0.04, top))
        hull.addLine(CGPoint(size.width * 0.72, top))
        // Rounded prow at the leading end.
        hull.addQuadCurve(CGPoint(size.width * 0.72, bottom),
                          CGPoint(size.width * 1.06, size.height * 0.5))
        hull.addLine(CGPoint(size.width * 0.04, bottom))
        hull.addQuadCurve(CGPoint(size.width * 0.04, top),
                          CGPoint(size.width * -0.10, size.height * 0.5))
        hull.close()
        fill(hull, ParkPalette.colour(ParkColour.brown))

        // Hollow, so it reads as something you sit in.
        val well = CGRect(size.width * 0.14, size.height * 0.30,
                          size.width * 0.62, size.height * 0.40)
        fill(UIBezierPath(well, well.height * 0.45),
             ParkPalette.colour(ParkColour.charcoal).withAlphaComponent(0.55))

        // Two riders.
        val head = size.height * 0.30
        for (offset in listOf((0.20).toDouble(), (0.48).toDouble())) {
            fill(UIBezierPath(ovalIn =  CGRect(size.width * offset,
                                             size.height * 0.5 - head / 2,
                                             head, head)),
                 ParkPalette.colour(ParkColour.cream))
        }
    }

    // region Towers and slides

    internal fun drawSlingshotBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val pad = CGRect(size.width * 0.14, size.height * 0.78,
                         size.width * 0.72, size.height * 0.16)
        withShadow(context) {
            fill(UIBezierPath(pad, pad.height * 0.35), secondary)
        }

        // Twin masts, leaning very slightly apart.
        for (direction in listOf((-1).toDouble(), (1).toDouble())) {
            val mast = UIBezierPath()
            mast.move(CGPoint(size.width / 2 + direction * size.width * 0.22,
                                  size.height * 0.04))
            mast.addLine(CGPoint(size.width / 2 + direction * size.width * 0.30,
                                     size.height * 0.82))
            stroke(mast, accent, max(2, size.width * 0.055))
        }

        // The elastic, slack between the two mast heads.
        val cable = UIBezierPath()
        cable.move(CGPoint(size.width * 0.28, size.height * 0.06))
        cable.addQuadCurve(CGPoint(size.width * 0.72, size.height * 0.06),
                           CGPoint(size.width * 0.50, size.height * 0.30))
        stroke(cable, primary, max(1, size.width * 0.025))
    }

    internal fun drawCapsule(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val ball = CGRect(CGPoint.zero, size).insetBy(1, 1)
        fill(UIBezierPath(ovalIn =  ball), primary)
        stroke(UIBezierPath(ovalIn =  ball.insetBy(ball.width * 0.18, ball.height * 0.18)),
               ParkPalette.colour(ParkColour.charcoal), max(1, size.width * 0.09))
    }

    internal fun drawCarpetSlideBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val ground = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.06, size.height * 0.06)
        withShadow(context) {
            fill(UIBezierPath(ground, ground.height * 0.12), secondary)
        }

        // Four lanes running top to bottom, with humps drawn as bands.
        val lanes = 4
        val laneWidth = ground.width * 0.17
        for (index in 0 until lanes) {
            val spacing = ground.width / (lanes + 1).toDouble()
            val x = ground.minX + spacing * (index + 1).toDouble() - laneWidth / 2
            val lane = CGRect(x, ground.minY + ground.height * 0.10,
                              laneWidth, ground.height * 0.66)
            fill(UIBezierPath(lane, laneWidth * 0.3),
 (if (index % 2 == 0) primary else accent))
            for (hump in 1..3) {
                val y = lane.minY + lane.height * (hump).toDouble() / 4
                fill(UIBezierPath(CGRect(lane.minX, y,
                                               lane.width,
                                               max(1, size.height * 0.012))),
                     ParkPalette.colour(ParkColour.cream))
            }
        }

        // Landing mat across the bottom.
        val landing = CGRect(ground.minX, ground.maxY - ground.height * 0.16,
                             ground.width, ground.height * 0.14)
        fill(UIBezierPath(landing, landing.height * 0.3),
             ParkPalette.colour(ParkColour.charcoal))
    }

    internal fun drawMat(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val mat = CGRect(CGPoint.zero, size).insetBy(0.5, 0.5)
        fill(UIBezierPath(mat, mat.height * 0.4),
             ParkPalette.colour(ParkColour.cream))
    }

    // A platform under a canopy, with a clock on the gable end. The train
    // belongs to the track rather than to the building, so nothing here moves.
    internal fun drawTrainStation(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val platform = CGRect(size.width * 0.04, size.height * 0.52,
                              size.width * 0.92, size.height * 0.40)
        withShadow(context) {
            fill(UIBezierPath(platform, platform.height * 0.18), secondary)
        }

        // Edge stripe along the platform, the way a real one is painted.
        fill(UIBezierPath(CGRect(platform.minX, platform.maxY - size.height * 0.06,
                                       platform.width, size.height * 0.045)),
             accent)

        val canopy = CGRect(size.width * 0.08, size.height * 0.14,
                            size.width * 0.84, size.height * 0.30)
        fill(UIBezierPath(canopy, canopy.height * 0.30), primary)

        // Posts holding the canopy up over the platform.
        for (x in listOf(size.width * 0.16, size.width * 0.80)) {
            fill(UIBezierPath(CGRect(x, canopy.maxY,
                                           size.width * 0.035,
                                           size.height * 0.16)),
                 ParkPalette.colour(ParkColour.brown))
        }

        val clock = min(size.width, size.height) * 0.18
        fill(UIBezierPath(ovalIn =  CGRect(size.width * 0.50 - clock / 2,
                                         canopy.midY - clock / 2,
                                         clock, clock)),
             ParkPalette.colour(ParkColour.cream))
        stroke(UIBezierPath(ovalIn =  CGRect(size.width * 0.50 - clock / 2,
                                           canopy.midY - clock / 2,
                                           clock, clock)),
               ParkPalette.colour(ParkColour.charcoal), max(1, size.width * 0.012))
    }

    // region Haunted house

    internal fun drawHauntedHouse(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(size.width * 0.14, size.height * 0.38,
                          size.width * 0.72, size.height * 0.52)
        withShadow(context) {
            fill(UIBezierPath(body), primary)
        }

        // Steep gabled roof overhanging the walls on both sides.
        val roof = UIBezierPath()
        roof.move(CGPoint(size.width * 0.08, size.height * 0.40))
        roof.addLine(CGPoint(size.width * 0.50, size.height * 0.08))
        roof.addLine(CGPoint(size.width * 0.92, size.height * 0.40))
        roof.close()
        fill(roof, secondary)

        // Lit windows, the only warm thing about it.
        val windowSize = CGSize(size.width * 0.13, size.height * 0.13)
        for (x in listOf((0.24).toDouble(), (0.63).toDouble())) {
            val rect = CGRect(CGPoint(size.width * x, size.height * 0.48),
                              windowSize)
            fill(UIBezierPath(rect, windowSize.width * 0.2), accent)
        }

        val door = CGRect(size.width * 0.43, size.height * 0.68,
                          size.width * 0.14, size.height * 0.22)
        fill(UIBezierPath(door, door.width * 0.4),
             ParkPalette.colour(ParkColour.charcoal))
    }

    internal fun drawGhost(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = UIBezierPath()
        val waist = size.height * 0.66
        body.move(CGPoint(size.width * 0.10, waist))
        body.addQuadCurve(CGPoint(size.width * 0.90, waist),
                          CGPoint(size.width * 0.50, -size.height * 0.24))
        // A scalloped hem, which is what makes a white blob read as a ghost.
        body.addLine(CGPoint(size.width * 0.90, size.height * 0.94))
        body.addQuadCurve(CGPoint(size.width * 0.50, size.height * 0.94),
                          CGPoint(size.width * 0.70, size.height * 0.72))
        body.addQuadCurve(CGPoint(size.width * 0.10, size.height * 0.94),
                          CGPoint(size.width * 0.30, size.height * 0.72))
        body.close()
        fill(body, ParkPalette.colour(ParkColour.white))

        val eye = size.width * 0.16
        for (x in listOf((0.28).toDouble(), (0.56).toDouble())) {
            fill(UIBezierPath(ovalIn =  CGRect(size.width * x, size.height * 0.42,
                                             eye, eye)),
                 ParkPalette.colour(ParkColour.charcoal))
        }
    }

    // region Mega coaster

    // The circuit a big coaster's train runs, in texture space.
    //
    // One list of points serves as both the track that gets drawn and the
    // path the train follows, so the two can never disagree about where the
    // rails are. A lift hill, a drop, a vertical loop and a run back to the
    // station, which is what makes it read as a coaster rather than an oval.
    internal fun megaCoasterPoints(size: CGSize): List<CGPoint> {
        fun at(x: Double, y: Double): CGPoint {
            return CGPoint(x * size.width, y * size.height)
        }

        val points = ArrayList<CGPoint>()

        fun line(from: CGPoint, to: CGPoint, steps: Int) {
            for (step in 0 until steps) {
                val t = (step).toDouble() / (steps).toDouble()
                points.add(CGPoint(from.x + (to.x - from.x) * t,
                                      from.y + (to.y - from.y) * t))
            }
        }

        fun curve(from: CGPoint, control: CGPoint, to: CGPoint, steps: Int) {
            for (step in 0 until steps) {
                val t = (step).toDouble() / (steps).toDouble()
                val inverse: Double = 1 - t
                val startWeight: Double = inverse * inverse
                val controlWeight: Double = 2 * inverse * t
                val endWeight: Double = t * t
                val x: Double = startWeight * from.x + controlWeight * control.x + endWeight * to.x
                val y: Double = startWeight * from.y + controlWeight * control.y + endWeight * to.y
                points.add(CGPoint(x, y))
            }
        }

        fun loop(centre: CGPoint, radius: Double, steps: Int) {
            // Entered and left at the foot of the circle, which in texture
            // space is the largest y.
            for (step in 0 until steps) {
                // Sweeping downwards from the foot takes the train up the far
                // side first, which is the way a real vertical loop is run
                // when you enter it going right.
                val angle = PI / 2 - (step).toDouble() / (steps).toDouble() * PI * 2
                points.add(CGPoint(centre.x + cos(angle) * radius,
                                      centre.y + sin(angle) * radius))
            }
        }

        // The loop is entered and left at its lowest point, travelling right
        // both times. Sending the train in one way and out the other is what
        // made it turn on a dime coming off the loop.
        val loopCentre = at(0.72, 0.62)
        val loopRadius = size.height * 0.28
        val loopFoot = CGPoint(loopCentre.x, loopCentre.y + loopRadius)

        // Out of the station and up the lift hill.
        line(at(0.06, 0.90), at(0.22, 0.90), 5)
        line(at(0.22, 0.90), at(0.32, 0.13), 16)
        // Over the crest and down the first drop.
        curve(at(0.32, 0.13), at(0.40, 0.10), at(0.44, 0.22), 6)
        curve(at(0.44, 0.22), at(0.51, 0.68), at(0.56, 0.90), 11)
        // Level run into the foot of the loop, still going right.
        line(at(0.56, 0.90), loopFoot, 5)
        loop(loopCentre, loopRadius, 30)
        // Straight out the far side, under the loop, and back along the
        // bottom to the station.
        line(loopFoot, at(0.90, 0.90), 6)
        curve(at(0.90, 0.90), at(0.95, 0.91), at(0.94, 0.955), 4)
        line(at(0.94, 0.955), at(0.11, 0.955), 18)
        curve(at(0.11, 0.955), at(0.04, 0.955), at(0.06, 0.90), 4)

        return points
    }

    internal fun drawMegaCoasterBase(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // No ground slab. A coaster is a structure standing on the park, not a
        // painted rectangle, and the grass should run under it.
        val points = megaCoasterPoints(size)
        if (!(points.size > 2)) return
        val deck = size.height * 0.97

        // Columns first, so the track sits on top of them. Thick enough to
        // read as steel: a hairline looked like a pencil sketch.
        val columns = UIBezierPath()
        for ((index, point) in points.withIndex()) {
            if (!(index % 5 == 0 && point.y < deck - 4)) continue
            columns.move(point)
            columns.addLine(CGPoint(point.x, deck))
        }
        stroke(columns, ParkPalette.coasterSupport, max(1.5, size.width * 0.016))

        // Cross-bracing between the columns, which is most of what makes a
        // coaster read as built rather than drawn.
        val bracing = UIBezierPath()
        var previous: CGPoint? = null
        for ((index, point) in points.withIndex()) {
            if (!(index % 5 == 0 && point.y < deck - 8)) continue
            val last = previous
            if (last != null && abs(point.x - last.x) < size.width * 0.22) {
                bracing.move(CGPoint(last.x, (last.y + deck) / 2))
                bracing.addLine(CGPoint(point.x, (point.y + deck) / 2))
            }
            previous = point
        }
        stroke(bracing, ParkPalette.coasterSupport.withAlphaComponent(0.55),
               max(1, size.width * 0.008))

        // A ground beam the columns stand on.
        val beam = UIBezierPath()
        beam.move(CGPoint(size.width * 0.03, deck))
        beam.addLine(CGPoint(size.width * 0.97, deck))
        stroke(beam, ParkPalette.coasterSupport, max(1.5, size.height * 0.020))

        val track = UIBezierPath()
        track.move(points[0])
        for (point in points.drop(1)) { track.addLine(point) }
        track.close()

        // Ties, then the rail on top, the same way the railway tiles are
        // drawn. Heavier than before: this is the flagship ride in the park.
        stroke(track, ParkPalette.coasterTie, max(3, size.height * 0.042))
        stroke(track, accent, max(1.5, size.height * 0.019))

        // Station shed over the bottom-left straight, where the train boards.
        val station = CGRect(size.width * 0.05, size.height * 0.84,
                             size.width * 0.26, size.height * 0.12)
        fill(UIBezierPath(station, station.height * 0.3), primary)

        // Chain marks up the lift hill, which is the bit everyone recognises.
        val chain = UIBezierPath()
        chain.move(CGPoint(size.width * 0.30, size.height * 0.90))
        chain.addLine(CGPoint(size.width * 0.40, size.height * 0.12))
        stroke(chain, ParkPalette.colour(ParkColour.cream).withAlphaComponent(0.75),
               max(1, size.height * 0.008))
    }

    // region Shops and services

    internal fun drawStall(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.09, size.height * 0.09)

        withShadow(context) {
            fill(UIBezierPath(body, body.width * 0.14), primary)
        }

        // Striped awning across the top third.
        val awning = CGRect(body.minX, body.minY,
                            body.width, body.height * 0.34)
        context.saveGState()
        UIBezierPath(awning, body.width * 0.14).addClip()
        val stripes = 6
        for (index in 0 until stripes) {
            val stripe = CGRect(awning.minX + awning.width * (index).toDouble() / (stripes).toDouble(),
                                awning.minY,
                                awning.width / (stripes).toDouble(),
                                awning.height)
            fill(UIBezierPath(stripe),
 (if (index % 2 == 0) secondary else ParkPalette.colour(ParkColour.cream)))
        }
        context.restoreGState()

        // Counter.
        val counter = CGRect(body.minX + body.width * 0.12,
                             body.maxY - body.height * 0.26,
                             body.width * 0.76,
                             body.height * 0.16)
        fill(UIBezierPath(counter, counter.height * 0.3), accent)
    }

    internal fun drawKiosk(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(size.width * 0.16, size.height * 0.30,
                          size.width * 0.68, size.height * 0.60)
        withShadow(context) {
            fill(UIBezierPath(body, body.width * 0.16), primary)
        }

        // Domed roof overhanging the body.
        val dome = CGRect(size.width * 0.08, size.height * 0.10,
                          size.width * 0.84, size.height * 0.34)
        fill(UIBezierPath(ovalIn =  dome), secondary)

        val window = CGRect(body.minX + body.width * 0.18,
                            body.minY + body.height * 0.28,
                            body.width * 0.64,
                            body.height * 0.34)
        fill(UIBezierPath(window, window.height * 0.25), accent)
    }

    internal fun drawShopFront(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.08, size.height * 0.08)
        withShadow(context) {
            fill(UIBezierPath(body, body.width * 0.12), primary)
        }

        val roof = CGRect(body.minX, body.minY,
                          body.width, body.height * 0.26)
        context.saveGState()
        UIBezierPath(body, body.width * 0.12).addClip()
        fill(UIBezierPath(roof), secondary)
        context.restoreGState()

        val windows = 3
        for (index in 0 until windows) {
            val slot = body.width / (windows).toDouble()
            val window = CGRect(body.minX + slot * (index).toDouble() + slot * 0.22,
                                body.minY + body.height * 0.46,
                                slot * 0.56,
                                body.height * 0.34)
            fill(UIBezierPath(window, window.width * 0.2), accent)
        }
    }

    internal fun drawRestroom(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(CGPoint.zero, size)
            .insetBy(size.width * 0.10, size.height * 0.10)
        withShadow(context) {
            fill(UIBezierPath(body, body.width * 0.12), primary)
        }

        val roof = CGRect(body.minX, body.minY,
                          body.width, body.height * 0.22)
        context.saveGState()
        UIBezierPath(body, body.width * 0.12).addClip()
        fill(UIBezierPath(roof), secondary)
        context.restoreGState()

        // Two doors, which is what makes a restroom readable at this size.
        for (direction in listOf((0).toDouble(), (1).toDouble())) {
            val door = CGRect(body.minX + body.width * (0.16 + 0.38 * direction),
                              body.minY + body.height * 0.38,
                              body.width * 0.30,
                              body.height * 0.50)
            fill(UIBezierPath(door, door.width * 0.2), accent)
        }
    }

    internal fun drawBench(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val seat = CGRect(size.width * 0.10, size.height * 0.40,
                          size.width * 0.80, size.height * 0.30)
        withShadow(context) {
            fill(UIBezierPath(seat, seat.height * 0.3), primary)
        }
        val back = CGRect(size.width * 0.10, size.height * 0.22,
                          size.width * 0.80, size.height * 0.14)
        fill(UIBezierPath(back, back.height * 0.4), secondary)

        for (direction in listOf((0).toDouble(), (1).toDouble())) {
            val leg = CGRect(size.width * (0.18 + 0.52 * direction),
                             seat.maxY,
                             size.width * 0.10,
                             size.height * 0.18)
            fill(UIBezierPath(leg), accent)
        }
    }

    internal fun drawBin(context: CGContext, size: CGSize, primary: UIColor, secondary: UIColor, accent: UIColor) {
        val body = CGRect(size.width * 0.28, size.height * 0.32,
                          size.width * 0.44, size.height * 0.52)
        withShadow(context) {
            fill(UIBezierPath(body, body.width * 0.18), primary)
        }
        val lid = CGRect(size.width * 0.22, size.height * 0.22,
                         size.width * 0.56, size.height * 0.14)
        fill(UIBezierPath(lid, lid.height * 0.45), secondary)

        val ridge = CGRect(body.minX + body.width * 0.20, body.minY + body.height * 0.24,
                           body.width * 0.60, max(1, size.height * 0.04))
        fill(UIBezierPath(ridge), accent)
    }

    // region Scenery

}
