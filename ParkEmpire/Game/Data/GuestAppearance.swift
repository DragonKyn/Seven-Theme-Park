import Foundation

/// What one guest looks like.
///
/// Like `BuildingAppearance`, this is data rather than drawing code: it names
/// colours and a handful of choices, and only the rendering layer knows what
/// those mean in pixels. Combining small choices gives far more variety than
/// drawing a dozen fixed guests would, for far less code.
struct GuestAppearance: Codable, Equatable {
    let shirt: ParkColour
    let hair: HairColour
    let skin: SkinTone
    let hat: HatStyle
    /// Trousers, shorts or a skirt. Kept to a muted range: a crowd where
    /// everybody's legs are as loud as their shirt reads as noise.
    var bottoms: ParkColour = .slate
    var pattern: ShirtPattern = .plain
    /// What they brought with them for the day.
    var accessory: Accessory = .none

    enum HairColour: String, Codable, CaseIterable {
        case dark, brown, sandy, ginger, grey
    }

    enum SkinTone: String, Codable, CaseIterable {
        case deep, tan, olive, fair
    }

    enum HatStyle: String, Codable, CaseIterable {
        case none
        /// Flat brim, worn by about a third of the crowd.
        case cap
        /// Wide brim, more common on older guests.
        case sunHat
        /// Brim with no crown, for people who want their hair to show.
        case visor
        /// Novelty headband with two pom-poms, bought inside the park.
        case bobbleBand
        /// Pulled up over the head. Nobody in the ordinary crowd wears one:
        /// it is kept for the park's occasional nuisance, who has to be
        /// pickable out of four hundred people at a glance.
        case hood
    }

    /// What is printed on the shirt. Three is enough: past that, nobody can
    /// tell one from another at the size a guest is actually drawn.
    enum ShirtPattern: String, Codable, CaseIterable {
        case plain
        /// Two bands across the chest.
        case stripes
        /// A contrasting panel down the middle, like an open jacket.
        case vest
    }

    /// Something a day at a park puts in somebody's hands.
    enum Accessory: String, Codable, CaseIterable {
        case none
        case sunglasses
        case backpack
        /// On a strap round the neck, which is what marks out a visitor.
        case camera
        /// Held up in front of them, filming. Only the park's occasional
        /// famous visitor carries one.
        case phone
    }

    /// Shirt colours guests actually wear. Deliberately not the whole palette:
    /// park buildings use the muted end of it, and guests need to read as
    /// people against that rather than blend into a stall.
    static let shirtColours: [ParkColour] = [
        .red, .orange, .yellow, .lime, .teal, .cyan, .blue, .violet, .pink, .cream
    ]

    /// Legwear. Denim, khaki and dark, plus two brighter ones for children.
    static let bottomsColours: [ParkColour] = [
        .indigo, .slate, .charcoal, .brown, .sand, .blue
    ]

    static func random(for age: AgeCategory, using generator: inout SeededGenerator) -> GuestAppearance {
        let shirt = shirtColours[generator.int(0...(shirtColours.count - 1))]
        let bottoms = bottomsColours[generator.int(0...(bottomsColours.count - 1))]

        // Older guests grey; children almost never do.
        var hairChoices = HairColour.allCases.filter { $0 != .grey }
        if age == .senior { hairChoices = [.grey, .grey, .dark, .sandy] }
        let hair = hairChoices[generator.int(0...(hairChoices.count - 1))]

        let skin = SkinTone.allCases[generator.int(0...(SkinTone.allCases.count - 1))]

        // Roughly half the crowd wears something on their head. Sun hats skew
        // older, novelty headbands skew young, and a visor suits anybody.
        let roll = generator.double(0...1)
        let hat: HatStyle
        switch age {
        case .senior:
            hat = roll < 0.32 ? .sunHat : (roll < 0.48 ? .cap : (roll < 0.58 ? .visor : .none))
        case .child:
            hat = roll < 0.26 ? .cap : (roll < 0.46 ? .bobbleBand : (roll < 0.54 ? .visor : .none))
        case .adult:
            hat = roll < 0.24 ? .cap : (roll < 0.36 ? .sunHat : (roll < 0.48 ? .visor : .none))
        }

        // Plain shirts stay the majority, so a patterned one still stands out.
        let patternRoll = generator.double(0...1)
        let pattern: ShirtPattern = patternRoll < 0.58
            ? .plain
            : (patternRoll < 0.82 ? .stripes : .vest)

        let accessoryRoll = generator.double(0...1)
        let accessory: Accessory
        switch age {
        case .child:
            accessory = accessoryRoll < 0.30 ? .backpack : .none
        case .adult:
            accessory = accessoryRoll < 0.20 ? .camera
                : (accessoryRoll < 0.38 ? .backpack
                   : (accessoryRoll < 0.52 ? .sunglasses : .none))
        case .senior:
            accessory = accessoryRoll < 0.22 ? .camera
                : (accessoryRoll < 0.40 ? .sunglasses : .none)
        }

        return GuestAppearance(shirt: shirt,
                               hair: hair,
                               skin: skin,
                               hat: hat,
                               bottoms: bottoms,
                               pattern: pattern,
                               accessory: accessory)
    }

    /// Used when a save predates guest artwork.
    static let unknown = GuestAppearance(shirt: .blue, hair: .brown, skin: .tan, hat: .none)
}

extension GuestAppearance {
    /// Lenient decoding, like every entity: a guest saved before clothes had
    /// colours comes back dressed in the defaults rather than failing the
    /// whole appearance and turning the crowd into clones.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        shirt = container.value(.shirt, or: .blue)
        hair = container.value(.hair, or: .brown)
        skin = container.value(.skin, or: .tan)
        hat = container.value(.hat, or: HatStyle.none)
        bottoms = container.value(.bottoms, or: .slate)
        pattern = container.value(.pattern, or: .plain)
        accessory = container.value(.accessory, or: Accessory.none)
    }
}

/// What a thought is about, so a bubble over a guest's head can say it
/// without words.
enum ThoughtIcon: String, Codable {
    case general
    case food
    case drink
    case restroom
    case ride
    case money
    case tired
    case dirty
    case queue

    /// SF Symbol drawn inside the bubble. Mood colours the bubble; this says
    /// what the thought is about.
    var symbolName: String {
        switch self {
        case .general: return "bubble.left.fill"
        case .food: return "fork.knife"
        case .drink: return "cup.and.saucer.fill"
        case .restroom: return "figure.stand"
        case .ride: return "sparkles"
        case .money: return "dollarsign.circle.fill"
        case .tired: return "figure.seated.side"
        case .dirty: return "trash.fill"
        case .queue: return "clock.fill"
        }
    }
}
