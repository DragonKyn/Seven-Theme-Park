import SwiftUI

/// Today's gift, from 20 to 26 December. A present to open: tapping it takes
/// the gift, which is either ten hours of a boost or one of the rides the
/// twelve days hand out.
struct HolidayGiftView: View {
    let onDismiss: () -> Void

    @State private var gift: HolidayGift?

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 12) {
                Text("A GIFT FOR YOU")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Festive.gold)

                Image(systemName: "gift.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(Circle().fill(Festive.ribbon))
                    .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2))

                if let gift {
                    reveal(gift)
                } else {
                    Text("Something is waiting under the tree")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("Every day from 20 to 26 December there is a present for you: ten hours of a free boost, or one of the rides from the 12 Days.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    button("Open it", filled: true) {
                        gift = HolidayGifts.claim()
                        if gift == nil { onDismiss() }
                    }
                    button("Later", filled: false, action: onDismiss)
                }
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panelTop, Theme.panelBottom], startPoint: .top, endPoint: .bottom)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Festive.gold.opacity(0.7), lineWidth: 1.5))
            .padding(.horizontal, 28)

            if gift != nil { SnowOverlayView(flakes: 50) }
        }
    }

    @ViewBuilder
    private func reveal(_ gift: HolidayGift) -> some View {
        switch gift {
        case .boost(let kind, let hours):
            Text("\(hours) hours of \(kind.title)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(kind.summary)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Text("It is running now, with no advert to watch. Find it on the Boosts screen.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Festive.gold)
                .multilineTextAlignment(.center)
        case .ride(let reward):
            Text(reward.title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(reward.detail)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Text("Unlocked for good. Build it from the Holiday shelf while the event is on.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Festive.gold)
                .multilineTextAlignment(.center)
        }
        button("Lovely, thank you", filled: true, action: onDismiss)
    }

    private func button(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: filled ? 16 : 14, weight: filled ? .heavy : .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: filled ? 48 : 40)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(filled ? AnyShapeStyle(Festive.ribbon) : AnyShapeStyle(Color.white.opacity(0.12))))
        }
        .buttonStyle(.plain)
    }
}
