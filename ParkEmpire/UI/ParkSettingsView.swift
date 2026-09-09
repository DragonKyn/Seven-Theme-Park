import SwiftUI

/// Park-wide settings. For now that means the gate price, which is the single
/// biggest lever the player has over demand.
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
