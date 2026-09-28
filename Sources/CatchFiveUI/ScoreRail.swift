import CatchFive
import SwiftUI

/// One team's number line to 25 down an edge of the table (N59): the phone holder's team on the left, the other
/// on the right, each from below its side seat to the bottom. A darker green track with a lighter green fill and
/// ticks every five, the score bold on a light tan tab at its foot, in the table's bottom corner (N62); tapping the
/// tab opens that team's panel. It holds still through a hand and fills to the new score when the hand ends,
/// jumping there under Reduce Motion; a score below zero leaves the bar empty and shows its number.
struct ScoreRail: View {
    let score: Int
    let label: String
    /// Which edge the rail runs down; its label and number line up with that edge.
    let leading: Bool
    /// Opens this team's score panel.
    let onOpen: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The marks along the line.
    nonisolated static let ticks = [5, 10, 15, 20, 25]

    /// How much of the bar a score fills: none below zero, all of it from 25 up.
    nonisolated static func fill(_ score: Int) -> Double {
        min(1, max(0, Double(score) / Double(HouseRules.matchTarget)))
    }

    /// The scores the rails show: the last finished hand's, so they only move when a hand ends.
    nonisolated static func shown(in match: Match) -> [Int] {
        match.history.last?.scores ?? [0, 0]
    }

    /// US and THEM in solo; in pass and play the phone turns, so each rail names its pair.
    nonisolated static func label(us: Bool, mode: PlayMode, teamNames: String) -> String {
        mode == .solo ? (us ? "US" : "THEM") : teamNames.uppercased()
    }

    var body: some View {
        VStack(alignment: leading ? .leading : .trailing, spacing: 4) {
            bar.allowsHitTesting(false).accessibilityHidden(true)
            Button(action: onOpen) { foot }
                .buttonStyle(.plain)
                .accessibilityLabel("\(label) \(score) of \(HouseRules.matchTarget)")
                .accessibilityHint("Shows this team's hands")
        }
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
    }

    /// The number over the label, on a light tan tab with a light brown edge, like the table's corners.
    private var foot: some View {
        VStack(spacing: 0) {
            Text(score, format: .number).font(.system(size: Theme.Table.railNumberSize, weight: .heavy, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.caption.weight(.heavy)).lineLimit(2).minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.Wood.streakDark)
        .padding(.horizontal, 4).padding(.vertical, 3)
        .frame(width: Theme.Table.railLabelWidth)
        .background(Theme.Table.cornerFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.Wood.light, lineWidth: 1.5))
        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        .contentShape(Rectangle())
    }

    private var bar: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Table.railWidth / 2, style: .continuous)
        return GeometryReader { geometry in
            let height = geometry.size.height
            ZStack(alignment: .bottom) {
                shape.fill(Theme.Table.railTrack)
                shape.fill(Theme.Table.railFill)
                    .overlay(shape.stroke(Theme.Table.railFillEdge, lineWidth: 1.5))
                    .frame(height: height * Self.fill(score))
                    .animation(reduceMotion ? nil : Theme.Motion.railFill, value: score)
                ForEach(Self.ticks, id: \.self) { tick in
                    Rectangle().fill(Theme.Table.railEdge)
                        .frame(height: 2)
                        .offset(y: -height * Double(tick) / Double(HouseRules.matchTarget) + 1)
                }
                shape.stroke(Theme.Table.railEdge, lineWidth: 2)
            }
        }
        .frame(width: Theme.Table.railWidth)
    }
}
