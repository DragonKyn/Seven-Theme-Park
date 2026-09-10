import Foundation

/// A piece of coaster that spans several tiles.
///
/// The first version of these was one element per tile, which meant a
/// "vertical loop" was a ring the size of a bin. An element is a structure:
/// it is placed on top of track you have already laid, covers a run of it,
/// and is drawn across the whole run as one thing.
struct CoasterElementDefinition: BuildableDefinition, Identifiable {
    let id: String
    let displayName: String
    let summary: String
    let purchasePrice: Double
    /// What this adds to a circuit, on the same scale the ride's excitement
    /// uses. This is the whole reason to buy one.
    let thrill: Double
    /// How hard the train is thrown as it crosses. 1 is no reaction.
    let intensity: CGFloat
    let footprint: GridSize
    let unlockLevel: Int
    let motif: CoasterElementMotif

    var category: BuildCategory { .coaster }

    /// It goes on track rather than beside it, so the usual walkway rule does
    /// not apply and a bed of track does instead.
    var requiresPathAccess: Bool { false }
    var bedTerrain: TerrainType? { .coasterTrack }

    var previewAppearance: BuildingAppearance? { nil }
}

/// The shape an element is drawn as.
enum CoasterElementMotif: String, Codable {
    case verticalLoop
    case corkscrew
    case airtimeHills
    case jump
    case helixTower
}

enum CoasterElementContent {

    static let all: [CoasterElementDefinition] = [
        CoasterElementDefinition(
            id: "element.hills",
            displayName: "Airtime Hills",
            summary: "A run of humps that lifts riders out of their seats. Cheap, and every circuit wants some.",
            purchasePrice: 1_400,
            thrill: 14,
            intensity: 1.22,
            footprint: GridSize(3, 1),
            unlockLevel: 1,
            motif: .airtimeHills
        ),
        CoasterElementDefinition(
            id: "element.loop",
            displayName: "Vertical Loop",
            summary: "The one everybody photographs. Three tiles of track go in, and the train comes out upside down.",
            purchasePrice: 3_600,
            thrill: 26,
            intensity: 1.55,
            footprint: GridSize(3, 1),
            unlockLevel: 1,
            motif: .verticalLoop
        ),
        CoasterElementDefinition(
            id: "element.helix",
            displayName: "Helix Tower",
            summary: "A tight descending spiral. Takes a square of track and gives back a long, heavy turn.",
            purchasePrice: 4_200,
            thrill: 28,
            intensity: 1.40,
            footprint: GridSize(2, 2),
            unlockLevel: 2,
            motif: .helixTower
        ),
        CoasterElementDefinition(
            id: "element.corkscrew",
            displayName: "Corkscrew",
            summary: "Two barrel rolls back to back, strung out over four tiles.",
            purchasePrice: 5_000,
            thrill: 30,
            intensity: 1.45,
            footprint: GridSize(4, 1),
            unlockLevel: 2,
            motif: .corkscrew
        ),
        CoasterElementDefinition(
            id: "element.jump",
            displayName: "Jump",
            summary: "A ramp, a gap, and a ramp. The train is launched across it and lands running.",
            purchasePrice: 6_500,
            thrill: 34,
            intensity: 1.85,
            footprint: GridSize(3, 1),
            unlockLevel: 3,
            motif: .jump
        )
    ]

    private static let byID: [String: CoasterElementDefinition] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func definition(_ id: String) -> CoasterElementDefinition? { byID[id] }
}
