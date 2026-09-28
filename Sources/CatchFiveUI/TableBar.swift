import SwiftUI

/// The bar pinned above the table (N68): one long, skinny bar of two boxes, Table and Clarify, each opening a
/// drop-down under it. Table pauses, starts over or goes home; Clarify answers "what am I looking at" in a few big
/// words. Play waits while a drop-down is open (`TablePause.menuShown`). It replaces the lone pause button.
struct TableBar: View {
    enum Box: CaseIterable {
        case table, clarify

        var title: String {
            switch self {
            case .table: "Table"
            case .clarify: "Clarify"
            }
        }
    }

    enum TableItem: CaseIterable {
        case pause, newGame, home

        var title: String {
            switch self {
            case .pause: "Pause"
            case .newGame: "New game"
            case .home: "Home"
            }
        }
    }

    /// New game asks Solo or Pass and play first; the start-over alert checks after (D57).
    struct NewGameChoice: Equatable {
        let title: String
        let mode: PlayMode
    }

    nonisolated static let newGameChoices = [NewGameChoice(title: "Solo", mode: .solo),
                                             NewGameChoice(title: "Pass and play", mode: .passAndPlay)]

    /// One short answer under Clarify.
    struct Answer: Equatable {
        let topic: String
        let text: String
    }

    nonisolated static let answers = [
        Answer(topic: "The bid box", text: "Who bid, what they bid, and trump."),
        Answer(topic: "The scorecard", text: "Each team's score after every hand. Tap it to see them all."),
        Answer(topic: "Tap the suit", text: "Adds a mark each time trump is played. Hold it to take one back."),
        Answer(topic: "Tap a face", text: "Marks that player out of trump. Tap again to clear it."),
    ]

    nonisolated static let howToPlay = "How to play"

    /// The drop-down that is open, if any.
    @Binding var open: Box?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Box.allCases, id: \.self) { box in
                Button { open = open == box ? nil : box } label: {
                    HStack(spacing: 6) {
                        Text(box.title).font(.headline.weight(.heavy))
                        Image(systemName: "chevron.down").font(.caption.weight(.heavy))
                            .rotationEffect(.degrees(open == box ? 180 : 0))
                    }
                    .foregroundStyle(Theme.Wood.streakDark)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: Theme.Table.barHeight)
                    .background(open == box ? Theme.Wood.streakLight : Theme.Table.cornerFill,
                                in: RoundedRectangle(cornerRadius: Theme.Table.barRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Table.barRadius, style: .continuous).stroke(Theme.Wood.light, lineWidth: 1.5))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(box.title)
                .accessibilityHint(box == .table ? "Pause, new game or home" : "What the table is showing")
                .accessibilityAddTraits(open == box ? .isSelected : [])
            }
        }
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
    }
}

/// What drops down under the bar: the Table choices or the Clarify answers, on a light tan card.
struct TableBarMenu: View {
    let box: TableBar.Box
    let onPause: () -> Void
    let onNewGame: (PlayMode) -> Void
    let onHome: () -> Void
    let onHowToPlay: () -> Void
    let onClose: () -> Void
    /// New game has been tapped: Solo or Pass and play show in its place.
    @State private var choosingMode = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.45).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                switch box {
                case .table: tableItems
                case .clarify: clarify
                }
            }
            .foregroundStyle(Theme.Wood.streakDark)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Table.cornerFill, in: RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous).stroke(Theme.Wood.light, lineWidth: 2))
            .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
            .padding(.horizontal, 16)
        }
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
    }

    @ViewBuilder private var tableItems: some View {
        if choosingMode {
            Text("New game").font(.title3.weight(.heavy))
            ForEach(TableBar.newGameChoices, id: \.title) { choice in
                MenuButtons.prominent(choice.title) { onNewGame(choice.mode) }
            }
            MenuButtons.plain("Back") { choosingMode = false }
        } else {
            ForEach(TableBar.TableItem.allCases, id: \.self) { item in
                MenuButtons.prominent(item.title) {
                    switch item {
                    case .pause: onPause()
                    case .newGame: choosingMode = true
                    case .home: onHome()
                    }
                }
            }
        }
    }

    @ViewBuilder private var clarify: some View {
        ForEach(TableBar.answers, id: \.topic) { answer in
            VStack(alignment: .leading, spacing: 1) {
                Text(answer.topic).font(.title3.weight(.heavy))
                Text(answer.text).font(.body.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
        MenuButtons.prominent(TableBar.howToPlay, action: onHowToPlay)
    }
}
