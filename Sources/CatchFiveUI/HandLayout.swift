import Foundation

/// How the human's hand is laid out for a given width, decided from measurements rather than hoped for.
/// The one invariant: every card exposes at least `Theme.Card.minimumTouchStrip` to a thumb. A fan that
/// cannot promise that gives way to two rows, which can.
enum HandLayout {
    enum Arrangement: Equatable {
        /// One overlapped row; `strip` is the exposed width of every card but the last.
        case fan(strip: Double)
        /// Two rows of `perRow` cards, each row with its own `strip`.
        case rows(perRow: Int, strip: Double)
    }

    /// The widest strip a row of `count` cards can have inside `available`, capped at the fan's own overlap.
    private static func strip(count: Int, cardWidth: Double, available: Double) -> Double {
        let ideal = Theme.Card.touchStrip(width: cardWidth)
        guard count > 1 else { return ideal }
        return min(ideal, (available - cardWidth) / Double(count - 1))
    }

    static func arrange(count: Int, cardWidth: Double, available: Double,
                        minimumStrip: Double = Theme.Card.minimumTouchStrip) -> Arrangement {
        let fan = strip(count: count, cardWidth: cardWidth, available: available)
        if count <= 1 || fan >= minimumStrip { return .fan(strip: fan) }
        let perRow = Int((Double(count) / 2).rounded(.up))
        return .rows(perRow: perRow, strip: strip(count: perRow, cardWidth: cardWidth, available: available))
    }

    /// Vertical room the hand needs: one card plus the fan's drop, or two cards and a gap.
    /// The air between cards when the hand lies flat during the auction (B01).
    static let baselineGap = 6.0

    /// The auction's flat row: every card on one baseline, evenly spaced, overlapping evenly only when the
    /// row would not otherwise fit (B01).
    static func baselineStrip(count: Int, cardWidth: Double, available: Double) -> Double {
        guard count > 1 else { return cardWidth + baselineGap }
        return min(cardWidth + baselineGap, (available - cardWidth) / Double(count - 1))
    }

    static func height(of arrangement: Arrangement, cardWidth: Double, flat: Bool = false) -> Double {
        let card = cardWidth * Theme.Card.ratio
        switch arrangement {
        // A hand lying flat for the auction needs no room for the fan's lift and arc (D97).
        case .fan where flat: return card + 4
        case .fan: return card + 16 + Theme.Card.fanDrop
        case .rows: return 2 * card + rowGap + 16
        }
    }

    static let rowGap = 8.0
}

/// The seat row: two side tiles and the pile between them share the table's width. The tiles give
/// way first, down to a floor that still fits a portrait and a short name.
enum TableLayout {
    /// The table's coordinate space, shared by the dealer's deck and the hand so a deal can fly between them.
    static let space = "table"
    /// A pile card nudged toward either side seat, plus 4 pt of air on each side.
    static let pileReservation = Theme.Card.pileWidth + 2 * Theme.Table.sideNudge + 8
    /// The pile's height before the cards' own scale: a card nudged up for the partner and one nudged down for you.
    static let pileHeight = Theme.Card.pileWidth * Theme.Card.ratio + Theme.Table.partnerNudge + Theme.Table.ownNudge + 8
    /// The spacer between a tile and the pile.
    static let seatGap = 4.0
    static let minimumSeatWidth = 84.0

    /// Each top corner's width: up to `Theme.Table.cornerWidth`, and never so wide that the two corners and the
    /// partner's tile overrun the row (N51).
    static func cornerWidth(available: Double) -> Double {
        min(Theme.Table.cornerWidth, (available - Theme.Table.seatTileWidth) / 2 - 2)
    }

    static func sideSeatWidth(available: Double) -> Double {
        let room = (available - pileReservation - 2 * seatGap) / 2
        return max(minimumSeatWidth, min(Theme.Table.seatTileWidth, room))
    }
}
