package com.wickedstudios.wonderlot

import java.util.UUID

/**
 * Serves guests at shops, restrooms and benches: pulls them off the queue into
 * a service slot, takes their money, and applies the need relief when done.
 */
class FacilitySystem {

    fun update(state: GameState, dt: Double) {
        val now = state.clock.simTime

        for (facility in state.facilities) {
            val definition = facility.definition ?: continue
            advanceSlots(facility, definition, state, dt, now)
            fillSlots(facility, definition, state, now)
            reindexQueue(facility, state)
        }
    }

    // region Service in progress

    private fun advanceSlots(facility: Facility, definition: FacilityDefinition, state: GameState, dt: Double, now: Double) {
        val completed = ArrayList<UUID>()

        for (slot in facility.slots) {
            slot.remaining -= dt
            if (slot.remaining <= 0) completed.add(slot.guestID)
        }

        if (completed.isEmpty()) return
        facility.slots.removeAll { it.guestID in completed }

        for (guestID in completed) {
            val guest = state.guest(guestID) ?: continue
            applyRelief(definition.relief, guest)
            applyAftereffects(definition, facility, guest, state, now)
            guest.activity = GuestActivity.Exploring
            guest.nextDecisionAt = now
            guest.queueWaitEstimate = 0.0
        }
    }

    /** What using the facility leaves behind: rubbish in the guest's hand, a dirtier restroom, or a fuller bin. */
    private fun applyAftereffects(definition: FacilityDefinition, facility: Facility, guest: Guest, state: GameState, now: Double) {
        when (definition.kind) {
            FacilityKind.game -> playGame(facility, guest, state, now)

            FacilityKind.bathroom -> {
                // Judged on the state it was in when they walked in.
                if (facility.isDirty) {
                    guest.adjustHappiness(-Balance.happinessDirtyBathroomPenalty)
                    guest.think("That restroom needs cleaning badly.", ThoughtMood.negative, now)
                }
                facility.soiling = SimMath.clamp(facility.soiling + definition.soilingPerUse)
            }

            FacilityKind.food, FacilityKind.drink -> {
                // A bag of popcorn is carried and eaten as the guest walks, and
                // only becomes rubbish once it is empty (CleanlinessSystem).
                if (definition.carriesSnack) {
                    guest.popcornRemaining = Balance.popcornEatSeconds
                    return
                }
                if (!state.rng.chance(Balance.trashChancePerPurchase)) return
                guest.carryingTrash = minOf(3, guest.carryingTrash + 1)
                guest.trashCarriedFor = 0.0
            }

            FacilityKind.bin -> CleanlinessSystem.disposeOfTrash(guest, facility, state)

            FacilityKind.souvenir, FacilityKind.bench -> {}
        }
    }

    /** Settles a go on a carnival booth. Winning means the prize is carried for the rest of the visit. */
    private fun playGame(facility: Facility, guest: Guest, state: GameState, now: Double) {
        val definition = facility.definition ?: return

        if (!state.rng.chance(definition.winChance)) {
            guest.adjustHappiness(-Balance.happinessGameLoss)
            val thought = ThoughtCatalog.gameLost(definition.displayName)
            guest.think(thought.text, thought.mood, now, ThoughtIcon.ride)
            return
        }

        val prize = GuestPrize.random(state.rng, definition.winChance)
        guest.prize = prize
        guest.prizesWon += 1
        guest.adjustHappiness(Balance.happinessGameWin)
        state.statistics.prizesWonTotal += 1
        facility.prizesGiven += 1

        val thought = ThoughtCatalog.gameWon(prize.displayName)
        guest.think(thought.text, thought.mood, now, ThoughtIcon.ride)
    }

    /** Positive hunger/thirst/bathroom values reduce those needs; energy and happiness are goods. */
    private fun applyRelief(relief: NeedRelief, guest: Guest) {
        guest.hunger = SimMath.clamp(guest.hunger - relief.hunger)
        guest.thirst = SimMath.clamp(guest.thirst - relief.thirst)
        guest.bathroomNeed = SimMath.clamp(guest.bathroomNeed - relief.bathroom)
        guest.nausea = SimMath.clamp(guest.nausea - relief.nausea)
        guest.energy = SimMath.clamp(guest.energy + relief.energy)
        guest.adjustHappiness(relief.happiness)
    }

