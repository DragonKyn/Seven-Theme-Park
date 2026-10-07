import CoreGraphics
import Foundation

/// Employees: wages, choosing their own work, walking to it, and doing it.
///
/// Job search runs a single breadth-first sweep outwards from the staff
/// member's own tile and then reads every candidate's distance out of it. That
/// is one grid sweep per employee every few seconds, rather than one route
/// query per candidate.
final class StaffSystem {

    private let pathfinder: PathfindingSystem

    /// Which stretches of walkway join, worked out once per change to the map
    /// and shared by every employee's job search.
    private var islandCache: (generation: Int, labels: [Int])?

    private func islandLabels(_ map: ParkMap) -> [Int] {
        if let cached = islandCache, cached.generation == map.generation { return cached.labels }
        let labels = StaffTransit.islands(in: map)
        islandCache = (map.generation, labels)
        return labels
    }

    init(pathfinder: PathfindingSystem) {
        self.pathfinder = pathfinder
    }

    func update(state: GameState, dt: Double) {
        chargeWages(state: state, dt: dt)
        releaseAbandonedCleaning(state: state)
        guard !state.staff.isEmpty else { return }

        let map = state.map
        let now = state.clock.simTime
        var claimed = claimedJobs(state: state)

        for index in state.staff.indices {
            switch state.staff[index].activity {
            case .idle:
                guard now >= state.staff[index].nextJobSearchAt else { continue }
                state.staff[index].nextJobSearchAt = now + Balance.staffJobSearchInterval

                // What the player asked for comes before anything the employee
                // would have picked for themselves.
                let ordered = state.staff[index].orders
                state.staff[index].orders = nil
                let job = ordered ?? findJob(staffIndex: index, state: state, map: map, claimed: claimed)

                if let job, beginTravel(to: job, staffIndex: index, state: state, map: map) {
                    claimed.insert(job)
                } else if let ordered {
                    stand(staffIndex: index, order: ordered, state: state, map: map)
                }

            case .travelling(let job):
                travel(staffIndex: index, job: job, state: state, map: map, dt: dt, now: now)

            case .working(let job):
                work(staffIndex: index, job: job, state: state, dt: dt, now: now)
            }
        }
    }

    // MARK: - Restrooms being cleaned

    /// A restroom is shut for as long as somebody is cleaning it, which means
    /// it must reopen if that somebody stops: dismissed, or reassigned. A
    /// restroom left shut with nobody in it would stay shut for ever.
    private func releaseAbandonedCleaning(state: GameState) {
        for index in state.facilities.indices where state.facilities[index].isBeingCleaned {
            let id = state.facilities[index].id
            let attended = state.staff.contains { member -> Bool in
                if case .working(.serviceFacility(let target)) = member.activity {
                    return target == id
                }
                return false
            }
            if !attended {
                state.facilities[index].cleaningRemaining = 0
                state.facilities[index].cleaningTotal = 0
            }
        }
    }

    /// Shuts a restroom and sends away anybody waiting for it. The janitor
    /// has arrived and the doors are closed; whoever is already inside is let
    /// finish.
    private func beginCleaning(facilityID: UUID, state: GameState) {
        guard let index = state.facilityIndex(id: facilityID),
              let definition = state.facilities[index].definition,
              definition.cleaningMinutes > 0 else { return }

        let dirt = state.facilities[index].soiling / 100
        let total = definition.cleaningMinutes * (1 + Balance.cleaningDirtExtra * dirt)
        state.facilities[index].cleaningTotal = total
        state.facilities[index].cleaningRemaining = total

        let now = state.clock.simTime
        for guestID in state.facilities[index].queue {
            guard let guestIndex = state.guestIndex(id: guestID) else { continue }
            state.guests[guestIndex].activity = .exploring
            state.guests[guestIndex].queueWaitEstimate = 0
            state.guests[guestIndex].nextDecisionAt = now
        }
        state.facilities[index].queue.removeAll()
    }

