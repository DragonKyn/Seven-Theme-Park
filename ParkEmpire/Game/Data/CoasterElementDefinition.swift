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
    /// How many tiles tall the drawing is. An element reaches up out of the
    /// ground it occupies: a loop over three tiles of track needs height to be
    /// a loop, and the track line runs along the bottom of the picture.
    let visualHeight: Int
    let unlockLevel: Int
    let motif: CoasterElementMotif

    /// Where the track runs through the drawing.
    var trackLine: CGFloat {
        CoasterElementArtwork.trackLine(footprintHeight: footprint.height,
                                        visualHeight: visualHeight)
    }

    var category: BuildCategory { .coaster }

    /// It brings its own track. Making the player lay a run of track first and
    /// then drop an element on exactly the right tiles was fiddly and easy to
    /// get wrong; an element lays whatever it needs under itself.
    var requiresPathAccess: Bool { false }
    var laysCoasterTrack: Bool { true }

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
            visualHeight: 2,
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
            visualHeight: 3,
            unlockLevel: 1,
            motif: .verticalLoop
        ),
        CoasterElementDefinition(
            id: "element.helix",
            displayName: "Helix Tower",
            summary: "A tight climbing spiral. Two tiles of track go in, and a long, heavy turn comes out.",
            purchasePrice: 4_200,
            thrill: 28,
            intensity: 1.40,
            // One row deep, like every other element. A two-deep footprint put
            // the rails on the seam between its rows rather than on the track.
            footprint: GridSize(2, 1),
            visualHeight: 3,
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
            visualHeight: 2,
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
            visualHeight: 2,
            unlockLevel: 3,
            motif: .jump
        )
    ]

    private static let byID: [String: CoasterElementDefinition] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func definition(_ id: String) -> CoasterElementDefinition? { byID[id] }
}
