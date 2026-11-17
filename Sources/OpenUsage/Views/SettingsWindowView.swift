// The content of the Settings window: a tab bar on top, then either the Accounts screen or the Settings
// form for the picked tab. It reuses the panel's own screens, driven by the window's own `PopoverState`,
// so moving around in this window never changes what the menu bar panel shows.

import SwiftUI

struct SettingsWindowView: View {
    static let minWidth: CGFloat = 400
    static let minHeight: CGFloat = 520
    private static let reorderSpace = "settingsWindowReorderSpace"

    @Environment(AppContainer.self) private var container
    @Environment(PopoverState.self) private var popover
    /// The row being dragged to reorder accounts or metrics, drawn floating above everything else.
    @State private var reorderLift: ReorderLift?

    var body: some View {
        @Bindable var popover = popover
        VStack(spacing: 0) {
            SettingsTabBar()
                .padding(.horizontal, PanelMetrics.margin)
                .padding(.vertical, 10)
            Divider()
            if popover.settingsTab == .accounts {
                accountsTab
            } else {
                SettingsScreen()
            }
        }
        .frame(minWidth: Self.minWidth, minHeight: Self.minHeight, alignment: .top)
        .background(Theme.panelBody)
        .overlay(alignment: .topLeading) {
            if let reorderLift { ReorderLiftPreview(lift: reorderLift) }
        }
        .coordinateSpace(name: Self.reorderSpace)
        .environment(\.concealsAccountNames, container.hideFromScreenShare.isConcealing)
        .sheet(isPresented: $popover.isAddingAccount, onDismiss: { popover.signingInAgainProviderID = nil }) {
            AddAccountSheet(container: container, popover: popover)
        }
        .onChange(of: popover.screen) { _, screen in
            reorderLift = nil
            // The panel refreshes CLIProxyAPI hubs whenever Accounts opens; keep doing that here.
            if screen == .accounts { Task { await container.hubs.syncDue(maxAge: 60) } }
        }
        .onChange(of: popover.customizeProviderID) { reorderLift = nil }
    }

    /// The panel's Accounts screen. The top bar (back button and account name) only shows inside one
    /// account's or hub's page: on the list itself the tab bar already says where you are, and the panel's
    /// back button there would leave for the dashboard, which this window doesn't have.
    private var accountsTab: some View {
        let isInsideAnAccount = popover.customizeProviderID != nil || popover.customizeHubID != nil
        return AccountsView(reorderSpaceName: Self.reorderSpace, reorderLift: $reorderLift)
            .panelBars {
                if isInsideAnAccount { PopoverTopBar(screen: .accounts) }
            } bottom: {
                PopoverFooter(screen: .accounts)
            }
    }
}
