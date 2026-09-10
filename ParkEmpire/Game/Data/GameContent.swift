import Foundation

/// The static content catalogue. All game objects are data; adding content
/// means adding an entry here, not editing a simulation system.
enum GameContent {

    // MARK: - Paths

    static let path = PathDefinition(
        id: "path.concrete",
        displayName: "Walkway",
        summary: "Guests can only travel on walkways.",
        purchasePrice: 25,
        refundValue: 10
    )

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
            appearance: BuildingAppearance(.carousel, .pink, .cream, .amber)
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
            appearance: BuildingAppearance(.swingBoat, .red, .sand, .brown)
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
            appearance: BuildingAppearance(.dropTower, .amber, .sand, .slate)
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
            appearance: BuildingAppearance(.coaster, .yellow, .lime, .blue)
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
            appearance: BuildingAppearance(.stall, .red, .amber, .brown)
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
            appearance: BuildingAppearance(.kiosk, .cyan, .blue, .cream)
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
            appearance: BuildingAppearance(.stall, .green, .red, .brown)
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
            appearance: BuildingAppearance(.kiosk, .pink, .cream, .violet)
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
            appearance: BuildingAppearance(.shopFront, .violet, .indigo, .amber)
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

    // MARK: - Lookup

    private static let attractionsByID: [String: AttractionDefinition] =
        Dictionary(uniqueKeysWithValues: attractions.map { ($0.id, $0) })

    private static let facilitiesByID: [String: FacilityDefinition] =
        Dictionary(uniqueKeysWithValues: facilities.map { ($0.id, $0) })

    static func attraction(_ id: String) -> AttractionDefinition? { attractionsByID[id] }
    static func facility(_ id: String) -> FacilityDefinition? { facilitiesByID[id] }

    /// Everything placeable, in menu order.
    static var allBuildables: [BuildableDefinition] {
        var result: [BuildableDefinition] = [path]
        result.append(contentsOf: attractions as [BuildableDefinition])
        result.append(contentsOf: facilities as [BuildableDefinition])
        return result
    }

    static func buildables(in category: BuildCategory, unlockLevel: Int) -> [BuildableDefinition] {
        allBuildables.filter { $0.category == category && $0.unlockLevel <= unlockLevel }
    }
}
