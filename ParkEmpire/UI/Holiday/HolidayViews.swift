import SwiftUI

/// Christmas red and pine green, for everything festive.
enum Festive {
    static let red = Color(red: 0.86, green: 0.18, blue: 0.22)
    static let deepRed = Color(red: 0.62, green: 0.10, blue: 0.16)
    static let green = Color(red: 0.20, green: 0.62, blue: 0.38)
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.28)
    static let snow = Color(red: 0.97, green: 0.98, blue: 1.0)
    static let bulbs: [Color] = [
        Color(red: 0.92, green: 0.23, blue: 0.22),
        Color(red: 1.0, green: 0.78, blue: 0.22),
        Color(red: 0.28, green: 0.78, blue: 0.42),
        Color(red: 0.35, green: 0.72, blue: 0.96)
    ]
    static let ribbon = LinearGradient(colors: [red, deepRed], startPoint: .leading, endPoint: .trailing)
}

/// Snow drifting down over a whole screen. Cheap: a few dozen circles at
/// positions worked out from the clock.
struct SnowOverlayView: View {
    var flakes = 90

    var body: some View {
        TimelineView(.animation) { timeline in
            let clock = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for index in 0..<flakes {
                    let a = fract(sin(Double(index) * 12.9898) * 43758.5453)
                    let b = fract(sin(Double(index * 2 + 2) * 12.9898) * 43758.5453)
                    let c = fract(sin(Double(index * 3 + 7) * 12.9898) * 43758.5453)
                    let speed = 24 + c * 40
                    let sway = sin(clock * (0.5 + c) + Double(index)) * 14
                    var x = (a * size.width + sway).truncatingRemainder(dividingBy: size.width)
                    if x < 0 { x += size.width }
                    let y = (b * size.height + clock * speed).truncatingRemainder(dividingBy: size.height)
                    let radius = 1.1 + c * 2.2
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius,
                                                        width: radius * 2, height: radius * 2)),
                                 with: .color(Festive.snow.opacity(0.55 + c * 0.35)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func fract(_ x: Double) -> Double { x - x.rounded(.down) }
}

/// A string of coloured lights hanging in a shallow curve across the width.
struct FestiveLights: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = (sin(timeline.date.timeIntervalSinceReferenceDate * 4.4) + 1) / 2
            Canvas { context, size in
                let count = 13
                var wire = Path()
                wire.move(to: CGPoint(x: 0, y: 2))
                wire.addQuadCurve(to: CGPoint(x: size.width, y: 2),
                                  control: CGPoint(x: size.width / 2, y: 26))
                context.stroke(wire, with: .color(.black.opacity(0.55)), lineWidth: 1.5)
                for index in 0..<count {
                    let t = (CGFloat(index) + 0.5) / CGFloat(count)
                    let x = size.width * t
                    let y = 2 + 24 * 2 * t * (1 - t) + 4
                    let lit = index % 2 == 0 ? 0.55 + 0.45 * phase : 1 - 0.45 * phase
                    context.fill(Path(ellipseIn: CGRect(x: x - 4.5, y: y - 4.5, width: 9, height: 9)),
                                 with: .color(Festive.bulbs[index % Festive.bulbs.count].opacity(lit)))
                }
            }
        }
        .frame(height: 34)
        .allowsHitTesting(false)
    }
}

/// The ribbon under the title during the event.
struct HolidayRibbon: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "snowflake")
                .font(.system(size: 11, weight: .bold))
            Text("HOLIDAY WONDER  ·  \(HolidaySeason.shortDatesLabel.uppercased())")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Capsule().fill(Festive.ribbon))
        .overlay(Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 1))
    }
}

