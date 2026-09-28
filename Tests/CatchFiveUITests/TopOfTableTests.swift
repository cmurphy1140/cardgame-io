import CatchFive
@testable import CatchFiveUI
import Foundation
import Testing

@MainActor @Test func theTableBarHasTableAndClarifyWithTheirDropDowns() {
    // N68: one skinny bar, two boxes; Table pauses, starts over or goes home, Clarify answers what's on the table.
    #expect(TableBar.Box.allCases.map(\.title) == ["Table", "Clarify"])
    #expect(TableBar.TableItem.allCases.map(\.title) == ["Pause", "New game", "Home"])
    #expect(TableBar.newGameChoices.map(\.title) == ["Solo", "Pass and play"])
    #expect(TableBar.newGameChoices.map(\.mode) == [.solo, .passAndPlay])
    #expect(TableBar.answers.map(\.topic) == ["The bid box", "The scorecard", "Tap the suit", "Tap a face"])
    #expect(TableBar.answers.allSatisfy { !$0.text.isEmpty })
    #expect(TableBar.howToPlay == "How to play")
    // Play waits while a drop-down is open.
    #expect(TablePause(menuShown: true).isPaused)
    #expect(!TablePause().isPaused)
    // The pause card says the game keeps its place.
    #expect(WelcomeCard.keepsPlace == "You can leave the app and come back to this exact spot.")
}

@MainActor @Test func theBidBoxShowsTheFaceTheBidAndTrumpAndTheSuitKeepsTheTally() throws {
    // N63, N67: who bid (their face), the bid and trump in one box; the tally lives on the suit.
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    let model = GameModel(match: try Match(deck: deck, dealer: 3))
    model.send(.bid(9))
    for _ in 0..<3 { model.stepComputer() }
    #expect(ContractPlaque.contract(in: model)?.trump == nil)
    model.send(.chooseTrump(.hearts))
    let bidder = try #require(model.match.hand.auction.winner)
    let contract = try #require(ContractPlaque.contract(in: model))
    #expect(contract.portrait == (Cast.opponent(at: bidder)?.portrait ?? model.settings.playerPortrait))
    #expect(contract.number == String(try #require(model.match.hand.auction.highestBid)))
    #expect(contract.trump == .hearts)
    let box = ContractPlaque.onTable(model, contract: contract, width: 120)
    box.onAdd()
    box.onAdd()
    #expect(model.trumpTally == 2)
    box.onTakeBack()
    #expect(model.trumpTally == 1)
    #expect(ContractPlaque.spoken(contract, tally: 1) == "\(model.seatNames[bidder]) bid 9, hearts are trump, 1 trump played")
    // The separate trump tile is gone: the suit is drawn in the box, in its own colour.
    #expect(ContractPlaque.glyphColor(.hearts) == .suitRed && ContractPlaque.glyphColor(.clubs) == .black)
}
