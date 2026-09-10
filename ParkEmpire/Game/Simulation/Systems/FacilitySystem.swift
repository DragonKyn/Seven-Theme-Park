import Foundation

/// Serves guests at shops, restrooms and benches: pulls them off the queue into
/// a service slot, takes their money, and applies the need relief when done.
final class FacilitySystem {

    func update(state: GameState, dt: Double) {
        let now = state.clock.simTime

        for index in state.facilities.indices {
            guard let definition = state.facilities[index].definition else { continue }
            advanceSlots(facilityIndex: index, definition: definition, state: state, dt: dt, now: now)
            fillSlots(facilityIndex: index, definition: definition, state: state, now: now)
            reindexQueue(facilityIndex: index, state: state)
        }
    }

    // MARK: - Service in progress

    private func advanceSlots(facilityIndex: Int,
                              definition: FacilityDefinition,
                              state: GameState,
                              dt: Double,
                              now: Double) {
        var completed: [UUID] = []

        for slotIndex in state.facilities[facilityIndex].slots.indices {
            state.facilities[facilityIndex].slots[slotIndex].remaining -= dt
            if state.facilities[facilityIndex].slots[slotIndex].remaining <= 0 {
                completed.append(state.facilities[facilityIndex].slots[slotIndex].guestID)
            }
        }

        guard !completed.isEmpty else { return }
        state.facilities[facilityIndex].slots.removeAll { completed.contains($0.guestID) }

        for guestID in completed {
            guard let guestIndex = state.guestIndex(id: guestID) else { continue }
            applyRelief(definition.relief, guestIndex: guestIndex, state: state)
            applyAftereffects(kind: definition.kind,
                              facilityIndex: facilityIndex,
                              guestIndex: guestIndex,
                              state: state,
                              now: now)
            state.guests[guestIndex].activity = .exploring
            state.guests[guestIndex].nextDecisionAt = now
            state.guests[guestIndex].queueWaitEstimate = 0
        }
    }

    /// What using the facility leaves behind: rubbish in the guest's hand, a
    /// dirtier restroom, or a fuller bin.
    private func applyAftereffects(kind: FacilityKind,
                                   facilityIndex: Int,
                                   guestIndex: Int,
                                   state: GameState,
                                   now: Double) {
        switch kind {
        case .bathroom:
            // Judged on the state it was in when they walked in.
            if state.facilities[facilityIndex].isDirty {
                state.guests[guestIndex].adjustHappiness(-Balance.happinessDirtyBathroomPenalty)
                state.guests[guestIndex].think("That restroom needs cleaning badly.",
                                               mood: .negative, at: now)
            }
            state.facilities[facilityIndex].soiling = SimMath.clamp(
                state.facilities[facilityIndex].soiling + Balance.bathroomSoilPerUse)

        case .food, .drink:
            guard state.rng.chance(Balance.trashChancePerPurchase) else { return }
            state.guests[guestIndex].carryingTrash = min(3, state.guests[guestIndex].carryingTrash + 1)
            state.guests[guestIndex].trashCarriedFor = 0

        case .bin:
            CleanlinessSystem.disposeOfTrash(guestIndex: guestIndex,
                                             facilityIndex: facilityIndex,
                                             state: state)

        case .souvenir, .bench:
            break
        }
    }

    /// Positive `hunger`/`thirst`/`bathroom` values *reduce* those needs;
    /// `energy` and `happiness` are goods, so they are added.
    private func applyRelief(_ relief: NeedRelief, guestIndex: Int, state: GameState) {
        let guest = state.guests[guestIndex]
        state.guests[guestIndex].hunger = SimMath.clamp(guest.hunger - relief.hunger)
        state.guests[guestIndex].thirst = SimMath.clamp(guest.thirst - relief.thirst)
        state.guests[guestIndex].bathroomNeed = SimMath.clamp(guest.bathroomNeed - relief.bathroom)
        state.guests[guestIndex].nausea = SimMath.clamp(guest.nausea - relief.nausea)
        state.guests[guestIndex].energy = SimMath.clamp(guest.energy + relief.energy)
        state.guests[guestIndex].adjustHappiness(relief.happiness)
    }

