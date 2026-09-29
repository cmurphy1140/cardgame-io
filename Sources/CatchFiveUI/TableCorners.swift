import CatchFive
import SwiftUI

/// The bid box in the table's top-left corner once the auction resolves (D65, D87): Connor's three biggest things,
/// who bid (their own face), the bid large in the display serif under a small BID eyebrow (9 and out reads as a 9
/// with "and out"), and trump, the suit big in its own colour once it is named (N63, N67). The suit is also the
/// player's tally of trumps played: tap adds a mark, press and hold takes one back; the app never counts for the
/// player (spec R4), it only keeps the marks they make. The separate trump tile is gone.
struct ContractPlaque: View {
    struct Contract: Equatable {
        let bid: Int
        let isNineAndOut: Bool
        let bidder: String
        /// The bidder's face, the same as at their seat.
        let portrait: Portrait
        /// Trump, once the bidder has named it.
        var trump: Suit? = nil

        /// The big figure: the bid, or 9 for 9 and out.
        var number: String { isNineAndOut ? "9" : String(bid) }
        /// The words under a 9 and out's figure; nil for an ordinary bid.
        var qualifier: String? { isNineAndOut ? "and out" : nil }
        var spoken: String { "\(bidder) bid \(isNineAndOut ? "9 and out" : String(bid))" }
    }

    /// The contract once the auction has resolved: the bid, who holds it, and trump when it is named.
    static func contract(in model: GameModel) -> Contract? {
        let auction = model.match.hand.auction
        guard auction.nextSeat == nil, let bidder = auction.winner, let bid = auction.highestBid else { return nil }
        return Contract(bid: bid, isNineAndOut: auction.isNineAndOut, bidder: model.seatNames[bidder],
                        portrait: Cast.opponent(at: bidder)?.portrait ?? model.settings.playerPortrait,
                        trump: model.match.hand.trump)
    }

    /// The box as the table shows it: the player's tally on the suit, and the demo's pulse on it (N61).
    static func onTable(_ model: GameModel, contract: Contract, width: Double) -> ContractPlaque {
        ContractPlaque(contract: contract, width: width, tally: model.trumpTally, demo: model.tallyDemo == .trump,
                       onAdd: model.tallyTrump, onTakeBack: model.untallyTrump)
    }

    let contract: Contract
    /// The corner's width, from `TableLayout.cornerWidth(available:)`; the height is `Theme.Table.cornerHeight`.
    let width: Double
    var tally = 0
    /// The tally demo is pointing at the suit.
    var demo = false
    var onAdd: () -> Void = {}
    var onTakeBack: () -> Void = {}

    /// The light tan of both corners, and the dark wood browns the box's words are set in (D76).
    static let fill = Theme.Table.cornerFill
    static let eyebrowInk = Theme.Wood.dark
    static let numberInk = Theme.Wood.streakDark

    /// The word printed beside the suit, so the glyph reads as trump and not as a card (D93).
    nonisolated static let trumpWord = "Trump"

    /// Red for hearts and diamonds, black for spades and clubs: the suit's own colour, never a control's.
    nonisolated static func glyphColor(_ suit: Suit) -> Color { suit.isRed ? .suitRed : .black }

    /// "Diane bid 4, hearts are trump, 3 trump played".
    static func spoken(_ contract: Contract, tally: Int) -> String {
        guard let trump = contract.trump else { return contract.spoken }
        return "\(contract.spoken), \(trump.rawValue) are trump, \(tally) trump played"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 4) {
                PortraitView(portrait: contract.portrait, size: Theme.Table.plaquePortraitSize, popsOut: true)
                    .padding(.top, Theme.Table.plaquePortraitSize * Theme.Table.portraitHeadroom)
                VStack(spacing: -6) {
                    Text("BID").font(.system(.caption2, design: .monospaced).weight(.semibold)).tracking(1.5)
                        .foregroundStyle(Self.eyebrowInk)
                    Text(contract.number).font(.system(size: Theme.Table.plaqueNumberSize, weight: .bold, design: .serif))
                        .foregroundStyle(Self.numberInk)
                    if let qualifier = contract.qualifier {
                        Text(qualifier).font(.caption.weight(.semibold)).foregroundStyle(Self.numberInk)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(contract.spoken)
            suit
        }
        .lineLimit(1).minimumScaleFactor(0.6)
        .padding(.horizontal, 6).padding(.vertical, 4)
        .frame(width: width, height: Theme.Table.cornerHeight)
        .background(Self.fill, in: RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous).stroke(Theme.Wood.light, lineWidth: 1.5))
        .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .accessibilityElement(children: .contain)
    }

