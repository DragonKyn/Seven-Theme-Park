import Foundation

enum TerrainType: String, Codable {
    case grass
    case path
    case entrance

    /// Guests may only ever stand on walkable terrain.
    var isWalkableTerrain: Bool {
        self == .path || self == .entrance
    }
}

struct Tile: Codable {
    var terrain: TerrainType = .grass
    /// Identifier of the building occupying this tile, if any.
    var buildingID: UUID?
    /// Rubbish on the ground, 0-100. Only ever non-zero on walkable tiles,
    /// because guests can only drop it where they can stand.
    var litter: Double = 0

    var isWalkable: Bool {
        buildingID == nil && terrain.isWalkableTerrain
    }

    var hasLitter: Bool { litter > 0.5 }
}

extension Tile {
    /// Lenient decoding: fields added after a save format was published come
    /// back as their default rather than failing the whole load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        terrain = container.value(.terrain, or: .grass)
        buildingID = container.optionalValue(.buildingID)
        litter = container.value(.litter, or: 0)
    }
}
