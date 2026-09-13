import SwiftUI

/// Top bar: the four numbers that matter, plus the clock.
struct HUDView: View {
    let hud: HUDSnapshot
    let alertCount: Int
    let onOpenFinance: () -> Void
    let onOpenAlerts: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                // The number people tap when they want to know where it went.
                Button(action: onOpenFinance) {
                    MoneyPill(cash: hud.cash,
                              todayProfit: hud.todayProfit,
                              isUnlimited: hud.mode.hasUnlimitedMoney)
                }
                .buttonStyle(.plain)
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

                // Named, because a bare gear in the corner of a game reads as
                // the app's settings. Everything behind it is the park's: the
                // gate price, the car park, the colours, the uniform.
                Button(action: onOpenSettings) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Park")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 9)
                    .frame(height: 28)
                    .background(Capsule().fill(Theme.control))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Park settings")
            }

            HStack(spacing: 8) {
                // The park's own name opens the park's own settings. It is
                // the most obvious thing on screen to tap when you want to
                // change something about your park, so it should do that.
                Button(action: onOpenSettings) {
                    HStack(spacing: 4) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(hud.parkName)
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            StarRatingView(stars: hud.starRating)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens park settings")

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
