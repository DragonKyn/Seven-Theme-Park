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

/// Paths are their own tiny definition: they change terrain rather than
/// creating an entity.
struct PathDefinition: BuildableDefinition {
    let id: String
    let displayName: String
    let summary: String
    let purchasePrice: Double
    let refundValue: Double
    var category: BuildCategory { .path }
    var footprint: GridSize { .single }
    var unlockLevel: Int { 1 }
    var requiresPathAccess: Bool { false }
}
