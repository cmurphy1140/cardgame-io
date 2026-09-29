import SwiftUI

/// The slim row across the top of the table (D93): Home on the left, a back arrow carved into the wood (D95), goes back to the main menu,
/// the match kept, and the closed book lying on the right opens the rules (D94). Nothing drops down and nothing pauses: leaving the table already saves the
/// game. It replaces the Table and Clarify bar (N68).
struct TableTopRow: View {
    struct Button: Equatable {
        let title: String
        let symbol: String
        /// The title is printed on the control; when false it is only VoiceOver's label (D95).
        var showsTitle = true
    }

    nonisolated static let home = Button(title: "Home", symbol: "arrow.backward", showsTitle: false)
    nonisolated static let rules = Button(title: "Rules", symbol: "book")

    let onHome: () -> Void
    let onRules: () -> Void

    var body: some View {
        HStack {
            item(Self.home, hint: "Back to the main menu; your game is saved", action: onHome) {
                // A back arrow alone, cut into the wood (D95): no house, no word, no pill.
                Image(systemName: Self.home.symbol)
                    .font(.system(size: Theme.Table.homeArrowSize, weight: .black))
                    .modifier(Carved(depth: Carving.depth(size: Theme.Table.homeArrowSize)))
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
