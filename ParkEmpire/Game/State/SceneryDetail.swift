import Foundation

/// What the scenery panel shows and offers for one placed decoration.
struct SceneryDetail: Identifiable {
    let id: UUID
    let name: String
    let variant: Int
    let styleCount: Int
    let colour: ParkColour?
    let colourChoices: [ParkColour]
    /// How it looks now, so the style buttons can show each alternative in
    /// the colours it is actually painted in.
    let appearance: BuildingAppearance

    init(item: SceneryItem, scheme: ParkScheme) {
        let definition = item.definition
        let base = definition?.appearance ?? .unknown

        id = item.id
        name = definition?.displayName ?? "Decoration"
        variant = item.variant
        styleCount = base.motif.variantCount
        colour = item.colour
        colourChoices = base.motif.colourChoices
        appearance = base.tinted(item.colour).applying(scheme)
    }
}
