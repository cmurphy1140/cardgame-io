import SwiftUI

/// The table showing its two taps by itself, once per install, the first time trump is named (N61): the trump tile
/// pulses as if tapped, then one opponent's face does, each under a big caption. It is only a show: no tally mark
/// or badge is made. Under Reduce Motion the captions come without the pulse.
public enum TallyDemo: Equatable, Sendable {
    case trump
    case face(seat: Int)

    /// The tile first, then the opponent on the phone holder's left.
    nonisolated static func steps(opponent: Int) -> [TallyDemo] { [.trump, .face(seat: opponent)] }

    public var caption: String {
        switch self {
        case .trump: "Count trump as it falls"
        case .face: "Mark who's out of trump"
        }
    }

    /// How long each step holds before the next; a tap on the caption moves on sooner.
    nonisolated static let stepSeconds = 2.8
}

/// A press and release, over and over, as if a finger were tapping it; nothing under Reduce Motion.
struct DemoTap: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if active, !reduceMotion {
            content.phaseAnimator([1.0, 0.86, 1.0, 1.0]) { view, scale in
                view.scaleEffect(scale).shadow(color: .ivory.opacity(scale < 1 ? 0.9 : 0.4), radius: 12)
            } animation: { _ in .easeInOut(duration: 0.3) }
        } else {
            content
        }
    }
}

/// The demo's words: big and bold on a light tan card with a light brown edge, like the table's corners.
struct TallyDemoCaption: View {
    let text: String

    var body: some View {
        Text(text).font(.title2.weight(.heavy)).multilineTextAlignment(.center)
            .foregroundStyle(Theme.Wood.streakDark)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Theme.Table.cornerFill, in: RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Table.cornerRadius, style: .continuous).stroke(Theme.Wood.light, lineWidth: 2))
            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
            .dynamicTypeSize(...Theme.Card.maximumTypeSize)
    }
}
