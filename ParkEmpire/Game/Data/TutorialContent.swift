import Foundation

/// One thing the game explains, once.
///
/// A tip is data: a line of advice and the situation that makes it worth
/// reading. Adding one is a new entry in the catalogue below and nothing else,
/// which is the same bargain the rides and the shops get.
struct TutorialTip: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let symbolName: String
    /// Shown first when several are eligible at once. Anything that is
    /// costing the player money outranks anything that is merely useful.
    let priority: Int
    /// When this tip is worth showing.
    let condition: (TutorialSignals) -> Bool

    static func == (lhs: TutorialTip, rhs: TutorialTip) -> Bool { lhs.id == rhs.id }
}

/// What the park looks like right now, flattened into the handful of numbers
/// the tips actually ask about.
///
/// Tips read this rather than `GameState` so a condition cannot accidentally
/// be expensive: this is built once per interface refresh, and every condition
/// is then a comparison.
struct TutorialSignals {
    var day = 1
    var minutesPlayed: Double = 0
    var guestCount = 0
    var cash: Double = 0
    var averageHappiness: Double = 100
    var rideCount = 0
    var shopCount = 0
    var boothCount = 0
    var benchCount = 0
    var hasRestroom = false
    var hasBin = false
    var staffCount = 0
    var mechanicCount = 0
    var janitorCount = 0
    var litteredTiles = 0
    var brokenRides = 0
    var longestQueue = 0
    var isBuilding = false
    var isPlacing = false
    var isFreeBuild = false
}

enum TutorialContent {