    private func cleanRestroom(staffIndex: Int,
                               facilityIndex: Int,
                               state: GameState,
                               dt: Double,
                               now: Double) {
        // Wait for the last user to come out.
        guard state.facilities[facilityIndex].slots.isEmpty else { return }

        state.facilities[facilityIndex].cleaningRemaining -= state.staff[staffIndex].workRate * dt
        guard state.facilities[facilityIndex].cleaningRemaining <= 0 else { return }

        state.facilities[facilityIndex].cleaningRemaining = 0
        state.facilities[facilityIndex].cleaningTotal = 0
        state.facilities[facilityIndex].soiling = 0
        state.facilities[facilityIndex].timesServiced += 1
        finish(staffIndex: staffIndex, state: state, now: now)
    }

    // MARK: - Wages

    private func chargeWages(state: GameState, dt: Double) {
        guard !state.staff.isEmpty else { return }
        let perSecond = state.staff.reduce(0.0) { $0 + $1.wagePerSecond }
        state.ledger.spend(perSecond * state.perks.wageFactor * dt, on: .wages)
    }

    // MARK: - Job assignment

    private func claimedJobs(state: GameState) -> Set<StaffJob> {
        var claimed: Set<StaffJob> = []
        for member in state.staff {
            if let job = member.currentJob { claimed.insert(job) }
        }
        return claimed
    }

    private func findJob(staffIndex: Int,
                         state: GameState,
                         map: ParkMap,
                         claimed: Set<StaffJob>) -> StaffJob? {
        let member = state.staff[staffIndex]
        guard map.isWalkable(member.tile) else { return nil }

        // Distances from this employee to everywhere, in one sweep.
        let field = pathfinder.distanceField(to: [member.tile], in: map)

        // Somewhere only reachable by train still counts, for the jobs that
        // can be done from the far side of it.
        let transit = StaffTransit(state: state, field: field, labels: islandLabels(map))

        func walkingDistance(to coord: GridCoord) -> Int? {
            guard map.isWalkable(coord) else { return nil }
            let value = field[map.linearIndex(of: coord)]
            return value == PathfindingSystem.unreachable ? nil : value
        }

        func distance(to coord: GridCoord) -> Int? {
            if let walk = walkingDistance(to: coord) { return walk }
            guard map.isWalkable(coord) else { return nil }
            return transit?.plan(to: [coord])?.cost
        }

        func nearestAccess(_ rect: GridRect) -> Int? {
            let tiles = map.accessTiles(for: rect)
            if let walk = tiles.compactMap({ walkingDistance(to: $0) }).min() { return walk }
            return transit?.plan(to: tiles)?.cost
        }

        switch member.role {
        case .janitor:
            var bestJob: StaffJob?
            var bestScore = -Double.greatestFiniteMagnitude

            // Bins and restrooms first: they are the cause, litter is the symptom.
            for facility in state.facilities {
                guard let priority = facility.servicingPriority else { continue }
                let job = StaffJob.serviceFacility(facility.id)
                guard !claimed.contains(job), let steps = nearestAccess(facility.rect) else { continue }
                let score = priority * 4 - Double(steps)
                if score > bestScore {
                    bestScore = score
                    bestJob = job
                }
            }

            for coord in map.litteredTiles {
                let job = StaffJob.cleanLitter(coord)
                guard !claimed.contains(job), let steps = distance(to: coord) else { continue }
                let score = map.litter(at: coord) - Double(steps) * 3
                if score > bestScore {
                    bestScore = score
                    bestJob = job
                }
            }

            return bestJob

        case .mechanic:
            var bestJob: StaffJob?
            var bestScore = -Double.greatestFiniteMagnitude
            for attraction in state.attractions {
                guard let priority = attraction.maintenancePriority else { continue }
                // A ride an inspector shut needs putting right, not looking
                // over, so it goes on the repair list alongside broken ones.
                let job = (attraction.isBroken || attraction.isImpounded)
                    ? StaffJob.repairRide(attraction.id)
                    : StaffJob.inspectRide(attraction.id)
                guard !claimed.contains(job), let steps = nearestAccess(attraction.rect) else { continue }
                let score = priority - Double(steps)
                if score > bestScore {
                    bestScore = score
                    bestJob = job
                }
            }
            return bestJob

        case .entertainer, .mascot:
            // Head for whichever queue is longest; failing that, wander.
            let busiest = state.attractions
                .filter { !$0.queue.isEmpty }
                .max(by: { $0.queue.count < $1.queue.count })

            if let busiest,
               let spot = map.accessTiles(for: busiest.rect).first(where: { distance(to: $0) != nil }) {
                let job = StaffJob.entertain(spot)
                if !claimed.contains(job) { return job }
            }

            // A mascot goes where the people are, which is what it is for.
            if member.role == .mascot,
               let spot = crowdedSpot(map: map, field: field, state: state) {
                return .entertain(spot)
            }

            if let spot = randomReachableTile(map: map, field: field, state: state) {
                return .entertain(spot)
            }
            return nil

        case .security:
            // A troublemaker outranks any post. This is the job the uniform
            // exists for, and a guard standing at the gate while somebody
            // tips a bin over behind them is the wrong picture entirely.
            let now = state.clock.simTime
            if let target = state.guests.first(where: {
                   $0.isActive && $0.isTroublemaker
                       && TroublemakerSystem.isNoticed($0, at: now)
                       && !claimed.contains(.escort($0.id))
               }),
               walkingDistance(to: target.tile) != nil {
                return .escort(target.id)
            }

            // The gate most of the time, because that is where guests arrive
            // and where a guard is worth the most; a lap of the park the rest
            // of the time, so the uniform is seen somewhere other than the
            // front door.
            if !state.rng.chance(Balance.securityPatrolChance),
               let post = gatePost(map: map, state: state, claimed: claimed, distance: distance) {
                return .patrol(post)
            }
            if let spot = randomReachableTile(map: map, field: field, state: state) {
                return .patrol(spot)
            }
            if let post = gatePost(map: map, state: state, claimed: claimed, distance: distance) {
                return .patrol(post)
            }
            return nil
        }
    }

