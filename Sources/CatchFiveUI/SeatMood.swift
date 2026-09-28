import CatchFive

/// What a seat's face shows, from public events only: whose turn it is, who took the last trick, who
/// won the match. Nothing here looks at a hand, so an expression can never leak a card.
enum SeatMood {
    static func expression(for seat: Int, in match: Match, matchWinner: Int? = nil) -> Portrait.Expression {
        if let winner = matchWinner ?? match.winner {
            return seat % 2 == winner % 2 ? .triumphant : .dismayed
        }
        if let big = bigMoment(for: seat, in: match.hand) { return big }
        let hand = match.hand
        if hand.nextSeat == seat, hand.phase != .finished { return .thinking }
        // A finished trick still on the table: the takers are pleased, the others rueful, until the next lead.
        if hand.phase == .playing, hand.currentTrick.isEmpty, let last = hand.completedTricks.last {
            return seat % 2 == last.winner % 2 ? .pleased : .rueful
        }
        return .neutral
    }

    /// True while a big public moment shows on this seat's face: the portrait is drawn larger for it (N36).
    static func isBigMoment(for seat: Int, in match: Match) -> Bool {
        match.winner == nil && bigMoment(for: seat, in: match.hand) != nil
    }

    /// The louder faces, ahead of the turn: the trick that caught the five of trump (the takers triumphant,
    /// the others dismayed) while it lies on the table, and a 9-and-out declaration (the declarer's partner
    /// surprised) until the first lead. Both end at the next lead.
    private static func bigMoment(for seat: Int, in hand: Hand) -> Portrait.Expression? {
        guard hand.currentTrick.isEmpty else { return nil }
        if let trump = hand.trump, let last = hand.completedTricks.last,
           last.plays.contains(where: { $0.card == Card(trump, .five) }) {
            return seat % 2 == last.winner % 2 ? .triumphant : .dismayed
        }
        if hand.completedTricks.isEmpty, hand.phase != .finished,
           let declarer = hand.auction.calls.last(where: { $0.bid == .nineAndOut })?.seat, seat == (declarer + 2) % 4 {
            return .surprised
        }
        return nil
    }
}
