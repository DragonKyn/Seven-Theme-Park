import Foundation

/// The holiday event's rides and decorations. Kept apart from the everyday
/// catalogue so the whole event can be read, balanced and switched off in one
/// place. A few are locked behind a trial reward; see `HolidayRewards`.
enum HolidayContent {

    static let attractions: [AttractionDefinition] = rides + [skatingRink]

    private static let rides: [AttractionDefinition] = [
        // Christmas
        AttractionDefinition(
            id: "ride.xmas.reindeercarousel",
            displayName: "Reindeer Carousel",
            summary: "Every horse has antlers, and every antler has a bell. A gentle one the whole family can share.",
            purchasePrice: 3_000,
            capacity: 14,
            rideDuration: 48,
            loadDuration: 12,
            excitement: 24,
            nausea: 5,
            maintenanceRate: 0.010,
            operatingCostPerCycle: 4,
            footprint: GridSize(3, 3),
            unlockLevel: 1,
            appearance: BuildingAppearance(.reindeerCarousel, .red, .cream, .green),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.xmas.sleighride",
            displayName: "Sleigh Ride",
            summary: "Round the hill in Santa's sleigh. Faster than it looks, and the bells never stop.",
            purchasePrice: 6_800,
            capacity: 12,
            rideDuration: 70,
            loadDuration: 16,
            excitement: 55,
            nausea: 28,
            maintenanceRate: 0.022,
            operatingCostPerCycle: 9,
            footprint: GridSize(5, 4),
            unlockLevel: 1,
            appearance: BuildingAppearance(.sleighRide, .red, .green, .amber),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.xmas.candycoaster",
            displayName: "Candy Cane Coaster",
            summary: "A coaster on candy-striped track with a lift hill that smells of peppermint. Earned in the Twelve Days.",
            purchasePrice: 16_500,
            capacity: 18,
            rideDuration: 95,
            loadDuration: 20,
            excitement: 84,
            nausea: 40,
            maintenanceRate: 0.036,
            operatingCostPerCycle: 19,
            footprint: GridSize(6, 4),
            unlockLevel: 1,
            appearance: BuildingAppearance(.candyCoaster, .red, .white, .green),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.xmas.snowglobe",
            displayName: "Snow Globe Spinner",
            summary: "Spin inside a glass dome while it snows on you. Pretty, and rougher on the stomach than it looks.",
            purchasePrice: 3_800,
            capacity: 12,
            rideDuration: 42,
            loadDuration: 12,
            excitement: 34,
            nausea: 50,
            maintenanceRate: 0.013,
            operatingCostPerCycle: 5,
            footprint: GridSize(3, 3),
            unlockLevel: 1,
            appearance: BuildingAppearance(.snowGlobe, .cyan, .white, .red),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.xmas.polarexpress",
            displayName: "North Pole Express",
            summary: "A little train round a tree the size of a house. Takes a crowd, and the crowd sings.",
            purchasePrice: 5_200,
            capacity: 24,
            rideDuration: 85,
            loadDuration: 18,
            excitement: 38,
            nausea: 8,
            maintenanceRate: 0.014,
            operatingCostPerCycle: 8,
            footprint: GridSize(4, 4),
            unlockLevel: 1,
            appearance: BuildingAppearance(.polarExpress, .red, .green, .amber),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.xmas.gingerbread",
            displayName: "Gingerbread Manor",
            summary: "A slow ride through a house made of cake, with icing on the roof and a witch in the kitchen.",
            purchasePrice: 7_800,
            capacity: 20,
            rideDuration: 90,
            loadDuration: 18,
            excitement: 46,
            nausea: 6,
            maintenanceRate: 0.015,
            operatingCostPerCycle: 9,
            footprint: GridSize(4, 4),
            unlockLevel: 1,
            appearance: BuildingAppearance(.gingerbreadManor, .brown, .white, .red),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.xmas.startopper",
            displayName: "Star Topper Drop",
            summary: "Up the tree, a pause beside the star, then all the way down. Earned in the Twelve Days.",
            purchasePrice: 8_800,
            capacity: 12,
            rideDuration: 50,
            loadDuration: 16,
            excitement: 80,
            nausea: 46,
            maintenanceRate: 0.033,
            operatingCostPerCycle: 13,
            footprint: GridSize(3, 3),
            unlockLevel: 1,
            appearance: BuildingAppearance(.starTopper, .green, .amber, .red),
            group: .holiday,
            seasonal: true
        ),

        // New Year's
        AttractionDefinition(
            id: "ride.newyear.countdownwheel",
            displayName: "Countdown Wheel",
            summary: "A big wheel with a clock at its heart. Every lap counts down to midnight.",
            purchasePrice: 7_000,
            capacity: 24,
            rideDuration: 100,
            loadDuration: 18,
            excitement: 30,
            nausea: 4,
            maintenanceRate: 0.012,
            operatingCostPerCycle: 10,
            footprint: GridSize(4, 4),
            unlockLevel: 1,
            appearance: BuildingAppearance(.countdownWheel, .indigo, .amber, .white),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.newyear.confettiswing",
            displayName: "Confetti Swing",
            summary: "Chairs fly out on chains and a cannon fires paper at every turn.",
            purchasePrice: 5_600,
            capacity: 16,
            rideDuration: 55,
            loadDuration: 14,
            excitement: 48,
            nausea: 36,
            maintenanceRate: 0.018,
            operatingCostPerCycle: 7,
            footprint: GridSize(3, 3),
            unlockLevel: 1,
            appearance: BuildingAppearance(.confettiSwing, .violet, .amber, .pink),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.newyear.balldrop",
            displayName: "Ball Drop Tower",
            summary: "Rise to the top with a glittering ball, wait for the count, and drop at midnight.",
            purchasePrice: 8_800,
            capacity: 12,
            rideDuration: 50,
            loadDuration: 16,
            excitement: 76,
            nausea: 48,
            maintenanceRate: 0.031,
            operatingCostPerCycle: 12,
            footprint: GridSize(3, 3),
            unlockLevel: 1,
            appearance: BuildingAppearance(.ballDrop, .indigo, .white, .amber),
            group: .holiday,
            seasonal: true
        ),
        AttractionDefinition(
            id: "ride.newyear.starburst",
            displayName: "Starburst Coaster",
            summary: "The finale: a coaster that ends every lap in a burst of sparks. Earned in the Twelve Days.",
            purchasePrice: 17_500,
            capacity: 18,
            rideDuration: 100,
            loadDuration: 20,
            excitement: 86,
            nausea: 44,
            maintenanceRate: 0.037,
            operatingCostPerCycle: 20,
            footprint: GridSize(6, 4),
            unlockLevel: 1,
            appearance: BuildingAppearance(.starburstCoaster, .indigo, .amber, .pink),
            group: .holiday,
            seasonal: true
        )
    ]

