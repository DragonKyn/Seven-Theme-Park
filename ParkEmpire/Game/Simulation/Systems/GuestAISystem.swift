import Foundation

/// Needs, thoughts and decision making.
///
/// Guests do not re-plan every tick: needs decay continuously, but a guest only
/// picks a new goal every `Balance.decisionInterval` sim-seconds (jittered per
/// guest so the work spreads across ticks rather than spiking on one).
final class GuestAISystem {

    private let pathfinder: PathfindingSystem
    private var cachedWalkableTiles: [GridCoord] = []
    private var cachedGeneration = -1

    init(pathfinder: PathfindingSystem) {
        self.pathfinder = pathfinder
    }

    // MARK: - Entry point

    func update(state: GameState, dt: Double) {
        refreshWalkableCache(state.map)
        let now = state.clock.simTime

        for index in state.guests.indices {
            guard state.guests[index].isActive else { continue }
            updateNeeds(index: index, state: state, dt: dt)
            updateThoughts(index: index, state: state, now: now)
            updateQueuePatience(index: index, state: state, now: now)

            guard shouldDecide(state.guests[index], now: now) else { continue }
            decide(index: index, state: state, now: now)
        }
    }

    // MARK: - Needs

    private func updateNeeds(index: Int, state: GameState, dt: Double) {
        let isMoving: Bool
        switch state.guests[index].activity {
        case .walking, .arriving, .exploring: isMoving = true
        default: isMoving = false
        }

        state.guests[index].timeInPark += dt
        state.guests[index].hunger = SimMath.clamp(state.guests[index].hunger + Balance.hungerRate * dt)
        state.guests[index].thirst = SimMath.clamp(state.guests[index].thirst + Balance.thirstRate * dt)
        state.guests[index].bathroomNeed = SimMath.clamp(state.guests[index].bathroomNeed + Balance.bathroomRate * dt)
        state.guests[index].nausea = SimMath.clamp(state.guests[index].nausea - Balance.nauseaDecay * dt)

        let energyDrain = isMoving ? Balance.energyDrainWalking : Balance.energyDrainIdle
        state.guests[index].energy = SimMath.clamp(state.guests[index].energy - energyDrain * dt)

        // Unmet needs erode happiness; the further past the threshold, the worse.
        var happinessDelta = Balance.happinessDriftPerSecond * dt
        happinessDelta -= unmetNeedPenalty(state.guests[index]) * dt

        if case .queueing = state.guests[index].activity {
            happinessDelta -= Balance.happinessQueueBoredomPerSecond * dt
        }

        state.guests[index].adjustHappiness(happinessDelta)
    }

    private func unmetNeedPenalty(_ guest: Guest) -> Double {
        var penalty = 0.0
        if guest.bathroomNeed > Balance.bathroomUrgent {
            penalty += SimMath.normalise(guest.bathroomNeed, from: Balance.bathroomUrgent, to: 100)
                * Balance.happinessUnmetNeedPenalty * 2.2
        }
        if guest.hunger > Balance.hungerUrgent {
            penalty += SimMath.normalise(guest.hunger, from: Balance.hungerUrgent, to: 100)
                * Balance.happinessUnmetNeedPenalty
        }
        if guest.thirst > Balance.thirstUrgent {
            penalty += SimMath.normalise(guest.thirst, from: Balance.thirstUrgent, to: 100)
                * Balance.happinessUnmetNeedPenalty
        }
        if guest.energy < Balance.energyLow {
            penalty += SimMath.normalise(Balance.energyLow - guest.energy, from: 0, to: Balance.energyLow)
                * Balance.happinessUnmetNeedPenalty
        }
        if guest.nausea > 60 {
            penalty += SimMath.normalise(guest.nausea, from: 60, to: 100)
                * Balance.happinessUnmetNeedPenalty
        }
        return penalty
    }

    // MARK: - Thoughts

