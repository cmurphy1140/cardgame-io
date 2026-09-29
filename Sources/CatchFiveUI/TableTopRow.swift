import SwiftUI

/// The slim row across the top of the table (D93): Home on the left, carved into the wood, goes back to the main menu,
/// the match kept, and the closed book lying on the right opens the rules (D94). Nothing drops down and nothing pauses: leaving the table already saves the
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
            item(Self.home, hint: "Back to the main menu; your game is saved", action: onHome) {
                // The house and the word set into the wood (D94), no pill.
                Label(Self.home.title, systemImage: Self.home.symbol)
                    .font(.title3.weight(.heavy))
                    .carved()
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            item(Self.rules, hint: "Opens the rules", action: onRules) { RulesBook() }
        }
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
    }

    /// One control of the row: whatever lies on the table there, inside a thumb-tall hit area.
    private func item(_ button: Button, hint: String, action: @escaping () -> Void, @ViewBuilder label: () -> some View) -> some View {
        SwiftUI.Button(action: action) {
            label()
                .padding(.horizontal, 6)
                .frame(minWidth: Theme.Table.topRowHeight, minHeight: Theme.Table.topRowHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(button.title)
        .accessibilityHint(hint)
    }
}
