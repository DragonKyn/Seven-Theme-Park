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
    /// The one-tile elements the coaster used to have. No longer offered:
    /// an element is a structure placed across several tiles now, so a loop
    /// can be the size of a loop. These stay so a park saved with them still
    /// loads, and they behave as ordinary coaster track.
    case coasterLoop
    case coasterHill
    case coasterHelix
    case coasterJump
    /// A deck over water. Walkable like a path, and the only way to cross a
    /// pond without filling it in.
    case bridge

    /// Guests may only ever stand on walkable terrain.
    var isWalkableTerrain: Bool {
        self == .path || self == .entrance || self == .bridge
    }

    /// Terrain guests walk along, which is drawn as one continuous route
    /// whatever it is made of.
    var isWalkway: Bool {
        isWalkableTerrain
    }

    /// Every kind of coaster track, which all join to one another.
    static let coasterPieces: Set<TerrainType> = [
        .coasterTrack, .coasterLoop, .coasterHill, .coasterHelix, .coasterJump
    ]

    var isCoasterTrack: Bool { TerrainType.coasterPieces.contains(self) }
}

struct Tile: Codable {
    var terrain: TerrainType = .grass
    /// Which finish this terrain is laid in: paving, brick, boardwalk or
    /// tarmac for a walkway; the colour of the water for a pond. Terrain is
    /// painted rather than placed, so the choice lives on the tile.
    var style: UInt8 = 0
    /// Identifier of the building occupying this tile, if any.
    var buildingID: UUID?
    /// Whether whatever is here stops guests walking through. A bench or a
    /// bin sits on the walkway and is walked around rather than blocking it,
    /// which is where park furniture actually goes.
    var blocksMovement: Bool = true
    /// Rubbish on the ground, 0-100. Only ever non-zero on walkable tiles,
    /// because guests can only drop it where they can stand.
    var litter: Double = 0
    /// Prettiness contributed by nearby scenery, 0-100. Recomputed whenever
    /// scenery is placed or removed, never simulated per tick.
    var beauty: Double = 0

    var isWalkable: Bool {
        (buildingID == nil || !blocksMovement) && terrain.isWalkableTerrain
    }

    /// Whether anything at all is standing here, blocking or not.
    var isOccupied: Bool { buildingID != nil }

    var hasLitter: Bool { litter > 0.5 }
}

extension Tile {
    /// Lenient decoding: fields added after a save format was published come
    /// back as their default rather than failing the whole load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        terrain = container.value(.terrain, or: .grass)
        style = container.value(.style, or: 0)
        buildingID = container.optionalValue(.buildingID)
        blocksMovement = container.value(.blocksMovement, or: true)
        litter = container.value(.litter, or: 0)
        beauty = container.value(.beauty, or: 0)
    }
}
