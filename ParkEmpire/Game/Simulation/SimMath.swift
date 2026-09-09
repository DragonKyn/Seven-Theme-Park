import CoreGraphics
import Foundation

enum SimMath {
    static func clamp(_ value: Double, _ lower: Double = 0, _ upper: Double = 100) -> Double {
        min(max(value, lower), upper)
    }

    /// Maps `value` from the range `from` to 0...1, clamped.
    static func normalise(_ value: Double, from lower: Double, to upper: Double) -> Double {
        guard upper > lower else { return 0 }
        return clamp((value - lower) / (upper - lower), 0, 1)
    }

    static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = Double(a.x - b.x)
        let dy = Double(a.y - b.y)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Picks an index with probability proportional to weight. Returns nil when
    /// every weight is zero.
    static func weightedChoice<G: RandomNumberGenerator>(_ weights: [Double], using generator: inout G) -> Int? {
        let total = weights.reduce(0, +)
        guard total > 0 else { return nil }
        var roll = Double.random(in: 0..<total, using: &generator)
        for (index, weight) in weights.enumerated() {
            roll -= weight
            if roll <= 0 { return index }
        }
        return weights.indices.last
    }
}
