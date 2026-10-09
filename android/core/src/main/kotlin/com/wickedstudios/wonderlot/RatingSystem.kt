package com.wickedstudios.wonderlot

import kotlin.math.abs

/** Scores the park 0-100 from eight weighted components. */
class RatingSystem {

    class Component(val name: String, val weight: Double, val value: Double)

    fun update(state: GameState) {
        if (state.clock.simTime < state.nextRatingUpdate) return
        state.nextRatingUpdate = state.clock.simTime + Balance.ratingInterval

        val components = evaluate(state)
        val totalWeight = components.sumOf { it.weight }
        if (totalWeight <= 0) return

        // A clean bill of health, or a review, is a swing on top of what the park earned.
        val earned = components.sumOf { it.weight * it.value } / totalWeight * 100
        val target = SimMath.clamp(earned + state.activeRatingModifier + state.perks.ratingBonus)

        val previousStars = state.starRating
        state.parkRating += (target - state.parkRating) * Balance.ratingSmoothing
        state.parkRating = SimMath.clamp(state.parkRating)

        state.ratingComponents = components.associate { it.name to it.value }.toMutableMap()

        if (state.starRating > previousStars) {
            state.postAlert("Park rating increased to ${state.starRating} stars.", AlertSeverity.info,
                "rating.up.${state.starRating}", cooldown = 300.0)
        }
    }

    /** Exposed so the management dashboard can show the same breakdown. */
    fun evaluate(state: GameState): List<Component> {
        val components = ArrayList<Component>()

        // An empty park is treated as neutral rather than zero.
        val guestCount = state.guestCount
        val happiness = if (guestCount > 0) state.averageHappiness / 100 else 0.5
        components.add(Component("Guest happiness", 0.22, happiness))

        val distinctTypes = state.attractions.map { it.definitionID }.toSet().size
        val varietyScore = minOf(1.0, distinctTypes / 4.0) * 0.7 + minOf(1.0, state.attractions.size / 6.0) * 0.3
        components.add(Component("Attraction variety", 0.13, varietyScore))

        components.add(Component("Facility availability", 0.10, facilityScore(state, guestCount)))

        val acceptable = GuestEconomics.acceptableAdmission(state.attractions.size, state.parkRating)
        val value = GuestEconomics.admissionWillingness(state.admissionPrice, acceptable)
        components.add(Component("Value for money", 0.10, value))

        components.add(Component("Queue satisfaction", 0.10, queueScore(state)))
        components.add(Component("Cleanliness", 0.13, cleanlinessScore(state)))
        components.add(Component("Ride reliability", 0.10, reliabilityScore(state)))
        components.add(Component("Park appearance", 0.12, appearanceScore(state)))

        return components
    }

    /** Ground litter dominates, but neglected bins and restrooms count too. */
    private fun cleanlinessScore(state: GameState): Double {
        val ground = state.map.cleanlinessScore

        val serviced = state.facilities.filter { it.definition?.kind?.needsServicing == true }
        // No bins or restrooms at all: judged on the ground alone, and penalised.
        if (serviced.isEmpty()) return ground * 0.8

        val averageSoiling = serviced.sumOf { it.soiling } / serviced.size
        val facilityScore = SimMath.clamp(1 - averageSoiling / 100, 0.0, 1.0)
        return ground * 0.7 + facilityScore * 0.3
    }

    private fun reliabilityScore(state: GameState): Double {
        if (state.attractions.isEmpty()) return 0.5

        val averageCondition = state.attractions.sumOf { it.condition } / state.attractions.size
        val brokenCount = state.attractions.count { it.isBroken }
        val brokenPenalty = brokenCount.toDouble() / state.attractions.size

        return SimMath.clamp(averageCondition / 100 - brokenPenalty * 0.8, 0.0, 1.0)
    }

    /** A park looks good when it is clean, decorated, and has not been paved end to end. */
    private fun appearanceScore(state: GameState): Double {
        val clean = state.map.cleanlinessScore
        val decorated = state.map.beautyScore

        val grass = state.map.tiles.count { it.terrain == TerrainType.grass }
        val grassRatio = grass.toDouble() / maxOf(1, state.map.tileCount)
        // Best around 70% open ground: neither a car park nor an empty field.
        val balance = SimMath.clamp(1 - abs(grassRatio - 0.7) / 0.7, 0.0, 1.0)

        return clean * 0.4 + decorated * 0.45 + balance * 0.15
    }

    private fun facilityScore(state: GameState, guestCount: Int): Double {
        var bathrooms = 0.0
        for (facility in state.facilities) {
            val definition = facility.definition ?: continue
            if (definition.kind == FacilityKind.bathroom) bathrooms += definition.ratingWeight
        }
        val foodAndDrink = state.facilities.count {
            val kind = it.definition?.kind
            kind == FacilityKind.food || kind == FacilityKind.drink
        }
        val benches = state.facilities.count { it.definition?.kind == FacilityKind.bench }

        // One of each per twenty guests is considered adequate.
        val expected = maxOf(1.0, guestCount / 20.0 * Balance.facilitiesPerTwentyGuests)
        val bathroomScore = minOf(1.0, bathrooms / expected)
        val shopScore = minOf(1.0, foodAndDrink / expected)
        val benchScore = minOf(1.0, benches / maxOf(1.0, expected * 1.5))

        return bathroomScore * 0.5 + shopScore * 0.35 + benchScore * 0.15
    }

    private fun queueScore(state: GameState): Double {
        var total = 0.0
        var count = 0

        for (attraction in state.attractions) {
            val definition = attraction.definition ?: continue
            val wait = attraction.estimatedWait(definition)
            total += 1 - SimMath.normalise(wait, 0.0, Balance.baseTolerableWait * 2)
            count += 1
        }
        for (facility in state.facilities) {
            val definition = facility.definition ?: continue
            if (definition.kind == FacilityKind.bench) continue
            val wait = facility.estimatedWait(definition)
            total += 1 - SimMath.normalise(wait, 0.0, Balance.baseTolerableWait)
            count += 1
        }

        if (count <= 0) return 0.5
        return total / count
    }
}
