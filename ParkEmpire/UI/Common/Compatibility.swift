import SwiftUI

/// The handful of places SwiftUI moved on after iOS 15.
///
/// The game runs back to iOS 15 so it reaches an iPhone X, an iPhone 8 and an
/// iPhone 7, all of which stopped taking updates years ago. Every shim here
/// uses the modern API wherever the phone has it, so a current device gets
/// exactly the screen it got before; the older branch is only ever a fallback.
///
/// Kept in one file on purpose. When the floor eventually rises, this file is
/// the whole list of things to delete.
enum Compatibility {
    /// True on the phones that never saw the modern navigation APIs.
    static var isLegacyOS: Bool {
        if #available(iOS 16.0, *) { return false }
        return true
    }
}

// MARK: - Navigation

/// `NavigationStack` where it exists, a stack-styled `NavigationView` below.
///
/// The two lay out identically for a screen that never pushes anything, which
/// is every sheet in the game; the one screen that does push (the trials
/// ladder) uses a plain `NavigationLink` to a destination rather than a typed
/// path, because that form works in both.
struct NavigationContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content }
        } else {
            NavigationView { content }
                .navigationViewStyle(.stack)
        }
    }
}

// MARK: - Rows

/// A title on the left and a value on the right, as `LabeledContent` draws it.
///
/// The fallback is what `LabeledContent` itself does inside a list: the label
/// in the body font, the value trailing and secondary.
struct LabelledValue: View {
    private let title: String
    private let value: String

    init(_ title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            LabeledContent(title, value: value)
        } else {
            HStack {
                Text(title)
                Spacer(minLength: 12)
                Text(value)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

// MARK: - Modifiers

extension View {

    /// Half-height and full-height sheet stops, where the OS supports them.
    ///
    /// Below iOS 16 a sheet is always full height. Nothing is lost but the
    /// glimpse of the park behind it, and every one of these sheets has its
    /// own Done button, so there is no way to be stuck in one.
    @ViewBuilder
    func parkSheetDetents(mediumOnly: Bool = false) -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents(mediumOnly ? [.medium] : [.medium, .large])
        } else {
            self
        }
    }

    /// Light text in the navigation bar, for the screens drawn on a dark
    /// panel. Below iOS 16 the app-wide `.preferredColorScheme(.dark)`
    /// already gives the bar light text, so there is nothing to do.
    @ViewBuilder
    func darkNavigationBar() -> some View {
        if #available(iOS 16.0, *) {
            self.toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            self
        }
    }

}

/// A scroll view that does not scroll, for a page panned by a gesture of its
/// own. Below iOS 16 there is simply no scroll view, which comes to the same
/// thing: the content is laid out once and stays put.
struct LockedScrollView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            ScrollView { content }
                .scrollDisabled(true)
        } else {
            content
        }
    }
}
