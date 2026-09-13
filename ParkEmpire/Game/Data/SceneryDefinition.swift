import Foundation

/// Static configuration for something built purely to look at.
///
/// Scenery has no guests, no queue and no income. Its whole job is to raise
/// the beauty of the tiles around it, which guests feel as they walk past and
/// which the park rating measures.
struct SceneryDefinition: BuildableDefinition, Codable, Identifiable {
    let id: String
    let displayName: String
    let summary: String
    let purchasePrice: Double
    /// How much prettiness this adds to the tile it stands on, 0-100.
    /// Neighbouring tiles get a share of it, falling off with distance.
    let beauty: Double
    /// How many tiles away the effect still reaches.
    let beautyRadius: Int
    let footprint: GridSize
    let unlockLevel: Int
    let appearance: BuildingAppearance
    /// Whether this is something a guest walks under. An arch over a path is
    /// the point of an arch; a tree over a path is a tree in the way.
    var spansWalkway: Bool = false

    var category: BuildCategory { .scenery }

    var previewAppearance: BuildingAppearance? { appearance }

    /// Scenery is decoration, not a destination, so it can stand anywhere
    /// there is room rather than having to touch a walkway.
    var requiresPathAccess: Bool { false }

    /// Set on pieces designed to be walked through rather than walked around.
    /// They are placed without blocking the tile, so the path underneath
    /// stays open.
    var mayStandOnWalkway: Bool { spansWalkway }

    /// Beauty contributed to a tile `distance` steps away. Linear falloff is
    /// enough: the player needs to see that closer is better, not model light.
    func beauty(atDistance distance: Int) -> Double {
        guard distance <= beautyRadius else { return 0 }
        guard beautyRadius > 0 else { return beauty }
        let falloff = 1 - Double(distance) / Double(beautyRadius + 1)
        return beauty * falloff
    }
}
