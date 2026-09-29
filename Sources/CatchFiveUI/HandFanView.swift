import CatchFive
import SwiftUI

/// The human's hand: six overlapped cards on a shallow fan, the dominant element on screen.
struct HandFanView: View {
    @ObservedObject var model: GameModel
    let namespace: Namespace.ID
    /// Called with the card when a tap is refused, so the table can shake it and buzz.
    let onIllegal: (Card) -> Void
    @Binding var shakes: [Card: Int]
    /// The centre of the deck beside the dealer, in the table's coordinate space; the refill deals in from it.
    var deck: CGPoint? = nil
    /// Your own deck, under the fan when you deal, says where it rests.
    var onDeck: (CGPoint) -> Void = { _ in }
    /// The phone holder's tag was tapped: rename that seat (D93).
    var onRename: (Int) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var scaledStandard = Theme.Card.handWidth
    @ScaledMetric(relativeTo: .title2) private var scaledWide = Theme.Card.handWidthWide
    /// The width the hand was actually given, so the arrangement is decided from a measurement.
    @State private var measuredWidth = 0.0
    /// Where the hand sits on the table, so a dealt card knows how far it has come from the deck.
    @State private var fanFrame = CGRect.zero

    private var wide: Bool { measuredWidth + 32 >= Theme.Card.wideScreenWidth }
    private var cardWidth: Double { wide ? Theme.Card.handWidthWide : Theme.Card.handWidth }
    private var scaledWidth: Double { wide ? scaledWide : scaledStandard }
    /// Fan or two rows: whichever keeps every card's exposed strip at least 44 pt (`HandLayout`).
    private var arrangement: HandLayout.Arrangement {
        // Before the first measurement the fan keeps its natural overlap; deciding on a zero width would
        // pick two rows and then tear the fan down once the real width lands.
        guard measuredWidth > 0 else { return .fan(strip: Theme.Card.touchStrip(width: scaledWidth)) }
        return HandLayout.arrange(count: model.humanCards.count, cardWidth: scaledWidth, available: measuredWidth - 16)
    }

