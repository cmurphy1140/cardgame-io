import CatchFive
import SwiftUI

/// The bar pinned above the table (spec R1): a score chip that opens the score sheet, and the menu, which
/// is also where the game pauses (spec R32). Nothing else lives up here; the bid and trump sit in the
/// table's top corners (D65), the hand number is on the score sheet, the seat to act is ringed at the
/// table, and the dealer badge sits on the hand's label.
struct ScoreBarView: View {
    let us: Int
    let them: Int
    let usLabel: String
    let themLabel: String
    let canUndo: Bool
    let onScores: () -> Void
    /// Opens the pause card over the table.
    let onPause: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onScores) {
                HStack(spacing: 4) {
                    Text("Us").opacity(0.7)
                    Text(us, format: .number).font(.system(.title3, design: .serif).weight(.semibold))
                    Text("·").opacity(0.5)
                    Text("Them").opacity(0.7)
                    Text(them, format: .number).font(.system(.title3, design: .serif).weight(.semibold))
                }
                .font(.subheadline.weight(.semibold)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(usLabel) \(us), \(themLabel) \(them)")
            .accessibilityHint("Shows every hand of this match")

            Spacer(minLength: 4)

            Button(action: onPause) {
                Image(systemName: "pause.circle").font(.title3).frame(width: 44, height: 44, alignment: .trailing)
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pause")
        }
        .foregroundStyle(.ivory)
    }
}
