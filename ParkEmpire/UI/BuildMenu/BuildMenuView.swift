import SwiftUI

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
        GameContent.buildables(in: controller.build.category,
                               unlockLevel: controller.state.unlockLevel)
            .map { BuildItem(id: $0.id, definition: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(BuildCategory.allCases) { category in
                    Button {
                        controller.enterBuildMode(category: category)
                    } label: {
                        Label(category.displayName, systemImage: category.symbolName)
                            .labelStyle(.iconOnly)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 40, height: 32)
                            .foregroundStyle(isSelected(category) ? Color.black : Theme.textPrimary)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected(category) ? Theme.accent : Color.white.opacity(0.10))
                            )
                    }
                }

                Spacer(minLength: 0)

                Button {
                    controller.enterDemolishMode()
                } label: {
                    Label("Remove", systemImage: "trash.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .foregroundStyle(controller.build.isDemolishing ? Color.black : Theme.textPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(controller.build.isDemolishing ? Theme.danger : Color.white.opacity(0.10))
                        )
                }
            }

            if !controller.build.isDemolishing {
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
                }
                .frame(height: 78)
            }

            Text(hintText)
                .font(.caption2)
                .foregroundStyle(hintIsError ? Theme.danger : Theme.textSecondary)
        }
        .padding(10)
        .panelBackground()
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
        if controller.selectedDefinition?.category == .path {
            return "Tap to place a walkway, or drag one finger to draw a run. Two fingers move the map."
        }
        return "Tap the map to place. Buildings must touch a walkway."
    }
}

private struct BuildItemCard: View {
    let definition: BuildableDefinition
    let isSelected: Bool
    let affordable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
            .frame(width: 108, alignment: .leading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Theme.accent : .clear, lineWidth: 2)
            )
            .foregroundStyle(Theme.textPrimary)
        }
    }
}
