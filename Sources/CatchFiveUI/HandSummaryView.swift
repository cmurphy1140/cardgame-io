import CatchFive
import SwiftUI

struct HandSummaryView: View {
    let match: Match
    let names: [String]
    /// Built once by the model from the same history; nil only before any hand has finished.
    let outcome: HandOutcome?
    let review: HandReview?
    let difficulty: Difficulty
    let describe: (PlayReview) -> String
    let coaching: Bool

    var body: some View {
        if let summary = match.history.last, let outcome {
            VStack(spacing: 10) {
                // The calm result (R01, R02): made or not, who bid, trump, and what it did to the score.
                HStack(spacing: 14) {
                    if let trump = match.hand.trump {
                        Text(trump.glyph).font(.system(size: 56))
                            .foregroundStyle(trump.isRed ? Color.suitRed : .black)
                            .accessibilityLabel("\(trump.rawValue) trump")
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(outcome.headline).font(.system(.title2, design: .serif).weight(.semibold))
                        Text("\(names[summary.bidder]) bid \(summary.isNineAndOut ? "9 and out" : String(summary.bid))")
                            .font(.subheadline).opacity(0.75)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                HStack(spacing: 12) {
                    score(team: 0, summary: summary)
                    score(team: 1, summary: summary)
                }
                Divider().overlay(.black.opacity(0.15)).padding(.vertical, 2)
                // Everything else waits in Review hand (R03, R04).
                DisclosureGroup("Review hand") {
                    VStack(spacing: 8) {
                        Text(outcome.bidderLine).font(.caption)
                        Text(outcome.defenderLine).font(.caption)
                        Text("HAND POINTS  \(summary.result.points[0]) – \(summary.result.points[1])").font(.headline)
                        row("High", team: summary.result.highTeam)
                        row("Low", team: summary.result.lowTeam)
                        row("Jack", team: summary.result.jackTeam)
                        row("Five · 5 points", team: summary.result.fiveTeam)
                        row("Game · \(summary.result.gameValues[0])–\(summary.result.gameValues[1])", team: summary.result.gameTeam)
                        ForEach(outcome.notes, id: \.self) { note in
                            Text(note).font(.caption).opacity(0.75).multilineTextAlignment(.center)
                        }
                        if let review {
                            ForEach(review.tricks, id: \.number) { trick in
                                DisclosureGroup("Hand \(trick.number) · \(names[trick.winner]) took it") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(trick.plays, id: \.play.card) { reviewPlay in
                                            playRow(reviewPlay)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.leading, 8)
                                }.tint(.black.opacity(0.7)).font(.subheadline)
                            }
                        }
                    }.padding(.top, 4)
                }.tint(Theme.Wood.dark)
            }
            .padding(16)
            .foregroundStyle(.black)
        }
    }

    /// One team's score change and where it now stands.
    private func score(team: Int, summary: HandSummary) -> some View {
        let before = match.history.dropLast().last?.scores[team] ?? 0
        let change = summary.scores[team] - before
        return VStack(spacing: 2) {
            Text("\(names[team]) + \(names[team + 2])").font(.caption).lineLimit(1).minimumScaleFactor(0.7).opacity(0.75)
            Text(summary.scores[team], format: .number).font(.system(.title, design: .serif).weight(.semibold)).monospacedDigit()
            Text(change >= 0 ? "+\(change)" : "\(change)").font(.subheadline.weight(.semibold)).monospacedDigit().opacity(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.Wood.dark.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
    
    private func row(_ name: String, team: Int?) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(team.map { "\(names[$0]) + \(names[$0 + 2])" } ?? "Out of play")
        }.font(.caption)
    }
    
    @ViewBuilder private func playRow(_ reviewPlay: PlayReview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(names[reviewPlay.play.seat]).font(.caption.weight(.semibold))
                Spacer()
                Text(reviewPlay.play.card.name).font(.caption)
                if coaching {
                    Image(systemName: reviewPlay.agreed ? "checkmark" : "arrow.triangle.branch")
                        .foregroundStyle(reviewPlay.agreed ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                }
            }
            if coaching && !reviewPlay.agreed {
                Text(describe(reviewPlay)).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
