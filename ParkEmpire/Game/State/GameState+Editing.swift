import Foundation

/// Changes to things that are already built: turning them round, and
/// repainting decoration. Placing and removing live in `GameState+Building`.
extension GameState {

    // MARK: - Decoration

    func setSceneryStyle(_ variant: Int, id: UUID) {
        guard let index = sceneryIndex(id: id) else { return }
        scenery[index].variant = variant
    }

    /// Nil puts the colours back to the ones the piece was designed in.
    func setSceneryColour(_ colour: ParkColour?, id: UUID) {
        guard let index = sceneryIndex(id: id) else { return }
        scenery[index].colour = colour
    }

    // MARK: - Turning

    /// Turns a decoration a quarter clockwise, if there is room for it to
    /// stand that way. A long piece turned on the spot sweeps out different
    /// ground, so it can be refused where a square one never is.
    @discardableResult
    func turnScenery(id: UUID) -> Bool {
        guard let index = sceneryIndex(id: id),
              let definition = scenery[index].definition else { return false }
        let item = scenery[index]
        let next = (item.rotation + 1) % 4

        guard refit(definition,
                    id: id,
                    from: item.rect,
                    origin: item.origin,
                    rotation: next,
                    blocking: !definition.leavesWalkwayOpen) else { return false }

        scenery[index].rotation = next
        scenery[index].size = definition.footprint(rotatedBy: next)
        return true
    }

    @discardableResult
    func turnFacility(id: UUID) -> Bool {
        guard let index = facilityIndex(id: id),
              let definition = facilities[index].baseDefinition else { return false }
        let facility = facilities[index]
        let next = (facility.rotation + 1) % 4
        let blocking = !definition.kind.isFurniture

        guard refit(definition,
                    id: id,
                    from: facility.rect,
                    origin: facility.origin,
                    rotation: next,
                    blocking: blocking) else { return false }

        facilities[index].rotation = next
        facilities[index].size = definition.footprint(rotatedBy: next)
        if blocking { clearGround(of: facilities[index].rect) }
        // Somebody sitting at a bench that has only been turned stays sat. It
        // is a different shape of ground that sends people on their way.
        if facilities[index].size != facility.size {
            evictGuests(from: .facility(id))
        }
        return true
    }

    @discardableResult
    func turnAttraction(id: UUID) -> Bool {
        guard let index = attractionIndex(id: id),
              let definition = GameContent.attraction(attractions[index].definitionID) else { return false }
        let attraction = attractions[index]
        let next = (attraction.rotation + 1) % 4

        guard refit(definition,
                    id: id,
                    from: attraction.rect,
                    origin: attraction.origin,
                    rotation: next,
                    blocking: true) else { return false }

        attractions[index].rotation = next
        attractions[index].size = definition.footprint(rotatedBy: next)
        clearGround(of: attractions[index].rect)
        if attractions[index].size != attraction.size {
            evictGuests(from: .attraction(id))
        }
        return true
    }

    /// Moves a building's claim on the map from the ground it held to the
    /// ground it would hold once turned, if the placement rules allow it.
    ///
    /// The old ground is let go first, so that the building does not count as
    /// being in its own way, and taken back if the new one is refused.
    private func refit(_ definition: BuildableDefinition,
                       id: UUID,
                       from old: GridRect,
                       origin: GridCoord,
                       rotation: Int,
                       blocking: Bool) -> Bool {
        let new = GridRect(origin: origin, size: definition.footprint(rotatedBy: rotation))

        map.setBuilding(nil, on: old.coords)
        let check = PlacementValidator.check(definition: definition,
                                             origin: origin,
                                             rotation: rotation,
                                             map: map,
                                             cash: .infinity,
                                             price: 0)
        guard check.isValid else {
            map.setBuilding(id, on: old.coords, blocking: blocking)
            return false
        }
        map.setBuilding(id, on: new.coords, blocking: blocking)
        return true
    }
}
