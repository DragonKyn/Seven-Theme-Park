import CoreGraphics
import Foundation

/// Integer tile coordinate. Origin is the bottom-left of the park; +y is north.
struct GridCoord: Hashable, Codable {
    var x: Int
    var y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    static let zero = GridCoord(0, 0)

    var orthogonalNeighbours: [GridCoord] {
        [GridCoord(x + 1, y), GridCoord(x - 1, y), GridCoord(x, y + 1), GridCoord(x, y - 1)]
    }

    func manhattanDistance(to other: GridCoord) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    /// Centre of the tile expressed in tile-space (1 unit == 1 tile).
    var centre: CGPoint {
        CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5)
    }
}

/// Footprint size in tiles.
struct GridSize: Hashable, Codable {
    var width: Int
    var height: Int

    init(_ width: Int, _ height: Int) {
        self.width = width
        self.height = height
    }

    static let single = GridSize(1, 1)
    var tileCount: Int { width * height }
}

/// An axis-aligned block of tiles: a building footprint or a selection.
struct GridRect: Hashable, Codable {
    var origin: GridCoord
    var size: GridSize

    init(origin: GridCoord, size: GridSize) {
        self.origin = origin
        self.size = size
    }

    var coords: [GridCoord] {
        var result: [GridCoord] = []
        result.reserveCapacity(size.tileCount)
        for dy in 0..<size.height {
            for dx in 0..<size.width {
                result.append(GridCoord(origin.x + dx, origin.y + dy))
            }
        }
        return result
    }

    func contains(_ coord: GridCoord) -> Bool {
        coord.x >= origin.x && coord.x < origin.x + size.width
            && coord.y >= origin.y && coord.y < origin.y + size.height
    }

    /// Tiles orthogonally touching the rect. Guests must reach one of these to
    /// use the building, which is how "buildings need path access" is enforced.
    var adjacentCoords: [GridCoord] {
        var result: [GridCoord] = []
        for dx in 0..<size.width {
            result.append(GridCoord(origin.x + dx, origin.y - 1))
            result.append(GridCoord(origin.x + dx, origin.y + size.height))
        }
        for dy in 0..<size.height {
            result.append(GridCoord(origin.x - 1, origin.y + dy))
            result.append(GridCoord(origin.x + size.width, origin.y + dy))
        }
        return result
    }

    /// How many tiles away `coord` is from the nearest tile of this rect,
    /// counting a diagonal step as one. Zero when the coordinate is inside.
    func chebyshevDistance(to coord: GridCoord) -> Int {
        let dx = max(origin.x - coord.x, coord.x - (origin.x + size.width - 1), 0)
        let dy = max(origin.y - coord.y, coord.y - (origin.y + size.height - 1), 0)
        return max(dx, dy)
    }

    /// Centre of the rect in tile-space, used for label and sprite placement.
    var centre: CGPoint {
        CGPoint(x: CGFloat(origin.x) + CGFloat(size.width) / 2.0,
                y: CGFloat(origin.y) + CGFloat(size.height) / 2.0)
    }
}