    // endregion

    // region Taking the next guest

    private fun fillSlots(facility: Facility, definition: FacilityDefinition, state: GameState, now: Double) {
        if (!facility.isAcceptingGuests || facility.isUnusable) return
        val facilityID = facility.id

        while (facility.slots.size < definition.simultaneousCapacity && facility.queue.isNotEmpty()) {
            val guestID = facility.queue.removeAt(0)
            val guest = state.guest(guestID) ?: continue
            if (!guest.isActive) continue
            val activity = guest.activity
            if (activity !is GuestActivity.Queueing) continue
            val queuedFor = activity.target as? ParkTarget.Shop ?: continue
            if (queuedFor.id != facilityID) continue

            if (definition.kind.sellsGoods) {
                if (!sell(facility, definition, guest, state, now)) {
                    // Priced out at the counter: back onto the paths.
                    guest.activity = GuestActivity.Exploring
                    guest.nextDecisionAt = now + 2
                    continue
                }
            }

            // Somewhere that sells nothing never counts customers when it sells, so count visits as they begin.
            if (definition.kind.countsVisits) {
                facility.customersToday += 1
                facility.totalCustomers += 1
            }

            facility.slots.add(ServiceSlot(guestID, definition.serviceDuration))
            guest.activity = GuestActivity.Engaged(ParkTarget.Shop(facilityID))
        }
    }

    /** Charges the guest. Returns false when the guest refuses at the counter. */
    private fun sell(facility: Facility, definition: FacilityDefinition, guest: Guest, state: GameState, now: Double): Boolean {
        val price = facility.price

        // The shop records how fair the crowd found the price, which an advert should not flatter.
        val fairness = GuestEconomics.purchaseWillingness(price, definition.referencePrice, guest.personality.spending)
        val willingness = fairness * state.adBoosts.spendFactor

        facility.sentimentSum += fairness
        facility.sentimentCount += 1

        val reaction = ThoughtCatalog.priceReaction(definition.displayName.lowercase(), price, fairness)
        guest.think(reaction.text, reaction.mood, now, ThoughtIcon.money)

        if (guest.cash < price) {
            val broke = ThoughtCatalog.outOfMoney()
            guest.think(broke.text, broke.mood, now, ThoughtIcon.money)
            return false
        }

        // Guests who think the price is unfair walk away and remember it.
        if (!state.rng.chance(maxOf(willingness, 0.02))) {
            guest.adjustHappiness(-Balance.happinessOverpricedPenalty)
            return false
        }

        guest.cash -= price
        guest.moneySpent += price
        guest.purchases += 1

        facility.revenueToday += price
        facility.totalRevenue += price
        val stockCost = definition.unitCost * state.perks.stockFactor
        facility.totalCost += stockCost
        facility.customersToday += 1
        facility.totalCustomers += 1

        state.ledger.receive(price, revenueCategory(definition.kind))
        state.ledger.spend(stockCost, ExpenseCategory.inventory)
        state.statistics.itemsSoldTotal += 1
        when (definition.kind) {
            FacilityKind.food -> state.statistics.foodSoldTotal += 1
            FacilityKind.drink -> state.statistics.drinksSoldTotal += 1
            FacilityKind.souvenir -> state.statistics.souvenirsSoldTotal += 1
            FacilityKind.game -> state.statistics.gamesPlayedTotal += 1
            else -> {}
        }

        return true
    }

    private fun revenueCategory(kind: FacilityKind): RevenueCategory = when (kind) {
        FacilityKind.food -> RevenueCategory.food
        FacilityKind.drink -> RevenueCategory.drinks
        // A go on a booth is a souvenir sold before it is won.
        FacilityKind.game -> RevenueCategory.souvenirs
        else -> RevenueCategory.other
    }

    private fun reindexQueue(facility: Facility, state: GameState) {
        for ((slot, guestID) in facility.queue.withIndex()) {
            state.guest(guestID)?.queueSlot = slot
        }
    }

    // endregion
}
