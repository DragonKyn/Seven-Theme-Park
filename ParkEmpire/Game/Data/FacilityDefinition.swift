import Foundation

enum FacilityKind: String, Codable {
    case food
    case drink
    case souvenir
    /// A carnival booth: pay, play, and maybe walk away with a prize.
    case game
    case bathroom
    case bench
    case bin

    /// Kinds that take the guest's money and therefore expose a price control.
    var sellsGoods: Bool {
        self == .food || self == .drink || self == .souvenir || self == .game
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
    /// How often a guest walks away from a carnival booth with a prize.
    /// Ignored by everything that is not a game.
    var winChance: Double = 0
    /// How much harder this pulls a guest in than a plain one of its kind.
    /// Raised by signage; 1 means no help.
    var drawFactor: Double = 1

    /// Whether this is something the player can pour money into after it is
    /// built. Restrooms, benches and bins are not: there is nothing to sell
    /// and nothing to improve about a bin.
    var acceptsUpgrades: Bool { kind.sellsGoods }

    var category: BuildCategory {
        switch kind {
        case .game: return .games
        case .food, .drink, .souvenir: return .shop
        case .bathroom, .bench, .bin: return .facility
        }
    }

    /// Furniture goes on the path. Everything else goes beside it.
    var bedTerrain: TerrainType? {
        kind.isFurniture ? .path : nil
    }

    /// Furniture on the walkway is already on it, so there is nothing to
    /// touch. Furniture beside the walkway is checked separately, because
    /// that is the case where reachability is not a given.
    var requiresPathAccess: Bool {
        !kind.isFurniture
    }

    /// Furniture may stand on the grass next to a path. The validator still
    /// insists it touches one, so a bin in the middle of a lawn is refused:
    /// the freedom is in where it looks right, not in making it useless.
    var maySitBesideBed: Bool {
        kind.isFurniture
    }

    var previewAppearance: BuildingAppearance? { appearance }

    var profitPerSale: Double { defaultPrice - unitCost }

    /// The same shop with its purchased upgrades folded in.
    ///
    /// Returning a definition rather than a separate stats type means every
    /// system that already reads a definition picks the upgrades up without
    /// being told about them, exactly as rides work.
    func applying(_ upgrades: [String: Int]) -> FacilityDefinition {
        guard !upgrades.isEmpty else { return self }
        func level(_ kind: ShopUpgradeKind) -> Double { Double(upgrades[kind.rawValue] ?? 0) }

        let service = level(.service)
        let quality = level(.quality)
        let signage = level(.signage)

        var improved = relief
        improved.happiness += quality * 3

        return FacilityDefinition(
            id: id,
            displayName: displayName,
            summary: summary,
            kind: kind,
            purchasePrice: purchasePrice,
            defaultPrice: defaultPrice,
            unitCost: unitCost,
            // What guests think it is worth. Raising this is what lets a
            // better stall charge more without anybody feeling fleeced.
            referencePrice: referencePrice * (1 + quality * 0.18),
            serviceDuration: serviceDuration,
            simultaneousCapacity: simultaneousCapacity + Int(service),
            queueCapacity: queueCapacity + Int(service) * 2,
            relief: improved,
            footprint: footprint,
            unlockLevel: unlockLevel,
            appearance: appearance,
            winChance: min(0.85, winChance > 0 ? winChance + quality * 0.06 : 0),
            drawFactor: drawFactor * (1 + signage * 0.18))
    }
}
