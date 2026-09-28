import SwiftUI

/// The words on the tip card between the home screen and the table (D67): where the game comes from, then
/// the tips in a fixed order, then why we play. `GameModel.takeNextTip()` keeps the place across visits in `Settings.nextTip`.
enum TipDeck {
    struct Face: Hashable {
        let label: String
        let text: String
    }

    static let tips = [
        "The five of trump is worth 5 of the 9 points. Protect yours, and hunt theirs.",
        "High and Low go to the highest and lowest trump actually played, not the Ace and the 2.",
        "A ten counts 10 toward Game. Win a trick with a ten in it and Game is close.",
        "Listen to the discards. Someone who throws 4 is still holding at least 2 trump.",
        "Undealt cards stay out of play. The Jack or the Five of trump may not be in anyone's hand.",
        "If everyone passes, the dealer has to bid 2.",
        "The dealer can match the highest bid and take it.",
        "9 and out: take all nine points and the match is yours. Miss one and it's gone.",
        "Fall short and you lose your whole bid. Defenders always keep what they catch.",
        "First to 25 wins. If both teams get there on the same hand, the bidders win.",
        "No Wi-Fi needed. On a plane? Read a book, or play our game.",
    ]

    /// The first face of every visit.
    static let origin = Face(label: "WHERE IT COMES FROM", text: RulesText.origin)

    /// Not a numbered tip: it closes each full cycle, after the eleventh (N38).
    static let whyWePlay = Face(label: "WHY WE PLAY", text: "52 cards. Endless ways to play. But at the end of the day, it brings people together.")

    /// The faces in one full cycle: every tip, then why we play.
    static let cycle = tips.count + 1

    /// Face `index` of the cycle, counted from 0 and read modulo `cycle`: the tips in order, then `whyWePlay`.
    static func face(_ index: Int) -> Face {
        let wrapped = (index % cycle + cycle) % cycle
        return wrapped == tips.count ? whyWePlay : tip(wrapped)
    }

    /// Tip `index`, counted from 0 and read modulo the number of tips.
    static func tip(_ index: Int) -> Face {
        let wrapped = (index % tips.count + tips.count) % tips.count
        return Face(label: "TIP \(wrapped + 1) OF \(tips.count)", text: tips[wrapped])
    }

    /// How long each face shows before the card turns over, or deals after its second face.
    static let flipInterval: Duration = .milliseconds(3200)
    /// The four card backs' flight to the seats as the table appears.
    static let dealSeconds = 0.5
}

/// A large card over the table that turns over to a tip, then deals the table in. A tap anywhere deals at
/// once; left alone it deals after its second face. Reduce Motion turns the flip and the deal into crossfades.
struct TipCardView: View {
    @ObservedObject var model: GameModel
    /// The screenshot stage keeps the card up instead of dealing on its own.
    var holds = false
    let onDealt: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var face = TipDeck.origin
    @State private var angle = 0.0
    /// The deal has begun: the backs are out and flying.
    @State private var dealing = false
    @State private var flown = false

    var body: some View {
        GeometryReader { geometry in
            let width = min(270, geometry.size.width * 0.66)
            ZStack {
                Theme.Wood.header.opacity(flown ? 0 : 0.6).ignoresSafeArea()
                VStack(spacing: 20) {
                    card(width: width)
                        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                    Text("Tap to deal")
                        .font(.system(.caption, design: .monospaced).weight(.semibold)).tracking(2)
                        .foregroundStyle(.ivory).opacity(0.8)
                }
                .scaleEffect(flown && !reduceMotion ? 0.7 : 1)
                .opacity(flown ? 0 : 1)
                // Always laid out, hidden until the deal, so the flight starts from the card's centre.
                if !reduceMotion {
                    ForEach(0..<4, id: \.self) { place in
                        CardBackView(width: 44)
                            .offset(flown ? Self.seatOffset(place, in: geometry.size) : .zero)
                            .opacity(dealing ? 1 : 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .onTapGesture { deal() }
        .task { await run() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(face.label.capitalized). \(face.text)")
        .accessibilityHint("Deals you in")
        .accessibilityAddTraits([.isButton, .isModal])
        .accessibilityAction { deal() }
    }

    /// Where each seat's back lands: 0 at the bottom, 1 on the left, 2 across, 3 on the right.
    static func seatOffset(_ place: Int, in size: CGSize) -> CGSize {
        switch place {
        case 0: CGSize(width: 0, height: size.height * 0.42)
        case 1: CGSize(width: -size.width * 0.42, height: 0)
        case 2: CGSize(width: 0, height: -size.height * 0.34)
        default: CGSize(width: size.width * 0.42, height: 0)
        }
    }

    private func card(width: Double) -> some View {
        let radius = width * 0.06
        return ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.ivory)
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(.black.opacity(0.18)))
                .shadow(color: .black.opacity(0.45), radius: 12, y: 8)
            VStack(spacing: 12) {
                Text(face.label)
                    .font(.system(.caption, design: .monospaced).weight(.semibold)).tracking(2)
                    .foregroundStyle(Theme.Wood.dark)
                Text(face.text)
                    .font(.system(.title3, design: .serif).weight(.medium))
                    .foregroundStyle(Theme.Wood.header)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 22)
            .id(face)
            .transition(.opacity)
            corner.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(12)
            corner.rotationEffect(.degrees(180)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(12)
        }
        .frame(width: width, height: width * 1.4)
    }

    /// The five of hearts' index in the card's corners, the game's signature.
    private var corner: some View {
        VStack(spacing: -4) {
            Text("5").font(.system(size: 26, weight: .bold, design: .serif))
            Text("♥").font(.system(size: 19))
        }
        .foregroundStyle(Color.suitRed)
    }

    /// The origin line, one tip, then the deal, unless a tap deals first.
    private func run() async {
        try? await Task.sleep(for: TipDeck.flipInterval)
        guard !Task.isCancelled, !dealing else { return }
        await turn(to: model.takeNextTip())
        guard !holds else { return }
        try? await Task.sleep(for: TipDeck.flipInterval)
        guard !Task.isCancelled else { return }
        deal()
    }

    /// A 3D turn about the vertical axis, the face swapped edge-on; a crossfade under Reduce Motion.
    private func turn(to next: TipDeck.Face) async {
        if reduceMotion {
            withAnimation(Theme.Motion.reduced) { face = next }
            return
        }
        withAnimation(.easeIn(duration: 0.25)) { angle = 90 }
        try? await Task.sleep(for: .milliseconds(250))
        face = next
        angle = -90
        withAnimation(.easeOut(duration: 0.25)) { angle = 0 }
    }

    private func deal() {
        guard !dealing else { return }
        dealing = true
        withAnimation(reduceMotion ? Theme.Motion.reduced : .easeOut(duration: TipDeck.dealSeconds)) { flown = true }
        Task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : TipDeck.dealSeconds))
            onDealt()
        }
    }
}
