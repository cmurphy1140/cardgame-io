import CatchFive
import SwiftUI

/// Owns the one `GameModel`. A new player sees login, then the tutorial as an intro they may skip, then the
/// table. A returning player lands on the main menu, Continue game one tap away; the table's menu opens a
/// pause card whose Main menu comes back here with the match preserved (spec R31, R32).
public struct RootView: View {
    enum Screen { case login, intro, menu, table }

    @StateObject private var model: GameModel
    @StateObject private var tutorial: TutorialModel
    @State private var screen: Screen
    /// The pause card over the table, opened from the table's menu.
    @State private var showWelcome = false
    /// The menu opens with the Solo or Pass and play question up (the `picker` launch stage).
    private let choosingMode: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    /// `stage` opens a named state directly, for headless screenshots: `picker` (the New match question),
    /// `curtain` (a fresh pass-and-play match waiting for its first player) or `seat` (that player's table);
    /// solo `bidding` (your bid), `table` (your play, cards on the pile) or `result` (the hand's result).
    public init(model: GameModel, stage: String? = nil) {
        if stage == "curtain" || stage == "seat" {
            model.newGame(mode: .passAndPlay)
            model.dismissDealerDraw()
            if stage == "seat" { model.ready() }
        }
        if stage == "bidding" || stage == "table" || stage == "result" {
            model.newGame(mode: .solo)
            model.dismissDealerDraw()
            Self.play(model) { hand, humanTurn in
                switch stage {
                case "bidding": humanTurn && hand.phase == .bidding
                case "table": humanTurn && hand.phase == .playing && !hand.currentTrick.isEmpty
                default: hand.phase == .finished
                }
            }
        }
        _model = StateObject(wrappedValue: model)
        _tutorial = StateObject(wrappedValue: model.makeTutorial())
        let screen: Screen = switch stage {
        case "picker": .menu
        case "curtain", "seat", "bidding", "table", "result": .table
        default: Self.initialScreen(for: model.settings)
        }
        _screen = State(initialValue: screen)
        choosingMode = stage == "picker"
    }

    /// Plays every seat with the computer strategy until `stop` holds, for the screenshot stages only.
    private static func play(_ model: GameModel, until stop: (Hand, Bool) -> Bool) {
        for _ in 0..<200 where !stop(model.match.hand, model.isHumanTurn) && model.match.hand.phase != .finished {
            if model.isHumanTurn, let view = try? PlayerView(match: model.match, seat: 0),
               let action = ComputerPlayer.decide(view, difficulty: .standard) {
                model.send(action)
            } else {
                model.stepComputer()
            }
        }
    }

    /// Login until a name is saved; the intro until it has been seen or skipped; then the main menu, never
    /// a popup over the table (spec R32).
    nonisolated static func initialScreen(for settings: Settings) -> Screen {
        if !settings.hasSignedIn { return .login }
        return settings.hasSeenRules ? .menu : .intro
    }

    enum Destination: Equatable { case menu, intro, table }

    /// Where New match on the sign-in screen leads. An older install that already has a match in progress
    /// keeps it and gets the main menu, so nothing is thrown away without a choice.
    nonisolated static func destinationAfterSignIn(matchInProgress: Bool, hasSeenRules: Bool) -> Destination {
        if matchInProgress { return .menu }
        return hasSeenRules ? .table : .intro
    }

    public var body: some View {
        ZStack {
            LinearGradient(colors: [.felt, .black], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            switch screen {
            case .login:
                LoginView(model: model) { startFirstMatch() }.transition(.opacity)
            case .intro:
                IntroView(model: model, tutorial: tutorial) { model.markRulesSeen(); show(.table) }.transition(.opacity)
            case .menu:
                MainMenuView(model: model, tutorial: tutorial, onPlay: { showWelcome = false; show(.table) }, choosingMode: choosingMode)
                    .transition(.opacity)
            case .table:
                TableView(model: model, tutorial: tutorial, covered: showWelcome) { withAnimation(motion) { showWelcome = true } }
                    .transition(.opacity)
                    // Under the card the table is neither tappable nor reachable by VoiceOver.
                    .accessibilityHidden(showWelcome)
                    .overlay {
                        if showWelcome {
                            ZStack {
                                Color.black.opacity(contrast == .increased ? 0.75 : 0.55).ignoresSafeArea()
                                WelcomeCard(model: model, onPlay: { withAnimation(motion) { showWelcome = false } },
                                            onMenu: { showWelcome = false; show(.menu) })
                            }
                            .transition(.opacity)
                            .accessibilityAddTraits(.isModal)
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
        // The table has its own notice alert; the sign-in and intro screens need one for restore notices.
        .alert("Game notice", isPresented: Binding(get: { screen != .table && model.errorMessage != nil },
                                                  set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    private var motion: Animation { reduceMotion ? Theme.Motion.reduced : Theme.Motion.overlay }

    /// After sign-in: a finished leftover match is replaced; one in progress is kept behind the welcome
    /// card; otherwise the intro, or the table if the rules were already seen.
    private func startFirstMatch() {
        if model.match.winner != nil { model.newGame() }
        switch Self.destinationAfterSignIn(matchInProgress: model.matchInProgress, hasSeenRules: model.settings.hasSeenRules) {
        case .menu: showWelcome = false; show(.menu)
        case .intro: showWelcome = false; show(.intro)
        case .table: showWelcome = false; show(.table)
        }
    }

    private func show(_ next: Screen) {
        withAnimation(motion) { screen = next }
    }
}
