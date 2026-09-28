import CatchFive
import SwiftUI

/// The gameplay screen: a compact score bar, the table with seats and pile, then the hand.
/// Nothing here scrolls; sheets do. Layout and motion values come from docs/redesign-plan.md.
public struct TableView: View {
    @StateObject private var model: GameModel
    @StateObject private var tutorial: TutorialModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var cards
    @State private var confirmNewGame = false
    @State private var confirmNineAndOut = false
    @State private var showSettings = false
    @State private var showTutorial = false
    /// The team whose score panel is open over the table (N62).
    @State private var scorePanel: Int?
    @State private var showStatistics = false
    /// Completed tricks whose cards have already collapsed toward the winner.
    @State private var collapsedTricks = 0
    @State private var reopenedTrick: Int?
    @State private var shakes: [Card: Int] = [:]
    @State private var shakeCount = 0
    @State private var toast: PlayerAction?
    /// What the last revision changed, reduced to the one cue worth a haptic.
    @State private var cue: (id: Int, cue: TableFeedback.Cue)?
    @State private var seen: TableFeedback.Snapshot
    /// The side seats' lower edge in the table's space: the score rails start below it (N59).
    @State private var sideSeatsBottom = 0.0
    /// Where the deck beside the dealer rests on the table; the refill deals in from here (T12).
    @State private var dealerDeck: CGPoint?
    /// Counts hands dealt while the table is up; each one riffles once at the dealer's deck (D68).
    @State private var shuffles = 0
    /// What still plays before the match-over card: the 9-and-out screen and the cascade (D69).
    @State private var celebrating: [Celebration] = []
    /// Counts cascades begun, for their success haptic.
    @State private var cascades = 0
    @AccessibilityFocusState private var statusFocused: Bool

    private let onLeave: () -> Void
    /// Something outside this view covers the table (the welcome card); computers wait while it is up.
    private let covered: Bool

    public init(model: GameModel, tutorial: TutorialModel? = nil, covered: Bool = false, onLeave: @escaping () -> Void = {}) {
        _model = StateObject(wrappedValue: model)
        // Share the root's tutorial model when there is one, so lessons finished in the intro show as done here.
        _tutorial = StateObject(wrappedValue: tutorial ?? model.makeTutorial())
        _seen = State(initialValue: TableFeedback.Snapshot(model))
        self.covered = covered
        self.onLeave = onLeave
    }

    /// Every reason the scheduler must wait, gathered in one place. Any sheet, dialog, cover or the
    /// reopened trick pauses play; closing one of several keeps it paused.
    private var pause: TablePause {
        TablePause(sceneActive: scenePhase == .active,
                   welcomeShown: covered,
                   sheetShown: showSettings || showTutorial || scorePanel != nil || showStatistics,
                   dialogShown: confirmNewGame || confirmNineAndOut || model.tallyDemo != nil || model.errorMessage != nil || model.saveError != nil,
                   inspectingTrick: reopenedTrick != nil,
                   drawShown: drawShown)
    }

    /// The draw for dealer is showing: a fresh match, not yet covered, with its draw still on the table.
    private var drawShown: Bool { model.dealerDraw != nil && model.match.actionCount == 0 && !covered }

    /// The tally demo is looked for when trump is named and when the table is uncovered again.
    private struct DemoKey: Hashable {
        let trumpNamed: Bool
        let paused: Bool
    }

    /// The scheduler restarts whenever an action lands or the pause lifts, and cancels when a pause begins.
    private struct SchedulerKey: Hashable {
        let revision: Int
        let paused: Bool
    }

    public var body: some View {
        withSheets
            // Pass and play: nothing of the table shows, to the eye or to VoiceOver, until the next player is ready.
            .accessibilityHidden(model.curtainSeat != nil)
            .overlay {
                if let seat = model.curtainSeat {
                    PassCurtainView(name: model.seatNames[seat], portrait: portraits[seat]) {
                        withAnimation(motion(Theme.Motion.overlay)) { model.ready() }
                    }
                    .transition(.opacity)
                }
            }
            .overlay {
                if drawShown, let draw = model.dealerDraw {
                    DealerDrawView(draw: draw, names: model.seatNames, portraits: portraits, saysYou: model.mode == .solo) {
                        withAnimation(motion(Theme.Motion.overlay)) { model.dismissDealerDraw() }
                    }
                    .transition(.opacity)
                }
            }
            // The one bid that can end the match on its own: the partner asks, then the engine judges it at that moment (D70).
            .overlay {
                if confirmNineAndOut {
                    NineAndOutConfirm(name: NineAndOutConfirm.partnerName(model), portrait: portraits[model.partnerSeat],
                                      onSure: { confirmNineAndOut = false; model.send(.nineAndOut) },
                                      onCancel: { withAnimation(motion(Theme.Motion.overlay)) { confirmNineAndOut = false } })
                        .transition(.opacity)
                }
            }
            .overlay { teamPanel }
            .overlay { celebration }
            .transformEnvironment(\.dynamicTypeSize) { $0 = $0.boosted(by: Theme.textBoostSteps) }
            .onAppear {
                // The screenshot stages open on a match already won, so nothing announced the win.
                if ["won", "ninewin", "ninelose"].contains(ScreenshotStage.name ?? "") { celebrating = model.celebrations }
                if ScreenshotStage.name == "confirm9" { confirmNineAndOut = true }
                if ScreenshotStage.name == "panel" { scorePanel = model.ourTeam }
            }
    }

