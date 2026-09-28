import CatchFive
import SwiftUI

/// The pause card, shown over the dimmed table from the table's menu: Continue game (until the match is
/// won) and Main menu, which keeps the match and goes to the menu, where New match, Settings, the lessons,
/// statistics and the build explainer live (P02, P03). No greeting and no summary: the main menu carries those.
struct WelcomeCard: View {
    @ObservedObject var model: GameModel
    let onPlay: () -> Void
    /// Leaves the table for the main menu with the match preserved.
    let onMenu: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 2) {
                Text("CATCH 5").font(.system(.caption2, design: .monospaced).weight(.medium)).tracking(1).opacity(0.7)
                Text("Paused").font(.system(.title3, design: .serif).weight(.semibold))
            }
            .accessibilityElement(children: .combine)

            VStack(spacing: 10) {
                if model.match.winner == nil {
                    // A dealt hand is a game to return to even before the first bid.
                    prominent("Continue game", action: onPlay)
                    plain("Main menu", action: onMenu)
                } else {
                    prominent("Main menu", action: onMenu)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: 360)
        .background(Theme.Wood.inlay.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.ivory.opacity(0.18), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
        .foregroundStyle(.ivory)
        .padding(24)
    }

    private func prominent(_ label: String, action: @escaping () -> Void) -> some View {
        MenuButtons.prominent(label, action: action)
    }

    private func plain(_ label: String, action: @escaping () -> Void) -> some View {
        MenuButtons.plain(label, action: action)
    }
}

/// The menu's two buttons, shared by the pause card and the main menu: both solid brown with ivory
/// labels (D75: no see-through pills), so nothing on the wood ever shows felt through it. On the main
/// actor because the button styles are (CI's Swift 6.1 checks this).
@MainActor enum MenuButtons {
    static func prominent(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(label).font(.headline).frame(maxWidth: .infinity).frame(minHeight: 48) }
            .buttonStyle(.borderedProminent).tint(Theme.Wood.dark).foregroundStyle(.ivory)
    }

    static func plain(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(label).frame(maxWidth: .infinity).frame(minHeight: 44) }
            .buttonStyle(.borderedProminent).tint(Theme.Wood.dark).foregroundStyle(.ivory)
    }
}

extension View {
    /// Full screen on the phone, where the reader wants the whole display; a sheet on the macOS test build.
    func fullScreenCoverOrSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        #if os(iOS)
        return fullScreenCover(isPresented: isPresented, content: content)
        #else
        return sheet(isPresented: isPresented, content: content)
        #endif
    }
}
