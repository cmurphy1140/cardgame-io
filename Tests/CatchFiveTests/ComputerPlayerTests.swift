import Testing
@testable import CatchFive

private func view(cards: [Card], phase: HandPhase = .playing, seat: Int = 0,
                  dealer: Int = 3, highestBid: Int? = nil, bidder: Int? = nil,
                  trick: [Play] = []) -> PlayerView {
    PlayerView(seat: seat, cards: cards, phase: phase, nextSeat: seat,
               dealer: dealer, highestBid: highestBid, bidder: bidder,
               trump: .hearts, trick: trick)
}

@Test func computerPassesWeakHandButDealerTakesForcedTwo() {
    // Middle cards promise no High, Low, Jack or Five, so nothing justifies even a two.
    let cards = [Card(.clubs, .nine), Card(.spades, .eight)]
    #expect(ComputerPlayer.decide(view(cards: cards, phase: .bidding)) == .bid(nil))
    #expect(ComputerPlayer.decide(view(cards: cards, phase: .bidding, dealer: 0)) == .bid(2))
}

@Test func computerRaisesWithStrongSuitAndChoosesIt() {
    let cards = [Card(.spades, .ace), Card(.spades, .king), Card(.spades, .jack),
                 Card(.spades, .five), Card(.clubs, .two), Card(.diamonds, .three)]
    // Four spades including the five is a 5 bid at Connor's table, so it says 5 rather than the 4
    // that would merely have cleared the auction: the smallest raise invites the next player in.
    #expect(ComputerPlayer.decide(view(cards: cards, phase: .bidding, highestBid: 3, bidder: 1)) == .bid(5))
    #expect(ComputerPlayer.decide(view(cards: cards, phase: .choosingTrump)) == .chooseTrump(.spades))
    #expect(ComputerPlayer.decide(view(cards: cards, phase: .bidding, highestBid: 3, bidder: 2)) == .bid(nil))
    // The dealer is the exception: bidding last and able to match, taking it at 3 beats naming 5.
    #expect(ComputerPlayer.decide(view(cards: cards, phase: .bidding, dealer: 0, highestBid: 3, bidder: 1)) == .bid(3))
}

@Test func computerFollowsSuitInsteadOfTrumping() {
    let cards = [Card(.hearts, .ace), Card(.clubs, .two)]
    let trick = [Play(seat: 3, card: Card(.clubs, .king))]
    #expect(ComputerPlayer.decide(view(cards: cards, trick: trick)) == .play(Card(.clubs, .two)))
}

@Test func computerUsesLowestWinningCardAgainstOpponentWhenNothingIsAtStake() {
    let cards = [Card(.hearts, .ace), Card(.hearts, .queen), Card(.hearts, .two)]
    let trick = [Play(seat: 3, card: Card(.hearts, .nine))]
    #expect(ComputerPlayer.decide(view(cards: cards, trick: trick)) == .play(Card(.hearts, .queen)))
}

@Test func computerSpendsTheAceToCaptureTheFive() {
    // Partner was forced to drop the five under an opponent's king; the ace is worth spending.
    let cards = [Card(.hearts, .ace), Card(.hearts, .queen), Card(.hearts, .two)]
    let trick = [Play(seat: 1, card: Card(.hearts, .king)), Play(seat: 2, card: Card(.hearts, .five)),
                 Play(seat: 3, card: Card(.hearts, .six))]
    #expect(ComputerPlayer.decide(view(cards: cards, trick: trick)) == .play(Card(.hearts, .ace)))
}

@Test func computerDumpsTheTrickWhenItIsWorthlessAndNoTrumpIsFree() {
    // Void in clubs, the trick holds no points: keep both trumps rather than trump a nothing trick.
    let cards = [Card(.hearts, .eight), Card(.hearts, .seven), Card(.spades, .four)]
    let trick = [Play(seat: 1, card: Card(.clubs, .nine)), Play(seat: 2, card: Card(.clubs, .three)),
                 Play(seat: 3, card: Card(.clubs, .eight))]
    #expect(ComputerPlayer.decide(view(cards: cards, trick: trick)) == .play(Card(.spades, .four)))
    // The same position with a ten on the table is worth the cheaper trump.
    let tenTrick = [Play(seat: 1, card: Card(.clubs, .ten)), Play(seat: 2, card: Card(.clubs, .three)),
                    Play(seat: 3, card: Card(.clubs, .eight))]
    #expect(ComputerPlayer.decide(view(cards: cards, trick: tenTrick)) == .play(Card(.hearts, .seven)))
}