    /// A spot to stand near the front gate that nobody else has taken.
    private func gatePost(map: ParkMap,
                          state: GameState,
                          claimed: Set<StaffJob>,
                          distance: (GridCoord) -> Int?) -> GridCoord? {
        let gate = map.entranceCoord
        let reach = Balance.securityGateRadius
        var posts: [GridCoord] = []

        for dx in -reach...reach {
            for dy in 0...reach {
                let coord = GridCoord(gate.x + dx, gate.y + dy)
                guard map.isWalkable(coord), distance(coord) != nil else { continue }
                guard !claimed.contains(.patrol(coord)) else { continue }
                posts.append(coord)
            }
        }

        guard !posts.isEmpty else { return nil }
        return posts[state.rng.int(0...(posts.count - 1))]
    }

    private func randomReachableTile(map: ParkMap, field: [Int], state: GameState) -> GridCoord? {
        for _ in 0..<8 {
            let index = state.rng.int(0...(map.tileCount - 1))
            let coord = map.coord(atLinearIndex: index)
            guard map.isWalkable(coord),
                  field[index] != PathfindingSystem.unreachable,
                  field[index] > 2 else { continue }
            return coord
        }
        return nil
    }

    // MARK: - Travel

    private func beginTravel(to job: StaffJob,
                             staffIndex: Int,
                             state: GameState,
                             map: ParkMap) -> Bool {
        let destinations = destinationTiles(for: job, state: state, map: map)
        guard !destinations.isEmpty else { return false }

        let tile = state.staff[staffIndex].tile
        if destinations.contains(tile) {
            state.staff[staffIndex].route = []
            state.staff[staffIndex].transfer = nil
            startWork(staffIndex: staffIndex, job: job, state: state)
            return true
        }

        let route = pathfinder.route(from: tile, to: destinations, in: map)
        if route.isEmpty {
            // Not on foot. By train, if there is one that goes there.
            let field = pathfinder.distanceField(to: [tile], in: map)
            guard let transit = StaffTransit(state: state, field: field, labels: islandLabels(map)),
                  let hop = transit.plan(to: destinations) else { return false }

            let toPlatform = hop.boarding.contains(tile)
                ? []
                : pathfinder.route(from: tile, to: hop.boarding, in: map)
            guard hop.boarding.contains(tile) || !toPlatform.isEmpty else { return false }

            state.staff[staffIndex].transfer = hop.transfer
            state.staff[staffIndex].route = toPlatform
            state.staff[staffIndex].activity = .travelling(job)
            return true
        }

        state.staff[staffIndex].transfer = nil
        state.staff[staffIndex].route = route
        state.staff[staffIndex].activity = .travelling(job)
        return true
    }

