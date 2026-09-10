import Foundation

/// Categories shown as tabs in the build menu.
enum BuildCategory: String, Codable, CaseIterable, Identifiable {
    case path
    case attraction
    case shop
    case facility
    case scenery

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .path: return "Paths"
        case .attraction: return "Rides"
        case .shop: return "Food & Retail"
        case .facility: return "Guest Services"
        case .scenery: return "Scenery"
        }
    }

    var symbolName: String {
        switch self {
        case .path: return "square.grid.3x3"
        case .attraction: return "sparkles"
        case .shop: return "cart"
        case .facility: return "figure.stand"
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
    /// Artwork for the build-menu thumbnail. Walkways have none: they are
    /// terrain rather than an object, and there is nothing to draw.
    var previewAppearance: BuildingAppearance? { get }
}

extension BuildableDefinition {
    var requiresPathAccess: Bool { true }
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
