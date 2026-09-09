import Foundation

/// Build and demolish commands. These are the only supported way for the UI to
/// change the park's layout.
extension GameState {

    func placementCheck(for definition: BuildableDefinition, at origin: GridCoord) -> PlacementCheck {
        PlacementValidator.check(definition: definition,
                                 origin: origin,
                                 map: map,
                                 cash: ledger.cash)
    }

    @discardableResult
    func place(_ definition: BuildableDefinition, at origin: GridCoord) -> Bool {
        guard placementCheck(for: definition, at: origin).isValid else { return false }

        // Money only moves once we know the definition is one we can build.
        switch definition {
        case is PathDefinition:
            map.setTerrain(.path, at: origin)

        case let attractionDefinition as AttractionDefinition:
            let attraction = Attraction(
                id: UUID(),
                definitionID: attractionDefinition.id,
                name: uniqueName(for: attractionDefinition.displayName),
                origin: origin,
                size: attractionDefinition.footprint
            )
            attractions.append(attraction)
            map.setBuilding(attraction.id, on: attraction.rect.coords)

        case let facilityDefinition as FacilityDefinition:
            let facility = Facility(
                id: UUID(),
                definitionID: facilityDefinition.id,
                name: uniqueName(for: facilityDefinition.displayName),
                origin: origin,
                size: facilityDefinition.footprint,
                price: facilityDefinition.defaultPrice
            )
            facilities.append(facility)
            map.setBuilding(facility.id, on: facility.rect.coords)

        default:
            return false
        }

        ledger.spend(definition.purchasePrice, on: .construction)
        return true
    }

    /// What sits on a tile, if anything.
    func target(at coord: GridCoord) -> ParkTarget? {
        guard let tile = map.tile(at: coord) else { return nil }
        guard let buildingID = tile.buildingID else { return nil }
        if attractionIndex(id: buildingID) != nil { return .attraction(buildingID) }
        if facilityIndex(id: buildingID) != nil { return .facility(buildingID) }
        return nil
    }

    /// Value returned to the player when demolishing.
    func demolitionRefund(at coord: GridCoord) -> Double {
        if let target = target(at: coord) {
            switch target {
            case .attraction(let id):
                guard let definition = attraction(id: id)?.definition else { return 0 }
                return definition.purchasePrice * 0.5
            case .facility(let id):
                guard let definition = facility(id: id)?.definition else { return 0 }
                return definition.purchasePrice * 0.5
            default:
                return 0
            }
        }
        if map.tile(at: coord)?.terrain == .path {
            return GameContent.path.refundValue
        }
        return 0
    }

    @discardableResult
    func demolish(at coord: GridCoord) -> Bool {
        if let target = target(at: coord) {
            switch target {
            case .attraction(let id):
                guard let index = attractionIndex(id: id) else { return false }
                let attraction = attractions[index]
                evictGuests(from: target)
                map.setBuilding(nil, on: attraction.rect.coords)
                attractions.remove(at: index)
                ledger.receive(demolitionRefundValue(for: attraction.definition), as: .other)
                return true

            case .facility(let id):
                guard let index = facilityIndex(id: id) else { return false }
                let facility = facilities[index]
                evictGuests(from: target)
                map.setBuilding(nil, on: facility.rect.coords)
                facilities.remove(at: index)
                ledger.receive(demolitionRefundValue(for: facility.definition), as: .other)
                return true

            default:
                return false
            }
        }

        guard let tile = map.tile(at: coord) else { return false }
        if tile.terrain == .path {
            map.setTerrain(.grass, at: coord)
            ledger.receive(GameContent.path.refundValue, as: .other)
            return true
        }
        return false
    }

    private func demolitionRefundValue(for definition: BuildableDefinition?) -> Double {
        guard let definition else { return 0 }
        return definition.purchasePrice * 0.5
    }

    /// Sends anyone queueing for or using a removed object back onto the paths.
    private func evictGuests(from target: ParkTarget) {
        for index in guests.indices {
            switch guests[index].activity {
            case .walking(let current), .queueing(let current), .engaged(let current):
                if current == target {
                    guests[index].activity = .exploring
                    guests[index].route = []
                    guests[index].nextDecisionAt = clock.simTime
                }
            default:
                break
            }
        }
    }

    private func uniqueName(for base: String) -> String {
        let existing = Set(attractions.map(\.name)).union(facilities.map(\.name))
        if !existing.contains(base) { return base }
        var suffix = 2
        while existing.contains("\(base) \(suffix)") { suffix += 1 }
        return "\(base) \(suffix)"
    }
}
