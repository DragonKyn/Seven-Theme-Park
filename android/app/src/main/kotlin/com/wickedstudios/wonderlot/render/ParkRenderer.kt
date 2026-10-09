package com.wickedstudios.wonderlot.render

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import com.wickedstudios.wonderlot.Attraction
import com.wickedstudios.wonderlot.AttractionKind
import com.wickedstudios.wonderlot.BuildingAppearance
import com.wickedstudios.wonderlot.FacilityKind
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.GameState
import com.wickedstudios.wonderlot.Guest
import com.wickedstudios.wonderlot.GuestActivity
import com.wickedstudios.wonderlot.GridCoord
import com.wickedstudios.wonderlot.GridSize
import com.wickedstudios.wonderlot.ParkColour
import com.wickedstudios.wonderlot.ParkMap
import com.wickedstudios.wonderlot.ParkScheme
import com.wickedstudios.wonderlot.ParkTarget
import com.wickedstudios.wonderlot.SelectionDetail
import com.wickedstudios.wonderlot.StaffRole
import com.wickedstudios.wonderlot.TerrainType
import com.wickedstudios.wonderlot.Tile
import com.wickedstudios.wonderlot.TrackNetwork
import com.wickedstudios.wonderlot.Vec2
import com.wickedstudios.wonderlot.gfx.BuildingArtwork
import com.wickedstudios.wonderlot.gfx.CGPoint
import com.wickedstudios.wonderlot.gfx.CGSize
import com.wickedstudios.wonderlot.gfx.GuestArtwork
import com.wickedstudios.wonderlot.gfx.GuestMood
import com.wickedstudios.wonderlot.gfx.ParkPalette
import com.wickedstudios.wonderlot.gfx.SpriteFactory
import com.wickedstudios.wonderlot.gfx.StaffArtwork
import com.wickedstudios.wonderlot.gfx.TerrainArtwork
import java.util.UUID
import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/**
 * Draws the park. The renderer owns no game state: every frame it advances the
 * controller and then draws [GameState] straight onto the canvas, so
 * rendering is free to run at the display's refresh rate while the simulation
 * ticks at its own fixed rate.
 *
 * Units: positions are in tiles, y up the screen as in the simulation. A tile
 * is [tileSide] points at 1:1 zoom.
 */
