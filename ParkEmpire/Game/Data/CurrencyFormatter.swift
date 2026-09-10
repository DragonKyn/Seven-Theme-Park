import Foundation

enum CurrencyFormatter {
    private static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let precise: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Rounded, for headline figures like cash and construction costs.
    static func short(_ value: Double) -> String {
        whole.string(from: NSNumber(value: value)) ?? "$0"
    }

    /// Two decimal places, for prices and per-sale figures.
    static func exact(_ value: Double) -> String {
        precise.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    /// Shortened for places with no room to grow: thousands and millions get
    /// a suffix rather than another four digits. A park that is doing well
    /// should not push the rest of a row onto a second line.
    static func compact(_ value: Double) -> String {
        let magnitude = abs(value)
        let sign = value < 0 ? "-" : ""
        switch magnitude {
        case 1_000_000_000...:
            return sign + String(format: "$%.1fB", magnitude / 1_000_000_000)
        case 1_000_000...:
            return sign + String(format: "$%.1fM", magnitude / 1_000_000)
        case 100_000...:
            return sign + String(format: "$%.0fK", magnitude / 1_000)
        case 10_000...:
            return sign + String(format: "$%.1fK", magnitude / 1_000)
        default:
            return short(value)
        }
    }

    /// Always signed, including a plus. For a running total the player is
    /// watching move, where "400" and "+400" mean different things.
    static func delta(_ value: Double) -> String {
        let magnitude = short(abs(value))
        return value < 0 ? "-\(magnitude)" : "+\(magnitude)"
    }

    /// Signed, for profit and loss.
    static func signed(_ value: Double) -> String {
        let magnitude = short(abs(value))
        return value < 0 ? "-\(magnitude)" : magnitude
    }
}
