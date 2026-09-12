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

    static func random(using generator: inout SeededGenerator) -> GuestPrize {
        let kinds = Kind.allCases
        return GuestPrize(kind: kinds[generator.int(0...(kinds.count - 1))],
                          colour: colours[generator.int(0...(colours.count - 1))])
    }

    /// "pink bear", for the thought a guest has on winning it.
    var displayName: String {
        "\(colourName) \(kind.displayName)"
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
