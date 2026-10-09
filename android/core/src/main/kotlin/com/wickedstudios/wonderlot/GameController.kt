@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.UseSerializers
import java.util.UUID
import kotlin.math.abs

/** Somewhere a building is about to go, once the player says so. */
data class PendingPlacement(val definitionID: String, var origin: GridCoord, var rotation: Int)

/** Somewhere the camera has been asked to go, in tile coordinates. */
class CameraRequest(val point: Vec2) {
    val id: UUID = UUID.randomUUID()
}

class PendingDemolition(val coord: GridCoord, val name: String, val refund: Double) {
    val id: UUID = UUID.randomUUID()
}

class BuildState {
    var isActive = false
    var isDemolishing = false

    /** While drawing, a one-finger drag paints walkway instead of moving the camera. */
    var isDrawing = false
    var category: BuildCategory = BuildCategory.path

    /** Quarter turns clockwise applied to whatever is about to be placed. */
    var rotation = 0

    /** Which cut of the selected thing to build, or null to let each one pick its own. */
    var variant: Int? = null

    /** A colour for the thing about to be built, where it comes in several. */
    var colour: ParkColour? = null

    /** A placement lined up and waiting to be confirmed. */
    var pending: PendingPlacement? = null

    /** Which shelf of the ride list is on show, or null for all of them. */
    var rideGroup: RideGroup? = null
    var selectedID: String? = null
    var ghost: GridCoord? = null
    var ghostValid = false
    var ghostReason: String? = null
}

/**
 * Owns the running park and is the only thing the UI talks to. The interface
 * reads cheap snapshots published from here rather than the simulation itself.
 */
