import CatchFive

/// One short line from one seat on the hand-end card, chosen from the hand's public result (N36). Solo only:
/// you are seat 0, your partner seat 2. Never offered while a hand is in play (`GameModel.handEndLine`).
struct HandEndLine: Equatable {
    /// Who speaks: a seat, named at the table with `GameModel.seatNames`.
    let seat: Int
    let text: String

    /// Every line the table says, in the order they are tried; the first that fits is the one shown.
    static let lines: [(when: Moment, text: String)] = [
        (.weWereSet, "We'll get it back."),
        (.theyWereSet, "Ouch."),
        (.weCaughtTheFive, "Nice catch on the five."),
        (.weMadeOurBid, "That's how it's done."),
    ]

    enum Moment {
        case weWereSet, theyWereSet, weCaughtTheFive, weMadeOurBid
    }

    /// The line for a finished hand, or nil when nothing fits: your partner speaks for your team, and the
    /// set bidder for the other.
    static func pick(bidder: Int, made: Bool, fiveTeam: Int?) -> HandEndLine? {
        let ours = bidder % 2 == 0
        for (moment, text) in lines {
            let speaker: Int? = switch moment {
            case .weWereSet: ours && !made ? 2 : nil
            case .theyWereSet: !ours && !made ? bidder : nil
            case .weCaughtTheFive: fiveTeam == 0 ? 2 : nil
            case .weMadeOurBid: ours && made ? 2 : nil
            }
            if let speaker { return HandEndLine(seat: speaker, text: text) }
        }
        return nil
    }

    /// The engine's record of a finished hand.
    init?(summary: HandSummary) {
        guard let line = Self.pick(bidder: summary.bidder, made: summary.contractMade, fiveTeam: summary.result.fiveTeam) else { return nil }
        self = line
    }

    init(seat: Int, text: String) {
        self.seat = seat
        self.text = text
    }
}
