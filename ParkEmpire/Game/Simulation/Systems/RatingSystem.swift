import Foundation

/// Scores the park 0-100.
///
/// Eight weighted components, all of which now have real data behind them.
/// Weights are still renormalised over whatever `evaluate` returns, so a future
/// component can be added or held back without the score changing scale.
final class RatingSystem {

    struct Component {
        let name: String
        let weight: Double
        let value: Double
    }

    func update(state: GameState) {
        guard state.clock.simTime >= state.nextRatingUpdate else { return }
        state.nextRatingUpdate = state.clock.simTime + Balance.ratingInterval

        let components = evaluate(state: state)
        let totalWeight = components.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return }

        // A clean bill of health is a bonus on top of what the park earned,
        // not a ninth thing the park is judged on. Added after the weights are
        // normalised, so the breakdown the dashboard shows stays honest.
        let earned = components.reduce(0.0) { $0 + $1.weight * $1.value } / totalWeight * 100
        let target = SimMath.clamp(earned + state.activeInspectionBonus)

        let previousStars = state.starRating
        state.parkRating += (target - state.parkRating) * Balance.ratingSmoothing
        state.parkRating = SimMath.clamp(state.parkRating)

        state.ratingComponents = Dictionary(uniqueKeysWithValues: components.map { ($0.name, $0.value) })

        if state.starRating > previousStars {
            state.postAlert("Park rating increased to \(state.starRating) stars.",
                            severity: .info,
                            key: "rating.up.\(state.starRating)",
                            cooldown: 300)
        }
    }

    /// Exposed so the management dashboard can show the same breakdown.
    func evaluate(state: GameState) -> [Component] {
        var components: [Component] = []

        // Guest happiness. An empty park is treated as neutral rather than zero.
        let guestCount = state.guestCount
        let happiness = guestCount > 0 ? state.averageHappiness / 100 : 0.5
        components.append(Component(name: "Guest happiness", weight: 0.22, value: happiness))

        // Attraction variety: distinct ride types, plus a nudge for quantity.
        let distinctTypes = Set(state.attractions.map(\.definitionID)).count
        let varietyScore = min(1.0, Double(distinctTypes) / 4.0) * 0.7
            + min(1.0, Double(state.attractions.count) / 6.0) * 0.3
        components.append(Component(name: "Attraction variety", weight: 0.13, value: varietyScore))

        // Facility availability, measured against the crowd it has to serve.
        components.append(Component(name: "Facility availability",
                                    weight: 0.10,
                                    value: facilityScore(state: state, guestCount: guestCount)))

        // Value for money at the gate.
        let acceptable = GuestEconomics.acceptableAdmission(attractionCount: state.attractions.count,
                                                            parkRating: state.parkRating)
        let value = GuestEconomics.admissionWillingness(price: state.admissionPrice, acceptable: acceptable)
        components.append(Component(name: "Value for money", weight: 0.10, value: value))

        // Queue satisfaction across every ride and shop.
        components.append(Component(name: "Queue satisfaction", weight: 0.10, value: queueScore(state: state)))

        // Litter on the paths plus the state of the bins and restrooms.
        components.append(Component(name: "Cleanliness", weight: 0.13, value: cleanlinessScore(state: state)))

        // Whether the rides actually run when guests turn up.
        components.append(Component(name: "Ride reliability", weight: 0.10, value: reliabilityScore(state: state)))

        components.append(Component(name: "Park appearance", weight: 0.12, value: appearanceScore(state: state)))

        return components
    }

    /// Ground litter dominates, but neglected bins and restrooms count too.
    private func cleanlinessScore(state: GameState) -> Double {
        let ground = state.map.cleanlinessScore

        let serviced = state.facilities.filter { $0.definition?.kind.needsServicing == true }
        guard !serviced.isEmpty else {
            // No bins or restrooms at all: judged on the ground alone, and
            // penalised because rubbish has nowhere to go.
            return ground * 0.8
        }

        let averageSoiling = serviced.reduce(0.0) { $0 + $1.soiling } / Double(serviced.count)
        let facilityScore = SimMath.clamp(1 - averageSoiling / 100, 0, 1)
        return ground * 0.7 + facilityScore * 0.3
    }

    private func reliabilityScore(state: GameState) -> Double {
        guard !state.attractions.isEmpty else { return 0.5 }

        let averageCondition = state.attractions.reduce(0.0) { $0 + $1.condition }
            / Double(state.attractions.count)
        let brokenCount = state.attractions.reduce(0) { $0 + ($1.isBroken ? 1 : 0) }
        let brokenPenalty = Double(brokenCount) / Double(state.attractions.count)

        return SimMath.clamp(averageCondition / 100 - brokenPenalty * 0.8, 0, 1)
    }

    /// A park looks good when it is clean, decorated, and has not been paved
    /// end to end. Decoration carries the most weight of the three because it
    /// is the only one of them the player builds on purpose.
    private func appearanceScore(state: GameState) -> Double {
        let clean = state.map.cleanlinessScore
        let decorated = state.map.beautyScore

        var grass = 0
        for index in 0..<state.map.tileCount {
            let coord = state.map.coord(atLinearIndex: index)
            if state.map.tile(at: coord)?.terrain == .grass { grass += 1 }
        }
        let grassRatio = Double(grass) / Double(max(1, state.map.tileCount))
        // Best around 70% open ground: neither a car park nor an empty field.
        let balance = SimMath.clamp(1 - abs(grassRatio - 0.7) / 0.7, 0, 1)

        return clean * 0.4 + decorated * 0.45 + balance * 0.15
    }

    private func facilityScore(state: GameState, guestCount: Int) -> Double {
        let bathrooms = state.facilities.filter { $0.definition?.kind == .bathroom }.count
        let foodAndDrink = state.facilities.filter {
            guard let kind = $0.definition?.kind else { return false }
            return kind == .food || kind == .drink
        }.count
        let benches = state.facilities.filter { $0.definition?.kind == .bench }.count

        // One of each per twenty guests is considered adequate; a park with no
        // guests yet is judged on simply having the basics.
        let expected = max(1.0, Double(guestCount) / 20.0 * Balance.facilitiesPerTwentyGuests)
        let bathroomScore = min(1.0, Double(bathrooms) / expected)
        let shopScore = min(1.0, Double(foodAndDrink) / expected)
        let benchScore = min(1.0, Double(benches) / max(1.0, expected * 1.5))

        return bathroomScore * 0.5 + shopScore * 0.35 + benchScore * 0.15
    }

    private func queueScore(state: GameState) -> Double {
        var total = 0.0
        var count = 0

        for attraction in state.attractions {
            guard let definition = attraction.definition else { continue }
            let wait = attraction.estimatedWait(definition: definition)
            total += 1 - SimMath.normalise(wait, from: 0, to: Balance.baseTolerableWait * 2)
            count += 1
        }
        for facility in state.facilities {
            guard let definition = facility.definition, definition.kind != .bench else { continue }
            let wait = facility.estimatedWait(definition: definition)
            total += 1 - SimMath.normalise(wait, from: 0, to: Balance.baseTolerableWait)
            count += 1
        }

        guard count > 0 else { return 0.5 }
        return total / Double(count)
    }
}
