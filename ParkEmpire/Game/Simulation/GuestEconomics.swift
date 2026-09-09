import Foundation

/// How guests judge prices. Kept separate so the same curve drives shop
/// purchases, admission demand and the "price sentiment" readout.
enum GuestEconomics {

    /// 0-1 willingness to pay `price` for something guests consider worth
    /// `reference`. Free at half the fair price, refused at 1.5x it, shifted
    /// by how freely the guest spends.
    static func purchaseWillingness(price: Double, reference: Double, spending: Double) -> Double {
        guard reference > 0 else { return 1 }
        guard price > 0 else { return 1 }
        let ratio = price / reference
        let base = 1.5 - ratio
        let personalityShift = (spending - 50) / 250
        return SimMath.clamp(base + personalityShift, 0, 1)
    }

    /// The admission price a park of this quality can get away with.
    static func acceptableAdmission(attractionCount: Int, parkRating: Double) -> Double {
        Balance.acceptablePriceFloor
            + Double(attractionCount) * Balance.acceptablePricePerAttraction
            + parkRating * 0.15
    }

    /// 0-1 chance a potential visitor accepts the gate price.
    static func admissionWillingness(price: Double, acceptable: Double) -> Double {
        guard acceptable > 0 else { return 0 }
        if price <= 0 { return 1 }
        let ratio = price / acceptable
        return SimMath.clamp(1.25 - 0.75 * ratio, 0, 1)
    }

    /// Wording for a shop's price sentiment readout.
    static func sentimentLabel(_ value: Double) -> String {
        switch value {
        case ..<0.2: return "Outrageous"
        case ..<0.4: return "Expensive"
        case ..<0.65: return "Fair"
        case ..<0.85: return "Good value"
        default: return "A bargain"
        }
    }
}
