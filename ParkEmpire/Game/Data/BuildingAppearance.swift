import Foundation

/// How a placed building is drawn.
///
/// This is deliberately data, not drawing code: it names a shape and three
/// colour roles, and the rendering layer decides what those mean in pixels.
/// Keeping it here means adding a ride is still one entry in `GameContent`,
/// which now describes how the ride looks as well as how it plays.
struct BuildingAppearance: Codable, Equatable {
    let motif: BuildingMotif
    var primary: ParkColour
    var secondary: ParkColour
    var accent: ParkColour
    /// Which cut of this shape to draw. One tree definition draws four
    /// different trees, so a row of them is a row of trees rather than one
    /// tree stamped four times.
    var variant: Int = 0

    init(_ motif: BuildingMotif,
         _ primary: ParkColour,
         _ secondary: ParkColour,
         _ accent: ParkColour,
         variant: Int = 0) {
        self.motif = motif
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.variant = variant
    }

    func withVariant(_ variant: Int) -> BuildingAppearance {
        var copy = self
        copy.variant = motif.variantCount > 1 ? variant % motif.variantCount : 0
        return copy
    }

    /// Repaints park furniture in the park's own colours. Anything that is
    /// meant to look like itself — a tree, a ride with its own livery — is
    /// handed back unchanged.
    func applying(_ scheme: ParkScheme) -> BuildingAppearance {
        guard motif.followsParkScheme else { return self }
        var copy = self
        copy.primary = scheme.primary
        copy.accent = scheme.trim
        return copy
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
    /// Walled pond with boats loose in it.
    case bumperBoats
    /// Reedy pond with a jetty and a rowing boat on it.
    case fishingBoats
    /// Rectangular pool with a standing wave rolling down it.
    case wavePool
    /// Two towers with a cable and chairs between them.
    case skyGliders
    /// Squat mirrored box.
    case mirrorMaze
    /// Boarding platform with the foot of a lift hill behind it.
    case coasterStation
    /// A clipped hedge, for edging a walkway.
    case hedge
    /// Table with benches either side and a parasol over it.
    case picnicTable
    /// Tall pole with a pennant at the top.
    case flagPole
    /// Arched gateway over the walkway, planted at both feet.
    case gardenArch
    /// Square tower with a clock face on it, the tallest thing in the park
    /// that nobody queues for.
    case clockTower
    /// Booth with a striped awning across the front.
    case stall
    /// Small booth with a domed top.
    case kiosk
    /// Carnival booths. Each is the same counter with a different game
    /// behind it, which is what a row of them looks like in life.
    case basketballGame
    case waterRaceGame
    case balloonGame
    case targetGame
    case moleGame
    case strengthTester
    case ringTossGame
    /// Booths with a board saying what they sell.
    case burgerStall
    case pizzaStall
    case drinkKiosk
    case iceCreamStall
    case souvenirShop
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

    /// How many different ways this shape is drawn. One is the usual answer;
    /// scenery is where variety is worth the drawing.
    var variantCount: Int {
        switch self {
        case .tree: return 4
        case .conifer: return 3
        case .flowerBed: return 3
        case .topiary: return 3
        case .statue: return 3
        case .lamp: return 2
        case .fountain: return 2
        case .hedge: return 3
        case .picnicTable: return 2
        case .flagPole: return 3
        case .gardenArch: return 2
        case .clockTower: return 2
        default: return 1
        }
    }

    /// Whether this is park furniture, painted in whatever colours the park
    /// has chosen, rather than a thing with a look of its own.
    ///
    /// Plants are not on this list on purpose: a park scheme of pink and gold
    /// should not produce pink trees.
    var followsParkScheme: Bool {
        switch self {
        case .lamp, .bench, .bin, .fountain, .statue,
             .picnicTable, .flagPole, .gardenArch, .clockTower:
            return true
        default:
            return false
        }
    }

    /// What moves once the building is running. Rides that animate read as
    /// alive; a stopped animation is how a broken ride announces itself.
    var motion: BuildingMotion {
        switch self {
        case .carousel, .ferrisWheel, .teacups: return .spin
        case .swingBoat: return .swing
        case .dropTower: return .rise
        case .coaster, .megaCoaster, .logFlume, .fishingBoats, .skyGliders: return .circuit
        case .goKarts: return .race
        case .bumperCars, .bumperBoats: return .bumper
        case .slingshot: return .launch
        case .carpetSlide: return .slide
        case .hauntedHouse: return .hover
        case .wavePool: return .surf
        case .fountain: return .bob
        // The two booths with something to watch. The rest are a backdrop for
        // the guests standing at them.
        case .moleGame: return .pop
        case .strengthTester: return .rise
        // The station itself is still; what moves is the train, and that runs
        // on the player's own track rather than round the building.
        case .trainStation: return .none
        case .mirrorMaze, .coasterStation: return .none
        case .hedge, .picnicTable, .flagPole, .gardenArch, .clockTower:
            return .none
        case .stall, .kiosk, .shopFront, .restroom, .bench, .bin,
             .burgerStall, .pizzaStall, .drinkKiosk, .iceCreamStall, .souvenirShop,
             .basketballGame, .waterRaceGame, .balloonGame, .targetGame, .ringTossGame,
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
    /// Runs the length of a pool and starts again from the top.
    case surf
    /// Several vehicles sharing a circuit at different speeds.
    case race
    /// Several vehicles crossing an arena and colliding.
    case bumper
    /// Up out of a hole, and straight back down again.
    case pop
}

/// Named colours the park is drawn from. Naming them rather than storing raw
/// components keeps the content catalogue free of UIKit and makes the palette
/// retunable in one place.
/// The two colours a park paints its own furniture in.
///
/// Deliberately only two: a scheme with five colours in it is a palette, and
/// a player choosing five colours for a bin is a player who has stopped
/// building a park.
struct ParkScheme: Codable, Equatable {
    var primary: ParkColour = .teal
    var trim: ParkColour = .cream
}

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
