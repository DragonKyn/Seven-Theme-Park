import CoreGraphics
import Foundation

/// Decides how many people want to visit, and admits them.
///
/// Demand is deliberately bounded by park quality: a park with one gentle ride
/// charging a premium gate price gets a trickle, and the same park at a fair
/// price gets a queue. Nothing here spawns guests unconditionally.
final class DemandSystem {

    func update(state: GameState, dt: Double) {
        // Coaches arrive on their own schedule, not out of the trickle.
        if CoachPartySystem.shouldArrive(state: state) {
            admitCoachParty(state: state)
        }

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

        // Parking is a small, steady multiplier rather than another source of
        // appeal: it decides how many of the people who already want to come
        // can actually get here.
        let parking = CarParkContent.demandMultiplier(level: state.carParkLevel)

        // A post about the park is a short, sharp rush on top of whatever
        // the park had already earned.
        let promotion = 1 + state.activePromotionBoost

        return SimMath.clamp(appeal * ratingFactor * priceFactor * parking * promotion,
                             0,
                             Balance.maxArrivalsPerMinute)
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

    /// A coach pulls up and empties.
    ///
    /// Child heavy and light in the pocket, and all of them through the gate
    /// in one go, which is the whole point of the event.
    func admitCoachParty(state: GameState) {
        // Booked first, so every way out of this method still re-books.
        CoachPartySystem.scheduleNext(state: state)

        let wanted = state.rng.int(Balance.coachPartySize)
        let room = Balance.maxGuests - state.guestCount
        let count = min(wanted, room)
        // A park with no room left turns the coach round at the gate rather
        // than squeezing a handful of them in and calling it an event.
        guard count >= Balance.coachPartyMinimumSize else { return }

        let groupID = UUID()
        var childCount = 0
        for _ in 0..<count {
            let isChild = state.rng.chance(Balance.coachPartyChildShare)
            if isChild { childCount += 1 }
            admitGuest(state: state,
                       ageOverride: isChild ? .child : .adult,
                       cashScale: Balance.coachPartySpendScale,
                       groupID: groupID)
        }

        let name = GuestNames.coachGroup(using: &state.rng)
        state.pendingCoachParties.append(
            CoachPartyReport(groupName: name, count: count, childCount: childCount))
        state.statistics.coachPartiesTotal += 1
        state.postAlert("\(name) has arrived, \(count) of them at once.",
                        severity: .info,
                        key: "coachParty",
                        cooldown: 60)
    }

    // MARK: - Admission

    private func admitGuest(state: GameState,
                            ageOverride: AgeCategory? = nil,
                            cashScale: Double = 1,
                            groupID: UUID? = nil) {
        let entrance = state.map.entranceCoord
        let now = state.clock.simTime

        let age = ageOverride ?? randomAge(&state.rng)
        let personality = GuestPersonality.random(for: age, using: &state.rng)

        let cashRange: ClosedRange<Double>
        switch age {
        case .child: cashRange = 30...80
        case .adult: cashRange = 65...170
        case .senior: cashRange = 50...140
        }
        let spendingScale = 0.7 + personality.spending / 100 * 0.6
        // Spending money, plus the price of the ticket on top.
        //
        // Somebody who has decided the gate is worth it brings the gate money
        // with them; they do not pay for it out of their lunch. Taking
        // admission out of a guest's pocket money meant a park charging near
        // the cap admitted a crowd with nothing left to spend, and every shop
        // and booth in it stood empty. Demand is still what an expensive park
        // pays for, through `admissionWillingness` below.
        let spendingMoney = state.rng.double(cashRange) * spendingScale * cashScale
        let startingCash = spendingMoney + state.admissionPrice

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
        guest.appearance = GuestAppearance.random(for: age, using: &state.rng)
        guest.groupID = groupID

        // Every so often, somebody with an audience. Never somebody who came
        // on a coach: a batch of twenty would otherwise swallow the schedule
        // the famous visitor is spaced out by.
        if groupID == nil, PromotionSystem.shouldAdmitInfluencer(state: state) {
            guest.isInfluencer = true
            // Dressed to be found in a crowd, and filming.
            guest.appearance = GuestAppearance(shirt: .pink,
                                               hair: guest.appearance.hair,
                                               skin: guest.appearance.skin,
                                               hat: .none,
                                               bottoms: .charcoal,
                                               pattern: .plain,
                                               accessory: .phone)
            guest.cash += 120
            PromotionSystem.scheduleNext(state: state)
        }

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
        guest.think(text, mood: mood, at: now, icon: .money)

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