/// What a holiday trial hands over, as a short list.
struct HolidayRewardList: View {
    let rewardIDs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rewardIDs, id: \.self) { id in
                if let reward = HolidayRewards.definition(id) {
                    HStack(spacing: 10) {
                        Image(systemName: reward.symbolName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Festive.red))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(reward.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(reward.detail)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}

/// The twelve days: every trial in the event, with what each one is worth.
struct HolidayLadderSection: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        let store = HolidayStore()
        let done = store.completedCount()

        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HolidayRibbon()
                Text("12 Days of Holiday Wonder")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Twelve parks to build before 5 January. Every one is open from the first day, and each hands over something for the season: decorations, ride makeovers, rides and a new performer.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill").foregroundStyle(Festive.gold)
                    Text("\(done) of \(TrialContent.holiday.count) days done this year")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule().fill(Festive.ribbon)
                                .frame(width: geometry.size.width * CGFloat(done)
                                       / CGFloat(max(1, TrialContent.holiday.count)))
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.top, 4)
            }

            ForEach(TrialContent.holiday) { trial in
                dayCard(trial, store: store)
            }
        }
    }

    @ViewBuilder
    private func dayCard(_ trial: TrialDefinition, store: HolidayStore) -> some View {
        let open = store.isOpen(trial)
        let completed = store.isCompleted(trial)
        let run = router.trialRuns[trial.id]

        let card = VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(completed ? Festive.green : (open ? Festive.red : Color.white.opacity(0.25)))
                    if completed {
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    } else {
                        Text("\(trial.number)").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.white)
                    }
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 0) {
                    Text("DAY \(trial.number)")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(Festive.gold)
                    Text(trial.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(open ? Color.white : Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if open {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            if open {
                ForEach(Array(trial.goals.enumerated()), id: \.offset) { _, goal in
                    Label(goal.title, systemImage: goal.symbolName)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                let names = trial.rewardIDs.compactMap { HolidayRewards.definition($0)?.title }.joined(separator: ", ")
                Label("Reward: \(names)", systemImage: "gift.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Festive.gold)
                if completed {
                    Text("Done this year  ·  \(trial.medal.name)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Festive.green)
                }
                if let run {
                    Text("Park in progress, day \(run.day)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
            } else {
                let needed = trial.needsRewardID.flatMap { HolidayRewards.definition($0)?.title } ?? "an earlier reward"
                Label("Earn \(needed) to open", systemImage: "lock.fill")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(open ? 0.09 : 0.04)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(completed ? Festive.green : Color.white.opacity(0.08), lineWidth: completed ? 2 : 1))

        if open {
            NavigationLink {
                TrialBriefingView(trial: trial)
            } label: {
                card
            }
            .buttonStyle(.plain)
        } else {
            card
        }
    }
}

/// The announcement on the main menu while the event is on. Shown at each
/// launch until the box is ticked, which puts it away until next year.
struct HolidayAnnouncementView: View {
    let onSeeTrials: () -> Void
    let onDismiss: () -> Void

    @State private var hideUntilNextYear = false

    private func close(_ then: (() -> Void)? = nil) {
        if hideUntilNextYear { HolidayStore().hideAnnouncement() }
        onDismiss()
        then?()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("THE HOLIDAY EVENT")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Holiday Wonder")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .background(Festive.ribbon)

                FestiveLights().padding(.horizontal, 6)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar").foregroundStyle(Festive.gold)
                            Text("\(HolidaySeason.datesLabel)  ·  \(HolidaySeason.daysLeft()) days left")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(Festive.gold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.10)))

                        row("snowflake", "11 new rides", "Seven Christmas rides and four for New Year's, from the Reindeer Carousel to the Ball Drop Tower.")
                        row("person.fill", "Santa and Mrs. Claus", "Two new entertainers, each with a bonus of their own.")
                        row("gift.fill", "12 Days of Holiday Wonder", "Twelve festive trials with a tab of their own in Park Trials.")
                        row("paintbrush.fill", "Exclusive rewards", "Earn decorations, ride makeovers and new rides, and keep them for every future holiday.")
                        row("party.popper.fill", "Company holiday parties", "Big office outings arrive by the busload with five times the spending money.")

                        Text("Snow is falling, the ground is white, and it all ends on January 5. Come and play.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            hideUntilNextYear.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: hideUntilNextYear ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 22))
                                    .foregroundStyle(hideUntilNextYear ? Festive.green : Color.white.opacity(0.6))
                                Text("Don't show this again until next year")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)

                        Button { close(onSeeTrials) } label: {
                            Label("See the 12 Days", systemImage: "gift.fill")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(.white)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Festive.ribbon))
                        }
                        .buttonStyle(.plain)

                        Button { close() } label: {
                            Text("Let's play")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .foregroundStyle(.white)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }
            }
            .frame(maxWidth: 380)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.panelTop, Theme.panelBottom], startPoint: .top, endPoint: .bottom))
            )
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Festive.gold.opacity(0.7), lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 22)
            .padding(.vertical, 40)

            SnowOverlayView(flakes: 60)
        }
    }

    private func row(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Festive.red))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
