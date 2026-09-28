import Testing
@testable import CatchFive

typealias Strategy = (PlayerView) -> PlayerAction?

struct BenchmarkResult {
    var candidateWins = 0
    var baselineWins = 0
    /// Sum over matches of (candidate score − baseline score) at the final settlement.
    var margin = 0
    var matches: Int { candidateWins + baselineWins }
    var candidateWinRate: Double { Double(candidateWins) / Double(matches) }
    var marginPerMatch: Double { Double(margin) / Double(matches) }
}

/// Plays one seeded match with `teamZero` steering seats 0/2 and `teamOne` seats 1/3.
func playSeededMatch(seed: Int, teamZero: Strategy, teamOne: Strategy) throws -> Match {
    let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit, $0) } }
    var random = RepeatableRandom(state: UInt64(seed))
    var match = try Match(deck: deck.shuffled(using: &random), dealer: seed % 4)
    while match.winner == nil {
        if match.hand.phase == .finished {
            try match.startNextHand(deck: deck.shuffled(using: &random))
            continue
        }
        let seat = try #require(match.hand.nextSeat)
        let strategy = seat % 2 == 0 ? teamZero : teamOne
        let action = try #require(strategy(PlayerView(match: match, seat: seat)))
        try match.apply(action, seat: seat)
    }
    return match
}

/// Every seed is played twice with the teams swapped so seat and dealer advantages cancel.
func mirroredBenchmark(seeds: Range<Int>, candidate: @escaping Strategy, baseline: @escaping Strategy) throws -> BenchmarkResult {
    var result = BenchmarkResult()
    for seed in seeds {
        let first = try playSeededMatch(seed: seed, teamZero: candidate, teamOne: baseline)
        if first.winner == 0 { result.candidateWins += 1 } else { result.baselineWins += 1 }
        result.margin += first.scores[0] - first.scores[1]
        let second = try playSeededMatch(seed: seed, teamZero: baseline, teamOne: candidate)
        if second.winner == 1 { result.candidateWins += 1 } else { result.baselineWins += 1 }
        result.margin += second.scores[1] - second.scores[0]
    }
    return result
}

@Test func benchmarkHarnessIsFairWhenBothSidesUseTheSameStrategy() throws {
    let result = try mirroredBenchmark(seeds: 1..<51, candidate: EasyPlayer.decide, baseline: EasyPlayer.decide)
    #expect(result.matches == 100)
    #expect(result.candidateWins == result.baselineWins)
    #expect(result.margin == 0)
}

/// The improvement target: the shipped player must clearly beat the frozen PR #2 player, which is also "Easy".
@Test func computerPlayerBeatsFrozenBaseline() throws {
    let result = try mirroredBenchmark(seeds: 1..<301, candidate: ComputerPlayer.decide, baseline: EasyPlayer.decide)
    // Measured 0.66 with a +5.5 point margin per match on 2026-09-04; the bar sits well below that.
    #expect(result.candidateWinRate >= 0.58)
    #expect(result.marginPerMatch >= 2)
}

/// The same view with the match score hidden, so `isTrailingBadly` never fires: Standard with the D71 rule off.
func withoutScores(_ view: PlayerView) -> PlayerView {
    PlayerView(seat: view.seat, cards: view.cards, phase: view.phase, nextSeat: view.nextSeat, dealer: view.dealer,
               highestBid: view.highestBid, bidder: view.bidder, trump: view.trump, trick: view.trick, calls: view.calls,
               completedTricks: view.completedTricks, discardCounts: view.discardCounts)
}

/// Contracts bid by a team that was down `ComputerPlayer.boldDeficit` or more when the hand was dealt.
struct TrailingContracts {
    var bid = 0
    var made = 0
    var rate: Double { bid == 0 ? 0 : Double(made) / Double(bid) }

    mutating func count(_ match: Match, team: Int) {
        var before = [0, 0]
        for summary in match.history {
            if summary.bidder % 2 == team, before[1 - team] - before[team] >= ComputerPlayer.boldDeficit {
                bid += 1
                if summary.contractMade { made += 1 }
            }
            before = summary.scores
        }
    }
}

/// D71 is a character rule, not a strength tune: this records what bidding one step bolder when down 10
/// does against the same strategy without it, and holds nothing to a bar beyond the harness being whole.
@Test func boldWhenTrailingIsMeasuredAgainstTheSameStrategyWithoutIt() throws {
    let off: Strategy = { ComputerPlayer.decide(withoutScores($0)) }
    var lines = ["D71, rule on vs off, mirrored:"]
    var total = BenchmarkResult(), onTrailing = TrailingContracts(), offTrailing = TrailingContracts()
    for seeds in [1..<601, 601..<1201] {
        var result = BenchmarkResult(), on = TrailingContracts(), without = TrailingContracts()
        for seed in seeds {
            let first = try playSeededMatch(seed: seed, teamZero: ComputerPlayer.decide, teamOne: off)
            if first.winner == 0 { result.candidateWins += 1 } else { result.baselineWins += 1 }
            result.margin += first.scores[0] - first.scores[1]
            on.count(first, team: 0); without.count(first, team: 1)
            let second = try playSeededMatch(seed: seed, teamZero: off, teamOne: ComputerPlayer.decide)
            if second.winner == 1 { result.candidateWins += 1 } else { result.baselineWins += 1 }
            result.margin += second.scores[1] - second.scores[0]
            on.count(second, team: 1); without.count(second, team: 0)
        }
        lines.append("  seeds \(seeds.lowerBound)..<\(seeds.upperBound): \(result.matches) matches, on wins \(result.candidateWinRate), margin \(result.marginPerMatch); contracts bid down 10+: on \(on.made)/\(on.bid), off \(without.made)/\(without.bid)")
        total.candidateWins += result.candidateWins; total.baselineWins += result.baselineWins; total.margin += result.margin
        onTrailing.bid += on.bid; onTrailing.made += on.made; offTrailing.bid += without.bid; offTrailing.made += without.made
    }
    lines.append("  all: \(total.matches) matches, on wins \(total.candidateWinRate), margin \(total.marginPerMatch); down 10+ made: on \(onTrailing.rate) of \(onTrailing.bid), off \(offTrailing.rate) of \(offTrailing.bid)")
    print(lines.joined(separator: "\n"))
    #expect(total.matches == 2400)
    #expect(onTrailing.bid > 0 && offTrailing.bid > 0)
}
