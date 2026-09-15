import Foundation

/// One thing a trial asks for. Every goal reads a number the park already
/// keeps, so a trial adds no bookkeeping of its own.
enum TrialGoal: Equatable {
    /// Guests inside the park at the same moment.
    case guestsInPark(Int)
    /// Guests through the gate since the park opened.
    case guestsAdmitted(Int)
    /// Park rating, 0-100.
    case parkRating(Double)
    /// Money in the bank.
    case cash(Double)
    /// Rides, transport and coaster stations of any kind.
    case rides(Int)
    /// Average guest happiness, 0-100.
    case happiness(Double)

    var target: Double {
        switch self {
        case .guestsInPark(let count), .guestsAdmitted(let count), .rides(let count):
            return Double(count)
        case .parkRating(let value), .cash(let value), .happiness(let value):
            return value
        }
    }

    func current(in state: GameState) -> Double {
        switch self {
        case .guestsInPark: return Double(state.guestCount)
        case .guestsAdmitted: return Double(state.statistics.guestsAdmittedTotal)
        case .parkRating: return state.parkRating
        case .cash: return state.ledger.cash
        case .rides: return Double(state.attractions.count)
        case .happiness: return state.averageHappiness
        }
    }

    func isMet(in state: GameState) -> Bool {
        current(in: state) >= target
    }

    /// What the goal asks for, in a line.
    var title: String {
        switch self {
        case .guestsInPark(let count): return "\(count) guests in the park at once"
        case .guestsAdmitted(let count): return "\(count) guests through the gate"
        case .parkRating(let value): return "Park rating of \(Int(value)) (\(Self.stars(for: value)) stars)"
        case .cash(let value): return "\(CurrencyFormatter.short(value)) in the bank"
        case .rides(let count): return "\(count) rides built"
        case .happiness(let value): return "Guests \(Int(value))% happy on average"
        }
    }

    /// A short label for a chip.
    var shortTitle: String {
        switch self {
        case .guestsInPark: return "In park"
        case .guestsAdmitted: return "Admitted"
        case .parkRating: return "Rating"
        case .cash: return "Bank"
        case .rides: return "Rides"
        case .happiness: return "Happy"
        }
    }

    var symbolName: String {
        switch self {
        case .guestsInPark: return "person.3.fill"
        case .guestsAdmitted: return "ticket.fill"
        case .parkRating: return "star.fill"
        case .cash: return "banknote.fill"
        case .rides: return "sparkles"
        case .happiness: return "face.smiling"
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .cash: return CurrencyFormatter.compact(value)
        case .happiness: return "\(Int(value))%"
        default: return "\(Int(value))"
        }
    }

    /// Mirrors `GameState.starRating`.
    private static func stars(for rating: Double) -> Int {
        switch rating {
        case ..<20: return 1
        case ..<40: return 2
        case ..<60: return 3
        case ..<80: return 4
        default: return 5
        }
    }
}

/// What finishing a trial earns.
struct TrialMedal: Equatable {
    let name: String
    let symbolName: String
}

/// One rung of the ladder.
struct TrialDefinition: Identifiable, Equatable {
    let id: String
    /// Position on the ladder, from 1.
    let number: Int
    let title: String
    /// Two or three sentences setting the scene and saying what makes it hard.
    let briefing: String
    let mapID: String
    let startingCash: Double
    /// Every goal has to be met, all at once, by the end of this day.
    let dayLimit: Int
    let goals: [TrialGoal]
    /// The most the gate may charge, when the trial caps it.
    var maxAdmission: Double?
    let medal: TrialMedal

    var map: MapBlueprint {
        MapCatalogue.blueprint(id: mapID) ?? MapCatalogue.openMeadow
    }
}

/// The ladder.
///
/// Numbers here are a first pass at difficulty and the one place to retune
/// it. For scale: arrivals top out around eleven guests a park hour, a visit
/// lasts about ten park hours, so a busy park holds somewhere near a hundred
/// guests at once and admits a hundred and thirty a day.
enum TrialContent {

    static func definition(id: String) -> TrialDefinition? {
        all.first { $0.id == id }
    }

