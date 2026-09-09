import Foundation

struct PlacementCheck {
    let isValid: Bool
    let reason: String?

    static let valid = PlacementCheck(isValid: true, reason: nil)
    static func invalid(_ reason: String) -> PlacementCheck {
        PlacementCheck(isValid: false, reason: reason)
    }
}

/// Pure placement rules, kept out of `GameState` so the build preview can call
/// them every time the ghost moves without touching game state.
enum PlacementValidator {

    static func check(definition: BuildableDefinition,
                      origin: GridCoord,
                      map: ParkMap,
                      cash: Double) -> PlacementCheck {
        let rect = GridRect(origin: origin, size: definition.footprint)

        for coord in rect.coords where !map.isInside(coord) {
            return .invalid("Outside the park")
        }

        if definition.category == .path {
            guard let tile = map.tile(at: origin) else { return .invalid("Outside the park") }
            if tile.terrain == .path { return .invalid("Already a walkway") }
            if tile.terrain == .entrance { return .invalid("That is the entrance") }
            if tile.buildingID != nil { return .invalid("Something is in the way") }
        } else {
            guard map.isAreaBuildable(rect) else {
                return .invalid("Something is in the way")
            }
            if definition.requiresPathAccess && map.accessTiles(for: rect).isEmpty {
                return .invalid("Needs to touch a walkway")
            }
        }

        guard cash >= definition.purchasePrice else {
            return .invalid("Not enough cash")
        }

        return .valid
    }
}