    /// An order that could not be carried out by walking or riding: there is
    /// no way there at all. Rather than ignore it, the employee is put on the
    /// spot, which is also how an employee stranded somewhere is got out.
    private func stand(staffIndex: Int, order: StaffJob, state: GameState, map: ParkMap) {
        guard case .goTo(let coord) = order, map.isWalkable(coord) else { return }
        state.staff[staffIndex].tile = coord
        state.staff[staffIndex].position = coord.centre
        state.staff[staffIndex].route = []
        state.staff[staffIndex].transfer = nil
        startWork(staffIndex: staffIndex, job: order, state: state)
    }

    private func destinationTiles(for job: StaffJob, state: GameState, map: ParkMap) -> [GridCoord] {
        switch job {
        case .cleanLitter(let coord), .entertain(let coord), .patrol(let coord), .goTo(let coord):
            return map.isWalkable(coord) ? [coord] : []
        case .serviceFacility(let id):
            guard let facility = state.facility(id: id) else { return [] }
            return map.accessTiles(for: facility.rect)
        case .repairRide(let id), .inspectRide(let id):
            guard let attraction = state.attraction(id: id) else { return [] }
            return map.accessTiles(for: attraction.rect)
        case .escort(let id):
            guard let guest = state.guest(id: id), map.isWalkable(guest.tile) else { return [] }
            return [guest.tile]
        }
    }

    private func travel(staffIndex: Int,
                        job: StaffJob,
                        state: GameState,
                        map: ParkMap,
                        dt: Double,
                        now: Double) {
        // The only job whose destination walks away while it is being walked
        // to, so it gets its own chase rather than a route planned once.
        if case .escort(let id) = job {
            chase(staffIndex: staffIndex, guestID: id, state: state, map: map, dt: dt, now: now)
            return
        }

        // Part of the way by train: the walk to the platform, the wait, the
        // ride and the step off are all handled together.
        if state.staff[staffIndex].transfer != nil {
            travelByTrain(staffIndex: staffIndex, job: job, state: state, map: map, dt: dt, now: now)
            return
        }

        if state.staff[staffIndex].route.isEmpty {
            startWork(staffIndex: staffIndex, job: job, state: state)
            return
        }

        // Local copy: several `inout` arguments through an array subscript
        // would be overlapping access.
        var member = state.staff[staffIndex]
        let result = Locomotion.advance(position: &member.position,
                                        tile: &member.tile,
                                        route: &member.route,
                                        speed: member.effectiveWalkSpeed,
                                        dt: dt,
                                        map: map)
        state.staff[staffIndex] = member

        switch result {
        case .moving:
            break
        case .arrived:
            startWork(staffIndex: staffIndex, job: job, state: state)
        case .blocked:
            state.staff[staffIndex].activity = .idle
            state.staff[staffIndex].nextJobSearchAt = now
        }
    }

