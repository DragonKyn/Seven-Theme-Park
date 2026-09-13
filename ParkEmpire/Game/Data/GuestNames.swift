import Foundation

/// Generic given/family name pools used to make guests feel individual.
enum GuestNames {
    private static let given = [
        "Ada", "Bo", "Cleo", "Dev", "Elin", "Fabi", "Gus", "Hana", "Ivo", "Jo",
        "Kai", "Lena", "Mila", "Nils", "Ola", "Pia", "Quin", "Rafa", "Sami", "Tova",
        "Uma", "Vik", "Wren", "Xan", "Yara", "Zeke", "Ines", "Otto", "Nora", "Theo"
    ]

    private static let family = [
        "Alder", "Brook", "Calder", "Dunn", "Ember", "Frost", "Garrow", "Hollis",
        "Ingram", "Jessup", "Kerr", "Lowry", "Marsh", "Nyland", "Orrick", "Pike",
        "Quist", "Rowe", "Sable", "Thorne", "Vance", "Wilde", "Yates", "Zell"
    ]

    /// Parties that turn up by the coachload. Built from the same family
    /// names as the guests themselves, so a park's cast hangs together.
    private static let coachGroups = [
        "Alderbrook Primary", "The Hollis Day Centre", "Marsh Lane Scouts",
        "Pike Street Youth Club", "The Rowe Family Reunion", "Thorne Valley School",
        "Kerr Road Nursery", "The Wilde Society", "Vance College", "Sable Park Guides",
        "Frost Hill Juniors", "The Ingram Walking Club"
    ]

    static func coachGroup(using generator: inout SeededGenerator) -> String {
        generator.pick(coachGroups) ?? "A day out"
    }

    static func random(using generator: inout SeededGenerator) -> String {
        let first = generator.pick(given) ?? "Guest"
        let last = generator.pick(family) ?? "Visitor"
        return "\(first) \(last)"
    }
}
