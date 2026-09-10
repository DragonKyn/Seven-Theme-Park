import Combine
import Foundation
import SwiftUI

/// Owns the running park and is the only thing the UI talks to.
///
/// SwiftUI observes cheap snapshot structs published from here rather than the
/// simulation itself, so a 40-tick-per-second simulation does not force the
/// view tree to re-evaluate 40 times a second.
@MainActor
final class GameController: ObservableObject {

    // MARK: - Published UI state

    @Published private(set) var hud = HUDSnapshot()
    @Published private(set) var selection: SelectionDetail?
    @Published private(set) var alerts: [ParkAlert] = []
    @Published var build = BuildState()
    @Published var pendingDemolition: PendingDemolition?
    @Published private(set) var saveMessage: String?
    /// The award currently being celebrated on screen, if any. Awards queue in
    /// the park and are shown one at a time, because two party poppers at once
    /// is not twice as good.
    @Published private(set) var celebration: AchievementAward?

    // MARK: - Simulation

    private(set) var state: GameState
    private let engine = SimulationEngine()
    private let saveService: SaveGameService
    private(set) var slot: Int
    /// A demo controller drives the park behind the main menu. It simulates
    /// normally but never writes a save, and nothing routes input to it.
    let isDemo: Bool

    private var uiRefreshAccumulator: Double = 0
    private var autosaveAccumulator: Double = 0
    private static let uiRefreshInterval: Double = 0.2

    // MARK: - Init

    init(state: GameState,
         slot: Int,
         saveService: SaveGameService = SaveGameService(),
         isDemo: Bool = false) {
        self.state = state
        self.slot = slot
        self.saveService = saveService
        self.isDemo = isDemo
        refreshUI()
    }

    /// The park that runs behind the main menu.
    static func demo() -> GameController {
        GameController(state: DemoPark.makeState(), slot: -1, isDemo: true)
    }

    convenience init(newParkNamed name: String,
                     mode: GameMode,
                     slot: Int,
                     saveService: SaveGameService = SaveGameService()) {
        self.init(state: GameState(parkName: name, mode: mode),
                  slot: slot,
                  saveService: saveService)
    }

    // MARK: - Frame driving

    /// Called once per rendered frame by `ParkScene`.
    func advance(realDelta: Double) {
        let ticks = engine.advance(state: state, realDelta: realDelta)

        uiRefreshAccumulator += realDelta
        if uiRefreshAccumulator >= Self.uiRefreshInterval {
            uiRefreshAccumulator = 0
            refreshUI()
        }

        guard ticks > 0, !isDemo else { return }
        autosaveAccumulator += Double(ticks) * Balance.tickDuration
        if autosaveAccumulator >= Balance.autosaveInterval {
            autosaveAccumulator = 0
            autosave()
        }
    }

    // MARK: - Speed

    func setSpeed(_ speed: GameSpeed) {
        state.clock.speed = speed
        engine.resetTiming()
        refreshUI()
    }

    func togglePause() {
        setSpeed(state.clock.speed == .paused ? .normal : .paused)
    }

    // MARK: - Park settings

    func setAdmissionPrice(_ price: Double) {
        state.admissionPrice = SimMath.clamp(price, 0, Balance.admissionPriceMax)
        refreshUI()
    }

    /// Colours every employee in the park. Cheap and instant: it changes how
    /// staff are drawn and nothing else.
    func setUniformColour(_ colour: ParkColour) {
        state.uniformColour = colour
        refreshUI()
    }

    // MARK: - Building

    var selectedDefinition: BuildableDefinition? {
        guard let id = build.selectedID else { return nil }
        return GameContent.allBuildables.first { $0.id == id }
    }

    func enterBuildMode(category: BuildCategory) {
        build.isActive = true
        build.isDemolishing = false
        build.pending = nil
        if build.category != category { build.rideGroup = nil }
        build.category = category
        if selectedDefinition?.category != category {
            build.selectedID = GameContent.buildables(in: category, unlockLevel: state.unlockLevel).first?.id
        }
        build.isDrawing = false
    }

    func exitBuildMode() {
        build = BuildState()
    }