    // MARK: - By train

    private func travelByTrain(staffIndex: Int,
                               job: StaffJob,
                               state: GameState,
                               map: ParkMap,
                               dt: Double,
                               now: Double) {
        guard var transfer = state.staff[staffIndex].transfer else { return }

        // The train has to be running to be caught. If it has stopped, or the
        // station has gone, the journey is off and they look for something
        // else.
        guard let station = state.attraction(id: transfer.stationID), station.isOperational else {
            abandonJourney(staffIndex: staffIndex, state: state, now: now)
            return
        }

        if !transfer.boarded {
            if !state.staff[staffIndex].route.isEmpty {
                var member = state.staff[staffIndex]
                let result = Locomotion.advance(position: &member.position,
                                                tile: &member.tile,
                                                route: &member.route,
                                                speed: member.effectiveWalkSpeed,
                                                dt: dt,
                                                map: map)
                state.staff[staffIndex] = member
                if case .blocked = result {
                    abandonJourney(staffIndex: staffIndex, state: state, now: now)
                }
                return
            }

            transfer.waiting -= dt
            if transfer.waiting <= 0 { transfer.boarded = true }
            state.staff[staffIndex].transfer = transfer
            return
        }

        transfer.riding -= dt
        guard transfer.riding <= 0 else {
            state.staff[staffIndex].transfer = transfer
            return
        }

        // Off the train, and on with the job.
        state.staff[staffIndex].tile = transfer.landing
        state.staff[staffIndex].position = transfer.landing.centre
        state.staff[staffIndex].transfer = nil
        state.staff[staffIndex].route = []

        let destinations = destinationTiles(for: job, state: state, map: map)
        if destinations.contains(transfer.landing) {
            startWork(staffIndex: staffIndex, job: job, state: state)
            return
        }

        let route = pathfinder.route(from: transfer.landing, to: destinations, in: map)
        if route.isEmpty {
            abandonJourney(staffIndex: staffIndex, state: state, now: now)
        } else {
            state.staff[staffIndex].route = route
        }
    }

    private func abandonJourney(staffIndex: Int, state: GameState, now: Double) {
        state.staff[staffIndex].transfer = nil
        state.staff[staffIndex].route = []
        state.staff[staffIndex].activity = .idle
        state.staff[staffIndex].nextJobSearchAt = now
    }

    // MARK: - Doing the work

    private func startWork(staffIndex: Int, job: StaffJob, state: GameState) {
        guard isStillNeeded(job: job, state: state) else {
            state.staff[staffIndex].activity = .idle
            return
        }

        switch job {
        case .repairRide(let id):
            // An impound takes longer to lift than a breakdown takes to fix:
            // there is paperwork as well as a spanner, and an impound nobody
            // sees because it cleared in twelve seconds teaches nothing.
            let work = state.attraction(id: id)?.isImpounded == true
                ? Balance.impoundRepairDuration
                : Balance.repairDuration
            state.staff[staffIndex].workTimer = work / state.staff[staffIndex].workRate
        case .inspectRide:
            state.staff[staffIndex].workTimer = Balance.inspectionDuration / state.staff[staffIndex].workRate
        case .entertain:
            state.staff[staffIndex].workTimer = 25
        case .patrol(let coord):
            // A post at the gate is held far longer than a spot out in the
            // park, which is what makes the gate the guard's home.
            let gate = state.map.entranceCoord
            let atGate = abs(coord.x - gate.x) <= Balance.securityGateRadius
                && abs(coord.y - gate.y) <= Balance.securityGateRadius
            state.staff[staffIndex].workTimer = atGate
                ? Balance.securityPostDuration
                : Balance.securityPatrolDuration
        case .serviceFacility(let id):
            state.staff[staffIndex].workTimer = 0
            beginCleaning(facilityID: id, state: state)
        case .goTo:
            state.staff[staffIndex].workTimer = Balance.staffPostHold
        case .cleanLitter, .escort:
            state.staff[staffIndex].workTimer = 0
        }

        state.staff[staffIndex].activity = .working(job)
    }

