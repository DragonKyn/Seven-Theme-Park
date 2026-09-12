import CoreGraphics
import Foundation

/// Something a guest won at a carnival booth and is now carrying around.
///
/// Data rather than drawing, like `GuestAppearance`: it names a shape and a
/// colour, and only the rendering layer knows what a "bear" looks like. A
/// handful of shapes across a handful of colours is enough that two guests
/// walking past each other are rarely carrying the same thing.
struct GuestPrize: Codable, Equatable {
    let kind: Kind
    let colour: ParkColour
    /// How big a thing they walked out with. The hard booths are the ones
    /// worth queueing for, so difficulty is what decides this.
    var size: Size = .small

    enum Size: String, Codable, CaseIterable {
        case small
        case big
        case giant

        /// How much bigger than the smallest prize this one is drawn.
        var scale: CGFloat {
            switch self {
            case .small: return 0.85
            case .big: return 1.25
            case .giant: return 1.60
            }
        }

        /// A giant prize is too big to tuck under an arm, so it is carried in
        /// front with both arms round it.
        var isHugged: Bool { self == .giant }

        var adjective: String? {
            switch self {
            case .small: return nil
            case .big: return "big"
            case .giant: return "giant"
            }
        }
    }

    enum Kind: String, Codable, CaseIterable {
        case bear
        case dog
        case bunny
        case duck
        case star
        case ball

        var displayName: String {
            switch self {
            case .bear: return "bear"
            case .dog: return "dog"
            case .bunny: return "bunny"
            case .duck: return "duck"
            case .star: return "star"
            case .ball: return "beach ball"
            }
        }
    }

    /// Prize colours: the loud end of the palette, because a prize nobody can
    /// see across the park is not worth carrying.
    static let colours: [ParkColour] = [
        .pink, .cyan, .yellow, .lime, .violet, .red, .orange, .teal
    ]

    /// `winChance` is how easy the booth is. A booth nearly everybody wins at
    /// hands out keyrings; one hardly anybody wins at hands out the bear that
    /// takes two arms to carry, which is the whole reason to play it.
    static func random(using generator: inout SeededGenerator,
                       winChance: Double) -> GuestPrize {
        let kinds = Kind.allCases
        let kind = kinds[generator.int(0...(kinds.count - 1))]
        let colour = colours[generator.int(0...(colours.count - 1))]

        // Difficulty sets the odds; the roll still leaves room for a small
        // prize off a hard booth and the occasional giant off an easy one.
        let difficulty = 1 - min(max(winChance, 0), 1)
        let roll = generator.double(0...1)
        let size: Size
        if roll < difficulty * difficulty * 0.8 {
            size = .giant
        } else if roll < difficulty {
            size = .big
        } else {
            size = .small
        }

        return GuestPrize(kind: kind, colour: colour, size: size)
    }

    /// "giant pink bear", for the thought a guest has on winning it.
    var displayName: String {
        guard let adjective = size.adjective else { return "\(colourName) \(kind.displayName)" }
        return "\(adjective) \(colourName) \(kind.displayName)"
    }

    private var colourName: String {
        switch colour {
        case .cyan: return "blue"
        case .lime: return "green"
        case .violet: return "purple"
        case .amber: return "gold"
        default: return colour.rawValue
        }
    }
}
