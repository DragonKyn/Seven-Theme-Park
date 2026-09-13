import SwiftUI

/// Everything the card needs to draw itself, worked out from the event.
///
/// The view knows nothing about parks: it is given a symbol, some words and a
/// row of figures, which is why one card can serve every rare event rather
/// than each one growing its own near-identical copy.
struct ParkEventPresentation {
    struct Figure: Identifiable {
        let id = UUID()
        let value: String
        let caption: String
    }

    let symbolName: String
    /// The two colours behind the symbol, and the colour of the kicker.
    let tint: Color
    let deepTint: Color
    /// The small tracked line above the headline.
    let kicker: String
    let headline: String
    let detail: String
    let figures: [Figure]
}

/// The card that appears when something happens in the park that the player
/// did not cause.
///
/// Shown as its own event rather than buried in the alert list, because these
/// are the moments that would otherwise pass unnoticed: the gate gets busy, or
/// a ride closes, and nothing on screen says why.
struct EventCardView: View {
    let event: ParkEvent
    let onDismiss: () -> Void

    @State private var shown = false

    /// Long enough to read, and a tap ends it sooner.
    private static let dwell: TimeInterval = 8.0

    private var presentation: ParkEventPresentation {
        ParkEventPresentation.make(for: event)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.28 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: finish)

            card
                .scaleEffect(shown ? 1 : 0.75)
                .opacity(shown ? 1 : 0)
                .onTapGesture(perform: finish)
        }
        .task {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.64)) { shown = true }
            try? await Task.sleep(nanoseconds: UInt64(Self.dwell * 1_000_000_000))
            finish()
        }
    }

    private var card: some View {
        let style = presentation
        return VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [style.tint, style.deepTint],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(width: 62, height: 62)
                Image(systemName: style.symbolName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2))

            Text(style.kicker)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2.4)
                .foregroundStyle(style.tint)

            Text(style.headline)
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(style.detail)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            if !style.figures.isEmpty {
                HStack(spacing: 14) {
                    ForEach(style.figures) { pill($0) }
                }
                .padding(.top, 2)
            }

            Text("Tap to carry on")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.top, 2)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                                     startPoint: .top,
                                     endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(style.tint.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
        )
    }

    private func pill(_ item: ParkEventPresentation.Figure) -> some View {
        VStack(spacing: 2) {
            Text(item.value)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.accent)
            Text(item.caption)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(minWidth: 96)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.white.opacity(0.10)))
    }

    private func finish() {
        guard shown else { return }
        withAnimation(.easeIn(duration: 0.16)) { shown = false }
        onDismiss()
    }
}

extension ParkEventPresentation {
    /// The one place an event turns into words and colours.
    static func make(for event: ParkEvent) -> ParkEventPresentation {
        switch event {
        case .promotion(let post):
            return ParkEventPresentation(
                symbolName: "iphone.gen3.radiowaves.left.and.right",
                tint: Color(red: 0.98, green: 0.55, blue: 0.78),
                deepTint: Color(red: 0.62, green: 0.36, blue: 0.92),
                kicker: "GOING VIRAL",
                headline: post.guestName,
                detail: "posted about \(post.rideName)",
                figures: [Figure(value: "+\(Int(post.boost * 100))%", caption: "ARRIVALS"),
                          Figure(value: post.durationLabel, caption: "FOR THE NEXT")])

        case .ejection(let report):
            return ParkEventPresentation(
                symbolName: report.wasEscorted ? "shield.lefthalf.filled" : "exclamationmark.triangle.fill",
                tint: report.wasEscorted ? Theme.accent : Theme.danger,
                deepTint: report.wasEscorted
                    ? Color(red: 0.10, green: 0.48, blue: 0.36)
                    : Color(red: 0.62, green: 0.16, blue: 0.20),
                kicker: report.wasEscorted ? "ESCORTED OUT" : "NOBODY STOPPED THEM",
                headline: report.guestName,
                detail: report.detail,
                figures: [Figure(value: "\(report.litterDropped)", caption: "RUBBISH DROPPED"),
                          Figure(value: report.durationLabel, caption: "IN THE PARK")])

        case .review(let review):
            return ParkEventPresentation(
                symbolName: review.isBad ? "hand.thumbsdown.fill" : "star.bubble.fill",
                tint: review.isBad ? Theme.danger : Theme.money,
                deepTint: review.isBad
                    ? Color(red: 0.62, green: 0.16, blue: 0.20)
                    : Theme.moneyDeep,
                kicker: "\(review.starLine)   REVIEWED",
                headline: review.headline,
                detail: review.detail,
                figures: review.ratingSwing == 0
                    ? [Figure(value: review.criticName, caption: "LEFT BY")]
                    : [Figure(value: "\(review.ratingSwing > 0 ? "+" : "")\(Int(review.ratingSwing))",
                              caption: "PARK RATING"),
                       Figure(value: review.durationLabel, caption: "FOR THE NEXT")])

        case .inspection(let report):
            return ParkEventPresentation(
                symbolName: report.passed ? "checkmark.seal.fill" : "xmark.seal.fill",
                tint: report.passed ? Theme.accent : Theme.danger,
                deepTint: report.passed
                    ? Color(red: 0.10, green: 0.48, blue: 0.36)
                    : Color(red: 0.62, green: 0.16, blue: 0.20),
                kicker: report.passed ? "SAFETY INSPECTION PASSED" : "SAFETY INSPECTION FAILED",
                headline: report.headline,
                detail: report.detail,
                figures: report.passed
                    ? [Figure(value: "\(Int(report.condition))%", caption: "CONDITION"),
                       Figure(value: "+\(Int(report.bonus)) for \(report.durationLabel)",
                              caption: "PARK RATING")]
                    : [Figure(value: "\(Int(report.condition))%", caption: "CONDITION"),
                       Figure(value: CurrencyFormatter.compact(report.fine), caption: "FINE")])

        case .coachParty(let report):
            return ParkEventPresentation(
                symbolName: "bus.fill",
                tint: Theme.accentWarm,
                deepTint: Theme.moneyDeep,
                kicker: "A COACH HAS ARRIVED",
                headline: report.groupName,
                detail: report.detail,
                figures: [Figure(value: "\(report.count)", caption: "THROUGH THE GATE"),
                          Figure(value: "\(report.childCount)", caption: "OF THEM CHILDREN")])
        }
    }
}
