import Foundation

/// What an entertainer does for a living.
///
/// Classic is the entertainer every existing park already employs: it is what
/// a save from before acts existed decodes to, and it wears the park's
/// uniform. The rest wear their own colours, because a mime in the staff
/// uniform is not a mime.
enum EntertainerAct: String, Codable, CaseIterable, Identifiable {
    case classic
    case balloonArtist
    case mime
    case juggler
    case magician

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Entertainer"
        case .balloonArtist: return "Balloon Artist"
        case .mime: return "Mime"
        case .juggler: return "Juggler"
        case .magician: return "Magician"
        }
    }

    var summary: String {
        switch self {
        case .classic:
            return "The all-rounder. Lifts the mood of everyone nearby."
        case .balloonArtist:
            return "Hands out balloons, children first. Guests carry them round for the rest of the visit."
        case .mime:
            return "Hardly lifts anyone passing, but is brilliant to a queue. Put one where the waiting is."
        case .juggler:
            return "A wider circle and a bigger lift than the all-rounder. Hard to walk past."
        case .magician:
            return "A modest lift all round, and now and then somebody is amazed enough to remember the whole day."
        }
    }

    /// Whether the act has a colour of its own to choose. The classic
    /// entertainer wears the park's uniform and has none.
    var usesColour: Bool { self != .classic }

    /// What the colour is on this act, for the label on the picker.
    var colourLabel: String {
        switch self {
        case .classic: return ""
        case .balloonArtist: return "Vest"
        case .mime: return "Stripes"
        case .juggler: return "Costume"
        case .magician: return "Cape"
        }
    }

    var defaultColour: ParkColour {
        switch self {
        case .classic: return .red
        case .balloonArtist: return .yellow
        case .mime: return .charcoal
        case .juggler: return .green
        case .magician: return .violet
        }
    }

    // MARK: - What the act does

    /// How wide a circle it works, as a share of the usual one.
    var radiusFactor: Double {
        switch self {
        case .classic: return 1.0
        case .balloonArtist: return 0.9
        case .mime: return 0.8
        case .juggler: return 1.15
        case .magician: return 1.0
        }
    }

    /// How hard it lifts the mood, as a share of the usual lift.
    var happinessFactor: Double {
        switch self {
        case .classic: return 1.0
        case .balloonArtist: return 0.6
        case .mime: return 0.9
        case .juggler: return 1.2
        case .magician: return 0.7
        }
    }

    /// Multiplies the lift for somebody standing in a queue.
    var queueFactor: Double {
        self == .mime ? 2.4 : 1.0
    }

    var handsOutBalloons: Bool { self == .balloonArtist }
    var doesTricks: Bool { self == .magician }
}