    /// The ice rink: a skating ride on the holiday shelf, with its skaters going round it.
    static let skatingRink = AttractionDefinition(
        id: "ride.xmas.skatingrink",
        displayName: "Skating Rink",
        summary: "A sheet of ice with a rail round it and a crowd going the same way. Gentle, cheap to run, and everybody wants a go.",
        purchasePrice: 4_200,
        capacity: 18,
        rideDuration: 75,
        loadDuration: 14,
        excitement: 36,
        nausea: 4,
        maintenanceRate: 0.008,
        operatingCostPerCycle: 5,
        footprint: GridSize(5, 4),
        unlockLevel: 1,
        appearance: BuildingAppearance(.skatingRink, .cyan, .white, .red),
        group: .holiday,
        seasonal: true
    )

    /// The two seasonal food venues. Both take the usual shop upgrades.
    static let facilities: [FacilityDefinition] = [
        FacilityDefinition(
            id: "shop.xmas.snowcone",
            displayName: "Snow Cone Cart",
            summary: "Shaved ice in a paper cone with a choice of syrups. Earned in the Twelve Days. Cold, cheap and very popular with children.",
            kind: .drink,
            purchasePrice: 700,
            defaultPrice: 3.5,
            unitCost: 0.7,
            referencePrice: 4,
            serviceDuration: 4,
            simultaneousCapacity: 1,
            queueCapacity: 8,
            relief: NeedRelief(hunger: 4, thirst: 42, bathroom: -10, happiness: 10),
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.snowConeCart, .cyan, .white, .pink),
            seasonal: true
        ),
        FacilityDefinition(
            id: "shop.xmas.hotcocoa",
            displayName: "Hot Chocolate Stand",
            summary: "A steaming cup with marshmallows on top. Cheap, quick, and guests come back for a second.",
            kind: .drink,
            purchasePrice: 1_100,
            defaultPrice: 3.5,
            unitCost: 1,
            referencePrice: 4.5,
            serviceDuration: 5,
            simultaneousCapacity: 1,
            queueCapacity: 10,
            relief: NeedRelief(hunger: 6, thirst: 60, bathroom: -16, happiness: 9),
            footprint: GridSize(2, 2),
            unlockLevel: 1,
            appearance: BuildingAppearance(.hotCocoaStand, .brown, .cream, .red),
            seasonal: true
        ),
        FacilityDefinition(
            id: "shop.xmas.candy",
            displayName: "Candy Stand",
            summary: "Candy canes, gumdrops and humbugs by the bag. A sweet tooth is a good customer.",
            kind: .food,
            purchasePrice: 1_000,
            defaultPrice: 3,
            unitCost: 0.9,
            referencePrice: 3.5,
            serviceDuration: 4,
            simultaneousCapacity: 1,
            queueCapacity: 10,
            relief: NeedRelief(hunger: 16, thirst: -6, bathroom: -4, happiness: 12),
            footprint: GridSize(2, 2),
            unlockLevel: 1,
            appearance: BuildingAppearance(.candyStand, .red, .white, .green),
            seasonal: true
        )
    ]

    static let scenery: [SceneryDefinition] = [
        SceneryDefinition(
            id: "scenery.xmas.canefence",
            displayName: "Candy Cane Fence",
            summary: "Crossed candy canes with a striped rail between them. A cheap way to edge a walkway or fence off a lawn.",
            purchasePrice: 60,
            beauty: 14,
            beautyRadius: 1,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.candyCaneFence, .red, .white, .green),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.xmas.lightstrand",
            displayName: "Holiday Lights",
            summary: "A twinkling strand of coloured bulbs between two stakes. Put them wherever the park needs cheering up.",
            purchasePrice: 70,
            beauty: 18,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.holidayLights, .green, .amber, .red),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.xmas.snowfamily",
            displayName: "Snow Family",
            summary: "A tall snowman, a short one and a very small one, in matching scarves. Earned in the Twelve Days.",
            purchasePrice: 240,
            beauty: 30,
            beautyRadius: 3,
            footprint: GridSize(2, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.snowFamily, .white, .red, .orange),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.xmas.tree",
            displayName: "Christmas Tree",
            summary: "A fir hung with baubles and topped with a star. Nothing says December like it.",
            purchasePrice: 120,
            beauty: 24,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.xmasTree, .green, .red, .amber),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.xmas.snowman",
            displayName: "Snowman",
            summary: "A carrot nose, a scarf and a very patient expression.",
            purchasePrice: 90,
            beauty: 20,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.snowman, .white, .red, .orange),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.xmas.wreath",
            displayName: "Wreath Arch",
            summary: "A garland arch over the walkway, with a red bow at the top.",
            purchasePrice: 260,
            beauty: 26,
            beautyRadius: 3,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.wreathArch, .green, .red, .amber),
            spansWalkway: true,
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.xmas.gifts",
            displayName: "Gift Stack",
            summary: "A tower of wrapped presents. Earned in the Twelve Days.",
            purchasePrice: 140,
            beauty: 24,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.giftStack, .red, .green, .amber),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.xmas.lights",
            displayName: "String-Light Pole",
            summary: "A tall pole with warm lights looped down it. Earned in the Twelve Days.",
            purchasePrice: 180,
            beauty: 26,
            beautyRadius: 3,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.lightPole, .brown, .amber, .red),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.xmas.candycane",
            displayName: "Candy Cane Post",
            summary: "A giant striped cane to mark a corner. Earned in the Twelve Days.",
            purchasePrice: 110,
            beauty: 22,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.candyCanePost, .red, .white, .green),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.newyear.fireworks",
            displayName: "Fireworks Stand",
            summary: "A rack of rockets that never quite goes off. Earned in the Twelve Days.",
            purchasePrice: 240,
            beauty: 30,
            beautyRadius: 3,
            footprint: GridSize(2, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.fireworkStand, .indigo, .amber, .pink),
            seasonal: true
        ),
        SceneryDefinition(
            id: "scenery.newyear.clock",
            displayName: "Countdown Clock",
            summary: "A tall clock counting down to midnight. Earned in the Twelve Days.",
            purchasePrice: 320,
            beauty: 34,
            beautyRadius: 3,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.countdownClock, .indigo, .amber, .white),
            seasonal: true
        )
    ]

    /// Whether the player may build this right now: the event is on, and any
    /// reward it needs is held.
    static func canBuild(_ definition: BuildableDefinition, season: Bool, store: HolidayStore) -> Bool {
        guard definition.seasonal else { return true }
        guard season else { return false }
        return store.canUse(definition.id)
    }

    /// Whether an act can be hired right now.
    static func canHire(_ act: EntertainerAct, season: Bool, store: HolidayStore) -> Bool {
        guard act.isSeasonal else { return true }
        guard season else { return false }
        guard let key = act.unlockKey else { return true }
        return store.canUse(key)
    }
}

