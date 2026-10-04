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

@Test func nineAndOutSitsOnThePassRowUnderTheNine() {
    // D97, over D85's own line: 9 and out sits at the right end of the Pass row, under the 9, still covering no number (D85), so the
    // auction fits above the hand.
    #expect(TableSurface.auctionRows(nineAndOut: true) == [.numbers, .passWithNineAndOut])
    #expect(TableSurface.auctionRows(nineAndOut: false) == [.numbers, .pass])
}