    /// The rides on show, once the chosen shelf is taken into account.
    ///
    /// Filed here rather than in the view because picking a shelf can empty
    /// the list, and the view should not be the thing that decides what to do
    /// about that.
    func buildables(in category: BuildCategory) -> [BuildableDefinition] {
        let all = GameContent.buildables(in: category, unlockLevel: state.unlockLevel)
        guard category == .attraction, let group = build.rideGroup else { return all }
        return all.filter { ($0 as? AttractionDefinition)?.group == group }
    }

    func showRideGroup(_ group: RideGroup?) {
        build.rideGroup = group
    }

    /// Whether turning would change anything. Only ever offered on a
    /// placement that is waiting to be confirmed, because that is the only
    /// point at which the player can see what they are turning.
    var canRotate: Bool {
        guard build.isActive, !build.isDemolishing, build.pending != nil else { return false }
        return pendingDefinition?.canRotate ?? false
    }

    /// The ground the current selection would take up, turned. The preview and
    /// the placement rules both read this so they can never disagree.
    var ghostFootprint: GridSize {
        guard let definition = selectedDefinition else { return .single }
        return definition.footprint(rotatedBy: build.rotation)
    }

    func select(definitionID: String) {
        build.selectedID = definitionID
        build.isDemolishing = false
        build.pending = nil
        if !canDraw { build.isDrawing = false }
    }

    /// Only terrain is worth dragging out in a run: a walkway or the edge of
    /// a pond. Everything else is placed one tap at a time.
    var canDraw: Bool {
        build.isActive && !build.isDemolishing && selectedDefinition is TerrainDefinition
    }

    func toggleDrawing() {
        guard canDraw else { return }
        build.isDrawing.toggle()
    }

    func enterDemolishMode() {
        build.isActive = true
        build.isDemolishing = true
        build.pending = nil
        build.isDrawing = false
        build.selectedID = nil
    }

    /// Updates the placement preview as the player's finger moves.
    func updateGhost(at coord: GridCoord?) {
        build.ghost = coord
        guard let coord else {
            build.ghostValid = false
            build.ghostReason = nil
            return
        }

        if build.isDemolishing {
            let refund = state.demolitionRefund(at: coord)
            build.ghostValid = refund > 0 || state.map.tile(at: coord)?.terrain == .path
            build.ghostReason = build.ghostValid ? nil : "Nothing to remove"
            return
        }

        guard let definition = selectedDefinition else {
            build.ghostValid = false
            build.ghostReason = nil
            return
        }

        let check = state.placementCheck(for: definition, at: coord, rotation: build.rotation)
        build.ghostValid = check.isValid
        build.ghostReason = check.reason
    }

    // MARK: - Placement, in two steps

    /// Whether this is something worth looking at before paying for it.
    ///
    /// A tree or a bin is one tile, cheap, and has no orientation to get
    /// wrong, so those still go down on a tap. Anything bigger or anything
    /// that can be turned is worth seeing in place first: getting a ride the
    /// wrong way round and paying for the privilege is not a decision anybody
    /// meant to make.
    private func needsConfirmation(_ definition: BuildableDefinition) -> Bool {
        guard !(definition is TerrainDefinition) else { return false }
        return definition.canRotate || definition.footprint.tileCount > 1
    }

    var pendingDefinition: BuildableDefinition? {
        guard let pending = build.pending else { return nil }
        return GameContent.allBuildables.first { $0.id == pending.definitionID }
    }

    /// Whether the pending placement would be allowed, and why not if it
    /// would not. Checked continuously, because the park can change under it.
    var pendingCheck: PlacementCheck? {
        guard let pending = build.pending, let definition = pendingDefinition else { return nil }
        return state.placementCheck(for: definition,
                                    at: pending.origin,
                                    rotation: pending.rotation)
    }

    /// Ground the pending placement would take up.
    var pendingFootprint: GridSize {
        guard let pending = build.pending, let definition = pendingDefinition else { return .single }
        return definition.footprint(rotatedBy: pending.rotation)
    }

    func rotatePending() {
        guard var pending = build.pending,
              let definition = pendingDefinition,
              definition.canRotate else { return }
        pending.rotation = (pending.rotation + 1) % 4
        // Carried into the next placement, so a row of benches all face the
        // same way without being turned one at a time.
        build.rotation = pending.rotation
        build.pending = pending
    }

