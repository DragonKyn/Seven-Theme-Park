import SwiftUI
import UIKit

/// Category tabs plus the placeable items in the chosen category.
struct BuildMenuView: View {
    @ObservedObject var controller: GameController

    /// Concrete `Identifiable` wrapper: `ForEach` cannot key off a key path
    /// rooted in a protocol existential.
    private struct BuildItem: Identifiable {
        let id: String
        let definition: BuildableDefinition
    }

    private var items: [BuildItem] {
        controller.buildables(in: controller.build.category)
            .map { BuildItem(id: $0.id, definition: $0) }
    }

    var body: some View {
        Group {
            if let definition = controller.pendingDefinition {
                PlacementConfirmBar(controller: controller, definition: definition)
                    .padding(10)
                    .panelBackground()
            } else {
                catalogue
            }
        }
    }

    private var catalogue: some View {
        VStack(alignment: .leading, spacing: 9) {
            toolRow
            categoryGrid

            if !controller.build.isDemolishing && controller.build.category == .attraction {
                rideGroups
            }

            if !controller.build.isDemolishing {
                itemStrip
            }

            if !controller.build.isDemolishing && controller.styleCount > 1 {
                styleChips
            }

            Text(hintText)
                .font(.caption2)
                .foregroundStyle(hintIsError ? Theme.danger : Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .panelBackground()
    }

    /// The heading, and the two things that are not categories.
    ///
    /// Draw and Remove used to sit on the end of the category row looking like
    /// two more categories. They are tools, they change what a tap on the map
    /// does, and they belong somewhere the eye reads as a different kind of
    /// control.
    private var toolRow: some View {
        HStack(spacing: 6) {
            Text(controller.build.isDemolishing
                 ? "REMOVING"
                 : controller.build.category.displayName.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(controller.build.isDemolishing ? Theme.danger : Theme.textSecondary)

            if !controller.build.isDemolishing && !items.isEmpty {
                Text("\(items.count)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Theme.control))
            }

            Spacer(minLength: 0)

            if controller.canDraw {
                toolChip(title: "Draw",
                         symbol: controller.build.isDrawing ? "hand.draw.fill" : "hand.draw",
                         active: controller.build.isDrawing,
                         activeTint: Theme.accentWarm,
                         restTint: Theme.textPrimary) {
                    controller.toggleDrawing()
                }
            }

            toolChip(title: "Remove",
                     symbol: "trash.fill",
                     active: controller.build.isDemolishing,
                     activeTint: Theme.danger,
                     // Red at rest as well as when active, so the one
                     // destructive control never reads as another category.
                     restTint: Theme.danger) {
                controller.enterDemolishMode()
            }
        }
    }

    private func toolChip(title: String,
                          symbol: String,
                          active: Bool,
                          activeTint: Color,
                          restTint: Color,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(active ? Color.black : restTint)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Capsule().fill(active ? activeTint : Theme.control))
        }
        .buttonStyle(.plain)
    }

    /// Every category, named, on screen at once.
    ///
    /// They used to be a scrolling row of unlabelled icons, which hid half the
    /// game: players who never thought to swipe never found coasters, games or
    /// scenery, and an icon on its own does not say what it opens. Four across
    /// and two down fits a phone with the names showing, and nothing is behind
    /// a gesture nobody knows to make.
    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                  spacing: 6) {
            ForEach(BuildCategory.allCases) { category in
                Button {
                    controller.enterBuildMode(category: category)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: category.symbolName)
                            .font(.system(size: 15, weight: .semibold))
                        Text(category.shortName)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .foregroundStyle(isSelected(category) ? Color.black : Theme.textPrimary)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(isSelected(category) ? Theme.accent : Theme.control)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// The things in the chosen category.
    ///
    /// Masked so the last card fades out at the edge rather than being cut in
    /// half. A card sliced cleanly by the panel edge looks like the end of the
    /// list; one fading out looks like there is more, which there is.
    private var itemStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    BuildItemCard(
                        definition: item.definition,
                        isSelected: controller.build.selectedID == item.id,
                        affordable: controller.hud.cash >= item.definition.purchasePrice
                    ) {
                        controller.select(definitionID: item.id)
                    }
                }
            }
            .padding(.vertical, 2)
            .padding(.trailing, 12)
        }
        .frame(height: 82)
        .mask(
            LinearGradient(stops: [.init(color: .black, location: 0),
                                   .init(color: .black, location: 0.92),
                                   .init(color: .black.opacity(0), location: 1)],
                           startPoint: .leading,
                           endPoint: .trailing)
        )
    }

    /// Which cut of the selected thing to build.
    ///
    /// Mixed is the default and the point: one catalogue entry draws four
    /// different trees, so an avenue planted without thinking about it looks
    /// planted rather than stamped. Picking a style is for when the player
    /// wants a matching row.
    private var styleChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                styleChip(nil, title: "Mixed")
                ForEach(Array(0..<controller.styleCount), id: \.self) { index in
                    styleChip(index, title: "Style \(index + 1)")
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func styleChip(_ variant: Int?, title: String) -> some View {
        let selected = controller.build.variant == variant
        return Button {
            controller.chooseStyle(variant)
        } label: {
            HStack(spacing: 4) {
                if let variant, let appearance = controller.selectedDefinition?.previewAppearance {
                    Image(uiImage: BuildingArtwork.previewImage(
                        for: appearance.withVariant(variant),
                        size: CGSize(width: 60, height: 60)))
                        .resizable()
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "shuffle")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 9)
            .frame(height: 26)
            .foregroundStyle(selected ? Color.black : Theme.textPrimary)
            .background(Capsule().fill(selected ? Theme.accent : Theme.control))
        }
        .buttonStyle(.plain)
    }

    /// A second shelf of chips inside the ride list. The list of rides only
    /// gets longer, and "everything with a queue" stops being a useful
    /// heading somewhere around a dozen.
    private var rideGroups: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                groupChip(nil, title: "All", symbol: "square.grid.2x2.fill")
                ForEach(RideGroup.allCases) { group in
                    groupChip(group, title: group.displayName, symbol: group.symbolName)
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func groupChip(_ group: RideGroup?, title: String, symbol: String) -> some View {
        let selected = controller.build.rideGroup == group
        return Button {
            controller.showRideGroup(group)
        } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 9)
                .frame(height: 26)
                .foregroundStyle(selected ? Color.black : Theme.textPrimary)
                .background(
                    Capsule().fill(selected ? Theme.accent : Theme.control)
                )
        }
    }

    private func isSelected(_ category: BuildCategory) -> Bool {
        !controller.build.isDemolishing && controller.build.category == category
    }

    private var hintIsError: Bool {
        controller.build.ghost != nil && !controller.build.ghostValid
    }

    private var hintText: String {
        if controller.build.isDemolishing {
            return "Tap anything you want to remove. Walkways refund a little; rides refund half."
        }
        if let reason = controller.build.ghostReason, controller.build.ghost != nil {
            return reason
        }
        if controller.build.isDrawing {
            return "Drawing: drag one finger to lay a run. Two fingers move the map."
        }
        if controller.canDraw {
            let name = controller.selectedDefinition?.displayName.lowercased() ?? "this"
            return "Tap to place \(name). Drag moves the map. Turn on Draw to lay a run."
        }
        if controller.build.category == .transport {
            return "Drag out a loop of track, then put stations on it. Guests ride between them."
        }
        if controller.build.category == .coaster {
            return "Drag out a circuit of track, drop elements on to it, then put a station beside it."
        }
        if controller.build.category == .scenery {
            return "Tap open ground to decorate. Guests are happier near it, and the rating notices."
        }
        return "Tap the map to line something up. You can turn it and check it before paying."
    }
}

