import CatchFive
import SwiftUI

/// One team's score, risen from its rail's foot over the table (N62): the total, the 25 points as dots filled in
/// green up to it, and the hands so far as cards that page sideways, so nothing scrolls down. A tap outside it or
/// a swipe closes it. It replaces the full Score page the header's score used to open.
struct ScorePanel: View {
    /// One finished hand, from this team's side.
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

    /// `team`'s panel from the match's finished hands.
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

    let content: Content
    /// US or THEM in solo, the pair's names in pass and play (the rail's own label).
    let label: String
    /// The two players, "Cheryl + Connor".
    let names: String
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
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(label).font(.title2.weight(.heavy)).lineLimit(1).minimumScaleFactor(0.6)
                    Text(names).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.6).opacity(0.8)
                }
                Spacer(minLength: 8)
                Text(content.total, format: .number).font(.system(size: 56, weight: .heavy, design: .rounded)).monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            dotsGrid
            hands
        }
        .foregroundStyle(Theme.Wood.streakDark)
        .padding(16)
        .background(Theme.Table.cornerFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.Wood.light, lineWidth: 2))
        .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
    }

    /// 1 to 25 in five rows of five, filled green up to the total.
    private var dotsGrid: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 6) {
            ForEach(0..<5, id: \.self) { row in
                GridRow {
                    ForEach(1...5, id: \.self) { column in
                        let point = row * 5 + column
                        let filled = point <= content.dots
                        Text("\(point)").font(.subheadline.weight(.bold)).monospacedDigit()
                            .foregroundStyle(filled ? Theme.Table.railEdge : Theme.Wood.dark.opacity(0.7))
                            .frame(width: 34, height: 34)
                            .background(filled ? Theme.Table.railFill : .clear, in: Circle())
                            .overlay(Circle().stroke(filled ? Theme.Table.railFillEdge : Theme.Wood.light, lineWidth: 1.5))
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(content.dots) of \(HouseRules.matchTarget) points")
    }

    /// The hands so far, one card each, newest first, paging sideways.
    @ViewBuilder private var hands: some View {
        if content.hands.isEmpty {
            Text("No hands scored yet").font(.headline).opacity(0.75).frame(height: Self.cardHeight)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(content.hands.reversed(), id: \.number) { hand in
                        handCard(hand).containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .frame(height: Self.cardHeight)
        }
    }

    private static let cardHeight = 92.0

    private func handCard(_ hand: HandCard) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Hand \(hand.number)").font(.headline.weight(.heavy))
                    // The hands this team bid carry the plaque's eyebrow.
                    if hand.ourBid {
                        Text("BID").font(.system(.caption2, design: .monospaced).weight(.semibold)).tracking(1.5).foregroundStyle(Theme.Wood.dark)
                    }
                }
                Text(hand.line).font(.subheadline.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 0) {
                Text(hand.change >= 0 ? "+\(hand.change)" : "\(hand.change)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded)).monospacedDigit()
                Text("now \(hand.total)").font(.subheadline.weight(.bold)).monospacedDigit()
            }
        }
        .padding(12)
        .frame(maxHeight: .infinity)
        .background(.ivory, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.Wood.light, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }
}
