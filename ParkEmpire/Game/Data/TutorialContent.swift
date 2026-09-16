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
    var securityCount = 0
    var sceneryCount = 0
    var impoundedRides = 0
    /// Shops and booths standing at nothing but their opening spec.
    var unimprovedShops = 0
    var isBuilding = false
    var isPlacing = false
    var isFreeBuild = false
    /// A trial has its own goals screen and its own save, so a handful of
    /// tips have nothing to say inside one.
    var isTrial = false
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
            message: "Everything you build has to touch one. Pick Paths, turn on Draw, and drag out a route; rides and shops go beside it, not on it.",
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
            message: "A ride shows its queue, its takings and what it can be improved with. A guest shows what they want and what they are thinking, which is usually how you find out what your park is missing.",
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
            message: "Coaster Builder is a box of parts rather than a shelf of rides. Lay your own track, put a station beside it, and bolt on loops, corkscrews and a jump. The train runs whatever you build, so a longer, wilder circuit is a better ride.",
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
            id: "tip.inspector",
            title: "An inspector has shut a ride",
            message: "It stays shut, and it cannot take anybody, until a mechanic has been out to it. Hire one if you have not, and expect the repair to take a while.",
            symbolName: "xmark.seal.fill",
            priority: 97,
            condition: { $0.impoundedRides > 0 }
        ),
        TutorialTip(
            id: "tip.shopupgrades",
            title: "Shops can be improved",
            message: "Tap a stall or a booth and look under Improvements. Another till moves the queue, better stock lets you charge more without complaints, and lit signage pulls people in from further down the path.",
            symbolName: "star.circle.fill",
            priority: 72,
            condition: { $0.unimprovedShops >= 1 && $0.day >= 2 && $0.cash >= 2_000 }
        ),
        TutorialTip(
            id: "tip.security",
            title: "Somebody to keep an eye on things",
            message: "A guard makes the crowd around them feel looked after, and they are the only ones who can see a troublemaker off the premises. Without one, a troublemaker has the run of the park all afternoon.",
            symbolName: "shield.lefthalf.filled",
            priority: 63,
            condition: { $0.guestCount >= 25 && $0.securityCount == 0 }
        ),
        TutorialTip(
            id: "tip.alerts",
            title: "The bell knows before you do",
            message: "Breakdowns, long queues, litter and empty tills all end up under the bell at the top. Tapping a notice takes you straight to whatever it is about.",
            symbolName: "bell.badge.fill",
            priority: 76,
            condition: { $0.brokenRides > 0 || $0.litteredTiles >= 10 }
        ),
        TutorialTip(
            id: "tip.scenery",
            title: "A park people want to look at",
            message: "Trees, flowers, lamps and fountains raise how pretty the ground around them is, and the rating counts it. Scenery in Build has several styles of each, and Park settings paints the benches and lamps in your own colours.",
            symbolName: "tree.fill",
            priority: 58,
            condition: { $0.rideCount >= 3 && $0.sceneryCount == 0 }
        ),
        TutorialTip(
            id: "tip.boosts",
            title: "A fifth gear, if you want it",
            message: "The greyed-out 5x on the speed control, and a busier gate, can each be switched on for ten minutes by watching a short advert. Nothing in the game needs them, and nothing will ever interrupt your park to ask.",
            symbolName: "hare.fill",
            priority: 52,
            condition: { $0.day >= 3 && $0.minutesPlayed >= 25 }
        ),
        TutorialTip(
            id: "tip.trials",
            title: "Fifteen parks against the clock",
            message: "Park Trials on the main menu is a ladder of parks built to a deadline on harder and harder land. Every one you beat earns a medal and a point to spend on a permanent bonus that applies to every park you build.",
            symbolName: "flag.checkered",
            priority: 50,
            condition: { !$0.isTrial && $0.day >= 4 && $0.rideCount >= 3 }
        ),
        TutorialTip(
            id: "tip.saving",
            title: "Your park saves itself",
            message: "Progress is written as you play. Menu has Save park if you want it now, and leaving through Menu asks first and saves before it goes.",
            symbolName: "externaldrive.fill",
            priority: 60,
            condition: { $0.day >= 2 && $0.minutesPlayed >= 6 }
        )
    ]
}
