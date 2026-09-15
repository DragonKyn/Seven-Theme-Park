import Foundation

/// What the map editor is painting with.
enum MapEditorTool: Equatable {
    case paint(MapGround)
    /// Tap along the bottom row to move the gate.
    case gate
}

/// The map editor's state and rules. The view draws it and forwards touches;
/// everything about what a touch does lives here.
@MainActor
final class MapEditorModel: ObservableObject {

    @Published var name: String
    @Published private(set) var layout: MapLayout
    @Published var tool: MapEditorTool = .paint(.water)
    /// Radius in tiles, so 0 is a single tile.
    @Published var brushRadius = 1
    @Published private(set) var canUndo = false

    /// A map with less land than this is not a map anyone can build a park
    /// on. Roughly a tenth of the lot.
    static let minimumBuildableTiles = 360
    static let brushRadii = [0, 1, 2, 4]

    private let id: UUID
    private var history: [MapLayout] = []
    private static let historyLimit = 40

    init(editing map: CustomMap? = nil) {
        id = map?.id ?? UUID()
        name = map?.name ?? ""
        layout = map?.layout ?? MapCatalogue.openMeadow.layout
    }

    // MARK: - Painting

    /// Call once at the start of a stroke, so a whole drag undoes as one.
    func beginStroke() {
        history.append(layout)
        if history.count > Self.historyLimit { history.removeFirst() }
        canUndo = true
    }

    /// Applies the current tool at a tile. `y` is in map space, 0 at the gate.
    func apply(atX x: Int, y: Int) {
        switch tool {
        case .gate:
            guard x >= 1, x <= layout.width - 2 else { return }
            layout.entranceX = x
            // The ground in front of a gate has to be open, or the park it
            // makes cannot let anybody in.
            layout.clearGateApproach()
        case .paint(let ground):
            var updated = layout
            for dy in -brushRadius...brushRadius {
                for dx in -brushRadius...brushRadius where dx * dx + dy * dy <= brushRadius * brushRadius + 1 {
                    guard !isGateApproach(x: x + dx, y: y + dy) else { continue }
                    updated.set(ground, x: x + dx, y: y + dy)
                }
            }
            if updated != layout { layout = updated }
        }
    }

    func undo() {
        guard let previous = history.popLast() else { return }
        layout = previous
        canUndo = !history.isEmpty
    }

    /// Starts again from one of the shipped maps, or from bare grass.
    func start(from blueprint: MapBlueprint?) {
        beginStroke()
        layout = blueprint?.layout ?? MapLayout()
    }

    /// The tiles in front of the gate are never painted over, so the player
    /// can see while drawing that the way in is kept open.
    func isGateApproach(x: Int, y: Int) -> Bool {
        y >= 0 && y <= MapLayout.clearance && abs(x - layout.entranceX) <= 1
    }

    // MARK: - Saving

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var buildableTiles: Int { layout.buildableCount }

    /// Why the map cannot be saved yet, or nil when it can.
    var problem: String? {
        if trimmedName.isEmpty { return "Give the map a name." }
        if buildableTiles < Self.minimumBuildableTiles {
            return "Leave more open grass. A park needs at least \(Self.minimumBuildableTiles) tiles of it."
        }
        return nil
    }

    func makeMap() -> CustomMap? {
        guard problem == nil else { return nil }
        var finished = layout
        finished.clearGateApproach()
        return CustomMap(id: id, name: trimmedName, layout: finished, savedAt: Date())
    }
}
