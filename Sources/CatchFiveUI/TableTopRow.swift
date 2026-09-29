import SwiftUI

/// The slim row across the top of the table (D93): Home on the left goes back to the main menu, the match kept, and
/// the book on the right opens the rules. Nothing drops down and nothing pauses: leaving the table already saves the
/// game. It replaces the Table and Clarify bar (N68).
struct TableTopRow: View {
    struct Button: Equatable {
        let title: String
        let symbol: String
    }

    nonisolated static let home = Button(title: "Home", symbol: "house")
    nonisolated static let rules = Button(title: "Rules", symbol: "book")

    let onHome: () -> Void
    let onRules: () -> Void

    var body: some View {
        HStack {
            item(Self.home, hint: "Back to the main menu; your game is saved", action: onHome)
            Spacer(minLength: 0)
            item(Self.rules, hint: "Opens the rules", action: onRules)
        }
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
    }

    /// Glyph and word on a light tan pill, a full thumb tall.
    private func item(_ button: Button, hint: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            Label(button.title, systemImage: button.symbol)
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.Wood.streakDark)
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.horizontal, 14)
                .frame(minHeight: Theme.Table.topRowHeight)
                .background(Theme.Table.cornerFill, in: Capsule())
                .overlay(Capsule().stroke(Theme.Wood.light, lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(button.title)
        .accessibilityHint(hint)
    }
}
