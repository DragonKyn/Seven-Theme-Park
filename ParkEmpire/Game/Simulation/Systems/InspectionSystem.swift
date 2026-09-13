import Foundation

/// A regulator's verdict on one ride.
struct InspectionReport: Codable, Identifiable, Equatable {
    var id = UUID()
    let rideName: String
    /// The condition the ride was in when they looked at it.
    let condition: Double
    let passed: Bool
    /// Charged on a failure, zero on a pass.
    let fine: Double
    /// Rating points a pass is worth, and the park minutes they last.
    let bonus: Double
    let minutes: Double

    var headline: String { rideName }

    var detail: String {
        passed
            ? "passed its safety inspection"
            : "failed its safety inspection and has been shut"
    }

    /// The duration as a person would say it.
    var durationLabel: String {
        minutes >= 60 ? "\(Int(minutes / 60))h" : "\(Int(minutes)) min"
    }
}

extension InspectionReport {
    /// Lenient decoding, like everything else that goes in a save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        rideName = container.value(.rideName, or: "a ride")
        condition = container.value(.condition, or: 0)
        passed = container.value(.passed, or: false)
        fine = container.value(.fine, or: 0)
        bonus = container.value(.bonus, or: 0)
        minutes = container.value(.minutes, or: 0)
    }
}

/// The park's safety inspections.
///
/// Condition already decides how often a ride breaks down, but a breakdown
/// reads as bad luck. An inspection reads as a consequence: the regulator
/// announces themselves, names the ride they are looking at, and gives the
/// park an hour to get a mechanic to it before the verdict lands.
///
/// Deliberately nobody on screen. A walking inspector would need an entity, a
/// route, a sprite and artwork of their own, and the event reads perfectly
/// well through the alert that names the ride and the ride going dark when
/// they shut it.
enum InspectionSystem {

    static func update(state: GameState) {
        let now = state.clock.simTime

        // Somebody is already here: the only question is whether they have
        // seen enough yet.
        if let rideID = state.inspectingRideID {
            guard now >= state.inspectionVerdictAt else { return }
            deliverVerdict(rideID: rideID, state: state, now: now)
            return
        }

        guard state.attractions.count >= Balance.safetyInspectionMinimumRides,
              now >= state.nextSafetyInspectionAt else { return }
        arrive(state: state, now: now)
    }

    /// Books the next visit.
    static func scheduleNext(state: GameState) {
        let days = state.rng.double(Balance.safetyInspectionGapDays)
        state.nextSafetyInspectionAt = state.clock.simTime + days * Balance.dayLength
    }

    // MARK: - The visit

    private static func arrive(state: GameState, now: Double) {
        // The worst ride in the park. Worst by condition rather than by what a
        // mechanic would prioritise, because a mechanic's list is empty in a
        // well kept park and the regulator should always find something to
        // look at.
        guard let worst = state.attractions.min(by: { $0.condition < $1.condition }) else {
            scheduleNext(state: state)
            return
        }

        state.inspectingRideID = worst.id
        state.inspectionVerdictAt = now + Balance.safetyInspectionWarning
        state.postAlert("A safety inspector is looking over \(worst.name).",
                        severity: .warning,
                        key: "inspection",
                        target: .attraction(worst.id),
                        cooldown: 60)
    }

    private static func deliverVerdict(rideID: UUID, state: GameState, now: Double) {
        state.inspectingRideID = nil
        scheduleNext(state: state)

        // The ride was demolished while they were looking at it, which is one
        // way of passing an inspection.
        guard let index = state.attractionIndex(id: rideID) else { return }

        let ride = state.attractions[index]
        let passed = !ride.isBroken && ride.condition >= Balance.safetyInspectionPassCondition

        if passed {
            state.inspectionBonus = .lasting(Balance.safetyInspectionBonusMinutes,
                                             worth: Balance.safetyInspectionRatingBonus,
                                             from: now)
            state.attractions[index].timeSinceInspection = 0
            state.statistics.safetyInspectionsPassedTotal += 1
            state.postAlert("\(ride.name) passed its safety inspection.",
                            severity: .info,
                            key: "inspection.result",
                            target: .attraction(rideID),
                            cooldown: 60)
        } else {
            state.ledger.spend(Balance.safetyInspectionFine, on: .maintenance)
            state.attractions[index].isImpounded = true
            MaintenanceSystem.evacuate(
                attractionIndex: index,
                state: state,
                riderMessage: "They stopped \(ride.name) with me still on it.",
                queueMessage: "All that queuing and they shut \(ride.name) down.")
            state.statistics.safetyInspectionsFailedTotal += 1
            state.postAlert("\(ride.name) failed its safety inspection and has been shut. "
                            + "A mechanic will have to put it right.",
                            severity: .critical,
                            key: "inspection.result",
                            target: .attraction(rideID),
                            cooldown: 60)
        }

        state.pendingInspections.append(
            InspectionReport(rideName: ride.name,
                             condition: ride.condition,
                             passed: passed,
                             fine: passed ? 0 : Balance.safetyInspectionFine,
                             bonus: passed ? Balance.safetyInspectionRatingBonus : 0,
                             minutes: passed ? Balance.safetyInspectionBonusMinutes : 0))
    }
}
