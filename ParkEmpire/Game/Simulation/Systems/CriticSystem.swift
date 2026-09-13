import Foundation

/// A review left by a visitor who never said who they were.
struct CriticReview: Codable, Identifiable, Equatable {
    var id = UUID()
    let criticName: String
    /// One to five.
    let stars: Int
    let headline: String
    /// Something they liked and something they did not, in their own words.
    /// Either can be empty when the visit gave them nothing to say.
    let praise: String
    let criticism: String
    /// Rating points the review moves the park by, positive or negative, and
    /// the park minutes it holds for. Both zero for a middling review.
    let ratingSwing: Double
    let minutes: Double

    var isGood: Bool { ratingSwing > 0 }
    var isBad: Bool { ratingSwing < 0 }

    /// Five characters, so the score reads at a glance.
    var starLine: String {
        String(repeating: "★", count: stars) + String(repeating: "☆", count: 5 - stars)
    }

    /// The line under the headline: whichever remark carries the verdict.
    var detail: String {
        if isBad, !criticism.isEmpty { return "\"\(criticism)\"" }
        if !praise.isEmpty { return "\"\(praise)\"" }
        if !criticism.isEmpty { return "\"\(criticism)\"" }
        return "They did not say much else."
    }

    var durationLabel: String {
        minutes >= 60 ? "\(Int(minutes / 60))h" : "\(Int(minutes)) min"
    }
}

extension CriticReview {
    /// Lenient decoding, like everything else that goes in a save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        criticName = container.value(.criticName, or: "A visitor")
        stars = container.value(.stars, or: 3)
        headline = container.value(.headline, or: "A day at the park")
        praise = container.value(.praise, or: "")
        criticism = container.value(.criticism, or: "")
        ratingSwing = container.value(.ratingSwing, or: 0)
        minutes = container.value(.minutes, or: 0)
    }
}

/// The park's anonymous reviewers.
///
/// A critic looks like everybody else, queues like everybody else and is
/// never pointed out, which is the entire idea: this is the one event the
/// player cannot prepare for, so the verdict lands on the park as it actually
/// was rather than the park as it was tidied up to be.
///
/// The review is worked out from what the guest already carries home with
/// them: how happy they ended up, whether they got on anything, whether they
/// bought anything, and why they left. Nothing is accumulated per guest, so
/// four hundred ordinary visitors pay nothing for this event existing.
enum CriticSystem {

    /// Whether now is a moment for one to walk in unannounced.
    static func shouldAdmit(state: GameState) -> Bool {
        guard state.attractions.count >= Balance.criticMinimumRides else { return false }
        guard state.clock.simTime >= state.nextCriticAt else { return false }
        return !state.guests.contains { $0.isActive && $0.isCritic }
    }

    /// Books the next one, some way off.
    static func scheduleNext(state: GameState) {
        let days = state.rng.double(Balance.criticGapDays)
        state.nextCriticAt = state.clock.simTime + days * Balance.dayLength
    }

    // MARK: - The verdict

    /// Called as a critic leaves the park, which is the only moment their
    /// opinion is complete.
    static func publish(guestIndex: Int, state: GameState) {
        let guest = state.guests[guestIndex]
        let now = state.clock.simTime
        state.guests[guestIndex].isCritic = false

        let stars = stars(for: guest)
        let swing = ratingSwing(stars: stars)

        if swing > 0 {
            state.reviewRating = .lasting(Balance.criticEffectMinutes, worth: swing, from: now)
            state.reviewArrivals = .lasting(Balance.criticEffectMinutes,
                                            worth: Balance.criticPraiseArrivals,
                                            from: now)
            state.statistics.goodReviewsTotal += 1
        } else if swing < 0 {
            state.reviewRating = .lasting(Balance.criticEffectMinutes, worth: swing, from: now)
            state.reviewArrivals = .inactive
            state.statistics.badReviewsTotal += 1
        }

        let review = CriticReview(criticName: guest.name,
                                  stars: stars,
                                  headline: headline(stars: stars),
                                  praise: remark(of: .positive, in: guest),
                                  criticism: remark(of: .negative, in: guest),
                                  ratingSwing: swing,
                                  minutes: swing == 0 ? 0 : Balance.criticEffectMinutes)
        state.pendingReviews.append(review)

        state.postAlert("\(guest.name) turned out to be a reviewer, and gave the park "
                        + "\(stars) out of 5.",
                        severity: swing < 0 ? .warning : .info,
                        key: "review",
                        cooldown: 60)
    }

    /// What the visit was worth, out of five.
    ///
    /// Happiness carries it, because happiness is already the sum of the
    /// queues, the litter, the prices and the rides. The adjustments on top
    /// are the things a reviewer would single out and a happiness number
    /// would not: never getting on anything, and storming off.
    private static func stars(for guest: Guest) -> Int {
        var score = guest.happiness
        if guest.ridesRidden == 0 { score -= 25 }
        if guest.purchases > 0 { score += 5 }
        if let reason = guest.departureReason, reason != DepartureReason.satisfied.rawValue {
            score -= 15
        }

        switch score {
        case 85...: return 5
        case Balance.criticPraiseHappiness...: return 4
        case 55...: return 3
        case Balance.criticComplaintHappiness...: return 2
        default: return 1
        }
    }

    private static func ratingSwing(stars: Int) -> Double {
        switch stars {
        case 5: return Balance.criticPraiseRating
        case 4: return Balance.criticPraiseRating * 0.6
        case 2: return -Balance.criticComplaintRating * 0.6
        case 1: return -Balance.criticComplaintRating
        // Three stars moves nothing, which is a real verdict and should read
        // as one rather than being rounded into a reward.
        default: return 0
        }
    }

    /// The most recent thing they thought in the given mood, quoted back.
    private static func remark(of mood: ThoughtMood, in guest: Guest) -> String {
        guest.thoughts.last(where: { $0.mood == mood })?.text ?? ""
    }

    private static func headline(stars: Int) -> String {
        switch stars {
        case 5: return "One of the best days out anywhere"
        case 4: return "Well worth the trip"
        case 3: return "A perfectly fine afternoon"
        case 2: return "Hard to recommend as it stands"
        default: return "I would not go back"
        }
    }
}
