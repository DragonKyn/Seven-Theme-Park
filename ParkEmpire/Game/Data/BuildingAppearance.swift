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

    /// What moves once the building is running. Rides that animate read as
    /// alive; a stopped animation is how a broken ride announces itself.
    var motion: BuildingMotion {
        switch self {
        case .carousel: return .spin
        case .swingBoat: return .swing
        case .dropTower: return .rise
        case .coaster: return .circuit
        case .stall, .kiosk, .shopFront, .restroom, .bench, .bin: return .none
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
