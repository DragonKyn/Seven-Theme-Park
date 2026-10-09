package com.wickedstudios.wonderlot

import java.util.UUID

/**
 * Decides how many people want to visit, and admits them. Demand is bounded by
 * park quality: nothing here spawns guests unconditionally.
 */
class DemandSystem {

    fun update(state: GameState, dt: Double) {
        // Tour buses arrive on their own schedule, not out of the trickle.
        if (TourBusSystem.shouldArrive(state)) admitTourBus(state)

        val arrivals = arrivalsPerMinute(state)
        state.currentArrivalsPerMinute = arrivals

        if (arrivals <= 0) return
        state.spawnAccumulator += arrivals / 60.0 * dt

        while (state.spawnAccumulator >= 1) {
            state.spawnAccumulator -= 1
            if (state.guestCount >= Balance.maxGuests) {
                state.spawnAccumulator = 0.0
                break
            }
            admitGuest(state)
        }
    }

    // region Demand model

    fun arrivalsPerMinute(state: GameState): Double {
        val openAttractions = state.attractions.filter { it.isOpen && it.definition != null }

        // Rides are the reason to visit; variety and thrill both matter.
        var attractionScore = 0.0
        for (attraction in openAttractions) {
            val definition = attraction.definition ?: continue
            attractionScore += 0.35 + definition.excitement / 100
        }
        attractionScore = minOf(attractionScore, Balance.maxAttractionAppeal)

        val facilityBonus = minOf(1.0, state.facilities.size * 0.12)
        val appeal = Balance.baseArrivalsPerMinute + attractionScore * 1.6 + facilityBonus

        val ratingFactor = 0.55 + 1.0 * (state.parkRating / 100)

        val acceptable = GuestEconomics.acceptableAdmission(openAttractions.size, state.parkRating)
        val priceFactor = GuestEconomics.admissionWillingness(state.admissionPrice, acceptable)

        // Nobody comes to a park they cannot walk into.
        if (!state.map.isWalkable(state.map.entranceCoord)) return 0.0

        val parking = CarParkContent.demandMultiplier(state.carParkLevel)

        // A post about the park, or a warm review, is a short sharp rush.
        val word = 1 + state.activePromotionBoost + state.activeReviewArrivals +
            state.adBoosts.extraArrivals + state.perks.extraArrivals

        return SimMath.clamp(appeal * ratingFactor * priceFactor * parking * word, 0.0, Balance.maxArrivalsPerMinute)
    }

    /** Admits guests immediately, bypassing the demand model. Used to populate the demo park. */
    fun seed(count: Int, state: GameState) {
        for (i in 0 until count) {
            if (state.guestCount >= Balance.maxGuests) break
            admitGuest(state)
        }
    }

    /** A tour bus pulls up and empties. */
    fun admitTourBus(state: GameState) {
        // Booked first, so every way out of this method still re-books.
        TourBusSystem.scheduleNext(state)

        val wanted = state.rng.int(Balance.tourBusSize)
        val room = Balance.maxGuests - state.guestCount
        val count = minOf(wanted, room)
        // A park with no room left turns the bus round at the gate.
        if (count < Balance.tourBusMinimumSize) return

        val groupID = UUID.randomUUID()
        var childCount = 0
        for (i in 0 until count) {
            val isChild = state.rng.chance(Balance.tourBusChildShare)
            if (isChild) childCount += 1
            admitGuest(state, if (isChild) AgeCategory.child else AgeCategory.adult,
                Balance.tourBusSpendScale, groupID)
        }

        val name = GuestNames.tourGroup(state.rng)
        state.pendingTourBuses.add(TourBusReport(groupName = name, count = count, childCount = childCount))
        state.statistics.tourBusesTotal += 1
        state.postAlert("$name has arrived, $count of them at once.", AlertSeverity.info, "tourBus", cooldown = 60.0)
    }

    // endregion

    // region Admission

