import Foundation

/// Something that happened in the park without the player causing it.
///
/// Every rare event ends in one of these, and the interface shows one at a
/// time. Wrapping them in a single value rather than giving each event its own
/// published property is what stops two cards dimming the screen at once, and
/// means a new event costs one case rather than a new drain, a new dismisser
/// and another branch in the root view.
enum ParkEvent: Identifiable, Equatable {
    /// A visitor with an audience posted about the park.
    case promotion(PromotionPost)
    /// A coach pulled up at the gate and emptied.
    case coachParty(CoachPartyReport)
    /// A safety inspector gave their verdict on a ride.
    case inspection(InspectionReport)
    /// A visitor nobody knew was reviewing the park published their verdict.
    case review(CriticReview)

    var id: UUID {
        switch self {
        case .promotion(let post): return post.id
        case .coachParty(let report): return report.id
        case .inspection(let report): return report.id
        case .review(let review): return review.id
        }
    }
}
