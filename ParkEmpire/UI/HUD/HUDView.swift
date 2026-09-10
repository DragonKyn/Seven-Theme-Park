import SwiftUI

/// Top bar: the four numbers that matter, plus the clock.
struct HUDView: View {
    let hud: HUDSnapshot
    let alertCount: Int
    let onOpenAlerts: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                MoneyPill(cash: hud.cash,
                          todayProfit: hud.todayProfit,
                          isUnlimited: hud.mode.hasUnlimitedMoney)
                StatPill(symbol: "person.2.fill", value: "\(hud.guestCount)")
                StatPill(symbol: "face.smiling",
                         value: "\(Int(hud.averageHappiness))%",
                         tint: Theme.happinessColour(hud.averageHappiness))

                Spacer(minLength: 0)

                Button(action: onOpenAlerts) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(7)
                            .background(Circle().fill(Theme.control))
                        if alertCount > 0 {
                            Circle()
                                .fill(Theme.danger)
                                .frame(width: 7, height: 7)
                                .offset(x: 1, y: -1)
                        }
                    }
                }

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(7)
                        .background(Circle().fill(Theme.control))
                }
            }

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(hud.parkName)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    StarRatingView(stars: hud.starRating)
                }

                Spacer(minLength: 0)

                StatPill(symbol: "star.fill", value: "\(Int(hud.parkRating))")
                StatPill(symbol: "ticket", value: CurrencyFormatter.short(hud.admissionPrice))
                StatPill(symbol: "clock", value: "Day \(hud.day) · \(hud.clockLabel)")
            }
        }
        .padding(8)
        .panelBackground()
    }
}
