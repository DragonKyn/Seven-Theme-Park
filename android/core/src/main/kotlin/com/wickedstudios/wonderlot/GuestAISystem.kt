package com.wickedstudios.wonderlot

import java.util.UUID
import kotlin.math.abs
import kotlin.math.pow

/**
 * Needs, thoughts and decision making. Guests do not re-plan every tick: needs
 * decay continuously, but a guest only picks a new goal every
 * [Balance.decisionInterval] sim-seconds (jittered per guest).
 */
class GuestAISystem(private val pathfinder: PathfindingSystem) {

    private var cachedWalkableTiles: List<GridCoord> = emptyList()
    private var cachedGeneration = -1

    fun update(state: GameState, dt: Double) {
        refreshWalkableCache(state.map)
        val now = state.clock.simTime

        for (guest in state.guests) {
            if (!guest.isActive) continue
            updateNeeds(guest, state, dt)
            updateThoughts(guest, state, now)
            updateQueuePatience(guest, state, now)

            if (!shouldDecide(guest, now)) continue
            decide(guest, state, now)
        }
    }

    // region Needs

    private fun updateNeeds(guest: Guest, state: GameState, dt: Double) {
        val isMoving = when (guest.activity) {
            is GuestActivity.Walking, is GuestActivity.Arriving, is GuestActivity.Exploring -> true
            else -> false
        }

        guest.timeInPark += dt
        guest.hunger = SimMath.clamp(guest.hunger + Balance.hungerRate * dt)
        guest.thirst = SimMath.clamp(guest.thirst + Balance.thirstRate * dt)
        guest.bathroomNeed = SimMath.clamp(guest.bathroomNeed + Balance.bathroomRate * dt)
        guest.nausea = SimMath.clamp(guest.nausea - Balance.nauseaDecay * dt)

        val energyDrain = if (isMoving) Balance.energyDrainWalking else Balance.energyDrainIdle
        guest.energy = SimMath.clamp(guest.energy - energyDrain * dt)

        // Unmet needs erode happiness; the further past the threshold, the worse.
        var happinessDelta = Balance.happinessDriftPerSecond * dt
        happinessDelta -= unmetNeedPenalty(guest) * dt

        if (guest.activity is GuestActivity.Queueing) {
            happinessDelta -= Balance.happinessQueueBoredomPerSecond * dt
        }

        // Somewhere pleasant to stand lifts the mood a little every second.
        val beauty = state.map.beauty(guest.tile)
        if (beauty > 0) happinessDelta += beauty / 100 * Balance.happinessBeautyPerSecond * dt

        guest.adjustHappiness(happinessDelta)
    }

    private fun unmetNeedPenalty(guest: Guest): Double {
        var penalty = 0.0
        if (guest.bathroomNeed > Balance.bathroomUrgent) {
            penalty += SimMath.normalise(guest.bathroomNeed, Balance.bathroomUrgent, 100.0) *
                Balance.happinessUnmetNeedPenalty * 2.2
        }
        if (guest.hunger > Balance.hungerUrgent) {
            penalty += SimMath.normalise(guest.hunger, Balance.hungerUrgent, 100.0) * Balance.happinessUnmetNeedPenalty
        }
        if (guest.thirst > Balance.thirstUrgent) {
            penalty += SimMath.normalise(guest.thirst, Balance.thirstUrgent, 100.0) * Balance.happinessUnmetNeedPenalty
        }
        if (guest.energy < Balance.energyLow) {
            penalty += SimMath.normalise(Balance.energyLow - guest.energy, 0.0, Balance.energyLow) *
                Balance.happinessUnmetNeedPenalty
        }
        if (guest.nausea > 60) {
            penalty += SimMath.normalise(guest.nausea, 60.0, 100.0) * Balance.happinessUnmetNeedPenalty
        }
        return penalty
    }

    // endregion

    // region Thoughts

    private fun updateThoughts(guest: Guest, state: GameState, now: Double) {
        val lastThought = guest.thoughts.lastOrNull()?.simTime ?: -1000.0
        if (now - lastThought <= 22) return

        val need = ThoughtCatalog.need(guest.hunger, guest.thirst, guest.bathroomNeed, guest.energy)
        if (need != null) {
            guest.think(need.text, need.mood, now, need.icon)
            return
        }
        val cleanliness = state.map.cleanlinessScore
        if (cleanliness < 0.55 && guest.personality.cleanlinessSensitivity > 45) {
            guest.think("There's rubbish everywhere.", ThoughtMood.negative, now, ThoughtIcon.dirty)
            return
        }
        if (cleanliness > 0.97 && state.map.litteredTiles.isEmpty() && guest.happiness > 60) {
            guest.think("This park is spotless.", ThoughtMood.positive, now)
            return
        }

        val enjoyment = ThoughtCatalog.enjoyment(guest.happiness)
        if (enjoyment != null) guest.think(enjoyment.text, enjoyment.mood, now)
    }

