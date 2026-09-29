import CatchFive
import SwiftUI

/// The playing surface: partner across the top, West and East at the sides, the pile in the middle,
/// the status line and explanations under it, and the phase controls where the pile sits during the auction.
struct TableSurface: View {
    @ObservedObject var model: GameModel
    let namespace: Namespace.ID
    /// Completed tricks that have already collapsed toward their winner.
    let collapsedTricks: Int
    /// A completed trick the player asked to see again.
    let reopenedTrick: Int?
    /// The human's latest action while its undo toast is showing.
    let toast: PlayerAction?
    let onReopenTrick: () -> Void
    let onCloseTrick: () -> Void
    /// The 9-and-out pill asks the table to confirm before the bid is sent.
    let onNineAndOut: () -> Void
    /// The deck beside the dealer's tile says where it rests, so the deal can start there.
    var onDeck: (CGPoint) -> Void = { _ in }
    /// The scorecard opens the full score sheet (N66).
    var onScorecard: () -> Void = {}
    /// A seat's name tag was tapped: rename that seat (D92).
    var onRename: (Int) -> Void = { _ in }
    /// A match-win celebration is playing; the hand-end card waits until it has finished (D69).
    var holdsResult = false
    /// VoiceOver focus lands on the status line when a cover lifts or the turn changes.
    let statusFocus: AccessibilityFocusState<Bool>.Binding
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The hint's full reason, opened from its Why? control (spec R22).
    @State private var showHintDetail = false
    /// The column's own height, measured so the table can tell whether it fits the surface (spec R25).
    @State private var contentHeight = 0.0
    /// The floating notice's height, so it sits wholly above "Your turn" in play.
    @State private var floatHeight = 0.0
    /// The top row's lower edge: the hand-end card starts under it, so the scorecard stays in view (N66).
    @State private var topRowBottom = 0.0

    private var hand: Hand { model.match.hand }

    /// Which plays the pile shows, and the winner if they are a finished trick.
    private var pile: (plays: [Play], winner: Int?, isLast: Bool) {
        if !hand.currentTrick.isEmpty { return (hand.currentTrick, nil, false) }
        guard let last = hand.completedTricks.last else { return ([], nil, false) }
        let count = hand.completedTricks.count
        if count > collapsedTricks || reopenedTrick == count { return (last.plays, last.winner, true) }
        return ([], nil, false)
    }

    private var inAuction: Bool { hand.phase == .bidding || hand.phase == .choosingTrump }
    /// Beginner mode is set aside for this milestone (H01, T03): the live table carries no coaching, and the
    /// teaching lives in How to Play. `Settings.beginnerMode` stays in the file so saves keep loading.
    private let coaching = false

