import SwiftUI

struct FacilityInspectorView: View {
    let facility: FacilityDetail
    @ObservedObject var controller: GameController

    var body: some View {
        VStack(spacing: 10) {
            if facility.sellsGoods {
                SectionCard(title: "Pricing") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(CurrencyFormatter.exact(facility.price))
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(facility.sentimentText)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(sentimentColour)
                        }

                        Slider(value: Binding(
                            get: { facility.price },
                            set: { controller.setPrice($0, facilityID: facility.id) }
                        ), in: 0...max(facility.referencePrice * 3, 5), step: 0.5)
                        .tint(Theme.accent)

                        VStack(spacing: 5) {
                            StatRow(label: "Cost per item", value: CurrencyFormatter.exact(facility.unitCost))
                            StatRow(label: "Profit per sale",
                                    value: CurrencyFormatter.exact(facility.profitPerSale),
                                    tint: facility.profitPerSale > 0 ? Theme.accent : Theme.danger)
                            StatRow(label: "Guests think it is fair at",
                                    value: CurrencyFormatter.exact(facility.referencePrice))
                        }
                    }
                }
            }

            SectionCard(title: "Trade") {
                VStack(spacing: 5) {
                    StatRow(label: "Type", value: facility.typeName)
                    if let interest = controller.guestInterest(in: facility.id) {
                        StatRow(label: "Guests", value: interest)
                    }
                    StatRow(label: "Queue", value: "\(facility.queueLength) waiting")
                    StatRow(label: "Customers today", value: "\(facility.customersToday)")
                    StatRow(label: "Customers all time", value: "\(facility.totalCustomers)")
                    if facility.isGame {
                        StatRow(label: "Prizes given", value: "\(facility.prizesGiven)")
                    }
                    if facility.sellsGoods {
                        StatRow(label: "Revenue today", value: CurrencyFormatter.short(facility.revenueToday))
                        StatRow(label: "Revenue all time", value: CurrencyFormatter.short(facility.totalRevenue))
                        StatRow(label: "Stock cost all time", value: CurrencyFormatter.short(facility.totalCost))
                        StatRow(label: "Gross profit",
                                value: CurrencyFormatter.signed(facility.totalRevenue - facility.totalCost),
                                tint: facility.totalRevenue - facility.totalCost >= 0 ? Theme.accent : Theme.danger)
                    }
                }
            }

            Button {
                controller.setFacilityOpen(!facility.isOpen, facilityID: facility.id)
            } label: {
                Label(facility.isOpen ? "Close" : "Open",
                      systemImage: facility.isOpen ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(facility.isOpen ? Theme.danger.opacity(0.85) : Theme.accent)
                    )
                    .foregroundStyle(.black)
            }
        }
    }

    private var sentimentColour: Color {
        guard let sentiment = facility.sentiment else { return Theme.textSecondary }
        switch sentiment {
        case ..<0.4: return Theme.danger
        case ..<0.65: return Theme.accentWarm
        default: return Theme.accent
        }
    }
}
