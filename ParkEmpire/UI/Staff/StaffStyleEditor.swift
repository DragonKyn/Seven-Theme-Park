import SwiftUI

/// Every colour a costume or an act can be painted. Wider than the park-wide
/// pickers, because a frog that can only be one of ten colours is not much
/// of a choice.
struct StaffColourPicker: View {
    let selected: ParkColour
    let onSelect: (ParkColour) -> Void

    private static let choices: [ParkColour] = [
        .red, .orange, .amber, .yellow, .lime, .green, .teal, .cyan, .blue,
        .indigo, .violet, .pink, .white, .cream, .sand, .brown, .slate, .charcoal
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 30), spacing: 8)], spacing: 8) {
            ForEach(Self.choices, id: \.rawValue) { colour in
                Button {
                    onSelect(colour)
                } label: {
                    Circle()
                        .fill(Color(ParkPalette.colour(colour)))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().strokeBorder(colour == selected ? Color.primary : Color.black.opacity(0.18),
                                                  lineWidth: colour == selected ? 3 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Picks an entertainer's act, or a mascot's costume and colours.
///
/// The same view hires somebody and changes them afterwards, so what is
/// offered when choosing and what can be changed later are never two lists.
struct StaffStyleEditor: View {
    let role: StaffRole
    @Binding var style: StaffStyle
    let uniform: ParkColour

    private var look: StaffLook { style.look(for: role) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch role {
            case .mascot:
                costumes
            case .entertainer:
                acts
            case .janitor, .mechanic, .security:
                EmptyView()
            }
        }
    }

    // MARK: - Mascots

    private var costumes: some View {
        VStack(alignment: .leading, spacing: 14) {
            portrait(for: look)

            Text("COSTUME")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)], spacing: 8) {
                ForEach(MascotCostume.allCases) { costume in
                    costumeButton(costume)
                }
            }

            let costume = look.costume
            colourRow("Fur or feathers", current: look.primary) { style.primary = $0 }
            colourRow(costume.secondaryLabel, current: look.secondary) { style.secondary = $0 }
            colourRow("Bow tie and shoes", current: look.trim) { style.trim = $0 }

            Button("Back to the original colours") {
                // One change, not three: see `costumeButton`.
                var next = style
                next.primary = nil
                next.secondary = nil
                next.trim = nil
                style = next
            }
            .font(.footnote.weight(.semibold))
        }
    }

    private func costumeButton(_ costume: MascotCostume) -> some View {
        let selected = look.costume == costume
        let sample = StaffStyle(costume: costume).look(for: .mascot)
        return Button {
            // A new costume comes in its own colours.
            //
            // All at once, as one change. Made one field at a time, each
            // change was built from the employee as the panel last saw them,
            // which is not yet the employee with the previous change in it, so
            // the second change put the old costume back.
            var next = style
            next.costume = costume
            next.primary = nil
            next.secondary = nil
            next.trim = nil
            style = next
        } label: {
            VStack(spacing: 2) {
                Image(uiImage: StaffArtwork.previewImage(for: sample, uniform: uniform,
                                                         size: CGSize(width: 126, height: 132)))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                Text(costume.displayName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(5)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(selected ? 0.25 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Entertainers

    private var acts: some View {
        VStack(alignment: .leading, spacing: 14) {
            portrait(for: look)

            Text("ACT")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                ForEach(EntertainerAct.allCases) { act in
                    actButton(act)
                }
            }

            Text(look.act.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if look.act.usesColour {
                colourRow(look.act.colourLabel, current: look.primary) { style.primary = $0 }
            }
        }
    }

    private func actButton(_ act: EntertainerAct) -> some View {
        let selected = look.act == act
        let sample = StaffStyle(act: act).look(for: .entertainer)
        return Button {
            var next = style
            next.act = act
            next.primary = nil
            style = next
        } label: {
            VStack(spacing: 2) {
                Image(uiImage: StaffArtwork.previewImage(for: sample, uniform: uniform,
                                                         size: CGSize(width: 126, height: 132)))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                Text(act.displayName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(5)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(selected ? 0.25 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pieces

    private func portrait(for look: StaffLook) -> some View {
        HStack {
            Spacer()
            Image(uiImage: StaffArtwork.previewImage(for: look, uniform: uniform,
                                                     size: CGSize(width: 252, height: 264)))
                .resizable()
                .scaledToFit()
                .frame(height: 120)
            Spacer()
        }
    }

    private func colourRow(_ title: String,
                           current: ParkColour,
                           onSelect: @escaping (ParkColour) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.secondary)
            StaffColourPicker(selected: current, onSelect: onSelect)
        }
    }
}

/// Choosing who to hire, for the two roles that come in more than one kind.
struct StaffHireSheet: View {
    let role: StaffRole
    @ObservedObject var controller: GameController
    @State private var style: StaffStyle
    @Environment(\.dismiss) private var dismiss

    init(role: StaffRole, controller: GameController) {
        self.role = role
        self.controller = controller
        switch role {
        case .mascot: _style = State(initialValue: StaffStyle(costume: .bear))
        case .entertainer: _style = State(initialValue: StaffStyle(act: .classic))
        case .janitor, .mechanic, .security: _style = State(initialValue: .standard)
        }
    }

    private var definition: StaffDefinition? { StaffContent.definition(for: role) }

    var body: some View {
        NavigationContainer {
            Form {
                Section {
                    StaffStyleEditor(role: role,
                                     style: $style,
                                     uniform: controller.state.uniformColour)
                        .padding(.vertical, 4)
                } footer: {
                    if let definition {
                        Text("\(CurrencyFormatter.short(definition.hiringCost)) to hire, then \(CurrencyFormatter.short(definition.dailyWage)) a day. You can change the look any time from their panel in the park.")
                    }
                }
            }
            .navigationTitle(role == .mascot ? "Hire a Mascot" : "Hire an Entertainer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hire") {
                        if controller.hireStaff(role: role, style: style) { dismiss() }
                    }
                    .font(.body.weight(.semibold))
                    .disabled(!controller.canHire(role: role))
                }
            }
        }
    }
}