    var body: some View {
        GeometryReader { geometry in
            let reach = CGSize(width: geometry.size.width / 2 + 40, height: geometry.size.height / 2 + 40)
            // Space goes by priority (spec R25): the seats and the pile hold the top of the table, the
            // status line with its controls and commentary sits down by the hand, and whatever the phase
            // leaves over opens up between them. The column is stretched to the surface whenever its
            // content fits; when it cannot, at accessibility text sizes, it keeps its own height and scrolls.
            let fits = contentHeight <= geometry.size.height + 0.5
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    // The phone holder sits at the bottom; in pass and play the table turns with the phone.
                    // The bid box in the top-left corner: who bid, the bid and trump with the player's tally on
                    // the suit (D65, N63), beside the partner and no taller than the partner's tile. It pops in the
                    // first time it fills (N53).
                    let cornerWidth = TableLayout.cornerWidth(available: geometry.size.width)
                    HStack(alignment: .top, spacing: 0) {
                        corner(width: cornerWidth) {
                            if let contract = ContractPlaque.contract(in: model) {
                                ContractPlaque.onTable(model, contract: contract, width: cornerWidth).modifier(CornerArrival())
                            }
                        }
                        .opacity(dim)
                        .accessibilitySortPriority(25)
                        Spacer(minLength: 0)
                        SeatView(model: model, seat: model.seat(at: 2), isPartner: true, onDeck: onDeck, onRename: onRename).accessibilitySortPriority(20)
                            // The partner's box sits beside them on the left, in the corner the bid box will take (N55),
                            // since the scorecard holds the right (N66). Level with the top of the face.
                            .overlay(alignment: .topLeading) {
                                if hand.phase == .bidding {
                                    bidBox(at: 2, from: CGSize(width: Theme.Table.bidBoxWidth, height: 0))
                                        .offset(x: -Theme.Table.bidBoxWidth - 4, y: Theme.Table.portraitSize * Theme.Table.portraitHeadroom)
                                }
                            }
                            .opacity(dim)
                        Spacer(minLength: 0)
                        // The scorecard: each team's total after every hand, handwritten on a notebook page (N66).
                        Scorecard(us: Scorecard.lines(team: model.ourTeam, history: model.match.history),
                                  them: Scorecard.lines(team: 1 - model.ourTeam, history: model.match.history),
                                  width: cornerWidth, onOpen: onScorecard)
                            .accessibilitySortPriority(24)
                    }
                    .onGeometryChange(for: Double.self) { $0.frame(in: .named(Self.space)).maxY } action: { topRowBottom = $0 }
                    // The side tiles give way before the pile can touch them (`TableLayout`); in the auction
                    // there is no pile, so they keep their full width. Faces sit level with the pile's centre,
                    // each beside the card its seat played.
                    let sideWidth = inAuction ? Theme.Table.seatTileWidth : TableLayout.sideSeatWidth(available: geometry.size.width)
                    HStack(alignment: .center) {
                        // Each side seat's box sits low beside it, toward the empty middle, clear of the partner's name (N55).
                        SeatView(model: model, seat: model.seat(at: 1), width: sideWidth, onDeck: onDeck, onRename: onRename).accessibilitySortPriority(30)
                            .modifier(DemoTap(active: model.tallyDemo == .face(seat: model.seat(at: 1))))
                            .overlay(alignment: .bottomTrailing) {
                                if hand.phase == .bidding {
                                    bidBox(at: 1, from: CGSize(width: -Theme.Table.bidBoxWidth, height: -Theme.Table.bidBoxHeight))
                                        .offset(x: Theme.Table.bidBoxWidth - Theme.Table.bidBoxTuck)
                                }
                            }
                        Spacer(minLength: TableLayout.seatGap)
                        if !inAuction { centre(reach: reach) }
                        Spacer(minLength: TableLayout.seatGap)
                        SeatView(model: model, seat: model.seat(at: 3), width: sideWidth, onDeck: onDeck, onRename: onRename).accessibilitySortPriority(10)
                            .overlay(alignment: .bottomLeading) {
                                if hand.phase == .bidding {
                                    bidBox(at: 3, from: CGSize(width: Theme.Table.bidBoxWidth, height: -Theme.Table.bidBoxHeight))
                                        .offset(x: Theme.Table.bidBoxTuck - Theme.Table.bidBoxWidth)
                                }
                            }
                    }
                    // While bidding there is no pile between them, so the side seats rise toward the partner, stopping
                    // under the scorecard, and the bigger faces leave the bid pills their room (N48).
                    .padding(.top, hand.phase == .bidding ? -Theme.Table.biddingSideRise : 0)
                    .opacity(dim)
                    Spacer(minLength: 4)
                    ForEach(Self.lowerRows(inAuction: inAuction), id: \.self) { row in
                        switch row {
                        case .commentary: commentary
                        case .status:
                            statusLine.accessibilitySortPriority(4)
                                .overlay(alignment: .top) {
                                    if Self.commentaryFloats(inAuction: inAuction) {
                                        commentary.padding(.bottom, 4)
                                            .onGeometryChange(for: Double.self) { $0.size.height } action: { floatHeight = $0 }
                                            .offset(y: -floatHeight)
                                    }
                                }
                        case .controls:
                            if model.isHumanTurn, hand.phase == .bidding { bidding }
                            if model.isHumanTurn, hand.phase == .choosingTrump { trumpChoice }
                        }
                    }
                    .opacity(dim)
                }
                .padding(.top, Theme.Table.seatInset)
                .onGeometryChange(for: Double.self) { $0.size.height } action: { contentHeight = $0 }
                .frame(width: geometry.size.width)
                .frame(height: fits ? geometry.size.height : nil)
            }
            .scrollBounceBehavior(.basedOnSize)
            // A side face at its big-moment size reaches a little past the column; the screen's margin holds it,
            // so the column clips top and bottom only.
            .scrollClipDisabled()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .mask { Rectangle().padding(.horizontal, -Theme.Table.seatInset) }
            // Trump, very large and faint behind the play area: there when you look for it, never in the way.
            .background {
                if let trump = hand.trump {
                    Text(trump.glyph).font(.system(size: Theme.Table.watermarkSize))
                        .foregroundStyle(.ivory.opacity(Theme.Table.watermarkOpacity))
                        .opacity(dim)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            // No corner deck or discard pile (T12): the deck sits beside the dealer's tile instead.
            // The finished hand's card takes over the table; what is underneath fades back and leaves the
            // accessibility tree, so VoiceOver meets the card and nothing behind it.
            .accessibilityHidden(hand.phase == .finished)
            .overlay { if hand.phase == .finished, !holdsResult { finishedCard.padding(.top, topRowBottom) } }
            // The one-time demo of the two taps says what each pulse means, in the middle of the table (N61).
            .overlay {
                if let demo = model.tallyDemo {
                    TallyDemoCaption(text: demo.caption)
                        .padding(.horizontal, Theme.Table.overlayInset)
                        .onTapGesture { withAnimation(reduceMotion ? Theme.Motion.reduced : Theme.Motion.overlay) { model.advanceTallyDemo() } }
                        .transition(.opacity)
                        .id(demo.caption)
                }
            }
        }
        .coordinateSpace(.named(Self.space))
        .accessibilityElement(children: .contain)
    }

    /// The surface's own space, for the top row's lower edge.
    nonisolated static let space = "surface"

    /// Everything but the scorecard fades back under the hand-end card, so the new total stays readable (N66).
    private var dim: Double { hand.phase == .finished ? 0.12 : 1 }

    /// The box of the seat at `place` round the table (N55), its call arriving from `from`.
    private func bidBox(at place: Int, from: CGSize) -> some View {
        BidBox(label: BidBox.label(for: model.seat(at: place), in: hand.auction), from: from)
    }

    /// A top corner of the table: a fixed width, top-aligned, empty until it has something to show.
    private func corner(width: Double, @ViewBuilder _ content: () -> some View) -> some View {
        // The clear strut holds the width while the corner is empty, so the partner stays centred.
        ZStack(alignment: .top) {
            Color.clear.frame(width: width, height: 0)
            content()
        }
    }

