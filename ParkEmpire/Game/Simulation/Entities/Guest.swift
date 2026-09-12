import CoreGraphics
import Foundation

/// Anything a guest can decide to walk towards.
enum ParkTarget: Codable, Equatable, Hashable {
    case attraction(UUID)
    case facility(UUID)
    case exit
    case wanderSpot(GridCoord)
}

enum GuestActivity: Codable, Equatable {
    /// Walking in from the entrance before the first decision.
    case arriving
    /// Walking somewhere with no particular goal.
    case exploring
    case walking(ParkTarget)
    case queueing(ParkTarget)
    /// Riding, being served, or sitting.
    case engaged(ParkTarget)
    case departed
}

enum AgeCategory: String, Codable, CaseIterable {
    case child
    case adult
    case senior

    var displayName: String {
        switch self {
        case .child: return "Child"
        case .adult: return "Adult"
        case .senior: return "Senior"
        }
    }
}

enum ThoughtMood: String, Codable {
    case positive
    case neutral
    case negative
}

struct GuestThought: Codable, Equatable, Identifiable {
    var id = UUID()
    var text: String
    var mood: ThoughtMood
    /// Sim time the thought occurred, used to age thoughts out of the panel.
    var simTime: Double
    /// What the thought is about, so it can be shown as a bubble over the
    /// guest without words.
    var icon: ThoughtIcon = .general
}

extension GuestThought {
    /// Lenient decoding so thoughts saved before bubbles existed still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        text = container.value(.text, or: "")
        mood = container.value(.mood, or: .neutral)
        simTime = container.value(.simTime, or: 0)
        icon = container.value(.icon, or: .general)
    }
}

/// Randomised traits that make two guests in identical circumstances behave
/// differently. All values are 0-100.
struct GuestPersonality: Codable {
    var thrillPreference: Double
    var patience: Double
    var spending: Double
    var cleanlinessSensitivity: Double

    static func random(for age: AgeCategory, using generator: inout SeededGenerator) -> GuestPersonality {
        let thrillCentre: Double
        switch age {
        case .child: thrillCentre = 45
        case .adult: thrillCentre = 60
        case .senior: thrillCentre = 30
        }
        return GuestPersonality(
            thrillPreference: SimMath.clamp(generator.double(thrillCentre - 35...thrillCentre + 35)),
            patience: generator.double(10...95),
            spending: generator.double(15...95),
            cleanlinessSensitivity: generator.double(10...95)
        )
    }
}

/// One visitor. Guests are value types held in a flat array on `GameState`;
/// systems mutate them in place, which keeps iteration cache-friendly.
struct Guest: Codable, Identifiable {
    let id: UUID
    var name: String
    var ageCategory: AgeCategory
    var personality: GuestPersonality
    var appearance: GuestAppearance = .unknown
    /// A visitor with an audience. They ride something, post about it, and
    /// the park sees a rush of arrivals off the back of it.
    var isInfluencer: Bool = false
    /// Set once they have posted, so one visit is one post.
    var hasPosted: Bool = false

    // Money
    var cash: Double
    var moneySpent: Double = 0

    // Needs. 100 always means "most urgent" for hunger, thirst, bathroom and
    // nausea; energy and happiness read the other way round (100 is good).
    var happiness: Double
    var hunger: Double
    var thirst: Double
    var energy: Double
    var bathroomNeed: Double
    var nausea: Double = 0

    // Position and movement, in tile-space (1 unit == 1 tile).
    var position: CGPoint
    var tile: GridCoord
    var route: [GridCoord] = []
    var walkSpeed: Double

    // Behaviour
    var activity: GuestActivity = .arriving
    var nextDecisionAt: Double = 0
    var queueJoinedAt: Double = 0
    var queueWaitEstimate: Double = 0
    var queueSlot: Int = 0
    /// Rides taken recently, so a guest does not loop on one attraction.
    var recentAttractions: [UUID] = []

    // Statistics
    var timeInPark: Double = 0
    var plannedVisitLength: Double
    var ridesRidden: Int = 0
    var purchases: Int = 0
    /// Pieces of rubbish the guest is holding. They look for a bin; the longer
    /// they carry it without finding one, the likelier they are to drop it.
    var carryingTrash: Int = 0
    var trashCarriedFor: Double = 0
    /// What they won at a carnival booth, if anything. Carried for the rest of
    /// the visit and drawn in their hand.
    var prize: GuestPrize?
    /// How many booths they have won at, so a guest who keeps winning stops
    /// being drawn under a pile of bears.
    var prizesWon: Int = 0
    var thoughts: [GuestThought] = []
    /// Set when the guest decides to go home; recorded on departure.
    var departureReason: String?

    var isActive: Bool {
        if case .departed = activity { return false }
        return true
    }

    /// Adds a thought, keeping only the most recent handful.
    mutating func think(_ text: String,
                        mood: ThoughtMood,
                        at simTime: Double,
                        icon: ThoughtIcon = .general) {
        // Avoid repeating the same thought back-to-back.
        if thoughts.last?.text == text { return }
        thoughts.append(GuestThought(text: text, mood: mood, simTime: simTime, icon: icon))
        if thoughts.count > 8 {
            thoughts.removeFirst(thoughts.count - 8)
        }
    }

    mutating func adjustHappiness(_ delta: Double) {
        happiness = SimMath.clamp(happiness + delta)
    }
}

extension Guest {
    /// Lenient decoding so saves written before litter existed still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        name = container.value(.name, or: "Guest")
        ageCategory = container.value(.ageCategory, or: .adult)
        appearance = container.value(.appearance, or: .unknown)
        isInfluencer = container.value(.isInfluencer, or: false)
        hasPosted = container.value(.hasPosted, or: false)
        personality = container.value(.personality,
                                      or: GuestPersonality(thrillPreference: 50,
                                                           patience: 50,
                                                           spending: 50,
                                                           cleanlinessSensitivity: 50))
        cash = container.value(.cash, or: 0)
        moneySpent = container.value(.moneySpent, or: 0)
        happiness = container.value(.happiness, or: 70)
        hunger = container.value(.hunger, or: 0)
        thirst = container.value(.thirst, or: 0)
        energy = container.value(.energy, or: 100)
        bathroomNeed = container.value(.bathroomNeed, or: 0)
        nausea = container.value(.nausea, or: 0)
        position = container.value(.position, or: .zero)
        tile = container.value(.tile, or: GridCoord.zero)
        route = container.value(.route, or: [])
        walkSpeed = container.value(.walkSpeed, or: Balance.guestWalkSpeed)
        activity = container.value(.activity, or: .exploring)
        nextDecisionAt = container.value(.nextDecisionAt, or: 0)
        queueJoinedAt = container.value(.queueJoinedAt, or: 0)
        queueWaitEstimate = container.value(.queueWaitEstimate, or: 0)
        queueSlot = container.value(.queueSlot, or: 0)
        recentAttractions = container.value(.recentAttractions, or: [])
        timeInPark = container.value(.timeInPark, or: 0)
        plannedVisitLength = container.value(.plannedVisitLength, or: Balance.visitLengthBase)
        ridesRidden = container.value(.ridesRidden, or: 0)
        purchases = container.value(.purchases, or: 0)
        carryingTrash = container.value(.carryingTrash, or: 0)
        trashCarriedFor = container.value(.trashCarriedFor, or: 0)
        prize = container.optionalValue(.prize)
        prizesWon = container.value(.prizesWon, or: 0)
        thoughts = container.value(.thoughts, or: [])
        departureReason = container.optionalValue(.departureReason)
    }
}
