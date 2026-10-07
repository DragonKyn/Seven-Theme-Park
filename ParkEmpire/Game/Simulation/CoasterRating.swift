import Foundation

/// What a coaster the player built is worth, judged from the circuit itself.
///
/// This used to be two numbers: how many tiles of track, and the sum of what
/// the elements on it were worth. That made the best coaster the one with the
/// most of everything, and the cheapest way to build it was to lay a long
/// line, drop five of the same loop on it, and never close the circuit. The
/// rating here is what makes a coaster a design problem rather than a
/// shopping list:
///
///  - a circuit that does not close is a shuttle, and rides as one;
///  - a second copy of an element is worth less than the first, and a
///    different element is worth more than a copy;
///  - elements packed shoulder to shoulder have no straight track between
///    them to be thrilling against;
///  - the harder the elements throw the train about, the sicker the riders
///    and the faster the ride wears out;
///  - a bigger coaster costs more to run.
///
/// Pure arithmetic over facts about the circuit, so it can be worked out
/// whenever the map changes and shown to the player as it stands.
struct CoasterRating: Codable, Equatable {
    var length: Int = 0
    var isLoop: Bool = false
    var elementCount: Int = 0
    var kindCount: Int = 0
    /// What the elements are worth once repeats, variety and crowding have
    /// been allowed for.
    var thrill: Double = 0
    /// How hard the elements throw a train about, 0-100.
    var intensity: Double = 0
    var isCrowded: Bool = false

    // MARK: - Judging a circuit

    /// `elements` is one entry per element placed on the circuit, so two loops
    /// are two entries.
    static func rate(length: Int, isLoop: Bool, elements: [CoasterElementDefinition]) -> CoasterRating {
        let grouped = Dictionary(grouping: elements, by: \.id)

        var thrill = 0.0
        var pull = 0.0
        for copies in grouped.values {
            guard let first = copies.first else { continue }
            var weight = 1.0
            for _ in copies {
                thrill += first.thrill * weight
                pull += Double(first.intensity - 1) * Balance.coasterIntensityScale * weight
                weight *= Balance.coasterRepeatDecay
            }
        }

        let kinds = grouped.count
        thrill += Double(min(max(0, kinds - 1), Balance.coasterVarietyKinds)) * Balance.coasterVarietyBonus

        let covered = elements.reduce(0) { $0 + $1.footprint.tileCount }
        let crowded = length > 0
            && Double(covered) / Double(length) > Balance.coasterCrowdingLimit
        if crowded { thrill *= Balance.coasterCrowdingFactor }

        return CoasterRating(length: length,
                             isLoop: isLoop,
                             elementCount: elements.count,
                             kindCount: kinds,
                             thrill: thrill,
                             intensity: SimMath.clamp(pull, 0, 100),
                             isCrowded: crowded)
    }

    // MARK: - What it does to the ride

    /// Added to the station's own excitement.
    var excitementBonus: Double {
        let score = min(30, Double(length) * 0.7) + min(35, thrill)
        return isLoop ? score : score * Balance.coasterOpenLineFactor
    }

    /// Added to the station's own nausea.
    var nauseaBonus: Double {
        min(Balance.coasterNauseaCeiling, intensity * 0.45 + Double(length) * 0.15)
    }

    /// Multiplies how fast the ride wears.
    var wearFactor: Double { 1 + intensity / 200 }

    /// Added to what each run costs. A long coaster takes more to move.
    var runningCost: Double { Double(length) * 0.35 }

    /// Added to how long a run lasts.
    var duration: Double { min(150, Double(length) * 1.6) }

    // MARK: - Telling the player

    /// What is holding the coaster back, most important first. Never empty:
    /// a circuit with nothing to say for it gets told so.
    var advice: [String] {
        var notes: [String] = []
        if length < Balance.coasterShortLength {
            notes.append("Short track: a ride this short is over before it starts. Aim for \(Balance.coasterShortLength) tiles or more.")
        }
        if !isLoop {
            notes.append("The circuit is not closed, so the train shuttles up and down it. Join the ends up for a full-strength ride.")
        }
        if elementCount == 0 {
            notes.append("No elements yet. A loop or a run of hills lifts a coaster a long way.")
        } else if kindCount == 1 && elementCount > 1 {
            notes.append("Every element is the same kind. A different one is worth more than another copy.")
        }
        if isCrowded {
            notes.append("The elements are crammed together. Leave straight track between them.")
        }
        if intensity > Balance.coasterIntenseThreshold {
            notes.append("Very intense: riders will come off queasy and the ride will wear faster.")
        }
        if notes.isEmpty {
            notes.append("Well balanced. A longer circuit or a new kind of element is the way up from here.")
        }
        return notes
    }
}