    static let all: [TrialDefinition] = [
        TrialDefinition(
            id: "trial.01",
            number: 1,
            title: "Opening Day",
            briefing: "An empty meadow and a gate. Get three rides running and a crowd through the door before the week is out.",
            mapID: MapCatalogue.openMeadowID,
            startingCash: 25_000,
            dayLimit: 5,
            goals: [.rides(3), .guestsInPark(30)],
            medal: TrialMedal(name: "Ribbon Cutter", symbolName: "scissors")),

        TrialDefinition(
            id: "trial.02",
            number: 2,
            title: "In the Black",
            briefing: "Less to start with, and the owners want their money back. Build cheaply, charge sensibly, and grow the balance.",
            mapID: MapCatalogue.openMeadowID,
            startingCash: 20_000,
            dayLimit: 7,
            goals: [.cash(30_000)],
            medal: TrialMedal(name: "Bookkeeper", symbolName: "banknote.fill")),

        TrialDefinition(
            id: "trial.03",
            number: 3,
            title: "Three Stars in the Pines",
            briefing: "The land comes in clearings between the trees. Link them up and give guests a park worth three stars.",
            mapID: "map.pinewood",
            startingCash: 22_000,
            dayLimit: 8,
            goals: [.parkRating(40), .guestsAdmitted(150)],
            medal: TrialMedal(name: "Three-Star Host", symbolName: "star.circle.fill")),

        TrialDefinition(
            id: "trial.04",
            number: 4,
            title: "Island Hopping",
            briefing: "The best ground is out on the islands. Bridge the lake and fill them with rides.",
            mapID: "map.willowlake",
            startingCash: 25_000,
            dayLimit: 10,
            goals: [.rides(6), .guestsInPark(50)],
            medal: TrialMedal(name: "Bridge Builder", symbolName: "water.waves")),

        TrialDefinition(
            id: "trial.05",
            number: 5,
            title: "The Long Pier",
            briefing: "Five tiles wide and a long walk to the end. Every square counts, and so does every step a guest takes.",
            mapID: "map.longpier",
            startingCash: 20_000,
            dayLimit: 10,
            goals: [.cash(35_000), .parkRating(45)],
            medal: TrialMedal(name: "Pier Master", symbolName: "sailboat.fill")),

        TrialDefinition(
            id: "trial.06",
            number: 6,
            title: "Shoestring",
            briefing: "Ten thousand and a river in the way. Keep costs down and keep the crowd happy while it grows.",
            mapID: "map.riverbend",
            startingCash: 10_000,
            dayLimit: 10,
            goals: [.guestsAdmitted(400), .happiness(65)],
            medal: TrialMedal(name: "Penny Pincher", symbolName: "dollarsign.circle.fill")),

        TrialDefinition(
            id: "trial.07",
            number: 7,
            title: "Canyon Run",
            briefing: "Sheer rock either side and a stream down the middle. Make the valley worth four stars.",
            mapID: "map.canyon",
            startingCash: 22_000,
            dayLimit: 12,
            goals: [.parkRating(60), .guestsInPark(60)],
            medal: TrialMedal(name: "Canyon Runner", symbolName: "mountain.2.fill")),

        TrialDefinition(
            id: "trial.08",
            number: 8,
            title: "Crowd Control",
            briefing: "Two plateaus and one narrow pass between them. Hold a big crowd without letting the queues sour it.",
            mapID: "map.twinplateaus",
            startingCash: 22_000,
            dayLimit: 12,
            goals: [.guestsInPark(80), .happiness(72)],
            medal: TrialMedal(name: "Crowd Tamer", symbolName: "person.3.fill")),

        TrialDefinition(
            id: "trial.09",
            number: 9,
            title: "Harbour Lights",
            briefing: "The council caps the gate at twenty dollars. The money has to come from inside the park.",
            mapID: "map.harbour",
            startingCash: 18_000,
            dayLimit: 14,
            goals: [.cash(60_000), .parkRating(65)],
            maxAdmission: 20,
            medal: TrialMedal(name: "Harbour Master", symbolName: "light.beacon.max.fill")),

        TrialDefinition(
            id: "trial.10",
            number: 10,
            title: "Wonder of the World",
            briefing: "A lake, a small budget and the bar only the best parks reach. Five stars, a full park and a fortune in the bank.",
            mapID: "map.willowlake",
            startingCash: 12_000,
            dayLimit: 18,
            goals: [.parkRating(80), .guestsInPark(90), .cash(80_000)],
            medal: TrialMedal(name: "Wonder Maker", symbolName: "crown.fill")),

        // The back five. Each asks for everything the one before it did and
        // takes something away as well: land, budget, the gate, or time.

        TrialDefinition(
            id: "trial.11",
            number: 11,
            title: "Archipelago",
            briefing: "The Wonder of the World again, only now the land is a scatter of islands. Every bridge comes out of the budget.",
            mapID: "map.archipelago",
            startingCash: 12_000,
            dayLimit: 18,
            goals: [.parkRating(80), .guestsInPark(90), .cash(90_000), .rides(8)],
            medal: TrialMedal(name: "Island Magnate", symbolName: "beach.umbrella.fill")),

        TrialDefinition(
            id: "trial.12",
            number: 12,
            title: "Pay What You Can",
            briefing: "The gate is capped at ten dollars, so the park has to earn its keep from food, shops and games. Keep people happy enough to spend.",
            mapID: "map.pinewood",
            startingCash: 10_000,
            dayLimit: 18,
            goals: [.cash(70_000), .parkRating(82), .happiness(75)],
            maxAdmission: 10,
            medal: TrialMedal(name: "Open Door", symbolName: "door.left.hand.open")),

        TrialDefinition(
            id: "trial.13",
            number: 13,
            title: "The Long Haul",
            briefing: "Back on the pier with less money and a far bigger crowd to move. Fifteen hundred people have to make that walk.",
            mapID: "map.longpier",
            startingCash: 10_000,
            dayLimit: 20,
            goals: [.guestsAdmitted(1_500), .parkRating(84), .cash(100_000)],
            medal: TrialMedal(name: "Marathon Maker", symbolName: "figure.walk")),

        TrialDefinition(
            id: "trial.14",
            number: 14,
            title: "Switchback",
            briefing: "One valley doubling back through solid rock, a capped gate and eight thousand to start. Pack the bends without souring the crowd.",
            mapID: "map.switchback",
            startingCash: 8_000,
            dayLimit: 20,
            goals: [.parkRating(86), .guestsInPark(92), .happiness(78), .cash(100_000)],
            maxAdmission: 25,
            medal: TrialMedal(name: "Ridge Runner", symbolName: "arrow.triangle.turn.up.right.diamond.fill")),

        TrialDefinition(
            id: "trial.15",
            number: 15,
            title: "The Grand Finale",
            briefing: "Everything at once, in a canyon, on six thousand dollars and a twenty dollar gate. The last rung, and the park that proves you have learned all fourteen before it.",
            mapID: "map.canyon",
            startingCash: 6_000,
            dayLimit: 24,
            goals: [.parkRating(88), .guestsInPark(95), .happiness(80), .cash(120_000), .rides(12)],
            maxAdmission: 20,
            medal: TrialMedal(name: "Legend of the Lot", symbolName: "trophy.fill"))
    ]
}
