import Foundation

/// What one guest looks like.
///
/// Like `BuildingAppearance`, this is data rather than drawing code: it names
/// colours and a couple of choices, and only the rendering layer knows what
/// those mean in pixels. Combining four small choices gives far more variety
/// than drawing a dozen fixed guests would, for far less code.
struct GuestAppearance: Codable, Equatable {
    let shirt: ParkColour
    let hair: HairColour
    let skin: SkinTone
    let hat: HatStyle

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
    }

    /// Shirt colours guests actually wear. Deliberately not the whole palette:
    /// park buildings use the muted end of it, and guests need to read as
    /// people against that rather than blend into a stall.
    static let shirtColours: [ParkColour] = [
        .red, .orange, .yellow, .lime, .teal, .cyan, .blue, .violet, .pink, .cream
    ]

    static func random(for age: AgeCategory, using generator: inout SeededGenerator) -> GuestAppearance {
        let shirt = shirtColours[generator.int(0...(shirtColours.count - 1))]

        // Older guests grey; children almost never do.
        var hairChoices = HairColour.allCases.filter { $0 != .grey }
        if age == .senior { hairChoices = [.grey, .grey, .dark, .sandy] }
        let hair = hairChoices[generator.int(0...(hairChoices.count - 1))]

        let skin = SkinTone.allCases[generator.int(0...(SkinTone.allCases.count - 1))]

        // Roughly half the crowd wears something on their head, and sun hats
        // skew older, which is enough to make a queue look like a mix of people.
        let roll = generator.double(0...1)
        let hat: HatStyle
        switch age {
        case .senior: hat = roll < 0.35 ? .sunHat : (roll < 0.55 ? .cap : .none)
        case .child: hat = roll < 0.40 ? .cap : .none
        case .adult: hat = roll < 0.28 ? .cap : (roll < 0.42 ? .sunHat : .none)
        }

        return GuestAppearance(shirt: shirt, hair: hair, skin: skin, hat: hat)
    }

    /// Used when a save predates guest artwork.
    static let unknown = GuestAppearance(shirt: .blue, hair: .brown, skin: .tan, hat: .none)
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
