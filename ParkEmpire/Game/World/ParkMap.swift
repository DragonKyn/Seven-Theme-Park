import Foundation

/// The park's tile grid. Owns terrain, building occupancy and litter; the
/// entities that sit on those tiles live in `GameState`.
struct ParkMap: Codable {
    let width: Int
    let height: Int
    private(set) var tiles: [Tile]

    /// Bumped whenever walkability changes. Cached routes compare against this
    /// and rebuild when it moves, so nothing has to explicitly invalidate them.
    private(set) var generation: Int = 0

    /// Bumped whenever litter changes, so the renderer can skip the work when
    /// nothing has been dropped or swept. Deliberately separate from
    /// `generation`: litter never affects where guests can walk.
    private(set) var litterGeneration: Int = 0

    /// Tiles currently holding rubbish. Kept as a set so janitors can find work
    /// and the renderer can find sprites without scanning the whole grid.
    private(set) var litteredTiles: Set<GridCoord> = []
    private(set) var litterTotal: Double = 0

    /// Where guests appear and leave. Always a walkable entrance tile.
    private(set) var entranceCoord: GridCoord

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.tiles = Array(repeating: Tile(), count: width * height)
        self.entranceCoord = GridCoord(width / 2, 0)
    }

    // MARK: - Access

    func isInside(_ coord: GridCoord) -> Bool {
        coord.x >= 0 && coord.x < width && coord.y >= 0 && coord.y < height
    }

    /// Row-major index of a coordinate. Callers must have checked `isInside`.
    func linearIndex(of coord: GridCoord) -> Int {
        coord.y * width + coord.x
    }

    func coord(atLinearIndex index: Int) -> GridCoord {
        GridCoord(index % width, index / width)
    }

    var tileCount: Int { width * height }

    func tile(at coord: GridCoord) -> Tile? {
        guard isInside(coord) else { return nil }
        return tiles[linearIndex(of: coord)]
    }

    func isWalkable(_ coord: GridCoord) -> Bool {
        guard isInside(coord) else { return false }
        return tiles[linearIndex(of: coord)].isWalkable
    }

    func walkableNeighbours(of coord: GridCoord) -> [GridCoord] {
        coord.orthogonalNeighbours.filter { isWalkable($0) }
    }

    var walkableTileCount: Int {
        tiles.reduce(0) { $0 + ($1.isWalkable ? 1 : 0) }
    }

    /// True when every tile of `rect` is inside the park, empty and buildable.
    func isAreaBuildable(_ rect: GridRect) -> Bool {
        for coord in rect.coords {
            guard let tile = tile(at: coord) else { return false }
            if tile.terrain != .grass || tile.buildingID != nil { return false }
        }
        return true
    }

    /// Walkable tiles a guest can stand on to use the given footprint.
    func accessTiles(for rect: GridRect) -> [GridCoord] {
        rect.adjacentCoords.filter { isWalkable($0) }
    }

    // MARK: - Terrain mutation

    mutating func setTerrain(_ terrain: TerrainType, at coord: GridCoord) {
        guard isInside(coord) else { return }
        let index = linearIndex(of: coord)
        guard tiles[index].terrain != terrain else { return }
        tiles[index].terrain = terrain
        generation += 1

        // Rubbish cannot sit on grass a guest can no longer reach.
        if !tiles[index].isWalkable {
            clearLitter(at: coord)
        }
    }

    mutating func setBuilding(_ id: UUID?, on coords: [GridCoord]) {
        var changed = false
        for coord in coords where isInside(coord) {
            let index = linearIndex(of: coord)
            if tiles[index].buildingID != id {
                tiles[index].buildingID = id
                changed = true
            }
        }
        if changed { generation += 1 }
    }

    /// Lays down the starting entrance plus a short stub of path leading in.
    mutating func applyStartingLayout(pathLength: Int) {
        entranceCoord = GridCoord(width / 2, 0)
        setTerrain(.entrance, at: entranceCoord)
        for offset in 1...max(1, pathLength) {
            setTerrain(.path, at: GridCoord(entranceCoord.x, entranceCoord.y + offset))
        }
    }

    // MARK: - Litter

    func litter(at coord: GridCoord) -> Double {
        tile(at: coord)?.litter ?? 0
    }

    mutating func addLitter(_ amount: Double, at coord: GridCoord) {
        guard isInside(coord), amount > 0 else { return }
        let index = linearIndex(of: coord)
        guard tiles[index].isWalkable else { return }

        let before = tiles[index].litter
        let after = min(100, before + amount)
        guard after != before else { return }

        tiles[index].litter = after
        litterTotal += after - before
        litteredTiles.insert(coord)
        litterGeneration += 1
    }

    /// Removes up to `amount` of rubbish. Returns what is left on the tile.
    @discardableResult
    mutating func removeLitter(_ amount: Double, at coord: GridCoord) -> Double {
        guard isInside(coord) else { return 0 }
        let index = linearIndex(of: coord)
        let before = tiles[index].litter
        guard before > 0 else { return 0 }

        let after = max(0, before - amount)
        tiles[index].litter = after
        litterTotal -= before - after
        if after <= 0.5 {
            tiles[index].litter = 0
            litteredTiles.remove(coord)
        }
        litterGeneration += 1
        return tiles[index].litter
    }

    mutating func clearLitter(at coord: GridCoord) {
        removeLitter(100, at: coord)
    }

    /// 0-1, where 1 is spotless. Concentrated rubbish reads as much worse than
    /// the raw average would suggest, which matches how guests experience it.
    var cleanlinessScore: Double {
        let walkable = walkableTileCount
        guard walkable > 0 else { return 1 }
        let saturation = litterTotal / (Double(walkable) * 100)
        return SimMath.clamp(1 - saturation * 6, 0, 1)
    }

    // MARK: - Beauty

    func beauty(at coord: GridCoord) -> Double {
        guard isInside(coord) else { return 0 }
        return tiles[linearIndex(of: coord)].beauty
    }

    /// Average prettiness of the ground guests can actually stand on.
    /// Decorating the far corner of an empty field should not flatter the
    /// park rating, so unwalkable tiles are not counted.
    var beautyScore: Double {
        var total = 0.0
        var count = 0
        for tile in tiles where tile.isWalkable {
            total += tile.beauty
            count += 1
        }
        guard count > 0 else { return 0 }
        return SimMath.clamp(total / Double(count) / 100, 0, 1)
    }

    /// One thing that makes the ground around it prettier: a piece of
    /// scenery, or a tile of water.
    struct BeautySource {
        let rect: GridRect
        /// Prettiness on its own tile, 0-100.
        let beauty: Double
        /// How many tiles away the effect still reaches.
        let radius: Int

        /// Linear falloff is enough: the player needs to see that closer is
        /// better, not to have light modelled.
        func beauty(atDistance distance: Int) -> Double {
            guard distance <= radius else { return 0 }
            guard radius > 0 else { return beauty }
            return beauty * (1 - Double(distance) / Double(radius + 1))
        }
    }

    /// Rebuilds the whole beauty field from what is currently placed. Cheap
    /// enough to redo wholesale: it only runs when the player places or
    /// removes something, never per tick, and doing it this way means the
    /// field can never drift out of step with what is on the map.
    mutating func recomputeBeauty(from sources: [BeautySource]) {
        for index in tiles.indices {
            tiles[index].beauty = 0
        }

        for source in sources {
            let radius = source.radius
            let area = source.rect
            let minX = area.origin.x - radius
            let maxX = area.origin.x + area.size.width - 1 + radius
            let minY = area.origin.y - radius
            let maxY = area.origin.y + area.size.height - 1 + radius

            for y in minY...maxY {
                for x in minX...maxX {
                    let coord = GridCoord(x, y)
                    guard isInside(coord) else { continue }
                    let distance = area.chebyshevDistance(to: coord)
                    let contribution = source.beauty(atDistance: distance)
                    guard contribution > 0 else { continue }

                    // Overlapping sources stack with diminishing returns, so
                    // a wall of trees is worth less than spreading them out.
                    let index = linearIndex(of: coord)
                    let current = tiles[index].beauty
                    tiles[index].beauty = min(100, current + contribution * (1 - current / 100))
                }
            }
        }
    }

    /// Whether any tile touching this footprint is the given terrain.
    func touchesTerrain(_ terrain: TerrainType, around rect: GridRect) -> Bool {
        rect.adjacentCoords.contains { tile(at: $0)?.terrain == terrain }
    }

    /// Every tile of the given terrain. Used to fold water into the beauty
    /// field, and small enough to scan on demand rather than index.
    func coords(ofTerrain terrain: TerrainType) -> [GridCoord] {
        var result: [GridCoord] = []
        for index in tiles.indices where tiles[index].terrain == terrain {
            result.append(GridCoord(index % width, index / width))
        }
        return result
    }
}

extension ParkMap {
    /// Lenient decoding so saves written before litter existed still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = container.value(.width, or: Balance.mapWidth)
        height = container.value(.height, or: Balance.mapHeight)
        tiles = container.value(.tiles, or: Array(repeating: Tile(), count: width * height))
        generation = container.value(.generation, or: 0)
        litterGeneration = container.value(.litterGeneration, or: 0)
        entranceCoord = container.value(.entranceCoord, or: GridCoord(width / 2, 0))

        // Recomputed rather than trusted, so the index can never drift out of
        // step with the tiles themselves.
        var littered: Set<GridCoord> = []
        var total = 0.0
        for index in tiles.indices where tiles[index].litter > 0 {
            littered.insert(GridCoord(index % width, index / width))
            total += tiles[index].litter
        }
        litteredTiles = littered
        litterTotal = total
    }
}