    private func updateThoughts(index: Int, state: GameState, now: Double) {
        let lastThought = state.guests[index].thoughts.last?.simTime ?? -1000
        guard now - lastThought > 22 else { return }
        let guest = state.guests[index]

        if let (text, mood) = ThoughtCatalog.need(hunger: guest.hunger,
                                                  thirst: guest.thirst,
                                                  bathroom: guest.bathroomNeed,
                                                  energy: guest.energy) {
            state.guests[index].think(text, mood: mood, at: now)
            return
        }
        let cleanliness = state.map.cleanlinessScore
        if cleanliness < 0.55, guest.personality.cleanlinessSensitivity > 45 {
            state.guests[index].think("There's rubbish everywhere.", mood: .negative, at: now)
            return
        }
        if cleanliness > 0.97, state.map.litteredTiles.isEmpty, guest.happiness > 60 {
            state.guests[index].think("This park is spotless.", mood: .positive, at: now)
            return
        }

        if let (text, mood) = ThoughtCatalog.enjoyment(happiness: guest.happiness) {
            state.guests[index].think(text, mood: mood, at: now)
        }
    }

    // MARK: - Queue patience

    private func updateQueuePatience(index: Int, state: GameState, now: Double) {
        guard case .queueing(let target) = state.guests[index].activity else { return }
        let guest = state.guests[index]
        let waited = now - guest.queueJoinedAt
        let tolerance = guest.queueWaitEstimate * Balance.queueAbandonGrace
            + 15 + guest.personality.patience * 0.5
        guard waited > tolerance else { return }

        let name = state.displayName(of: target)
        Self.removeFromQueue(guestID: guest.id, target: target, state: state)
        state.guests[index].activity = .exploring
        state.guests[index].nextDecisionAt = now
        state.guests[index].adjustHappiness(-Balance.happinessQueueAbandonPenalty)
        state.guests[index].think(ThoughtCatalog.abandonedQueue(name), mood: .negative, at: now)
    }

    /// Removes a guest from whichever queue it is standing in.
    static func removeFromQueue(guestID: UUID, target: ParkTarget, state: GameState) {
        switch target {
        case .attraction(let id):
            guard let attractionIndex = state.attractionIndex(id: id) else { return }
            state.attractions[attractionIndex].queue.removeAll { $0 == guestID }
        case .facility(let id):
            guard let facilityIndex = state.facilityIndex(id: id) else { return }
            state.facilities[facilityIndex].queue.removeAll { $0 == guestID }
        default:
            break
        }
    }

    // MARK: - Decisions

    private func shouldDecide(_ guest: Guest, now: Double) -> Bool {
        switch guest.activity {
        case .arriving, .exploring:
            return now >= guest.nextDecisionAt
        default:
            return false
        }
    }

    private struct Option {
        let target: ParkTarget
        let score: Double
        let departureReason: DepartureReason?
    }

    private func decide(index: Int, state: GameState, now: Double) {
        let guest = state.guests[index]
        let options = scoreOptions(for: guest, state: state)

        state.guests[index].nextDecisionAt = now + Balance.decisionInterval
            + Double.random(in: 0...Balance.decisionIntervalJitter, using: &state.rng)

        let weights = options.map(\.score)
        guard let chosenIndex = SimMath.weightedChoice(weights, using: &state.rng) else {
            state.guests[index].activity = .exploring
            return
        }

        commit(option: options[chosenIndex], guestIndex: index, state: state, now: now)
    }

