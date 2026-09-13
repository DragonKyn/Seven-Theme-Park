import CoreGraphics
import Foundation

/// What one disruptive visitor did, and how their visit ended.
struct EjectionReport: Codable, Identifiable, Equatable {
    var id = UUID()
    let guestName: String
    /// Nil when nobody removed them and they left in their own time.
    let guardName: String?
    /// Pieces of rubbish they left behind.
    let litterDropped: Int
    /// Park minutes they were in the park.
    let minutes: Double

    var wasEscorted: Bool { guardName != nil }

    var detail: String {
        if let guardName {
            return "was walked out by \(guardName)"
        }
        return "made a nuisance of themselves all afternoon, unchallenged"
    }

    var durationLabel: String {
        minutes >= 60 ? "\(Int(minutes / 60))h" : "\(Int(minutes)) min"
    }
}

extension EjectionReport {
    /// Lenient decoding, like everything else that goes in a save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        guestName = container.value(.guestName, or: "A visitor")
        guardName = container.optionalValue(.guardName)
        litterDropped = container.value(.litterDropped, or: 0)
        minutes = container.value(.minutes, or: 0)
    }
}

/// The park's occasional nuisance.
///
/// One turns up every few days, drops rubbish faster than a janitor can sweep
/// it, sours the mood of everybody near them, and shoves people out of queues.
/// A park with a security guard has them walked out. A park without one
/// watches them do it for four hours and then leave, which is the lesson.
enum TroublemakerSystem {

    /// Whether now is a moment for one to walk in.
    static func shouldAdmit(state: GameState) -> Bool {
        guard state.guestCount >= Balance.troublemakerMinimumGuests else { return false }
        guard state.clock.simTime >= state.nextTroublemakerAt else { return false }
        return state.troublemakerIndex == nil
    }

    /// Books the next one, some way off.
    static func scheduleNext(state: GameState) {
        let days = state.rng.double(Balance.troublemakerGapDays)
        state.nextTroublemakerAt = state.clock.simTime + days * Balance.dayLength
    }

    /// Turns a freshly admitted guest into the nuisance.
    ///
    /// The look is made entirely of appearance values that already exist,
    /// which matters more than it sounds: guest textures are cached against
    /// those values, so a look driven by a flag the renderer reads instead
    /// would quietly collide in the cache and draw them as anybody else.
    static func mark(_ guest: inout Guest, state: GameState, now: Double) {
        guest.isTroublemaker = true
        guest.troublemakerUntil = now + Balance.troublemakerStayLength
        guest.appearance = GuestAppearance(shirt: .charcoal,
                                           hair: guest.appearance.hair,
                                           skin: guest.appearance.skin,
                                           hat: .hood,
                                           bottoms: .charcoal,
                                           pattern: .vest,
                                           accessory: .sunglasses)

        if state.staffCount(role: .security) == 0 {
            state.postAlert("Somebody is causing trouble and you have no security.",
                            severity: .warning,
                            key: "staff.security.missing",
                            cooldown: 300)
        }
    }

    // MARK: - Per tick

    static func update(state: GameState, dt: Double) {
        guard let index = state.troublemakerIndex else { return }
        let now = state.clock.simTime
        let centre = state.guests[index].position

        // Everybody nearby has a worse time of it.
        let drain = Balance.troublemakerHappinessPerSecond * dt
        for other in state.guests.indices
        where other != index && state.guests[other].isActive {
            guard SimMath.distance(state.guests[other].position, centre)
                    <= Balance.troublemakerRadius else { continue }
            state.guests[other].adjustHappiness(-drain)
        }

        if state.rng.chance(Balance.troublemakerLitterChancePerSecond * dt) {
            state.map.addLitter(Balance.litterPerPiece, at: state.guests[index].tile)
            state.guests[index].troublemakerLitter += 1
        }

        if state.rng.chance(Balance.troublemakerQueueChancePerSecond * dt) {
            barge(near: centre, state: state, now: now)
        }

        if now >= state.guests[index].troublemakerUntil {
            remove(guestIndex: index, state: state, guardName: nil)
        }
    }

    /// Pushes somebody out of a queue they had been waiting in.
    private static func barge(near centre: CGPoint, state: GameState, now: Double) {
        for attraction in state.attractions where !attraction.queue.isEmpty {
            guard SimMath.distance(attraction.origin.centre, centre)
                    <= Balance.troublemakerQueueRadius else { continue }
            guard let victimID = attraction.queue.first,
                  let victim = state.guestIndex(id: victimID) else { continue }

            GuestAISystem.removeFromQueue(guestID: victimID,
                                          target: .attraction(attraction.id),
                                          state: state)
            state.guests[victim].activity = .exploring
            state.guests[victim].route = []
            state.guests[victim].nextDecisionAt = now
            state.guests[victim].adjustHappiness(-Balance.troublemakerQueuePenalty)
            state.guests[victim].think("Someone shoved in and pushed me out of the queue.",
                                       mood: .negative, at: now, icon: .queue)
            return
        }
    }

    // MARK: - Removal

    /// Ends the visit, either because a guard caught up with them or because
    /// they had their afternoon and left.
    ///
    /// Deliberately not routed through the ordinary departure, which files a
    /// reason against the park's complaints. Being thrown out is not a
    /// complaint, and counting it as one would poison the figure the
    /// dashboard shows as what guests are unhappy about.
    static func remove(guestIndex: Int, state: GameState, guardName: String?) {
        let guest = state.guests[guestIndex]
        state.guests[guestIndex].isTroublemaker = false
        state.guests[guestIndex].activity = .departed
        state.guests[guestIndex].route = []

        state.pendingEjections.append(
            EjectionReport(guestName: guest.name,
                           guardName: guardName,
                           litterDropped: guest.troublemakerLitter,
                           minutes: guest.timeInPark))

        if let guardName {
            state.statistics.troublemakersEjectedTotal += 1
            // Relief for everybody who watched it happen.
            for index in state.guests.indices where state.guests[index].isActive {
                guard SimMath.distance(state.guests[index].position, guest.position)
                        <= Balance.escortReliefRadius else { continue }
                state.guests[index].adjustHappiness(Balance.escortHappinessRelief)
            }
            state.postAlert("\(guardName) escorted \(guest.name) out of the park.",
                            severity: .info,
                            key: "escort",
                            cooldown: 30)
        } else {
            state.statistics.troublemakersEscapedTotal += 1
            state.postAlert("\(guest.name) caused trouble all afternoon and walked out "
                            + "unchallenged.",
                            severity: .warning,
                            key: "escort.missed",
                            cooldown: 120)
        }
    }
}
