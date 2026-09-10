import Foundation

/// Awards achievement tiers and pays out for them.
///
/// Checked on a slow timer rather than every tick: every metric is a running
/// total or a value read straight off the park, so nothing is missed by
/// looking a few seconds later, and a park with three hundred guests in it
/// should not be evaluating seventeen ladders forty times a second.
final class AchievementSystem {

    func update(state: GameState) {
        // A park built for nothing has not achieved anything, so free build
        // earns none of these.
        guard state.mode.earnsAchievements else { return }
        guard state.clock.simTime >= state.nextAchievementCheck else { return }
        state.nextAchievementCheck = state.clock.simTime + Balance.achievementCheckInterval

        for definition in AchievementContent.all {
            award(definition, state: state)
        }
    }

    /// Awards one tier at most per check, so a park that jumps several tiers
    /// at once celebrates them one after another rather than all at once.
    private func award(_ definition: AchievementDefinition, state: GameState) {
        let earned = state.achievements[definition.id] ?? 0
        guard earned < definition.tierCount else { return }

        let next = earned + 1
        guard let threshold = definition.threshold(forTier: next),
              value(of: definition.metric, in: state) >= threshold else { return }

        state.achievements[definition.id] = next

        let reward = definition.reward(forTier: next)
        state.ledger.receive(reward, as: .other)
        state.pendingAwards.append(AchievementAward(definitionID: definition.id,
                                                    tier: next,
                                                    reward: reward))

        state.postAlert("\(definition.name) \(AchievementDefinition.tierName(next)) earned. "
                        + "\(CurrencyFormatter.short(reward)) awarded.",
                        severity: .info,
                        key: "achievement.\(definition.id).\(next)",
                        cooldown: 0)
    }

    /// Current value of a metric. Counters come from the statistics block;
    /// everything else is read off the park as it stands, which is why a
    /// crowd that peaks and disperses still counts.
    private func value(of metric: AchievementMetric, in state: GameState) -> Double {
        switch metric {
        case .guestsAdmitted: return Double(state.statistics.guestsAdmittedTotal)
        case .ridesGiven: return Double(state.statistics.ridesGivenTotal)
        case .foodSold: return Double(state.statistics.foodSoldTotal)
        case .drinksSold: return Double(state.statistics.drinksSoldTotal)
        case .souvenirsSold: return Double(state.statistics.souvenirsSoldTotal)
        case .litterCleaned: return Double(state.statistics.litterCleanedTotal)
        case .repairsCompleted: return Double(state.statistics.repairsCompletedTotal)
        case .upgradesBought: return Double(state.statistics.upgradesBoughtTotal)
        case .transportTrips: return Double(state.statistics.transportTripsTotal)
        case .attractionCount: return Double(state.attractions.count)
        case .sceneryCount: return Double(state.scenery.count)
        case .staffCount: return Double(state.staff.count)
        case .guestsInPark: return Double(state.guestCount)
        case .parkRating: return state.parkRating
        case .lifetimeProfit: return state.ledger.lifetime.profit
        case .cashOnHand: return state.ledger.cash
        case .daysOperated: return Double(state.clock.day)
        }
    }

    /// Progress towards every achievement, for the list screen.
    static func progress(state: GameState) -> [AchievementProgress] {
        let system = AchievementSystem()
        return AchievementContent.all.map { definition in
            let earned = state.achievements[definition.id] ?? 0
            let current = system.value(of: definition.metric, in: state)
            return AchievementProgress(definition: definition,
                                       earnedTier: earned,
                                       current: current)
        }
    }
}

/// One achievement's standing, for the list screen.
struct AchievementProgress: Identifiable {
    let definition: AchievementDefinition
    let earnedTier: Int
    let current: Double

    var id: String { definition.id }
    var isComplete: Bool { earnedTier >= definition.tierCount }

    /// The threshold being worked towards, or nil when every tier is done.
    var nextThreshold: Double? {
        definition.threshold(forTier: earnedTier + 1)
    }

    /// 0-1 towards the next tier, measured from the previous one so the bar
    /// restarts at each rung rather than creeping across the whole ladder.
    var fraction: Double {
        guard let next = nextThreshold else { return 1 }
        let floorValue = definition.threshold(forTier: earnedTier) ?? 0
        guard next > floorValue else { return 1 }
        return SimMath.clamp((current - floorValue) / (next - floorValue), 0, 1)
    }

    func format(_ value: Double) -> String {
        definition.formatted(value)
    }
}
