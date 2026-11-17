import Foundation

struct MenuBarContent: Equatable {
    struct Item: Equatable, Identifiable {
        let id: String
        let provider: Provider
        let label: String
        let shortLabel: String
        let value: String
    }

    /// One of the stacked bars the user picked in Settings.
    struct Bar: Equatable, Identifiable {
        let id: String
        let label: String
        /// How full the bar is, 0 to 1, following Show Usage As. Nil when the limit has no reading.
        let fraction: Double?
    }

    let items: [Item]
    var overflow = 0
    var updateAvailable = false
    /// When not empty, the menu bar draws these stacked bars instead of `items`.
    var bars: [Bar] = []

    var isEmpty: Bool { items.isEmpty && bars.isEmpty }

    var accessibilityText: String {
        let shown = items.map { "\($0.provider.fullName) \($0.label) \($0.value)" }
        let barTexts = bars.map { bar in
            "\(bar.label) \(bar.fraction.map { "\(Int(($0 * 100).rounded()))%" } ?? "no data")"
        }
        let more = overflow > 0 ? ["\(overflow) more"] : []
        let update = updateAvailable ? ["Update available"] : []
        return (shown + barTexts + more + update).joined(separator: "; ")
    }
}

@MainActor
enum MenuBarContentBuilder {
    private static let genericWords: Set<String> = ["models", "bot", "usage"]

    /// Only what's running out, or with `alwaysShows` every section of the Priority tab in its order, top to bottom.
    static func build(board: PriorityBoard, limit: MenuBarLimit, alwaysShows: Bool = false) -> MenuBarContent {
        guard limit != .iconOnly else { return MenuBarContent(items: []) }
        let counted = alwaysShows
            ? board.pinned.map { ($0.provider, $0.line) } + (board.attention + board.useItOrLoseIt).map { ($0.provider, $0.line) }
            : board.runningOut.map { ($0.provider, $0.line) }
        let usedUp = alwaysShows ? board.usedUp.map { ($0.provider, $0.line) } : []
        let shown = (counted + usedUp).prefix(limit.count).map { provider, line in
            let label = line.data.title
            return MenuBarContent.Item(
                id: line.id,
                provider: provider,
                label: label,
                shortLabel: shortLabel(label),
                value: line.data.menuBarValue
            )
        }
        return MenuBarContent(items: shown, overflow: max(0, counted.count - shown.count))
    }

    /// Turns the saved bar slots into bars, top to bottom, skipping empty slots. A picked limit that isn't
    /// on the dashboard right now (no reading yet, or its account was removed) becomes an empty bar so the
    /// other bars keep their places.
    static func bars(slots: [String], accounts: [DashboardAccount]) -> [MenuBarContent.Bar] {
        let choices = barChoices(accounts: accounts)
        return slots.enumerated().compactMap { slot, lineID in
            guard !lineID.isEmpty else { return nil }
            let choice = choices.first { $0.id == lineID }
            return MenuBarContent.Bar(
                id: "\(slot).\(lineID)", // the slot number keeps IDs unique if one limit is picked twice
                label: choice?.label ?? "Unavailable",
                fraction: choice?.fraction
            )
        }
    }

    /// Every limit that can be a bar, in dashboard order: only those with a cap, since a bar needs
    /// something to fill toward. Each comes with the name Settings shows for it.
    static func barChoices(accounts: [DashboardAccount]) -> [(id: String, label: String, fraction: Double)] {
        accounts.flatMap { account in
            account.lines
                .filter { $0.data.hasData && $0.data.isBounded }
                .map { (id: $0.id, label: "\(account.provider.fullName) · \($0.data.title)", fraction: $0.data.fraction) }
        }
    }

    static func shortLabel(_ label: String) -> String {
        var words = label.split(separator: " ")
        guard words.count > 1, let last = words.last, genericWords.contains(last.lowercased()) else { return label }
        words.removeLast()
        return words.joined(separator: " ")
    }
}
