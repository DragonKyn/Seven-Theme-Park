import Foundation

/// Runs ride cycles: boarding from the queue, running, then unloading and
/// applying the experience to each rider.
final class AttractionSystem {

    func update(state: GameState, dt: Double) {
        let now = state.clock.simTime

        for index in state.attractions.indices {
            guard let definition = state.attractions[index].definition else { continue }

            switch state.attractions[index].phase {
            case .loading:
                // A broken ride keeps its phase but takes nobody aboard.
                board(attractionIndex: index, definition: definition, state: state)

                guard !state.attractions[index].riders.isEmpty else {
                    state.attractions[index].phaseTimer = 0
                    continue
                }

                state.attractions[index].phaseTimer += dt
                let full = state.attractions[index].riders.count >= definition.capacity
                if full || state.attractions[index].phaseTimer >= definition.loadDuration {
                    state.attractions[index].phase = .running
                    state.attractions[index].phaseTimer = 0
                }

            case .running:
                state.attractions[index].phaseTimer += dt
                if state.attractions[index].phaseTimer >= definition.rideDuration {
                    unload(attractionIndex: index, definition: definition, state: state, now: now)
                }
            }
        }
    }

    // MARK: - Boarding

    private func board(attractionIndex: Int, definition: AttractionDefinition, state: GameState) {
        guard state.attractions[attractionIndex].isOperational else { return }
        let attractionID = state.attractions[attractionIndex].id

        while state.attractions[attractionIndex].riders.count < definition.capacity,
              !state.attractions[attractionIndex].queue.isEmpty {

            let guestID = state.attractions[attractionIndex].queue.removeFirst()
            guard let guestIndex = state.guestIndex(id: guestID),
                  state.guests[guestIndex].isActive,
                  case .queueing(.attraction(let queuedFor)) = state.guests[guestIndex].activity,
                  queuedFor == attractionID else {
                continue
            }

            state.attractions[attractionIndex].riders.append(guestID)
            state.guests[guestIndex].activity = .engaged(.attraction(attractionID))
        }

        // Keep queue slot indices tidy so the renderer can line guests up.
        for (slot, guestID) in state.attractions[attractionIndex].queue.enumerated() {
            if let guestIndex = state.guestIndex(id: guestID) {
                state.guests[guestIndex].queueSlot = slot
            }
        }
    }

    // MARK: - Unloading

    private func unload(attractionIndex: Int, definition: AttractionDefinition, state: GameState, now: Double) {
        let riders = state.attractions[attractionIndex].riders
        let attractionID = state.attractions[attractionIndex].id
        let attractionName = state.attractions[attractionIndex].name

        for guestID in riders {
            guard let guestIndex = state.guestIndex(id: guestID) else { continue }
            let satisfaction = applyRideExperience(guestIndex: guestIndex,
                                                   definition: definition,
                                                   attractionID: attractionID,
                                                   attractionName: attractionName,
                                                   state: state,
                                                   now: now)
            state.attractions[attractionIndex].satisfactionSum += satisfaction
            state.attractions[attractionIndex].satisfactionCount += 1
        }

        state.attractions[attractionIndex].guestsToday += riders.count
        state.attractions[attractionIndex].totalGuests += riders.count
        state.statistics.ridesGivenTotal += riders.count
        state.attractions[attractionIndex].riders = []
        state.attractions[attractionIndex].phase = .loading
        state.attractions[attractionIndex].phaseTimer = 0

        state.ledger.spend(definition.operatingCostPerCycle, on: .maintenance)
        // Wear and breakdown risk are `MaintenanceSystem`'s business; it works
        // from the ride's phase so it does not need telling about cycles.
    }

    /// Returns the happiness delta the ride produced, which doubles as the
    /// attraction's satisfaction score.
    private func applyRideExperience(guestIndex: Int,
                                     definition: AttractionDefinition,
                                     attractionID: UUID,
                                     attractionName: String,
                                     state: GameState,
                                     now: Double) -> Double {
        let guest = state.guests[guestIndex]
        let thrillMatch = 1 - abs(definition.excitement - guest.personality.thrillPreference) / 100
        let conditionFactor = 0.7 + 0.3 * (state.attraction(id: attractionID)?.condition ?? 100) / 100

        var satisfaction = Balance.happinessRideBase * (0.35 + thrillMatch) * conditionFactor
        if thrillMatch > 0.85 {
            satisfaction += Balance.happinessThrillMatchBonus
        }

        state.guests[guestIndex].adjustHappiness(satisfaction)
        state.guests[guestIndex].nausea = SimMath.clamp(guest.nausea + definition.nausea * 0.45)
        state.guests[guestIndex].energy = SimMath.clamp(guest.energy - 3)
        state.guests[guestIndex].ridesRidden += 1
        state.guests[guestIndex].activity = .exploring
        state.guests[guestIndex].nextDecisionAt = now
        state.guests[guestIndex].queueWaitEstimate = 0

        var recent = guest.recentAttractions
        recent.append(attractionID)
        if recent.count > 3 { recent.removeFirst(recent.count - 3) }
        state.guests[guestIndex].recentAttractions = recent

        let (text, mood) = ThoughtCatalog.afterRide(attractionName, satisfaction: satisfaction)
        state.guests[guestIndex].think(text, mood: mood, at: now)

        return satisfaction
    }
}