    @discardableResult
    func confirmPending() -> Bool {
        guard let pending = build.pending, let definition = pendingDefinition else { return false }
        guard state.place(definition, at: pending.origin, rotation: pending.rotation) else {
            return false
        }
        build.pending = nil
        refreshUI()
        return true
    }

    func cancelPending() {
        build.pending = nil
    }

    /// A tap on the map. In build mode it places or removes; otherwise it
    /// inspects whatever is under the finger.
    func handleTap(at coord: GridCoord, guestID: UUID?, staffID: UUID? = nil) {
        if build.isActive {
            if build.isDemolishing {
                requestDemolition(at: coord)
            } else if let definition = selectedDefinition {
                if needsConfirmation(definition) {
                    // Lines up the placement and waits. Nothing is charged
                    // until the player has seen it standing there.
                    build.pending = PendingPlacement(definitionID: definition.id,
                                                     origin: coord,
                                                     rotation: build.rotation)
                } else {
                    _ = state.place(definition, at: coord, rotation: build.rotation)
                    refreshUI()
                }
            }
            updateGhost(at: coord)
            return
        }

        if let guestID {
            selection = makeSelection(.guest(guestID))
            return
        }
        if let staffID {
            selection = makeSelection(.staff(staffID))
            return
        }
        if let target = state.target(at: coord) {
            switch target {
            case .attraction(let id): selection = makeSelection(.attraction(id))
            case .facility(let id): selection = makeSelection(.facility(id))
            default: selection = nil
            }
            return
        }
        selection = nil
    }

    /// Paint a run of path tiles as the finger drags.
    func paint(at coord: GridCoord) {
        guard build.isActive, build.isDrawing, !build.isDemolishing,
              let definition = selectedDefinition,
              definition is TerrainDefinition else { return }
        _ = state.place(definition, at: coord)
        refreshUI()
    }

    private func requestDemolition(at coord: GridCoord) {
        let refund = state.demolitionRefund(at: coord)

        let name: String
        if let target = state.target(at: coord) {
            name = state.displayName(of: target)
        } else if let item = state.sceneryItem(at: coord) {
            name = item.definition?.displayName ?? "this decoration"
        } else {
            // Paths are cheap; remove without ceremony.
            if state.demolish(at: coord) { refreshUI() }
            return
        }

        if refund >= 500 {
            pendingDemolition = PendingDemolition(coord: coord, name: name, refund: refund)
        } else {
            _ = state.demolish(at: coord)
            refreshUI()
        }
    }

    func confirmPendingDemolition() {
        guard let pending = pendingDemolition else { return }
        _ = state.demolish(at: pending.coord)
        pendingDemolition = nil
        selection = nil
        refreshUI()
    }

    func cancelPendingDemolition() {
        pendingDemolition = nil
    }

    // MARK: - Inspection commands

    func clearSelection() {
        selection = nil
    }

    func focus(on target: ParkTarget) {
        switch target {
        case .attraction(let id): selection = makeSelection(.attraction(id))
        case .facility(let id): selection = makeSelection(.facility(id))
        default: break
        }
    }

    func setRideOpen(_ isOpen: Bool, attractionID: UUID) {
        guard let index = state.attractionIndex(id: attractionID) else { return }
        state.attractions[index].isOpen = isOpen
        if !isOpen {
            releaseQueue(attractionIndex: index)
        }
        refreshUI()
    }

    func setCoasterLivery(_ colour: ParkColour, attractionID: UUID) {
        guard let index = state.attractionIndex(id: attractionID) else { return }
        state.attractions[index].livery = colour
        // The train is rebuilt from the map generation, so nudge it to make
        // the scene notice a change that is not on the map at all.
        state.bumpDecor()
        refreshUI()
    }

    func setCoasterCarStyle(_ style: CoasterCarStyle, attractionID: UUID) {
        guard let index = state.attractionIndex(id: attractionID) else { return }
        state.attractions[index].carStyle = style
        state.bumpDecor()
        refreshUI()
    }

    func rename(attractionID: UUID, to name: String) {
        guard let index = state.attractionIndex(id: attractionID) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.attractions[index].name = trimmed
        refreshUI()
    }

    func setFacilityOpen(_ isOpen: Bool, facilityID: UUID) {
        guard let index = state.facilityIndex(id: facilityID) else { return }
        state.facilities[index].isOpen = isOpen
        refreshUI()
    }

