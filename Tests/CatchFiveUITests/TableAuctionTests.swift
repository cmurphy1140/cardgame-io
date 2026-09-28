import CatchFive
@testable import CatchFiveUI
import Testing

@MainActor @Test func everySeatsBidBoxShowsItsCallBigPassOrNineOut() throws {
    // N55: seat 0 bids 3, seat 1 passes, seat 2 declares 9 and out; the dealer has not spoken yet.
    var match = try Match(deck: GameModel.deck(), dealer: 3)
    #expect((0..<4).map { BidBox.label(for: $0, in: match.hand.auction) } == [nil, nil, nil, nil])
    try match.bid(seat: 0, amount: 3)
    try match.bid(seat: 1, amount: nil)
    try match.bidNineAndOut(seat: 2)
    #expect(BidBox.label(for: 0, in: match.hand.auction) == "3")
    #expect(BidBox.label(for: 1, in: match.hand.auction) == "PASS")
    #expect(BidBox.label(for: 2, in: match.hand.auction) == "9 OUT")
    #expect(BidBox.label(for: 3, in: match.hand.auction) == nil)
}

@Test func theBidRowKeepsEveryNumberAndGreysTheOnesPassed() {
    // N55: 2 to 9 always, in one row; the ones the auction has passed stay in place, disabled.
    let row = TableSurface.bidRow(allows: { $0 >= 6 })
    #expect(row.map(\.bid) == Array(2...9))
    #expect(row.filter(\.enabled).map(\.bid) == [6, 7, 8, 9])
    #expect(TableSurface.bidRow(allows: { _ in false }).map(\.bid) == Array(2...9))
    #expect(TableSurface.bidRow(allows: { _ in false }).allSatisfy { !$0.enabled })
}

@Test func scoreRailsFillToTwentyFiveAndEmptyBelowZero() {
    // N59: a number line to 25; a negative score shows an empty bar and its own number.
    #expect(ScoreRail.fill(0) == 0)
    #expect(ScoreRail.fill(12) == 12.0 / 25)
    #expect(ScoreRail.fill(25) == 1)
    #expect(ScoreRail.fill(31) == 1)
    #expect(ScoreRail.fill(-4) == 0)
    #expect(ScoreRail.ticks == [5, 10, 15, 20, 25])
    #expect(ScoreRail.label(us: true, mode: .solo, teamNames: "Cheryl + Connor") == "US")
    #expect(ScoreRail.label(us: false, mode: .solo, teamNames: "JC + Diane") == "THEM")
    #expect(ScoreRail.label(us: false, mode: .passAndPlay, teamNames: "JC + Diane") == "JC + DIANE")
}

@MainActor @Test func scoreRailsMoveOnlyWhenTheHandEnds() throws {
    var match = try Match(deck: RootView.nineAndOutDeck(), dealer: 3)
    try match.bid(seat: 0, amount: 5)
    for seat in 1...3 { try match.bid(seat: seat, amount: nil) }
    try match.chooseTrump(seat: 0, suit: .hearts)
    while match.hand.phase != .finished {
        #expect(ScoreRail.shown(in: match) == [0, 0])
        let seat = try #require(match.hand.nextSeat)
        try match.play(seat: seat, card: try #require(match.hand.legalMoves(seat: seat).first))
    }
    #expect(ScoreRail.shown(in: match) == match.scores)
    #expect(ScoreRail.shown(in: match) != [0, 0])
}

@Test func nineAndOutTakesItsOwnLineUnderTheBidRow() {
    // The 9-and-out pill sits on its own line between the numbers and Pass, covering no bid pill.
    #expect(TableSurface.auctionRows(nineAndOut: true) == [.numbers, .nineAndOut, .pass])
    #expect(TableSurface.auctionRows(nineAndOut: false) == [.numbers, .pass])
}
