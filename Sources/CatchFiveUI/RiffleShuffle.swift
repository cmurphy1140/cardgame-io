import CatchFive
import SwiftUI

/// A quick riffle of card backs at the dealer's seat as each hand starts (D68). It is decoration only: it
/// never takes a tap, never enters `TablePause`, and the scheduler and the computers carry on underneath it.
struct RiffleShuffle: View {
    /// The whole riffle: the halves part, rifle back together and the stack fades.
    static let seconds = 0.6
    /// Card backs in each half.
    static let cardsPerHalf = 3

    /// A hand that has just been dealt: the auction is open and nobody has called yet.
    nonisolated static func startsHand(_ hand: Hand) -> Bool { hand.phase == .bidding && hand.auction.calls.isEmpty }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0 gathered, 1 split apart, 2 riffled back together.
    @State private var step = 0
    @State private var shown = true

    var body: some View {
        ZStack {
            ForEach(0..<(Self.cardsPerHalf * 2), id: \.self) { index in
                let left = index % 2 == 0
                let layer = Double(index / 2)
                CardBackView(width: 22)
                    .rotationEffect(.degrees(step == 1 ? (left ? -14 : 14) : 0))
                    .offset(x: step == 1 ? (left ? -13 : 13) : 0, y: step == 1 ? -layer * 2 : -Double(index))
            }
        }
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            if reduceMotion {
                try? await Task.sleep(for: .seconds(Self.seconds / 2))
                withAnimation(Theme.Motion.reduced) { shown = false }
                return
            }
            withAnimation(.easeOut(duration: 0.18)) { step = 1 }
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeIn(duration: 0.24)) { step = 2 }
            try? await Task.sleep(for: .milliseconds(240))
            withAnimation(.easeOut(duration: 0.18)) { shown = false }
        }
    }
}
