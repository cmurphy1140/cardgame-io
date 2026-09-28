import CatchFive
@testable import CatchFiveUI
import Testing

@MainActor @Test func theHeaderCarriesNoScore() {
    // N62: the score lives at the foot of the rails; the header keeps only the pause button.
    let bar = ScoreBarView(onPause: {})
    #expect(Mirror(reflecting: bar).children.map(\.label) == ["onPause"])
}

@MainActor @Test func eachTeamsPanelShowsItsTotalDotsAndHands() throws {
    // N62: a 5 bid by seat 0, played out; each panel carries its own total, dots to 25 and the hand so far.
    var match = try Match(deck: RootView.nineAndOutDeck(), dealer: 3)
    try match.bid(seat: 0, amount: 5)
    for seat in 1...3 { try match.bid(seat: seat, amount: nil) }
    try match.chooseTrump(seat: 0, suit: .hearts)
    while match.hand.phase != .finished {
        let seat = try #require(match.hand.nextSeat)
        try match.play(seat: seat, card: try #require(match.hand.legalMoves(seat: seat).first))
    }
    let names = ["Cheryl", "JC", "Connor", "Diane"]
    for team in 0...1 {
        let panel = ScorePanel.content(team: team, history: match.history, seatNames: names)
        #expect(panel.total == match.scores[team])
        #expect(panel.dots == min(25, max(0, match.scores[team])))
        #expect(panel.hands.count == 1)
        #expect(panel.hands[0].number == 1)
        #expect(panel.hands[0].line == "Cheryl bid 5, \(match.history[0].contractMade ? "made" : "set")")
        #expect(panel.hands[0].change == match.scores[team])
        #expect(panel.hands[0].total == match.scores[team])
        #expect(panel.hands[0].ourBid == (team == 0))
    }
    #expect(ScorePanel.content(team: 1, history: [], seatNames: names) == ScorePanel.Content(total: 0, dots: 0, hands: []))
    #expect(ScorePanel.dots(-3) == 0 && ScorePanel.dots(31) == 25 && ScorePanel.dots(12) == 12)
}
