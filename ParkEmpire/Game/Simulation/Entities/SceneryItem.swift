import Foundation

/// A placed decoration. Deliberately tiny: scenery has no behaviour, no state
/// that changes over time, and nothing to simulate. It occupies tiles and it
/// makes the ground around it prettier.
struct SceneryItem: Codable, Identifiable {
    let id: UUID
    let definitionID: String
    var origin: GridCoord
    var size: GridSize
    /// Quarter turns clockwise, 0 to 3.
    var rotation: Int = 0
    /// Which cut of this shape was planted. Picked when it is placed, kept
    /// forever after, so an avenue of trees stays the avenue it was.
    var variant: Int = 0

    var rect: GridRect { GridRect(origin: origin, size: size) }

    var definition: SceneryDefinition? { GameContent.scenery(definitionID) }
}

extension SceneryItem {
    /// Lenient decoding: fields added after a save format was published come
    /// back as their default rather than failing the whole load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        definitionID = container.value(.definitionID, or: "")
        origin = container.value(.origin, or: GridCoord(0, 0))
        size = container.value(.size, or: .single)
        rotation = container.value(.rotation, or: 0)
        variant = container.value(.variant, or: 0)
    }
}
