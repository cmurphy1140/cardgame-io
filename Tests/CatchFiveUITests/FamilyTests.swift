import CatchFive
@testable import CatchFiveUI
import Foundation
import Testing

@Test func rulesSheetEndsWithTheFamilysNoteAndAMailLink() throws {
    #expect(RulesText.signOff == "We're honored you took a seat at our table. This game has been part of my family for generations. Always will be. The rules stay as they are, but if you have ideas for the app, email me. I'd love to hear them.")
    #expect(RulesText.contactEmail == "cmurphy1140@gmail.com")
    let url = RulesText.contactURL
    #expect(url.absoluteString == "mailto:cmurphy1140@gmail.com?subject=Catch%205")
    let parts = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    #expect(parts.scheme == "mailto")
    #expect(parts.path == "cmurphy1140@gmail.com")
    #expect(parts.queryItems == [URLQueryItem(name: "subject", value: "Catch 5")])
    // Not a rule: the verbatim check against the rules document never sees it.
    #expect(!RulesText.allText.contains(RulesText.signOff))
}

@MainActor @Test func theFiveOfTrumpTrickGetsTheBigFacesUntilTheNextLead() throws {
    // You hold the ace, king, queen, jack, five and two of hearts; every other heart is undealt.
    var match = try Match(deck: RootView.nineAndOutDeck(), dealer: 3)
    try match.bid(seat: 0, amount: 5)
    for seat in 1...3 { try match.bid(seat: seat, amount: nil) }
    try match.chooseTrump(seat: 0, suit: .hearts)
    try match.play(seat: 0, card: Card(.hearts, .five))
    for _ in 0..<3 {
        let seat = try #require(match.hand.nextSeat)
        try match.play(seat: seat, card: try #require(match.hand.legalMoves(seat: seat).first))
    }
    #expect(match.hand.completedTricks.last?.winner == 0)
    // The takers are triumphant, the leader included, and the other team dismayed.
    for seat in 0..<4 {
        #expect(SeatMood.expression(for: seat, in: match) == (seat % 2 == 0 ? .triumphant : .dismayed))
        #expect(SeatMood.isBigMoment(for: seat, in: match))
    }
    // The next lead ends it.
    try match.play(seat: 0, card: Card(.hearts, .ace))
    for seat in 0..<4 { #expect(!SeatMood.isBigMoment(for: seat, in: match)) }
    #expect(SeatMood.expression(for: try #require(match.hand.nextSeat), in: match) == .thinking)
    #expect(SeatMood.expression(for: 2, in: match) == .neutral)
}

@MainActor @Test func aNineAndOutDeclarationSurprisesTheDeclarersPartnerUntilTheFirstLead() throws {
    var match = try Match(deck: RootView.nineAndOutDeck(), dealer: 3)
    try match.bidNineAndOut(seat: 0)
    #expect(SeatMood.expression(for: 2, in: match) == .surprised)
    #expect(SeatMood.isBigMoment(for: 2, in: match))
    #expect(SeatMood.expression(for: 1, in: match) == .thinking)
    #expect(SeatMood.expression(for: 3, in: match) == .neutral)
    #expect(SeatMood.expression(for: 0, in: match) == .neutral)
    for seat in 1...3 { try match.bid(seat: seat, amount: nil) }
    // Still surprised while the declarer names trump.
    #expect(SeatMood.expression(for: 2, in: match) == .surprised)
    #expect(SeatMood.expression(for: 0, in: match) == .thinking)
    try match.chooseTrump(seat: 0, suit: .hearts)
    try match.play(seat: 0, card: Card(.hearts, .ace))
    #expect(!SeatMood.isBigMoment(for: 2, in: match))
    #expect(SeatMood.expression(for: 2, in: match) != .surprised)
}

@Test func handEndWordsFollowThePublicResult() {
    #expect((4...6).contains(HandEndLine.lines.count))
    // Your team caught the five: your partner says so, even ahead of a made bid.
    #expect(HandEndLine.pick(bidder: 0, made: true, fiveTeam: 0) == HandEndLine(seat: 2, text: "Nice catch on the five."))
    #expect(HandEndLine.pick(bidder: 3, made: true, fiveTeam: 0) == HandEndLine(seat: 2, text: "Nice catch on the five."))
    // You made your bid.
    #expect(HandEndLine.pick(bidder: 0, made: true, fiveTeam: 1) == HandEndLine(seat: 2, text: "That's how it's done."))
    #expect(HandEndLine.pick(bidder: 2, made: true, fiveTeam: nil) == HandEndLine(seat: 2, text: "That's how it's done."))
    // Your team was set, five or not.
    #expect(HandEndLine.pick(bidder: 2, made: false, fiveTeam: 0) == HandEndLine(seat: 2, text: "We'll get it back."))
    // The other team was set: its bidder speaks.
    #expect(HandEndLine.pick(bidder: 1, made: false, fiveTeam: nil) == HandEndLine(seat: 1, text: "Ouch."))
    #expect(HandEndLine.pick(bidder: 3, made: false, fiveTeam: 0) == HandEndLine(seat: 3, text: "Ouch."))
    // The other team made its bid and kept the five: nothing to say.
    #expect(HandEndLine.pick(bidder: 3, made: true, fiveTeam: 1) == nil)
}

@MainActor @Test func noWordsWhileAHandIsInPlayAndNoneInPassAndPlay() throws {
    let model = GameModel(match: try Match(deck: GameModel.deck(), dealer: 3))
    for _ in 0..<400 where model.match.hand.phase != .finished {
        #expect(model.handEndLine == nil)
        if model.isHumanTurn { model.showHint(); model.send(try #require(model.hint).action) } else { model.stepComputer() }
    }
    let summary = try #require(model.match.history.last)
    #expect(model.handEndLine == HandEndLine(summary: summary))
    model.nextHand()
    #expect(model.handEndLine == nil)

    let passed = GameModel(match: try Match(deck: GameModel.deck(), dealer: 3))
    passed.newGame(mode: .passAndPlay)
    passed.dismissDealerDraw()
    for _ in 0..<400 where passed.match.hand.phase != .finished {
        if passed.curtainSeat != nil { passed.ready() }
        guard let seat = passed.viewerSeat, let view = try? PlayerView(match: passed.match, seat: seat),
              let action = ComputerPlayer.decide(view, difficulty: .standard) else { break }
        passed.send(action)
    }
    #expect(passed.match.hand.phase == .finished)
    #expect(passed.handEndLine == nil)
}
