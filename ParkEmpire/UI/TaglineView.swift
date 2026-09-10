import SwiftUI

/// The rotating tagline under the title, laid down by a coaster car.
///
/// A little car runs the crest of a hill from left to right and each letter
/// drops into place just behind it, so the line reads as track being laid
/// rather than as text fading in. When the line has been up long enough the
/// whole thing lifts away and the next one is run out.
struct TaglineView: View {
    let taglines: [String]

    @State private var index = 0
    /// Drives the entrance: false while a line is being laid, true once it is
    /// down. Flipping it back to false is what starts the next run.
    @State private var laid = false

    /// Seconds between one letter landing and the next.
    private static let letterDelay = 0.035
    /// How long a finished line stays up.
    private static let dwell: TimeInterval = 4.6
    /// How far the crest of the hill rises above the ends of the line.
    private static let arc: CGFloat = 7

    private var characters: [(id: Int, value: Character)] {
        Array(taglines[index].enumerated()).map { (id: $0.offset, value: $0.element) }
    }

    /// How long the car takes to cross, which is one delay per letter.
    private var runDuration: Double {
        Double(max(characters.count, 1)) * Self.letterDelay
    }

    var body: some View {
        ZStack(alignment: .leading) {
            letters
            car
        }
        .frame(height: 26)
        .id(index)
        .task(id: index) {
            laid = false
            withAnimation(.easeOut(duration: 0.28)) { laid = true }
            try? await Task.sleep(nanoseconds: UInt64((Self.dwell + runDuration) * 1_000_000_000))
            withAnimation(.easeIn(duration: 0.22)) { laid = false }
            try? await Task.sleep(nanoseconds: 240_000_000)
            index = (index + 1) % max(taglines.count, 1)
        }
    }

    private var letters: some View {
        HStack(spacing: 0) {
            ForEach(characters, id: \.id) { character in
                Text(String(character.value))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.88))
                    .offset(y: height(for: character.id) + (laid ? 0 : 14))
                    .opacity(laid ? 1 : 0)
                    .animation(.spring(response: 0.34, dampingFraction: 0.7)
                        .delay(Double(character.id) * Self.letterDelay),
                               value: laid)
            }
        }
    }

    /// The car itself: a stubby two-tone body that runs the crest once, ahead
    /// of the letters, and is gone by the time the line is finished.
    private var car: some View {
        GeometryReader { geometry in
            let travel = geometry.size.width
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Theme.accentWarm)
                .frame(width: 14, height: 8)
                .overlay(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Theme.danger)
                        .frame(width: 5, height: 8)
                }
                .offset(x: laid ? travel : -18,
                        y: geometry.size.height / 2 - 14)
                .opacity(laid ? 0 : 1)
                .animation(.easeInOut(duration: runDuration + 0.3), value: laid)
        }
        .allowsHitTesting(false)
    }

    /// Letters sit on a shallow hill: highest in the middle, lowest at the
    /// ends, which is what makes a straight line of text read as track.
    private func height(for position: Int) -> CGFloat {
        let count = max(characters.count - 1, 1)
        let along = Double(position) / Double(count)
        return -Self.arc * CGFloat(sin(along * .pi))
    }
}
