import CatchFive
import SwiftUI

/// The full score sheet, opened from the scorecard (N66): both teams side by side, each with its total and the 25
/// points as dots filled in green up to it, and the hands so far as cards that page sideways, newest first, so
/// nothing scrolls down. A tap outside it or a swipe up or down closes it.
struct ScorePanel: View {
    /// One finished hand, from one team's side.
    struct HandCard: Equatable {
        let number: Int
        /// "Cheryl bid 5, made".
        let line: String
        /// What the hand did to this team's score.
        let change: Int
        /// This team's score after the hand.
        let total: Int
        /// This team held the bid.
        let ourBid: Bool
    }

    struct Content: Equatable {
        let total: Int
        /// How many of the 25 dots are filled.
        let dots: Int
        let hands: [HandCard]
    }

    /// The dots a score fills: none below zero, all 25 from 25 up.
    nonisolated static func dots(_ score: Int) -> Int { min(HouseRules.matchTarget, max(0, score)) }

    /// `team`'s side of the sheet from the match's finished hands.
    nonisolated static func content(team: Int, history: [HandSummary], seatNames: [String]) -> Content {
        var before = 0
        let hands = history.map { hand in
            defer { before = hand.scores[team] }
            let bid = hand.isNineAndOut ? "9 and out" : String(hand.bid)
            return HandCard(number: hand.number, line: "\(seatNames[hand.bidder]) bid \(bid), \(hand.contractMade ? "made" : "set")",
                            change: hand.scores[team] - before, total: hand.scores[team], ourBid: hand.bidder % 2 == team)
        }
        let total = history.last?.scores[team] ?? 0
        return Content(total: total, dots: dots(total), hands: hands)
    }

    /// The phone holder's team and the other team.
    let us: Content
    let them: Content
    /// US and THEM in solo, the pairs' names in pass and play (`Scorecard.label(us:mode:teamNames:)`).
    let usLabel: String
    let themLabel: String
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)
                .gesture(DragGesture(minimumDistance: 20).onEnded { _ in onClose() })
                .accessibilityHidden(true)
            panel
                .padding(.horizontal, 12).padding(.bottom, 8)
                // A swipe up or down on the panel closes it; sideways belongs to the hands.
                .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { drag in
                    if abs(drag.translation.height) > abs(drag.translation.width) { onClose() }
                })
        }
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
    }

    private var panel: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                side(label: usLabel, content: us)
                side(label: themLabel, content: them)
            }
            hands
        }
        .foregroundStyle(Theme.Wood.streakDark)
        .padding(16)
        .background(Theme.Table.cornerFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.Wood.light, lineWidth: 2))
        .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
    }

    /// One team: its label and total over its dots.
    private func side(label: String, content: Content) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(.title3.weight(.heavy)).lineLimit(1).minimumScaleFactor(0.5)
                Spacer(minLength: 4)
                Text(content.total, format: .number).font(.system(size: 40, weight: .heavy, design: .rounded)).monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            dotsGrid(content.dots)
        }
        .frame(maxWidth: .infinity)
    }

    /// 1 to 25 in five rows of five, filled green up to the total.
    private func dotsGrid(_ dots: Int) -> some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            ForEach(0..<5, id: \.self) { row in
                GridRow {
                    ForEach(1...5, id: \.self) { column in
                        let point = row * 5 + column
                        let filled = point <= dots
                        Text("\(point)").font(.caption.weight(.bold)).monospacedDigit().minimumScaleFactor(0.6)
                            .foregroundStyle(filled ? Theme.Table.dotInk : Theme.Wood.dark.opacity(0.7))
                            .frame(width: 26, height: 26)
                            .background(filled ? Theme.Table.dotFill : .clear, in: Circle())
                            .overlay(Circle().stroke(filled ? Theme.Table.dotFillEdge : Theme.Wood.light, lineWidth: 1.5))
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dots) of \(HouseRules.matchTarget) points")
    }

    /// The hands so far, one card each with both teams' change and total, newest first, paging sideways.
    @ViewBuilder private var hands: some View {
        if us.hands.isEmpty {
            Text("No hands scored yet").font(.headline).opacity(0.75).frame(height: Self.cardHeight)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(Array(zip(us.hands, them.hands).reversed()), id: \.0.number) { ours, theirs in
                        handCard(ours, theirs).containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .frame(height: Self.cardHeight)
        }
    }

    private static let cardHeight = 104.0

    private func handCard(_ ours: HandCard, _ theirs: HandCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("Hand \(ours.number)").font(.headline.weight(.heavy))
                Text(ours.line).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.6)
            }
            HStack(spacing: 12) {
                change(label: usLabel, ours)
                change(label: themLabel, theirs)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.ivory, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.Wood.light, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }

    /// One team's line on a hand card: its label, the change, and "now" the total; BID on the team that bid.
    private func change(label: String, _ hand: HandCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(label).font(.caption.weight(.heavy)).lineLimit(1).minimumScaleFactor(0.6)
                if hand.ourBid {
                    Text("BID").font(.system(.caption2, design: .monospaced).weight(.semibold)).tracking(1.5).foregroundStyle(Theme.Wood.dark)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(hand.change >= 0 ? "+\(hand.change)" : "\(hand.change)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded)).monospacedDigit()
                Text("now \(hand.total)").font(.subheadline.weight(.bold)).monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
