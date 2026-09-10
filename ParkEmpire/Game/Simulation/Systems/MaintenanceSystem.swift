import Foundation

/// Wear, inspections and breakdowns.
///
/// Condition falls only while a ride is actually running, and the breakdown
/// hazard is scaled so that a ride kept near 100% effectively never fails while
/// a neglected one fails often. Overdue inspections double the hazard, which is
/// what makes hiring a mechanic worthwhile before anything has broken.
final class MaintenanceSystem {

    func update(state: GameState, dt: Double) {
        for index in state.attractions.indices {
            state.attractions[index].timeSinceInspection += dt

            guard let definition = state.attractions[index].definition,
                  state.attractions[index].isOperational,
                  state.attractions[index].phase == .running else { continue }

            state.attractions[index].condition = SimMath.clamp(
                state.attractions[index].condition - definition.maintenanceRate * dt)

            rollForBreakdown(index: index, definition: definition, state: state, dt: dt)
        }
    }

    private func rollForBreakdown(index: Int,
                                  definition: AttractionDefinition,
                                  state: GameState,
                                  dt: Double) {
        let attraction = state.attractions[index]
        let missingCondition = 1 - attraction.condition / 100
        guard missingCondition > 0.02 else { return }

        let cycleLength = max(1, definition.loadDuration + definition.rideDuration)
        let overdue = attraction.isInspectionOverdue ? Balance.overdueInspectionPenalty : 1.0
        // Expressed as a per-second hazard so the result is independent of tick
        // rate: over one full cycle it works out to roughly the configured
        // per-cycle chance.
        let hazardPerSecond = Balance.breakdownChanceAtZeroCondition
            * missingCondition * missingCondition * overdue / cycleLength

        guard state.rng.chance(hazardPerSecond * dt) else { return }
        breakDown(index: index, state: state)
    }

    /// Closes the ride, empties it, and disappoints everyone involved.
    private func breakDown(index: Int, state: GameState) {
        let now = state.clock.simTime
        let name = state.attractions[index].name
        let attractionID = state.attractions[index].id

        state.attractions[index].isBroken = true
        state.attractions[index].totalBreakdowns += 1
        state.attractions[index].phase = .loading
        state.attractions[index].phaseTimer = 0

        // Riders are let off mid-experience, which they take badly.
        let riders = state.attractions[index].riders
        state.attractions[index].riders = []
        for guestID in riders {
            guard let guestIndex = state.guestIndex(id: guestID) else { continue }
            state.guests[guestIndex].adjustHappiness(-Balance.happinessRideBrokeDown)
            state.guests[guestIndex].activity = .exploring
            state.guests[guestIndex].nextDecisionAt = now
            state.guests[guestIndex].think("\(name) broke down while I was on it!",
                                           mood: .negative, at: now)
        }

        // The queue is cleared, as promised on the tin.
        let queued = state.attractions[index].queue
        state.attractions[index].queue = []
        for guestID in queued {
            guard let guestIndex = state.guestIndex(id: guestID) else { continue }
            state.guests[guestIndex].adjustHappiness(-Balance.happinessQueueAbandonPenalty)
            state.guests[guestIndex].activity = .exploring
            state.guests[guestIndex].nextDecisionAt = now
            state.guests[guestIndex].think("All that queuing and \(name) broke down.",
                                           mood: .negative, at: now)
        }

        state.statistics.breakdownsTotal += 1
        state.postAlert("\(name) has broken down.",
                        severity: .critical,
                        key: "breakdown.\(attractionID.uuidString)",
                        target: .attraction(attractionID),
                        cooldown: 60)

        if state.staffCount(role: .mechanic) == 0 {
            state.postAlert("You have no mechanics. Broken rides will stay closed.",
                            severity: .critical,
                            key: "staff.mechanic.missing",
                            cooldown: 300)
        }
    }

    // MARK: - Mechanic outcomes

    static func completeRepair(attractionIndex: Int, state: GameState) {
        state.statistics.repairsCompletedTotal += 1
        state.attractions[attractionIndex].isBroken = false
        state.attractions[attractionIndex].condition = max(
            state.attractions[attractionIndex].condition, Balance.repairedCondition)
        state.attractions[attractionIndex].timeSinceInspection = 0
        state.attractions[attractionIndex].phase = .loading
        state.attractions[attractionIndex].phaseTimer = 0

        state.postAlert("\(state.attractions[attractionIndex].name) is running again.",
                        severity: .info,
                        key: "repaired.\(state.attractions[attractionIndex].id.uuidString)",
                        target: .attraction(state.attractions[attractionIndex].id),
                        cooldown: 60)
    }

    static func completeInspection(attractionIndex: Int, state: GameState) {
        state.attractions[attractionIndex].timeSinceInspection = 0
        state.attractions[attractionIndex].condition = SimMath.clamp(
            state.attractions[attractionIndex].condition + Balance.inspectionConditionBonus)
    }
}
