import Foundation

/// Rubbish: who is carrying it, where it ends up, and how much guests mind.
///
/// The cause-and-effect chain this creates is deliberate — no bins means guests
/// drop rubbish on the paths, litter makes guests unhappy and drags the park
/// rating down, and only a janitor can reverse it.
final class CleanlinessSystem {

    func update(state: GameState, dt: Double) {
        let now = state.clock.simTime

        // One check for the whole park rather than one per guest.
        let hasUsableBin = state.facilities.contains {
            $0.definition?.kind == .bin && $0.isOpen && !$0.isFull
        }

        // Where the guards are standing. Gathered once rather than per guest,
        // and usually empty.
        let guards = state.staff.filter { $0.role == .security }.map(\.position)

        for index in state.guests.indices {
            guard state.guests[index].isActive else { continue }
            applyLitterDisgust(index: index, state: state, dt: dt)
            eatPopcorn(index: index, state: state, dt: dt, now: now)
            guard state.guests[index].carryingTrash > 0 else { continue }
            state.guests[index].trashCarriedFor += dt
            let watched = guards.contains {
                SimMath.distance($0, state.guests[index].position) <= Balance.securityRadius
            }
            maybeDropLitter(index: index,
                            state: state,
                            dt: dt,
                            hasUsableBin: hasUsableBin,
                            watched: watched,
                            now: now)
        }
    }

    /// Working through a bag of popcorn, and what to do with the empty bag.
    ///
    /// Somewhere to put it nearby and the guest carries it there like any
    /// other rubbish. Nowhere near, and it goes on the ground where they are
    /// standing: that is the whole reason to keep a bin by the cart, and the
    /// reason a park that sells popcorn needs more janitors.
    private func eatPopcorn(index: Int, state: GameState, dt: Double, now: Double) {
        guard state.guests[index].popcornRemaining > 0 else { return }
        state.guests[index].popcornRemaining -= dt
        guard state.guests[index].popcornRemaining <= 0 else { return }
        state.guests[index].popcornRemaining = 0

        let tile = state.guests[index].tile
        let binNearby = state.facilities.contains { facility -> Bool in
            guard facility.definition?.kind == .bin, facility.isOpen, !facility.isFull else {
                return false
            }
            let distance = abs(facility.origin.x - tile.x) + abs(facility.origin.y - tile.y)
            return distance <= Balance.popcornBinRadius
        }

        if binNearby {
            state.guests[index].carryingTrash = min(3, state.guests[index].carryingTrash + 1)
            state.guests[index].trashCarriedFor = 0
        } else {
            state.map.addLitter(Balance.popcornLitter, at: tile)
            state.guests[index].think("No bin near, so the empty bag goes on the ground.",
                                      mood: .negative, at: now, icon: .dirty)
        }
    }

    /// Standing in rubbish is unpleasant, and some guests mind far more.
    private func applyLitterDisgust(index: Int, state: GameState, dt: Double) {
        let litter = state.map.litter(at: state.guests[index].tile)
        guard litter > 5 else { return }
        let sensitivity = state.guests[index].personality.cleanlinessSensitivity / 100
        let penalty = (litter / 100) * sensitivity * Balance.happinessLitterPenalty * dt
        state.guests[index].adjustHappiness(-penalty)
    }

    /// A guest holding rubbish gets steadily more willing to just drop it. Tidy
    /// guests hold on far longer, and everyone gives up sooner when the park
    /// has no bin to aim for.
    private func maybeDropLitter(index: Int,
                                 state: GameState,
                                 dt: Double,
                                 hasUsableBin: Bool,
                                 watched: Bool,
                                 now: Double) {
        let guest = state.guests[index]
        let impatience = min(1, guest.trashCarriedFor / Balance.trashPatience)
        let tidiness = guest.personality.cleanlinessSensitivity / 100
        var chance = Balance.litterDropChancePerSecond * impatience * (1.6 - tidiness) * dt
        if !hasUsableBin { chance *= 2.5 }
        // Nobody drops a wrapper in front of a guard.
        if watched { chance *= (1 - Balance.securityLitterDeterrence) }
        chance *= state.adBoosts.litterFactor

        guard state.rng.chance(chance) else { return }

        state.map.addLitter(Balance.litterPerPiece, at: guest.tile)
        state.guests[index].carryingTrash -= 1
        state.guests[index].trashCarriedFor = 0

        if !hasUsableBin {
            state.guests[index].think("There's nowhere to put my rubbish.", mood: .negative, at: now, icon: .dirty)
        }
    }

    /// Called when a guest finishes at a bin.
    static func disposeOfTrash(guestIndex: Int, facilityIndex: Int, state: GameState) {
        let carried = state.guests[guestIndex].carryingTrash
        guard carried > 0 else { return }
        state.guests[guestIndex].carryingTrash = 0
        state.guests[guestIndex].trashCarriedFor = 0
        state.facilities[facilityIndex].soiling = SimMath.clamp(
            state.facilities[facilityIndex].soiling + Balance.binFillPerItem * Double(carried))
    }
}
