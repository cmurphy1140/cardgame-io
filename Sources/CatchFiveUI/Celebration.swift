import CatchFive
import SwiftUI

/// A 9-and-out hand read from the engine's own result (D69): which of the five points the bidders caught.
/// A point nobody could catch (an undealt Jack or Five) counts as missed, as it does in the engine's nine.
struct NineAndOutResult: Hashable {
    enum Point: String, CaseIterable, Hashable {
        case high = "High", low = "Low", jack = "Jack", five = "Five", game = "Game"
    }

    /// The seat that bid 9 and out.
    let bidder: Int
    /// The points the bidders did not catch, in the order the table counts them.
    let missed: [Point]

    var made: Bool { missed.isEmpty }

    init(bidder: Int, highTeam: Int?, lowTeam: Int?, jackTeam: Int?, fiveTeam: Int?, gameTeam: Int) {
        let team = bidder % 2
        let owners: [(Point, Int?)] = [(.high, highTeam), (.low, lowTeam), (.jack, jackTeam), (.five, fiveTeam), (.game, gameTeam)]
        self.bidder = bidder
        missed = owners.filter { $0.1 != team }.map(\.0)
    }

    /// Nil unless the hand was bid 9 and out.
    init?(summary: HandSummary) {
        guard summary.isNineAndOut else { return nil }
        let result = summary.result
        self.init(bidder: summary.bidder, highTeam: result.highTeam, lowTeam: result.lowTeam,
                  jackTeam: result.jackTeam, fiveTeam: result.fiveTeam, gameTeam: result.gameTeam)
    }
}

/// What plays between a won match and the match-over card (D69), in order.
enum Celebration: Hashable {
    /// The full-screen 9-and-out moment, made or missed.
    case nineAndOut(NineAndOutResult)
    /// Cards cascading across the table for a win worth cheering: the phone's team in solo, anyone in pass and play.
    case cascade

    static func steps(winner: Int?, mode: PlayMode, nineAndOut: NineAndOutResult?) -> [Celebration] {
        guard let winner else { return [] }
        var steps: [Celebration] = nineAndOut.map { [.nineAndOut($0)] } ?? []
        if mode == .passAndPlay || winner == 0 { steps.append(.cascade) }
        return steps
    }

    /// How long the cascade runs before the match-over card.
    static let cascadeSeconds = 2.0
    /// How long a 9-and-out screen stays before it moves on by itself; a tap moves on sooner.
    static let nineSeconds = 3.5
}

/// Cards tumbling down across the table, each from its own column and at its own pace; a still spread of
/// cards under Reduce Motion. Takes no taps.
struct CardCascade: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    private static let cards: [Card] = [.init(.hearts, .five), .init(.spades, .ace), .init(.diamonds, .jack), .init(.clubs, .king),
                                        .init(.hearts, .ten), .init(.spades, .five), .init(.diamonds, .queen), .init(.clubs, .two),
                                        .init(.hearts, .ace), .init(.clubs, .jack), .init(.diamonds, .five), .init(.spades, .king),
                                        .init(.hearts, .queen), .init(.clubs, .five), .init(.diamonds, .ace), .init(.spades, .ten)]

    var body: some View {
        GeometryReader { geometry in
            if reduceMotion {
                HStack(spacing: -24) {
                    ForEach(Array(Self.cards.prefix(5).enumerated()), id: \.offset) { index, card in
                        CardView(card: card, width: 56).rotationEffect(.degrees(Double(index - 2) * 8))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    ZStack {
                        ForEach(Array(Self.cards.enumerated()), id: \.offset) { index, card in
                            let spot = Self.spot(index, elapsed: elapsed, in: geometry.size)
                            CardView(card: card, width: 52)
                                .rotationEffect(.degrees(spot.turn))
                                .position(spot.point)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Card `index` falls from above its column, starting a little after the one before, and turns as it goes.
    static func spot(_ index: Int, elapsed: Double, in size: CGSize) -> (point: CGPoint, turn: Double) {
        let count = Double(cards.count)
        let column = (Double((index * 7) % cards.count) + 0.5) / count
        let delay = Double(index) / count * 0.9
        let t = max(0, elapsed - delay)
        let fall = size.height + 160
        let y = -80 + fall * min(1, t * t * 1.4 + t * 0.35)
        let x = size.width * column + sin(t * 3 + Double(index)) * 18
        return (CGPoint(x: x, y: y), Double(index % 2 == 0 ? 1 : -1) * t * 220 + Double(index * 23))
    }
}

/// The 9-and-out moment: made is a full-screen cheer with every point ticked; missed is quieter and names
/// what was missed. A tap moves on; so does the time.
struct NineAndOutScreen: View {
    let result: NineAndOutResult
    let bidderName: String
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Theme.Wood.header.opacity(result.made ? 0.95 : 0.9).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(result.made ? "9 and out" : "9 and out missed")
                    .font(.system(size: result.made ? 60 : 40, weight: .bold, design: .serif))
                    .foregroundStyle(result.made ? Color.gold : .ivory)
                    .multilineTextAlignment(.center)
                Text(result.made ? "\(bidderName) took all nine" : "\(bidderName) missed \(Self.list(result.missed))")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(.ivory)
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(NineAndOutResult.Point.allCases, id: \.self) { point in
                        let caught = !result.missed.contains(point)
                        HStack(spacing: 12) {
                            Image(systemName: caught ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(caught ? Color.gold : .ivory.opacity(0.55))
                            Text(point.rawValue).foregroundStyle(.ivory.opacity(caught ? 1 : 0.6))
                        }
                        .font(.title3.weight(.semibold))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(point.rawValue), \(caught ? "caught" : "missed")")
                    }
                }
                .padding(.top, 6)
            }
            .padding(32)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDone)
        .accessibilityAddTraits([.isModal, .isButton])
        .accessibilityAction(named: "Continue", onDone)
    }

    /// "Low and Game", "High, Jack and Game".
    static func list(_ points: [NineAndOutResult.Point]) -> String {
        let names = points.map(\.rawValue)
        guard names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " and " + names.last!
    }
}
