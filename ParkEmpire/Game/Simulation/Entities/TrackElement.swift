import Foundation

/// A placed coaster element: a loop, a corkscrew, a jump.
///
/// Deliberately tiny, like scenery. It sits on top of track the player has
/// already laid and changes nothing about where that track goes. What it
/// changes is how good the ride is and how the train behaves crossing it.
struct TrackElement: Codable, Identifiable {
    let id: UUID
    let definitionID: String
    var origin: GridCoord
    var size: GridSize
    /// Quarter turns clockwise, 0 to 3.
    var rotation: Int = 0

    var rect: GridRect { GridRect(origin: origin, size: size) }

    var definition: CoasterElementDefinition? {
        CoasterElementContent.definition(definitionID)
    }
}

extension TrackElement {
    /// Lenient decoding, like every other entity: a field added later comes
    /// back as its default rather than failing the whole load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        definitionID = container.value(.definitionID, or: "")
        origin = container.value(.origin, or: GridCoord(0, 0))
        size = container.value(.size, or: .single)
        rotation = container.value(.rotation, or: 0)
    }
}