    // MARK: Pile

    @ViewBuilder private func centre(reach: CGSize) -> some View {
        let pile = pile
        ZStack {
            // Reserve the pile's footprint so the layout does not jump between phases.
            Color.clear.frame(width: TableLayout.pileReservation,
                              height: Theme.Card.pileWidth * Theme.Card.ratio + Theme.Table.partnerNudge + Theme.Table.ownNudge + 8)
            ForEach(pile.plays, id: \.card) { play in
                Button { model.explain(play, inLastTrick: pile.isLast) } label: {
                    CardView(card: play.card, width: Theme.Card.pileWidth, style: .pile)
                        .overlay(RoundedRectangle(cornerRadius: Theme.Card.radius(width: Theme.Card.pileWidth), style: .continuous)
                            .stroke(.gold, lineWidth: pile.winner == play.seat ? 3 : 0))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(coaching)
                .accessibilityLabel(model.spokenDescription(of: play, winner: pile.winner))
                .accessibilityHint(coaching ? "Explains why this card was played" : "")
                .rotationEffect(.degrees(toss(for: play).rotation))
                .offset(Self.pileOffset(for: model.place(of: play.seat)) + toss(for: play).offset)
                .matchedGeometryEffect(id: play.card, in: namespace)
                .transition(transition(for: play, winner: pile.winner, reach: reach))
                .zIndex(Double(pile.plays.firstIndex(where: { $0.card == play.card }) ?? 0))
            }
            if pile.plays.isEmpty, hand.phase == .playing, !model.isHumanTurn || hand.completedTricks.isEmpty {
                Text(hand.completedTricks.isEmpty ? "First lead" : "").font(.caption2).opacity(0.7)
            }
        }
        .accessibilitySortPriority(5)
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
    }

    /// The card's own turn and drift on the pile, fixed for as long as this trick lies there.
    private func toss(for play: Play) -> CardToss.Pose {
        CardToss.pose(for: play.card, hand: model.match.handNumber, trick: hand.completedTricks.count)
    }

    /// Where each card rests on the pile: nudged toward the place (0 bottom, 1 left, 2 across, 3 right) of the
    /// seat that played it.
    static func pileOffset(for place: Int) -> CGSize {
        switch place {
        case 1: CGSize(width: -Theme.Table.sideNudge, height: 0)
        case 2: CGSize(width: 0, height: -Theme.Table.partnerNudge)
        case 3: CGSize(width: Theme.Table.sideNudge, height: 0)
        default: CGSize(width: 0, height: Theme.Table.ownNudge)
        }
    }

    /// Unit direction from the pile toward a place round the table.
    static func direction(for place: Int) -> CGSize {
        switch place {
        case 1: CGSize(width: -1, height: 0)
        case 2: CGSize(width: 0, height: -1)
        case 3: CGSize(width: 1, height: 0)
        default: CGSize(width: 0, height: 1)
        }
    }

    /// Another seat's card arrives from its place; a finished trick leaves toward the winner's place.
    /// The phone holder's own card is moved by `matchedGeometryEffect` from the hand instead.
    private func transition(for play: Play, winner: Int?, reach: CGSize) -> AnyTransition {
        if reduceMotion { return .opacity }
        let from = Self.direction(for: model.place(of: play.seat))
        let to = Self.direction(for: model.place(of: winner ?? play.seat))
        let insertion: AnyTransition = model.place(of: play.seat) == 0 ? .identity
            : .offset(x: from.width * reach.width, y: from.height * reach.height).combined(with: .opacity)
        let removal: AnyTransition = .offset(x: to.width * reach.width, y: to.height * reach.height)
            .combined(with: .scale(scale: 0.5)).combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }

    // MARK: Status, hints, explanations

    enum LowerRow: Hashable { case commentary, status, controls }

    /// The rows under the pile, top to bottom. In play the column has no height to spare above the hand, so
    /// the notice line ("Discarded: …") takes no row: it floats above "Your turn" in the space the pile
    /// leaves. The auction keeps its call under the controls.
    nonisolated static func lowerRows(inAuction: Bool) -> [LowerRow] {
        inAuction ? [.status, .controls, .commentary] : [.controls, .status]
    }

    nonisolated static func commentaryFloats(inAuction: Bool) -> Bool { !inAuction }

    /// Height the commentary holds even when empty: none in play (it floats), none while your bid controls
    /// need the space.
    nonisolated static func commentaryMinHeight(inAuction: Bool, humanTurn: Bool) -> Double {
        inAuction && !humanTurn ? 36 : 0
    }

    /// The status line while the last trick is reopened: it is the last trick of the hand in play (N42).
    nonisolated static let reviewLabel = "Reviewing last trick"

    private var statusLine: some View {
        HStack(spacing: 8) {
            if reopenedTrick != nil {
                // Reviewing the last trick is its own state (spec R24): say so, and name the way back.
                // Play waits while the trick is open; no hint is offered, since nothing is being decided.
                Button(action: onCloseTrick) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.subheadline.weight(.bold))
                        Text("Back to play").font(.subheadline.weight(.semibold))
                    }
                    .frame(minHeight: Theme.Table.statusButtonHitSize)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to play")
                Text(Self.reviewLabel).font(.title3.weight(.medium)).lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .accessibilityFocused(statusFocus)
                Spacer().frame(width: Theme.Table.statusButtonHitSize, height: Theme.Table.statusButtonHitSize)
            } else {
                // Left: your own box in the auction, its call rising from the bid row (N55); in play, reopen the
                // last trick when the pile is clear. Right: the hint on your turn.
                if hand.phase == .bidding {
                    bidBox(at: 0, from: CGSize(width: 0, height: Theme.Table.auctionButtonHeight + Theme.Table.bidBoxHeight))
                } else if pile.plays.isEmpty, hand.completedTricks.last != nil, hand.phase == .playing {
                    smallButton("rectangle.stack", label: "Show the last hand", action: onReopenTrick)
                } else {
                    Spacer().frame(width: Theme.Table.statusButtonHitSize, height: Theme.Table.statusButtonHitSize)
                }
                // Your turn is the loudest line on the table (T05); everything else stays at a calm weight.
                statusText.font(model.isHumanTurn ? .title2.weight(.bold) : .title3.weight(.medium))
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .accessibilityFocused(statusFocus)
                if model.isHumanTurn, hand.phase != .finished, coaching {
                    smallButton("lightbulb", label: "Hint") { model.showHint() }
                } else if hand.phase == .bidding {
                    Spacer().frame(width: Theme.Table.bidBoxWidth, height: Theme.Table.bidBoxHeight)
                } else {
                    Spacer().frame(width: Theme.Table.statusButtonHitSize, height: Theme.Table.statusButtonHitSize)
                }
            }
        }
    }

    /// A tertiary control: a 28pt circle inside a 44pt hit area.
    /// A bare glyph with a soft shadow for contrast, no plate (spec R19); the hit area stays 48 pt.
    private func smallButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.title3.weight(.medium))
                .shadow(color: .black.opacity(0.45), radius: 1.5, y: 1)
                .frame(width: Theme.Table.statusButtonHitSize, height: Theme.Table.statusButtonHitSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var statusText: Text {
        if let winner = model.match.winner {
            return Text(model.winnerHeadline(winner))
        }
        let actor = hand.nextSeat.map { model.seatNames[$0] } ?? ""
        switch hand.phase {
        case .bidding:
            let bid = hand.auction.isNineAndOut ? "9 and out" : hand.auction.highestBid.map(String.init) ?? "none"
            // On your bid the auction chips carry the high bid (B04), so the line only says whose turn it is.
            return model.isHumanTurn ? Text("Your bid").foregroundStyle(.gold)
                : Text("\(actor) is bidding · high bid \(bid)")
        case .choosingTrump:
            return model.isHumanTurn ? Text("Choose trump").foregroundStyle(.gold) : Text("\(actor) is choosing trump")
        case .playing:
            // No follow-suit line (T06), and no "is thinking": the dots above that seat's tile say it (T04).
            return model.isHumanTurn ? Text("Your turn").foregroundStyle(.gold) : Text(" ")
        case .finished:
            return Text("Hand complete")
        }
    }

    /// One line under the status: a refusal, else a hint reason or explanation, else the notice (no undo
    /// toast on the play surface, T07), else the note that a team down 10 is bidding bolder (D71), else your standing call in the auction, else a
    /// placeholder in play. Reserves no space in the auction while the controls need it.
    @ViewBuilder private var commentary: some View {
        ZStack {
            if let refusal = model.refusal {
                // A refused tap answers first: it is the freshest thing the player did.
                Text(refusal).font(.footnote).multilineTextAlignment(.center).foregroundStyle(.ivory.opacity(0.9))
                    .padding(.horizontal, 8)
            } else if let hint = model.hint {
                // One complete recommendation on one line; the reason waits behind Why?, so a long hint
                // can never push the controls above it off the screen (spec R22).
                let parts = Self.hintParts(hint.reason)
                HStack(spacing: 10) {
                    Text(parts.recommendation).font(.footnote.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                    if !parts.detail.isEmpty {
                        Button("Why?") { showHintDetail = true }
                            .font(.footnote.weight(.semibold)).tint(.ivory).underline()
                            .accessibilityHint("Opens the reason for this hint")
                    }
                }
                .foregroundStyle(.ivory)
                .padding(.horizontal, 8)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Hint: \(parts.recommendation)")
            } else if let text = model.explanation {
                Text(text)
                    .font(.footnote).multilineTextAlignment(.center)
                    .foregroundStyle(.ivory.opacity(0.85))
                    .padding(.horizontal, 8)
            } else if let notice = model.notice {
                Text(notice).font(.footnote).opacity(0.85)
            } else if let note = model.boldNote {
                Text(note).font(.footnote).opacity(0.85)
                    .transition(.opacity)
            } else if hand.phase == .bidding, !model.isHumanTurn, let seat = model.viewerSeat, let call = model.latestCall(for: seat) {
                Text("You: \(call)").font(.footnote).opacity(0.85)
            } else if !inAuction {
                Text(pile.plays.isEmpty || !coaching ? " " : (reopenedTrick != nil ? "Tap a card to see why it was played" : "Tap a card on the table to see why it was played"))
                    .font(.footnote).foregroundStyle(.ivory.opacity(0.7))
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.commentaryMinHeight(inAuction: inAuction, humanTurn: model.isHumanTurn), alignment: .top)
        .animation(reduceMotion ? Theme.Motion.reduced : Theme.Motion.overlay, value: toast)
        .sheet(isPresented: $showHintDetail) {
            if let hint = model.hint {
                HintDetailView(parts: Self.hintParts(hint.reason))
            }
        }
    }

    /// Advice reads "Play the six of clubs: partner's queen holds the trick, so…". The part before the
    /// colon is the recommendation; the rest, with a capital, is the reason. No colon: all recommendation.
    nonisolated static func hintParts(_ reason: String) -> (recommendation: String, detail: String) {
        guard let colon = reason.firstIndex(of: ":") else { return (reason, "") }
        let recommendation = String(reason[..<colon]).trimmingCharacters(in: .whitespaces)
        let rest = reason[reason.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        guard let first = rest.first else { return (recommendation, "") }
        return (recommendation, first.uppercased() + rest.dropFirst())
    }

    // MARK: Phase controls

    /// One pill of the bid row: its number, and whether the seat to act may still bid it.
    struct BidPill: Equatable {
        let bid: Int
        let enabled: Bool
    }

    /// Every bid from 2 to 9, lowest first; the ones the auction has passed stay in place, greyed (N55, over B03).
    nonisolated static func bidRow(allows: (Int) -> Bool) -> [BidPill] {
        HouseRules.bidRange.map { BidPill(bid: $0, enabled: allows($0)) }
    }

    enum AuctionRow: Hashable { case numbers, nineAndOut, pass }

    /// The auction's rows, top to bottom: the numbers, 9 and out on its own line under them when it may be bid
    /// (so it covers no number), then Pass.
    nonisolated static func auctionRows(nineAndOut: Bool) -> [AuctionRow] {
        nineAndOut ? [.numbers, .nineAndOut, .pass] : [.numbers, .pass]
    }

    /// The auction's controls (B05, N55): every number in one row, the lowest you may bid edged in light brown,
    /// 9 and out on a short line of its own under the 9, and Pass as the one wide secondary action. The seats' boxes
    /// carry who bid what, so there are no High and Lowest chips.
    private var bidding: some View {
        let row = Self.bidRow { model.allows(.bid($0)) }
        let lowest = row.first(where: \.enabled)?.bid
        return VStack(spacing: Theme.Table.auctionButtonSpacing) {
            if let context = model.auctionContext {
                Text(context).font(.footnote).opacity(0.85).multilineTextAlignment(.center).padding(.bottom, 2)
            }
            ForEach(Self.auctionRows(nineAndOut: model.allows(.nineAndOut)), id: \.self) { line in
                switch line {
                case .numbers:
                    HStack(spacing: Theme.Table.auctionButtonSpacing) {
                        ForEach(row, id: \.bid) { pill in
                            actionButton(String(pill.bid), action: .bid(pill.bid), fill: .ivory,
                                         font: .title2.weight(.bold), labelColor: .suitRed)
                                .overlay(RoundedRectangle(cornerRadius: Theme.Table.auctionButtonRadius, style: .continuous)
                                    .stroke(Theme.Wood.light, lineWidth: pill.bid == lowest ? 3 : 0))
                        }
                    }
                    .dynamicTypeSize(...Theme.Card.maximumTypeSize)
                case .nineAndOut:
                    // Flush with the row's end, under the 9 it belongs to.
                    HStack { Spacer(minLength: 0); nineAndOutButton }
                case .pass:
                    actionButton("Pass", action: .bid(nil), fill: Theme.Wood.header,
                                 font: .body.weight(.semibold), labelColor: .ivory)
                }
            }
        }
        .animation(reduceMotion ? Theme.Motion.reduced : Theme.Motion.overlay, value: row)
    }

    /// The rare bid, small and set apart under the 9 it belongs to (B02).
    private var nineAndOutButton: some View {
        Button { onNineAndOut() } label: {
            Text("9 and out").font(.caption.weight(.semibold)).foregroundStyle(.ivory)
                .lineLimit(1).fixedSize()
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(Theme.Wood.dark, in: Capsule())
                .overlay(Capsule().stroke(Theme.Wood.light, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Take all nine points or lose the match; asks you to confirm")
    }

    /// Four suit pills, each named for newcomers and captioned with what choosing it keeps and draws.
    /// Suits alternate red and black, ♥ ♠ ♦ ♣, so the two red suits never sit side by side (spec R13).
    nonisolated static let trumpOrder: [Suit] = [.hearts, .spades, .diamonds, .clubs]

    private var trumpChoice: some View {
        HStack(alignment: .top, spacing: Theme.Table.auctionButtonSpacing) {
            ForEach(Self.trumpOrder, id: \.self) { suit in
                VStack(spacing: 2) {
                    // The glyph carries the suit's colour on the same dark pill as every other choice; a red
                    // fill only hid the glyph (spec R13).
                    actionButton(suit.glyph, action: .chooseTrump(suit), fill: .ivory,
                                 font: .largeTitle.weight(.bold),
                                 labelColor: suit.isRed ? Color.suitRed : .black)
                        .accessibilityLabel("\(suit.rawValue), \(model.trumpPreview(for: suit) ?? "")")
                    // The suit on one line and, in beginner mode, what it keeps on a second (spec R30), so no
                    // caption is ever shrunk to fit its column; the draw count is implied and VoiceOver reads it all.
                    // A single row of pills leaves room for two short lines even on the smallest phone (D34).
                    VStack(spacing: 1) {
                        Text(suit.rawValue)
                        if coaching, let keeps = model.trumpPreview(for: suit)?.split(separator: " · ").first {
                            Text(keeps)
                        }
                    }
                    .font(.caption2.weight(.semibold)).opacity(0.8)
                    .lineLimit(1)
                }
                .accessibilityElement(children: .contain)
            }
        }
    }

    /// Pills fill their column so neighbours almost touch: solid, tall, with a large label.
    private func actionButton(_ label: String, action: PlayerAction, fill: Color = Theme.Wood.inlay,
                              font: Font = .title3.weight(.semibold), labelColor: Color = .ivory) -> some View {
        // One dry run per pill: the reason, when there is one, is also why the pill is greyed.
        let reason = model.validationMessage(for: action)
        return Button { model.send(action) } label: { Text(label).font(font) }
            .buttonStyle(PillButtonStyle(fill: fill, labelColor: labelColor))
            .disabled(reason != nil)
            // A greyed pill still says why it is greyed to assistive technology.
            .accessibilityHint(reason ?? "")
    }

    // MARK: Hand end

    private var finishedCard: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                if let winner = model.match.winner { matchOver(winner) }
                if let line = model.handEndLine { handEndWords(line) }
                HandSummaryView(match: model.match, names: model.seatNames, outcome: model.lastHandOutcome, review: model.handReview(), difficulty: model.settings.difficulty, describe: model.describe, coaching: coaching)
                dealButton
            }
            .padding(12)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(.ivory, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.Wood.header.opacity(0.45), lineWidth: 1.5))
        .padding(.vertical, 8).padding(.horizontal, Theme.Table.overlayInset)
        .transition(reduceMotion ? .opacity : .offset(y: 12).combined(with: .opacity))
        .accessibilitySortPriority(40)
    }

    /// One seat's line about the hand, under its portrait and name (N36).
    private func handEndWords(_ line: HandEndLine) -> some View {
        HStack(spacing: 10) {
            PortraitView(portrait: Cast.opponent(at: line.seat)?.portrait ?? model.settings.playerPortrait, size: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(model.seatNames[line.seat]).font(.caption.weight(.semibold)).foregroundStyle(Theme.Wood.dark)
                Text("\u{201C}\(line.text)\u{201D}").font(.system(.title3, design: .serif).italic()).foregroundStyle(Theme.Wood.header)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    private var dealButton: some View {
        Button(model.match.winner == nil ? "Deal next hand" : "Play again") {
            if model.match.winner == nil { model.nextHand() } else { model.newGame() }
        }.buttonStyle(.borderedProminent).tint(Theme.Wood.dark).foregroundStyle(.ivory).lineLimit(1)
        .frame(minHeight: 56) // From R11: ~56-60pt tall
    }

    /// The card shown once a team reaches 25 or a 9-and-out resolves.
    private func matchOver(_ winner: Int) -> some View {
        VStack(spacing: 6) {
            Text(model.mode == .solo && winner == 0 ? "YOU WIN THE MATCH" : "\(model.teamNames(winner)) WIN")
                .font(.system(.subheadline, design: .monospaced).weight(.bold)).tracking(2)
            Text("\(model.match.scores[0]) – \(model.match.scores[1]) after \(model.match.history.count) hands").font(.title3.weight(.semibold))
            if let performance = model.finalPerformance {
                Text("You made \(performance.bidsMade) of \(performance.bids) bids and played the strategy's card \(performance.playsAgreed) of \(performance.plays) times.")
                    .font(.footnote).multilineTextAlignment(.center).opacity(0.8)
            }
        }.foregroundStyle(.black)
    }
}

/// One opponent: a face with a name tag pinned to its shirt, and the dealer badge. A gold ring marks the seat whose
/// turn it is.
struct SeatView: View {
    @ObservedObject var model: GameModel
    let seat: Int
    /// Side tiles take the width the row can spare; the partner's tile keeps the full width.
    var width: Double = Theme.Table.seatTileWidth
    /// The partner across the top: no badge band, so the row stays short, and the dealer's mark set out beside the tile.
    var isPartner = false
    /// The dealer's deck says where it rests.
    var onDeck: (CGPoint) -> Void = { _ in }
    /// The name tag was tapped: rename this seat (D92).
    var onRename: (Int) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The halo's breathing, driven by a repeating animation while this seat is deciding.
    @State private var pulsing = false
    @ScaledMetric(relativeTo: .title2) private var backWidth = Theme.Table.seatBackWidth

    private var hand: Hand { model.match.hand }
    private var active: Bool { hand.nextSeat == seat && model.match.winner == nil }
    private var thinking: Bool { active && !model.isHuman(seat) && hand.phase != .finished }
    /// This seat won the auction, once the auction is over.
    private var isBidder: Bool { hand.auction.nextSeat == nil && hand.auction.winner == seat }
    /// This seat deals the hand and wears the dealer's mark (N65).
    private var deals: Bool { Self.marks(seat: seat, dealer: hand.auction.dealer, bidder: hand.auction.winner).contains(DealerMark.label) }
    /// The player has marked this seat as out of trump (D65).
    private var markedOut: Bool { hand.trump != nil && model.outOfTrump.contains(seat) }

    /// A face with its name tag pinned to the shirt (D92) over one line of badges: the dealer's mark beside the face
    /// (N65), no stack of backs (D92) and no BIDDER, since the bid box shows who bid. Everything a seat says sits on or under its own portrait, so nothing
    /// about a player floats elsewhere on the table (spec R2). The seat to act wears a gold halo that
    /// breathes; that halo is the table's only turn indicator.
    var body: some View {
        VStack(spacing: 2) {
            PortraitView(portrait: portrait, size: Theme.Table.portraitSize, expression: expression, popsOut: true)
                // Big public moments show larger on the face, until the next lead (N36).
                .scaleEffect(bigMomentScale, anchor: .bottom)
                .animation(reduceMotion ? Theme.Motion.reduced : Theme.Motion.overlay, value: SeatMood.isBigMoment(for: seat, in: model.match))
                // The bidder's ring: dashed, light brown, on the portrait's own edge, never the gold halo (D65).
                .overlay {
                    Circle().strokeBorder(Theme.Wood.streakLight,
                                          style: StrokeStyle(lineWidth: Theme.Table.bidderRingWidth, dash: Theme.Table.bidderRingDash))
                        .opacity(isBidder ? 1 : 0)
                }
                .overlay(alignment: .bottomLeading) {
                    if markedOut, let trump = hand.trump { OutOfTrumpBadge(trump: trump).offset(x: -8, y: 2) }
                }
                // Tapping a face marks that seat out of trump, or clears the mark; the player's note, not the game's.
                .contentShape(Circle())
                .onTapGesture { model.toggleOutOfTrump(seat) }
                .overlay {
                    Circle().stroke(.gold, lineWidth: Theme.Table.activeRingWidth)
                        .padding(-Theme.Table.activeRingGap)
                        .opacity(active ? 1 : 0)
                }
                // The popped head goes over the rings as well, so it stays in front of its circle (N49).
                .overlay {
                    PortraitView(portrait: portrait, size: Theme.Table.portraitSize, expression: expression, popsOut: true, headOnly: true)
                        .scaleEffect(bigMomentScale, anchor: .bottom)
                }
                // The tag is pinned to the shirt, a little crooked, like a sticker put on by hand (D92); a tap renames the seat.
                .overlay(alignment: .top) { pinnedTag }
                .scaleEffect(pulsing ? Theme.Table.activePulseScale : 1)
                .onChange(of: active, initial: true) { _, isActive in
                    if isActive, !reduceMotion {
                        withAnimation(Theme.Motion.pulse) { pulsing = true }
                    } else {
                        withAnimation(Theme.Motion.overlay) { pulsing = false }
                    }
                }
                .padding(.vertical, Theme.Table.activeRingGap)
                .padding(.top, Theme.Table.portraitSize * Theme.Table.portraitHeadroom)
                // A computer deciding shows calm dots above its tile instead of a status line (T04).
                .overlay(alignment: .top) {
                    if thinking { ThinkingDots().offset(y: -14).transition(.opacity) }
                }
            // The partner's tile ends at the face, so the row stays short.
            if !isPartner { badges }
        }
        .padding(.horizontal, Self.tilePadding).padding(.vertical, 1)
        .frame(width: width)
        // The dealer owns the deck: the big dealer mark, static, never a control (T12, T13, N65). The side seats wear
        // it under the face (below); the partner's sits off to the right of the tile, beside
        // their card on the pile and under the scorecard.
        .overlay(alignment: .bottomTrailing) {
            if isPartner, deals {
                DealerMark(onPlaced: onDeck)
                    .offset(x: Theme.Table.dealerMarkWidth + Theme.Table.partnerMarkGap, y: Theme.Table.partnerMarkDrop)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.seatSummary(for: seat) + (markedOut ? ", out of trump" : ""))
        .accessibilityActions {
            Button("Rename \(model.seatNames[seat])") { onRename(seat) }
            if hand.trump != nil {
                Button(markedOut ? "Clear out of trump" : "Mark out of trump") { model.toggleOutOfTrump(seat) }
            }
        }
    }

    /// Room the tile keeps on each side.
    nonisolated static let tilePadding = 4.0
    /// About how tall a seat's scaled tag stands, so its thumb-tall hit area can be centred on it.
    nonisolated static let tagHeight = 26.0

    /// The words a seat wears beside its face: DEALER for the dealer, and nothing for the bidder, whom the bid box
    /// shows (N65).
    nonisolated static func marks(seat: Int, dealer: Int, bidder: Int?) -> [String] {
        dealer == seat ? [DealerMark.label] : []
    }

    /// One band, the same height through a hand, so the tiles do not jump when a call lands or the phase turns: the
    /// dealer's mark when this seat deals (N65). The stack of backs that sat beside it is gone (D92).
    private var badges: some View {
        HStack(spacing: 6) {
            if deals { DealerMark(onPlaced: onDeck) }
        }
        .frame(height: deals ? nil : backWidth * Theme.Card.ratio + 2)
    }

    /// The seat's tag, sized to its shirt and a little crooked; its thumb-tall hit area is centred on the sticker.
    private var pinnedTag: some View {
        let drop = Theme.Table.portraitSize * Theme.Table.seatTagDrop - (Theme.Table.statusButtonHitSize - Self.tagHeight) / 2
        return NameTag(name: model.seatNames[seat], width: Theme.Table.portraitSize * Theme.Table.seatTagWidthRatio,
                       scale: Theme.Table.seatTagScale)
            .renames { onRename(seat) }
            .rotationEffect(.degrees(Theme.Table.seatTagTiltDegrees))
            .offset(y: drop)
    }

    private var portrait: Portrait { Cast.opponent(at: seat)?.portrait ?? model.settings.playerPortrait }
    private var expression: Portrait.Expression { SeatMood.expression(for: seat, in: model.match) }
    private var bigMomentScale: Double { SeatMood.isBigMoment(for: seat, in: model.match) ? Theme.Table.bigMomentScale : 1 }
}

/// Whoever deals (N65): a proper deck, much larger than the small stack it replaces, with a big DEALER label on a
/// light tan pill across its foot. Nothing about it is a control.
struct DealerMark: View {
    nonisolated static let label = "DEALER"
    /// Told the deck's centre in the table's coordinate space whenever it moves; the deal starts there.
    var onPlaced: (CGPoint) -> Void = { _ in }
    /// The label beside the deck rather than across its foot, for the short row under the hand.
    var sideways = false

    var body: some View {
        Group {
            if sideways {
                HStack(spacing: 6) { DealerDeck(onPlaced: onPlaced); word }
            } else {
                VStack(spacing: -10) { DealerDeck(onPlaced: onPlaced); word }.frame(width: Theme.Table.dealerMarkWidth)
            }
        }
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var word: some View {
        Text(Self.label).font(.system(size: 14, weight: .heavy)).tracking(0.5)
            .foregroundStyle(Theme.Wood.streakDark)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Theme.Table.cornerFill, in: Capsule())
            .overlay(Capsule().stroke(Theme.Wood.light, lineWidth: 1.5))
            .fixedSize()
    }
}

/// The dealer's deck: a squared stack of backs with no plate, edge or tap, so it reads as a thing on the table and
/// not a button (T13).
struct DealerDeck: View {
    /// Told the deck's centre in the table's coordinate space whenever it moves; the deal starts there.
    var onPlaced: (CGPoint) -> Void = { _ in }

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                CardBackView(width: Theme.Table.dealerMarkDeckWidth).offset(x: Double(index) * -1.5, y: Double(index) * -1.5)
            }
        }
        .onGeometryChange(for: CGPoint.self) { proxy in
            let frame = proxy.frame(in: .named(TableLayout.space))
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { onPlaced($0) }
        .rotationEffect(.degrees(-8))
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Three dots that brighten in turn: a seat is deciding. Still under Reduce Motion.
struct ThinkingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                if reduceMotion {
                    dot.opacity(0.8)
                } else {
                    dot.phaseAnimator([0, 1, 2]) { view, phase in
                        view.opacity(phase == index ? 1 : 0.35)
                    } animation: { _ in .easeInOut(duration: 0.4) }
                }
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Theme.Wood.inlay.opacity(0.85), in: Capsule())
        .accessibilityHidden(true)
    }

    private var dot: some View { Circle().fill(.ivory).frame(width: 6, height: 6) }
}

extension Suit {
    var isRed: Bool { self == .hearts || self == .diamonds }
}

extension Color {
    /// Catch 5 red: the five, hearts/diamonds, and the one primary action on non-felt surfaces.
    static var suitRed: Color { Color(red: 0.698, green: 0.122, blue: 0.180) } // #B21F2E
}

/// The auction's pills: a solid fill, ivory label, a faint edge, dimmed when the rule disallows the
/// action, and a small press. Fills the column it is given.
struct PillButtonStyle: ButtonStyle {
    var fill: Color
    var labelColor: Color = .ivory
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(labelColor)
            .frame(maxWidth: .infinity, minHeight: Theme.Table.auctionButtonHeight)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.Table.auctionButtonRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Table.auctionButtonRadius, style: .continuous)
                .stroke(.ivory.opacity(0.18), lineWidth: 1))
            .opacity(isEnabled ? 1 : 0.35)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.Motion.press, value: configuration.isPressed)
    }
}

