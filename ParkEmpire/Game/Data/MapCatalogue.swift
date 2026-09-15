import Foundation

/// A map a park can be built on: a name, a line about what makes it what it
/// is, and the land itself.
struct MapBlueprint: Identifiable, Equatable {
    let id: String
    let name: String
    let summary: String
    /// How much the land fights the player, 1 to 5. Shown as a hint, not a
    /// rule: an awkward map in free build is just an interesting one.
    let difficulty: Int
    let layout: MapLayout
    /// False for the maps that ship with the game.
    var isCustom = false

    static func == (lhs: MapBlueprint, rhs: MapBlueprint) -> Bool {
        lhs.id == rhs.id && lhs.layout == rhs.layout && lhs.name == rhs.name
    }
}

/// The maps that ship with the game.
///
/// Each is a handful of shapes rather than a hand-drawn grid, so the name
/// describes the layout and the layout is easy to read from the code. The
/// seed is fixed per map, so a map is the same every time it is played.
enum MapCatalogue {

    static let openMeadowID = "map.meadow"

    static let all: [MapBlueprint] = [
        openMeadow, willowLake, longPier, riverbend,
        pinewoodClearing, canyonFloor, twinPlateaus, harbourPoint
    ]

    static func blueprint(id: String) -> MapBlueprint? {
        all.first { $0.id == id }
    }

    // MARK: - The maps

    /// Almost all of it is open grass. A few copses round the edge, so the
    /// map is not a green rectangle.
    static let openMeadow: MapBlueprint = {
        var painter = MapPainter(seed: 11)
        painter.scatter(.forest, x: 0...59, y: 50...59, density: 0.35)
        painter.blob(.forest, centreX: 6, centreY: 30, radiusX: 4, radiusY: 6)
        painter.blob(.forest, centreX: 54, centreY: 22, radiusX: 3.5, radiusY: 5)
        return MapBlueprint(
            id: openMeadowID,
            name: "Open Meadow",
            summary: "Flat, open grass as far as the fence. Room for anything.",
            difficulty: 1,
            layout: painter.finish())
    }()

    /// A lake in the middle of the lot with two islands in it. The best
    /// spots in the park are out on the water, and getting there takes
    /// bridges.
    static let willowLake: MapBlueprint = {
        var painter = MapPainter(seed: 23)
        painter.blob(.water, centreX: 30, centreY: 34, radiusX: 19, radiusY: 15, rough: 0.14)
        painter.blob(.grass, centreX: 22, centreY: 38, radiusX: 6, radiusY: 5)
        painter.blob(.grass, centreX: 38, centreY: 30, radiusX: 5, radiusY: 6)
        painter.scatter(.forest, x: 0...59, y: 54...59, density: 0.30)
        return MapBlueprint(
            id: "map.willowlake",
            name: "Willow Lake",
            summary: "A lake fills the middle with two islands in it. Bridges get you there.",
            difficulty: 2,
            layout: painter.finish())
    }()

    /// A strip of land five tiles wide running out into the sea, with a
    /// wider platform at the far end. Every tile counts, and every guest
    /// walks the whole way.
    static let longPier: MapBlueprint = {
        var painter = MapPainter(fill: .water, entranceX: 30, seed: 37)
        painter.rect(.grass, x: 28...32, y: 0...44)
        painter.blob(.grass, centreX: 30, centreY: 50, radiusX: 9, radiusY: 6, rough: 0.10)
        // A couple of jetties off the side, to reward thinking sideways.
        painter.rect(.grass, x: 18...27, y: 16...19)
        painter.rect(.grass, x: 33...42, y: 30...33)
        painter.rect(.rock, x: 0...59, y: 57...59)
        return MapBlueprint(
            id: "map.longpier",
            name: "The Long Pier",
            summary: "A strip five tiles wide out into the sea. Nothing is wasted here.",
            difficulty: 4,
            layout: painter.finish())
    }()