    func setPrice(_ price: Double, facilityID: UUID) {
        guard let index = state.facilityIndex(id: facilityID) else { return }
        state.facilities[index].price = max(0, price)
        // Sentiment is a rolling average; reset it so the readout reflects the
        // new price rather than the old one.
        state.facilities[index].sentimentSum = 0
        state.facilities[index].sentimentCount = 0
        refreshUI()
    }

    private func releaseQueue(attractionIndex: Int) {
        let queued = state.attractions[attractionIndex].queue
        state.attractions[attractionIndex].queue = []
        for guestID in queued {
            guard let guestIndex = state.guestIndex(id: guestID) else { continue }
            state.guests[guestIndex].activity = .exploring
            state.guests[guestIndex].nextDecisionAt = state.clock.simTime
            state.guests[guestIndex].adjustHappiness(-Balance.happinessQueueAbandonPenalty)
            state.guests[guestIndex].think("They closed the ride while I was waiting.",
                                           mood: .negative,
                                           at: state.clock.simTime)
        }
    }

    // MARK: - Staff

    func canHire(role: StaffRole) -> Bool {
        guard let definition = StaffContent.definition(for: role) else { return false }
        return state.ledger.canAfford(definition.hiringCost) && state.staff.count < Balance.maxStaff
    }

    @discardableResult
    func hireStaff(role: StaffRole) -> Bool {
        guard let definition = StaffContent.definition(for: role), canHire(role: role) else { return false }

        state.ledger.spend(definition.hiringCost, on: .wages)

        let entrance = state.map.entranceCoord
        let member = Staff(id: UUID(),
                           name: GuestNames.random(using: &state.rng),
                           role: role,
                           position: entrance.centre,
                           tile: entrance)
        state.staff.append(member)
        refreshUI()
        return true
    }

    func fireStaff(id: UUID) {
        state.staff.removeAll { $0.id == id }
        if case .staff(let selectedID) = selection?.identity, selectedID == id {
            selection = nil
        }
        refreshUI()
    }

    // MARK: - Upgrades

    /// What the next level of an upgrade costs on a ride, or nil when it is
    /// already at its maximum.
    func upgradeCost(_ kind: RideUpgradeKind, attractionID: UUID) -> Double? {
        guard let attraction = state.attraction(id: attractionID),
              let definition = UpgradeContent.rideUpgrade(kind),
              let base = attraction.baseDefinition else { return nil }
        let next = attraction.upgradeLevel(kind) + 1
        guard next <= definition.maxLevel else { return nil }
        return definition.cost(forLevel: next, ridePrice: base.purchasePrice)
    }

    func canAffordUpgrade(_ kind: RideUpgradeKind, attractionID: UUID) -> Bool {
        guard let cost = upgradeCost(kind, attractionID: attractionID) else { return false }
        return state.ledger.canAfford(cost)
    }

    @discardableResult
    func buyUpgrade(_ kind: RideUpgradeKind, attractionID: UUID) -> Bool {
        guard let cost = upgradeCost(kind, attractionID: attractionID),
              state.ledger.canAfford(cost),
              let index = state.attractionIndex(id: attractionID) else { return false }

        state.ledger.spend(cost, on: .construction)
        let next = state.attractions[index].upgradeLevel(kind) + 1
        state.attractions[index].upgrades[kind.rawValue] = next
        state.statistics.upgradesBoughtTotal += 1

        // Theming decorates the ground around the ride, so the beauty field
        // has to be rebuilt the same way placing scenery rebuilds it.
        if kind == .theming { state.refreshBeauty() }

        refreshUI()
        return true
    }

    /// What paving the next stretch of car park costs, or nil once it is
    /// finished.
    func carParkUpgradeCost() -> Double? {
        CarParkContent.cost(forLevel: state.carParkLevel + 1)
    }

    @discardableResult
    func upgradeCarPark() -> Bool {
        guard let cost = carParkUpgradeCost(), state.ledger.canAfford(cost) else { return false }
        state.ledger.spend(cost, on: .construction)
        state.carParkLevel += 1
        refreshUI()
        return true
    }

    /// What the next level of training costs for one employee, or nil when
    /// they have had all of it.
    func trainingCost(staffID: UUID) -> Double? {
        guard let member = state.staffMember(id: staffID),
              let definition = member.definition else { return nil }
        let next = member.trainingLevel + 1
        guard next <= UpgradeContent.staffTraining.maxLevel else { return nil }
        return UpgradeContent.staffTraining.cost(forLevel: next,
                                                 hiringCost: definition.hiringCost)
    }

