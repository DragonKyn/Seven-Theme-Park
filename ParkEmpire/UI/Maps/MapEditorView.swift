import SwiftUI

/// Draw a map: paint the ground with a finger, choose where the gate goes,
/// and name it.
struct MapEditorView: View {
    @StateObject private var model: MapEditorModel
    let onSave: (CustomMap) -> Void
    @Environment(\.dismiss) private var dismiss

    /// Whether the current drag has already been recorded for undo.
    @State private var strokeStarted = false

    init(editing map: CustomMap? = nil, onSave: @escaping (CustomMap) -> Void) {
        _model = StateObject(wrappedValue: MapEditorModel(editing: map))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Map name", text: $model.name)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)

                    canvas

                    tools

                    if case .paint = model.tool {
                        brushSizes
                    }

                    actions

                    status
                }
                .padding(16)
            }
            .scrollDisabled(true)
            .navigationTitle("Draw a Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let map = model.makeMap() else { return }
                        onSave(map)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(model.problem != nil)
                }
            }
        }
    }

    // MARK: - The map

    private var canvas: some View {
        GeometryReader { geometry in
            let side = geometry.size.width
            Canvas { context, size in
                context.withCGContext { cg in
                    MapArtwork.draw(model.layout, in: cg, size: size)
                }
                drawGateApproach(in: &context, size: size)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !strokeStarted {
                            model.beginStroke()
                            strokeStarted = true
                        }
                        paint(at: value.location, side: side)
                    }
                    .onEnded { _ in strokeStarted = false }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// The clear strip in front of the gate, outlined so it is obvious that
    /// painting there does nothing and why.
    private func drawGateApproach(in context: inout GraphicsContext, size: CGSize) {
        let layout = model.layout
        let cellWidth = size.width / CGFloat(layout.width)
        let cellHeight = size.height / CGFloat(layout.height)
        let rect = CGRect(x: CGFloat(layout.entranceX - 1) * cellWidth,
                          y: size.height - CGFloat(MapLayout.clearance + 1) * cellHeight,
                          width: cellWidth * 3,
                          height: CGFloat(MapLayout.clearance + 1) * cellHeight)
        context.stroke(Path(rect),
                       with: .color(.white.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
    }

    private func paint(at location: CGPoint, side: CGFloat) {
        let layout = model.layout
        guard location.x >= 0, location.y >= 0, location.x < side, location.y < side else { return }
        let x = Int(location.x / side * CGFloat(layout.width))
        // Screen rows run downward; map rows count up from the gate.
        let y = layout.height - 1 - Int(location.y / side * CGFloat(layout.height))
        model.apply(atX: x, y: y)
    }

    // MARK: - Controls

    private var tools: some View {
        HStack(spacing: 8) {
            ForEach(MapGround.allCases) { ground in
                toolButton(title: ground.displayName,
                           isSelected: model.tool == .paint(ground)) {
                    model.tool = .paint(ground)
                } swatch: {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color(MapArtwork.colour(for: ground)))
                        .frame(width: 26, height: 26)
                }
            }

            toolButton(title: "Gate", isSelected: model.tool == .gate) {
                model.tool = .gate
            } swatch: {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(MapArtwork.gate))
                    .frame(width: 26, height: 26)
            }
        }
    }

    private func toolButton<Swatch: View>(title: String,
                                          isSelected: Bool,
                                          action: @escaping () -> Void,
                                          @ViewBuilder swatch: () -> Swatch) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                swatch()
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var brushSizes: some View {
        HStack {
            Text("Brush")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("Brush", selection: $model.brushRadius) {
                Text("Fine").tag(MapEditorModel.brushRadii[0])
                Text("Small").tag(MapEditorModel.brushRadii[1])
                Text("Medium").tag(MapEditorModel.brushRadii[2])
                Text("Large").tag(MapEditorModel.brushRadii[3])
            }
            .pickerStyle(.segmented)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                model.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!model.canUndo)

            Spacer()

            Menu {
                Button("Blank grass") { model.start(from: nil) }
                Divider()
                ForEach(MapCatalogue.all) { blueprint in
                    Button(blueprint.name) { model.start(from: blueprint) }
                }
            } label: {
                Label("Start from", systemImage: "square.on.square")
            }
        }
        .font(.subheadline.weight(.semibold))
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(gateHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let problem = model.problem {
                Label(problem, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.orange)
            } else {
                Label("\(model.buildableTiles) tiles of open grass. Ready to save.",
                      systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    private var gateHint: String {
        switch model.tool {
        case .gate:
            return "Tap along the bottom edge to move the gate. The dashed strip in front of it always stays open."
        case .paint:
            return "Drag to paint. Water can be bridged in the park; rock and forest can never be built on."
        }
    }
}
