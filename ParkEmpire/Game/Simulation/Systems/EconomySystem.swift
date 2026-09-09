import Foundation

/// Recurring costs, the daily accounting rollover, and money-related alerts.
final class EconomySystem {

    func update(state: GameState, dt: Double) {
        chargeUtilities(state: state, dt: dt)
        checkDayRollover(state: state)
        checkWarnings(state: state)
    }

    /// Running the park costs money whether or not anyone visits.
    private func chargeUtilities(state: GameState, dt: Double) {
        let buildingCount = Double(state.attractions.count + state.facilities.count)
        let perSecond = Balance.utilitiesPerSecond + buildingCount * 0.02
        state.ledger.spend(perSecond * dt, on: .utilities)
    }

    private func checkDayRollover(state: GameState) {
        let currentDay = state.clock.elapsedDayNumber
        guard currentDay != state.clock.day else { return }

        let closingProfit = state.ledger.today.profit
        state.ledger.rollOverDay()
        state.statistics.rollOverDay()
        state.clock.day = currentDay

        for index in state.attractions.indices {
            state.attractions[index].guestsToday = 0
        }
        for index in state.facilities.indices {
            state.facilities[index].customersToday = 0
            state.facilities[index].revenueToday = 0
        }

        let verb = closingProfit >= 0 ? "profit" : "loss"
        state.postAlert("Day \(currentDay - 1) closed with a \(CurrencyFormatter.short(abs(closingProfit))) \(verb).",
                        severity: closingProfit >= 0 ? .info : .warning,
                        key: "day.summary",
                        cooldown: 30)
    }

    private func checkWarnings(state: GameState) {
        if state.ledger.cash < 1_000 {
            state.postAlert("Your park is running low on cash.",
                            severity: .critical,
                            key: "cash.low",
                            cooldown: 240)
        }

        // Long queues are worth surfacing; they are the most common reason a
        // park with good rides still has unhappy guests.
        for attraction in state.attractions {
            guard let definition = attraction.definition else { continue }
            if attraction.estimatedWait(definition: definition) > Balance.baseTolerableWait * 2 {
                state.postAlert("\(attraction.name) has an extremely long queue.",
                                severity: .warning,
                                key: "queue.\(attraction.id.uuidString)",
                                target: .attraction(attraction.id),
                                cooldown: 300)
            }
        }

        // Missing basics.
        if state.guestCount > 12 && !state.facilities.contains(where: { $0.definition?.kind == .bathroom }) {
            state.postAlert("Guests are complaining about restroom availability.",
                            severity: .warning,
                            key: "facility.bathroom.missing",
                            cooldown: 300)
        }

        // Cleanliness is the slow-motion failure that catches players out, so
        // it gets its own escalating warnings.
        let cleanliness = state.map.cleanlinessScore
        if cleanliness < 0.5 {
            if state.staffCount(role: .janitor) == 0 {
                state.postAlert("Litter is piling up and you have no janitors.",
                                severity: .critical,
                                key: "staff.janitor.missing",
                                cooldown: 240)
            } else {
                state.postAlert("Guests are complaining about litter in the park.",
                                severity: .warning,
                                key: "cleanliness.low",
                                cooldown: 240)
            }
        }

        if state.facilities.contains(where: { $0.isFull }) {
            state.postAlert("Some bins are overflowing.",
                            severity: .warning,
                            key: "bins.full",
                            cooldown: 240)
        }

        if state.attractions.contains(where: { $0.isBroken }) && state.staffCount(role: .mechanic) == 0 {
            state.postAlert("A ride is broken and there is no mechanic to fix it.",
                            severity: .critical,
                            key: "staff.mechanic.needed",
                            cooldown: 180)
        }
    }
}