    /// Work can become pointless between being assigned and being reached.
    private func isStillNeeded(job: StaffJob, state: GameState) -> Bool {
        switch job {
        case .cleanLitter(let coord):
            return state.map.litter(at: coord) > 0
        case .serviceFacility(let id):
            return (state.facility(id: id)?.soiling ?? 0) > 0
        case .repairRide(let id):
            guard let ride = state.attraction(id: id) else { return false }
            return ride.isBroken || ride.isImpounded
        case .inspectRide(let id):
            return state.attraction(id: id)?.isInspectionOverdue == true
        case .entertain, .patrol, .goTo:
            return true
        case .escort(let id):
            return state.guest(id: id)?.isTroublemaker == true
        }
    }

    private func work(staffIndex: Int,
                      job: StaffJob,
                      state: GameState,
                      dt: Double,
                      now: Double) {
        switch job {
        case .cleanLitter(let coord):
            let remaining = state.map.removeLitter(
                Balance.litterCleanRate * state.staff[staffIndex].workRate * dt, at: coord)
            if remaining <= 0 {
                state.statistics.litterCleanedTotal += 1
                finish(staffIndex: staffIndex, state: state, now: now)
            }

        case .serviceFacility(let id):
            guard let facilityIndex = state.facilityIndex(id: id) else {
                finish(staffIndex: staffIndex, state: state, now: now)
                return
            }
            if (state.facilities[facilityIndex].definition?.cleaningMinutes ?? 0) > 0 {
                cleanRestroom(staffIndex: staffIndex,
                              facilityIndex: facilityIndex,
                              state: state,
                              dt: dt,
                              now: now)
                return
            }
            state.facilities[facilityIndex].soiling = max(
                0, state.facilities[facilityIndex].soiling
                    - Balance.facilityCleanRate * state.staff[staffIndex].workRate * dt)
            if state.facilities[facilityIndex].soiling <= 0 {
                state.facilities[facilityIndex].timesServiced += 1
                finish(staffIndex: staffIndex, state: state, now: now)
            }

        case .repairRide(let id):
            state.staff[staffIndex].workTimer -= dt
            guard state.staff[staffIndex].workTimer <= 0 else { return }
            if let attractionIndex = state.attractionIndex(id: id) {
                MaintenanceSystem.completeRepair(attractionIndex: attractionIndex, state: state)
            }
            finish(staffIndex: staffIndex, state: state, now: now)

        case .inspectRide(let id):
            state.staff[staffIndex].workTimer -= dt
            guard state.staff[staffIndex].workTimer <= 0 else { return }
            if let attractionIndex = state.attractionIndex(id: id) {
                MaintenanceSystem.completeInspection(attractionIndex: attractionIndex, state: state)
            }
            finish(staffIndex: staffIndex, state: state, now: now)

        case .entertain:
            state.staff[staffIndex].workTimer -= dt
            perform(staffIndex: staffIndex, state: state, dt: dt, now: now)
            if state.staff[staffIndex].workTimer <= 0 {
                finish(staffIndex: staffIndex, state: state, now: now)
            }

        case .patrol:
            state.staff[staffIndex].workTimer -= dt
            reassureNearbyGuests(staffIndex: staffIndex, state: state, dt: dt)
            // A post is abandoned the moment somebody needs seeing off, but
            // not before security have clocked them. A guard who waits out the
            // remaining fifty seconds of a shift while a bin goes over behind
            // them does not look like security, it looks like scenery.
            let wanted = state.troublemakerIndex.map {
                TroublemakerSystem.isNoticed(state.guests[$0], at: now)
            } ?? false
            if state.staff[staffIndex].workTimer <= 0 || wanted {
                finish(staffIndex: staffIndex, state: state, now: now)
            }

        case .goTo:
            // Holding the spot they were sent to, until they have been there
            // long enough to be left to choose their own work again.
            state.staff[staffIndex].workTimer -= dt
            if state.staff[staffIndex].workTimer <= 0 {
                finish(staffIndex: staffIndex, state: state, now: now)
            }

        case .escort(let id):
            // Only reached when the guard was already standing on them.
            guard let guestIndex = state.guestIndex(id: id),
                  state.guests[guestIndex].isTroublemaker else {
                finish(staffIndex: staffIndex, state: state, now: now)
                return
            }
            TroublemakerSystem.remove(guestIndex: guestIndex,
                                      state: state,
                                      guardName: state.staff[staffIndex].name)
            finish(staffIndex: staffIndex, state: state, now: now)
        }
    }

