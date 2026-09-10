import SwiftUI

/// Shared visual language for the interface.
///
/// The park itself is bright, so the panels over it are a lit blue-slate
/// rather than near-black: dark enough to read white text against grass,
/// light enough that the interface looks like part of the same game.
enum Theme {

    // MARK: - Surfaces

    /// Top and bottom of the panel gradient. A panel is never a flat slab,
    /// which is most of what stops it reading as a dark hole in the screen.
    static let panelTop = Color(red: 0.20, green: 0.27, blue: 0.38)
    static let panelBottom = Color(red: 0.12, green: 0.17, blue: 0.25)
    /// Flat equivalent, for the few places a gradient will not do.
    static let panel = Color(red: 0.16, green: 0.22, blue: 0.32).opacity(0.95)
    static let panelRaised = Color(red: 0.24, green: 0.31, blue: 0.42)
    /// Hairline along the top edge of a panel, which reads as light catching it.
    static let panelStroke = Color.white.opacity(0.16)
    /// Background for a control sitting on a panel.
    static let control = Color.white.opacity(0.14)
    static let controlRaised = Color.white.opacity(0.24)

    // MARK: - Accents

    static let accent = Color(red: 0.20, green: 0.78, blue: 0.55)
    static let accentWarm = Color(red: 1.00, green: 0.72, blue: 0.28)
    static let danger = Color(red: 0.95, green: 0.40, blue: 0.36)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)

    // MARK: - Money

    /// Cash on hand. Gold rather than green, so it stands apart from the
    /// green used for "this is going well" everywhere else.
    static let money = Color(red: 1.00, green: 0.82, blue: 0.35)
    static let moneyDeep = Color(red: 0.96, green: 0.63, blue: 0.16)
    static let profit = Color(red: 0.38, green: 0.88, blue: 0.55)
    static let loss = Color(red: 0.98, green: 0.48, blue: 0.42)

    /// The gradient behind the cash readout. The one place in the interface
    /// that is allowed to shout.
    static let moneyGradient = LinearGradient(colors: [money, moneyDeep],
                                              startPoint: .top,
                                              endPoint: .bottom)

    static func profitColour(_ amount: Double) -> Color {
        amount < 0 ? loss : profit
    }

    // MARK: - Metrics

    static let cornerRadius: CGFloat = 14

    static func happinessColour(_ value: Double) -> Color {
        switch value {
        case ..<40: return danger
        case ..<70: return accentWarm
        default: return accent
        }
    }

    /// Needs read "100 is bad", so the colour ramp runs the other way.
    static func needColour(_ value: Double) -> Color {
        switch value {
        case ..<50: return accent
        case ..<80: return accentWarm
        default: return danger
        }
    }
}

extension View {
    func panelBackground(cornerRadius: CGFloat = Theme.cornerRadius) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                                     startPoint: .top,
                                     endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Theme.panelStroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
        )
    }
}
