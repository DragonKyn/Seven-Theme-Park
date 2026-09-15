import Foundation

/// A map the player drew.
struct CustomMap: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var layout: MapLayout
    var savedAt: Date = Date()

    /// How it appears alongside the maps that ship with the game.
    var blueprint: MapBlueprint {
        MapBlueprint(id: "custom.\(id.uuidString)",
                     name: name,
                     summary: "Your own map. \(Int(buildableShare * 100))% of it can be built on.",
                     difficulty: estimatedDifficulty,
                     layout: layout,
                     isCustom: true)
    }

    private var buildableShare: Double {
        Double(layout.buildableCount) / Double(max(1, layout.ground.count))
    }

    /// A guess from how much land there is. Crude, and good enough for a row
    /// of dots: less room is harder, whatever shape it comes in.
    private var estimatedDifficulty: Int {
        switch buildableShare {
        case 0.75...: return 1
        case 0.55...: return 2
        case 0.40...: return 3
        case 0.25...: return 4
        default: return 5
        }
    }
}

extension CustomMap {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.value(.id, or: UUID())
        name = container.value(.name, or: "My Map")
        layout = container.value(.layout, or: MapLayout())
        savedAt = container.value(.savedAt, or: Date())
    }
}

/// Keeps the player's maps in a file of their own, apart from the parks.
///
/// Maps outlive parks: deleting the park built on a map should not take the
/// map with it, and a map is something you build several parks on.
final class CustomMapStore {

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var fileURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents
            .appendingPathComponent("Maps", isDirectory: true)
            .appendingPathComponent("custom-maps.json")
    }

    func load() -> [CustomMap] {
        guard let data = try? Data(contentsOf: fileURL),
              let maps = try? decoder.decode([CustomMap].self, from: data) else { return [] }
        return maps.sorted { $0.savedAt > $1.savedAt }
    }

    func save(_ maps: [CustomMap]) throws {
        let directory = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let data = try encoder.encode(maps)
        try data.write(to: fileURL, options: .atomic)
    }
}