    // MARK: - Taking the next guest

    private func fillSlots(facilityIndex: Int,
                           definition: FacilityDefinition,
                           state: GameState,
                           now: Double) {
        guard state.facilities[facilityIndex].isOpen,
              !state.facilities[facilityIndex].isUnusable else { return }
        let facilityID = state.facilities[facilityIndex].id

        while state.facilities[facilityIndex].slots.count < definition.simultaneousCapacity,
              !state.facilities[facilityIndex].queue.isEmpty {

            let guestID = state.facilities[facilityIndex].queue.removeFirst()
            guard let guestIndex = state.guestIndex(id: guestID),
                  state.guests[guestIndex].isActive,
                  case .queueing(.facility(let queuedFor)) = state.guests[guestIndex].activity,
                  queuedFor == facilityID else {
                continue
            }

            if definition.kind.sellsGoods {
                guard sell(facilityIndex: facilityIndex,
                           definition: definition,
                           guestIndex: guestIndex,
                           state: state,
                           now: now) else {
                    // Priced out at the counter: back onto the paths.
                    state.guests[guestIndex].activity = .exploring
                    state.guests[guestIndex].nextDecisionAt = now + 2
                    continue
                }
            }

            state.facilities[facilityIndex].slots.append(
                ServiceSlot(guestID: guestID, remaining: definition.serviceDuration))
            state.guests[guestIndex].activity = .engaged(.facility(facilityID))
        }
    }

    /// Charges the guest. Returns false when the guest refuses at the counter,
    /// which is how a high price shows up as lost sales rather than lost guests.
    private func sell(facilityIndex: Int,
                      definition: FacilityDefinition,
                      guestIndex: Int,
                      state: GameState,
                      now: Double) -> Bool {
        let price = state.facilities[facilityIndex].price
        let guest = state.guests[guestIndex]

        let willingness = GuestEconomics.purchaseWillingness(
            price: price,
            reference: definition.referencePrice,
            spending: guest.personality.spending)

        state.facilities[facilityIndex].sentimentSum += willingness
        state.facilities[facilityIndex].sentimentCount += 1

        let (text, mood) = ThoughtCatalog.priceReaction(item: definition.displayName.lowercased(),
                                                        price: price,
                                                        willingness: willingness)
        state.guests[guestIndex].think(text, mood: mood, at: now, icon: .money)

        guard guest.cash >= price else {
            let (outOfMoney, outOfMoneyMood) = ThoughtCatalog.outOfMoney()
            state.guests[guestIndex].think(outOfMoney, mood: outOfMoneyMood, at: now, icon: .money)
            return false
        }

        // Guests who think the price is unfair walk away and remember it.
        if !state.rng.chance(max(willingness, 0.02)) {
            state.guests[guestIndex].adjustHappiness(-Balance.happinessOverpricedPenalty)
            return false
        }

        state.guests[guestIndex].cash -= price
        state.guests[guestIndex].moneySpent += price
        state.guests[guestIndex].purchases += 1

        state.facilities[facilityIndex].revenueToday += price
        state.facilities[facilityIndex].totalRevenue += price
        state.facilities[facilityIndex].totalCost += definition.unitCost
        state.facilities[facilityIndex].customersToday += 1
        state.facilities[facilityIndex].totalCustomers += 1

        state.ledger.receive(price, as: revenueCategory(for: definition.kind))
        state.ledger.spend(definition.unitCost, on: .inventory)
        state.statistics.itemsSoldTotal += 1

        return true
    }

    private func revenueCategory(for kind: FacilityKind) -> RevenueCategory {
        switch kind {
        case .food: return .food
        case .drink: return .drinks
        case .souvenir: return .souvenirs
        default: return .other
        }
    }

    private func reindexQueue(facilityIndex: Int, state: GameState) {
        for (slot, guestID) in state.facilities[facilityIndex].queue.enumerated() {
            if let guestIndex = state.guestIndex(id: guestID) {
                state.guests[guestIndex].queueSlot = slot
            }
        }
    }
}