    var body: some View {
        let cards = model.humanCards
        let arrangement = arrangement
        VStack(spacing: 6) {
            Group {
                switch arrangement {
                case .fan where model.match.hand.phase == .bidding && measuredWidth > 0:
                    // B01: while bidding, the hand lies flat on one baseline, evenly spaced; the fan comes back after.
                    row(cards, indices: Array(cards.indices), strip: HandLayout.baselineStrip(count: cards.count, cardWidth: scaledWidth,
                                                                                           available: measuredWidth - 16), fanned: false)
                case let .fan(strip):
                    row(cards, indices: Array(cards.indices), strip: strip, fanned: true)
                case let .rows(perRow, strip):
                    VStack(spacing: HandLayout.rowGap) {
                        row(cards, indices: Array(0..<min(perRow, cards.count)), strip: strip, fanned: false)
                        if cards.count > perRow { row(cards, indices: Array(perRow..<cards.count), strip: strip, fanned: false) }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
            .frame(height: HandLayout.height(of: arrangement, cardWidth: scaledWidth))
            .onGeometryChange(for: Double.self) { $0.size.width } action: { measuredWidth = $0 }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(TableLayout.space)) } action: { fanFrame = $0 }
            // No "Your hand" caption (T05). Under the hand, the phone holder's name carved into the wood, trump beside it
            // when they bid (D94), a tap renames them (D93), and, when yours, the deal with its dealer button.
            HStack(spacing: 10) {
                if let seat = model.viewerSeat {
                    let hand = model.match.hand
                    NameTag(name: model.seatNames[seat], trump: SeatView.carvedTrump(seat: seat, bidder: hand.auction.winner, trump: hand.trump))
                        .renames { onRename(seat) }
                }
                Spacer(minLength: 0)
                if !cards.isEmpty, model.match.hand.auction.dealer == model.viewerSeat {
                    DealerMark(onPlaced: onDeck, sideways: DealerMark.placement(forPlace: 0) == .besideYourName)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @State private var selectedCard: Card?

    /// One row of cards. Fanned rows rotate and dip; the two-row fallback lays cards flat so nothing
    /// overlaps a neighbour's touch strip.
    private func row(_ cards: [Card], indices: [Int], strip: Double, fanned: Bool) -> some View {
        let playing = model.match.hand.phase == .playing
        let fanCount = fanned ? cards.count : 1
        return HStack(spacing: strip - scaledWidth) {
            ForEach(indices, id: \.self) { index in
                let card = cards[index]
                let playable = model.allows(.play(card))
                let isSelected = selectedCard == card
                let style: CardStyle = playing && model.isHumanTurn ? (playable ? .playable : .dimmed) : .rest
                Button {
                    if playable {
                        if selectedCard == card {
                            model.send(.play(card))
                            selectedCard = nil
                        } else {
                            selectedCard = card
                        }
                    } else {
                        onIllegal(card)
                        selectedCard = nil
                    }
                } label: {
                    CardView(card: card, width: cardWidth, style: style)
                        .overlay(RoundedRectangle(cornerRadius: Theme.Card.radius(width: cardWidth), style: .continuous)
                            .strokeBorder(.ivory.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                            .opacity(model.hint?.action == .play(card) ? 1 : 0))
                }
                .buttonStyle(CardPressStyle(enabled: playable))
                .modifier(ShakeEffect(trigger: shakes[card, default: 0]))
                .rotationEffect(.degrees(reduceMotion || !fanned ? 0 : fanAngle(index, of: fanCount)), anchor: .bottom)
                .offset(y: reduceMotion || !fanned ? 0 : fanDrop(index, of: fanCount))
                .offset(y: isSelected ? -24 : 0)
                .allowsHitTesting(playing)
                .accessibilityValue(model.accessibilityValue(for: card))
                .modifier(MatchedCard(card: card, namespace: namespace, enabled: !reduceMotion))
                .transition(handTransition(index: index, slot: indices.firstIndex(of: index) ?? 0, count: indices.count, strip: strip))
                .zIndex(isSelected ? 100 : Double(index))
            }
        }
    }

    /// How a card enters or leaves the fan. A played card leaves by `matchedGeometryEffect` (identity
    /// here). While trump is being chosen, a leaving card is a discard: it rises toward the table and
    /// fades, one after another. At the start of play, an arriving card is part of the refill: it
    /// deals in from the deck beside the dealer, deck-sized and faint, after the discards have gone.
    private func handTransition(index: Int, slot: Int, count: Int, strip: Double) -> AnyTransition {
        if reduceMotion { return .opacity }
        let hand = model.match.hand
        let dealing = hand.phase == .playing && hand.currentTrick.isEmpty && hand.completedTricks.isEmpty
        // Until the deck has said where it rests, a refill card fades in where it lands.
        let flight = deck.map { Self.dealOrigin(slot: slot, count: count, strip: strip, cardWidth: scaledWidth, in: fanFrame, deck: $0) } ?? .zero
        let insertion: AnyTransition = dealing
            ? .offset(flight)
                .combined(with: .scale(scale: Theme.Table.dealerMarkDeckWidth / scaledWidth)).combined(with: .opacity)
                .animation(Theme.Motion.flight.delay(Theme.Motion.dealDelay + Double(index) * Theme.Motion.dealStagger))
            : .identity
        // A discard flies to the pile in the top-left corner, shrinking to a card back.
        let removal: AnyTransition = hand.phase == .choosingTrump
            ? .offset(Self.discardTarget(index: index, count: model.humanCards.count, width: measuredWidth))
                .combined(with: .scale(scale: Theme.Table.deckWidth / scaledWidth)).combined(with: .opacity)
                .animation(Theme.Motion.collapse.delay(Double(index) * Theme.Motion.discardStagger))
            : .identity
        return .asymmetric(insertion: insertion, removal: removal)
    }

    /// Where a card of a row comes to rest: `strip` apart around the middle of the hand's `frame`, on its
    /// bottom edge. `slot` counts from the left of the row.
    nonisolated static func cardCentre(slot: Int, count: Int, strip: Double, cardWidth: Double, in frame: CGRect) -> CGPoint {
        CGPoint(x: frame.midX + (Double(slot) - Double(count - 1) / 2) * strip,
                y: frame.maxY - cardWidth * Theme.Card.ratio / 2)
    }

    /// Where a dealt card starts, relative to its place in the fan: the deck beside the dealer (T12), wherever
    /// that seat sits. `frame` and `deck` share the table's coordinate space.
    nonisolated static func dealOrigin(slot: Int, count: Int, strip: Double, cardWidth: Double, in frame: CGRect, deck: CGPoint) -> CGSize {
        let centre = cardCentre(slot: slot, count: count, strip: strip, cardWidth: cardWidth, in: frame)
        return CGSize(width: deck.x - centre.x, height: deck.y - centre.y)
    }

    /// Where a discard lands: the pile in the top-left corner, level with the deck (spec R3).
    nonisolated static func discardTarget(index: Int, count: Int, width: Double) -> CGSize {
        let cardCentre = (Double(index) + 0.5) * width / Double(max(count, 1))
        return CGSize(width: Theme.Table.deckWidth * 0.85 / 2 - cardCentre, height: -Theme.Table.deckRise)
    }

    /// Cards rotate from −8° on the left to +8° on the right about their bottom edge.
    private func fanAngle(_ index: Int, of count: Int) -> Double {
        guard count > 1 else { return 0 }
        let t = Double(index) / Double(count - 1)
        return (t - 0.5) * 2 * Theme.Card.fanRotationDegrees
    }

    /// The outer cards sit a little lower so the tops trace a shallow arc.
    private func fanDrop(_ index: Int, of count: Int) -> Double {
        guard count > 1 else { return 0 }
        let t = Double(index) / Double(count - 1)
        return pow((t - 0.5) * 2, 2) * Theme.Card.fanDrop
    }
}

/// Three quick side-to-side oscillations over 0.3 s; runs whenever `trigger` changes.
struct ShakeEffect: ViewModifier {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        // Under Reduce Motion nothing moves; the refusal reason on the message line does the talking.
        let a = reduceMotion ? 0 : Theme.Motion.shakeAmplitude
        content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(-a, duration: 0.05)
                CubicKeyframe(a, duration: 0.08)
                CubicKeyframe(-a * 0.8, duration: 0.07)
                CubicKeyframe(a * 0.5, duration: 0.05)
                CubicKeyframe(0, duration: 0.05)
            }
        }
    }
}

/// Joins a hand card to its pile counterpart so a play flies between them; off under Reduce Motion.
struct MatchedCard: ViewModifier {
    let card: Card
    let namespace: Namespace.ID
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled { content.matchedGeometryEffect(id: card, in: namespace) } else { content }
    }
}