private struct BuildItemCard: View {
    let definition: BuildableDefinition
    let isSelected: Bool
    let affordable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 7) {
                thumbnail

                VStack(alignment: .leading, spacing: 3) {
                    Text(definition.displayName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text(CurrencyFormatter.short(definition.purchasePrice))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(affordable ? Theme.accent : Theme.danger)
                    Text("\(definition.footprint.width)×\(definition.footprint.height) tiles")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 142, alignment: .leading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.11))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Theme.accent : .clear, lineWidth: 2)
            )
            .foregroundStyle(Theme.textPrimary)
        }
    }

    /// The same artwork the map draws, so what you pick is what you get.
    @ViewBuilder
    private var thumbnail: some View {
        if let element = definition as? CoasterElementDefinition {
            // Elements are wide and thin, so the thumbnail keeps their shape
            // rather than squaring them off into a smudge.
            Image(uiImage: CoasterElementArtwork.previewImage(
                for: element.motif,
                size: CGSize(width: CGFloat(element.footprint.width) * 44,
                             height: CGFloat(element.visualHeight) * 44),
                trackY: element.trackLine))
                .resizable()
                .frame(width: CGFloat(element.footprint.width) * 11,
                       height: CGFloat(element.visualHeight) * 11)
        } else if let appearance = definition.previewAppearance {
            Image(uiImage: BuildingArtwork.previewImage(
                for: appearance,
                size: CGSize(width: BuildItemCard.thumbnailSide,
                             height: BuildItemCard.thumbnailSide)))
                .resizable()
                .frame(width: 38, height: 38)
        } else if let terrain = definition as? TerrainDefinition {
            // The actual tile. Every walkway used to show as the same white
            // square, so choosing between paving, brick and boards meant
            // paying first and finding out afterwards.
            Image(uiImage: TerrainArtwork.previewImage(
                terrain: terrain.terrain,
                style: terrain.style,
                size: CGSize(width: BuildItemCard.thumbnailSide,
                             height: BuildItemCard.thumbnailSide)))
                .resizable()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.2))
                .frame(width: 38, height: 38)
        }
    }

    /// Rendered larger than it is shown so the artwork stays crisp on a
    /// high-density screen.
    static let thumbnailSide: CGFloat = 114
}

