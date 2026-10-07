import SwiftUI

/// What can be changed about a decoration once it is standing: which cut of
/// the shape it is, what colour, and which way it faces.
struct SceneryInspectorView: View {
    let item: SceneryDetail
    @ObservedObject var controller: GameController

    var body: some View {
        VStack(spacing: 10) {
            if item.styleCount > 1 {
                SectionCard(title: "Style") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(0..<item.styleCount), id: \.self) { index in
                                styleButton(index)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !item.colourChoices.isEmpty {
                SectionCard(title: "Colour") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            classicButton
                            ForEach(item.colourChoices, id: \.rawValue) { colour in
                                colourButton(colour)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Button {
                controller.turnSelected()
            } label: {
                Label("Turn", systemImage: "rotate.right")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.accentWarm)
                    )
                    .foregroundStyle(.black)
            }
        }
    }

    private func styleButton(_ index: Int) -> some View {
        let selected = item.variant % item.styleCount == index
        return Button {
            controller.setSceneryStyle(index)
        } label: {
            Image(uiImage: BuildingArtwork.previewImage(
                for: item.appearance.withVariant(index),
                size: CGSize(width: 80, height: 80)))
                .resizable()
                .frame(width: 40, height: 40)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Theme.control)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(selected ? Theme.accent : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    /// The colours the piece was designed in.
    private var classicButton: some View {
        Button {
            controller.setSceneryColour(nil)
        } label: {
            Text("Classic")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 10)
                .frame(height: 30)
                .foregroundStyle(item.colour == nil ? Color.black : Theme.textPrimary)
                .background(Capsule().fill(item.colour == nil ? Theme.accent : Theme.control))
        }
        .buttonStyle(.plain)
    }

    private func colourButton(_ colour: ParkColour) -> some View {
        let selected = item.colour == colour
        return Button {
            controller.setSceneryColour(colour)
        } label: {
            Circle()
                .fill(Color(ParkPalette.colour(colour)))
                .frame(width: 28, height: 28)
                .overlay(
                    Circle().stroke(selected ? Theme.accent : Color.white.opacity(0.35),
                                    lineWidth: selected ? 3 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
