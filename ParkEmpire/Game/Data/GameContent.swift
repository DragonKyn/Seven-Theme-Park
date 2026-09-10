import Foundation

/// The static content catalogue. All game objects are data; adding content
/// means adding an entry here, not editing a simulation system.
enum GameContent {

    // MARK: - Terrain

    static let path = TerrainDefinition(
        id: "path.concrete",
        displayName: "Walkway",
        summary: "Guests can only travel on walkways.",
        purchasePrice: 25,
        refundValue: 10,
        terrain: .path,
        category: .path,
        beauty: 0,
        beautyRadius: 0
    )

    static let water = TerrainDefinition(
        id: "terrain.water",
        displayName: "Water",
        summary: "A pond. Nothing can cross it or be built on it, and nothing else this cheap looks as good.",
        purchasePrice: 90,
        refundValue: 20,
        terrain: .water,
        category: .scenery,
        beauty: 52,
        beautyRadius: 2
    )

    static let coasterTrack = TerrainDefinition(
        id: "terrain.coastertrack",
        displayName: "Coaster Track",
        summary: "Lay your own circuit. The longer and the better it runs, the better the ride.",
        purchasePrice: 120,
        refundValue: 40,
        terrain: .coasterTrack,
        category: .coaster,
        beauty: 0,
        beautyRadius: 0
    )

    /// Terrain in build-menu order. Both are drawn by dragging, so they share
    /// the same handling everywhere the player paints a run of tiles.
    static let track = TerrainDefinition(
        id: "terrain.track",
        displayName: "Track",
        summary: "Railway for the trains. Drag out a loop, then put a station on it.",
        purchasePrice: 45,
        refundValue: 15,
        terrain: .track,
        category: .transport,
        beauty: 0,
        beautyRadius: 0
    )

    /// Terrain in build-menu order. All of it is drawn by dragging, so it
    /// shares the same handling everywhere the player paints a run of tiles.
    static let terrains: [TerrainDefinition] = [path, water, track, coasterTrack]

    // MARK: - Attractions

