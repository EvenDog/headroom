import AppKit

/// Presents the standard macOS About panel for the footer menu's "About Headroom" item.
///
/// As a menu-bar accessory app, OpenUsage is not the active app while the popover is showing, so the
/// app is activated first — otherwise the panel would open behind whatever app currently owns the
/// foreground. The panel pulls the app icon, name, and version (`CFBundleShortVersionString` — the
/// same string `AppInfo.version` surfaces in the footer) straight from the bundle; we only supply the
/// credits line: Headroom is a fork of OpenUsage, so it credits OpenUsage's authors and links both repos.
enum AboutPanel {
    @MainActor
    static func present() {
        NSApp.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    private static var credits: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let base: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph,
        ]

        let credits = NSMutableAttributedString()
        // OpenUsage's trademark policy asks forks to say clearly that they aren't the official app.
        credits.append(NSAttributedString(string: "An unofficial fork of ", attributes: base))
        credits.append(link("OpenUsage", "https://github.com/robinebers/openusage", base: base))
        credits.append(NSAttributedString(string: " by Robin Ebers,\nnot affiliated with or endorsed by it.", attributes: base))
        credits.append(NSAttributedString(string: "\n\nHeadroom source on ", attributes: base))
        credits.append(link("GitHub", "https://github.com/EvenDog/openusage", base: base))
        return credits
    }

    private static func link(_ text: String, _ urlString: String, base: [NSAttributedString.Key: Any]) -> NSAttributedString {
        var attributes = base
        if let url = URL(string: urlString) {
            attributes[.link] = url
        }
        return NSAttributedString(string: text, attributes: attributes)
    }
}