@Test func computerFeedsFiveToPartnerWhenLastToPlay() {
    let cards = [Card(.hearts, .five), Card(.hearts, .two)]
    let trick = [Play(seat: 1, card: Card(.hearts, .king)),
                 Play(seat: 2, card: Card(.hearts, .ace)),
                 Play(seat: 3, card: Card(.hearts, .three))]
    #expect(ComputerPlayer.decide(view(cards: cards, trick: trick)) == .play(Card(.hearts, .five)))
}

@Test func computerPreservesFiveWhenItCannotWin() {
    let cards = [Card(.hearts, .five), Card(.hearts, .three)]
    let trick = [Play(seat: 3, card: Card(.hearts, .ace))]
    #expect(ComputerPlayer.decide(view(cards: cards, trick: trick)) == .play(Card(.hearts, .three)))
}

@Test func computerDoesNotActOutsideItsTurn() throws {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    let match = try Match(deck: deck, dealer: 3)
    #expect(ComputerPlayer.decide(try PlayerView(match: match, seat: 1)) == nil)
    #expect(throws: RuleError.invalidSeat) { try PlayerView(match: match, seat: 4) }
}

@Test func changingHiddenCardsDoesNotChangeComputerDecision() throws {
    var deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    let first = try Match(deck: deck, dealer: 3)
    // Seat 0 gets positions 0...2 and 12...14. Swap an opponent card with stock.
    deck.swapAt(3, 40)
    let second = try Match(deck: deck, dealer: 3)
    let a = try PlayerView(match: first, seat: 0)
    let b = try PlayerView(match: second, seat: 0)
    #expect(a.cards == b.cards)
    #expect(ComputerPlayer.decide(a) == ComputerPlayer.decide(b))
}

struct RepeatableRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

@Test func computersCompleteShuffledMatchesThroughRealRules() throws {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    for seed in 1...24 {
        var random = RepeatableRandom(state: UInt64(seed))
        var match = try Match(deck: deck.shuffled(using: &random), dealer: seed % 4)
        for _ in 0..<10000 {
            if match.winner != nil { break }
            if match.hand.phase == .finished {
                try match.startNextHand(deck: deck.shuffled(using: &random))
                continue
            }
            let seat = try #require(match.hand.nextSeat)
            let action = try #require(ComputerPlayer.decide(PlayerView(match: match, seat: seat)))
            try match.apply(action, seat: seat)
        }
        let winner = try #require(match.winner)
        #expect(match.scores[winner] >= 25)
        #expect(match.history.count >= 3)
        let restored = try MatchSave.decode(MatchSave.encode(match))
        #expect(restored.winner == winner)
        #expect(restored.scores == match.scores)
    }
}

@Test func computerLeadsHighestTrumpButKeepsTheFiveBack() {
    let cards = [Card(.hearts, .ace), Card(.hearts, .five), Card(.clubs, .ten)]
    #expect(ComputerPlayer.decide(view(cards: cards)) == .play(Card(.hearts, .ace)))
    let fiveOnlyTrump = [Card(.hearts, .five), Card(.clubs, .ten), Card(.spades, .king)]
    #expect(ComputerPlayer.decide(view(cards: fiveOnlyTrump)) == .play(Card(.spades, .king)))
    #expect(ComputerPlayer.decide(view(cards: [Card(.hearts, .five)])) == .play(Card(.hearts, .five)))
}

@Test func computerSeesPublicAuctionCalls() throws {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var match = try Match(deck: deck, dealer: 3)
    try match.bid(seat: 0, amount: 4)
    let view = try PlayerView(match: match, seat: 1)
    #expect(view.calls == [AuctionCall(seat: 0, bid: .points(4))])
}

