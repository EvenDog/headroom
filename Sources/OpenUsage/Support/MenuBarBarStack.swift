// Draws the limits picked in Settings → Menu Bar Bars as thin bars stacked top to bottom, for the menu bar.
// It's drawn in black at varying opacity: `MenuBarStripRenderer` turns it into a template image, so macOS
// recolors it for a light or dark menu bar and only the opacity carries through.

import AppKit
import SwiftUI

struct MenuBarBarStack: View {
    let content: MenuBarContent

    static let barWidth: CGFloat = 28
    static let barHeight: CGFloat = 4
    static let barGap: CGFloat = 2
    /// How visible the empty part of a bar is, so you can see where 100% is.
    static let trackOpacity: Double = 0.3

    var body: some View {
        HStack(spacing: 6) {
            VStack(spacing: Self.barGap) {
                ForEach(content.bars) { bar($0) }
            }
            if content.updateAvailable {
                Image(nsImage: MenuBarStripRenderer.appIconWithUpdateDot)
                    .renderingMode(.template)
            }
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .fixedSize()
        .compositingGroup()
    }

    /// One bar: a faint full-width track with a solid fill from the left, both clipped to rounded ends.
    private func bar(_ bar: MenuBarContent.Bar) -> some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(Color.black.opacity(Self.trackOpacity))
            Rectangle().fill(Color.black)
                .frame(width: Self.barWidth * (bar.fraction ?? 0))
        }
        .frame(width: Self.barWidth, height: Self.barHeight)
        .clipShape(Capsule())
    }
}
