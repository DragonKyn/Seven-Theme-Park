import Foundation

enum TerrainType: String, Codable {
    case grass
    case path
    case entrance
    /// Decorative water. Guests cannot walk on it and nothing can be built
    /// over it, which is the price of how good it looks.
    case water
    /// Railway. Guests cannot walk on it; trains run along it between
    /// stations, and nothing else can be built over it.
    case track
    /// Coaster track. Laid the same way as railway and just as unwalkable,
    /// but it belongs to one station rather than to a network of them.
    case coasterTrack
    /// A vertical loop. Costs more, and is worth far more to the ride.
    case coasterLoop
    /// An airtime hill.
    case coasterHill
    /// A corkscrew.
    case coasterHelix

    /// Guests may only ever stand on walkable terrain.
    var isWalkableTerrain: Bool {
        self == .path || self == .entrance
    }

    /// Every kind of coaster track, which all join to one another.
    static let coasterPieces: Set<TerrainType> = [
        .coasterTrack, .coasterLoop, .coasterHill, .coasterHelix
    ]

    var isCoasterTrack: Bool { TerrainType.coasterPieces.contains(self) }

    /// How much a tile of this adds to a ride, beyond simply being longer.
    /// Plain track is the baseline; the special pieces are what the player is
    /// actually paying for.
    var coasterThrill: Double {
        switch self {
        case .coasterLoop: return 9
        case .coasterHelix: return 7
        case .coasterHill: return 4
        default: return 0
        }
    }
}

struct Tile: Codable {
    var terrain: TerrainType = .grass
    /// Identifier of the building occupying this tile, if any.
    var buildingID: UUID?
    /// Rubbish on the ground, 0-100. Only ever non-zero on walkable tiles,
    /// because guests can only drop it where they can stand.
    var litter: Double = 0
    /// Prettiness contributed by nearby scenery, 0-100. Recomputed whenever
    /// scenery is placed or removed, never simulated per tick.
    var beauty: Double = 0

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
        beauty = container.value(.beauty, or: 0)
    }
}