    private func scoreOptions(for guest: Guest, state: GameState) -> [Option] {
        var options: [Option] = []
        let map = state.map

        // --- Shops, restrooms and benches --------------------------------
        for facility in state.facilities {
            guard facility.isOpen, !facility.isUnusable, let definition = facility.definition else { continue }
            let access = map.accessTiles(for: facility.rect)
            guard !access.isEmpty else { continue }
            guard let distance = pathfinder.distance(from: guest.tile, to: access, in: map) else { continue }

            let wait = facility.estimatedWait(definition: definition)
            let tolerance = tolerableWait(for: guest)
            guard wait < tolerance else { continue }
            let queueFactor = 1 - (wait / tolerance) * 0.6

            var score = 0.0
            switch definition.kind {
            case .bathroom:
                score = 430 * pow(guest.bathroomNeed / 100, 3.5)
                // A filthy restroom is a last resort rather than a destination.
                if facility.isDirty { score *= 0.45 }

            case .bin:
                guard guest.carryingTrash > 0 else { continue }
                // The longer they have been holding it, the more they want rid.
                let urgency = 0.4 + min(1, guest.trashCarriedFor / 40) * 0.6
                score = 150 * urgency

            case .food:
                guard guest.cash >= facility.price else { continue }
                score = 260 * pow(guest.hunger / 100, 2.2) * willingness(guest, facility, definition)

            case .drink:
                guard guest.cash >= facility.price else { continue }
                score = 250 * pow(guest.thirst / 100, 2.2) * willingness(guest, facility, definition)

            case .souvenir:
                guard guest.cash >= facility.price else { continue }
                score = 90 * (guest.happiness / 100) * willingness(guest, facility, definition)

            case .bench:
                let tiredness = SimMath.normalise(45 - guest.energy, from: 0, to: 45)
                score = 220 * pow(tiredness, 2) + guest.nausea * 0.9
            }

            score *= proximityFactor(distance) * queueFactor
            if score > 0.5 {
                options.append(Option(target: .facility(facility.id), score: score, departureReason: nil))
            }
        }

        // --- Rides --------------------------------------------------------
        // An urgent need suppresses the appetite for rides almost entirely.
        let needPressure = max(
            SimMath.normalise(guest.bathroomNeed, from: Balance.bathroomUrgent, to: 100),
            max(SimMath.normalise(guest.hunger, from: Balance.hungerUrgent + 10, to: 100),
                SimMath.normalise(guest.thirst, from: Balance.thirstUrgent + 10, to: 100)))
        let rideAppetite = 1 - needPressure

        if rideAppetite > 0.05 {
            for attraction in state.attractions {
                guard attraction.isOperational, let definition = attraction.definition else { continue }
                if guest.nausea > Balance.nauseaRefuseRide && definition.nausea > 20 { continue }

                let access = map.accessTiles(for: attraction.rect)
                guard !access.isEmpty else { continue }
                guard let distance = pathfinder.distance(from: guest.tile, to: access, in: map) else { continue }

                let wait = attraction.estimatedWait(definition: definition)
                let tolerance = tolerableWait(for: guest)
                guard wait < tolerance else { continue }

                let thrillMatch = 1 - abs(definition.excitement - guest.personality.thrillPreference) / 100
                guard thrillMatch > 0.2 else { continue }

                var score = 190 * pow(thrillMatch, 2) * rideAppetite
                score *= 1 - (wait / tolerance) * 0.7
                score *= proximityFactor(distance)
                score *= attraction.condition / 100
                if guest.recentAttractions.contains(attraction.id) {
                    score *= 0.15
                }

                if score > 0.5 {
                    options.append(Option(target: .attraction(attraction.id), score: score, departureReason: nil))
                }
            }
        }

        // --- Going home ----------------------------------------------------
        if let departure = departureUrge(guest: guest, state: state) {
            options.append(Option(target: .exit, score: departure.score, departureReason: departure.reason))
        }

        // --- Wandering ------------------------------------------------------
        if let spot = randomWanderSpot(near: guest.tile, state: state) {
            options.append(Option(target: .wanderSpot(spot), score: 22, departureReason: nil))
        }

        return options
    }

    private func willingness(_ guest: Guest,
                             _ facility: Facility,
                             _ definition: FacilityDefinition) -> Double {
        GuestEconomics.purchaseWillingness(price: facility.price,
                                           reference: definition.referencePrice,
                                           spending: guest.personality.spending)
    }