    static let attractions: [AttractionDefinition] = [
        AttractionDefinition(
            id: "ride.carousel",
            displayName: "Carousel",
            summary: "A gentle spinning ride the whole family enjoys.",
            purchasePrice: 2_500,
            capacity: 12,
            rideDuration: 45,
            loadDuration: 12,
            excitement: 20,
            nausea: 5,
            maintenanceRate: 0.010,
            operatingCostPerCycle: 4,
            footprint: GridSize(3, 3),
            unlockLevel: 1,
            appearance: BuildingAppearance(.carousel, .pink, .cream, .amber),
            group: .gentle
        ),
        AttractionDefinition(
            id: "ride.pirateship",
            displayName: "Swinging Galleon",
            summary: "A swinging boat that builds to a satisfying arc.",
            purchasePrice: 5_000,
            capacity: 16,
            rideDuration: 60,
            loadDuration: 14,
            excitement: 50,
            nausea: 45,
            maintenanceRate: 0.020,
            operatingCostPerCycle: 8,
            footprint: GridSize(4, 3),
            unlockLevel: 2,
            appearance: BuildingAppearance(.swingBoat, .red, .sand, .brown),
            group: .thrill
        ),
        AttractionDefinition(
            id: "ride.droptower",
            displayName: "Sky Plunge",
            summary: "A slow climb, a long pause, then straight down.",
            purchasePrice: 8_500,
            capacity: 12,
            rideDuration: 50,
            loadDuration: 16,
            excitement: 78,
            nausea: 50,
            maintenanceRate: 0.032,
            operatingCostPerCycle: 12,
            footprint: GridSize(3, 3),
            unlockLevel: 3,
            appearance: BuildingAppearance(.dropTower, .amber, .sand, .slate),
            group: .thrill
        ),
        AttractionDefinition(
            id: "ride.minicoaster",
            displayName: "Sapling Coaster",
            summary: "A compact coaster with a surprising amount of bite.",
            purchasePrice: 15_000,
            capacity: 16,
            rideDuration: 90,
            loadDuration: 20,
            excitement: 82,
            nausea: 42,
            maintenanceRate: 0.035,
            operatingCostPerCycle: 18,
            footprint: GridSize(6, 4),
            unlockLevel: 4,
            appearance: BuildingAppearance(.coaster, .yellow, .lime, .blue),
            group: .thrill
        ),
        AttractionDefinition(
            id: "ride.teacups",
            displayName: "Spinning Teacups",
            summary: "Cheap, cheerful, and rougher on the stomach than it looks.",
            purchasePrice: 3_200,
            capacity: 12,
            rideDuration: 40,
            loadDuration: 12,
            excitement: 32,
            nausea: 58,
            maintenanceRate: 0.012,
            operatingCostPerCycle: 5,
            footprint: GridSize(3, 3),
            unlockLevel: 1,
            appearance: BuildingAppearance(.teacups, .violet, .cream, .pink),
            group: .family
        ),
        AttractionDefinition(
            id: "ride.bumpercars",
            displayName: "Bumper Cars",
            summary: "A big draw for families, and almost nothing on it can break.",
            purchasePrice: 4_200,
            capacity: 14,
            rideDuration: 55,
            loadDuration: 16,
            excitement: 42,
            nausea: 22,
            maintenanceRate: 0.014,
            operatingCostPerCycle: 7,
            footprint: GridSize(4, 3),
            unlockLevel: 2,
            appearance: BuildingAppearance(.bumperCars, .blue, .charcoal, .yellow),
            group: .family
        ),
        AttractionDefinition(
            id: "ride.carpetslide",
            displayName: "Carpet Slide",
            summary: "Four lanes, one hessian mat, and a queue that never stops moving.",
            purchasePrice: 5_500,
            capacity: 10,
            rideDuration: 26,
            loadDuration: 10,
            excitement: 45,
            nausea: 14,
            maintenanceRate: 0.011,
            operatingCostPerCycle: 4,
            footprint: GridSize(4, 4),
            unlockLevel: 2,
            appearance: BuildingAppearance(.carpetSlide, .orange, .sand, .yellow),
            group: .family
        ),
        AttractionDefinition(
            id: "ride.gokarts.small",
            displayName: "Go Karts: Sprint",
            summary: "A short circuit. Two laps and they are queueing again.",
            purchasePrice: 6_500,
            capacity: 8,
            rideDuration: 65,
            loadDuration: 22,
            excitement: 52,
            nausea: 20,
            maintenanceRate: 0.030,
            operatingCostPerCycle: 11,
            footprint: GridSize(4, 4),
            unlockLevel: 2,
            appearance: BuildingAppearance(.goKarts, .red, .lime, .white),
            group: .family
        ),
        AttractionDefinition(
            id: "ride.hauntedhouse",
            displayName: "Haunted Manor",
            summary: "A slow ride through the dark. Takes crowds, and takes them all day.",
            purchasePrice: 9_000,
            capacity: 20,
            rideDuration: 95,
            loadDuration: 18,
            excitement: 56,
            nausea: 8,
            maintenanceRate: 0.016,
            operatingCostPerCycle: 10,
            footprint: GridSize(4, 4),
            unlockLevel: 2,
            appearance: BuildingAppearance(.hauntedHouse, .indigo, .charcoal, .amber),
            group: .gentle
        ),
        AttractionDefinition(
            id: "ride.ferriswheel",
            displayName: "Grand Wheel",
            summary: "Gentle, enormous capacity, and it makes the whole park look busier.",
            purchasePrice: 11_000,
            capacity: 24,
            rideDuration: 110,
            loadDuration: 24,
            excitement: 40,
            nausea: 10,
            maintenanceRate: 0.018,
            operatingCostPerCycle: 12,
            footprint: GridSize(4, 4),
            unlockLevel: 2,
            appearance: BuildingAppearance(.ferrisWheel, .cyan, .red, .white),
            group: .gentle
        ),
        AttractionDefinition(
            id: "ride.gokarts.medium",
            displayName: "Go Karts: Circuit",
            summary: "A proper lap with a hairpin. Worth the ground it eats.",
            purchasePrice: 12_000,
            capacity: 12,
            rideDuration: 95,
            loadDuration: 26,
            excitement: 64,
            nausea: 24,
            maintenanceRate: 0.038,
            operatingCostPerCycle: 17,
            footprint: GridSize(6, 5),
            unlockLevel: 3,
            appearance: BuildingAppearance(.goKarts, .amber, .lime, .white),
            group: .thrill
        ),
        AttractionDefinition(
            id: "ride.slingshot",
            displayName: "Slingshot",
            summary: "Two riders, straight up. Nothing else in the park excites them more.",
            purchasePrice: 13_500,
            capacity: 4,
            rideDuration: 34,
            loadDuration: 20,
            excitement: 93,
            nausea: 74,
            maintenanceRate: 0.048,
            operatingCostPerCycle: 14,
            footprint: GridSize(3, 3),
            unlockLevel: 4,
            appearance: BuildingAppearance(.slingshot, .yellow, .slate, .charcoal),
            group: .thrill
        ),
        AttractionDefinition(
            id: "ride.logflume",
            displayName: "Log Flume",
            summary: "A long, wet circuit ending in a drop everyone stops to watch.",
            purchasePrice: 16_000,
            capacity: 16,
            rideDuration: 105,
            loadDuration: 22,
            excitement: 70,
            nausea: 28,
            maintenanceRate: 0.034,
            operatingCostPerCycle: 16,
            footprint: GridSize(6, 5),
            unlockLevel: 3,
            appearance: BuildingAppearance(.logFlume, .cream, .green, .cyan),
            group: .water
        ),
        AttractionDefinition(
            id: "ride.gokarts.large",
            displayName: "Go Karts: Grand Prix",
            summary: "The full track. Expensive to run, and guests talk about nothing else.",
            purchasePrice: 22_000,
            capacity: 16,
            rideDuration: 130,
            loadDuration: 30,
            excitement: 74,
            nausea: 28,
            maintenanceRate: 0.046,
            operatingCostPerCycle: 26,
            footprint: GridSize(8, 6),
            unlockLevel: 4,
            appearance: BuildingAppearance(.goKarts, .indigo, .slate, .white),
            group: .thrill
        ),
        AttractionDefinition(
            id: "ride.bigcoaster",
            displayName: "Thunder Coaster",
            summary: "The one people come for. It will also break more than anything else you own.",
            purchasePrice: 38_000,
            capacity: 24,
            rideDuration: 125,
            loadDuration: 26,
            excitement: 96,
            nausea: 58,
            maintenanceRate: 0.052,
            operatingCostPerCycle: 34,
            footprint: GridSize(9, 6),
            unlockLevel: 4,
            appearance: BuildingAppearance(.megaCoaster, .red, .charcoal, .amber),
            group: .thrill
        ),
        AttractionDefinition(
            id: "ride.mirrormaze",
            displayName: "Mirror Maze",
            summary: "Cheap, quiet, and it keeps a queue moving all day. Nothing on it can break.",
            purchasePrice: 2_800,
            capacity: 14,
            rideDuration: 70,
            loadDuration: 10,
            excitement: 34,
            nausea: 6,
            maintenanceRate: 0.006,
            operatingCostPerCycle: 3,
            footprint: GridSize(3, 3),
            unlockLevel: 1,
            appearance: BuildingAppearance(.mirrorMaze, .indigo, .cyan, .amber),
            group: .gentle
        ),
        AttractionDefinition(
            id: "ride.fishingboats",
            displayName: "Fishing Boats",
            summary: "A slow lap of a reedy pond. Needs water beside it, and calms a nauseous crowd.",
            purchasePrice: 4_600,
            capacity: 12,
            rideDuration: 95,
            loadDuration: 16,
            excitement: 26,
            nausea: 2,
            maintenanceRate: 0.010,
            operatingCostPerCycle: 6,
            footprint: GridSize(5, 4),
            unlockLevel: 1,
            appearance: BuildingAppearance(.fishingBoats, .cream, .green, .red),
            group: .water,
            needsWater: true
        ),
        AttractionDefinition(
            id: "ride.bumperboats",
            displayName: "Bumper Boats",
            summary: "Bumper cars, wet. Needs water beside it, and the queue never stops laughing.",
            purchasePrice: 6_800,
            capacity: 12,
            rideDuration: 65,
            loadDuration: 18,
            excitement: 48,
            nausea: 18,
            maintenanceRate: 0.018,
            operatingCostPerCycle: 9,
            footprint: GridSize(4, 4),
            unlockLevel: 2,
            appearance: BuildingAppearance(.bumperBoats, .teal, .cyan, .amber),
            group: .water,
            needsWater: true
        ),
        AttractionDefinition(
            id: "ride.skygliders",
            displayName: "Sky Gliders",
            summary: "Chairs on a cable. Enormous capacity, almost no thrill, and everybody rides it once.",
            purchasePrice: 9_500,
            capacity: 26,
            rideDuration: 115,
            loadDuration: 20,
            excitement: 38,
            nausea: 8,
            maintenanceRate: 0.020,
            operatingCostPerCycle: 11,
            footprint: GridSize(6, 3),
            unlockLevel: 2,
            appearance: BuildingAppearance(.skyGliders, .cream, .green, .red),
            group: .gentle
        ),
        AttractionDefinition(
            id: "ride.wavepool",
            displayName: "Wave Rider",
            summary: "A standing wave to surf. Needs water beside it, and thrills without spinning anybody.",
            purchasePrice: 14_000,
            capacity: 10,
            rideDuration: 60,
            loadDuration: 20,
            excitement: 72,
            nausea: 22,
            maintenanceRate: 0.038,
            operatingCostPerCycle: 18,
            footprint: GridSize(5, 4),
            unlockLevel: 3,
            appearance: BuildingAppearance(.wavePool, .slate, .sand, .cyan),
            group: .water,
            needsWater: true
        ),
        AttractionDefinition(
            id: "coaster.station",
            displayName: "Wonder Coaster",
            summary: "Lay a circuit of coaster track and put this on it. A longer ride is a better ride.",
            purchasePrice: 12_000,
            capacity: 20,
            rideDuration: 20,
            loadDuration: 20,
            excitement: 45,
            nausea: 40,
            maintenanceRate: 0.040,
            operatingCostPerCycle: 20,
            footprint: GridSize(4, 2),
            unlockLevel: 2,
            appearance: BuildingAppearance(.coasterStation, .red, .slate, .amber),
            kind: .custom,
            group: .thrill
        ),
        AttractionDefinition(
            id: "transport.station",
            displayName: "Train Station",
            summary: "Carries guests to another station on the same track. Cheap to run, and it saves a long walk.",
            purchasePrice: 4_800,
            capacity: 20,
            rideDuration: 60,
            loadDuration: 18,
            excitement: 30,
            nausea: 4,
            maintenanceRate: 0.014,
            operatingCostPerCycle: 6,
            footprint: GridSize(3, 2),
            unlockLevel: 1,
            appearance: BuildingAppearance(.trainStation, .green, .cream, .brown),
            kind: .transport
        )
    ]

