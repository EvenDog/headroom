// Owns the Settings window: an ordinary macOS window holding `SettingsWindowView`, opened from the panel's
// Options menu, ⌘, the status item's right-click menu, and anywhere the panel used to open Accounts.
// The window is made once and kept; closing it only hides it.

import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let container: AppContainer
    /// The window's own navigation state, separate from the panel's, so the two never move each other.
    private let state = PopoverState()
    private let window: NSWindow

    init(container: AppContainer, updater: UpdaterController) {
        self.container = container
        let host = NSHostingView(
            rootView: SettingsWindowView()
                .reduceAnimationsWhenRequested()
                .environment(container)
                .environment(container.layout)
                .environment(container.dataStore)
                .environment(container.renaming)
                .environment(state)
                .environment(updater)
        )
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: SettingsWindowView.minWidth, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Headroom Settings"
        window.contentView = host
        window.contentMinSize = NSSize(width: SettingsWindowView.minWidth, height: SettingsWindowView.minHeight)
        window.isReleasedWhenClosed = false // keep the window around so reopening is instant
        window.center()
        // Remembers where you put the window (and its size) between launches.
        window.setFrameAutosaveName("OpenUsageSettingsWindow")
        super.init()
        window.delegate = self
    }

    /// Brings the window to the front, showing what `request` asks for.
    func show(_ request: SettingsWindowRequest) {
        switch request {
        case .tab(let tab):
            state.selectSettingsTab(tab)
        case .account(let providerID):
            state.selectSettingsTab(.accounts)
            state.customizeHubID = nil
            state.customizeProviderID = providerID
        case .addAccount:
            state.selectSettingsTab(.accounts)
            state.isAddingAccount = true
        }
        // A menu-bar app isn't the active app until asked, and an inactive app's window can't take typing.
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// Closing returns the window to General with nothing open, like the panel does when it closes.
    func windowWillClose(_ notification: Notification) {
        container.renaming.commit()
        state.reset()
    }
}