/// The undealt stock in the table's top-right corner. Its thickness says roughly how much is left;
/// there is no number, because counting is the player's skill, not the app's (spec R20).
struct DeckView: View {
    let remaining: Int

    /// One back per six cards or part of one, so a full stock reads as five and a near-empty one as one.
    nonisolated static func thickness(_ count: Int) -> Int { max(1, min(5, (count + 5) / 6)) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ForEach(0..<Self.thickness(remaining), id: \.self) { index in
                CardBackView(width: Theme.Table.deckWidth)
                    .offset(x: Double(index) * -2, y: Double(index) * -2)
            }
        }
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Deck")
    }
}

/// The discards, face down in the top-left corner: nothing about them is a secret worth keeping (the rules put
/// them out of play), but nothing about them needs showing either, so no number here (spec R20).
struct DiscardPileView: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ForEach(0..<min(3, DeckView.thickness(count)), id: \.self) { index in
                CardBackView(width: Theme.Table.deckWidth * 0.85)
                    .rotationEffect(.degrees(5 - Double(index) * 5))
                    .offset(x: Double(index) * 1.5, y: Double(index) * -1.5)
            }
        }
        .opacity(0.8)
        .dynamicTypeSize(...Theme.Card.maximumTypeSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Discard pile")
    }
}

private func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

/// The hint's reason, in a short sheet over the table: bounded, scrollable, never in the way of a control.
struct HintDetailView: View {
    let parts: (recommendation: String, detail: String)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("HINT").font(.system(.caption, design: .monospaced)).tracking(1).opacity(0.7)
                Text(parts.recommendation).font(.system(.title3, design: .serif).weight(.bold))
                Text(parts.detail).font(.body).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .foregroundStyle(.ivory)
        .background(WoodGrainView().ignoresSafeArea())
        .presentationDetents([.fraction(0.35), .medium])
        .presentationDragIndicator(.visible)
    }
}

