import Foundation

enum FacilityKind: String, Codable {
    case food
    case drink
    case souvenir
    case bathroom
    case bench
    case bin

    /// Kinds that take the guest's money and therefore expose a price control.
    var sellsGoods: Bool {
        self == .food || self == .drink || self == .souvenir
    }

    /// Park furniture: it stands on the walkway rather than beside it, and
    /// guests walk round it. A bench on the grass behind a path is a bench
    /// nobody sits on, which is not what a bench is for.
    var isFurniture: Bool {
        self == .bench || self == .bin
    }

    /// Kinds that get dirty or fill up and need a janitor's attention.
    var needsServicing: Bool {
        self == .bathroom || self == .bin
    }

    /// Wording used when a janitor is working on one.
    var servicingVerb: String {
        self == .bin ? "Emptying" : "Cleaning"
    }
}

/// How much a single use of a facility moves a guest's needs.
/// Positive values on `hunger`/`thirst`/`bathroom` mean the need is *reduced*
/// by that amount; the stats themselves always read "100 = most urgent".
struct NeedRelief: Codable {
    var hunger: Double = 0
    var thirst: Double = 0
    var bathroom: Double = 0
    var energy: Double = 0
    var happiness: Double = 0
    var nausea: Double = 0
}

/// Static configuration for shops, bathrooms and benches.
struct FacilityDefinition: BuildableDefinition, Codable, Identifiable {
    let id: String
    let displayName: String
    let summary: String
    let kind: FacilityKind
    let purchasePrice: Double
    /// Price the shop opens with; the player can change it afterwards.
    let defaultPrice: Double
    /// What each sale costs the park.
    let unitCost: Double
    /// The price guests consider fair. Charging above this erodes willingness
    /// to buy; see `GuestEconomics.purchaseWillingness`.
    let referencePrice: Double
    /// Sim-seconds one guest occupies a service slot.
    let serviceDuration: Double
    /// Guests that can be served at the same time (stalls, seats, tills).
    let simultaneousCapacity: Int
    let queueCapacity: Int
    let relief: NeedRelief
    let footprint: GridSize
    let unlockLevel: Int
    /// How the placed building is drawn.
    let appearance: BuildingAppearance

    var category: BuildCategory {
        kind.sellsGoods ? .shop : .facility
    }

    /// Furniture goes on the path. Everything else goes beside it.
    var bedTerrain: TerrainType? {
        kind.isFurniture ? .path : nil
    }

    /// Furniture is already on the walkway, so there is nothing to touch.
    var requiresPathAccess: Bool {
        !kind.isFurniture
    }

    var previewAppearance: BuildingAppearance? { appearance }

    var profitPerSale: Double { defaultPrice - unitCost }
}
