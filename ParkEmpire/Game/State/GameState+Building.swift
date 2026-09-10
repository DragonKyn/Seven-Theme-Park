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
        case let terrainDefinition as TerrainDefinition:
            map.setTerrain(terrainDefinition.terrain, at: origin)
            if terrainDefinition.beauty > 0 { refreshBeauty() }

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

        case let sceneryDefinition as SceneryDefinition:
            let item = SceneryItem(
                id: UUID(),
                definitionID: sceneryDefinition.id,
                origin: origin,
                size: sceneryDefinition.footprint
            )
            scenery.append(item)
            map.setBuilding(item.id, on: item.rect.coords)
            refreshBeauty()

        default:
            return false
        }

        ledger.spend(definition.purchasePrice, on: .construction)
        return true
    }

    /// Rebuilds the tile beauty field from everything currently placed.
    /// Called on every change rather than tracked incrementally, because
    /// removing one item can uncover overlap from several others.
    func refreshBeauty() {
        var sources = scenery.compactMap { item -> ParkMap.BeautySource? in
            guard let definition = item.definition else { return nil }
            return ParkMap.BeautySource(rect: item.rect,
                                        beauty: definition.beauty,
                                        radius: definition.beautyRadius)
        }

        // Water is terrain rather than an object, so it has no entity to hang
        // its prettiness on and is folded in a tile at a time instead.
        for definition in GameContent.terrains where definition.beauty > 0 {
            for coord in map.coords(ofTerrain: definition.terrain) {
                sources.append(ParkMap.BeautySource(rect: GridRect(origin: coord, size: .single),
                                                    beauty: definition.beauty,
                                                    radius: definition.beautyRadius))
            }
        }

        map.recomputeBeauty(from: sources)
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
        if let item = sceneryItem(at: coord) {
            return (item.definition?.purchasePrice ?? 0) * 0.5
        }
        if let terrain = map.tile(at: coord)?.terrain,
           let definition = GameContent.terrains.first(where: { $0.terrain == terrain }) {
            return definition.refundValue
        }
        return 0
    }

    /// Scenery deliberately is not a `ParkTarget`: guests never travel to it
    /// and there is nothing to inspect, so it is found by tile instead.
    func sceneryItem(at coord: GridCoord) -> SceneryItem? {
        guard let buildingID = map.tile(at: coord)?.buildingID else { return nil }
        return scenery.first { $0.id == buildingID }
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

        if let item = sceneryItem(at: coord), let index = sceneryIndex(id: item.id) {
            map.setBuilding(nil, on: item.rect.coords)
            scenery.remove(at: index)
            refreshBeauty()
            ledger.receive(demolitionRefundValue(for: item.definition), as: .other)
            return true
        }

        guard let tile = map.tile(at: coord),
              let definition = GameContent.terrains.first(where: { $0.terrain == tile.terrain })
        else { return false }

        map.setTerrain(.grass, at: coord)
        if definition.beauty > 0 { refreshBeauty() }
        ledger.receive(definition.refundValue, as: .other)
        return true
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
