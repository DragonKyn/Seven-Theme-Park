import Foundation

/// Build and demolish commands. These are the only supported way for the UI to
/// change the park's layout.
extension GameState {

    func placementCheck(for definition: BuildableDefinition,
                        at origin: GridCoord,
                        rotation: Int = 0) -> PlacementCheck {
        PlacementValidator.check(definition: definition,
                                 origin: origin,
                                 rotation: rotation,
                                 map: map,
                                 cash: ledger.spendableCash)
    }

    @discardableResult
    /// `variant` picks which cut of a shape is built; nil leaves it to
    /// chance, which is what makes a row of trees look like a row of trees.
    func place(_ definition: BuildableDefinition,
               at origin: GridCoord,
               rotation: Int = 0,
               variant: Int? = nil) -> Bool {
        guard placementCheck(for: definition, at: origin, rotation: rotation).isValid else {
            return false
        }

        // Money only moves once we know the definition is one we can build.
        switch definition {
        case let terrainDefinition as TerrainDefinition:
            map.setTerrain(terrainDefinition.terrain,
                           at: origin,
                           style: terrainDefinition.style)
            if terrainDefinition.beauty > 0 { refreshBeauty() }

        case let attractionDefinition as AttractionDefinition:
            let attraction = Attraction(
                id: UUID(),
                definitionID: attractionDefinition.id,
                name: uniqueName(for: attractionDefinition.displayName),
                origin: origin,
                size: attractionDefinition.footprint(rotatedBy: rotation),
                rotation: rotation
            )
            attractions.append(attraction)
            map.setBuilding(attraction.id, on: attraction.rect.coords)

        case let facilityDefinition as FacilityDefinition:
            let facility = Facility(
                id: UUID(),
                definitionID: facilityDefinition.id,
                name: uniqueName(for: facilityDefinition.displayName),
                origin: origin,
                size: facilityDefinition.footprint(rotatedBy: rotation),
                rotation: rotation,
                price: facilityDefinition.defaultPrice
            )
            facilities.append(facility)
            map.setBuilding(facility.id,
                            on: facility.rect.coords,
                            blocking: !facilityDefinition.kind.isFurniture)

        case let elementDefinition as CoasterElementDefinition:
            let element = TrackElement(
                id: UUID(),
                definitionID: elementDefinition.id,
                origin: origin,
                size: elementDefinition.footprint(rotatedBy: rotation),
                rotation: rotation
            )
            // Lays its own rails, so an element can be dropped on bare ground
            // and joined up afterwards.
            for coord in element.rect.coords {
                map.setTerrain(.coasterTrack, at: coord)
            }
            trackElements.append(element)
            // Claiming the tiles is what stops two elements being stacked on
            // one another; the terrain underneath stays track either way.
            map.setBuilding(element.id, on: element.rect.coords)

        case let sceneryDefinition as SceneryDefinition:
            let styles = sceneryDefinition.appearance.motif.variantCount
            let style = variant ?? (styles > 1 ? rng.int(0...(styles - 1)) : 0)
            let item = SceneryItem(
                id: UUID(),
                definitionID: sceneryDefinition.id,
                origin: origin,
                size: sceneryDefinition.footprint(rotatedBy: rotation),
                rotation: rotation,
                variant: style
            )
            scenery.append(item)
            map.setBuilding(item.id,
                            on: item.rect.coords,
                            blocking: !sceneryDefinition.mayStandOnWalkway)
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

        // A themed ride decorates the ground around it, which is half of why
        // theming is worth buying.
        for attraction in attractions {
            let level = attraction.upgradeLevel(.theming)
            guard level > 0 else { continue }
            sources.append(ParkMap.BeautySource(rect: attraction.rect,
                                                beauty: UpgradeContent.themingBeauty(level: level),
                                                radius: UpgradeContent.themingBeautyRadius))
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
        if let element = trackElement(at: coord) {
            return (element.definition?.purchasePrice ?? 0) * 0.5
        }
        if let item = sceneryItem(at: coord) {
            return (item.definition?.purchasePrice ?? 0) * 0.5
        }
        if let tile = map.tile(at: coord),
           let definition = GameContent.terrains.first(where: { $0.terrain == tile.terrain
                                                                && $0.style == tile.style })
            ?? GameContent.terrains.first(where: { $0.terrain == tile.terrain }) {
            return definition.refundValue
        }
        return 0
    }

    /// Scenery deliberately is not a `ParkTarget`: guests never travel to it
    /// and there is nothing to inspect, so it is found by tile instead.
    /// Like scenery, an element is found by tile rather than being a target:
    /// guests never travel to one and there is nothing to inspect.
    func trackElement(at coord: GridCoord) -> TrackElement? {
        guard let buildingID = map.tile(at: coord)?.buildingID else { return nil }
        return trackElements.first { $0.id == buildingID }
    }

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
                // A themed ride decorated the ground around it, so taking it
                // away has to take that with it.
                if attraction.upgradeLevel(.theming) > 0 { refreshBeauty() }
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

        if let element = trackElement(at: coord),
           let index = trackElements.firstIndex(where: { $0.id == element.id }) {
            map.setBuilding(nil, on: element.rect.coords)
            trackElements.remove(at: index)
            ledger.receive(demolitionRefundValue(for: element.definition), as: .other)
            return true
        }

        if let item = sceneryItem(at: coord), let index = sceneryIndex(id: item.id) {
            map.setBuilding(nil, on: item.rect.coords)
            scenery.remove(at: index)
            refreshBeauty()
            ledger.receive(demolitionRefundValue(for: item.definition), as: .other)
            return true
        }

        guard let tile = map.tile(at: coord) else { return false }
        // Matched on the finish as well as the terrain, so taking up a
        // boardwalk does not refund the price of plain paving.
        let terrains = GameContent.terrains
        guard let definition = terrains.first(where: { $0.terrain == tile.terrain
                                                       && $0.style == tile.style })
            ?? terrains.first(where: { $0.terrain == tile.terrain })
        else { return false }

        // Taking a bridge out leaves the water it was crossing, not a hole in
        // the pond.
        map.setTerrain(tile.terrain == .bridge ? .water : .grass, at: coord)
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
