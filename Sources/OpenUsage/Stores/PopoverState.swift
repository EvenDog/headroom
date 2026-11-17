import Observation
import SwiftUI

enum PopoverScreen: Hashable, Sendable {
    case dashboard
    case accounts
    case settings

    var slideRank: Int {
        switch self {
        case .dashboard: 0
        case .accounts: 1
        case .settings: 2
        }
    }
}

enum SettingsTab: Hashable, Sendable, CaseIterable {
    case general, accounts, display, alerts, advanced

    var title: String {
        switch self {
        case .general: "General"
        case .accounts: "Accounts"
        case .display: "Display"
        case .alerts: "Alerts"
        case .advanced: "Advanced"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .accounts: "person.crop.circle"
        case .display: "macwindow"
        case .alerts: "bell"
        case .advanced: "terminal"
        }
    }
}

/// What the panel asks the Settings window to show.
enum SettingsWindowRequest: Equatable {
    case tab(SettingsTab)
    /// The Accounts tab, opened to one account's page, or to the list when nil.
    case account(String?)
    /// The Accounts tab with the Add Account sheet open.
    case addAccount
}

@MainActor
@Observable
final class PopoverState {
    /// Set only on the panel's state, by `StatusItemController`. When set, Accounts and Settings open in the
    /// Settings window instead of sliding over the panel. Left nil, the panel slides as it always did.
    @ObservationIgnored var opensSettingsWindow: ((SettingsWindowRequest) -> Void)?

    var screen = PopoverScreen.dashboard {
        didSet {
            guard screen != oldValue else { return }
            // Recorded synchronously with the change — not via SwiftUI's `onChange`, which fires a
            // frame later and would let the popover paint the destination before the slide begins.
            // DashboardView reads these on its very next render to slide in from the screen being left.
            screenSlideFrom = oldValue
            screenSlideID += 1
            if screen != .accounts {
                customizeProviderID = nil
                customizeHubID = nil
                isAddingAccount = false
            }
        }
    }
    private(set) var screenSlideFrom = PopoverScreen.dashboard
    private(set) var screenSlideID = 0
    var customizeProviderID: String?
    /// The CLIProxyAPI hub whose page Accounts shows. An account opened from it goes back to it.
    var customizeHubID: UUID?
    var isAddingAccount = false
    /// The account the Add Account sheet signs in again, in place of adding a new one.
    var signingInAgainProviderID: String?
    var dashboardTab = DashboardTab.priority
    var settingsTab = SettingsTab.general
    /// Whether the popover is on-screen. `StatusItemController` flips it at its show/hide chokepoints,
    /// synchronously with `makeKeyAndOrderFront`/`orderOut`, and `DashboardView` re-seeds the panel
    /// height on reopen from it. Deliberately not derived from occlusion or window key state: a
    /// `.canJoinAllSpaces` panel is briefly fully occluded mid Space-switch while still following the
    /// user on-screen. Never persisted.
    var popoverShown = false

    let shareNotice = TransientNotice<Bool>(clearedValue: false, timeout: .seconds(2.5))

    @discardableResult
    func back() -> Bool {
        if customizeProviderID != nil {
            withAnimation(Motion.navigation) { customizeProviderID = nil }
            return true
        }
        if customizeHubID != nil {
            withAnimation(Motion.navigation) { customizeHubID = nil }
            return true
        }
        guard screen != .dashboard else { return false }
        withAnimation(Motion.modeSwitch) { screen = .dashboard }
        return true
    }

    func toggle(_ target: PopoverScreen) {
        if let opensSettingsWindow, target != .dashboard {
            opensSettingsWindow(.tab(target == .accounts ? .accounts : .general))
            return
        }
        withAnimation(Motion.modeSwitch) { screen = screen == target ? .dashboard : target }
    }

    func openAccounts(_ providerID: String?) {
        if let opensSettingsWindow {
            opensSettingsWindow(.account(providerID))
            return
        }
        withAnimation(Motion.modeSwitch) {
            customizeProviderID = providerID
            customizeHubID = nil
            screen = .accounts
        }
    }

    /// Opens the Add Account sheet: in the Settings window when the panel has one, otherwise right here.
    func addAccount() {
        if let opensSettingsWindow {
            opensSettingsWindow(.addAccount)
        } else {
            isAddingAccount = true
        }
    }

    /// Picks a tab in the Settings window. Accounts shows the accounts screen; every other tab shows Settings.
    func selectSettingsTab(_ tab: SettingsTab) {
        settingsTab = tab
        screen = tab == .accounts ? .accounts : .settings
    }

    func showDashboard(on tab: DashboardTab) {
        dashboardTab = tab
        withAnimation(Motion.modeSwitch) { screen = .dashboard }
    }

    func show(dashboardTab: DashboardTab) {
        self.dashboardTab = dashboardTab
        popoverShown = true
    }

    func reset() {
        if screen != .dashboard { screen = .dashboard }
        settingsTab = .general
        shareNotice.clear()
    }
}
