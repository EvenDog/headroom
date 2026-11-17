// Checks that, once the panel has a Settings window, everything that used to slide the panel to Accounts
// or Settings asks the window instead, and that without one the panel behaves as it always did.

import XCTest
@testable import OpenUsage

@MainActor
final class SettingsWindowRoutingTests: XCTestCase {
    /// A panel state connected to a stand-in window that records every request.
    private func panelWithWindow() -> (PopoverState, () -> [SettingsWindowRequest]) {
        let panel = PopoverState()
        var requests: [SettingsWindowRequest] = []
        panel.opensSettingsWindow = { requests.append($0) }
        return (panel, { requests })
    }

    func testWithAWindowAccountsAndSettingsOpenThereAndThePanelStaysOnTheDashboard() {
        let (panel, requests) = panelWithWindow()

        panel.toggle(.settings)
        panel.toggle(.accounts)
        panel.openAccounts("claude@1")
        panel.openAccounts(nil)
        panel.addAccount()

        XCTAssertEqual(requests(), [.tab(.general), .tab(.accounts), .account("claude@1"), .account(nil), .addAccount])
        XCTAssertEqual(panel.screen, .dashboard)
        XCTAssertFalse(panel.isAddingAccount, "the sheet opens in the window, not over the panel")
    }

    func testWithoutAWindowThePanelSlidesAsBefore() {
        let panel = PopoverState()

        panel.toggle(.settings)
        XCTAssertEqual(panel.screen, .settings)
        panel.openAccounts("claude@1")
        XCTAssertEqual(panel.screen, .accounts)
        XCTAssertEqual(panel.customizeProviderID, "claude@1")
        panel.addAccount()
        XCTAssertTrue(panel.isAddingAccount)
    }

    func testTheAccountsTabShowsTheAccountsScreenAndEveryOtherTabShowsSettings() {
        let window = PopoverState()
        for tab in SettingsTab.allCases {
            window.selectSettingsTab(tab)
            XCTAssertEqual(window.settingsTab, tab)
            XCTAssertEqual(window.screen, tab == .accounts ? .accounts : .settings, "\(tab)")
        }
    }
}
