import SwiftUI

/// Shared visual language for the interface: bright, friendly, high contrast.
enum Theme {
    static let panel = Color(red: 0.11, green: 0.13, blue: 0.18).opacity(0.92)
    static let panelRaised = Color(red: 0.17, green: 0.20, blue: 0.26)
    static let accent = Color(red: 0.15, green: 0.68, blue: 0.53)
    static let accentWarm = Color(red: 0.96, green: 0.66, blue: 0.25)
    static let danger = Color(red: 0.90, green: 0.33, blue: 0.31)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)

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
                .fill(Theme.panel)
        )
    }
}
