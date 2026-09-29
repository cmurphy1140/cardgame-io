public struct Play: Equatable, Sendable {
    public let seat: Int
    public let card: Card

    public init(seat: Int, card: Card) {
        self.seat = seat
        self.card = card
    }
}

/// Pass `openingTrump` for the bid winner's opening lead of the hand: they must lead a trump if they
/// hold one (house rule, D91). Every later lead is free; following suit is unchanged.
public func legalCards(in hand: [Card], led: Suit?, openingTrump: Suit? = nil) -> [Card] {
    guard let led else {
        let trumps = hand.filter { $0.suit == openingTrump }
        return trumps.isEmpty ? hand : trumps
    }
    let following = hand.filter { $0.suit == led }
    return following.isEmpty ? hand : following
}

public func trickWinner(_ plays: [Play], trump: Suit) throws -> Int {
    guard plays.count == 4,
          Set(plays.map(\.seat)) == Set(0..<4),
          Set(plays.map(\.card)).count == 4 else { throw RuleError.invalidTrick }
    let led = plays[0].card.suit
    let trumps = plays.filter { $0.card.suit == trump }
    let candidates = trumps.isEmpty ? plays.filter { $0.card.suit == led } : trumps
    // There is always at least the leading card, or one trump.
    return candidates.max { $0.card.rank.rawValue < $1.card.rank.rawValue }!.seat
}
