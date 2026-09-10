import Foundation

/// How a placed building is drawn.
///
/// This is deliberately data, not drawing code: it names a shape and three
/// colour roles, and the rendering layer decides what those mean in pixels.
/// Keeping it here means adding a ride is still one entry in `GameContent`,
/// which now describes how the ride looks as well as how it plays.
struct BuildingAppearance: Codable, Equatable {
    let motif: BuildingMotif
    let primary: ParkColour
    let secondary: ParkColour
    let accent: ParkColour

    init(_ motif: BuildingMotif,
         _ primary: ParkColour,
         _ secondary: ParkColour,
         _ accent: ParkColour) {
        self.motif = motif
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
    }

    /// Used when a saved building names a definition this build no longer has.
    static let unknown = BuildingAppearance(.shopFront, .slate, .charcoal, .cream)
}

/// The silhouette a building is drawn with. One case per recognisable shape,
/// not one per catalogue entry, so several rides can share a look with
/// different colours.
enum BuildingMotif: String, Codable {
    /// Round platform under a striped conical canopy.
    case carousel
    /// Boat hanging from an A-frame.
    case swingBoat
    /// Tall column with a car that climbs and drops.
    case dropTower
    /// Oval of track over a base, with a train running it.
    case coaster
    /// A full-size coaster: lift hill, first drop, vertical loop, return run.
    case megaCoaster
    /// Upright wheel hung with cabins.
    case ferrisWheel
    /// Round floor carrying a cluster of cups.
    case teacups
    /// Walled arena with cars loose inside it.
    case bumperCars
    /// Gabled house with lit windows and a ghost outside.
    case hauntedHouse
    /// Asphalt circuit with kerbs and a pit building.
    case goKarts
    /// Water channel around a splash pool, with a log on it.
    case logFlume
    /// Twin launch towers with a capsule between them.
    case slingshot
    /// Parallel slide lanes running down to a landing mat.
    case carpetSlide
    /// Platform under a canopy, with a clock on the end.
    case trainStation
    /// Booth with a striped awning across the front.
    case stall
    /// Small booth with a domed top.
    case kiosk
    /// Wider building with a row of windows.
    case shopFront
    /// Plain block with a sign board.
    case restroom
    /// Slatted seat.
    case bench
    /// Cylinder with a lid.
    case bin
    /// Broad leafy canopy over a trunk.
    case tree
    /// Narrow cone, darker and taller than a tree.
    case conifer
    /// Low bed of massed flowers.
    case flowerBed
    /// Round basin with a jet in the middle.
    case fountain
    /// Slim post with a lit head.
    case lamp
    /// Clipped shrub on a square base.
    case topiary
    /// Carved figure on a plinth.
    case statue

    /// What moves once the building is running. Rides that animate read as
    /// alive; a stopped animation is how a broken ride announces itself.
    var motion: BuildingMotion {
        switch self {
        case .carousel, .ferrisWheel, .teacups: return .spin
        case .swingBoat: return .swing
        case .dropTower: return .rise
        case .coaster, .megaCoaster, .logFlume: return .circuit
        case .goKarts: return .race
        case .bumperCars: return .bumper
        case .slingshot: return .launch
        case .carpetSlide: return .slide
        case .hauntedHouse: return .hover
        case .fountain: return .bob
        // The station itself is still; what moves is the train, and that runs
        // on the player's own track rather than round the building.
        case .trainStation: return .none
        case .stall, .kiosk, .shopFront, .restroom, .bench, .bin,
             .tree, .conifer, .flowerBed, .lamp, .topiary, .statue:
            return .none
        }
    }
}

/// The kind of movement a motif's moving part makes.
enum BuildingMotion: String, Codable {
    case none
    case spin
    case swing
    case rise
    case circuit
    /// A small vertical pulse, for things that trickle rather than travel.
    case bob
    /// Fired upward fast, then falling back and settling.
    case launch
    /// Runs down its lane, then reappears at the top.
    case slide
    /// Floats gently around one spot, never leaving it.
    case hover
    /// Several vehicles sharing a circuit at different speeds.
    case race
    /// Several vehicles crossing an arena and colliding.
    case bumper
}

/// Named colours the park is drawn from. Naming them rather than storing raw
/// components keeps the content catalogue free of UIKit and makes the palette
/// retunable in one place.
enum ParkColour: String, Codable {
    case red
    case orange
    case amber
    case yellow
    case lime
    case green
    case teal
    case cyan
    case blue
    case indigo
    case violet
    case pink
    case cream
    case sand
    case brown
    case slate
    case charcoal
    case white
}