    private fun admitGuest(
        state: GameState,
        ageOverride: AgeCategory? = null,
        cashScale: Double = 1.0,
        groupID: UUID? = null,
    ) {
        val entrance = state.map.entranceCoord
        val now = state.clock.simTime
        val rng = state.rng

        val age = ageOverride ?: randomAge(rng)
        val personality = GuestPersonality.random(age, rng)

        val cashRange = when (age) {
            AgeCategory.child -> 30.0..80.0
            AgeCategory.adult -> 65.0..170.0
            AgeCategory.senior -> 50.0..140.0
        }
        val spendingScale = 0.7 + personality.spending / 100 * 0.6
        // Spending money, plus the price of the ticket on top: somebody who has
        // decided the gate is worth it brings the gate money with them.
        val spendingMoney = rng.double(cashRange) * spendingScale * cashScale * (1 + state.perks.guestSpending)
        val startingCash = spendingMoney + state.admissionPrice

        val speedScale = when (age) {
            AgeCategory.child -> 0.9
            AgeCategory.adult -> 1.0
            AgeCategory.senior -> 0.82
        }

        val name = GuestNames.random(rng)
        val happiness = SimMath.clamp(rng.double(62.0..86.0) + state.perks.guestHappiness)
        val hunger = rng.double(5.0..35.0)
        val thirst = rng.double(10.0..40.0)
        val energy = rng.double(72.0..100.0)
        val bathroomNeed = rng.double(0.0..25.0)
        val speedJitter = rng.double(-Balance.guestWalkSpeedVariance..Balance.guestWalkSpeedVariance)
        val visitJitter = rng.double(-Balance.visitLengthVariance..Balance.visitLengthVariance)

        val guest = Guest(
            id = UUID.randomUUID(),
            name = name,
            ageCategory = age,
            personality = personality,
            cash = startingCash,
            happiness = happiness,
            hunger = hunger,
            thirst = thirst,
            energy = energy,
            bathroomNeed = bathroomNeed,
            position = entrance.centre,
            tile = entrance,
            walkSpeed = (Balance.guestWalkSpeed + speedJitter) * speedScale,
            plannedVisitLength = Balance.visitLengthBase + visitJitter,
            activity = GuestActivity.Arriving,
        )
        guest.appearance = GuestAppearance.random(age, rng)
        guest.groupID = groupID

        // Every so often, somebody with an audience. Never somebody who came on a bus.
        if (groupID == null && PromotionSystem.shouldAdmitInfluencer(state)) {
            guest.isInfluencer = true
            // Dressed to be found in a crowd, and filming.
            guest.appearance = GuestAppearance(
                shirt = ParkColour.pink, hair = guest.appearance.hair, skin = guest.appearance.skin,
                hat = GuestAppearance.HatStyle.none, bottoms = ParkColour.charcoal,
                pattern = GuestAppearance.ShirtPattern.plain, accessory = GuestAppearance.Accessory.phone,
            )
            guest.cash += 120
            PromotionSystem.scheduleNext(state)
        } else if (groupID == null && TroublemakerSystem.shouldAdmit(state)) {
            TroublemakerSystem.mark(guest, state, now)
            TroublemakerSystem.scheduleNext(state)
        } else if (groupID == null && CriticSystem.shouldAdmit(state)) {
            // Nothing is changed about how they look. Being impossible to spot is the whole event.
            guest.isCritic = true
            CriticSystem.scheduleNext(state)
        }

        guest.nextDecisionAt = now + 1

        // Pay at the gate.
        val price = state.admissionPrice
        if (price > 0) {
            guest.cash = maxOf(0.0, guest.cash - price)
            guest.moneySpent += price
            state.ledger.receive(price, RevenueCategory.admission)
        }

        val acceptable = GuestEconomics.acceptableAdmission(state.attractions.size, state.parkRating)
        val willingness = GuestEconomics.admissionWillingness(price, acceptable)
        val thought = ThoughtCatalog.admission(price, willingness)
        guest.think(thought.text, thought.mood, now, ThoughtIcon.money)

        state.guests.add(guest)
        state.statistics.guestsAdmittedToday += 1
        state.statistics.guestsAdmittedTotal += 1
    }

    private fun randomAge(rng: SeededGenerator): AgeCategory {
        val roll = rng.double(0.0..1.0)
        if (roll < 0.25) return AgeCategory.child
        if (roll < 0.87) return AgeCategory.adult
        return AgeCategory.senior
    }

    // endregion
}
