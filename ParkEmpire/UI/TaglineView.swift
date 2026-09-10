import SwiftUI

/// The rotating tagline under the title, laid down by a coaster car.
///
/// A car runs the crest of a hill from left to right and each letter drops
/// into place just behind it, so the line reads as track being laid rather
/// than as text fading in. When the line has been up long enough the whole
/// thing lifts away and the next one is run out.
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
    private static let carLength: CGFloat = 26
    private static let carHeight: CGFloat = 15

    private var characters: [(id: Int, value: Character)] {
        Array(taglines[index].enumerated()).map { (id: $0.offset, value: $0.element) }
    }

    /// How long the car takes to cross, which is one delay per letter.
    private var runDuration: Double {
        Double(max(characters.count, 1)) * Self.letterDelay
    }

    var body: some View {
        // The letters size themselves and the car is laid over them, so the
        // car runs exactly the width of the line and the whole thing centres
        // as one block. Measuring the car against the full screen width was
        // what pushed the line off to the left.
        letters
            .overlay { car }
            .frame(height: 30)
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
        HStack(spacing: 0.6) {
            ForEach(characters, id: \.id) { character in
                letter(character.value)
                    .offset(y: height(for: character.id) + (laid ? 0 : 14))
                    .opacity(laid ? 1 : 0)
                    .animation(.spring(response: 0.34, dampingFraction: 0.7)
                        .delay(Double(character.id) * Self.letterDelay),
                               value: laid)
            }
        }
        .fixedSize()
    }

    /// Spaces are drawn as a fixed gap rather than as a space character, so
    /// the line's width does not depend on how the font treats whitespace.
    @ViewBuilder
    private func letter(_ value: Character) -> some View {
        if value == " " {
            Color.clear.frame(width: 4, height: 1)
        } else {
            Text(String(value))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    /// A stubby coaster car: nosed body, a rider, and a dark chassis. It runs
    /// the crest once, ahead of the letters, and is gone by the time the line
    /// has finished landing.
    private var car: some View {
        GeometryReader { geometry in
            coasterCar
                .offset(x: laid ? geometry.size.width + 4 : -Self.carLength,
                        y: geometry.size.height / 2 - Self.arc - Self.carHeight)
                .opacity(laid ? 0 : 1)
                .animation(.easeInOut(duration: runDuration + 0.3), value: laid)
        }
        .allowsHitTesting(false)
    }

    private var coasterCar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Theme.accentWarm)
                .frame(width: Self.carLength, height: Self.carHeight)

            // Nose at the front, so it reads as pointing where it is going.
            Circle()
                .fill(Theme.danger)
                .frame(width: Self.carHeight, height: Self.carHeight)
                .offset(x: Self.carLength - Self.carHeight)

            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: Self.carHeight * 0.42, height: Self.carHeight * 0.42)
                .offset(x: Self.carLength * 0.24, y: -1)
        }
        .frame(width: Self.carLength, height: Self.carHeight, alignment: .leading)
        .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
    }

    /// Letters sit on a shallow hill: highest in the middle, lowest at the
    /// ends, which is what makes a straight line of text read as track.
    private func height(for position: Int) -> CGFloat {
        let count = max(characters.count - 1, 1)
        let along = Double(position) / Double(count)
        return -Self.arc * CGFloat(sin(along * .pi))
    }
}
