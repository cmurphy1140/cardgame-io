import SwiftUI

/// A "HI, MY NAME IS" sticker (N64): white with a green outline, the words printed on a green band, the name
/// handwritten under it in the scorecard's Marker Felt. Every seat wears one pinned to its shirt (D93), the phone
/// holder's under the hand at full size.
struct NameTag: View {
    let name: String
    /// The sticker's width; a seat's tag fits its shirt.
    var width = Theme.Table.nameTagWidth
    /// The printing and the handwriting, scaled together so a smaller tag still reads as the same sticker.
    var scale = 1.0

    nonisolated static let band = "HI, MY NAME IS"
    nonisolated static let handwriting = Scorecard.handwriting

    /// The names by place round the table, 0 the phone holder at the bottom, then left, across and right.
    static func names(_ model: GameModel) -> [String] {
        (0..<4).map { model.seatNames[model.seat(at: $0)] }
    }

    var body: some View {
        sticker.dynamicTypeSize(...Theme.Card.maximumTypeSize)
    }

    private var sticker: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        return VStack(spacing: 0) {
            Text(Self.band).font(.system(size: 9 * scale, weight: .heavy)).tracking(0.5 * scale)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 1)
                .background(Theme.Table.tagGreen)
            Text(name).font(.custom(Self.handwriting, size: Theme.Table.nameTagSize * scale, relativeTo: .title3))
                .foregroundStyle(Theme.Wood.streakDark)
                .padding(.horizontal, 6 * scale).padding(.vertical, -2 * scale)
        }
        .lineLimit(1).minimumScaleFactor(0.5)
        .frame(width: width)
        .fixedSize(horizontal: false, vertical: true)
        .background(.white, in: shape)
        .clipShape(shape)
        .overlay(shape.stroke(Theme.Table.tagGreen, lineWidth: 2))
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
    }
}

extension NameTag {
    /// The tag as a button that renames its seat (D93): the sticker unchanged, its hit area at least a thumb tall.
    func renames(_ onRename: @escaping () -> Void) -> some View {
        Button(action: onRename) {
            frame(minHeight: Theme.Table.statusButtonHitSize).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityHint("Rename this seat")
    }
}
