import Foundation

/// SplitMix64. Deterministic and `Codable`, so a saved park resumes with the
/// same random stream it had when it was saved.
struct SeededGenerator: RandomNumberGenerator, Codable {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    init() {
        self.state = UInt64.random(in: UInt64.min...UInt64.max)
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Convenience for the many `0...100` personality rolls.
    mutating func double(_ range: ClosedRange<Double>) -> Double {
        Double.random(in: range, using: &self)
    }

    mutating func int(_ range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }

    mutating func chance(_ probability: Double) -> Bool {
        Double.random(in: 0..<1, using: &self) < probability
    }

    mutating func pick<T>(_ elements: [T]) -> T? {
        guard !elements.isEmpty else { return nil }
        return elements[Int.random(in: 0..<elements.count, using: &self)]
    }
}
