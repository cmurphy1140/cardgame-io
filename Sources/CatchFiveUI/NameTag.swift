import SwiftUI

/// A "HI, MY NAME IS" sticker floating above a seat's head (N64): white with a green outline, the words printed on
/// a green band, the name handwritten under it in the scorecard's Marker Felt. Every seat wears one, the phone
/// holder's under the hand.
struct NameTag: View {
    let name: String
    /// The partner's stack of backs rides beside the tag (N64).
    var backs = 0

    nonisolated static let band = "HI, MY NAME IS"
    nonisolated static let handwriting = Scorecard.handwriting

    /// The names by place round the table, 0 the phone holder at the bottom, then left, across and right.
    static func names(_ model: GameModel) -> [String] {
        (0..<4).map { model.seatNames[model.seat(at: $0)] }
    }

    var body: some View {
        sticker
            // Tucked behind the tag's corner, so the partner's tile keeps its width beside the corners.
            .overlay(alignment: .bottomTrailing) {
                if backs > 0 {
                    ZStack(alignment: .leading) {
                        ForEach(0..<min(3, backs), id: \.self) { index in
                            CardBackView(width: Theme.Table.seatBackWidth).offset(x: Double(index) * 3)
                        }
                    }
                    .offset(x: 10, y: 4)
                    .accessibilityHidden(true)
                }
            }
            .dynamicTypeSize(...Theme.Card.maximumTypeSize)
    }

    private var sticker: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        return VStack(spacing: 0) {
            Text(Self.band).font(.system(size: 9, weight: .heavy)).tracking(0.5)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 1)
                .background(Theme.Table.tagGreen)
            Text(name).font(.custom(Self.handwriting, size: Theme.Table.nameTagSize, relativeTo: .title3))
                .foregroundStyle(Theme.Wood.streakDark)
                .padding(.horizontal, 6).padding(.vertical, -2)
        }
        .lineLimit(1).minimumScaleFactor(0.5)
        .frame(width: Theme.Table.nameTagWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(.white, in: shape)
        .clipShape(shape)
        .overlay(shape.stroke(Theme.Table.tagGreen, lineWidth: 2))
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
    }
}