    // endregion

    // region Queue patience

    private fun updateQueuePatience(guest: Guest, state: GameState, now: Double) {
        val activity = guest.activity as? GuestActivity.Queueing ?: return
        val target = activity.target
        val waited = now - guest.queueJoinedAt
        val tolerance = guest.queueWaitEstimate * Balance.queueAbandonGrace + 15 + guest.personality.patience * 0.5
        if (waited <= tolerance) return

        val name = state.displayName(target)
        removeFromQueue(guest.id, target, state)
        guest.activity = GuestActivity.Exploring
        guest.nextDecisionAt = now
        guest.adjustHappiness(-Balance.happinessQueueAbandonPenalty)
        guest.think(ThoughtCatalog.abandonedQueue(name), ThoughtMood.negative, now, ThoughtIcon.queue)
    }

    // endregion

    // region Decisions

    private fun shouldDecide(guest: Guest, now: Double): Boolean = when (guest.activity) {
        is GuestActivity.Arriving, is GuestActivity.Exploring -> now >= guest.nextDecisionAt
        else -> false
    }

    private class Option(val target: ParkTarget, val score: Double, val departureReason: DepartureReason?)

    private fun decide(guest: Guest, state: GameState, now: Double) {
        val options = scoreOptions(guest, state)

        guest.nextDecisionAt = now + Balance.decisionInterval + state.rng.double(0.0..Balance.decisionIntervalJitter)

        val weights = options.map { it.score }
        val chosenIndex = SimMath.weightedChoice(weights, state.rng)
        if (chosenIndex == null) {
            guest.activity = GuestActivity.Exploring
            return
        }

        commit(options[chosenIndex], guest, state, now)
    }

    private fun scoreOptions(guest: Guest, state: GameState): List<Option> {
        val options = ArrayList<Option>()
        val map = state.map

        // Every shop, restroom, booth and bench is judged by FacilityAppeal,
        // which the inspector also reads.
        for (facility in state.facilities) {
            val definition = facility.definition ?: continue
            val access = map.accessTiles(facility.rect)
            val distance = if (access.isEmpty()) null else pathfinder.distance(guest.tile, access, map)

            val verdict = FacilityAppeal.evaluate(
                facility, definition, guest, access.isNotEmpty(), distance, state.adBoosts.spendFactor,
            )
            if (verdict !is FacilityAppeal.Verdict.Wants) continue
            options.add(Option(ParkTarget.Shop(facility.id), verdict.score, null))
        }

        // An urgent need suppresses the appetite for rides almost entirely.
        val needPressure = maxOf(
            SimMath.normalise(guest.bathroomNeed, Balance.bathroomUrgent, 100.0),
            maxOf(
                SimMath.normalise(guest.hunger, Balance.hungerUrgent + 10, 100.0),
                SimMath.normalise(guest.thirst, Balance.thirstUrgent + 10, 100.0),
            ),
        )
        val rideAppetite = 1 - needPressure

        if (rideAppetite > 0.05) {
            for (attraction in state.attractions) {
                if (!attraction.isOperational) continue
                val definition = attraction.definition ?: continue
                if (guest.nausea > Balance.nauseaRefuseRide && definition.nausea > 20) continue

                val access = map.accessTiles(attraction.rect)
                if (access.isEmpty()) continue
                val distance = pathfinder.distance(guest.tile, access, map) ?: continue

                val wait = attraction.estimatedWait(definition)
                val tolerance = FacilityAppeal.tolerableWait(guest)
                if (wait >= tolerance) continue

                val thrillMatch = 1 - abs(definition.excitement - guest.personality.thrillPreference) / 100
                if (thrillMatch <= 0.2) continue

                var score = 190 * thrillMatch.pow(2) * rideAppetite
                score *= 1 - (wait / tolerance) * 0.7
                score *= FacilityAppeal.proximityFactor(distance)
                score *= attraction.condition / 100
                if (guest.recentAttractions.contains(attraction.id)) score *= 0.15

                if (score > 0.5) options.add(Option(ParkTarget.Ride(attraction.id), score, null))
            }
        }

        // Going home.
        val departure = departureUrge(guest, state)
        if (departure != null) options.add(Option(ParkTarget.Exit, departure.first, departure.second))

        // Wandering.
        val spot = randomWanderSpot(guest.tile, state)
        if (spot != null) options.add(Option(ParkTarget.Wander(spot), 22.0, null))

        return options
    }

