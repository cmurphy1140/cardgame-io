import CatchFive
import SwiftUI

extension Suit {
    var glyph: String {
        switch self {
        case .clubs: "♣"
        case .diamonds: "♦"
        case .hearts: "♥"
        case .spades: "♠"
        }
    }
    var ink: Color { self == .hearts || self == .diamonds ? .suitRed : .black }
}

extension Rank {
    /// The corner-index letter or number: A, K, Q, J, else the pip count.
    var label: String {
        switch self {
        case .ace: "A"
        case .king: "K"
        case .queen: "Q"
        case .jack: "J"
        default: String(rawValue)
        }
    }
}

extension Card {
    var label: String { rank.label }
    var spoken: String { name }
}

/// How a card face is drawn: at rest, lifted because it may be played, dimmed because it may not,
/// or flat on the pile. The hand adds the press, the pick and the drag on top of these (`HandFanView`, D97).
enum CardStyle: Equatable {
    case rest, playable, dimmed, pile
}

struct CardView: View {
    let card: Card
    let style: CardStyle
    /// A ring drawn at the card's own scaled radius, so it fits at every text size; nil for none.
    let ring: Color?
    // Cards grow with the reader's text size so the faces stay legible under Dynamic Type.
    @ScaledMetric private var width: Double
    @Environment(\.colorSchemeContrast) private var contrast

    init(card: Card, width: Double = Theme.Card.tutorialWidth, style: CardStyle = .rest, ring: Color? = nil) {
        self.card = card
        self.style = style
        self.ring = ring
        _width = ScaledMetric(wrappedValue: width, relativeTo: .title2)
    }

    var body: some View {
        let radius = Theme.Card.radius(width: width)
        CardFace(card: card, width: width)
            .frame(width: width, height: width * Theme.Card.ratio)
            .background(CardFace.paper, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(.black.opacity(0.18), lineWidth: 0.75))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(ring ?? .clear, lineWidth: 3))
            // A card on the table casts a tight contact shadow and a softer one; a lifted card's spreads further.
            .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
            .shadow(color: .black.opacity(style == .playable ? 0.38 : 0.24), radius: style == .playable ? 9 : 4, y: style == .playable ? 6 : 3)
        // "Not legal now": the card stays opaque but sits in shadow, its colour drained; never see-through.
        .saturation(style == .dimmed ? Theme.Card.dimmedSaturation : 1)
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(.black.opacity(style == .dimmed ? (contrast == .increased ? Theme.Card.dimmedVeilHighContrast : Theme.Card.dimmedVeil) : 0)))
        // With Increase Contrast the dashed edge carries the state as well.
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(.black.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
            .opacity(style == .dimmed && contrast == .increased ? 1 : 0))
        // Last, so the veil and the edge move with the card: a legal card stands up, an illegal one sinks (D97).
        .offset(y: style == .playable ? -Theme.Card.liftPlayable : style == .dimmed ? Theme.Card.sinkDimmed : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.spoken)
    }
}

/// What is printed on a card (D97): the rank and suit in two opposite corners, the second turned upside down as
/// on a real card, and between them the pips laid out as a deck lays them, a single large pip for an ace, or a
/// framed letter for a court card. Everything scales with the card's width.
struct CardFace: View {
    let card: Card
    let width: Double

    /// Warm white paper, a touch darker at the foot so the card reads as lit from above.
    static let paper = LinearGradient(colors: [.ivory, Color(red: 0.95, green: 0.92, blue: 0.83)], startPoint: .top, endPoint: .bottom)

