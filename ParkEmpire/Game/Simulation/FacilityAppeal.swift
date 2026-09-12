import Foundation

/// Why a guest would, or would not, walk to a shop, a restroom or a booth.
///
/// This is the single place that decides how much a guest wants a facility.
/// The guest AI reads it to pick where to go, and the inspector reads it to
/// explain why nobody is coming. Two copies of this rule would eventually
/// disagree, and the one the player is shown would be the wrong one.
enum FacilityAppeal {

    enum Verdict {
        case notOpen
        case unusable
        case noWalkway
        case unreachable
        case queueTooLong
        case cannotAfford
        /// Working, reachable, and of no interest to this guest right now.
        case notWanted
        /// How strongly this guest wants it, on the same scale rides use.
        case wants(Double)

        var summary: String {
            switch self {
            case .notOpen: return "Closed, so nobody is coming in"
            case .unusable: return "In no state for guests to use"
            case .noWalkway: return "No walkway touches it"
            case .unreachable: return "Guests cannot walk to it"
            case .queueTooLong: return "The queue is longer than guests will wait"
            case .cannotAfford: return "Guests nearby cannot afford it"
            case .notWanted: return "Nobody nearby wants it right now"
            // No number here on purpose. The appeal score is a knob inside the
            // simulation, and printing it invites tuning a park against a
            // figure that means nothing outside this file.
            case .wants: return "Guests want this"
            }
        }
    }

    /// `distance` is the walking distance in tiles to the nearest tile a guest
    /// can stand on to use it, or nil when there is no route.
    static func evaluate(facility: Facility,
                         definition: FacilityDefinition,
                         guest: Guest,
                         hasAccess: Bool,
                         distance: Int?) -> Verdict {
        guard facility.isOpen else { return .notOpen }
        guard !facility.isUnusable else { return .unusable }
        guard hasAccess else { return .noWalkway }
        guard let distance else { return .unreachable }

        let wait = facility.estimatedWait(definition: definition)
        let tolerance = tolerableWait(for: guest)
        guard wait < tolerance else { return .queueTooLong }
        let queueFactor = 1 - (wait / tolerance) * 0.6

        if definition.kind.sellsGoods && guest.cash < facility.price {
            return .cannotAfford
        }

        let appeal = desire(for: guest, facility: facility, definition: definition)
        let score = appeal * proximityFactor(distance) * queueFactor
        return score > 0.5 ? .wants(score) : .notWanted
    }

    /// How much this guest wants what the facility offers, before distance and
    /// queue are taken into account.
    private static func desire(for guest: Guest,
                               facility: Facility,
                               definition: FacilityDefinition) -> Double {
        switch definition.kind {
        case .bathroom:
            var score = 430 * pow(guest.bathroomNeed / 100, 3.5)
            // A filthy restroom is a last resort rather than a destination.
            if facility.isDirty { score *= 0.45 }
            return score

        case .bin:
            guard guest.carryingTrash > 0 else { return 0 }
            // The longer they have been holding it, the more they want rid.
            let urgency = 0.4 + min(1, guest.trashCarriedFor / 40) * 0.6
            return 150 * urgency

        case .food:
            return 260 * pow(guest.hunger / 100, 2.2) * willingness(guest, facility, definition)

        case .drink:
            return 250 * pow(guest.thirst / 100, 2.2) * willingness(guest, facility, definition)

        case .souvenir:
            return 90 * (guest.happiness / 100) * willingness(guest, facility, definition)

        case .game:
            // A booth competes with the rides for the same idle guest, so it
            // is scored like one rather than like a shop. Scored off need, the
            // way food is, it could never win: nobody needs to knock a
            // coconut off a post.
            var appetite = 0.6 + guest.personality.spending / 150
            switch guest.ageCategory {
            case .child: appetite *= 1.9
            case .adult: appetite *= 1.0
            case .senior: appetite *= 0.7
            }
            // Somebody already carrying a bear is playing for the fun of it
            // rather than for the prize.
            if guest.prize != nil { appetite *= 0.45 }
            return 240 * appetite * willingness(guest, facility, definition)

        case .bench:
            let tiredness = SimMath.normalise(45 - guest.energy, from: 0, to: 45)
            return 220 * pow(tiredness, 2) + guest.nausea * 0.9
        }
    }

    static func willingness(_ guest: Guest,
                            _ facility: Facility,
                            _ definition: FacilityDefinition) -> Double {
        GuestEconomics.purchaseWillingness(price: facility.price,
                                           reference: definition.referencePrice,
                                           spending: guest.personality.spending)
    }

    static func proximityFactor(_ tileDistance: Int) -> Double {
        1.0 / (1.0 + Double(tileDistance) / 12.0)
    }

    static func tolerableWait(for guest: Guest) -> Double {
        Balance.baseTolerableWait + guest.personality.patience * Balance.patienceWaitScale
    }
}