    private fun departureUrge(guest: Guest, state: GameState): Pair<Double, DepartureReason>? {
        var score = 0.0
        var reason = DepartureReason.satisfied

        if (guest.timeInPark > guest.plannedVisitLength) {
            val overrun = (guest.timeInPark - guest.plannedVisitLength) / 120
            score = 120 + overrun * 220
            reason = DepartureReason.satisfied
        }

        if (guest.happiness < Balance.unhappyLeaveThreshold) {
            val severity = SimMath.normalise(Balance.unhappyLeaveThreshold - guest.happiness, 0.0, Balance.unhappyLeaveThreshold)
            val candidate = 200 + severity * 500
            if (candidate > score) {
                score = candidate
                reason = DepartureReason.unhappy
            }
        }

        if (guest.energy < 10 && score < 260) {
            score = 260.0
            reason = DepartureReason.tired
        }

        if (guest.bathroomNeed > 97 && score < 520 && !hasReachableBathroom(guest, state)) {
            score = 520.0
            reason = DepartureReason.noBathroom
        }

        // A filthy park drives the fussiest guests out first.
        val cleanliness = state.map.cleanlinessScore
        if (cleanliness < 0.35) {
            val disgust = (0.35 - cleanliness) / 0.35 * (guest.personality.cleanlinessSensitivity / 100)
            val candidate = 120 + disgust * 480
            if (candidate > score) {
                score = candidate
                reason = DepartureReason.tooDirty
            }
        }

        val cheapestPurchase = state.facilities
            .filter { it.definition?.kind?.sellsGoods == true }
            .minOfOrNull { it.price }
        if (cheapestPurchase != null && guest.cash < cheapestPurchase && guest.timeInPark > 180 && score < 150) {
            score = 150.0
            reason = DepartureReason.brokeAndBored
        }

        if (score <= 0) return null
        return Pair(score, reason)
    }

    private fun hasReachableBathroom(guest: Guest, state: GameState): Boolean {
        for (facility in state.facilities) {
            if (facility.definition?.kind != FacilityKind.bathroom || !facility.isOpen) continue
            val access = state.map.accessTiles(facility.rect)
            if (pathfinder.distance(guest.tile, access, state.map) != null) return true
        }
        return false
    }

    // endregion

    // region Committing to a target

    private fun commit(option: Option, guest: Guest, state: GameState, now: Double) {
        val access = state.accessTiles(option.target)

        if (access.isEmpty()) {
            guest.activity = GuestActivity.Exploring
            return
        }

        guest.departureReason = option.departureReason?.text

        // Already standing where it needs to be.
        if (access.contains(guest.tile)) {
            guest.route = mutableListOf()
            MovementSystem.beginActivity(option.target, state.guests.indexOf(guest), state, now)
            return
        }

        val route = pathfinder.route(guest.tile, access, state.map)
        if (route.isEmpty()) {
            guest.activity = GuestActivity.Exploring
            return
        }

        guest.route = route
        guest.activity = GuestActivity.Walking(option.target)

        when (val target = option.target) {
            is ParkTarget.Ride -> {
                val attraction = state.attraction(target.id)
                val definition = attraction?.definition
                if (attraction != null && definition != null) {
                    val thought = ThoughtCatalog.joinedQueue(attraction.name, attraction.estimatedWait(definition))
                    guest.think(thought.text, thought.mood, now, ThoughtIcon.ride)
                }
            }
            is ParkTarget.Exit -> {
                val reason = option.departureReason
                if (reason != null) {
                    val thought = ThoughtCatalog.leaving(reason)
                    guest.think(thought.text, thought.mood, now)
                }
            }
            else -> {}
        }
    }

    // endregion

    // region Wandering

    private fun refreshWalkableCache(map: ParkMap) {
        if (map.generation == cachedGeneration) return
        cachedGeneration = map.generation
        cachedWalkableTiles = (0 until map.tileCount).map { map.coordAt(it) }.filter { map.isWalkable(it) }
    }

    private fun randomWanderSpot(tile: GridCoord, state: GameState): GridCoord? {
        if (cachedWalkableTiles.isEmpty()) return null
        for (attempt in 0 until 6) {
            val candidate = state.rng.pick(cachedWalkableTiles) ?: return null
            if (candidate == tile) continue
            if (candidate.manhattanDistance(tile) > 18) continue
            if (pathfinder.distance(tile, listOf(candidate), state.map) != null) return candidate
        }
        return null
    }

    // endregion

    companion object {
        /** Removes a guest from whichever queue it is standing in. */
        fun removeFromQueue(guestID: UUID, target: ParkTarget, state: GameState) {
            when (target) {
                is ParkTarget.Ride -> state.attraction(target.id)?.queue?.removeAll { it == guestID }
                is ParkTarget.Shop -> state.facility(target.id)?.queue?.removeAll { it == guestID }
                else -> {}
            }
        }
    }
}
