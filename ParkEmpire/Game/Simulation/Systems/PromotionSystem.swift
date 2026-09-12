import Foundation

/// One post about the park, and what it did for the gate.
struct PromotionPost: Codable, Identifiable, Equatable {
    var id = UUID()
    let guestName: String
    let rideName: String
    /// Extra arrivals as a share: 0.3 is thirty per cent more people.
    let boost: Double
    /// How long it runs, in park minutes.
    let minutes: Double
}

extension PromotionPost {
    /// Lenient decoding, like everything else that goes in a save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        guestName = container.value(.guestName, or: "A visitor")
        rideName = container.value(.rideName, or: "a ride")
        boost = container.value(.boost, or: 0)
        minutes = container.value(.minutes, or: 0)
    }
}

/// The park's occasional famous visitor.
///
/// One turns up every couple of days at most, rides something, and posts
/// about it. What the park gets is a burst of arrivals, which is worth more
/// the better the ride they happened to pick.
enum PromotionSystem {

    /// Whether now is a moment for one to walk in.
    ///
    /// Three gates: not too soon after the last, not while one is already
    /// here, and not before the park has anything worth filming.
    static func shouldAdmitInfluencer(state: GameState) -> Bool {
        guard state.attractions.count >= Balance.influencerMinimumRides else { return false }
        guard state.clock.simTime >= state.nextInfluencerAt else { return false }
        return !state.guests.contains { $0.isActive && $0.isInfluencer }
    }

    /// Books the next one, some way off.
    static func scheduleNext(state: GameState) {
        let days = state.rng.double(Balance.influencerGapDays)
        state.nextInfluencerAt = state.clock.simTime + days * Balance.dayLength
    }

    /// Called when a famous visitor gets off a ride.
    ///
    /// The boost scales with how exciting the ride was, so a post about the
    /// coaster the park was built around is worth more than one about the
    /// teacups.
    static func post(guestIndex: Int,
                     attraction: Attraction,
                     state: GameState,
                     now: Double) {
        let excitement = attraction.definition?.excitement ?? 40
        let boost = Balance.promotionBoostFloor
            + (excitement / 100) * Balance.promotionBoostRange
        let minutes = Balance.promotionMinutes

        state.promotionBoost = boost
        state.promotionEndsAt = now + minutes * 60

        let post = PromotionPost(guestName: state.guests[guestIndex].name,
                                 rideName: attraction.name,
                                 boost: boost,
                                 minutes: minutes)
        state.pendingPromotions.append(post)
        state.statistics.promotionsTotal += 1

        state.guests[guestIndex].think("Posting this. My followers are going to love \(attraction.name).",
                                       mood: .positive,
                                       at: now,
                                       icon: .ride)

        state.postAlert("\(post.guestName) posted about \(attraction.name). Expect a rush at the gate.",
                        severity: .info,
                        key: "promotion",
                        target: .attraction(attraction.id),
                        cooldown: 60)
    }
}
