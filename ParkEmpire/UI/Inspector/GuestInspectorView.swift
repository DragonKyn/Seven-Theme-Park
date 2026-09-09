import SwiftUI

/// What one guest is feeling, doing and thinking. Watching this is meant to
/// explain the park back to the player.
struct GuestInspectorView: View {
    let guest: GuestDetail

    var body: some View {
        VStack(spacing: 10) {
            SectionCard(title: "Right now") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(guest.activityText)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)

                    HStack(spacing: 10) {
                        StatPill(symbol: "face.smiling",
                                 value: "\(Int(guest.happiness))%",
                                 tint: Theme.happinessColour(guest.happiness))
                        StatPill(symbol: "wallet.bifold", value: CurrencyFormatter.short(guest.cash))
                        StatPill(symbol: "clock", value: guest.timeInParkText)
                    }
                }
            }

            SectionCard(title: "Needs") {
                VStack(spacing: 8) {
                    MeterBar(label: "Hunger", value: guest.hunger, tint: Theme.needColour(guest.hunger))
                    MeterBar(label: "Thirst", value: guest.thirst, tint: Theme.needColour(guest.thirst))
                    MeterBar(label: "Restroom", value: guest.bathroomNeed, tint: Theme.needColour(guest.bathroomNeed))
                    MeterBar(label: "Nausea", value: guest.nausea, tint: Theme.needColour(guest.nausea))
                    MeterBar(label: "Energy", value: guest.energy, tint: Theme.happinessColour(guest.energy))
                }
            }

            SectionCard(title: "Recent thoughts") {
                if guest.thoughts.isEmpty {
                    Text("Nothing on their mind yet.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(guest.thoughts.prefix(5)) { thought in
                            HStack(alignment: .top, spacing: 6) {
                                Circle()
                                    .fill(colour(for: thought.mood))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 5)
                                Text(thought.text)
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textPrimary.opacity(0.9))
                            }
                        }
                    }
                }
            }

            SectionCard(title: "This visit") {
                VStack(spacing: 5) {
                    StatRow(label: "Visitor", value: guest.ageCategory)
                    StatRow(label: "Rides experienced", value: "\(guest.ridesRidden)")
                    StatRow(label: "Purchases", value: "\(guest.purchases)")
                    StatRow(label: "Money spent", value: CurrencyFormatter.exact(guest.moneySpent))
                }
            }

            SectionCard(title: "Personality") {
                VStack(spacing: 8) {
                    MeterBar(label: "Thrill preference", value: guest.thrillPreference, tint: Theme.accentWarm)
                    MeterBar(label: "Patience", value: guest.patience, tint: Theme.accent)
                    MeterBar(label: "Spending", value: guest.spending, tint: Theme.accent)
                }
            }
        }
    }

    private func colour(for mood: ThoughtMood) -> Color {
        switch mood {
        case .positive: return Theme.accent
        case .neutral: return Theme.textSecondary
        case .negative: return Theme.danger
        }
    }
}
