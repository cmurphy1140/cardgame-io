import CatchFive
import SwiftUI

/// The table's top-left corner once the auction resolves: who bid and how much (D65). The bidder's own face
/// beside the number, large in the display serif, under a small BID eyebrow, and the bidder's name small
/// underneath (N52); 9 and out reads as a 9 with "and out".
struct ContractPlaque: View {
    struct Contract: Equatable {
        let bid: Int
        let isNineAndOut: Bool
        let bidder: String
        /// The bidder's face, the same as at their seat.
        let portrait: Portrait

        /// The big figure: the bid, or 9 for 9 and out.
        var number: String { isNineAndOut ? "9" : String(bid) }
        /// The words under a 9 and out's figure; nil for an ordinary bid.
        var qualifier: String? { isNineAndOut ? "and out" : nil }
        var spoken: String { "\(bidder) bid \(isNineAndOut ? "9 and out" : String(bid))" }
    }

    let contract: Contract
    /// The corner's width, from `TableLayout.cornerWidth(available:)`; the height is `Theme.Table.cornerHeight`.
    let width: Double

    /// The light tan of both corners, and the dark wood browns the plaque's words are set in (D76).
    static let fill = Theme.Table.cornerFill
    static let eyebrowInk = Theme.Wood.dark
    static let numberInk = Theme.Wood.streakDark
    static let nameInk = Theme.Wood.dark

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .bottom, spacing: 6) {
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
            Text(contract.bidder).font(.subheadline.weight(.semibold)).foregroundStyle(Self.nameInk)
        }
        .lineLimit(1).minimumScaleFactor(0.6)
        .padding(8)
        .frame(width: width, height: Theme.Table.cornerHeight)
        .background(Self.fill, in: RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous).stroke(Theme.Wood.light, lineWidth: 1.5))
        .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(contract.spoken)
    }
}

/// The table's top-right corner once trump is named: the suit big on a light tan tile (D76) the same size as the
/// bid's (N51), and under it the player's own tally of trumps played (D65). Tap adds a mark, press and hold takes
/// one back; the app never counts for the player (spec R4), it only keeps the marks they make.
struct TrumpTile: View {
    let trump: Suit
    let tally: Int
    /// The corner's width, from `TableLayout.cornerWidth(available:)`; the height is `Theme.Table.cornerHeight`.
    let width: Double
    let onAdd: () -> Void
    let onTakeBack: () -> Void

    static let fill = Theme.Table.cornerFill

    /// Red for hearts and diamonds, black for spades and clubs: the suit's own colour, never a control's.
    nonisolated static func glyphColor(_ suit: Suit) -> Color { suit.isRed ? .suitRed : .black }

    /// "Hearts are trump, 4 trump played".
    nonisolated static func spoken(trump: Suit, tally: Int) -> String {
        "\(trump.rawValue.capitalized) are trump, \(tally) trump played"
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(trump.glyph).font(.system(size: Theme.Table.trumpGlyphSize))
                .foregroundStyle(Self.glyphColor(trump))
                .frame(width: width, height: Theme.Table.cornerHeight)
                .background(Self.fill, in: RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous).stroke(Theme.Wood.light, lineWidth: 1.5))
                .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
                .dynamicTypeSize(...Theme.Card.maximumTypeSize)
            TallyMarks(count: tally).frame(width: width, height: Theme.Table.tallyHeight)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onAdd)
        .onLongPressGesture(perform: onTakeBack)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spoken(trump: trump, tally: tally))
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

/// Tally strokes in groups of five, the fifth drawn across the four before it, as on paper.
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
                context.stroke(path, with: .color(.ivory), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
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