    /// Trump and its tally strokes, the tap target; an empty line of the same height until trump is named.
    @ViewBuilder private var suit: some View {
        if let trump = contract.trump {
            HStack(spacing: 6) {
                Text(trump.glyph).font(.system(size: Theme.Table.bidBoxSuitSize))
                    .foregroundStyle(Self.glyphColor(trump))
                    .modifier(DemoTap(active: demo))
                // The word sits over the tally, the way BID sits over the number, so the row keeps its height.
                VStack(alignment: .leading, spacing: 0) {
                    Text(Self.trumpWord).font(.system(size: Theme.Table.trumpWordSize, weight: .heavy))
                        .foregroundStyle(Self.numberInk)
                    TallyMarks(count: tally).frame(maxWidth: .infinity).frame(height: Theme.Table.tallyHeight)
                }
            }
            .frame(height: Theme.Table.bidBoxSuitSize * 1.15)
            .contentShape(Rectangle())
            .onTapGesture(perform: onAdd)
            .onLongPressGesture(perform: onTakeBack)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.spoken(contract, tally: tally))
            .accessibilityHint("Tap when a trump is played; swipe up or down to change the count")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onAdd() }
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: onAdd()
                case .decrement: onTakeBack()
                @unknown default: break
                }
            }
        } else {
            Color.clear.frame(height: Theme.Table.bidBoxSuitSize * 1.15)
        }
    }
}

/// A corner's arrival (N53): the first time it fills it grows in with a light glow that fades, so players know
/// where to look; under Reduce Motion it fades in instead.
struct CornerArrival: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false
    @State private var glowing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: .ivory.opacity(glowing ? 0.9 : 0), radius: 14)
            .scaleEffect(arrived || reduceMotion ? 1 : Theme.Table.cornerArrivalScale)
            .opacity(arrived ? 1 : 0)
            .onAppear {
                guard !reduceMotion else {
                    withAnimation(Theme.Motion.reduced) { arrived = true }
                    return
                }
                glowing = true
                withAnimation(.spring(duration: 0.45, bounce: 0.35)) { arrived = true }
                withAnimation(.easeOut(duration: Theme.Table.cornerGlowSeconds).delay(0.3)) { glowing = false }
            }
    }
}

/// Tally strokes in groups of five, the fifth drawn across the four before it, as on paper, in dark brown beside
/// the suit in the bid box.
struct TallyMarks: View {
    let count: Int

    /// The strokes in each group, left to right: 13 is [5, 5, 3].
    nonisolated static func groups(_ count: Int) -> [Int] {
        stride(from: 0, to: max(count, 0), by: 5).map { min(5, count - $0) }
    }

    var body: some View {
        Canvas { context, size in
            let step = Theme.Table.tallyStep, gap = Theme.Table.tallyGroupGap
            let groupWidth = 3 * step
            var x = 1.0
            for strokes in Self.groups(count) {
                var path = Path()
                for index in 0..<min(strokes, 4) {
                    let stroke = x + Double(index) * step
                    path.move(to: CGPoint(x: stroke, y: 1))
                    path.addLine(to: CGPoint(x: stroke, y: size.height - 1))
                }
                if strokes == 5 {
                    path.move(to: CGPoint(x: x - 2, y: size.height - 3))
                    path.addLine(to: CGPoint(x: x + groupWidth + 2, y: 3))
                }
                context.stroke(path, with: .color(Theme.Wood.streakDark), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                x += groupWidth + gap
            }
        }
        .accessibilityHidden(true)
    }
}

/// The player's mark on a seat they have seen run out of trump: the suit on an ivory disc, crossed out.
struct OutOfTrumpBadge: View {
    let trump: Suit

    var body: some View {
        Text(trump.glyph).font(.system(size: Theme.Table.outOfTrumpBadgeSize * 0.6))
            .foregroundStyle(trump.isRed ? Color.suitRed : .black)
            .frame(width: Theme.Table.outOfTrumpBadgeSize, height: Theme.Table.outOfTrumpBadgeSize)
            .background(.ivory, in: Circle())
            .overlay {
                Rectangle().fill(.black).frame(width: 2, height: Theme.Table.outOfTrumpBadgeSize * 0.8)
                    .rotationEffect(.degrees(45))
            }
            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            .accessibilityHidden(true)
    }
}
