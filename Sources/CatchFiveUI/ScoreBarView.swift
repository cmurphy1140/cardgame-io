import SwiftUI

/// The bar pinned above the table (spec R1): the menu, which is also where the game pauses (spec R32). The
/// score sits at the foot of the green rails (N62) and the bid and trump in the table's top corners (D65); the
/// rest of the bar is left empty on purpose.
struct ScoreBarView: View {
    /// Opens the pause card over the table.
    let onPause: () -> Void

    var body: some View {
        HStack(spacing: 10) {
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