    /// A river crosses the whole map in a loose S, so the park either stays
    /// on the gate's bank or pays to cross.
    static let riverbend: MapBlueprint = {
        var painter = MapPainter(seed: 41)
        painter.band(.water,
                     through: [(-2, 16), (14, 22), (28, 14), (42, 26), (50, 40), (62, 44)],
                     width: 5)
        painter.scatter(.forest, x: 0...59, y: 48...59, density: 0.28)
        painter.blob(.forest, centreX: 8, centreY: 44, radiusX: 5, radiusY: 4)
        return MapBlueprint(
            id: "map.riverbend",
            name: "Riverbend",
            summary: "A river winds right across the lot. Stay on one bank, or pay to cross.",
            difficulty: 3,
            layout: painter.finish())
    }()

    /// Thick pine forest with a chain of clearings through it. The land is
    /// there; it just comes in pockets.
    static let pinewoodClearing: MapBlueprint = {
        var painter = MapPainter(fill: .forest, seed: 53)
        painter.blob(.grass, centreX: 30, centreY: 9, radiusX: 11, radiusY: 8)
        painter.blob(.grass, centreX: 18, centreY: 27, radiusX: 10, radiusY: 8)
        painter.blob(.grass, centreX: 41, centreY: 33, radiusX: 11, radiusY: 9)
        painter.blob(.grass, centreX: 27, centreY: 49, radiusX: 12, radiusY: 7)
        painter.band(.grass, through: [(30, 9), (18, 27), (41, 33), (27, 49)], width: 4)
        return MapBlueprint(
            id: "map.pinewood",
            name: "Pinewood Clearing",
            summary: "Dense pines with a chain of clearings through them. Build in pockets.",
            difficulty: 3,
            layout: painter.finish())
    }()

    /// Rock walls either side of a winding valley. The valley is the park.
    static let canyonFloor: MapBlueprint = {
        var painter = MapPainter(fill: .rock, entranceX: 24, seed: 67)
        painter.band(.grass,
                     through: [(24, -2), (22, 14), (34, 26), (30, 40), (38, 52), (36, 62)],
                     width: 12)
        // A stream down the middle of it, because it is a canyon.
        painter.band(.water,
                     through: [(31, 20), (34, 26), (31, 36), (33, 44)],
                     width: 2)
        return MapBlueprint(
            id: "map.canyon",
            name: "Canyon Floor",
            summary: "Sheer rock either side of a winding valley. The valley is all you get.",
            difficulty: 4,
            layout: painter.finish())
    }()

    /// Two blocks of land split by a rocky ridge, joined by a single narrow
    /// pass. Crowds have to squeeze through it.
    static let twinPlateaus: MapBlueprint = {
        var painter = MapPainter(seed: 79)
        painter.band(.rock, through: [(-2, 30), (20, 28), (40, 32), (62, 30)], width: 7)
        painter.rect(.grass, x: 28...31, y: 22...38)
        painter.border(.forest, depth: 1, ragged: 2)
        return MapBlueprint(
            id: "map.twinplateaus",
            name: "Twin Plateaus",
            summary: "A rocky ridge splits the land in two, with one narrow pass between.",
            difficulty: 3,
            layout: painter.finish())
    }()

    /// A point of land narrowing into the sea, water on three sides. Plenty
    /// of room near the gate, less and less the further out you go.
    static let harbourPoint: MapBlueprint = {
        var painter = MapPainter(fill: .water, entranceX: 30, seed: 97)
        for y in 0..<60 {
            let halfWidth = max(3, 28 - Double(y) * 0.42)
            let centre = 30 + sin(Double(y) / 9) * 3
            for x in Int(centre - halfWidth)...Int(centre + halfWidth) {
                painter.rect(.grass, x: x...x, y: y...y)
            }
        }
        painter.blob(.rock, centreX: 30, centreY: 56, radiusX: 3, radiusY: 3)
        return MapBlueprint(
            id: "map.harbour",
            name: "Harbour Point",
            summary: "A headland narrowing into the sea. Roomy at the gate, tight at the tip.",
            difficulty: 3,
            layout: painter.finish())
    }()
}
