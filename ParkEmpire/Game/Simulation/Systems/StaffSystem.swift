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

    init(pathfinder: PathfindingSystem) {
        self.pathfinder = pathfinder
    }

    func update(state: GameState, dt: Double) {
        chargeWages(state: state, dt: dt)
        guard !state.staff.isEmpty else { return }

        let map = state.map
        let now = state.clock.simTime
        var claimed = claimedJobs(state: state)

        for index in state.staff.indices {
            switch state.staff[index].activity {
            case .idle:
                guard now >= state.staff[index].nextJobSearchAt else { continue }
                state.staff[index].nextJobSearchAt = now + Balance.staffJobSearchInterval
                if let job = findJob(staffIndex: index, state: state, map: map, claimed: claimed),
                   beginTravel(to: job, staffIndex: index, state: state, map: map) {
                    claimed.insert(job)
                }

            case .travelling(let job):
                travel(staffIndex: index, job: job, state: state, map: map, dt: dt, now: now)

            case .working(let job):
                work(staffIndex: index, job: job, state: state, dt: dt, now: now)
            }
        }
    }

    // MARK: - Wages

    private func chargeWages(state: GameState, dt: Double) {
        guard !state.staff.isEmpty else { return }
        let perSecond = state.staff.reduce(0.0) { $0 + $1.wagePerSecond }
        state.ledger.spend(perSecond * dt, on: .wages)
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

        func distance(to coord: GridCoord) -> Int? {
            guard map.isWalkable(coord) else { return nil }
            let value = field[map.linearIndex(of: coord)]
            return value == PathfindingSystem.unreachable ? nil : value
        }

        func nearestAccess(_ rect: GridRect) -> Int? {
            map.accessTiles(for: rect).compactMap { distance(to: $0) }.min()
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

        case .entertainer:
            // Head for whichever queue is longest; failing that, wander.
            let busiest = state.attractions
                .filter { !$0.queue.isEmpty }
                .max(by: { $0.queue.count < $1.queue.count })

            if let busiest,
               let spot = map.accessTiles(for: busiest.rect).first(where: { distance(to: $0) != nil }) {
                let job = StaffJob.entertain(spot)
                if !claimed.contains(job) { return job }
            }

            if let spot = randomReachableTile(map: map, field: field, state: state) {
                return .entertain(spot)
            }
            return nil

        case .security:
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

        if destinations.contains(state.staff[staffIndex].tile) {
            state.staff[staffIndex].route = []
            startWork(staffIndex: staffIndex, job: job, state: state)
            return true
        }

        let route = pathfinder.route(from: state.staff[staffIndex].tile, to: destinations, in: map)
        guard !route.isEmpty else { return false }

        state.staff[staffIndex].route = route
        state.staff[staffIndex].activity = .travelling(job)
        return true
    }

    private func destinationTiles(for job: StaffJob, state: GameState, map: ParkMap) -> [GridCoord] {
        switch job {
        case .cleanLitter(let coord), .entertain(let coord), .patrol(let coord):
            return map.isWalkable(coord) ? [coord] : []
        case .serviceFacility(let id):
            guard let facility = state.facility(id: id) else { return [] }
            return map.accessTiles(for: facility.rect)
        case .repairRide(let id), .inspectRide(let id):
            guard let attraction = state.attraction(id: id) else { return [] }
            return map.accessTiles(for: attraction.rect)
        }
    }

    private func travel(staffIndex: Int,
                        job: StaffJob,
                        state: GameState,
                        map: ParkMap,
                        dt: Double,
                        now: Double) {
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

    // MARK: - Doing the work

    private func startWork(staffIndex: Int, job: StaffJob, state: GameState) {
        guard isStillNeeded(job: job, state: state) else {
            state.staff[staffIndex].activity = .idle
            return
        }

        switch job {
        case .repairRide:
            state.staff[staffIndex].workTimer = Balance.repairDuration / state.staff[staffIndex].workRate
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
        case .cleanLitter, .serviceFacility:
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
        case .entertain, .patrol:
            return true
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
            entertainNearbyGuests(staffIndex: staffIndex, state: state, dt: dt)
            if state.staff[staffIndex].workTimer <= 0 {
                finish(staffIndex: staffIndex, state: state, now: now)
            }

        case .patrol:
            state.staff[staffIndex].workTimer -= dt
            reassureNearbyGuests(staffIndex: staffIndex, state: state, dt: dt)
            if state.staff[staffIndex].workTimer <= 0 {
                finish(staffIndex: staffIndex, state: state, now: now)
            }
        }
    }

    private func entertainNearbyGuests(staffIndex: Int, state: GameState, dt: Double) {
        let centre = state.staff[staffIndex].position
        let radius = Balance.entertainerRadius
        let boost = Balance.entertainerHappinessPerSecond * state.staff[staffIndex].workRate * dt

        for index in state.guests.indices where state.guests[index].isActive {
            let distance = SimMath.distance(state.guests[index].position, centre)
            guard distance <= radius else { continue }
            state.guests[index].adjustHappiness(boost)
        }
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
