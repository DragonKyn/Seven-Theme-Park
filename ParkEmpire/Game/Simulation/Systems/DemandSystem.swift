import CoreGraphics
import Foundation

/// Decides how many people want to visit, and admits them.
///
/// Demand is deliberately bounded by park quality: a park with one gentle ride
/// charging a premium gate price gets a trickle, and the same park at a fair
/// price gets a queue. Nothing here spawns guests unconditionally.
final class DemandSystem {

    func update(state: GameState, dt: Double) {
        let arrivals = arrivalsPerMinute(state: state)
        state.currentArrivalsPerMinute = arrivals

        guard arrivals > 0 else { return }
        state.spawnAccumulator += arrivals / 60.0 * dt

        while state.spawnAccumulator >= 1 {
            state.spawnAccumulator -= 1
            guard state.guestCount < Balance.maxGuests else {
                state.spawnAccumulator = 0
                break
            }
            admitGuest(state: state)
        }
    }

    // MARK: - Demand model

    func arrivalsPerMinute(state: GameState) -> Double {
        let openAttractions = state.attractions.filter { $0.isOpen && $0.definition != nil }

        // Rides are the reason to visit; variety and thrill both matter.
        var attractionScore = 0.0
        for attraction in openAttractions {
            guard let definition = attraction.definition else { continue }
            attractionScore += 0.35 + definition.excitement / 100
        }
        attractionScore = min(attractionScore, 6)

        let facilityBonus = min(1.0, Double(state.facilities.count) * 0.12)
        let appeal = Balance.baseArrivalsPerMinute + attractionScore * 1.6 + facilityBonus

        let ratingFactor = 0.55 + 1.0 * (state.parkRating / 100)

        let acceptable = GuestEconomics.acceptableAdmission(attractionCount: openAttractions.count,
                                                            parkRating: state.parkRating)
        let priceFactor = GuestEconomics.admissionWillingness(price: state.admissionPrice,
                                                              acceptable: acceptable)

        // Nobody comes to a park they cannot walk into.
        guard state.map.isWalkable(state.map.entranceCoord) else { return 0 }

        return SimMath.clamp(appeal * ratingFactor * priceFactor, 0, Balance.maxArrivalsPerMinute)
    }

    /// Admits guests immediately, bypassing the demand model.
    ///
    /// Only used to populate the demo park behind the main menu: waiting for
    /// arrivals would take ten simulated minutes to draw a crowd, which is far
    /// too much work to do while the menu is opening.
    func seed(count: Int, state: GameState) {
        for _ in 0..<count where state.guestCount < Balance.maxGuests {
            admitGuest(state: state)
        }
    }

    // MARK: - Admission

    private func admitGuest(state: GameState) {
        let entrance = state.map.entranceCoord
        let now = state.clock.simTime

        let age = randomAge(&state.rng)
        let personality = GuestPersonality.random(for: age, using: &state.rng)

        let cashRange: ClosedRange<Double>
        switch age {
        case .child: cashRange = 30...80
        case .adult: cashRange = 65...170
        case .senior: cashRange = 50...140
        }
        let spendingScale = 0.7 + personality.spending / 100 * 0.6
        let startingCash = state.rng.double(cashRange) * spendingScale

        let speedScale: Double
        switch age {
        case .child: speedScale = 0.9
        case .adult: speedScale = 1.0
        case .senior: speedScale = 0.82
        }

        let name = GuestNames.random(using: &state.rng)
        let happiness = state.rng.double(62...86)
        let hunger = state.rng.double(5...35)
        let thirst = state.rng.double(10...40)
        let energy = state.rng.double(72...100)
        let bathroomNeed = state.rng.double(0...25)
        let speedJitter = state.rng.double(-Balance.guestWalkSpeedVariance...Balance.guestWalkSpeedVariance)
        let visitJitter = state.rng.double(-Balance.visitLengthVariance...Balance.visitLengthVariance)

        var guest = Guest(
            id: UUID(),
            name: name,
            ageCategory: age,
            personality: personality,
            cash: startingCash,
            happiness: happiness,
            hunger: hunger,
            thirst: thirst,
            energy: energy,
            bathroomNeed: bathroomNeed,
            position: entrance.centre,
            tile: entrance,
            walkSpeed: (Balance.guestWalkSpeed + speedJitter) * speedScale,
            plannedVisitLength: Balance.visitLengthBase + visitJitter
        )

        guest.nextDecisionAt = now + 1

        // Pay at the gate.
        let price = state.admissionPrice
        if price > 0 {
            guest.cash = max(0, guest.cash - price)
            guest.moneySpent += price
            state.ledger.receive(price, as: .admission)
        }

        let acceptable = GuestEconomics.acceptableAdmission(
            attractionCount: state.attractions.count,
            parkRating: state.parkRating)
        let willingness = GuestEconomics.admissionWillingness(price: price, acceptable: acceptable)
        let (text, mood) = ThoughtCatalog.admission(price: price, willingness: willingness)
        guest.think(text, mood: mood, at: now)

        state.guests.append(guest)
        state.statistics.guestsAdmittedToday += 1
        state.statistics.guestsAdmittedTotal += 1
    }

    private func randomAge(_ generator: inout SeededGenerator) -> AgeCategory {
        let roll = generator.double(0...1)
        if roll < 0.25 { return .child }
        if roll < 0.87 { return .adult }
        return .senior
    }
}
