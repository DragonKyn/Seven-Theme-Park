import SwiftUI

/// How hard the park is asked to work this phone.
///
/// Separate from the park settings on purpose: nothing here belongs to a park,
/// and none of it is saved with one. It describes the phone, and it is the
/// same whichever park is open.
struct DisplaySettingsView: View {
    @ObservedObject var settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationContainer {
            DisplaySettingsForm(settings: settings)
                .navigationTitle("Graphics")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// The settings themselves, without any navigation of their own, so the same
/// page can be a sheet from the main menu and a pushed page from inside a
/// park.
struct DisplaySettingsForm: View {
    @ObservedObject var settings: DisplaySettings

    var body: some View {
        Form {
            Section("Detail") {
                Picker("Detail", selection: $settings.mode) {
                    ForEach(GraphicsMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("What compatibility changes") {
                change("speedometer", "Half the frame rate",
                       "Thirty frames a second, which an older phone holds steadily where it cannot hold sixty.")
                change("person.2.fill", "Fewer figures drawn",
                       "Only the guests the camera can see are drawn, and only so many of them at once.")
                change("bubble.left.fill", "Fewer thought bubbles",
                       "Three at a time instead of ten.")
                change("photo.on.rectangle", "Smaller artwork",
                       "Rides, guests and tiles are drawn at a lower resolution, which is a fraction of the memory.")
                change("play.rectangle", "A still title screen",
                       "No live park running behind the main menu.")
            }

            Section("What it does not change") {
                Text("Nothing about the park itself. Every guest still walks, queues, spends and complains; rides wear and break at the same rate; the management screen shows the same numbers; and a Park Trial is exactly as hard either way. This setting only decides how much of it is drawn.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("This phone") {
                LabelledValue("Hardware", value: DeviceProfile.summary)
                LabelledValue("Drawing", value: settings.isReduced ? "Compatibility" : "Full detail")
            }

            Section {
                Text("The frame rate and the figures change straight away. The artwork resolution is set when the game starts, so switching here shows fully the next time you open \(AppInfo.gameName).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var explanation: String {
        switch settings.mode {
        case .automatic: return settings.automaticExplanation
        case .full: return "The full park, whatever the phone. On an older one this may not hold a steady frame rate."
        case .compatibility: return "The lighter park, whatever the phone. Steadier, and kinder to the battery."
        }
    }

    private func change(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}
