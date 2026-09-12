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
                      rotation: Int = 0,
                      map: ParkMap,
                      cash: Double) -> PlacementCheck {
        let rect = GridRect(origin: origin, size: definition.footprint(rotatedBy: rotation))

        for coord in rect.coords where !map.isInside(coord) {
            return .invalid("Outside the park")
        }

        if let terrainDefinition = definition as? TerrainDefinition {
            // Most terrain is painted onto bare grass. The exceptions are the
            // ones that are a finish rather than a thing: a walkway can be
            // repaved without being dug up, and a bridge goes on the water it
            // is there to cross.
            guard let tile = map.tile(at: origin) else { return .invalid("Outside the park") }
            if tile.terrain == terrainDefinition.terrain && tile.style == terrainDefinition.style {
                return .invalid("Already \(terrainDefinition.displayName.lowercased())")
            }
            if tile.terrain == .entrance { return .invalid("That is the entrance") }
            guard terrainDefinition.placeableOn.contains(tile.terrain) else {
                if terrainDefinition.terrain == .bridge {
                    return .invalid("Bridges go over water")
                }
                return .invalid("Clear the ground here first")
            }
            if tile.buildingID != nil { return .invalid("Something is in the way") }
        } else if definition.laysCoasterTrack {
            // Goes on bare ground or on track already laid, and brings its own
            // rails either way.
            for coord in rect.coords {
                guard let tile = map.tile(at: coord) else { return .invalid("Outside the park") }
                guard tile.terrain == .grass || tile.terrain.isCoasterTrack else {
                    return .invalid("Needs clear ground or coaster track")
                }
                guard !tile.isOccupied else {
                    return .invalid("Something is already here")
                }
            }
        } else if let bed = definition.bedTerrain {
            // Built on top of something rather than beside it: every tile it
            // covers has to be that terrain, and free.
            for coord in rect.coords {
                guard let tile = map.tile(at: coord) else { return .invalid("Outside the park") }
                let matches = bed == .coasterTrack
                    ? tile.terrain.isCoasterTrack
                    : tile.terrain == bed
                guard matches else {
                    switch bed {
                    case .water: return .invalid("Needs to sit on water")
                    case .path: return .invalid("Goes on a walkway")
                    default: return .invalid("Lay coaster track here first")
                    }
                }
                guard !tile.isOccupied else {
                    return .invalid("Something is already here")
                }
            }
            if definition.requiresPathAccess && map.accessTiles(for: rect).isEmpty {
                return .invalid("Needs to touch a walkway")
            }
        } else {
            guard map.isAreaBuildable(rect) else {
                return .invalid("Something is in the way")
            }
            if definition.requiresPathAccess && map.accessTiles(for: rect).isEmpty {
                return .invalid("Needs to touch a walkway")
            }
            if definition.requiresTrackAccess && !map.touchesTerrain(.track, around: rect) {
                return .invalid("Needs to touch a track")
            }
            if definition.requiresCoasterTrackAccess
                && !map.touchesTerrain(.coasterTrack, around: rect) {
                return .invalid("Needs to touch coaster track")
            }
        }

        guard cash >= definition.purchasePrice else {
            return .invalid("Not enough cash")
        }

        return .valid
    }
}
