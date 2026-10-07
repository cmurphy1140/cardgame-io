import Testing
@testable import CatchFive

/// Six spades to the ace, king, queen, jack and five: the strongest bidding hand in the computer tests.
private let huge = [Card(.spades, .ace), Card(.spades, .king), Card(.spades, .queen),
                    Card(.spades, .jack), Card(.spades, .five), Card(.spades, .two)]

/// A deck that deals `cards` to the dealer, seat 3: packets of three go to seats 0, 1, 2 and 3, twice.
private func deck(dealing cards: [Card]) -> [Card] {
    var rest = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }.filter { !cards.contains($0) }
    var deck: [Card] = []
    for index in 0..<24 {
        if (9..<12).contains(index) { deck.append(cards[index - 9]) }
        else if (21..<24).contains(index) { deck.append(cards[index - 18]) }
        else { deck.append(rest.removeFirst()) }
    }
    return deck + rest
}

/// Seat 0 declares 9 and out, seats 1 and 2 pass: the dealer, seat 3, answers with `cards`.
private func facingNineAndOut(_ cards: [Card], scores: [Int]) -> PlayerView {
    PlayerView(seat: 3, cards: cards, phase: .bidding, nextSeat: 3, dealer: 3, highestBid: 9, bidder: 0,
               trump: nil, trick: [], calls: [AuctionCall(seat: 0, bid: .nineAndOut),
                                              AuctionCall(seat: 1, bid: nil), AuctionCall(seat: 2, bid: nil)],
               scores: scores)
}

/// D102, the closeout audit's blocker: a computer dealer with a big hand answered a 9 and out with a plain 9,
/// the engine refused it, and the game asked the same seat again forever.
@Test(arguments: Difficulty.allCases)
func aComputerDealerAnswersANineAndOutWithALegalCall(_ difficulty: Difficulty) throws {
    var match = try Match(deck: deck(dealing: huge), dealer: 3)
    try match.apply(.nineAndOut, seat: 0)
    try match.apply(.bid(nil), seat: 1)
    try match.apply(.bid(nil), seat: 2)
    let action = try #require(ComputerPlayer.decide(try PlayerView(match: match, seat: 3), difficulty: difficulty))
    try match.apply(action, seat: 3)
    #expect(match.hand.phase != .bidding)
}

/// Every hand, level, behind or below zero: the only answer is a pass, since nobody may match a 9 and out (D103).
@Test(arguments: Difficulty.allCases)
func aStandingNineAndOutIsOnlyEverPassed(_ difficulty: Difficulty) throws {
    let all = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var random = RepeatableRandom(state: 102)
    var hands = [huge]
    for _ in 0..<300 { hands.append(Array(all.shuffled(using: &random).prefix(6))) }
    for cards in hands {
        for scores in [[0, 0], [20, 5], [0, 12], [10, -4]] {
            let action = ComputerPlayer.decide(facingNineAndOut(cards, scores: scores), difficulty: difficulty)
            if action != .bid(nil) {
                Issue.record("\(difficulty) answered a 9 and out with \(String(describing: action))")
            }
        }
    }
}

/// Easy is frozen (D17, D26) and never declares a 9 and out, so it never takes one over either.
@Test func easyPassesAStandingNineAndOut() {
    #expect(ComputerPlayer.decide(facingNineAndOut(huge, scores: [0, 0]), difficulty: .easy) == .bid(nil))
}