    /// The next celebration step over the table, each moving on by itself or at a tap (D69).
    @ViewBuilder private var celebration: some View {
        switch celebrating.first {
        case .cascade:
            CardCascade()
                .transition(.opacity)
                .task {
                    cascades += 1
                    try? await Task.sleep(for: .seconds(Celebration.cascadeSeconds))
                    guard !Task.isCancelled else { return }
                    nextCelebration()
                }
        case let .nineAndOut(result):
            NineAndOutScreen(result: result, bidderName: model.seatNames[result.bidder], onDone: nextCelebration)
                .transition(.opacity)
                .task {
                    try? await Task.sleep(for: .seconds(Celebration.nineSeconds))
                    guard !Task.isCancelled else { return }
                    nextCelebration()
                }
        case nil:
            EmptyView()
        }
    }

    /// One team's score panel, risen from its rail's foot (N62).
    @ViewBuilder private var teamPanel: some View {
        if let team = scorePanel {
            ScorePanel(content: ScorePanel.content(team: team, history: model.match.history, seatNames: model.seatNames),
                       label: railLabel(team), names: model.teamNames(team),
                       onClose: { withAnimation(motion(Theme.Motion.overlay)) { scorePanel = nil } })
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func nextCelebration() {
        guard !celebrating.isEmpty else { return }
        withAnimation(motion(Theme.Motion.overlay)) { _ = celebrating.removeFirst() }
    }

    private var portraits: [Portrait] {
        [model.settings.playerPortrait] + Cast.opponents.map(\.portrait)
    }

    /// Score bar, table and hand in one non-scrolling column.
    private var layout: some View {
        VStack(spacing: 6) {
            // The score sits at the foot of the rails (N62); the rest of the header stays empty.
            ScoreBarView(onPause: onLeave)
                .padding(.horizontal, 16).padding(.top, 2).padding(.bottom, 8)
                // A solid header band: runs up behind the status bar and ends in a frown, the corners
                // hanging lower than the middle, so the pause button sits on one colour and the wood starts beneath.
                .background {
                    WoodGrainView(vignette: .linear)
                        .clipShape(HeaderBandShape(dip: Theme.Table.headerDip))
                        .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
                        .ignoresSafeArea(edges: .top)
                }
            TableSurface(model: model, namespace: cards, collapsedTricks: collapsedTricks, reopenedTrick: reopenedTrick, toast: toast,
                         onReopenTrick: { withAnimation(motion(Theme.Motion.collapse)) { reopenedTrick = model.match.hand.completedTricks.count } },
                         onCloseTrick: { withAnimation(motion(Theme.Motion.collapse)) { reopenedTrick = nil } },
                         onNineAndOut: { withAnimation(motion(Theme.Motion.overlay)) { confirmNineAndOut = true } },
                         onDeck: { dealerDeck = $0 },
                         onSideSeats: { sideSeatsBottom = $0 },
                         holdsResult: !celebrating.isEmpty,
                         statusFocus: $statusFocused)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
            // Cards stop growing at XXXL so the fan keeps six cards on screen; the cap must sit above the
            // fan's own scaled metrics, which read it from the environment.
            HandFanView(model: model, namespace: cards, onIllegal: shake, shakes: $shakes,
                        deck: dealerDeck, onDeck: { dealerDeck = $0 })
                .dynamicTypeSize(...Theme.Card.maximumTypeSize)
                .padding(.horizontal, 16)
        }
        // The shuffle sits over the dealer's deck, in the same space the deck reports its place in.
        .overlay(alignment: .topLeading) {
            if shuffles > 0, let dealerDeck {
                RiffleShuffle().id(shuffles).position(dealerDeck)
            }
        }
        // The score rails run down both edges, in the margin beside the hand, from below the side seats (N59), each
        // ending in its team's score in a bottom corner (N62).
        .overlay(alignment: .topLeading) { scoreRails }
        .coordinateSpace(.named(TableLayout.space))
        .dynamicTypeSize(...Theme.maximumTableTypeSize)
        .padding(.bottom, 6)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.ivory)
        .background(WoodGrainView().ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    /// Your team's rail on the left, the other team's on the right, each showing the score as the last hand left it.
    /// Only the scores at their feet take taps.
    private var scoreRails: some View {
        let scores = ScoreRail.shown(in: model.match)
        let top = sideSeatsBottom + Theme.Table.railGap
        return GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                rail(team: model.ourTeam, scores: scores, leading: true)
                Spacer(minLength: 0)
                rail(team: 1 - model.ourTeam, scores: scores, leading: false)
            }
            .padding(.horizontal, Theme.Table.railInset)
            .frame(width: geometry.size.width, height: max(0, geometry.size.height - top))
            .offset(y: top)
        }
        .opacity(sideSeatsBottom > 0 ? 1 : 0)
        .allowsHitTesting(sideSeatsBottom > 0)
    }

    private func rail(team: Int, scores: [Int], leading: Bool) -> some View {
        ScoreRail(score: scores[team], label: railLabel(team), leading: leading) {
            withAnimation(motion(Theme.Motion.overlay)) { scorePanel = team }
        }
    }

    /// US or THEM in solo, the pair's names in pass and play.
    private func railLabel(_ team: Int) -> String {
        ScoreRail.label(us: team == model.ourTeam, mode: model.mode, teamNames: model.teamNames(team))
    }

    /// One animation for the whole table per accepted action, so cards fly between hand and pile in one
    /// transaction; the scheduler task holds finished tricks and lets computers act.
    private var withScheduling: some View {
        layout
            .animation(motion(Theme.Motion.flight), value: model.revision)
            .task(id: SchedulerKey(revision: model.revision, paused: pause.isPaused)) { await advance() }
            .onChange(of: model.match.handNumber) { _, _ in collapsedTricks = 0; reopenedTrick = nil }
            .onChange(of: model.revision) { _, revision in
                withAnimation(motion(Theme.Motion.collapse)) { reopenedTrick = nil }
                if RiffleShuffle.startsHand(model.match.hand) { shuffles += 1 }
                noteChanges(revision)
            }
            .onChange(of: model.lastHumanAction) { _, action in toast = action }
            // Focus follows the game: a lifted cover or a new turn puts VoiceOver on the status line.
            .onChange(of: covered) { _, now in if !now { statusFocused = true } }
            .onChange(of: pause.sheetShown) { _, now in if !now { statusFocused = true } }
            .onChange(of: pause.dialogShown) { _, now in if !now { statusFocused = true } }
            .onChange(of: model.isHumanTurn) { _, now in if now { statusFocused = true } }
            .task(id: toast) {
                guard toast != nil else { return }
                try? await Task.sleep(for: .seconds(Theme.Motion.toastSeconds))
                guard !Task.isCancelled else { return }
                withAnimation(motion(Theme.Motion.overlay)) { toast = nil }
            }
            // The bold note says its piece once and fades; the `bold` screenshot stage holds it.
            .task(id: model.boldNote) {
                guard model.boldNote != nil, ScreenshotStage.name != "bold" else { return }
                try? await Task.sleep(for: .seconds(Theme.Motion.boldNoteSeconds))
                guard !Task.isCancelled else { return }
                withAnimation(motion(Theme.Motion.overlay)) { model.clearBoldNote() }
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active { model.persist() } }
            // The first time trump is named on this install, once nothing covers the table, it shows its two taps (N61).
            // Screenshot stages leave it out, except `demo`, which holds its first caption.
            .task(id: DemoKey(trumpNamed: model.match.hand.trump != nil, paused: pause.isPaused || model.curtainSeat != nil)) {
                guard ScreenshotStage.name == nil || ScreenshotStage.name == "demo", !pause.isPaused, model.curtainSeat == nil else { return }
                withAnimation(motion(Theme.Motion.overlay)) { model.beginTallyDemoIfDue() }
            }
            .task(id: model.tallyDemo) {
                guard model.tallyDemo != nil, ScreenshotStage.name != "demo" else { return }
                try? await Task.sleep(for: .seconds(TallyDemo.stepSeconds))
                guard !Task.isCancelled else { return }
                withAnimation(motion(Theme.Motion.overlay)) { model.advanceTallyDemo() }
            }
    }

    /// Two haptics only: the refusal buzz, and one outcome cue per accepted action (`TableFeedback`).
    private var withHaptics: some View {
        withScheduling
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.4), trigger: shakeCount) { _, _ in model.settings.haptics }
            .sensoryFeedback(cue?.cue.feedback ?? .selection, trigger: cue?.id ?? 0) { _, _ in model.settings.haptics && cue != nil }
            .sensoryFeedback(.success, trigger: cascades) { _, _ in model.settings.haptics }
    }

    /// After each accepted action, work out what it did and pick the one cue and announcement for it.
    private func noteChanges(_ revision: Int) {
        let now = TableFeedback.Snapshot(model)
        if let picked = TableFeedback.cue(from: seen, to: now) { cue = (revision, picked) }
        if now.winner != nil, seen.winner == nil { celebrating = model.celebrations }
        let handEnded = now.hands > seen.hands
        if now.tricks > seen.tricks, !handEnded, let winner = now.lastTrickWinner {
            AccessibilityNotification.Announcement("\(model.seatNames[winner]) took the hand").post()
        } else if handEnded, let outcome = model.lastHandOutcome {
            AccessibilityNotification.Announcement("\(outcome.headline). \(outcome.bidderLine)").post()
        }
        seen = now
    }

    private var withSheets: some View {
        withHaptics
            .sheet(isPresented: $showSettings) { SettingsView(settings: $model.settings) }
            .sheet(isPresented: $showTutorial, onDismiss: { model.markRulesSeen() }) { TutorialView(model: tutorial) { showTutorial = false } }
            .sheet(isPresented: $showStatistics) { StatisticsView(stats: model.statistics, records: model.records) { showStatistics = false } }
            .alert("Game notice", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
                Button("OK") { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
            // The buttons clear the error themselves; dismissal must not, or a failed Retry would go quiet.
            .alert("Could not save", isPresented: Binding(get: { model.saveError != nil }, set: { _ in })) {
                Button("Retry") { model.retrySave() }
                Button("Not now", role: .cancel) { model.saveError = nil }
            } message: { Text(model.saveError ?? "") }
            // An alert, not a confirmation dialog: iOS 26 anchors the dialog to its button as a popover and drops
            // the Cancel button, so only an alert keeps the explicit way out on every system (D57).
            .alert("Start over?", isPresented: $confirmNewGame) {
                Button("Solo", role: .destructive) { model.newGame(mode: .solo) }
                Button("Pass and play", role: .destructive) { model.newGame(mode: .passAndPlay) }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This replaces your saved game. " + PlayMode.choiceMessage) }
    }

    private func motion(_ animation: Animation) -> Animation { reduceMotion ? Theme.Motion.reduced : animation }



    /// A finished trick is worth a medium tap when our side took it, a light one otherwise.

    private func shake(_ card: Card) {
        shakes[card, default: 0] += 1
        shakeCount += 1
        model.refuse(.play(card))
    }

    /// After every accepted action: hold a finished trick, collapse it, then let the next computer act.
    private func advance() async {
        guard !pause.isPaused else { return }
        let hand = model.match.hand
        if collapsedTricks > hand.completedTricks.count { collapsedTricks = hand.completedTricks.count }
        let step = TableScheduler.plan(hand: hand, collapsedTricks: collapsedTricks)
        if step.hold {
            try? await Task.sleep(for: model.settings.trickHold)
            guard !Task.isCancelled else { return }
            withAnimation(motion(Theme.Motion.collapse)) { collapsedTricks = hand.completedTricks.count }
        }
        if step.dealing {
            try? await Task.sleep(for: Theme.Motion.dealHold)
            guard !Task.isCancelled else { return }
        }
        guard !model.isHumanTurn, hand.nextSeat != nil, model.match.winner == nil else { return }
        try? await Task.sleep(for: model.settings.delay(leadingTrick: step.leading))
        guard !Task.isCancelled else { return }
        model.stepComputer()
    }

}

enum TableScheduler {
    /// Whether a finished trick still needs its hold before collapsing, whether the coming computer
    /// play is a lead (which gets the longer pause) rather than a follow, and whether the hand has
    /// just been refilled after trump (so the deal animation gets its own pause first).
    static func plan(hand: Hand, collapsedTricks: Int) -> (hold: Bool, leading: Bool, dealing: Bool) {
        let hold = hand.phase == .playing && hand.currentTrick.isEmpty && hand.completedTricks.count > collapsedTricks
        let dealing = hand.phase == .playing && hand.currentTrick.isEmpty && hand.completedTricks.isEmpty
        return (hold, hand.currentTrick.isEmpty && !hold, dealing)
    }
}

/// The header band: square at the top, and along the bottom a frown, an arc whose ends hang `dip`
/// points lower than its middle.
struct HeaderBandShape: Shape {
    var dip: Double
    var animatableData: Double { get { dip } set { dip = newValue } }
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // A quadratic curve peaks halfway between its ends and its control point.
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                          control: CGPoint(x: rect.midX, y: rect.maxY - 2 * dip))
        path.closeSubpath()
        return path
    }
}