    private func departureUrge(guest: Guest, state: GameState) -> (score: Double, reason: DepartureReason)? {
        var score = 0.0
        var reason = DepartureReason.satisfied

        if guest.timeInPark > guest.plannedVisitLength {
            let overrun = (guest.timeInPark - guest.plannedVisitLength) / 120
            score = 120 + overrun * 220
            reason = .satisfied
        }

        if guest.happiness < Balance.unhappyLeaveThreshold {
            let severity = SimMath.normalise(Balance.unhappyLeaveThreshold - guest.happiness,
                                             from: 0, to: Balance.unhappyLeaveThreshold)
            let candidate = 200 + severity * 500
            if candidate > score {
                score = candidate
                reason = .unhappy
            }
        }

        if guest.energy < 10 && score < 260 {
            score = 260
            reason = .tired
        }

        if guest.bathroomNeed > 97 && score < 520 && !hasReachableBathroom(guest: guest, state: state) {
            score = 520
            reason = .noBathroom
        }

        // A filthy park drives the fussiest guests out first.
        let cleanliness = state.map.cleanlinessScore
        if cleanliness < 0.35 {
            let disgust = (0.35 - cleanliness) / 0.35 * (guest.personality.cleanlinessSensitivity / 100)
            let candidate = 120 + disgust * 480
            if candidate > score {
                score = candidate
                reason = .tooDirty
            }
        }

        let cheapestPurchase = state.facilities
            .filter { $0.definition?.kind.sellsGoods == true }
            .map(\.price)
            .min()
        if let cheapest = cheapestPurchase,
           guest.cash < cheapest,
           guest.timeInPark > 180,
           score < 150 {
            score = 150
            reason = .brokeAndBored
        }

        guard score > 0 else { return nil }
        return (score, reason)
    }

    private func hasReachableBathroom(guest: Guest, state: GameState) -> Bool {
        for facility in state.facilities where facility.definition?.kind == .bathroom && facility.isOpen {
            let access = state.map.accessTiles(for: facility.rect)
            if pathfinder.distance(from: guest.tile, to: access, in: state.map) != nil { return true }
        }
        return false
    }

    /// Distance falls off gently: somewhere twice as far is roughly half as
    /// appealing, but never completely ignored.
    private func proximityFactor(_ tileDistance: Int) -> Double {
        1.0 / (1.0 + Double(tileDistance) / 12.0)
    }

    private func tolerableWait(for guest: Guest) -> Double {
        Balance.baseTolerableWait + guest.personality.patience * Balance.patienceWaitScale
    }

    // MARK: - Committing to a target

    private func commit(option: Option, guestIndex: Int, state: GameState, now: Double) {
        let guest = state.guests[guestIndex]
        let access = state.accessTiles(for: option.target)

        guard !access.isEmpty else {
            state.guests[guestIndex].activity = .exploring
            return
        }

        state.guests[guestIndex].departureReason = option.departureReason?.rawValue

        // Already standing where it needs to be.
        if access.contains(guest.tile) {
            state.guests[guestIndex].route = []
            MovementSystem.beginActivity(at: option.target, guestIndex: guestIndex, state: state, now: now)
            return
        }

        let route = pathfinder.route(from: guest.tile, to: access, in: state.map)
        guard !route.isEmpty else {
            state.guests[guestIndex].activity = .exploring
            return
        }

        state.guests[guestIndex].route = route
        state.guests[guestIndex].activity = .walking(option.target)

        switch option.target {
        case .attraction(let id):
            if let attraction = state.attraction(id: id), let definition = attraction.definition {
                let (text, mood) = ThoughtCatalog.joinedQueue(attraction.name,
                                                             wait: attraction.estimatedWait(definition: definition))
                state.guests[guestIndex].think(text, mood: mood, at: now)
            }
        case .exit:
            if let reason = option.departureReason {
                let (text, mood) = ThoughtCatalog.leaving(reason: reason)
                state.guests[guestIndex].think(text, mood: mood, at: now)
            }
        default:
            break
        }
    }

    // MARK: - Wandering

    private func refreshWalkableCache(_ map: ParkMap) {
        guard map.generation != cachedGeneration else { return }
        cachedGeneration = map.generation
        cachedWalkableTiles = (0..<map.tileCount)
            .map { map.coord(atLinearIndex: $0) }
            .filter { map.isWalkable($0) }
    }

    private func randomWanderSpot(near tile: GridCoord, state: GameState) -> GridCoord? {
        guard !cachedWalkableTiles.isEmpty else { return nil }
        for _ in 0..<6 {
            guard let candidate = state.rng.pick(cachedWalkableTiles) else { return nil }
            if candidate == tile { continue }
            if candidate.manhattanDistance(to: tile) > 18 { continue }
            if pathfinder.distance(from: tile, to: [candidate], in: state.map) != nil {
                return candidate
            }
        }
        return nil
    }
}
