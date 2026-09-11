import Foundation

/// Categories shown as tabs in the build menu.
enum BuildCategory: String, Codable, CaseIterable, Identifiable {
    case path
    case attraction
    case shop
    case facility
    case coaster
    case transport
    case scenery

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .path: return "Paths"
        case .attraction: return "Rides"
        case .shop: return "Food & Retail"
        case .facility: return "Guest Services"
        case .coaster: return "Coasters"
        case .transport: return "Transport"
        case .scenery: return "Scenery"
        }
    }

    var symbolName: String {
        switch self {
        case .path: return "square.grid.3x3"
        case .attraction: return "sparkles"
        case .shop: return "cart"
        case .facility: return "figure.stand"
        // A swooping line, which is what track looks like. The rolling
        // figure it had before is a wheelchair symbol.
        case .coaster: return "point.topleft.down.curvedto.point.bottomright.up"
        case .transport: return "tram.fill"
        case .scenery: return "tree.fill"
        }
    }
}

/// Everything the build menu can place shares this surface, so the menu and
/// the placement validator never need to know about concrete types.
protocol BuildableDefinition {
    var id: String { get }
    var displayName: String { get }
    var summary: String { get }
    var category: BuildCategory { get }
    var purchasePrice: Double { get }
    var footprint: GridSize { get }
    var unlockLevel: Int { get }
    /// Whether the placed object must touch a walkable tile to function.
    var requiresPathAccess: Bool { get }
    /// Whether it also has to sit against a railway to be any use.
    var requiresTrackAccess: Bool { get }
    /// Whether it has to sit against coaster track.
    var requiresCoasterTrackAccess: Bool { get }
    /// Terrain this is built on top of rather than beside. A boat ride goes on
    /// the water.
    var bedTerrain: TerrainType? { get }
    /// Whether placing this lays coaster track under itself.
    var laysCoasterTrack: Bool { get }
    /// Artwork for the build-menu thumbnail. Walkways have none: they are
    /// terrain rather than an object, and there is nothing to draw.
    var previewAppearance: BuildingAppearance? { get }
}

extension BuildableDefinition {
    /// The ground this takes up once turned. Occupancy, access tiles and the
    /// placement preview all work from this rather than from the raw
    /// footprint, so rotation needs no special cases anywhere else.
    func footprint(rotatedBy quarterTurns: Int) -> GridSize {
        footprint.rotated(by: quarterTurns)
    }

    /// Turning a one-tile object achieves nothing, and turning terrain is
    /// meaningless, so the build menu only offers it where it does something.
    var canRotate: Bool {
        !(self is TerrainDefinition) && footprint.width != footprint.height
    }

    var requiresPathAccess: Bool { true }
    var requiresTrackAccess: Bool { false }
    var requiresCoasterTrackAccess: Bool { false }
    var bedTerrain: TerrainType? { nil }
    var laysCoasterTrack: Bool { false }
    var previewAppearance: BuildingAppearance? { nil }
}

/// Terrain rather than an object: placing one repaints a tile instead of
/// creating an entity. Walkways and water are both this.
struct TerrainDefinition: BuildableDefinition {
    let id: String
    let displayName: String
    let summary: String
    let purchasePrice: Double
    let refundValue: Double
    /// What the tile becomes.
    let terrain: TerrainType
    let category: BuildCategory
    /// Prettiness this terrain lends the tiles around it, on the same 0-100
    /// scale scenery uses. Walkways add none; water adds a lot.
    let beauty: Double
    let beautyRadius: Int

    var footprint: GridSize { .single }
    var unlockLevel: Int { 1 }
    var requiresPathAccess: Bool { false }
}
