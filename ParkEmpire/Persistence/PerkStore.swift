import Foundation

/// What the player has spent their trial points on.
///
/// Kept beside the trial medals rather than in a park's save, for the same
/// reason: the ladder and what it pays out belong to the player. Deleting a
/// park must not take a point back.
struct PerkStore {

    private let defaults: UserDefaults
    private static let key = "perks.ranks"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Perk id to how many points are in it.
    var ranks: [String: Int] {
        (defaults.dictionary(forKey: Self.key) as? [String: Int]) ?? [:]
    }

    func rank(_ perk: PerkDefinition) -> Int {
        min(perk.maxRank, ranks[perk.id] ?? 0)
    }

    /// Points spent in one branch, which is what gates the later perks in it.
    func spent(in branch: PerkBranch) -> Int {
        PerkContent.inBranch(branch).reduce(0) { $0 + rank($1) }
    }

    var spent: Int {
        PerkContent.all.reduce(0) { $0 + rank($1) }
    }

    /// One point per trial beaten.
    func earned(completedTrials: Int) -> Int { completedTrials }

    func available(completedTrials: Int) -> Int {
        max(0, earned(completedTrials: completedTrials) - spent)
    }

    /// Whether a perk is open to be bought into: enough points in hand, room
    /// left in it, and enough already spent in its branch.
    func canSpend(on perk: PerkDefinition, completedTrials: Int) -> Bool {
        guard available(completedTrials: completedTrials) > 0 else { return false }
        guard rank(perk) < perk.maxRank else { return false }
        return spent(in: perk.branch) >= perk.requires
    }

    @discardableResult
    func spend(on perk: PerkDefinition, completedTrials: Int) -> Bool {
        guard canSpend(on: perk, completedTrials: completedTrials) else { return false }
        var updated = ranks
        updated[perk.id] = rank(perk) + 1
        defaults.set(updated, forKey: Self.key)
        return true
    }

    /// Whether one point can be taken back out of a perk.
    ///
    /// Refused only when doing so would leave another perk in the branch
    /// standing on fewer points than it needs. Take those back first and the
    /// road unwinds the way it was built.
    func canRefund(_ perk: PerkDefinition) -> Bool {
        guard rank(perk) > 0 else { return false }
        let remaining = spent(in: perk.branch) - 1
        for other in PerkContent.inBranch(perk.branch) where rank(other) > 0 {
            let needs = other.id == perk.id && rank(other) == 1 ? 0 : other.requires
            if remaining < needs { return false }
        }
        return true
    }

    @discardableResult
    func refund(_ perk: PerkDefinition) -> Bool {
        guard canRefund(perk) else { return false }
        var updated = ranks
        let next = rank(perk) - 1
        if next == 0 {
            updated.removeValue(forKey: perk.id)
        } else {
            updated[perk.id] = next
        }
        defaults.set(updated, forKey: Self.key)
        return true
    }

    /// Hands every point back.
    ///
    /// Free and unlimited on purpose. These are permanent choices across
    /// every park, and a player who cannot try a different road without
    /// replaying the whole ladder will not try one at all.
    func reset() {
        defaults.removeObject(forKey: Self.key)
    }

    /// The bonuses the simulation actually reads.
    var bonuses: ParkPerks {
        func value(_ id: String) -> Double {
            guard let perk = PerkContent.definition(id: id) else { return 0 }
            return perk.perRank * Double(rank(perk))
        }
        return ParkPerks(extraArrivals: value("perk.arrivals"),
                         guestHappiness: value("perk.mood"),
                         guestSpending: value("perk.spending"),
                         buildDiscount: value("perk.building"),
                         wageDiscount: value("perk.wages"),
                         stockDiscount: value("perk.stock"),
                         wearReduction: value("perk.wear"),
                         breakdownReduction: value("perk.safety"),
                         ratingBonus: value("perk.reputation"))
    }
}