    /// In rough order of when a new player meets them. Priority, not order,
    /// decides what is shown when two apply at once.
    static let all: [TutorialTip] = [
        TutorialTip(
            id: "tip.welcome",
            title: "Welcome to your lot",
            message: "You have an empty field, a gate, and some money. Tap Build to lay a walkway out from the entrance, then put something at the end of it worth walking to.",
            symbolName: "hand.wave.fill",
            priority: 100,
            condition: { _ in true }
        ),
        TutorialTip(
            id: "tip.paths",
            title: "Guests only walk on walkways",
            message: "Everything you build has to touch one. Pick Paths, turn on the drag toggle, and draw a route; rides and shops go beside it, not on it.",
            symbolName: "square.grid.3x3",
            priority: 90,
            condition: { $0.isBuilding }
        ),
        TutorialTip(
            id: "tip.placing",
            title: "Line it up before you pay",
            message: "Nothing is bought until you confirm it. Drag it around the map with one finger, nudge it a tile at a time with the arrows, turn it until it faces the way you want, then tap Build it.",
            symbolName: "rotate.right.fill",
            priority: 95,
            condition: { $0.isPlacing }
        ),
        TutorialTip(
            id: "tip.firstride",
            title: "Give them something to ride",
            message: "Guests are arriving to an empty park and will leave again. Open Build, choose Rides, and put a gentle one near the gate where everybody walks past it.",
            symbolName: "sparkles",
            priority: 88,
            condition: { $0.guestCount >= 3 && $0.rideCount == 0 }
        ),
        TutorialTip(
            id: "tip.inspect",
            title: "Tap anything to inspect it",
            message: "A ride shows its queue, its takings and its upgrades. A guest shows what they want and what they are thinking, which is usually how you find out what your park is missing.",
            symbolName: "hand.tap.fill",
            priority: 80,
            condition: { $0.rideCount >= 1 && $0.guestCount >= 5 }
        ),
        TutorialTip(
            id: "tip.food",
            title: "Hungry guests spend money",
            message: "Food and drink stalls are the steadiest income in the park, and a guest who cannot find one goes home early. Build one where the queues are.",
            symbolName: "fork.knife",
            priority: 78,
            condition: { $0.guestCount >= 8 && $0.shopCount == 0 }
        ),
        TutorialTip(
            id: "tip.restroom",
            title: "They will need a restroom",
            message: "Nothing empties a park faster than nowhere to go. Restrooms earn nothing directly and pay for themselves in guests who stay all day.",
            symbolName: "figure.stand",
            priority: 85,
            condition: { $0.guestCount >= 10 && !$0.hasRestroom }
        ),
        TutorialTip(
            id: "tip.staff",
            title: "Hire somebody",
            message: "Open Staff to take somebody on. Janitors sweep litter and clean restrooms, mechanics fix rides before they break, entertainers lift the mood of a queue, and security keep an eye on the gate.",
            symbolName: "person.2.badge.gearshape.fill",
            priority: 84,
            condition: { $0.guestCount >= 12 && $0.staffCount == 0 }
        ),
        TutorialTip(
            id: "tip.litter",
            title: "The park is getting dirty",
            message: "Guests drop rubbish when there is no bin to hand, and litter drags your rating down. Bins go straight on the walkway; a janitor deals with the rest.",
            symbolName: "trash.fill",
            priority: 82,
            condition: { $0.litteredTiles >= 4 && $0.janitorCount == 0 }
        ),
        TutorialTip(
            id: "tip.breakdown",
            title: "A ride has broken down",
            message: "It earns nothing until somebody fixes it. Hire a mechanic and they will inspect rides on their own, which is what stops the next breakdown.",
            symbolName: "wrench.and.screwdriver.fill",
            priority: 92,
            condition: { $0.brokenRides >= 1 }
        ),
        TutorialTip(
            id: "tip.queues",
            title: "That queue is getting long",
            message: "Guests give up when they have waited longer than they think it is worth. Upgrade the ride's capacity from its panel, or build a second thing to do nearby.",
            symbolName: "clock.fill",
            priority: 76,
            condition: { $0.longestQueue >= 9 }
        ),
        TutorialTip(
            id: "tip.money",
            title: "Money is getting tight",
            message: "Wages and upkeep run whether the park is busy or not. Check Money for where it is going, and remember you get most of a building's cost back if you remove it.",
            symbolName: "dollarsign.circle.fill",
            priority: 94,
            condition: { !$0.isFreeBuild && $0.cash < 1_200 }
        ),
        TutorialTip(
            id: "tip.admission",
            title: "What to charge at the gate",
            message: "Park Settings sets the admission price. Guests weigh it against how much there is to do, so raise it after you add rides rather than before, and watch arrivals when you do.",
            symbolName: "ticket.fill",
            priority: 70,
            condition: { $0.day >= 2 }
        ),
        TutorialTip(
            id: "tip.unhappy",
            title: "Your guests are unhappy",
            message: "Tap a miserable one and read their thoughts. They will tell you whether it is the queues, the prices, the litter or the walk, and that is faster than guessing.",
            symbolName: "face.dashed",
            priority: 86,
            condition: { $0.guestCount >= 10 && $0.averageHappiness < 45 }
        ),
        TutorialTip(
            id: "tip.booths",
            title: "Carnival booths pull a crowd",
            message: "A booth is cheap, quick to play and the winners carry a prize round the park all day. The harder the game, the bigger the prize.",
            symbolName: "target",
            priority: 68,
            condition: { $0.rideCount >= 2 && $0.boothCount == 0 && $0.guestCount >= 10 }
        ),
        TutorialTip(
            id: "tip.coaster",
            title: "Build your own coaster",
            message: "Under Coasters you can lay your own track, drop a station on it, and bolt on loops, corkscrews and a jump. The train runs whatever you build, so a longer, wilder circuit is a better ride.",
            symbolName: "point.topleft.down.curvedto.point.bottomright.up",
            priority: 66,
            condition: { $0.rideCount >= 4 }
        ),
        TutorialTip(
            id: "tip.benches",
            title: "Somewhere to sit",
            message: "Benches go on the walkway. Tired guests sit down instead of going home, and a guest who feels sick will recover on one rather than leave in a bad mood.",
            symbolName: "chair.lounge.fill",
            priority: 64,
            condition: { $0.guestCount >= 14 && $0.benchCount == 0 }
        ),
        TutorialTip(
            id: "tip.saving",
            title: "Your park saves itself",
            message: "Progress is written to your slot as you play, and Menu has Save park if you want it now. Leaving through Save and exit always writes first.",
            symbolName: "externaldrive.fill",
            priority: 60,
            condition: { $0.day >= 2 && $0.minutesPlayed >= 6 }
        )
    ]
}
