import SwiftUI

/// Everything the card needs to draw itself, worked out from the event.
///
/// The view knows nothing about parks: it is given a banner, a symbol, some
/// words and a row of figures, which is why one card can serve every rare
/// event rather than each one growing its own near-identical copy.
struct ParkEventPresentation {
    struct Figure: Identifiable {
        let id = UUID()
        let value: String
        let caption: String
    }

    /// The band across the top of the card. Each one gives its event a look
    /// of its own without any of them needing a view of its own.
    enum Banner {
        /// Nothing but the card.
        case none
        /// Diagonal hazard stripes with a title, for anything that reads as
        /// an incident somebody had to deal with.
        case incident(String)
        /// A bus destination board: amber lettering on black.
        case destination(String)
        /// A stamped certificate line, for a verdict handed down.
        case stamp(String, passed: Bool)
    }

    let banner: Banner
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

    /// How much of its time on screen is left, 1 down to 0. Counted by the
    /// controller rather than by the view.
    ///
    /// The card used to time itself with `try? await Task.sleep` inside a
    /// `.task`. A cancelled sleep returns immediately and the `try?` swallowed
    /// the cancellation, so the dismissal ran on the spot; SwiftUI cancels a
    /// `.task` whenever the view around it is rebuilt, which this one is
    /// several times a second while the park is running. The card was
    /// disappearing long before anybody could read it.
    let remaining: Double
    /// Declared last so the call site can pass it as a trailing closure.
    let onDismiss: () -> Void

    @State private var shown = false

    private static let corner: CGFloat = 20

    private var presentation: ParkEventPresentation {
        ParkEventPresentation.make(for: event)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.32 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: finish)

            card
                .scaleEffect(shown ? 1 : 0.75)
                .opacity(shown ? 1 : 0)
                .onTapGesture(perform: finish)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.64)) { shown = true }
        }
    }

    private var card: some View {
        let style = presentation
        return VStack(spacing: 0) {
            BannerView(banner: style.banner)

            VStack(spacing: 10) {
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
                .shadow(color: style.deepTint.opacity(0.5), radius: 10, y: 4)

                Text(style.kicker)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(style.tint)
                    .multilineTextAlignment(.center)

                Text(style.headline)
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(style.detail)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if !style.figures.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(style.figures) { pill($0, tint: style.tint) }
                    }
                    .padding(.top, 2)
                }

                Text("Tap to carry on")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // How long is left. A card that closes itself with no warning
            // feels like a glitch; a card with a bar running down feels like
            // a decision the player can beat by tapping.
            GeometryReader { geometry in
                Rectangle()
                    .fill(style.tint.opacity(0.75))
                    .frame(width: geometry.size.width * max(0, min(1, remaining)))
            }
            .frame(height: 3)
            .background(Color.white.opacity(0.10))
            // The controller reports five times a second; the animation is
            // what turns that into a bar that glides rather than steps.
            .animation(.linear(duration: 0.2), value: remaining)
        }
        .frame(maxWidth: 310)
        .background(
            RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                                     startPoint: .top,
                                     endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                .strokeBorder(style.tint.opacity(0.6), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Self.corner, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 18, y: 9)
    }

    private func pill(_ item: ParkEventPresentation.Figure, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(item.value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(item.caption)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.white.opacity(0.10)))
    }

    private func finish() {
        guard shown else { return }
        shown = false
        onDismiss()
    }
}

// MARK: - Banners

/// The band across the top of an event card.
private struct BannerView: View {
    let banner: ParkEventPresentation.Banner

    var body: some View {
        switch banner {
        case .none:
            EmptyView()

        case .incident(let title):
            ZStack {
                HazardStripes()
                Text(title)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.black.opacity(0.72)))
            }
            .frame(height: 34)
            .clipped()

        case .destination(let text):
            // A bus destination board: amber on black, letter-spaced, with a
            // hairline under it like the lip of the sign.
            VStack(spacing: 0) {
                Text(text.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.money)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.80))
                Rectangle()
                    .fill(Theme.moneyDeep.opacity(0.8))
                    .frame(height: 2)
            }

        case .stamp(let title, let passed):
            stamp(title, colour: passed ? Theme.accent : Theme.danger)
        }
    }

    private func stamp(_ title: String, colour: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(3)
            .foregroundStyle(colour)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(colour.opacity(0.18))
            .overlay(Rectangle().fill(colour.opacity(0.55)).frame(height: 2),
                     alignment: .bottom)
    }
}