    /// Where the pips of a number card sit, as fractions of the pip area: x 0 left column, 0.5 middle, 1 right; y 0
    /// top row to 1 bottom row. Pips below the middle are printed upside down.
    nonisolated static func pipLayout(_ rank: Rank) -> [CGPoint] {
        let sides: (Double) -> [CGPoint] = { y in [CGPoint(x: 0, y: y), CGPoint(x: 1, y: y)] }
        switch rank {
        case .two: return [CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1)]
        case .three: return [CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 1)]
        case .four: return sides(0) + sides(1)
        case .five: return sides(0) + sides(1) + [CGPoint(x: 0.5, y: 0.5)]
        case .six: return sides(0) + sides(0.5) + sides(1)
        case .seven: return sides(0) + sides(0.5) + sides(1) + [CGPoint(x: 0.5, y: 0.25)]
        case .eight: return sides(0) + sides(0.5) + sides(1) + [CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.5, y: 0.75)]
        case .nine: return sides(0) + sides(1.0 / 3) + sides(2.0 / 3) + sides(1) + [CGPoint(x: 0.5, y: 0.5)]
        case .ten: return sides(0) + sides(1.0 / 3) + sides(2.0 / 3) + sides(1) + [CGPoint(x: 0.5, y: 1.0 / 6), CGPoint(x: 0.5, y: 5.0 / 6)]
        default: return []
        }
    }

    /// The court cards and the ace carry no pip layout.
    nonisolated static func isCourt(_ rank: Rank) -> Bool { rank == .jack || rank == .queen || rank == .king }

    var body: some View {
        let height = width * Theme.Card.ratio
        ZStack {
            centre(height: height)
            index.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            index.rotationEffect(.degrees(180)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .foregroundStyle(card.suit.ink)
        .frame(width: width, height: height)
    }

    /// Rank over suit, large enough to read in the strip a fanned card shows.
    private var index: some View {
        VStack(spacing: -width * 0.05) {
            Text(card.label)
                .font(.system(size: max(13, width * 0.25), weight: .bold, design: .serif))
                .tracking(card.rank == .ten ? -width * 0.03 : 0)
            Text(card.suit.glyph).font(.system(size: max(10, width * 0.19)))
        }
        .fixedSize()
        .padding(.top, width * 0.045).padding(.leading, width * 0.055)
        .padding(.bottom, width * 0.045).padding(.trailing, width * 0.055)
    }

    @ViewBuilder private func centre(height: Double) -> some View {
        if card.rank == .ace {
            pip(size: width * 0.5)
        } else if Self.isCourt(card.rank) {
            court(height: height)
        } else {
            // The pip area keeps clear of both indices: a central column band, a little shorter than the card.
            let area = CGSize(width: width * 0.36, height: height * 0.6)
            ZStack {
                ForEach(Array(Self.pipLayout(card.rank).enumerated()), id: \.offset) { _, spot in
                    pip(size: width * 0.19)
                        .rotationEffect(.degrees(spot.y > 0.5 ? 180 : 0))
                        .position(x: spot.x * area.width, y: spot.y * area.height)
                }
            }
            .frame(width: area.width, height: area.height)
        }
    }

    private func pip(size: Double) -> some View {
        Text(card.suit.glyph).font(.system(size: size)).fixedSize()
    }

    /// A court card: its letter large in a double-ruled frame, the suit in the frame's corners, a faint tint inside.
    private func court(height: Double) -> some View {
        let frame = CGSize(width: width * 0.5, height: height * 0.64)
        let corner = width * 0.05
        return ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(card.suit.ink.opacity(0.07))
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(card.suit.ink.opacity(0.55), lineWidth: max(0.75, width * 0.014))
            RoundedRectangle(cornerRadius: corner * 0.6, style: .continuous)
                .inset(by: width * 0.03)
                .stroke(card.suit.ink.opacity(0.3), lineWidth: max(0.5, width * 0.008))
            Text(card.label).font(.system(size: width * 0.36, weight: .bold, design: .serif))
            Text(card.suit.glyph).font(.system(size: width * 0.13))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(width * 0.05)
            Text(card.suit.glyph).font(.system(size: width * 0.13)).rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(width * 0.05)
        }
        .frame(width: frame.width, height: frame.height)
    }
}

/// A face-down card for the opponents' seats.
struct CardBackView: View {
    @ScaledMetric private var width: Double

    init(width: Double = Theme.Card.backWidth) {
        _width = ScaledMetric(wrappedValue: width, relativeTo: .title2)
    }

    var body: some View {
        let radius = Theme.Card.radius(width: width)
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color(red: 0.06, green: 0.22, blue: 0.18))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(.ivory.opacity(0.7), lineWidth: 1.5))
            .overlay(RoundedRectangle(cornerRadius: max(2, radius - 3), style: .continuous)
                .stroke(.ivory.opacity(0.35), lineWidth: 1).padding(5))
            .frame(width: width, height: width * Theme.Card.ratio)
            .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            .accessibilityHidden(true)
    }
}

extension ShapeStyle where Self == Color {
    static var ivory: Color { Color(red: 0.98, green: 0.96, blue: 0.89) }
    static var felt: Color { Color(red: 0.035, green: 0.16, blue: 0.13) }
    static var gold: Color { Color(red: 0.91, green: 0.75, blue: 0.42) }
}
