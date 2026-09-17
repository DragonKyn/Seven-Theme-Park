import SwiftUI

/// Why the game exists, and what it will never do to the people playing it.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    masthead
                    story
                    rememberedList
                    promises
                    signOff
                }
                .padding(20)
                .padding(.bottom, 12)
            }
            .background(
                LinearGradient(colors: [Theme.panelTop, Theme.panelBottom],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Sections

    private var masthead: some View {
        VStack(spacing: 6) {
            Text(AppInfo.gameName)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.moneyGradient)
            Text(AppInfo.tagline)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            Text(versionLine)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var story: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("Why I made this")

            paragraph("""
            Some of my favourite hours as a kid were spent staring at a patch of empty \
            grass on a screen, trying to figure out where the first ride should go. \
            Laying a path, watching the first guests wander in, holding my breath the \
            first time a coaster I built actually made it round the track. Those games \
            taught me patience, a little bit of maths, and how much fun it is to make \
            something out of nothing.
            """)

            paragraph("""
            \(AppInfo.gameName) is my love letter to those theme park and ride \
            simulators. Somewhere along the way, a lot of games in this genre stopped \
            feeling like toys you could get lost in and started feeling like shops you \
            were standing inside. I wanted to build the game I remember: one where the \
            only thing standing between you and your dream park is your own imagination.
            """)
        }
    }

    private var rememberedList: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("The things I wanted back")

            memory("square.dashed", "An empty lot and a blank slate",
                   "Starting with nothing but a gate and a bit of path, and making it yours.")
            memory("person.3.fill", "Guests with opinions",
                   "Little people who get hungry, get lost, love a ride and let you know when the queue is too long.")
            memory("point.topleft.down.curvedto.point.bottomright.up", "Building your own coaster",
                   "Laying track one piece at a time and watching the train run the thing you designed.")
            memory("chart.line.uptrend.xyaxis", "A park that has to pay its way",
                   "The quiet satisfaction of balancing the books and watching the numbers turn green.")
            memory("hourglass", "Losing an afternoon",
                   "Just one more ride. Just one more path. Just one more day.")
        }
    }

    private var promises: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("My promise to you")

            promise("hand.raised.fill", Theme.accent,
                    "No forced ads. Ever.",
                    "Nothing will pop up and interrupt your park. If you ever see an ad in \(AppInfo.gameName), it is because you chose to watch one in exchange for an in-game boost, and you never have to.")
            promise("dollarsign.circle.fill", Theme.money,
                    "No in-game currency.",
                    "No gems, no tokens, no bundles of coins. I do not believe in them. The money in your park is money you earned by running it well.")
            promise("hand.point.up.braille.fill", Theme.textSecondary,
                    "Your answer to the tracking question is yours.",
                    "Say no and nothing about the game changes. Every ride, map, trial and medal stays exactly as open as it was.")
            promise("lock.open.fill", Theme.accentWarm,
                    "Everything is playable without spending a cent.",
                    "Every ride, every map, every trial and every medal can be reached just by playing. Nothing is locked behind a purchase.")
        }
    }

    private var signOff: some View {
        VStack(alignment: .leading, spacing: 10) {
            paragraph("""
            Thank you for playing. Whether you are building your hundredth park or \
            placing your very first path, I hope \(AppInfo.gameName) gives you a little \
            of the wonder those old games gave me.
            """)
            Text("Now go build something great.")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.money.opacity(0.35), lineWidth: 1)
                )
        )
    }

    // MARK: - Pieces

    private var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private func heading(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.8)
            .foregroundStyle(Theme.money)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func memory(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func promise(_ symbol: String, _ tint: Color, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(Circle().fill(tint.opacity(0.18)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
    }
}
