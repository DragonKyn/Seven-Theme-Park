import Foundation

/// A placed decoration. Deliberately tiny: scenery has no behaviour, no state
/// that changes over time, and nothing to simulate. It occupies tiles and it
/// makes the ground around it prettier.
struct SceneryItem: Codable, Identifiable {
    let id: UUID
    let definitionID: String
    var origin: GridCoord
    var size: GridSize

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
    }
}
