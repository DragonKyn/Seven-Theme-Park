import SwiftUI

/// A strip of map cards: every premade map, every map the player has drawn,
/// and a card for drawing a new one.
struct MapPickerView: View {
    let maps: [MapBlueprint]
    @Binding var selectedID: String
    let onCreate: () -> Void
    let onEdit: (MapBlueprint) -> Void
    let onDelete: (MapBlueprint) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(maps) { map in
                    MapCard(map: map, isSelected: map.id == selectedID)
                        .onTapGesture { selectedID = map.id }
                        .contextMenu {
                            if map.isCustom {
                                Button("Edit map", systemImage: "pencil") { onEdit(map) }
                                Button("Delete map", systemImage: "trash", role: .destructive) {
                                    onDelete(map)
                                }
                            }
                        }
                }

                Button(action: onCreate) {
                    VStack(spacing: 8) {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 26, weight: .semibold))
                        Text("Draw your own")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text("Paint water, rock and forest, and put the gate where you like.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: 128, height: 206)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.6),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
    }
}

/// One map: its shape, its name, how awkward it is, and what it is like.
struct MapCard: View {
    let map: MapBlueprint
    let isSelected: Bool
    var width: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(uiImage: MapArtwork.thumbnail(for: map.layout, side: width * 2))
                .resizable()
                .interpolation(.none)
                .frame(width: width - 12, height: width - 12)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 4) {
                Text(map.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if map.isCustom {
                    Image(systemName: "person.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            DifficultyDots(level: map.difficulty)

            Text(map.summary)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(width: width, height: 218, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Five dots, filled as far as the difficulty goes.
struct DifficultyDots: View {
    let level: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= level ? colour : Color.secondary.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 2)
        }
    }

    private var colour: Color {
        switch level {
        case ...2: return .green
        case 3: return .orange
        default: return .red
        }
    }

    private var label: String {
        switch level {
        case ...1: return "Easy"
        case 2: return "Gentle"
        case 3: return "Awkward"
        case 4: return "Hard"
        default: return "Brutal"
        }
    }
}