class ParkRenderer(
    private val controller: GameController,
    /** A presentation renderer draws the park but takes no input and drifts the camera by itself. */
    val isInteractive: Boolean = true,
) {
    companion object {
        /** Points per tile at 1:1 zoom. */
        const val tileSide = 32.0
        const val guestHeight = tileSide * 0.58
        const val staffHeight = tileSide * 0.66
        const val minCameraScale = 0.4
        const val maxCameraScale = 2.6
        private const val focusCameraScale = 0.8
        private const val focusDuration = 0.45

        /** Camera scale beyond which building names are hidden. */
        private const val labelCutoffScale = 1.35
    }

    // region Camera

    /** Where the camera is looking, in tiles. */
    var camX = 30.0
    var camY = 5.0

    /** Camera scale: points of world per point of screen, so bigger is further out. */
    var scale = 1.0

    private var width = 1
    private var height = 1
    private var density = 1f
    private var time = 0.0

    private var glideFrom: Vec2? = null
    private var glideTo: Vec2? = null
    private var glideScaleFrom = 1.0
    private var glideScaleTo = 1.0
    private var glideStart = 0.0
    private var handledCameraRequest: UUID? = null

    private val pixelsPerTile: Double get() = tileSide * density / scale

    fun screenX(tileX: Double): Float = ((tileX - camX) * pixelsPerTile + width / 2.0).toFloat()
    fun screenY(tileY: Double): Float = (height / 2.0 - (tileY - camY) * pixelsPerTile).toFloat()

    fun worldX(screenX: Float): Double = (screenX - width / 2.0) / pixelsPerTile + camX
    fun worldY(screenY: Float): Double = (height / 2.0 - screenY) / pixelsPerTile + camY

    fun tileAt(screenX: Float, screenY: Float): GridCoord? {
        val coord = GridCoord(floor(worldX(screenX)).toInt(), floor(worldY(screenY)).toInt())
        return if (controller.state.map.isInside(coord)) coord else null
    }

    fun panBy(dxPixels: Float, dyPixels: Float) {
        glideTo = null
        camX -= dxPixels / pixelsPerTile
        camY += dyPixels / pixelsPerTile
        clampCamera()
    }

    fun zoomBy(factor: Double, focusX: Float, focusY: Float) {
        glideTo = null
        val beforeX = worldX(focusX)
        val beforeY = worldY(focusY)
        scale = (scale / factor).coerceIn(minCameraScale, maxCameraScale)
        // Keep the point under the fingers where it was.
        camX += beforeX - worldX(focusX)
        camY += beforeY - worldY(focusY)
        clampCamera()
    }

    fun centreOnEntrance() {
        val entrance = controller.state.map.entranceCoord
        camX = entrance.x + 0.5
        camY = entrance.y + 5.0
        scale = 1.0
    }

    private fun clampCamera() {
        val map = controller.state.map
        val margin = 6.0
        camX = camX.coerceIn(-margin, map.width + margin)
        camY = camY.coerceIn(-margin, map.height + margin)
    }

    private fun applyCameraRequest() {
        val request = controller.cameraRequest ?: return
        if (request.id == handledCameraRequest) return
        handledCameraRequest = request.id

        glideFrom = Vec2(camX, camY)
        glideTo = request.point
        glideScaleFrom = scale
        glideScaleTo = max(min(scale, focusCameraScale), minCameraScale)
        glideStart = time
    }

    private fun stepGlide() {
        val to = glideTo ?: return
        val from = glideFrom ?: return
        val u = ((time - glideStart) / focusDuration).coerceIn(0.0, 1.0)
        val eased = u * u * (3 - 2 * u)
        camX = from.x + (to.x - from.x) * eased
        camY = from.y + (to.y - from.y) * eased
        scale = glideScaleFrom + (glideScaleTo - glideScaleFrom) * eased
        if (u >= 1.0) glideTo = null
    }

    /** Slowly sweeps the park so the menu background is never quite still. */
    private fun drift() {
        val centreX = controller.state.map.width / 2.0
        val period = 52.0
        val phase = (time % period) / period
        val wave = if (phase < 0.5) phase * 2 else (1 - phase) * 2
        val eased = wave * wave * (3 - 2 * wave)
        camX = centreX
        camY = 5.0 + 10.0 * eased
        scale = 0.78
    }

    // endregion

    // region Per-frame bookkeeping

    private val bitmapPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        textAlign = Paint.Align.CENTER
    }
    private val rect = RectF()

    private var tileBitmaps: Array<Bitmap?> = emptyArray()
    private var tileCodes: IntArray = IntArray(0)
    private var renderedMapGeneration = -1
    private var renderedTrackColour: ParkColour? = null

    private class CachedBuilding(val key: String, val bitmap: Bitmap)

    private val buildingBitmaps = HashMap<UUID, CachedBuilding>()
    private val sceneryBitmaps = HashMap<UUID, CachedBuilding>()
    private var renderedScheme: ParkScheme? = null

    private class GuestSprite(var mood: GuestMood, var prize: Any?, var popcorn: Boolean, var balloon: ParkColour?, var bitmap: Bitmap)

    private val guestSprites = HashMap<UUID, GuestSprite>()
    private val staffBitmaps = HashMap<UUID, Pair<String, Bitmap>>()
    private var renderedUniform: ParkColour? = null

    private class Bubble(val guestID: UUID, val bitmap: Bitmap, val startedAt: Double)

    private val bubbles = ArrayList<Bubble>()
    private val shownThought = HashMap<UUID, UUID>()

    // Trains.
    private class TrainCar(
        val loop: PathMotion.Loop,
        val attractionID: UUID?,
        val isLeading: Boolean,
        val isCoaster: Boolean,
        val flip: Boolean,
        val size: CGSize,
        val locomotive: Boolean,
    )

    private val trainCars = ArrayList<TrainCar>()
    private var renderedTrackGeneration = -1

    // endregion

    /** Advances the simulation and draws the result. */
    fun frame(canvas: Canvas, widthPx: Int, heightPx: Int, densityScale: Float, deltaSeconds: Double) {
        width = max(1, widthPx)
        height = max(1, heightPx)
        density = densityScale
        val delta = min(deltaSeconds, 0.25)
        time += delta

        controller.advance(delta)

        if (isInteractive) {
            applyCameraRequest()
            stepGlide()
        } else {
            drift()
        }

        draw(canvas)
    }

    private fun draw(canvas: Canvas) {
        val state = controller.state

        repaintParkFurniture(state)
        syncTiles(state)
        syncTrains(state)

        canvas.drawColor(Color.rgb(107, 168, 97))

        drawCarPark(canvas, state)
        drawTiles(canvas, state)
        drawLitter(canvas, state)
        drawScenery(canvas, state)
        drawTrains(canvas, state)
        drawBuildings(canvas, state)
        drawEntranceSign(canvas, state)
        if (isInteractive) drawGhost(canvas)
        drawGuests(canvas, state)
        drawStaff(canvas, state)
        drawBubbles(canvas, state)
        if (isInteractive) {
            drawSelection(canvas)
            drawMoveMarker(canvas)
        }
        drawLabels(canvas, state)
    }

    // region Helpers

    private fun spriteRect(centreX: Double, centreY: Double, widthTiles: Double, heightTiles: Double): RectF {
        val ppt = pixelsPerTile
        val cx = screenX(centreX)
        val cy = screenY(centreY)
        rect.set(
            (cx - widthTiles / 2 * ppt).toFloat(), (cy - heightTiles / 2 * ppt).toFloat(),
            (cx + widthTiles / 2 * ppt).toFloat(), (cy + heightTiles / 2 * ppt).toFloat(),
        )
        return rect
    }

    private fun drawSprite(canvas: Canvas, bitmap: Bitmap, centreX: Double, centreY: Double,
                           widthTiles: Double, heightTiles: Double,
                           quarterTurns: Int = 0, degrees: Double = 0.0, alpha: Float = 1f, flip: Boolean = false) {
        val turns = ((quarterTurns % 4) + 4) % 4
        val total = turns * 90.0 + degrees
        bitmapPaint.alpha = (alpha * 255).toInt()
        val dst = spriteRect(centreX, centreY, widthTiles, heightTiles)
        if (total == 0.0 && !flip) {
            canvas.drawBitmap(bitmap, null, dst, bitmapPaint)
        } else {
            canvas.save()
            canvas.rotate(total.toFloat(), screenX(centreX), screenY(centreY))
            if (flip) canvas.scale(-1f, 1f, screenX(centreX), screenY(centreY))
            canvas.drawBitmap(bitmap, null, dst, bitmapPaint)
            canvas.restore()
        }
        bitmapPaint.alpha = 255
    }

    private fun isVisible(centreX: Double, centreY: Double, halfExtentTiles: Double): Boolean {
        val ppt = pixelsPerTile
        val sx = screenX(centreX)
        val sy = screenY(centreY)
        val extent = halfExtentTiles * ppt
        return sx + extent >= 0 && sx - extent <= width && sy + extent >= 0 && sy - extent <= height
    }

    // endregion

    // region Tiles

    /** Drops every building and every piece of scenery when the park's colours change. */
    private fun repaintParkFurniture(state: GameState) {
        if (renderedScheme == state.scheme) return
        renderedScheme = state.scheme
        buildingBitmaps.clear()
        sceneryBitmaps.clear()
    }

    private fun syncTiles(state: GameState) {
        val map = state.map
        if (tileBitmaps.size != map.tileCount) {
            tileBitmaps = arrayOfNulls(map.tileCount)
            tileCodes = IntArray(map.tileCount) { -1 }
            renderedMapGeneration = -1
        }
        // Repainting the track is not a change to the map, so it forces its own pass.
        if (renderedTrackColour != state.coasterTrackColour) {
            renderedTrackColour = state.coasterTrackColour
            tileCodes.fill(-1)
            renderedMapGeneration = -1
        }

        if (map.generation == renderedMapGeneration) return
        renderedMapGeneration = map.generation

        // Each tile keeps a small code for how it currently looks, so the common case is an integer comparison.
        for (index in 0 until map.tileCount) {
            val coord = map.coordAt(index)
            val tile = map.tiles[index]
            val code = appearanceCode(tile, coord, map)
            if (tileCodes[index] == code && tileBitmaps[index] != null) continue
            tileCodes[index] = code
            tileBitmaps[index] = tileBitmap(tile, coord, map, state.coasterTrackColour)
        }
    }

    private fun appearanceCode(tile: Tile, coord: GridCoord, map: ParkMap): Int {
        val terrain = when (tile.terrain) {
            TerrainType.grass -> 0
            TerrainType.path -> 1
            TerrainType.entrance -> 2
            TerrainType.water -> 3
            TerrainType.track -> 4
            TerrainType.coasterTrack -> 5
            TerrainType.coasterLoop -> 6
            TerrainType.coasterHill -> 7
            TerrainType.coasterHelix -> 8
            TerrainType.coasterJump -> 9
            TerrainType.bridge -> 10
            TerrainType.rock -> 11
            TerrainType.forest -> 12
        }
        return terrain * 100_000 + tile.style * 10_000 + tileVariant(coord) * 100 + neighbourMask(tile, coord, map)
    }

    /** Which repeat of a terrain a tile uses, taken from the coordinate. */
    private fun tileVariant(coord: GridCoord): Int = ((coord.x * 7) + (coord.y * 13)) and 3

    private fun neighbourMask(tile: Tile, coord: GridCoord, map: ParkMap): Int = when (tile.terrain) {
        TerrainType.water -> shoreMask(coord, map)
        TerrainType.path, TerrainType.entrance, TerrainType.bridge -> walkwayConnections(coord, map)
        TerrainType.rock, TerrainType.forest -> edgeMask(tile.terrain, coord, map)
        else -> trackConnections(coord, map)
    }

    private fun neighbours(coord: GridCoord) = listOf(
        1 to GridCoord(coord.x, coord.y + 1),
        2 to GridCoord(coord.x + 1, coord.y),
        4 to GridCoord(coord.x, coord.y - 1),
        8 to GridCoord(coord.x - 1, coord.y),
    )

    /** Which of the four neighbours a guest could walk on to from here. */
    private fun walkwayConnections(coord: GridCoord, map: ParkMap): Int {
        var connections = 0
        for ((bit, neighbour) in neighbours(coord)) {
            if (map.tile(neighbour)?.terrain?.isWalkway == true) connections = connections or bit
        }
        return connections
    }

    /** Sides of a rock or forest tile that are open ground. */
    private fun edgeMask(terrain: TerrainType, coord: GridCoord, map: ParkMap): Int {
        var edges = 0
        for ((bit, neighbour) in neighbours(coord)) {
            // Off the map counts as more of the same, so the border does not grow a cliff edge against nothing.
            val other = map.tile(neighbour) ?: continue
            if (other.terrain != terrain) edges = edges or bit
        }
        return edges
    }

    /** Sides of a water tile that are not more water. */
    private fun shoreMask(coord: GridCoord, map: ParkMap): Int {
        var shores = 0
        for ((bit, neighbour) in neighbours(coord)) {
            if (map.tile(neighbour)?.terrain != TerrainType.water) shores = shores or bit
        }
        return shores
    }

    /** Which of the four neighbours are the same kind of track. */
    private fun trackConnections(coord: GridCoord, map: ParkMap): Int {
        val terrain = map.tile(coord)?.terrain ?: return 0
        if (terrain != TerrainType.track && !terrain.isCoasterTrack) return 0
        var connections = 0
        // Every kind of coaster piece joins every other.
        for ((bit, neighbour) in neighbours(coord)) {
            val other = map.tile(neighbour)?.terrain ?: continue
            val joins = if (terrain.isCoasterTrack) other.isCoasterTrack else other == terrain
            if (joins) connections = connections or bit
        }
        return connections
    }

    private fun tileBitmap(tile: Tile, coord: GridCoord, map: ParkMap, rail: ParkColour?): Bitmap {
        val variant = tileVariant(coord)
        return when (tile.terrain) {
            TerrainType.grass -> SpriteFactory.grassTexture(variant, tileSide)
            TerrainType.path -> TerrainArtwork.walkwayTexture(walkwayConnections(coord, map), tile.style, variant, tileSide)
            TerrainType.bridge -> TerrainArtwork.bridgeTexture(walkwayConnections(coord, map), tileSide)
            TerrainType.water -> TerrainArtwork.waterTexture(shoreMask(coord, map), tile.style, variant, tileSide)
            TerrainType.entrance -> SpriteFactory.tileTexture(ParkPalette.entrance, tileSide)
            TerrainType.rock -> TerrainArtwork.rockTexture(edgeMask(TerrainType.rock, coord, map), variant, tileSide)
            TerrainType.forest -> TerrainArtwork.forestTexture(edgeMask(TerrainType.forest, coord, map), variant, tileSide)
            TerrainType.track, TerrainType.coasterTrack, TerrainType.coasterLoop, TerrainType.coasterHill,
            TerrainType.coasterHelix, TerrainType.coasterJump ->
                SpriteFactory.trackTileTexture(trackConnections(coord, map), tileSide, tile.terrain.isCoasterTrack, rail)
        }
    }

    private fun drawTiles(canvas: Canvas, state: GameState) {
        val map = state.map
        if (tileBitmaps.size != map.tileCount) return
        val ppt = pixelsPerTile

        val minX = max(0, floor(worldX(0f)).toInt())
        val maxX = min(map.width - 1, floor(worldX(width.toFloat())).toInt())
        val minY = max(0, floor(worldY(height.toFloat())).toInt())
        val maxY = min(map.height - 1, floor(worldY(0f)).toInt())

        for (y in minY..maxY) {
            for (x in minX..maxX) {
                val bitmap = tileBitmaps[y * map.width + x] ?: continue
                // Overdrawn by a pixel so a seam never shows between two tiles.
                val left = screenX(x.toDouble())
                val top = screenY(y + 1.0)
                rect.set(left, top, (left + ppt + 1).toFloat(), (top + ppt + 1).toFloat())
                canvas.drawBitmap(bitmap, null, rect, bitmapPaint)
            }
        }
    }

    private fun drawLitter(canvas: Canvas, state: GameState) {
        val map = state.map
        for (coord in map.litteredTiles) {
            if (!isVisible(coord.x + 0.5, coord.y + 0.5, 1.0)) continue
            val intensity = min(2, (map.litter(coord) / 34).toInt())
            drawSprite(canvas, SpriteFactory.litterTexture(intensity, tileSide), coord.x + 0.5, coord.y + 0.5, 1.0, 1.0)
        }
    }

    // endregion

    // region Car park and sign

    private fun drawCarPark(canvas: Canvas, state: GameState) {
        val entrance = state.map.entranceCoord
        val bitmap = SpriteFactory.carParkTexture(state.carParkLevel, CGSize(tileSide * 13, tileSide * 4.4))
        drawSprite(canvas, bitmap, entrance.x + 0.5, entrance.y - 4.1, 13.0, 4.4)
    }

    private fun drawEntranceSign(canvas: Canvas, state: GameState) {
        val entrance = state.map.entranceCoord
        val widthTiles = 5.4
        val heightTiles = 1.5
        val cx = entrance.x + 0.5
        val cy = entrance.y - 0.85
        val bitmap = SpriteFactory.entranceSignTexture(CGSize(tileSide * widthTiles, tileSide * heightTiles))
        drawSprite(canvas, bitmap, cx, cy, widthTiles, heightTiles)

        // The park's name on the board face, shrunk to fit.
        val ppt = pixelsPerTile
        val face = widthTiles * 0.86 * ppt
        val name = state.parkName
        var size = min(heightTiles * ppt * 0.40, face * 1.5 / max(1, name.length))
        size = max(size, 1.0)
        textPaint.textSize = size.toFloat()
        textPaint.color = ParkPalette.signText.argb
        canvas.drawText(name, screenX(cx), (screenY(cy) - heightTiles * ppt * 0.13 + size * 0.35).toFloat(), textPaint)
    }

    // endregion

    // region Buildings and scenery

    private fun cachedBitmap(cache: HashMap<UUID, CachedBuilding>, id: UUID, appearance: BuildingAppearance,
                             widthTiles: Int, heightTiles: Int): Bitmap {
        val key = "${appearance.motif.name}${appearance.primary.name}${appearance.secondary.name}" +
            "${appearance.accent.name}${appearance.variant}-${widthTiles}x$heightTiles"
        cache[id]?.let { if (it.key == key) return it.bitmap }
        val bitmap = BuildingArtwork.bodyTexture(appearance, CGSize(widthTiles * tileSide, heightTiles * tileSide))
        cache[id] = CachedBuilding(key, bitmap)
        return bitmap
    }

    private fun drawScenery(canvas: Canvas, state: GameState) {
        val live = HashSet<UUID>()
        for (item in state.scenery) {
            live.add(item.id)
            if (!isVisible(item.rect.centre.x, item.rect.centre.y, max(item.size.width, item.size.height).toDouble())) continue

            val appearance = (item.definition?.appearance ?: BuildingAppearance.unknown)
                .withVariant(item.variant)
                .tinted(item.colour)
                .applying(state.scheme)
            val drawn = item.size.rotated(item.rotation)
            val bitmap = cachedBitmap(sceneryBitmaps, item.id, appearance, drawn.width, drawn.height)
            val centre = item.rect.centre
            drawSprite(canvas, bitmap, centre.x, centre.y, drawn.width.toDouble(), drawn.height.toDouble(), quarterTurns = item.rotation)
        }
        sceneryBitmaps.keys.retainAll(live)
    }

    private fun drawBuildings(canvas: Canvas, state: GameState) {
        val live = HashSet<UUID>()

        for (attraction in state.attractions) {
            live.add(attraction.id)
            drawBuilding(canvas, attraction.id, attraction.size, attraction.origin.x, attraction.origin.y, attraction.rotation,
                (attraction.definition?.appearance ?: BuildingAppearance.unknown).tinted(attraction.tint).applying(state.scheme),
                alpha = if (attraction.isOperational) 1f else 0.45f)
        }

        for (facility in state.facilities) {
            live.add(facility.id)
            val dimmed = !facility.isOpen || facility.isUnusable || facility.isBeingCleaned
            drawBuilding(canvas, facility.id, facility.size, facility.origin.x, facility.origin.y, facility.rotation,
                (facility.definition?.appearance ?: BuildingAppearance.unknown).withVariant(facility.variant).applying(state.scheme),
                alpha = if (dimmed) 0.45f else 1f)
        }

        buildingBitmaps.keys.retainAll(live)
    }

    private fun drawBuilding(canvas: Canvas, id: UUID, size: GridSize, originX: Int, originY: Int, rotation: Int,
                             appearance: BuildingAppearance, alpha: Float) {
        val centreX = originX + size.width / 2.0
        val centreY = originY + size.height / 2.0
        if (!isVisible(centreX, centreY, max(size.width, size.height).toDouble())) return

        // `size` is the ground the building takes up, already turned; the artwork is drawn the way round it was designed.
        val drawn = size.rotated(rotation)
        val bitmap = cachedBitmap(buildingBitmaps, id, appearance, drawn.width, drawn.height)
        drawSprite(canvas, bitmap, centreX, centreY, drawn.width.toDouble(), drawn.height.toDouble(), quarterTurns = rotation, alpha = alpha)
    }

    // endregion

    // region Trains

    private fun tileCentre(coord: GridCoord) = CGPoint(coord.x + 0.5, coord.y + 0.5)

    /** Puts a train on every circuit that has something to serve it. */
    private fun syncTrains(state: GameState) {
        if (state.map.generation == renderedTrackGeneration) return
        renderedTrackGeneration = state.map.generation
        trainCars.clear()

        runTrains(state.trackNetwork, state.attractions.filter { it.baseDefinition?.kind == AttractionKind.transport }, false)
        runTrains(state.coasterNetwork, state.attractions.filter { it.baseDefinition?.kind == AttractionKind.custom }, true)
    }

    private fun runTrains(network: TrackNetwork, stations: List<Attraction>, coaster: Boolean) {
        val carSize = if (coaster) CGSize(tileSide * 0.62, tileSide * 0.40) else CGSize(tileSide * 0.86, tileSide * 0.46)
        // A railway needs a station at each end to be worth running; a coaster is one ride, so one station is the whole thing.
        val stationsNeeded = if (coaster) 1 else 2

        for ((index, route) in network.routes.withIndex()) {
            if (route.tiles.size <= 2) continue
            val served = stations.filter { network.routeIndex(it.rect) == index }
            if (served.size < stationsNeeded) continue

            val points = PathMotion.smoothed(route.tiles.map { tileCentre(it) }, route.isLoop, 2)
            val pace = if (coaster) 0.34 else 0.85
            val span = PathMotion.ringLength(points)
            val duration = span * (if (route.isLoop) pace else pace * 2)

            val cars = if (coaster) 4 else 3
            val spacing = if (coaster) 0.68 else 1.0
            val consist = spacing * (cars - 1)

            for (carriage in 0 until cars) {
                val isTailLocomotive = !coaster && !route.isLoop && carriage == cars - 1
                val isLeading = carriage == 0 || isTailLocomotive

                if (route.isLoop) {
                    val perTile = max(1, points.size / max(route.tiles.size, 1))
                    val back = (carriage * perTile) % points.size
                    val offset = (points.size - back) % points.size
                    val carPath = points.subList(offset, points.size) + points.subList(0, offset)
                    trainCars.add(TrainCar(PathMotion.Loop(carPath, duration), served.firstOrNull()?.id, carriage == 0, coaster, false, carSize, isLeading))
                } else {
                    val run = PathMotion.shuttleRun(points, carriage, spacing, consist, max(48, points.size * 3))
                    trainCars.add(TrainCar(PathMotion.Loop(run.points, duration, run.headings.ifEmpty { null }),
                        served.firstOrNull()?.id, carriage == 0, coaster, isTailLocomotive, carSize, isLeading))
                }
            }
        }
    }

    private fun drawTrains(canvas: Canvas, state: GameState) {
        for (car in trainCars) {
            val pose = car.loop.pose(time)
            if (!isVisible(pose.x, pose.y, 2.0)) continue

            val bitmap = if (car.isCoaster) {
                val ride = car.attractionID?.let { state.attraction(it) }
                SpriteFactory.coasterCarTexture(car.isLeading, ride?.carStyle ?: com.wickedstudios.wonderlot.CoasterCarStyle.classic,
                    ride?.livery ?: ParkColour.red, car.size)
            } else {
                SpriteFactory.trainCarTexture(car.locomotive, car.size)
            }
            // The scene has y up and the sprite's heading is measured anticlockwise; the canvas turns clockwise.
            drawSprite(canvas, bitmap, pose.x, pose.y, car.size.width / tileSide, car.size.height / tileSide,
                degrees = -Math.toDegrees(pose.heading), flip = car.flip)
        }
    }

    // endregion

    // region People

    /** Where a guest's sprite actually sits: queueing guests fan out into slots, and diners sit on the seat. */
    private fun drawPosition(guest: Guest, state: GameState): Vec2 {
        seatPosition(guest, state)?.let { return it }
        var offsetX = 0.0
        var offsetY = 0.0
        if (guest.activity is GuestActivity.Queueing) {
            val slot = guest.queueSlot
            offsetX = ((slot % 3) - 1) * 0.24
            offsetY = (slot / 3) * -0.22
        }
        return Vec2(guest.position.x + offsetX, guest.position.y + offsetY)
    }

    /** Where a guest sitting at a bench or a picnic table is drawn: on the seat, not on the path beside it. */
    private fun seatPosition(guest: Guest, state: GameState): Vec2? {
        val activity = guest.activity as? GuestActivity.Engaged ?: return null
        val target = activity.target as? ParkTarget.Shop ?: return null
        val facility = state.facility(target.id) ?: return null
        if (facility.definition?.kind != FacilityKind.bench) return null
        val seat = facility.slots.indexOfFirst { it.guestID == guest.id }
        if (seat < 0) return null

        val offsets = seatOffsets(facility.definition?.simultaneousCapacity ?: 1)
        var offsetX = offsets[seat % offsets.size].first
        var offsetY = offsets[seat % offsets.size].second

        // Quarter turns clockwise, in a map whose y runs up the screen.
        repeat((((facility.rotation % 4) + 4) % 4)) {
            val x = offsetY
            val y = -offsetX
            offsetX = x
            offsetY = y
        }

        val centre = facility.rect.centre
        return Vec2(centre.x + offsetX, centre.y + offsetY)
    }

    private fun seatOffsets(count: Int): List<Pair<Double, Double>> = when {
        count >= 4 -> listOf(-0.20 to 0.30, 0.20 to 0.30, -0.20 to -0.30, 0.20 to -0.30)
        count >= 2 -> listOf(-0.18 to 0.02, 0.18 to 0.02)
        else -> listOf(0.0 to 0.02)
    }

    /** Whether a guest busy with something is still out in the open. */
    private fun isInTheOpen(target: ParkTarget, state: GameState): Boolean {
        val shop = target as? ParkTarget.Shop ?: return false
        val kind = state.facility(shop.id)?.definition?.kind ?: return false
        return kind == FacilityKind.game || kind == FacilityKind.bench
    }

    private fun drawGuests(canvas: Canvas, state: GameState) {
        val spriteHeight = guestHeight
        val spriteWidth = spriteHeight * GuestArtwork.aspect
        val live = HashSet<UUID>()
        val now = state.clock.simTime

        for (guest in state.guests) {
            if (!guest.isActive) continue
            live.add(guest.id)

            val activity = guest.activity
            if (activity is GuestActivity.Engaged && !isInTheOpen(activity.target, state)) continue

            val place = drawPosition(guest, state)
            if (!isVisible(place.x, place.y, 1.5)) continue

            val mood = GuestMood.of(guest.happiness)
            val eating = guest.popcornRemaining > 0
            var sprite = guestSprites[guest.id]
            if (sprite == null || sprite.mood != mood || sprite.prize != guest.prize || sprite.popcorn != eating || sprite.balloon != guest.balloon) {
                val bitmap = GuestArtwork.texture(guest.appearance, guest.ageCategory, mood, guest.prize, eating, guest.balloon, spriteHeight)
                if (sprite == null) {
                    sprite = GuestSprite(mood, guest.prize, eating, guest.balloon, bitmap)
                    guestSprites[guest.id] = sprite
                } else {
                    sprite.mood = mood
                    sprite.prize = guest.prize
                    sprite.popcorn = eating
                    sprite.balloon = guest.balloon
                    sprite.bitmap = bitmap
                }
            }

            drawSprite(canvas, sprite.bitmap, place.x, place.y, spriteWidth / tileSide, spriteHeight / tileSide)
            maybeShowBubble(guest, now)
        }

        guestSprites.keys.retainAll(live)
        shownThought.keys.retainAll(live)
    }

    private fun drawStaff(canvas: Canvas, state: GameState) {
        if (renderedUniform != state.uniformColour) {
            renderedUniform = state.uniformColour
            staffBitmaps.clear()
            StaffArtwork.clearCache()
        }

        val live = HashSet<UUID>()
        for (member in state.staff) {
            live.add(member.id)
            // Out of sight while on the train.
            if (member.isOnTrain) continue

            val look = member.look
            val scale = StaffArtwork.figureScale(look)
            val key = "${look.role.name}${look.act.name}${look.costume.name}${look.primary.name}${look.secondary.name}${look.trim.name}"
            var entry = staffBitmaps[member.id]
            if (entry == null || entry.first != key) {
                entry = key to StaffArtwork.texture(look, state.uniformColour, staffHeight)
                staffBitmaps[member.id] = entry
            }

            val sizeHeight = staffHeight * scale
            val sizeWidth = sizeHeight * StaffArtwork.aspect
            if (!isVisible(member.position.x, member.position.y, 2.0)) continue

            // Somebody in a costume does not walk like somebody in shorts.
            var sway = 0.0
            if (member.role == StaffRole.mascot) sway = Math.sin(time * Math.PI / 0.28 / 2) * 0.07 * (180 / Math.PI)

            drawSprite(canvas, entry.second, member.position.x, member.position.y, sizeWidth / tileSide, sizeHeight / tileSide, degrees = sway)
        }
        staffBitmaps.keys.retainAll(live)
    }

    // endregion

    // region Bubbles

    /** Pops a bubble over a guest who has just thought something new. */
    private fun maybeShowBubble(guest: Guest, now: Double) {
        val thought = guest.thoughts.lastOrNull() ?: return
        if (shownThought[guest.id] == thought.id) return
        shownThought[guest.id] = thought.id

        bubbles.removeAll { time - it.startedAt > 3.2 }
        if (now - thought.simTime >= 2.5 || bubbles.size >= 10) return

        val bitmap = GuestArtwork.bubbleTexture(thought.icon, thought.mood, tileSide * 0.62)
        bubbles.add(Bubble(guest.id, bitmap, time))
    }

    private fun drawBubbles(canvas: Canvas, state: GameState) {
        val side = 0.62
        val iterator = bubbles.iterator()
        while (iterator.hasNext()) {
            val bubble = iterator.next()
            val age = time - bubble.startedAt
            if (age > 3.2) {
                iterator.remove()
                continue
            }
            val guest = state.guest(bubble.guestID) ?: continue
            val place = drawPosition(guest, state)

            val grow = (age / 0.18).coerceIn(0.0, 1.0)
            val scale = 0.25 + 0.75 * grow
            var alpha = min(1.0, age / 0.14)
            var rise = 0.0
            val leaveAt = 0.18 + 2.4
            if (age > leaveAt) {
                val u = ((age - leaveAt) / 0.35).coerceIn(0.0, 1.0)
                alpha = 1 - u
                rise = side * 0.30 * u
            }
            val cx = place.x + side * 0.34
            val cy = place.y + guestHeight / tileSide * 0.55 + side * 0.42 + rise
            drawSprite(canvas, bubble.bitmap, cx, cy, side * scale, side * scale, alpha = alpha.toFloat())
        }
    }

    // endregion

    // region Overlays

    private fun drawFrame(canvas: Canvas, centreX: Double, centreY: Double, widthTiles: Double, heightTiles: Double,
                          colour: com.wickedstudios.wonderlot.gfx.UIColor, lineWidth: Double = 4.0, pulse: Double = 1.0) {
        val bitmap = SpriteFactory.outlineTexture(colour, CGSize(widthTiles * tileSide, heightTiles * tileSide), lineWidth)
        drawSprite(canvas, bitmap, centreX, centreY, widthTiles * pulse, heightTiles * pulse)
    }

    private fun drawGhost(canvas: Canvas) {
        // A placement waiting to be confirmed is drawn as the thing itself, the way round it would stand.
        val pending = controller.build.pending
        val definition = controller.pendingDefinition
        if (pending != null && definition != null) {
            val footprint = controller.pendingFootprint
            val drawn = footprint.rotated(pending.rotation)
            val centreX = pending.origin.x + footprint.width / 2.0
            val centreY = pending.origin.y + footprint.height / 2.0
            val valid = controller.pendingCheck?.isValid ?: false

            val appearance = definition.previewAppearance
            if (appearance != null) {
                val styled = appearance.withVariant(controller.build.variant ?: 0)
                    .tinted(controller.build.colour).applying(controller.state.scheme)
                val bitmap = BuildingArtwork.bodyTexture(styled, CGSize(drawn.width * tileSide, drawn.height * tileSide))
                drawSprite(canvas, bitmap, centreX, centreY, drawn.width.toDouble(), drawn.height.toDouble(),
                    quarterTurns = pending.rotation, alpha = if (valid) 0.92f else 0.5f)
            } else {
                val bitmap = SpriteFactory.buildingTexture(if (valid) ParkPalette.ghostValid else ParkPalette.ghostInvalid,
                    CGSize(drawn.width * tileSide, drawn.height * tileSide))
                drawSprite(canvas, bitmap, centreX, centreY, drawn.width.toDouble(), drawn.height.toDouble(), quarterTurns = pending.rotation)
            }

            // The pulsing outline round the ground a placement would take up.
            val pulse = 1.0 + 0.02 * (1 + Math.sin(time * Math.PI / 0.6))
            drawFrame(canvas, centreX, centreY, footprint.width.toDouble(), footprint.height.toDouble(),
                if (valid) ParkPalette.previewValid else ParkPalette.ghostInvalid, 4.0, pulse)
            return
        }

        if (!controller.build.isActive) return
        val coord = controller.build.ghost ?: return
        val size = if (controller.build.isDemolishing) GridSize.single else controller.ghostFootprint
        val colour = if (controller.build.ghostValid) ParkPalette.ghostValid else ParkPalette.ghostInvalid
        val bitmap = SpriteFactory.buildingTexture(colour, CGSize(size.width * tileSide, size.height * tileSide))
        drawSprite(canvas, bitmap, coord.x + size.width / 2.0, coord.y + size.height / 2.0, size.width.toDouble(), size.height.toDouble())
    }

    private fun drawSelection(canvas: Canvas) {
        val selection = controller.selection ?: return
        val state = controller.state

        var cx: Double? = null
        var cy = 0.0
        var w = 1.0
        var h = 1.0

        when (selection) {
            is SelectionDetail.OfGuest -> {
                val guest = state.guest(selection.detail.id)
                // A guest on a ride is not drawn, so the marker goes with them.
                if (guest != null && !(guest.activity is GuestActivity.Engaged && !isInTheOpen((guest.activity as GuestActivity.Engaged).target, state))) {
                    val place = drawPosition(guest, state)
                    cx = place.x
                    cy = place.y
                    val margin = 0.16
                    w = guestHeight / tileSide * GuestArtwork.aspect + margin
                    h = guestHeight / tileSide + margin
                }
            }
            is SelectionDetail.OfAttraction -> state.attraction(selection.detail.id)?.let {
                cx = it.origin.x + it.size.width / 2.0; cy = it.origin.y + it.size.height / 2.0
                w = it.size.width.toDouble(); h = it.size.height.toDouble()
            }
            is SelectionDetail.OfFacility -> state.facility(selection.detail.id)?.let {
                cx = it.origin.x + it.size.width / 2.0; cy = it.origin.y + it.size.height / 2.0
                w = it.size.width.toDouble(); h = it.size.height.toDouble()
            }
            is SelectionDetail.OfStaff -> state.staffMember(selection.detail.id)?.let {
                cx = it.position.x; cy = it.position.y
                val scale = StaffArtwork.figureScale(it.look)
                val margin = 0.16
                w = staffHeight / tileSide * scale * StaffArtwork.aspect + margin
                h = staffHeight / tileSide * scale + margin
            }
            is SelectionDetail.OfScenery -> state.scenery.firstOrNull { it.id == selection.detail.id }?.let {
                cx = it.origin.x + it.size.width / 2.0; cy = it.origin.y + it.size.height / 2.0
                w = it.size.width.toDouble(); h = it.size.height.toDouble()
            }
        }
        val x = cx ?: return
        drawFrame(canvas, x, cy, w, h, ParkPalette.selection, 3.0)
    }

    /** A pulsing square on the spot somebody is about to be sent to. */
    private fun drawMoveMarker(canvas: Canvas) {
        val coord = controller.pendingStaffMove ?: return
        val pulse = 1.0 + 0.09 * Math.sin(time * Math.PI / 0.5)
        drawFrame(canvas, coord.x + 0.5, coord.y + 0.5, 1.0, 1.0, ParkPalette.previewValid, 5.0, pulse)
    }

    // endregion

    // region Labels

    private fun drawLabels(canvas: Canvas, state: GameState) {
        val showNames = scale <= labelCutoffScale

        fun chip(centreX: Double, bottomY: Double, text: String) {
            val sx = screenX(centreX)
            val sy = screenY(bottomY)
            val size = (9.0 / scale * density).toFloat()
            textPaint.textSize = size
            val textWidth = textPaint.measureText(text)
            val chipWidth = max(18f * density / scale.toFloat(), textWidth + 10f * density / scale.toFloat())
            val chipHeight = 14f * density / scale.toFloat()
            rect.set(sx - chipWidth / 2, sy, sx + chipWidth / 2, sy + chipHeight)
            fillPaint.color = ParkPalette.labelChip.argb
            canvas.drawRoundRect(rect, chipHeight / 2, chipHeight / 2, fillPaint)
            textPaint.color = Color.WHITE
            canvas.drawText(text, sx, sy + chipHeight / 2 + size * 0.35f, textPaint)
        }

        fun badge(originX: Int, originY: Int, size: GridSize, text: String, colour: com.wickedstudios.wonderlot.gfx.UIColor) {
            val sx = screenX(originX + size.width.toDouble()) - 4f * density / scale.toFloat()
            val sy = screenY(originY + size.height.toDouble()) + 4f * density / scale.toFloat()
            val radius = 9f * density / scale.toFloat()
            fillPaint.color = colour.argb
            canvas.drawCircle(sx, sy, radius, fillPaint)
            textPaint.textSize = 10f * density / scale.toFloat()
            textPaint.color = Color.WHITE
            canvas.drawText(text, sx, sy + textPaint.textSize * 0.35f, textPaint)
        }

        for (attraction in state.attractions) {
            if (!isVisible(attraction.origin.x + attraction.size.width / 2.0, attraction.origin.y + attraction.size.height / 2.0, 6.0)) continue
            if (showNames) chip(attraction.origin.x + attraction.size.width / 2.0, attraction.origin.y.toDouble() - 0.1, attraction.name)
            when {
                attraction.isBroken -> badge(attraction.origin.x, attraction.origin.y, attraction.size, "!", ParkPalette.broken)
                attraction.queue.isNotEmpty() -> badge(attraction.origin.x, attraction.origin.y, attraction.size, "${attraction.queue.size}", ParkPalette.badge)
            }
        }

        for (facility in state.facilities) {
            if (!isVisible(facility.origin.x + facility.size.width / 2.0, facility.origin.y + facility.size.height / 2.0, 6.0)) continue
            if (showNames && facility.definition?.kind?.isFurniture != true) {
                chip(facility.origin.x + facility.size.width / 2.0, facility.origin.y.toDouble() - 0.1, facility.name)
            }
            when {
                facility.isBeingCleaned -> badge(facility.origin.x, facility.origin.y, facility.size, "…", ParkPalette.badge)
                facility.isUnusable -> badge(facility.origin.x, facility.origin.y, facility.size, "!", ParkPalette.broken)
                facility.queue.isNotEmpty() -> badge(facility.origin.x, facility.origin.y, facility.size, "${facility.queue.size}", ParkPalette.badge)
            }
        }
    }

    // endregion

    /** The nearest guest or employee to a point, within a generous tap radius. */
    fun personNear(worldX: Double, worldY: Double, state: GameState, buildMode: Boolean): Pair<UUID?, UUID?> {
        if (buildMode) return null to null
        var bestGuest: UUID? = null
        var bestStaff: UUID? = null
        var bestDistance = 0.8

        for (guest in state.guests) {
            if (!guest.isActive) continue
            // A guest inside a ride is not drawn, so it cannot be tapped.
            if (guest.activity is GuestActivity.Engaged) continue
            val distance = hypot(guest.position.x - worldX, guest.position.y - worldY)
            if (distance < bestDistance) {
                bestDistance = distance
                bestGuest = guest.id
                bestStaff = null
            }
        }
        for (member in state.staff) {
            val distance = hypot(member.position.x - worldX, member.position.y - worldY)
            if (distance < bestDistance) {
                bestDistance = distance
                bestStaff = member.id
                bestGuest = null
            }
        }
        return bestGuest to bestStaff
    }
}
