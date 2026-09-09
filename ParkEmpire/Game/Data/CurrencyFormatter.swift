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

    /// Signed, for profit and loss.
    static func signed(_ value: Double) -> String {
        let magnitude = short(abs(value))
        return value < 0 ? "-\(magnitude)" : magnitude
    }
}