/// The costumes a park mascot can be hired in.
enum MascotCostume: String, Codable, CaseIterable, Identifiable {
    case bear
    case frog
    case bunny
    case duck
    case cat
    case owl
    case penguin
    case dragon
    case lion
    case elephant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bear: return "Bear"
        case .frog: return "Frog"
        case .bunny: return "Bunny"
        case .duck: return "Duck"
        case .cat: return "Cat"
        case .owl: return "Owl"
        case .penguin: return "Penguin"
        case .dragon: return "Dragon"
        case .lion: return "Lion"
        case .elephant: return "Elephant"
        }
    }

    /// The three colours of a costume: the fur or feathers, what is set
    /// against them (belly, muzzle, mane, beak), and the bow tie and shoes.
    var defaultPrimary: ParkColour {
        switch self {
        case .bear: return .brown
        case .frog: return .green
        case .bunny: return .white
        case .duck: return .yellow
        case .cat: return .orange
        case .owl: return .brown
        case .penguin: return .charcoal
        case .dragon: return .teal
        case .lion: return .amber
        case .elephant: return .slate
        }
    }

    var defaultSecondary: ParkColour {
        switch self {
        case .bear: return .sand
        case .frog: return .lime
        case .bunny: return .pink
        case .duck: return .orange
        case .cat: return .cream
        case .owl: return .cream
        case .penguin: return .white
        case .dragon: return .amber
        case .lion: return .brown
        case .elephant: return .pink
        }
    }

    var defaultTrim: ParkColour {
        switch self {
        case .bear: return .red
        case .frog: return .red
        case .bunny: return .teal
        case .duck: return .blue
        case .cat: return .indigo
        case .owl: return .amber
        case .penguin: return .red
        case .dragon: return .red
        case .lion: return .red
        case .elephant: return .amber
        }
    }

    /// What each costume's secondary colour is, for the picker.
    var secondaryLabel: String {
        switch self {
        case .bear: return "Muzzle and belly"
        case .frog: return "Belly"
        case .bunny: return "Ears and nose"
        case .duck: return "Beak and feet"
        case .cat: return "Muzzle and belly"
        case .owl: return "Face and chest"
        case .penguin: return "Belly"
        case .dragon: return "Horns and belly"
        case .lion: return "Mane"
        case .elephant: return "Inner ears"
        }
    }

    private var names: [String] {
        switch self {
        case .bear: return ["Barnaby", "Bruno", "Honey"]
        case .frog: return ["Freddy", "Ribbit", "Lily"]
        case .bunny: return ["Clover", "Hopper", "Bunbun"]
        case .duck: return ["Waddles", "Dilly", "Quackers"]
        case .cat: return ["Whiskers", "Mitzi", "Tango"]
        case .owl: return ["Hoot", "Wisp", "Sage"]
        case .penguin: return ["Pip", "Gus", "Flipper"]
        case .dragon: return ["Ember", "Spark", "Draco"]
        case .lion: return ["Rory", "Goldie", "Marigold"]
        case .elephant: return ["Ellie", "Tusker", "Peanut"]
        }
    }

    func name(using generator: inout SeededGenerator) -> String {
        generator.pick(names) ?? displayName
    }
}

/// What the player chose when hiring, or when changing an employee's look.
/// Everything is optional: nil means the design's own default.
struct StaffStyle: Equatable {
    var act: EntertainerAct?
    var costume: MascotCostume?
    var primary: ParkColour?
    var secondary: ParkColour?
    var trim: ParkColour?

    static let standard = StaffStyle()

    /// The finished look, with every default filled in.
    func look(for role: StaffRole) -> StaffLook {
        let costume = self.costume ?? .bear
        let act = self.act ?? .classic

        switch role {
        case .mascot:
            return StaffLook(role: role, act: .classic, costume: costume,
                             primary: primary ?? costume.defaultPrimary,
                             secondary: secondary ?? costume.defaultSecondary,
                             trim: trim ?? costume.defaultTrim)
        case .entertainer:
            return StaffLook(role: role, act: act, costume: .bear,
                             primary: primary ?? act.defaultColour,
                             secondary: secondary ?? .cream,
                             trim: trim ?? .red)
        case .janitor, .mechanic, .security:
            return StaffLook(role: role, act: .classic, costume: .bear,
                             primary: .teal, secondary: .cream, trim: .red)
        }
    }
}

/// Everything the artwork needs to draw an employee, with every default
/// filled in, so the same value is both what is drawn and what the cached
/// drawing is filed under.
struct StaffLook: Hashable {
    let role: StaffRole
    let act: EntertainerAct
    let costume: MascotCostume
    let primary: ParkColour
    let secondary: ParkColour
    let trim: ParkColour
}

/// How an employee who performs affects the guests around them.
struct PerformerProfile {
    let radius: Double
    /// Multiplies `Balance.entertainerHappinessPerSecond`.
    let happinessFactor: Double
    let queueFactor: Double
    let childFactor: Double
    let handsOutBalloons: Bool
    let doesTricks: Bool

    static func of(_ member: Staff) -> PerformerProfile {
        if member.role == .mascot {
            return PerformerProfile(radius: Balance.entertainerRadius * Balance.mascotRadiusFactor,
                                    happinessFactor: Balance.mascotHappinessFactor,
                                    queueFactor: 1.4,
                                    childFactor: Balance.mascotChildFactor,
                                    handsOutBalloons: false,
                                    doesTricks: false)
        }
        let act = member.resolvedAct
        return PerformerProfile(radius: Balance.entertainerRadius * act.radiusFactor,
                                happinessFactor: act.happinessFactor,
                                queueFactor: act.queueFactor,
                                childFactor: 1,
                                handsOutBalloons: act.handsOutBalloons,
                                doesTricks: act.doesTricks)
    }
}
