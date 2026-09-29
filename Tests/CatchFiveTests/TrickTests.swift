import Testing
@testable import CatchFive

@Test func mustFollowSuitEvenWithTrump() {
    let club = Card(.clubs, .two)
    let hand = [club, Card(.hearts, .ace)]
    #expect(legalCards(in: hand, led: .clubs) == [club])
    #expect(legalCards(in: hand, led: .spades) == hand)
    #expect(legalCards(in: hand, led: nil) == hand)
}

@Test func openingLeadMustBeTrumpWhenTheLeaderHoldsOne() {
    let trumps = [Card(.hearts, .two), Card(.hearts, .king)]
    let hand = [Card(.clubs, .ace)] + trumps + [Card(.spades, .four)]
    #expect(legalCards(in: hand, led: nil, openingTrump: .hearts) == trumps)
    // Without a trump the opening lead is free, and once a suit is led only following suit counts.
    #expect(legalCards(in: hand, led: nil, openingTrump: .diamonds) == hand)
    #expect(legalCards(in: hand, led: .clubs, openingTrump: .hearts) == [Card(.clubs, .ace)])
}

@Test func trumpBeatsLedAce() throws {
    let plays = [Play(seat: 2, card: Card(.clubs, .ace)),
                 Play(seat: 3, card: Card(.hearts, .two)),
                 Play(seat: 0, card: Card(.clubs, .king)),
                 Play(seat: 1, card: Card(.spades, .ace))]
    #expect(try trickWinner(plays, trump: .hearts) == 3)
    #expect(try trickWinner(plays, trump: .diamonds) == 2)
}

@Test func highestTrumpWins() throws {
    let plays = [Play(seat: 0, card: Card(.clubs, .ace)),
                 Play(seat: 1, card: Card(.hearts, .two)),
                 Play(seat: 2, card: Card(.hearts, .king)),
                 Play(seat: 3, card: Card(.hearts, .five))]
    #expect(try trickWinner(plays, trump: .hearts) == 2)
}

@Test func malformedTricksAreRejected() {
    #expect(throws: RuleError.invalidTrick) { try trickWinner([], trump: .clubs) }
    let duplicate = Array(repeating: Play(seat: 0, card: Card(.clubs, .ace)), count: 4)
    #expect(throws: RuleError.invalidTrick) { try trickWinner(duplicate, trump: .clubs) }
}

@Test func cardValuesForGame() {
    #expect(Rank.allCases.map(\.gameValue) == [0, 0, 0, 0, 0, 0, 0, 0, 10, 1, 2, 3, 4])
}