/// The twelve days of the holiday event. All open from the first day, apart
/// from the few that use something an earlier one hands over. Nothing here
/// asks for an item the player might not have: a goal that needs a reward
/// names it in `needsRewardID`, and the trial stays shut until it is held.
extension TrialContent {
    static let holiday: [TrialDefinition] = [
        TrialDefinition(
            id: "holiday.01",
            number: 1,
            title: "A Partridge in a Pear Tree",
            briefing: "Deck the lot. Open two holiday rides and put up eight decorations before the week is out.",
            mapID: MapCatalogue.openMeadowID,
            startingCash: 18_000,
            dayLimit: 6,
            goals: [.holidayRides(2), .holidayScenery(8)],
            medal: TrialMedal(name: "Tree Trimmer", symbolName: "tree.fill"),
            series: .holiday,
            rewardIDs: ["reward.makeover.gentle"]),

        TrialDefinition(
            id: "holiday.02",
            number: 2,
            title: "Two Turtle Doves",
            briefing: "A cast for the season. Hire Santa Claus and an elf, train one of them up, and keep the crowd coming.",
            mapID: MapCatalogue.openMeadowID,
            startingCash: 18_000,
            dayLimit: 7,
            goals: [.holidayStaff(2), .trainedHolidayStaff(1), .guestsInPark(30)],
            medal: TrialMedal(name: "Cast Director", symbolName: "person.2.fill"),
            series: .holiday,
            rewardIDs: ["reward.giftstack"]),

        TrialDefinition(
            id: "holiday.03",
            number: 3,
            title: "Three French Hens",
            briefing: "Pine trees, snow and a crowd to keep warm. Three holiday rides and happy guests.",
            mapID: "map.pinewood",
            startingCash: 20_000,
            dayLimit: 8,
            goals: [.holidayRides(3), .guestsInPark(40), .happiness(65)],
            medal: TrialMedal(name: "Hen Keeper", symbolName: "snowflake"),
            series: .holiday,
            rewardIDs: ["reward.lightpole", "reward.snowcone"]),

        TrialDefinition(
            id: "holiday.04",
            number: 4,
            title: "Four Calling Birds",
            briefing: "The office parties are coming. Fill the park with rides, host a company holiday party and let them spend.",
            mapID: MapCatalogue.openMeadowID,
            startingCash: 20_000,
            dayLimit: 10,
            goals: [.holidayParties(1), .guestsAdmitted(150), .cash(25_000)],
            medal: TrialMedal(name: "Party Host", symbolName: "party.popper.fill"),
            series: .holiday,
            rewardIDs: ["reward.performer.missus"]),

        TrialDefinition(
            id: "holiday.05",
            number: 5,
            title: "Five Golden Rings",
            briefing: "A wheel for the new year. Build the Countdown Wheel, add holiday rides around it and earn three stars.",
            mapID: "map.willowlake",
            startingCash: 24_000,
            dayLimit: 10,
            goals: [.build("ride.newyear.countdownwheel", 1), .holidayRides(5), .parkRating(45)],
            medal: TrialMedal(name: "Ring Master", symbolName: "circle.dotted"),
            series: .holiday,
            rewardIDs: ["reward.makeover.water"]),

        TrialDefinition(
            id: "holiday.06",
            number: 6,
            title: "Six Geese a-Laying",
            briefing: "Stalls, games and prizes. Sell the season: four shops, thirty prizes won and twelve decorations up.",
            mapID: "map.pinewood",
            startingCash: 16_000,
            dayLimit: 9,
            goals: [.shops(4), .prizes(30), .holidayScenery(12)],
            medal: TrialMedal(name: "Goose Girl", symbolName: "gift.fill"),
            series: .holiday,
            rewardIDs: ["reward.ride.candycoaster", "reward.candycane"]),

        TrialDefinition(
            id: "holiday.07",
            number: 7,
            title: "Seven Swans a-Swimming",
            briefing: "Dress the old favourites for the season. Give two rides a holiday makeover and keep six rides running.",
            mapID: "map.willowlake",
            startingCash: 22_000,
            dayLimit: 10,
            goals: [.makeovers(2), .rides(6), .holidayRides(4)],
            medal: TrialMedal(name: "Swan Keeper", symbolName: "sparkles"),
            series: .holiday,
            rewardIDs: ["reward.makeover.family"],
            needsRewardID: "reward.makeover.gentle"),

        TrialDefinition(
            id: "holiday.08",
            number: 8,
            title: "Eight Maids a-Milking",
            briefing: "A big, cheerful crowd. Sixty guests in the park, seventy percent happy and six shops to serve them.",
            mapID: MapCatalogue.openMeadowID,
            startingCash: 20_000,
            dayLimit: 10,
            goals: [.guestsInPark(60), .happiness(70), .shops(6)],
            medal: TrialMedal(name: "Milkmaid", symbolName: "face.smiling"),
            series: .holiday,
            rewardIDs: ["reward.ride.startopper", "reward.snowfamily"]),

        TrialDefinition(
            id: "holiday.09",
            number: 9,
            title: "Nine Ladies Dancing",
            briefing: "The whole company on the payroll. Three holiday performers, two of them trained, among six staff.",
            mapID: "map.pinewood",
            startingCash: 22_000,
            dayLimit: 10,
            goals: [.holidayStaff(3), .trainedHolidayStaff(2), .staff(6), .parkRating(55)],
            medal: TrialMedal(name: "Stage Manager", symbolName: "theatermasks.fill"),
            series: .holiday,
            rewardIDs: ["reward.makeover.thrill"]),

        TrialDefinition(
            id: "holiday.10",
            number: 10,
            title: "Ten Lords a-Leaping",
            briefing: "Thrills for the party season: a ride rated seventy-five for excitement, six holiday rides and forty thousand in the bank.",
            mapID: "map.willowlake",
            startingCash: 24_000,
            dayLimit: 12,
            goals: [.thrillRide(75), .holidayRides(6), .cash(40_000)],
            medal: TrialMedal(name: "High Leaper", symbolName: "bolt.fill"),
            series: .holiday,
            rewardIDs: ["reward.fireworks"]),

        TrialDefinition(
            id: "holiday.11",
            number: 11,
            title: "Eleven Pipers Piping",
            briefing: "Four rides in their holiday best, two company parties and eighty guests in the park at once.",
            mapID: "map.pinewood",
            startingCash: 26_000,
            dayLimit: 12,
            goals: [.makeovers(4), .holidayParties(2), .guestsInPark(80)],
            medal: TrialMedal(name: "Piper", symbolName: "music.note"),
            series: .holiday,
            rewardIDs: ["reward.countdown"],
            needsRewardID: "reward.makeover.gentle"),

        TrialDefinition(
            id: "holiday.12",
            number: 12,
            title: "Twelve Drummers Drumming",
            briefing: "The grand finale. Eight holiday rides, a hundred guests, a packed bank and a park worth four stars to ring in the year.",
            mapID: "map.willowlake",
            startingCash: 28_000,
            dayLimit: 14,
            goals: [.holidayRides(8), .guestsInPark(100), .parkRating(70), .cash(60_000), .holidayParties(2)],
            medal: TrialMedal(name: "Wonder of the Season", symbolName: "crown.fill"),
            series: .holiday,
            rewardIDs: ["reward.ride.starburst"])
    ]
}