    /// Security walking down somebody who is walking away.
    ///
    /// The route is re-planned on a timer rather than every tick: a route
    /// query per guard per tick would be the most expensive thing in the
    /// simulation, and a guard a second behind still catches somebody who
    /// walks slower than they do. The work timer is free while travelling, so
    /// it serves as the countdown rather than putting another field on every
    /// employee in every save.
    private func chase(staffIndex: Int,
                       guestID: UUID,
                       state: GameState,
                       map: ParkMap,
                       dt: Double,
                       now: Double) {
        guard let guestIndex = state.guestIndex(id: guestID),
              state.guests[guestIndex].isTroublemaker else {
            state.staff[staffIndex].route = []
            state.staff[staffIndex].activity = .idle
            state.staff[staffIndex].nextJobSearchAt = now
            return
        }

        // Close enough to have a word.
        if SimMath.distance(state.staff[staffIndex].position,
                            state.guests[guestIndex].position) <= Balance.escortCatchRadius {
            TroublemakerSystem.remove(guestIndex: guestIndex,
                                      state: state,
                                      guardName: state.staff[staffIndex].name)
            finish(staffIndex: staffIndex, state: state, now: now)
            return
        }

        state.staff[staffIndex].workTimer -= dt
        if state.staff[staffIndex].workTimer <= 0 || state.staff[staffIndex].route.isEmpty {
            state.staff[staffIndex].workTimer = Balance.escortRepathInterval
            let route = pathfinder.route(from: state.staff[staffIndex].tile,
                                         to: [state.guests[guestIndex].tile],
                                         in: map)
            guard !route.isEmpty else {
                // Nowhere to walk to. Give it up rather than stand there.
                state.staff[staffIndex].activity = .idle
                state.staff[staffIndex].nextJobSearchAt = now + Balance.staffJobSearchInterval
                return
            }
            state.staff[staffIndex].route = route
        }

        var member = state.staff[staffIndex]
        let result = Locomotion.advance(position: &member.position,
                                        tile: &member.tile,
                                        route: &member.route,
                                        speed: member.effectiveWalkSpeed,
                                        dt: dt,
                                        map: map)
        state.staff[staffIndex] = member

        // Arriving where they used to be, and being blocked, mean the same
        // thing here: plan again next tick.
        switch result {
        case .moving:
            break
        case .arrived, .blocked:
            state.staff[staffIndex].route = []
            state.staff[staffIndex].workTimer = 0
        }
    }

    private static let balloonColours: [ParkColour] = [
        .red, .yellow, .green, .blue, .pink, .orange, .violet
    ]

