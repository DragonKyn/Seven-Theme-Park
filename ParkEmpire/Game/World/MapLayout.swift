import Foundation

/// What the land is like before anybody builds on it.
///
/// Only four kinds, because a map is a puzzle about space, not a painting.
/// Grass is where the park goes. The other three are the shape of the puzzle:
/// water that can be bridged, and rock and forest that cannot be built on at
/// all.
enum MapGround: UInt8, Codable, CaseIterable, Identifiable {
    case grass
    case water
    case rock
    case forest

    var id: UInt8 { rawValue }

    var displayName: String {
        switch self {
        case .grass: return "Grass"
        case .water: return "Water"
        case .rock: return "Rock"
        case .forest: return "Forest"
        }
    }

    /// The terrain a tile of this ground becomes in a park.
    var terrain: TerrainType {
        switch self {
        case .grass: return .grass
        case .water: return .water
        case .rock: return .rock
        case .forest: return .forest
        }
    }
}

/// The ground of a whole map, and where its gate is.
///
/// The gate is always on the bottom edge. The car park, the sign and where
/// security stand are all drawn outside that edge, and a map is a better
/// puzzle for choosing where along it the gate goes than for rotating the
/// whole world.
struct MapLayout: Codable, Hashable {
    let width: Int
    let height: Int
    var ground: [MapGround]
    /// Column of the gate on the bottom row.
    var entranceX: Int

    /// How many tiles in front of the gate are kept clear, so every park can
    /// at least open. Matches the walkway a new park starts with, plus room
    /// either side of it to put something down.
    static let clearance = 4

    init(width: Int = Balance.mapWidth,
         height: Int = Balance.mapHeight,
         fill: MapGround = .grass,
         entranceX: Int? = nil) {
        self.width = width
        self.height = height
        self.ground = Array(repeating: fill, count: width * height)
        self.entranceX = entranceX ?? width / 2
    }

    func index(_ x: Int, _ y: Int) -> Int? {
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        return y * width + x
    }

    func ground(atX x: Int, y: Int) -> MapGround {
        guard let index = index(x, y) else { return .rock }
        return ground[index]
    }

    mutating func set(_ value: MapGround, x: Int, y: Int) {
        guard let index = index(x, y) else { return }
        ground[index] = value
    }

    /// Tiles a park could be built on.
    var buildableCount: Int {
        ground.reduce(0) { $0 + ($1 == .grass ? 1 : 0) }
    }

    /// Forces the land in front of the gate to grass. Called on every map
    /// before it is used, including ones the player drew, so a map can be
    /// awkward but never impossible to open.
    mutating func clearGateApproach() {
        entranceX = max(1, min(width - 2, entranceX))
        for y in 0...Self.clearance {
            for dx in -1...1 {
                set(.grass, x: entranceX + dx, y: y)
            }
        }
    }
}

extension MapLayout {
    /// Lenient decoding, for maps the player saved with an older build.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = container.value(.width, or: Balance.mapWidth)
        height = container.value(.height, or: Balance.mapHeight)
        let stored: [MapGround] = container.value(.ground, or: [])
        ground = stored.count == width * height
            ? stored
            : Array(repeating: .grass, count: width * height)
        entranceX = container.value(.entranceX, or: width / 2)
    }
}

// MARK: - Painting

/// Draws the shapes premade maps are made of.
///
/// Maps are written as a handful of shapes rather than as sixty rows of
/// characters, which is what makes them readable and cheap to tune. Edges are
/// roughened with a fixed noise so a lake is a lake rather than an ellipse,
/// and the same map always comes out the same.
struct MapPainter {
    private(set) var layout: MapLayout
    private let seed: UInt64

    init(fill: MapGround = .grass, entranceX: Int? = nil, seed: UInt64) {
        layout = MapLayout(fill: fill, entranceX: entranceX)
        self.seed = seed
    }

    /// A stable pseudo-random number in 0...1 for one tile.
    func noise(_ x: Int, _ y: Int, salt: UInt64 = 0) -> Double {
        var value = seed &+ salt &* 0x9E37_79B9_7F4A_7C15
        value ^= UInt64(truncatingIfNeeded: x) &* 0xBF58_476D_1CE4_E5B9
        value ^= UInt64(truncatingIfNeeded: y) &* 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        value = value &* 0xD6E8_FEB8_6659_FD93
        value ^= value >> 29
        return Double(value % 10_000) / 10_000
    }

    /// Every tile in a rectangle, inclusive of both corners.
    mutating func rect(_ ground: MapGround, x: ClosedRange<Int>, y: ClosedRange<Int>) {
        for row in y {
            for column in x {
                layout.set(ground, x: column, y: row)
            }
        }
    }

    /// A blob: an ellipse whose edge wanders by up to `rough` of its radius.
    mutating func blob(_ ground: MapGround,
                       centreX: Double,
                       centreY: Double,
                       radiusX: Double,
                       radiusY: Double,
                       rough: Double = 0.18) {
        let reachX = Int(radiusX * (1 + rough)) + 1
        let reachY = Int(radiusY * (1 + rough)) + 1
        for y in Int(centreY) - reachY...Int(centreY) + reachY {
            for x in Int(centreX) - reachX...Int(centreX) + reachX {
                let dx = (Double(x) - centreX) / radiusX
                let dy = (Double(y) - centreY) / radiusY
                let wobble = 1 + (noise(x, y) - 0.5) * 2 * rough
                if dx * dx + dy * dy <= wobble * wobble {
                    layout.set(ground, x: x, y: y)
                }
            }
        }
    }

    /// A band following a line through a list of points, `width` tiles across.
    mutating func band(_ ground: MapGround, through points: [(Double, Double)], width: Double) {
        guard points.count > 1 else { return }
        for index in 0..<(points.count - 1) {
            let (x0, y0) = points[index]
            let (x1, y1) = points[index + 1]
            let length = max(1, ((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)).squareRoot())
            let steps = Int(length * 2)
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let x = x0 + (x1 - x0) * t
                let y = y0 + (y1 - y0) * t
                let wander = (noise(Int(x), Int(y), salt: 7) - 0.5) * 1.2
                blob(ground,
                     centreX: x,
                     centreY: y,
                     radiusX: width / 2 + wander,
                     radiusY: width / 2 + wander,
                     rough: 0.05)
            }
        }
    }

    /// A ragged edge of `ground` around the whole map, `depth` tiles deep with
    /// some tiles reaching further in.
    mutating func border(_ ground: MapGround, depth: Int, ragged: Int = 2) {
        let width = layout.width
        let height = layout.height
        for y in 0..<height {
            for x in 0..<width {
                let edge = min(x, y, width - 1 - x, height - 1 - y)
                let reach = depth + Int(noise(x, y, salt: 3) * Double(ragged + 1))
                if edge < reach { layout.set(ground, x: x, y: y) }
            }
        }
    }

    /// Scatters `ground` over grass in a region, at roughly `density`.
    mutating func scatter(_ ground: MapGround,
                          x: ClosedRange<Int>,
                          y: ClosedRange<Int>,
                          density: Double) {
        for row in y {
            for column in x where layout.ground(atX: column, y: row) == .grass {
                if noise(column, row, salt: 11) < density {
                    layout.set(ground, x: column, y: row)
                }
            }
        }
    }

    /// The finished map, with the gate approach guaranteed clear.
    func finish() -> MapLayout {
        var result = layout
        result.clearGateApproach()
        return result
    }
}
