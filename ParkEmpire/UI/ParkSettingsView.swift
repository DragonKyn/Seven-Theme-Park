import SwiftUI

/// Park-wide settings: the gate price, which is the single biggest lever the
/// player has over demand, and the staff uniform.
struct ParkSettingsView: View {
    @ObservedObject var controller: GameController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Admission price") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(CurrencyFormatter.short(controller.hud.admissionPrice))
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))

                        Slider(value: Binding(
                            get: { controller.hud.admissionPrice },
                            set: { controller.setAdmissionPrice($0) }
                        ), in: 0...Balance.admissionPriceMax, step: 1)

                        Text(demandAdvice)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Staff uniform") {
                    VStack(alignment: .leading, spacing: 10) {
                        UniformPicker(selected: controller.state.uniformColour) {
                            controller.setUniformColour($0)
                        }
                        Text("Every employee wears this. Their hat and their tools still say which job they do.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                Section("Right now") {
                    LabeledContent("Arrivals",
                                   value: String(format: "%.1f guests per minute", controller.hud.arrivalsPerMinute))
                    LabeledContent("Guests in park", value: "\(controller.hud.guestCount)")
                    LabeledContent("Park rating", value: "\(Int(controller.hud.parkRating)) / 100")
                }

                Section {
                    Text("Guests judge the gate price against how much there is to do. Add rides and raise your rating before you raise the price.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Park Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var demandAdvice: String {
        let acceptable = GuestEconomics.acceptableAdmission(
            attractionCount: controller.state.attractions.count,
            parkRating: controller.state.parkRating)
        let willingness = GuestEconomics.admissionWillingness(price: controller.hud.admissionPrice,
                                                              acceptable: acceptable)
        switch willingness {
        case ..<0.15: return "Almost nobody thinks this park is worth the price."
        case ..<0.4: return "Most people are turned away by this price."
        case ..<0.7: return "A fair price for what the park offers right now."
        default: return "Great value — expect a steady stream of visitors."
        }
    }
}

/// A row of swatches. Deliberately a fixed shortlist rather than the full
/// palette: every colour here has to stay legible on a small figure against
/// grass, and most of the palette does not.
private struct UniformPicker: View {
    let selected: ParkColour
    let onSelect: (ParkColour) -> Void

    private static let choices: [ParkColour] = [
        .teal, .blue, .indigo, .violet, .red, .orange, .amber, .green, .charcoal, .cream
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Self.choices, id: \.rawValue) { colour in
                Button {
                    onSelect(colour)
                } label: {
                    Circle()
                        .fill(Color(ParkPalette.colour(colour)))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().strokeBorder(colour == selected ? Color.primary : Color.black.opacity(0.15),
                                                  lineWidth: colour == selected ? 3 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