    @discardableResult
    func trainStaff(id: UUID) -> Bool {
        guard let cost = trainingCost(staffID: id),
              state.ledger.canAfford(cost),
              let index = state.staffIndex(id: id) else { return false }

        state.ledger.spend(cost, on: .wages)
        state.staff[index].trainingLevel += 1
        refreshUI()
        return true
    }

    // MARK: - Dashboards

    func makeFinanceSnapshot() -> FinanceSnapshot {
        FinanceSnapshot(ledger: state.ledger)
    }

    func makeDashboardSnapshot() -> DashboardSnapshot {
        DashboardSnapshot(state: state, ratingComponents: engine.ratingBreakdown(state: state))
    }

    // MARK: - Saving

    func save() {
        do {
            try saveService.save(state, to: slot)
            saveMessage = "Park saved."
        } catch {
            saveMessage = "Could not save: \(error.localizedDescription)"
        }
    }

    private func autosave() {
        try? saveService.save(state, to: slot)
    }

    func saveOnBackground() {
        autosave()
    }

    func clearSaveMessage() {
        saveMessage = nil
    }

    // MARK: - UI snapshots

    /// Dismissed by the celebration view once its animation has run.
    func dismissCelebration() {
        celebration = nil
    }

    func makeAchievementProgress() -> [AchievementProgress] {
        AchievementSystem.progress(state: state)
    }

    private func refreshUI() {
        hud = HUDSnapshot(state: state)

        if celebration == nil, !state.pendingAwards.isEmpty {
            celebration = state.pendingAwards.removeFirst()
        }
        alerts = Array(state.alerts.suffix(12).reversed())

        if let current = selection?.identity {
            selection = makeSelection(current)
        }
    }

    private func makeSelection(_ identity: SelectionIdentity) -> SelectionDetail? {
        switch identity {
        case .guest(let id):
            guard let guest = state.guest(id: id) else { return nil }
            return .guest(GuestDetail(guest: guest, state: state))
        case .attraction(let id):
            guard let attraction = state.attraction(id: id) else { return nil }
            return .attraction(AttractionDetail(attraction: attraction))
        case .facility(let id):
            guard let facility = state.facility(id: id) else { return nil }
            return .facility(FacilityDetail(facility: facility))
        case .staff(let id):
            guard let member = state.staffMember(id: id) else { return nil }
            return .staff(StaffDetail(staff: member, state: state))
        }
    }
}

// MARK: - Supporting types

struct BuildState {
    var isActive = false
    var isDemolishing = false
    /// While drawing, a one-finger drag paints walkway instead of moving the
    /// camera. Off by default so dragging the map is never destructive.
    var isDrawing = false
    var category: BuildCategory = .path
    /// Quarter turns clockwise applied to whatever is about to be placed.
    /// Kept across placements, so a row of benches all face the same way.
    var rotation = 0
    /// A placement lined up and waiting to be confirmed. Nothing has been
    /// built or charged while this is set.
    var pending: PendingPlacement?
    /// Which shelf of the ride list is on show, or nil for all of them.
    var rideGroup: RideGroup?
    var selectedID: String?
    var ghost: GridCoord?
    var ghostValid = false
    var ghostReason: String?
}

/// Somewhere a building is about to go, once the player says so.
struct PendingPlacement: Equatable {
    let definitionID: String
    var origin: GridCoord
    var rotation: Int
}

struct PendingDemolition: Identifiable {
    let id = UUID()
    let coord: GridCoord
    let name: String
    let refund: Double
}

enum SelectionIdentity: Equatable {
    case guest(UUID)
    case attraction(UUID)
    case facility(UUID)
    case staff(UUID)
}

enum SelectionDetail {
    case guest(GuestDetail)
    case attraction(AttractionDetail)
    case facility(FacilityDetail)
    case staff(StaffDetail)

    var identity: SelectionIdentity {
        switch self {
        case .guest(let detail): return .guest(detail.id)
        case .attraction(let detail): return .attraction(detail.id)
        case .facility(let detail): return .facility(detail.id)
        case .staff(let detail): return .staff(detail.id)
        }
    }
}