/// Diagonal warning stripes, drawn rather than tiled from an image.
private struct HazardStripes: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Theme.accentWarm.opacity(0.30)))

            let width: CGFloat = 12
            let step = width * 2
            var x = -size.height
            while x < size.width + size.height {
                var stripe = Path()
                stripe.move(to: CGPoint(x: x, y: size.height))
                stripe.addLine(to: CGPoint(x: x + size.height, y: 0))
                stripe.addLine(to: CGPoint(x: x + size.height + width, y: 0))
                stripe.addLine(to: CGPoint(x: x + width, y: size.height))
                stripe.closeSubpath()
                context.fill(stripe, with: .color(Theme.accentWarm.opacity(0.55)))
                x += step
            }
        }
    }
}

// MARK: - Events to words

extension ParkEventPresentation {
    /// The one place an event turns into words and colours.
    static func make(for event: ParkEvent) -> ParkEventPresentation {
        switch event {
        case .promotion(let post):
            return ParkEventPresentation(
                banner: .none,
                symbolName: "iphone.gen3.radiowaves.left.and.right",
                tint: Color(red: 0.98, green: 0.55, blue: 0.78),
                deepTint: Color(red: 0.62, green: 0.36, blue: 0.92),
                kicker: "GOING VIRAL",
                headline: post.guestName,
                detail: "posted about \(post.rideName)",
                figures: [Figure(value: "+\(Int(post.boost * 100))%", caption: "ARRIVALS"),
                          Figure(value: post.durationLabel, caption: "FOR THE NEXT")])

        case .ejection(let report):
            // The guard's own name is deliberately not here. What the player
            // wants to know is whether the department they pay for did its
            // job, not which employee happened to be nearest.
            return ParkEventPresentation(
                banner: .incident(report.wasEscorted ? "INCIDENT CLOSED" : "INCIDENT LOGGED"),
                symbolName: report.wasEscorted ? "shield.lefthalf.filled" : "shield.slash.fill",
                tint: report.wasEscorted ? Theme.accent : Theme.danger,
                deepTint: report.wasEscorted
                    ? Color(red: 0.10, green: 0.48, blue: 0.36)
                    : Color(red: 0.62, green: 0.16, blue: 0.20),
                kicker: "PARK SECURITY",
                headline: report.wasEscorted
                    ? "Your security team escorted out a troublemaker"
                    : "A troublemaker walked out unchallenged",
                detail: report.detail,
                figures: [Figure(value: "\(report.litterDropped)", caption: "RUBBISH DROPPED"),
                          Figure(value: report.durationLabel, caption: "ON SITE"),
                          Figure(value: report.wasEscorted ? "REMOVED" : "NO COVER",
                                 caption: "OUTCOME")])

        case .review(let review):
            return ParkEventPresentation(
                banner: .none,
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
                banner: .stamp(report.passed ? "CERTIFICATE ISSUED" : "PROHIBITION NOTICE",
                               passed: report.passed),
                symbolName: report.passed ? "checkmark.seal.fill" : "xmark.seal.fill",
                tint: report.passed ? Theme.accent : Theme.danger,
                deepTint: report.passed
                    ? Color(red: 0.10, green: 0.48, blue: 0.36)
                    : Color(red: 0.62, green: 0.16, blue: 0.20),
                kicker: "SAFETY INSPECTION",
                headline: report.headline,
                detail: report.detail,
                figures: report.passed
                    ? [Figure(value: "\(Int(report.condition))%", caption: "CONDITION"),
                       Figure(value: "+\(Int(report.bonus))", caption: "PARK RATING"),
                       Figure(value: report.durationLabel, caption: "FOR THE NEXT")]
                    : [Figure(value: "\(Int(report.condition))%", caption: "CONDITION"),
                       Figure(value: CurrencyFormatter.compact(report.fine), caption: "FINE"),
                       Figure(value: "CLOSED", caption: "UNTIL REPAIRED")])

        case .tourBus(let report):
            return ParkEventPresentation(
                banner: .destination(report.groupName),
                symbolName: "bus.doubledecker.fill",
                tint: Theme.money,
                deepTint: Theme.moneyDeep,
                kicker: "TOUR BUS ARRIVING",
                headline: report.headline,
                detail: report.detail,
                figures: [Figure(value: "\(report.count)", caption: "ON BOARD"),
                          Figure(value: "\(report.childCount)", caption: "CHILDREN"),
                          Figure(value: "\(report.count - report.childCount)", caption: "ADULTS")])
        }
    }
}