    // MARK: - Facilities

    static let facilities: [FacilityDefinition] = [
        FacilityDefinition(
            id: "shop.burger",
            displayName: "Burger Stand",
            summary: "Hot food that takes a real bite out of hunger.",
            kind: .food,
            purchasePrice: 1_200,
            defaultPrice: 7,
            unitCost: 3,
            referencePrice: 8,
            serviceDuration: 7,
            simultaneousCapacity: 1,
            queueCapacity: 10,
            relief: NeedRelief(hunger: 55, thirst: -10, bathroom: -12, happiness: 4),
            footprint: GridSize(2, 2),
            unlockLevel: 1,
            appearance: BuildingAppearance(.burgerStall, .red, .amber, .brown)
        ),
        FacilityDefinition(
            id: "shop.drinks",
            displayName: "Drink Kiosk",
            summary: "Cold drinks. Guests get thirsty faster than they get hungry.",
            kind: .drink,
            purchasePrice: 900,
            defaultPrice: 3,
            unitCost: 1,
            referencePrice: 4,
            serviceDuration: 5,
            simultaneousCapacity: 1,
            queueCapacity: 10,
            relief: NeedRelief(thirst: 65, bathroom: -20, happiness: 3),
            footprint: GridSize(2, 2),
            unlockLevel: 1,
            appearance: BuildingAppearance(.drinkKiosk, .cyan, .blue, .indigo)
        ),
        FacilityDefinition(
            id: "shop.pizza",
            displayName: "Pizza Stand",
            summary: "Filling, and it makes guests thirsty afterwards.",
            kind: .food,
            purchasePrice: 1_400,
            defaultPrice: 9,
            unitCost: 3.5,
            referencePrice: 10,
            serviceDuration: 8,
            simultaneousCapacity: 1,
            queueCapacity: 10,
            relief: NeedRelief(hunger: 62, thirst: -14, bathroom: -14, happiness: 5),
            footprint: GridSize(2, 2),
            unlockLevel: 2,
            appearance: BuildingAppearance(.pizzaStall, .green, .cream, .red)
        ),
        FacilityDefinition(
            id: "shop.icecream",
            displayName: "Ice Cream Stand",
            summary: "Barely a meal, but it cheers guests up more than anything else.",
            kind: .food,
            purchasePrice: 1_000,
            defaultPrice: 4.5,
            unitCost: 1.5,
            referencePrice: 5,
            serviceDuration: 5,
            simultaneousCapacity: 1,
            queueCapacity: 10,
            relief: NeedRelief(hunger: 22, thirst: 12, bathroom: -6, happiness: 11),
            footprint: GridSize(2, 2),
            unlockLevel: 2,
            appearance: BuildingAppearance(.iceCreamStall, .pink, .cream, .violet)
        ),
        FacilityDefinition(
            id: "shop.souvenir",
            displayName: "Souvenir Shop",
            summary: "Happy guests with money left over buy something to take home.",
            kind: .souvenir,
            purchasePrice: 1_800,
            defaultPrice: 14,
            unitCost: 5,
            referencePrice: 15,
            serviceDuration: 9,
            simultaneousCapacity: 1,
            queueCapacity: 8,
            relief: NeedRelief(happiness: 9),
            footprint: GridSize(2, 2),
            unlockLevel: 3,
            appearance: BuildingAppearance(.souvenirShop, .violet, .indigo, .amber)
        ),
        FacilityDefinition(
            id: "facility.bathroom",
            displayName: "Restroom",
            summary: "Guests get unhappy fast when they cannot find one.",
            kind: .bathroom,
            purchasePrice: 1_500,
            defaultPrice: 0,
            unitCost: 0,
            referencePrice: 0,
            serviceDuration: 22,
            simultaneousCapacity: 2,
            queueCapacity: 12,
            relief: NeedRelief(bathroom: 100, happiness: 3),
            footprint: GridSize(2, 2),
            unlockLevel: 1,
            appearance: BuildingAppearance(.restroom, .cream, .teal, .slate)
        ),
        FacilityDefinition(
            id: "facility.bench",
            displayName: "Bench",
            summary: "Tired guests sit here instead of going home early.",
            kind: .bench,
            purchasePrice: 120,
            defaultPrice: 0,
            unitCost: 0,
            referencePrice: 0,
            serviceDuration: 40,
            simultaneousCapacity: 2,
            queueCapacity: 2,
            relief: NeedRelief(energy: 45, happiness: 2, nausea: 25),
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.bench, .brown, .sand, .charcoal)
        ),
        FacilityDefinition(
            id: "facility.bin",
            displayName: "Garbage Bin",
            summary: "Guests carrying rubbish look for one. Without bins, they litter.",
            kind: .bin,
            purchasePrice: 80,
            defaultPrice: 0,
            unitCost: 0,
            referencePrice: 0,
            serviceDuration: 2,
            simultaneousCapacity: 1,
            queueCapacity: 4,
            relief: NeedRelief(),
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.bin, .slate, .charcoal, .amber)
        )
    ]

    // MARK: - Scenery

    static let scenery: [SceneryDefinition] = [
        SceneryDefinition(
            id: "scenery.tree",
            displayName: "Shade Tree",
            summary: "Cheap greenery. A row of them turns a bare walkway into somewhere pleasant.",
            purchasePrice: 150,
            beauty: 30,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.tree, .green, .lime, .brown)
        ),
        SceneryDefinition(
            id: "scenery.conifer",
            displayName: "Pine",
            summary: "Taller and darker than a shade tree, and reaches a little further.",
            purchasePrice: 220,
            beauty: 38,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.conifer, .teal, .green, .brown)
        ),
        SceneryDefinition(
            id: "scenery.flowerbed",
            displayName: "Flower Bed",
            summary: "Low colour beside a path. Best in clusters where guests queue.",
            purchasePrice: 180,
            beauty: 34,
            beautyRadius: 1,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.flowerBed, .pink, .yellow, .brown)
        ),
        SceneryDefinition(
            id: "scenery.lamp",
            displayName: "Park Lamp",
            summary: "Modest on its own, but it tidies up a long stretch of walkway.",
            purchasePrice: 120,
            beauty: 20,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 1,
            appearance: BuildingAppearance(.lamp, .amber, .cream, .charcoal)
        ),
        SceneryDefinition(
            id: "scenery.topiary",
            displayName: "Topiary",
            summary: "Clipped hedging in a planter. Smart enough for a park entrance.",
            purchasePrice: 320,
            beauty: 46,
            beautyRadius: 2,
            footprint: GridSize(1, 1),
            unlockLevel: 2,
            appearance: BuildingAppearance(.topiary, .green, .lime, .sand)
        ),
        SceneryDefinition(
            id: "scenery.statue",
            displayName: "Statue",
            summary: "A landmark. Expensive, and worth it where everybody walks past.",
            purchasePrice: 1_400,
            beauty: 70,
            beautyRadius: 3,
            footprint: GridSize(1, 1),
            unlockLevel: 3,
            appearance: BuildingAppearance(.statue, .cream, .amber, .slate)
        ),
        SceneryDefinition(
            id: "scenery.fountain",
            displayName: "Fountain",
            summary: "The centrepiece. Nothing else lifts the look of a park this much.",
            purchasePrice: 3_200,
            beauty: 100,
            beautyRadius: 4,
            footprint: GridSize(2, 2),
            unlockLevel: 3,
            appearance: BuildingAppearance(.fountain, .cyan, .white, .slate)
        )
    ]

    // MARK: - Lookup

    private static let attractionsByID: [String: AttractionDefinition] =
        Dictionary(uniqueKeysWithValues: attractions.map { ($0.id, $0) })

    private static let facilitiesByID: [String: FacilityDefinition] =
        Dictionary(uniqueKeysWithValues: facilities.map { ($0.id, $0) })

    private static let sceneryByID: [String: SceneryDefinition] =
        Dictionary(uniqueKeysWithValues: scenery.map { ($0.id, $0) })

    static func attraction(_ id: String) -> AttractionDefinition? { attractionsByID[id] }
    static func facility(_ id: String) -> FacilityDefinition? { facilitiesByID[id] }
    static func scenery(_ id: String) -> SceneryDefinition? { sceneryByID[id] }

    /// Everything placeable, in menu order.
    static var allBuildables: [BuildableDefinition] {
        var result: [BuildableDefinition] = terrains as [BuildableDefinition]
        result.append(contentsOf: attractions as [BuildableDefinition])
        result.append(contentsOf: facilities as [BuildableDefinition])
        result.append(contentsOf: CoasterElementContent.all as [BuildableDefinition])
        result.append(contentsOf: scenery as [BuildableDefinition])
        return result
    }

    static func buildables(in category: BuildCategory, unlockLevel: Int) -> [BuildableDefinition] {
        allBuildables.filter { $0.category == category && $0.unlockLevel <= unlockLevel }
    }
}
