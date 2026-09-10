import SpriteKit
import UIKit

/// Colours for the map. Bright, flat and high-contrast so the park stays
/// readable on a phone at a glance.
enum ParkPalette {
    static let grass = UIColor(red: 0.55, green: 0.78, blue: 0.45, alpha: 1)
    static let grassAlt = UIColor(red: 0.51, green: 0.74, blue: 0.42, alpha: 1)
    static let path = UIColor(red: 0.87, green: 0.84, blue: 0.76, alpha: 1)
    static let entrance = UIColor(red: 0.96, green: 0.74, blue: 0.30, alpha: 1)
    static let water = UIColor(red: 0.35, green: 0.63, blue: 0.86, alpha: 1)
    static let waterAlt = UIColor(red: 0.31, green: 0.58, blue: 0.83, alpha: 1)

    static let ride = UIColor(red: 0.36, green: 0.55, blue: 0.92, alpha: 1)
    static let food = UIColor(red: 0.94, green: 0.51, blue: 0.35, alpha: 1)
    static let drink = UIColor(red: 0.36, green: 0.75, blue: 0.82, alpha: 1)
    static let bathroom = UIColor(red: 0.63, green: 0.53, blue: 0.86, alpha: 1)
    static let bench = UIColor(red: 0.68, green: 0.52, blue: 0.36, alpha: 1)
    static let shop = UIColor(red: 0.92, green: 0.62, blue: 0.78, alpha: 1)

    static let ghostValid = UIColor(red: 0.30, green: 0.85, blue: 0.45, alpha: 0.55)
    static let ghostInvalid = UIColor(red: 0.92, green: 0.30, blue: 0.30, alpha: 0.55)

    static let guestHappy = UIColor(red: 0.20, green: 0.72, blue: 0.35, alpha: 1)
    static let guestNeutral = UIColor(red: 0.97, green: 0.78, blue: 0.24, alpha: 1)
    static let guestUnhappy = UIColor(red: 0.90, green: 0.32, blue: 0.28, alpha: 1)

    static let asphalt = UIColor(red: 0.34, green: 0.35, blue: 0.38, alpha: 1)
    static let bayLine = UIColor(red: 0.86, green: 0.86, blue: 0.83, alpha: 0.85)

    static let signPost = UIColor(red: 0.47, green: 0.33, blue: 0.22, alpha: 1)
    static let signFace = UIColor(red: 0.98, green: 0.94, blue: 0.84, alpha: 1)
    static let signFrame = UIColor(red: 0.90, green: 0.55, blue: 0.20, alpha: 1)
    static let signText = UIColor(red: 0.32, green: 0.21, blue: 0.12, alpha: 1)

    static let selection = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
    static let bin = UIColor(red: 0.45, green: 0.50, blue: 0.55, alpha: 1)
    static let litter = UIColor(red: 0.58, green: 0.47, blue: 0.30, alpha: 1)
    static let broken = UIColor(red: 0.88, green: 0.24, blue: 0.22, alpha: 1)
    static let badge = UIColor(red: 0.15, green: 0.17, blue: 0.22, alpha: 0.9)

    static let janitor = UIColor(red: 0.30, green: 0.72, blue: 0.62, alpha: 1)
    static let mechanic = UIColor(red: 0.98, green: 0.62, blue: 0.15, alpha: 1)
    static let entertainer = UIColor(red: 0.85, green: 0.36, blue: 0.72, alpha: 1)

    static func colour(for role: StaffRole) -> UIColor {
        switch role {
        case .janitor: return janitor
        case .mechanic: return mechanic
        case .entertainer: return entertainer
        }
    }

    static func colour(for kind: FacilityKind) -> UIColor {
        switch kind {
        case .food: return food
        case .drink: return drink
        case .bathroom: return bathroom
        case .bench: return bench
        case .souvenir: return shop
        case .bin: return bin
        }
    }

    /// The flat colour of one terrain tile. Checkerboarded terrains take a
    /// second shade so a large expanse of them does not read as a solid slab.
    static func colour(for terrain: TerrainType, alternate: Bool) -> UIColor {
        switch terrain {
        case .path: return path
        case .entrance: return entrance
        case .water: return alternate ? waterAlt : water
        case .grass: return alternate ? grassAlt : grass
        }
    }

    static func guestColour(happiness: Double) -> UIColor {
        switch happiness {
        case ..<40: return guestUnhappy
        case ..<70: return guestNeutral
        default: return guestHappy
        }
    }

    // MARK: - Named content colours

    /// Resolves the colour names used by the content catalogue. This is the
    /// only place a `ParkColour` becomes pixels, so the whole park can be
    /// retinted from here.
    static func colour(_ colour: ParkColour) -> UIColor {
        switch colour {
        case .red:      return UIColor(red: 0.89, green: 0.29, blue: 0.28, alpha: 1)
        case .orange:   return UIColor(red: 0.95, green: 0.53, blue: 0.26, alpha: 1)
        case .amber:    return UIColor(red: 0.96, green: 0.70, blue: 0.24, alpha: 1)
        case .yellow:   return UIColor(red: 0.98, green: 0.84, blue: 0.33, alpha: 1)
        case .lime:     return UIColor(red: 0.66, green: 0.83, blue: 0.36, alpha: 1)
        case .green:    return UIColor(red: 0.32, green: 0.71, blue: 0.42, alpha: 1)
        case .teal:     return UIColor(red: 0.25, green: 0.70, blue: 0.64, alpha: 1)
        case .cyan:     return UIColor(red: 0.38, green: 0.78, blue: 0.85, alpha: 1)
        case .blue:     return UIColor(red: 0.33, green: 0.55, blue: 0.90, alpha: 1)
        case .indigo:   return UIColor(red: 0.36, green: 0.40, blue: 0.78, alpha: 1)
        case .violet:   return UIColor(red: 0.60, green: 0.45, blue: 0.85, alpha: 1)
        case .pink:     return UIColor(red: 0.93, green: 0.55, blue: 0.74, alpha: 1)
        case .cream:    return UIColor(red: 0.98, green: 0.95, blue: 0.87, alpha: 1)
        case .sand:     return UIColor(red: 0.88, green: 0.80, blue: 0.64, alpha: 1)
        case .brown:    return UIColor(red: 0.60, green: 0.44, blue: 0.31, alpha: 1)
        case .slate:    return UIColor(red: 0.47, green: 0.53, blue: 0.60, alpha: 1)
        case .charcoal: return UIColor(red: 0.24, green: 0.26, blue: 0.31, alpha: 1)
        case .white:    return UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
        }
    }
}