    /// Everything an entertainer or a mascot does while performing: lift the
    /// mood of whoever is in range, and whatever else the act adds to that.
    ///
    /// Children are worth more to a mascot, a queue is worth more to a mime,
    /// a balloon artist hands out balloons and a magician now and then leaves
    /// somebody amazed. All of it is read off the performer's profile, so a
    /// new act is a new row of numbers rather than a new branch here.
    private func perform(staffIndex: Int, state: GameState, dt: Double, now: Double) {
        let member = state.staff[staffIndex]
        let profile = PerformerProfile.of(member)
        let base = Balance.entertainerHappinessPerSecond * profile.happinessFactor
            * member.workRate * dt

        var audience: [Int] = []
        for index in state.guests.indices where state.guests[index].isActive {
            let distance = SimMath.distance(state.guests[index].position, member.position)
            guard distance <= profile.radius else { continue }

            var lift = base
            if state.guests[index].ageCategory == .child { lift *= profile.childFactor }
            if case .queueing = state.guests[index].activity { lift *= profile.queueFactor }
            state.guests[index].adjustHappiness(lift)
            audience.append(index)
        }
        guard !audience.isEmpty else { return }

        if profile.handsOutBalloons,
           state.rng.chance(Balance.balloonHandoutPerSecond * member.workRate * dt) {
            handOutBalloon(among: audience, state: state, now: now)
        }
        if profile.doesTricks, state.rng.chance(dt / Balance.magicTrickInterval) {
            amaze(among: audience, state: state, now: now)
        }
    }

    /// A balloon for somebody who has not got one, a child if there is one.
    private func handOutBalloon(among audience: [Int], state: GameState, now: Double) {
        let without = audience.filter { state.guests[$0].balloon == nil }
        guard !without.isEmpty else { return }
        let children = without.filter { state.guests[$0].ageCategory == .child }
        let pool = children.isEmpty ? without : children

        let guest = pool[state.rng.int(0...(pool.count - 1))]
        let colours = Self.balloonColours
        state.guests[guest].balloon = colours[state.rng.int(0...(colours.count - 1))]
        state.guests[guest].adjustHappiness(Balance.balloonHappiness)
        state.guests[guest].think("A balloon! For me?", mood: .positive, at: now)
    }

    private func amaze(among audience: [Int], state: GameState, now: Double) {
        let guest = audience[state.rng.int(0...(audience.count - 1))]
        state.guests[guest].adjustHappiness(Balance.magicTrickHappiness)
        state.guests[guest].think("How did they do that?!", mood: .positive, at: now)
    }

    /// Where the people are: the best of a few places picked at random, so a
    /// mascot spends its time where there is somebody to wave at.
    private func crowdedSpot(map: ParkMap, field: [Int], state: GameState) -> GridCoord? {
        var best: GridCoord?
        var bestCount = 0
        for _ in 0..<Balance.mascotSpotSamples {
            guard let coord = randomReachableTile(map: map, field: field, state: state) else { continue }
            var nearby = 0
            for guest in state.guests where guest.isActive
                && SimMath.distance(guest.position, coord.centre) <= Balance.entertainerRadius {
                nearby += 1
            }
            if nearby > bestCount {
                bestCount = nearby
                best = coord
            }
        }
        return best
    }

    /// A guard on a post makes the people around them feel looked after. A
    /// smaller lift than an entertainer's, over a wider circle: nobody comes
    /// to a park for the security, but they notice when there is none.
    private func reassureNearbyGuests(staffIndex: Int, state: GameState, dt: Double) {
        let centre = state.staff[staffIndex].position
        let radius = Balance.securityRadius
        let boost = Balance.securityHappinessPerSecond * dt

        for index in state.guests.indices where state.guests[index].isActive {
            guard SimMath.distance(state.guests[index].position, centre) <= radius else { continue }
            state.guests[index].adjustHappiness(boost)
        }
    }

    private func finish(staffIndex: Int, state: GameState, now: Double) {
        state.staff[staffIndex].tasksCompleted += 1
        state.staff[staffIndex].activity = .idle
        state.staff[staffIndex].workTimer = 0
        state.staff[staffIndex].nextJobSearchAt = now
    }
}
