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
            // Built on top of something rather than beside it.
            for coord in rect.coords {
                guard let tile = map.tile(at: coord) else { return .invalid("Outside the park") }
                guard !tile.isOccupied else {
                    return .invalid("Something is already here")
                }
            }

            let onBed = rect.coords.allSatisfy { coord in
                guard let tile = map.tile(at: coord) else { return false }
                return bed == .coasterTrack ? tile.terrain.isCoasterTrack : tile.terrain == bed
            }

            if onBed {
                if definition.requiresPathAccess && map.accessTiles(for: rect).isEmpty {
                    return .invalid("Needs to touch a walkway")
                }
            } else if definition.maySitBesideBed {
                // Off the path is allowed, so long as somebody standing on the
                // path can still reach it. That is what keeps a bin on the
                // grass a bin rather than an ornament.
                guard map.isAreaBuildable(rect) else {
                    return .invalid("Something is in the way")
                }
                guard !map.accessTiles(for: rect).isEmpty else {
                    return .invalid("Put it on a walkway, or on the ground beside one")
                }
            } else {
                switch bed {
                case .water: return .invalid("Needs to sit on water")
                case .path: return .invalid("Goes on a walkway")
                default: return .invalid("Lay coaster track here first")
                }
            }
        } else if definition.mayStandOnWalkway && map.isWalkwayArea(rect) {
            // Straddles the path rather than standing beside it. Placed
            // without blocking, so the route underneath stays open.
            for coord in rect.coords {
                guard map.tile(at: coord)?.isOccupied == false else {
                    return .invalid("Something is already here")
                }
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