@Test func estimateRanksControlAndTheFiveAboveScatteredCards() {
    let strong = [Card(.spades, .ace), Card(.spades, .king), Card(.spades, .five), Card(.hearts, .two)]
    let weak = [Card(.clubs, .two), Card(.clubs, .three), Card(.hearts, .ace), Card(.diamonds, .king)]
    #expect(ComputerPlayer.estimate(strong, suit: .spades) > ComputerPlayer.estimate(weak, suit: .clubs))
    #expect(ComputerPlayer.estimate(strong, suit: .spades) > ComputerPlayer.estimate(strong, suit: .hearts))
    #expect(ComputerPlayer.estimate([Card(.hearts, .five), Card(.hearts, .ace)], suit: .hearts)
            > ComputerPlayer.estimate([Card(.hearts, .five), Card(.clubs, .ace)], suit: .hearts))
    #expect(ComputerPlayer.estimate([Card(.clubs, .ace)], suit: .hearts) == 0)
    // The estimate is only half the call: this shape meets a house floor of 5, and the floor wins.
    #expect(ComputerPlayer.decide(view(cards: strong, phase: .bidding, highestBid: 3, bidder: 1)) == .bid(5))
}

/// Guards the bidding calibration: computers should compete for most hands and usually make their contract.
@Test func computerBiddingIsCompetitiveAndUsuallyMakesContract() throws {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var hands = 0, made = 0, forcedDealerTwo = 0
    for seed in 1...200 {
        var random = RepeatableRandom(state: UInt64(seed))
        var match = try Match(deck: deck.shuffled(using: &random), dealer: seed % 4)
        while match.winner == nil {
            if match.hand.phase == .finished { try match.startNextHand(deck: deck.shuffled(using: &random)); continue }
            let seat = try #require(match.hand.nextSeat)
            // A dealer who must open because the other three passed is the forced two.
            if match.hand.phase == .bidding, seat == match.hand.auction.dealer, match.hand.auction.highestBid == nil {
                forcedDealerTwo += 1
            }
            try match.apply(try #require(ComputerPlayer.decide(PlayerView(match: match, seat: seat))), seat: seat)
        }
        for summary in match.history {
            hands += 1
            if summary.result.points[summary.bidder % 2] >= summary.bid { made += 1 }
        }
    }
    #expect(Double(made) / Double(hands) >= 0.7)
    #expect(Double(forcedDealerTwo) / Double(hands) <= 0.35)
}

@Test func adviceNamesTheActionAndExplainsIt() throws {
    let strong = [Card(.spades, .ace), Card(.spades, .king), Card(.spades, .five), Card(.hearts, .two)]
    let bid = try #require(ComputerPlayer.advise(view(cards: strong, phase: .bidding, highestBid: 3, bidder: 1)))
    // Three spades including the five is a 5 bid at the table, and the reason says which suit.
    #expect(bid.action == .bid(5))
    #expect(bid.reason.contains("spades"))
    let pass = try #require(ComputerPlayer.advise(view(cards: strong, phase: .bidding, highestBid: 3, bidder: 2)))
    #expect(pass.action == .bid(nil))
    #expect(pass.reason.lowercased().contains("partner"))
    let trump = try #require(ComputerPlayer.advise(view(cards: strong, phase: .choosingTrump)))
    #expect(trump.action == .chooseTrump(.spades))
    #expect(trump.reason.contains("spades"))
}

@Test func adviceExplainsCardPlay() throws {
    // Leading with the boss trump.
    let lead = try #require(ComputerPlayer.advise(view(cards: [Card(.hearts, .ace), Card(.hearts, .five), Card(.clubs, .ten)])))
    #expect(lead.action == .play(Card(.hearts, .ace)))
    #expect(lead.reason.contains("ace of hearts") && lead.reason.lowercased().contains("beat"))
    // Feeding the five to a partner who holds the trick.
    let feedTrick = [Play(seat: 1, card: Card(.hearts, .king)), Play(seat: 2, card: Card(.hearts, .ace)), Play(seat: 3, card: Card(.hearts, .three))]
    let feed = try #require(ComputerPlayer.advise(view(cards: [Card(.hearts, .five), Card(.hearts, .two)], trick: feedTrick)))
    #expect(feed.action == .play(Card(.hearts, .five)))
    #expect(feed.reason.lowercased().contains("partner"))
    // Losing cheaply while keeping the five.
    let lose = try #require(ComputerPlayer.advise(view(cards: [Card(.hearts, .five), Card(.hearts, .three)], trick: [Play(seat: 3, card: Card(.hearts, .ace))])))
    #expect(lose.action == .play(Card(.hearts, .three)))
    #expect(lose.reason.lowercased().contains("five"))
    // Advice matches decide everywhere it is offered.
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var random = RepeatableRandom(state: 7)
    var match = try Match(deck: deck.shuffled(using: &random), dealer: 0)
    while match.winner == nil {
        if match.hand.phase == .finished { try match.startNextHand(deck: deck.shuffled(using: &random)); continue }
        let seat = try #require(match.hand.nextSeat)
        let playerView = try PlayerView(match: match, seat: seat)
        let advice = try #require(ComputerPlayer.advise(playerView))
        #expect(ComputerPlayer.decide(playerView) == advice.action)
        #expect(!advice.reason.isEmpty)
        try match.apply(advice.action, seat: seat)
    }
}

@Test func replayedViewExplainsEveryComputerPlayExactly() throws {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var random = RepeatableRandom(state: 11)
    var match = try Match(deck: deck.shuffled(using: &random), dealer: 1)
    var checked = 0
    while match.winner == nil {
        if match.hand.phase == .finished { try match.startNextHand(deck: deck.shuffled(using: &random)); continue }
        let seat = try #require(match.hand.nextSeat)
        try match.apply(try #require(ComputerPlayer.decide(PlayerView(match: match, seat: seat))), seat: seat)
        // Every card on the table and in every completed trick must be explained by the same decision.
        for play in match.hand.currentTrick {
            let view = try PlayerView(match: match, replaying: play, inCompletedTrick: nil)
            #expect(ComputerPlayer.decide(view) == .play(play.card)); checked += 1
        }
        for (index, trick) in match.hand.completedTricks.enumerated() where index == match.hand.completedTricks.count - 1 {
            for play in trick.plays {
                let view = try PlayerView(match: match, replaying: play, inCompletedTrick: index)
                #expect(view.completedTricks.count == index)
                #expect(view.cards.contains(play.card))
                #expect(ComputerPlayer.decide(view) == .play(play.card)); checked += 1
            }
        }
    }
    #expect(checked > 100)
    #expect(throws: HandError.cardNotHeld) {
        try PlayerView(match: match, replaying: Play(seat: 0, card: Card(.clubs, .two)), inCompletedTrick: 0)
    }
}

@Test func easyDifficultyPlaysTheFrozenPlayerAndStandardTheCurrentOne() throws {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var random = RepeatableRandom(state: 5)
    var match = try Match(deck: deck.shuffled(using: &random), dealer: 2)
    var differed = 0
    while match.winner == nil {
        if match.hand.phase == .finished { try match.startNextHand(deck: deck.shuffled(using: &random)); continue }
        let seat = try #require(match.hand.nextSeat)
        let view = try PlayerView(match: match, seat: seat)
        #expect(ComputerPlayer.decide(view, difficulty: .easy) == EasyPlayer.decide(view))
        #expect(ComputerPlayer.decide(view, difficulty: .standard) == ComputerPlayer.decide(view))
        if ComputerPlayer.decide(view, difficulty: .easy) != ComputerPlayer.decide(view) { differed += 1 }
        try match.apply(try #require(ComputerPlayer.decide(view, difficulty: seat % 2 == 0 ? .easy : .standard)), seat: seat)
    }
    #expect(differed > 0)
}

/// A bidding view for seat 0 with the given match score, team 0 first.
private func bidding(_ cards: [Card], scores: [Int], highestBid: Int? = nil, bidder: Int? = nil) -> PlayerView {
    PlayerView(seat: 0, cards: cards, phase: .bidding, nextSeat: 0, dealer: 3, highestBid: highestBid,
               bidder: bidder, trump: nil, trick: [], scores: scores)
}

@Test func trailingBadlyStartsAtExactlyTenBehind() {
    let cards = [Card(.clubs, .nine), Card(.spades, .eight)]
    #expect(ComputerPlayer.isTrailingBadly(bidding(cards, scores: [0, 10])))
    #expect(ComputerPlayer.isTrailingBadly(bidding(cards, scores: [-5, 5])))
    #expect(ComputerPlayer.isTrailingBadly(bidding(cards, scores: [3, 20])))
    #expect(!ComputerPlayer.isTrailingBadly(bidding(cards, scores: [0, 9])))
    #expect(!ComputerPlayer.isTrailingBadly(bidding(cards, scores: [10, 0])))   // ahead, not behind
    #expect(!ComputerPlayer.isTrailingBadly(bidding(cards, scores: [0, 0])))
    // Seat 1 reads the other column: team 1 behind team 0.
    let seatOne = PlayerView(seat: 1, cards: cards, phase: .bidding, nextSeat: 1, dealer: 3, highestBid: nil,
                             bidder: nil, trump: nil, trick: [], scores: [12, 2])
    #expect(ComputerPlayer.isTrailingBadly(seatOne))
}

@Test func trailingBadlyRaisesTheBidCeilingByOne() throws {
    // Worth about 1.4 in clubs: one short of opening at 2, so it passes when level and opens when down 10.
    let weak = [Card(.clubs, .nine), Card(.spades, .eight)]
    #expect(ComputerPlayer.decide(bidding(weak, scores: [0, 9])) == .bid(nil))
    let bold = try #require(ComputerPlayer.advise(bidding(weak, scores: [0, 10])))
    #expect(bold.action == .bid(2))
    #expect(bold.reason.hasSuffix("Your team is down 10, so the table bids one step bolder."))
    // One step only: the same hand still passes a 2 it would have to raise to 3.
    #expect(ComputerPlayer.decide(bidding(weak, scores: [0, 15], highestBid: 2, bidder: 1)) == .bid(nil))
}

@Test func trailingBadlyNeverBidsAboveNineOrNineAndOut() throws {
    // Six spades to the ace, king, jack and five: worth 9 already, so the ceiling cannot rise past it.
    let huge = [Card(.spades, .ace), Card(.spades, .king), Card(.spades, .queen),
                Card(.spades, .jack), Card(.spades, .five), Card(.spades, .two)]
    #expect(ComputerPlayer.decide(bidding(huge, scores: [0, 20], highestBid: 8, bidder: 1)) == .bid(9))
    #expect(ComputerPlayer.decide(bidding(huge, scores: [0, 20], highestBid: 9, bidder: 1)) == .bid(nil))
    // Every hand dealt from a shuffled deck, at every price, down 10 or level: never a 9 and out, never above 9,
    // and down 10 it goes at most one higher than it would level.
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var random = RepeatableRandom(state: 71)
    var bolder = 0
    for _ in 0..<300 {
        let cards = Array(deck.shuffled(using: &random).prefix(6))
        for high in [nil, 2, 3, 4, 5, 6, 7, 8] as [Int?] {
            let level = try #require(ComputerPlayer.decide(bidding(cards, scores: [4, 4], highestBid: high, bidder: high.map { _ in 1 })))
            let down = try #require(ComputerPlayer.decide(bidding(cards, scores: [4, 14], highestBid: high, bidder: high.map { _ in 1 })))
            #expect(down != .nineAndOut)
            guard case let .bid(amount) = down else { Issue.record("a bidding view bids"); continue }
            #expect((amount ?? 0) <= 9)
            if down != level {
                bolder += 1
                // Only the step from passing to the next bid, or one higher than it would have said.
                if case let .bid(was) = level, let was, let amount { #expect(amount == was + 1 || amount <= was) }
            }
        }
    }
    #expect(bolder > 0)
}

@Test func easyIgnoresTheMatchScore() throws {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var random = RepeatableRandom(state: 17)
    for _ in 0..<200 {
        let cards = Array(deck.shuffled(using: &random).prefix(6))
        for high in [nil, 2, 3, 4, 5] as [Int?] {
            let level = bidding(cards, scores: [0, 0], highestBid: high, bidder: high.map { _ in 1 })
            let down = bidding(cards, scores: [0, 20], highestBid: high, bidder: high.map { _ in 1 })
            #expect(EasyPlayer.decide(level) == EasyPlayer.decide(down))
            #expect(ComputerPlayer.decide(down, difficulty: .easy) == EasyPlayer.decide(level))
        }
    }
}

@Test func playerViewCarriesTheScoreTheHandWasDealtAt() throws {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var random = RepeatableRandom(state: 9)
    var match = try Match(deck: deck.shuffled(using: &random), dealer: 0)
    while match.hand.phase != .finished {
        let seat = try #require(match.hand.nextSeat)
        try match.apply(try #require(ComputerPlayer.decide(PlayerView(match: match, seat: seat))), seat: seat)
    }
    // Scored: `scores` has moved on, but the hand was dealt at 0 to 0.
    #expect(match.scores != [0, 0])
    #expect(try PlayerView(match: match, seat: 0).scores == [0, 0])
    try match.startNextHand(deck: deck.shuffled(using: &random))
    #expect(try PlayerView(match: match, seat: 1).scores == match.scores)
}
