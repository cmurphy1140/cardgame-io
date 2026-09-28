import CatchFive
import SwiftUI

/// One seat's box in the auction (N55): empty until the seat speaks, then its bid, PASS or 9 OUT, big. Every
/// seat has one, the phone holder included; the call arrives from where it was made (the bid row for you,
/// the seat for everyone else), and the boxes go when the auction ends and the bid corner takes over.
struct BidBox: View {
    let label: String?
    /// Where the call comes in from, relative to the box: the bid row below it, or the seat beside it.
    let from: CGSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// What `seat`'s box says: its latest call, or nil before it has spoken.
    nonisolated static func label(for seat: Int, in auction: Auction) -> String? {
        auction.calls.last { $0.seat == seat }.map { call in
            switch call.bid {
            case nil: "PASS"
            case .nineAndOut: "9 OUT"
            case let .points(amount): String(amount)
            }
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Table.bidBoxRadius, style: .continuous)
        ZStack {
            if let label {
                Text(label)
                    .font(.system(size: label.count > 1 ? Theme.Table.bidBoxWordSize : Theme.Table.bidBoxNumberSize,
                                  weight: .heavy, design: .rounded))
                    .foregroundStyle(label == "PASS" ? Theme.Wood.dark : Theme.Wood.header)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, 3)
                    .id(label)
                    .transition(reduceMotion ? .opacity
                        : .asymmetric(insertion: .offset(from).combined(with: .scale(scale: 0.5)).combined(with: .opacity),
                                      removal: .opacity))
            }
        }
        .frame(width: Theme.Table.bidBoxWidth, height: Theme.Table.bidBoxHeight)
        // A light tan fill with a darker brown edge of the same hue; empty, the box is only a faint outline.
        .background(Theme.Table.cornerFill.opacity(label == nil ? 0.18 : 1), in: shape)
        .overlay(shape.stroke(Theme.Wood.light, lineWidth: 2))
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .accessibilityHidden(true)
    }
}