/// Shown while a placement is lined up but not yet paid for: what it is,
/// what it costs, which way round it is, and the three things the player can
/// do about it.
struct PlacementConfirmBar: View {
    @ObservedObject var controller: GameController
    let definition: BuildableDefinition

    private var check: PlacementCheck? { controller.pendingCheck }
    private var isValid: Bool { check?.isValid ?? false }
    private var affordable: Bool { controller.hud.cash >= definition.purchasePrice }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                thumbnail

                VStack(alignment: .leading, spacing: 2) {
                    Text(definition.displayName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(CurrencyFormatter.short(definition.purchasePrice))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(affordable ? Theme.money : Theme.danger)
                        Text("\(controller.pendingFootprint.width)×\(controller.pendingFootprint.height) tiles")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer(minLength: 0)
            }

            positionControls

            Text(hint)
                .font(.caption2)
                .foregroundStyle(isValid ? Theme.textSecondary : Theme.danger)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    controller.cancelPending()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.control)
                        )
                        .foregroundStyle(Theme.textPrimary)
                }

                Button {
                    controller.confirmPending()
                } label: {
                    Label("Build it", systemImage: "hammer.fill")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isValid ? Theme.accent : Theme.control)
                        )
                        .foregroundStyle(isValid ? Color.black : Theme.textSecondary)
                }
                .disabled(!isValid)
            }
        }
    }

    /// Sliding and turning, side by side.
    ///
    /// A building is placed by its bottom-left corner, so a tap a tile out is
    /// easy to make and used to mean starting again. These shunt it a tile at
    /// a time; dragging it around the map does the same thing coarsely.
    private var positionControls: some View {
        HStack(spacing: 6) {
            ForEach(Self.nudges) { nudge in
                Button {
                    controller.nudgePending(dx: nudge.dx, dy: nudge.dy)
                } label: {
                    Image(systemName: nudge.symbol)
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 38, height: 34)
                        .foregroundStyle(Theme.textPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Theme.control)
                        )
                }
            }

            Spacer(minLength: 0)

            if definition.canRotate {
                Button {
                    controller.rotatePending()
                } label: {
                    Label("Turn", systemImage: "rotate.right")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .foregroundStyle(Color.black)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Theme.accentWarm)
                        )
                }
            }
        }
    }

    /// Up is north, which is up the screen: the map is drawn with north at the
    /// top, so an arrow means what it points at.
    private struct Nudge: Identifiable {
        let symbol: String
        let dx: Int
        let dy: Int
        var id: String { symbol }
    }

    private static let nudges: [Nudge] = [
        Nudge(symbol: "arrow.left", dx: -1, dy: 0),
        Nudge(symbol: "arrow.down", dx: 0, dy: -1),
        Nudge(symbol: "arrow.up", dx: 0, dy: 1),
        Nudge(symbol: "arrow.right", dx: 1, dy: 0)
    ]

    @ViewBuilder
    private var thumbnail: some View {
        if let appearance = definition.previewAppearance {
            Image(uiImage: BuildingArtwork.previewImage(
                for: appearance,
                size: CGSize(width: 120, height: 120)))
                .resizable()
                .frame(width: 40, height: 40)
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.control)
                .frame(width: 40, height: 40)
        }
    }

    private var hint: String {
        if let reason = check?.reason { return reason }
        return "Drag it around the map or nudge it a tile at a time. Two fingers move the map."
    }
}