class GameController(
    var state: GameState,
    var location: SaveLocation,
    private val services: Services,
    /** A demo controller drives the park behind the main menu and never writes a save. */
    val isDemo: Boolean = false,
) {
    /** Everything the controller needs from the platform. */
    class Services(
        val saveService: SaveGameService,
        val boosts: BoostCenter,
        val perkStore: PerkStore,
        val trialProgress: TrialProgressStore,
        val tutorial: TutorialDirector,
        val now: () -> Long = { System.currentTimeMillis() },
    )

    // region Published UI state

    var hud = HUDSnapshot()
        private set
    var selection: SelectionDetail? = null
        private set

    /** The employee the player is choosing a destination for, and where they have tapped so far. */
    var movingStaffID: UUID? = null
        private set
    var pendingStaffMove: GridCoord? = null
        private set

    /** The last place the player asked the map to show them. Read by the renderer every frame. */
    var cameraRequest: CameraRequest? = null
        private set
    var alerts: List<ParkAlert> = emptyList()
        private set
    var build = BuildState()
    var pendingDemolition: PendingDemolition? = null
        private set
    var saveMessage: String? = null
        private set

    /** A short message to the player that is not about saving. */
    var notice: String? = null
        private set

    /** The award currently being celebrated on screen, if any. */
    var celebration: AchievementAward? = null
        private set
    var currentTip: TutorialTip? = null
        private set

    /** The rare event currently on screen, if any. One at a time. */
    var event: ParkEvent? = null
        private set
    var eventRemaining = 1.0
        private set
    var celebrationRemaining = 1.0
        private set

    /** The end of a trial, on screen until the player chooses what next. */
    var trialResult: TrialResultReport? = null
        private set

    /** Bumped every time something the interface shows may have changed. */
    var uiVersion = 0
        private set

    // endregion

    private val engine = SimulationEngine()
    private var lastPaintedTile: GridCoord? = null
    private var eventShownAt: Long? = null
    private var celebrationShownAt: Long? = null
    private var uiRefreshAccumulator = 0.0
    private var autosaveAccumulator = 0.0

    private val eventDwell = 14.0
    private val celebrationDwell = 9.0
    private val uiRefreshInterval = 0.2

    /** Lets the platform's save/restore of the tick ceiling be set per device. */
    var maxTicksPerFrame: Int
        get() = engine.maxTicksPerFrame
        set(value) { engine.maxTicksPerFrame = value }

    init {
        refreshUI()
    }

    // region Frame driving

    /** Called once per rendered frame. */
    fun advance(realDelta: Double) {
        val ticks = engine.advance(state, realDelta)

        uiRefreshAccumulator += realDelta
        if (uiRefreshAccumulator >= uiRefreshInterval) {
            uiRefreshAccumulator = 0.0
            refreshUI()
        }

        if (ticks <= 0 || isDemo) return
        autosaveAccumulator += ticks * Balance.tickDuration
        if (autosaveAccumulator >= Balance.autosaveInterval) {
            autosaveAccumulator = 0.0
            autosave()
        }
    }

    // endregion

    // region Speed

    /** Whether the fifth notch is unlocked just now. */
    val isTurboUnlocked: Boolean get() = services.boosts.isActive(BoostKind.turboSpeed)

    fun setSpeed(speed: GameSpeed) {
        // A notch that needs a boost is refused rather than silently ignored.
        if (speed.needsBoost && !isTurboUnlocked) return
        state.clock.speed = speed
        engine.resetTiming()
        refreshUI()
    }

    fun togglePause() {
        setSpeed(if (state.clock.speed == GameSpeed.paused) GameSpeed.normal else GameSpeed.paused)
    }

    // endregion

    // region Park settings

    fun setAdmissionPrice(price: Double) {
        state.admissionPrice = SimMath.clamp(price, 0.0, admissionPriceLimit)
        refreshUI()
    }

    /** The most the gate may charge: the game's ceiling, or a trial's cap when it sets a lower one. */
    val admissionPriceLimit: Double
        get() = minOf(Balance.admissionPriceMax, state.trial?.maxAdmission ?: Balance.admissionPriceMax)

    fun setUniformColour(colour: ParkColour) {
        state.uniformColour = colour
        refreshUI()
    }

    fun setSchemePrimary(colour: ParkColour) {
        state.scheme = state.scheme.copy(primary = colour)
        refreshUI()
    }

    fun setSchemeTrim(colour: ParkColour) {
        state.scheme = state.scheme.copy(trim = colour)
        refreshUI()
    }

    /** Repaints every piece of coaster track in the park, and the loops and corkscrews bolted to it. */
    fun setCoasterTrackColour(colour: ParkColour) {
        state.coasterTrackColour = colour
        refreshUI()
    }

    // endregion

    // region Building

    val selectedDefinition: BuildableDefinition?
        get() {
            val id = build.selectedID ?: return null
            return GameContent.allBuildables.firstOrNull { it.id == id }
        }

    fun enterBuildMode(category: BuildCategory) {
        build.isActive = true
        build.isDemolishing = false
        build.pending = null
        if (build.category != category) build.rideGroup = null
        build.category = category
        if (selectedDefinition?.category != category) {
            build.selectedID = GameContent.buildables(category, state.unlockLevel).firstOrNull()?.id
        }
        build.isDrawing = false
        refreshUI()
    }

    fun exitBuildMode() {
        build = BuildState()
        refreshUI()
    }

    /** The rides on show, once the chosen shelf is taken into account. */
    fun buildables(category: BuildCategory): List<BuildableDefinition> {
        val all = GameContent.buildables(category, state.unlockLevel)
        val group = build.rideGroup
        if (category != BuildCategory.attraction || group == null) return all
        return all.filter { (it as? AttractionDefinition)?.group == group }
    }

    fun showRideGroup(group: RideGroup?) {
        build.rideGroup = group
        refreshUI()
    }

    /** How many ways the selected thing can be drawn, or 1 when there is only the one. */
    val styleCount: Int get() = selectedDefinition?.previewAppearance?.motif?.variantCount ?: 1

    /** Colours on offer for the selected thing: flowers, so far. */
    val colourChoices: List<ParkColour> get() = selectedDefinition?.previewAppearance?.motif?.colourChoices ?: emptyList()

    fun chooseColour(colour: ParkColour?) {
        build.colour = colour
        refreshUI()
    }

    /** Null means mixed: every one placed picks its own style. */
    fun chooseStyle(variant: Int?) {
        build.variant = variant
        refreshUI()
    }

    /** Whether turning would change anything. Only offered on a placement that is waiting to be confirmed. */
    val canRotate: Boolean
        get() {
            if (!build.isActive || build.isDemolishing || build.pending == null) return false
            return pendingDefinition?.canRotate ?: false
        }

    /** Whether the thing chosen in the menu can be turned before it is put down. */
    val canTurnSelection: Boolean
        get() {
            if (!build.isActive || build.isDemolishing || build.pending != null) return false
            return selectedDefinition?.canRotate ?: false
        }

    /** What the next thing placed will face, for the label on the turn button. */
    val facingName: String get() = listOf("Up", "Right", "Down", "Left")[((build.rotation % 4) + 4) % 4]

    fun turnSelection() {
        if (!canTurnSelection) return
        build.rotation = selectedDefinition?.nextTurn(build.rotation) ?: 0
        updateGhost(build.ghost)
    }

    /** The ground the current selection would take up, turned. */
    val ghostFootprint: GridSize
        get() = selectedDefinition?.footprint(build.rotation) ?: GridSize.single

    fun select(definitionID: String) {
        build.selectedID = definitionID
        build.isDemolishing = false
        build.pending = null
        build.variant = null
        build.colour = null
        // Carried over from the last thing chosen, which may have been turned somewhere this one is not allowed to go.
        selectedDefinition?.let { build.rotation = it.settledTurn(build.rotation) }
        if (!canDraw) build.isDrawing = false
        refreshUI()
    }

    /** Only terrain is worth dragging out in a run. */
    val canDraw: Boolean
        get() = build.isActive && !build.isDemolishing && selectedDefinition is TerrainDefinition

    fun toggleDrawing() {
        if (!canDraw) return
        build.isDrawing = !build.isDrawing
        refreshUI()
    }

    fun enterDemolishMode() {
        build.isActive = true
        build.isDemolishing = true
        build.pending = null
        build.isDrawing = false
        build.selectedID = null
        refreshUI()
    }

    /** Updates the placement preview as the player's finger moves. */
    fun updateGhost(coord: GridCoord?) {
        build.ghost = coord
        if (coord == null) {
            build.ghostValid = false
            build.ghostReason = null
            return
        }

        if (build.isDemolishing) {
            val refund = state.demolitionRefund(coord)
            build.ghostValid = refund > 0 || state.map.tile(coord)?.terrain == TerrainType.path
            build.ghostReason = if (build.ghostValid) null else "Nothing to remove"
            return
        }

        val definition = selectedDefinition
        if (definition == null) {
            build.ghostValid = false
            build.ghostReason = null
            return
        }

        val check = state.placementCheck(definition, coord, build.rotation)
        build.ghostValid = check.isValid
        build.ghostReason = check.reason
    }

    // endregion

    // region Placement, in two steps

    /** Anything bigger than a tile is worth seeing in place before paying for it. */
    private fun needsConfirmation(definition: BuildableDefinition): Boolean {
        if (definition is TerrainDefinition) return false
        return definition.footprint.tileCount > 1
    }

    val pendingDefinition: BuildableDefinition?
        get() {
            val pending = build.pending ?: return null
            return GameContent.allBuildables.firstOrNull { it.id == pending.definitionID }
        }

    /** Whether the pending placement would be allowed, and why not if it would not. */
    val pendingCheck: PlacementCheck?
        get() {
            val pending = build.pending ?: return null
            val definition = pendingDefinition ?: return null
            return state.placementCheck(definition, pending.origin, pending.rotation)
        }

    /** Ground the pending placement would take up. */
    val pendingFootprint: GridSize
        get() {
            val pending = build.pending ?: return GridSize.single
            val definition = pendingDefinition ?: return GridSize.single
            return definition.footprint(pending.rotation)
        }

    /** Slides the waiting placement one tile. */
    fun nudgePending(dx: Int, dy: Int) {
        val pending = build.pending ?: return
        val moved = GridCoord(pending.origin.x + dx, pending.origin.y + dy)
        if (!state.map.isInside(moved)) return
        pending.origin = moved
        updateGhost(moved)
        refreshUI()
    }

    /** Puts the waiting placement somewhere else outright, for dragging it around the map. */
    fun movePending(origin: GridCoord) {
        val pending = build.pending ?: return
        if (pending.origin == origin || !state.map.isInside(origin)) return
        pending.origin = origin
        updateGhost(origin)
    }

    /** Whether [definition] could stand at [origin] turned this way, leaving cash out of it. */
    private fun fits(definition: BuildableDefinition, origin: GridCoord, rotation: Int): Boolean =
        PlacementValidator.check(definition, origin, rotation, state.map, Double.POSITIVE_INFINITY, 0.0).isValid

    fun rotatePending() {
        val pending = build.pending ?: return
        val definition = pendingDefinition ?: return
        if (!definition.canRotate) return

        // A turn that would leave the building overlapping its neighbours is refused; a placement
        // that is already in the way can still be turned while it is being moved.
        val fitsNow = fits(definition, pending.origin, pending.rotation)
        val next = definition.nextTurn(pending.rotation)
        if (fitsNow && !fits(definition, pending.origin, next)) {
            notice = "No room to turn it here."
            refreshUI()
            return
        }
        pending.rotation = next
        // Carried into the next placement, so a row of benches all face the same way.
        build.rotation = pending.rotation
        refreshUI()
    }

    fun confirmPending(): Boolean {
        val pending = build.pending ?: return false
        val definition = pendingDefinition ?: return false
        if (!state.place(definition, pending.origin, pending.rotation, build.variant, build.colour)) return false
        build.pending = null
        refreshUI()
        return true
    }

    fun cancelPending() {
        build.pending = null
        refreshUI()
    }

    /** A tap on the map. In build mode it places or removes; otherwise it inspects whatever is under the finger. */
    fun handleTap(coord: GridCoord, guestID: UUID?, staffID: UUID? = null) {
        // Choosing where to send somebody: every tap is an answer to that.
        if (movingStaffID != null) {
            stageStaffMove(coord)
            refreshUI()
            return
        }

        if (build.isActive) {
            if (build.isDemolishing) {
                requestDemolition(coord)
            } else {
                val definition = selectedDefinition
                if (definition != null) {
                    if (needsConfirmation(definition)) {
                        // Lines up the placement and waits. Nothing is charged until confirmed.
                        build.pending = PendingPlacement(definition.id, coord, build.rotation)
                    } else {
                        state.place(definition, coord, build.rotation, build.variant, build.colour)
                    }
                }
            }
            updateGhost(coord)
            refreshUI()
            return
        }

        if (guestID != null) {
            selection = makeSelection(SelectionIdentity.Guest(guestID))
        } else if (staffID != null) {
            selection = makeSelection(SelectionIdentity.Staff(staffID))
        } else {
            val target = state.target(coord)
            if (target != null) {
                selection = when (target) {
                    is ParkTarget.Ride -> makeSelection(SelectionIdentity.Attraction(target.id))
                    is ParkTarget.Shop -> makeSelection(SelectionIdentity.Facility(target.id))
                    else -> null
                }
            } else {
                // Decoration is not a destination, but it can be edited.
                val item = state.sceneryItem(coord)
                selection = if (item != null) makeSelection(SelectionIdentity.Scenery(item.id)) else null
            }
        }
        refreshUI()
    }

    /**
     * Paint a run of path tiles as the finger drags. Every tile between the
     * last one painted and this one is laid too, so the run is joined up
     * whatever the finger did.
     */
    fun paint(coord: GridCoord) {
        if (!build.isActive || !build.isDrawing || build.isDemolishing) return
        val definition = selectedDefinition as? TerrainDefinition ?: return

        for (tile in tilesToPaint(coord)) state.place(definition, tile)
        lastPaintedTile = coord
        refreshUI()
    }

    /** Called when a drag begins or ends, so the next run starts afresh. */
    fun endPaint() {
        lastPaintedTile = null
    }

    private fun tilesToPaint(coord: GridCoord): List<GridCoord> {
        val from = lastPaintedTile
        if (from == null || from == coord || from.manhattanDistance(coord) > Balance.maxPaintGap) return listOf(coord)

        val run = ArrayList<GridCoord>()
        var current = from
        while (current != coord) {
            val dx = coord.x - current.x
            val dy = coord.y - current.y
            current = if (abs(dx) >= abs(dy)) GridCoord(current.x + (if (dx > 0) 1 else -1), current.y)
            else GridCoord(current.x, current.y + (if (dy > 0) 1 else -1))
            run.add(current)
        }
        return run
    }

    private fun requestDemolition(coord: GridCoord) {
        val refund = state.demolitionRefund(coord)

        val name: String
        val target = state.target(coord)
        val item = state.sceneryItem(coord)
        if (target != null) {
            name = state.displayName(target)
        } else if (item != null) {
            name = item.definition?.displayName ?: "this decoration"
        } else {
            // Paths are cheap; remove without ceremony.
            state.demolish(coord)
            return
        }

        if (refund >= 500) {
            pendingDemolition = PendingDemolition(coord, name, refund)
        } else {
            state.demolish(coord)
        }
    }

    fun confirmPendingDemolition() {
        val pending = pendingDemolition ?: return
        state.demolish(pending.coord)
        pendingDemolition = null
        selection = null
        refreshUI()
    }

    fun cancelPendingDemolition() {
        pendingDemolition = null
        refreshUI()
    }

    // endregion

    // region Inspection commands

    fun clearSelection() {
        selection = null
        refreshUI()
    }

    fun focus(target: ParkTarget) {
        when (target) {
            is ParkTarget.Ride -> {
                selection = makeSelection(SelectionIdentity.Attraction(target.id))
                state.attraction(target.id)?.let { lookAt(centre(it.rect)) }
            }
            is ParkTarget.Shop -> {
                selection = makeSelection(SelectionIdentity.Facility(target.id))
                state.facility(target.id)?.let { lookAt(centre(it.rect)) }
            }
            else -> {}
        }
        refreshUI()
    }

    /** Takes the player to an employee in the park and selects them. */
    fun focusStaff(id: UUID) {
        val member = state.staffMember(id) ?: return
        selection = makeSelection(SelectionIdentity.Staff(id))
        lookAt(member.position)
        refreshUI()
    }

    private fun centre(rect: GridRect): Vec2 = Vec2(rect.origin.x + rect.size.width / 2.0, rect.origin.y + rect.size.height / 2.0)

    private fun lookAt(tile: Vec2) {
        cameraRequest = CameraRequest(tile)
    }

    /**
     * Removes whatever is selected, if it is something that can be removed.
     * Always asks first for a ride or a facility.
     */
    fun removeSelected() {
        val identity = selection?.identity ?: return

        val coord: GridCoord
        val name: String
        val alwaysAsk: Boolean
        when (identity) {
            is SelectionIdentity.Attraction -> {
                val attraction = state.attraction(identity.id) ?: return
                coord = attraction.origin
                name = attraction.name
                alwaysAsk = true
            }
            is SelectionIdentity.Facility -> {
                val facility = state.facility(identity.id) ?: return
                coord = facility.origin
                name = facility.name
                alwaysAsk = true
            }
            is SelectionIdentity.Scenery -> {
                val item = state.scenery.firstOrNull { it.id == identity.id } ?: return
                coord = item.origin
                name = item.definition?.displayName ?: "this decoration"
                alwaysAsk = false
            }
            is SelectionIdentity.Guest, is SelectionIdentity.Staff -> return
        }

        val refund = state.demolitionRefund(coord)
        if (alwaysAsk || refund >= 500) {
            pendingDemolition = PendingDemolition(coord, name, refund)
        } else {
            state.demolish(coord)
            selection = null
        }
        refreshUI()
    }

    /** Whether the selection is something the Remove button applies to. */
    val canRemoveSelected: Boolean
        get() = when (selection?.identity) {
            is SelectionIdentity.Attraction, is SelectionIdentity.Facility, is SelectionIdentity.Scenery -> true
            else -> false
        }

    /** Turns whatever is selected a quarter, if there is room for it. */
    fun turnSelected() {
        val identity = selection?.identity ?: return
        val turned = when (identity) {
            is SelectionIdentity.Scenery -> state.turnScenery(identity.id)
            is SelectionIdentity.Facility -> state.turnFacility(identity.id)
            is SelectionIdentity.Attraction -> state.turnAttraction(identity.id)
            is SelectionIdentity.Guest, is SelectionIdentity.Staff -> return
        }
        if (!turned) notice = "No room to turn that here."
        refreshUI()
    }

    fun setSceneryStyle(variant: Int) {
        val identity = selection?.identity as? SelectionIdentity.Scenery ?: return
        state.setSceneryStyle(variant, identity.id)
        refreshUI()
    }

    fun setSceneryColour(colour: ParkColour?) {
        val identity = selection?.identity as? SelectionIdentity.Scenery ?: return
        state.setSceneryColour(colour, identity.id)
        refreshUI()
    }

    fun setRideOpen(isOpen: Boolean, attractionID: UUID) {
        val attraction = state.attraction(attractionID) ?: return
        attraction.isOpen = isOpen
        if (!isOpen) releaseQueue(attraction)
        refreshUI()
    }

    /** Repaints one ride. Null puts it back to the colours it was designed in. */
    fun setRideTint(colour: ParkColour?, attractionID: UUID) {
        state.attraction(attractionID)?.tint = colour
        refreshUI()
    }

    fun setCoasterLivery(colour: ParkColour, attractionID: UUID) {
        state.attraction(attractionID)?.livery = colour
        refreshUI()
    }

    fun setCoasterCarStyle(style: CoasterCarStyle, attractionID: UUID) {
        state.attraction(attractionID)?.carStyle = style
        refreshUI()
    }

    fun rename(attractionID: UUID, name: String) {
        val attraction = state.attraction(attractionID) ?: return
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return
        attraction.name = trimmed
        refreshUI()
    }

    /** Why guests are, or are not, coming to a facility, judged against the guest currently closest to it. */
    fun guestInterest(facilityID: UUID): String? {
        val facility = state.facility(facilityID) ?: return null
        val definition = facility.definition ?: return "This build no longer has this kind of building"

        val access = state.map.accessTiles(facility.rect)
        if (access.isEmpty()) return FacilityAppeal.Verdict.NoWalkway.summary

        val candidates = state.guests.filter { it.isActive }
        if (candidates.isEmpty()) return "No guests in the park yet"

        val centre = Vec2(facility.origin.x + facility.size.width / 2.0, facility.origin.y + facility.size.height / 2.0)
        val nearest = candidates.minByOrNull { SimMath.distance(it.position, centre) } ?: return null

        val distance = engine.pathfinder.distance(nearest.tile, access, state.map)
        return FacilityAppeal.evaluate(facility, definition, nearest, true, distance, state.adBoosts.spendFactor).summary
    }

    fun setFacilityOpen(isOpen: Boolean, facilityID: UUID) {
        state.facility(facilityID)?.isOpen = isOpen
        refreshUI()
    }

    fun setPrice(price: Double, facilityID: UUID) {
        val facility = state.facility(facilityID) ?: return
        facility.price = maxOf(0.0, price)
        // Sentiment is a rolling average; reset it so the readout reflects the new price.
        facility.sentimentSum = 0.0
        facility.sentimentCount = 0
        refreshUI()
    }

    private fun releaseQueue(attraction: Attraction) {
        val queued = attraction.queue.toList()
        attraction.queue = mutableListOf()
        for (guestID in queued) {
            val guest = state.guest(guestID) ?: continue
            guest.activity = GuestActivity.Exploring
            guest.nextDecisionAt = state.clock.simTime
            guest.adjustHappiness(-Balance.happinessQueueAbandonPenalty)
            guest.think("They closed the ride while I was waiting.", ThoughtMood.negative, state.clock.simTime)
        }
    }

    // endregion

    // region Staff

    fun canHire(role: StaffRole): Boolean {
        val definition = StaffContent.definition(role) ?: return false
        return state.ledger.canAfford(definition.hiringCost) && state.staff.size < Balance.maxStaff
    }

    fun hireStaff(role: StaffRole, style: StaffStyle = StaffStyle.standard): Boolean {
        val definition = StaffContent.definition(role) ?: return false
        if (!canHire(role)) return false

        state.ledger.spend(definition.hiringCost, ExpenseCategory.wages)

        val entrance = state.map.entranceCoord
        val member = Staff(id = UUID.randomUUID(), name = GuestNames.random(state.rng), role = role,
            position = entrance.centre, tile = entrance)

        when (role) {
            StaffRole.entertainer -> {
                member.act = style.act
                member.primaryColour = style.primary
            }
            StaffRole.mascot -> {
                // A mascot is a character, so it is named like one.
                val costume = style.costume ?: MascotCostume.bear
                member.costume = costume
                member.name = costume.name(state.rng)
                member.primaryColour = style.primary
                member.secondaryColour = style.secondary
                member.trimColour = style.trim
            }
            else -> {}
        }

        state.staff.add(member)
        refreshUI()
        return true
    }

    // endregion

    // region Moving staff

    /** Starts choosing where to move the selected employee to. */
    fun beginMovingStaff() {
        val identity = selection?.identity as? SelectionIdentity.Staff ?: return
        build = BuildState()
        movingStaffID = identity.id
        pendingStaffMove = null
        refreshUI()
    }

    fun cancelStaffMove() {
        movingStaffID = null
        pendingStaffMove = null
        refreshUI()
    }

    /** Marks a spot, for the player to confirm or change their mind about. */
    private fun stageStaffMove(coord: GridCoord) {
        if (!state.map.isWalkable(coord)) {
            notice = "Staff can only stand on a walkway."
            return
        }
        pendingStaffMove = coord
    }

    fun confirmStaffMove() {
        val id = movingStaffID
        val coord = pendingStaffMove
        val member = id?.let { state.staffMember(it) }
        if (id == null || coord == null || member == null) {
            cancelStaffMove()
            return
        }

        // Whatever they were doing is dropped, and the order is what they pick up next.
        member.activity = StaffActivity.Idle
        member.route = mutableListOf()
        member.transfer = null
        member.orders = StaffJob.GoTo(coord)
        member.nextJobSearchAt = state.clock.simTime

        cancelStaffMove()
    }

    /** Sends somebody who was told to hold a spot back to their usual work. */
    fun releaseStaff(id: UUID) {
        val member = state.staffMember(id) ?: return
        member.activity = StaffActivity.Idle
        member.route = mutableListOf()
        member.transfer = null
        member.orders = null
        member.nextJobSearchAt = state.clock.simTime
        refreshUI()
    }

    val movingStaffName: String? get() = movingStaffID?.let { state.staffMember(it)?.name }

    /** Changes how an entertainer or a mascot looks. */
    fun setStaffStyle(id: UUID, style: StaffStyle) {
        val member = state.staffMember(id) ?: return
        when (member.role) {
            StaffRole.entertainer -> {
                member.act = style.act
                member.primaryColour = style.primary
            }
            StaffRole.mascot -> {
                member.costume = style.costume
                member.primaryColour = style.primary
                member.secondaryColour = style.secondary
                member.trimColour = style.trim
            }
            else -> return
        }
        refreshUI()
    }

    fun fireStaff(id: UUID) {
        if (movingStaffID == id) cancelStaffMove()
        state.staff.removeAll { it.id == id }
        if ((selection?.identity as? SelectionIdentity.Staff)?.id == id) selection = null
        refreshUI()
    }

    // endregion

    // region Upgrades

    /** What the next level of an upgrade costs on a ride, or null when it is already at its maximum. */
    fun upgradeCost(kind: RideUpgradeKind, attractionID: UUID): Double? {
        val attraction = state.attraction(attractionID) ?: return null
        val definition = UpgradeContent.rideUpgrade(kind) ?: return null
        val base = attraction.baseDefinition ?: return null
        val next = attraction.upgradeLevel(kind) + 1
        if (next > definition.maxLevel) return null
        return definition.cost(next, base.purchasePrice)
    }

    fun canAffordUpgrade(kind: RideUpgradeKind, attractionID: UUID): Boolean {
        val cost = upgradeCost(kind, attractionID) ?: return false
        return state.ledger.canAfford(cost)
    }

    fun buyUpgrade(kind: RideUpgradeKind, attractionID: UUID): Boolean {
        val cost = upgradeCost(kind, attractionID) ?: return false
        if (!state.ledger.canAfford(cost)) return false
        val attraction = state.attraction(attractionID) ?: return false

        state.ledger.spend(cost, ExpenseCategory.construction)
        attraction.upgrades[kind.name] = attraction.upgradeLevel(kind) + 1
        state.statistics.upgradesBoughtTotal += 1

        // Theming decorates the ground around the ride.
        if (kind == RideUpgradeKind.theming) state.refreshBeauty()

        refreshUI()
        return true
    }

    fun shopUpgradeCost(kind: ShopUpgradeKind, facilityID: UUID): Double? {
        val facility = state.facility(facilityID) ?: return null
        val base = facility.baseDefinition ?: return null
        if (!base.acceptsUpgrades) return null
        val next = facility.upgradeLevel(kind) + 1
        if (next > kind.maxLevel) return null
        return kind.cost(next, base.purchasePrice)
    }

    fun buyShopUpgrade(kind: ShopUpgradeKind, facilityID: UUID): Boolean {
        val cost = shopUpgradeCost(kind, facilityID) ?: return false
        if (!state.ledger.canAfford(cost)) return false
        val facility = state.facility(facilityID) ?: return false

        state.ledger.spend(cost, ExpenseCategory.construction)
        facility.upgrades[kind.name] = facility.upgradeLevel(kind) + 1
        state.statistics.upgradesBoughtTotal += 1

        refreshUI()
        return true
    }

    /** What paving the next stretch of car park costs, or null once it is finished. */
    fun carParkUpgradeCost(): Double? = CarParkContent.cost(state.carParkLevel + 1)

    fun upgradeCarPark(): Boolean {
        val cost = carParkUpgradeCost() ?: return false
        if (!state.ledger.canAfford(cost)) return false
        state.ledger.spend(cost, ExpenseCategory.construction)
        state.carParkLevel += 1
        refreshUI()
        return true
    }

    /** What the next level of training costs for one employee, or null when they have had all of it. */
    fun trainingCost(staffID: UUID): Double? {
        val member = state.staffMember(staffID) ?: return null
        val definition = member.definition ?: return null
        val next = member.trainingLevel + 1
        if (next > UpgradeContent.staffTraining.maxLevel) return null
        return UpgradeContent.staffTraining.cost(next, definition.hiringCost)
    }

    fun trainStaff(id: UUID): Boolean {
        val cost = trainingCost(id) ?: return false
        if (!state.ledger.canAfford(cost)) return false
        val member = state.staffMember(id) ?: return false

        state.ledger.spend(cost, ExpenseCategory.wages)
        member.trainingLevel += 1
        refreshUI()
        return true
    }

    // endregion

    // region Dashboards

    fun makeFinanceSnapshot() = FinanceSnapshot(state.ledger)

    /** The columns behind the finance chart. */
    fun makeFinanceSeries(range: FinanceRange) = FinanceSeriesBuilder.points(state.ledger.history, range)

    fun makeDashboardSnapshot() = DashboardSnapshot(state, engine.ratingBreakdown(state))

    fun makeAchievementProgress() = AchievementSystem.progress(state)

    // endregion

    // region Saving

    fun save() {
        saveMessage = try {
            services.saveService.save(state, location)
            "Park saved."
        } catch (e: Exception) {
            "Could not save: ${e.message}"
        }
        refreshUI()
    }

    private fun autosave() {
        runCatching { services.saveService.save(state, location) }
    }

    fun saveOnBackground() {
        if (!isDemo) autosave()
    }

    fun clearSaveMessage() {
        saveMessage = null
        notice = null
        refreshUI()
    }

    // endregion

    // region UI snapshots

    /** Dismissed by the celebration view once its animation has run. */
    fun dismissCelebration() {
        celebration = null
        celebrationShownAt = null
        refreshUI()
    }

    fun refreshUI() {
        applyBoosts()
        hud = HUDSnapshot.of(state)

        if (celebration == null && state.pendingAwards.isNotEmpty()) {
            celebration = state.pendingAwards.removeAt(0)
            celebrationShownAt = services.now()
            celebrationRemaining = 1.0
        }
        expireCards()
        drainTrialResult()
        drainEvents()
        alerts = state.alerts.takeLast(12).reversed()

        selection?.identity?.let { selection = makeSelection(it) }

        refreshTutorial()
        uiVersion += 1
    }

    // endregion

    // region Tips

    /** The park behind the main menu never teaches anybody anything. */
    private fun refreshTutorial() {
        if (isDemo) return
        if (services.tutorial.evaluate(tutorialSignals())) currentTip = services.tutorial.current
    }

    private fun tutorialSignals(): TutorialSignals {
        val signals = TutorialSignals()
        signals.day = state.clock.day
        signals.minutesPlayed = state.clock.simTime / 60
        signals.guestCount = state.guestCount
        signals.cash = state.ledger.cash
        signals.averageHappiness = state.averageHappiness
        signals.rideCount = state.attractions.size
        signals.staffCount = state.staff.size
        signals.mechanicCount = state.staffCount(StaffRole.mechanic)
        signals.janitorCount = state.staffCount(StaffRole.janitor)
        signals.litteredTiles = state.map.litteredTiles.size
        signals.brokenRides = state.attractions.count { it.isBroken }
        signals.longestQueue = state.attractions.maxOfOrNull { it.queue.size } ?: 0
        signals.isBuilding = build.isActive
        signals.isPlacing = build.pending != null
        signals.isFreeBuild = state.mode.hasUnlimitedMoney
        signals.isTrial = state.mode == GameMode.trial
        signals.securityCount = state.staffCount(StaffRole.security)
        signals.sceneryCount = state.scenery.size
        signals.impoundedRides = state.attractions.count { it.isImpounded }

        for (facility in state.facilities) {
            val definition = facility.definition ?: continue
            if (definition.acceptsUpgrades && facility.upgrades.isEmpty()) signals.unimprovedShops += 1
            when (definition.kind) {
                FacilityKind.food, FacilityKind.drink -> signals.shopCount += 1
                FacilityKind.game -> signals.boothCount += 1
                FacilityKind.bench -> signals.benchCount += 1
                FacilityKind.bathroom -> signals.hasRestroom = true
                FacilityKind.bin -> signals.hasBin = true
                FacilityKind.souvenir -> {}
            }
        }

        return signals
    }

    /**
     * Shows a trial's end, and records a win on the ladder. Recorded here
     * rather than in the simulation: the ladder belongs to the player.
     */
    private fun drainTrialResult() {
        if (trialResult != null || isDemo) return
        val result = state.pendingTrialResult ?: return
        state.pendingTrialResult = null

        var isFirstWin = false
        val trial = result.trial
        if (result.won && trial != null) isFirstWin = services.trialProgress.recordWin(trial, result.day)
        val next = trial?.let { current -> TrialContent.all.firstOrNull { it.number == current.number + 1 } }
        trialResult = TrialResultReport(result, isFirstWin, next)
        // Saved at once, so a win is never lost to the app closing on the card that announced it.
        autosave()
    }

    fun dismissTrialResult() {
        trialResult = null
        refreshUI()
    }

    /** Carries the player's boosts into the park, and takes them away again when they lapse. */
    private fun applyBoosts() {
        // Re-read every refresh, so a point moved in the perk tree is felt straight away.
        val perks = services.perkStore.bonuses
        if (state.perks != perks) state.perks = perks

        val effects = AdBoostEffects.from { services.boosts.isActive(it) }
        if (state.adBoosts != effects) state.adBoosts = effects
        if (state.clock.speed.needsBoost && !isTurboUnlocked) {
            state.clock.speed = GameSpeed.veryFast
            engine.resetTiming()
            services.boosts.refresh()
        }
    }

    /** Retires a card once it has had its time. */
    private fun expireCards() {
        val now = services.now()
        celebrationShownAt?.let {
            celebrationRemaining = maxOf(0.0, 1 - (now - it) / 1000.0 / celebrationDwell)
            if (celebrationRemaining <= 0) {
                celebration = null
                celebrationShownAt = null
            }
        }
        eventShownAt?.let {
            eventRemaining = maxOf(0.0, 1 - (now - it) / 1000.0 / eventDwell)
            if (eventRemaining <= 0) {
                event = null
                eventShownAt = null
            }
        }
    }

    /** Order is a priority: something that shut a ride matters more than something that filled the gate. */
    private fun drainEvents() {
        if (event != null) return
        event = when {
            state.pendingEjections.isNotEmpty() -> ParkEvent.Ejection(state.pendingEjections.removeAt(0))
            state.pendingReviews.isNotEmpty() -> ParkEvent.Review(state.pendingReviews.removeAt(0))
            state.pendingInspections.isNotEmpty() -> ParkEvent.Inspection(state.pendingInspections.removeAt(0))
            state.pendingPromotions.isNotEmpty() -> ParkEvent.Promotion(state.pendingPromotions.removeAt(0))
            state.pendingTourBuses.isNotEmpty() -> ParkEvent.TourBus(state.pendingTourBuses.removeAt(0))
            else -> null
        }
        if (event != null) {
            eventShownAt = services.now()
            eventRemaining = 1.0
        }
    }

    /** Dismissed by the event's card once it has been read, or by its own time running out. */
    fun dismissEvent() {
        event = null
        eventShownAt = null
        refreshUI()
    }

    /** The player has read the tip on screen. */
    fun dismissTip() {
        services.tutorial.dismissCurrent()
        currentTip = null
        refreshUI()
    }

    val tipsEnabled: Boolean get() = services.tutorial.isEnabled

    fun setTipsEnabled(enabled: Boolean) {
        services.tutorial.setEnabled(enabled)
        currentTip = services.tutorial.current
        refreshUI()
    }

    /** Offers every tip again, for a player handing the game to somebody else. */
    fun resetTips() {
        services.tutorial.reset()
        currentTip = null
        refreshUI()
    }

    val tipsReadText: String get() = "${services.tutorial.tipsRead} of ${services.tutorial.tipsTotal} read"

    private fun makeSelection(identity: SelectionIdentity): SelectionDetail? = when (identity) {
        is SelectionIdentity.Guest -> state.guest(identity.id)?.let { SelectionDetail.OfGuest(GuestDetail(it, state)) }
        is SelectionIdentity.Attraction -> state.attraction(identity.id)?.let { SelectionDetail.OfAttraction(AttractionDetail(it)) }
        is SelectionIdentity.Facility -> state.facility(identity.id)?.let { SelectionDetail.OfFacility(FacilityDetail(it)) }
        is SelectionIdentity.Staff -> state.staffMember(identity.id)?.let { SelectionDetail.OfStaff(StaffDetail(it, state)) }
        is SelectionIdentity.Scenery ->
            state.scenery.firstOrNull { it.id == identity.id }?.let { SelectionDetail.OfScenery(SceneryDetail(it, state.scheme)) }
    }

    // endregion

    companion object {
        /** The park that runs behind the main menu. */
        fun demo(services: Services): GameController =
            GameController(DemoPark.makeState(), SaveLocation.Slot(-1), services, isDemo = true)
    }
}
