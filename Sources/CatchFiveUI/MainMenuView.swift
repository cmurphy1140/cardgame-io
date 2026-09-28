import CatchFive
import SwiftUI

/// The main menu (spec R31): who is playing, where the saved match stands, and every destination that is
/// not the table itself. Back to the table leads back to the match untouched; Deal me in starts a new one,
/// after a word of warning if it would replace one (D67); How to play opens the lessons. Settings, Statistics and the build explainer wait in a
/// hamburger menu in the top-right corner, one tap from here in every mode (spec R29), as a bare glyph
/// with no plate (spec R19).
struct MainMenuView: View {
    @ObservedObject var model: GameModel
    @ObservedObject var tutorial: TutorialModel
    /// Back to the table or a fresh deal: the tip card, then the table.
    let onPlay: () -> Void
    /// Opens with the Solo or Pass and play question already up (the screenshot launch stage).
    var choosingMode = false
    @State private var confirmNewMatch = false
    @State private var showSettings = false
    @State private var showTutorial = false
    @State private var showStatistics = false
    @State private var showExplainer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Catch 5")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                    Text("A FAMILY CARD GAME")
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .tracking(2)
                        .opacity(0.82)
                }
                .padding(.top, 34)

                // The five is the visual signature of the game, not another control.
                HomeFiveCard()
                    .rotationEffect(.degrees(-5))
                    .padding(.vertical, 4)
                    .accessibilityHidden(true)

                HStack(spacing: 14) {
                    PortraitView(portrait: model.settings.playerPortrait, size: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.settings.playerName ?? "friend")
                            .font(.system(.title3, design: .serif).weight(.semibold)).lineLimit(1)
                        Text(model.settings.difficulty == .easy ? "Easy opponents" : "Standard opponents")
                            .font(.footnote).opacity(0.75)
                        if let context = model.resumeContext {
                            Text(context).font(.footnote).opacity(0.75)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(Theme.Wood.inlay.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.ivory.opacity(0.14)))
                .accessibilityElement(children: .combine)

                VStack(spacing: 10) {
                    // Deal me in always asks Solo or Pass and play; the same question warns when a match is in progress.
                    ForEach(Self.homeButtons(matchInProgress: model.matchInProgress), id: \.title) { button in
                        let action = button.action == .backToTable ? onPlay : { confirmNewMatch = true }
                        if button.prominent { MenuButtons.prominent(button.title, action: action) }
                        else { MenuButtons.plain(button.title, action: action) }
                    }
                    MenuButtons.plain("How to play") { showTutorial = true }
                }
            }
            .padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
        }
        .overlay(alignment: .topTrailing) {
            Menu {
                Button("Settings", systemImage: "gearshape") { showSettings = true }
                Button("Statistics", systemImage: "chart.bar") { showStatistics = true }
                Button("How Catch 5 is built", systemImage: "doc.text.magnifyingglass") { showExplainer = true }
            } label: {
                Image(systemName: "line.3.horizontal").font(.title2.weight(.medium))
                    .shadow(color: .black.opacity(0.45), radius: 1.5, y: 1)
                    .frame(width: Theme.Table.statusButtonHitSize, height: Theme.Table.statusButtonHitSize)
                    .contentShape(Rectangle())
            }
            .tint(.ivory)
            .accessibilityLabel("Menu")
            .padding(.trailing, 12).padding(.top, 4)
        }
        .foregroundStyle(.ivory)
        .background(WoodGrainView().ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) { SettingsView(settings: $model.settings) }
        .sheet(isPresented: $showTutorial, onDismiss: { model.markRulesSeen() }) { TutorialView(model: tutorial) { showTutorial = false } }
        .sheet(isPresented: $showStatistics) { StatisticsView(stats: model.statistics, records: model.records) { showStatistics = false } }
        .fullScreenCoverOrSheet(isPresented: $showExplainer) { ExplainerView { showExplainer = false } }
        // An alert, not a confirmation dialog: iOS 26 anchors the dialog to its button as a popover and drops
        // the Cancel button, so only an alert keeps the explicit way out on every system (D57).
        .alert(model.matchInProgress ? "Start over?" : "New match", isPresented: $confirmNewMatch) {
            Button("Solo", role: model.matchInProgress ? .destructive : nil) { model.newGame(mode: .solo); onPlay() }
            Button("Pass and play", role: model.matchInProgress ? .destructive : nil) { model.newGame(mode: .passAndPlay); onPlay() }
            Button("Cancel", role: .cancel) {}
        } message: { Text((model.matchInProgress ? "This replaces your saved game. " : "") + PlayMode.choiceMessage) }
        .onAppear {
            if choosingMode { confirmNewMatch = true }
            switch ScreenshotStage.name {
            case "stats": showStatistics = true
            case "settings": showSettings = true
            case "howto", "rules", "signoff": showTutorial = true
            default: break
            }
        }
    }
}


extension MainMenuView {
    struct HomeButton: Equatable {
        enum Action { case backToTable, dealMeIn }
        let title: String
        let prominent: Bool
        let action: Action
    }

    /// The home screen's play buttons (D67): with a match in progress, Back to the table in the prominent style
    /// and Deal me in plain; otherwise Deal me in alone, prominent. Deal me in keeps New match's alert and mode picker.
    nonisolated static func homeButtons(matchInProgress: Bool) -> [HomeButton] {
        matchInProgress
            ? [HomeButton(title: "Back to the table", prominent: true, action: .backToTable),
               HomeButton(title: "Deal me in", prominent: false, action: .dealMeIn)]
            : [HomeButton(title: "Deal me in", prominent: true, action: .dealMeIn)]
    }
}

/// The home-screen signature card: a real five-of-hearts pip layout, larger than gameplay cards. It sways
/// slowly and turns over to its back about every nine seconds (D67); under Reduce Motion it holds still.
private struct HomeFiveCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swayed = false
    @State private var angle = 0.0
    @State private var showsBack = false

    var body: some View {
        Group {
            if showsBack { CardBackView(width: 112).frame(width: 112, height: 168) } else { face }
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .rotationEffect(.degrees(swayed ? 2 : -2))
        .offset(y: swayed ? -4 : 0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { swayed = true }
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(9))
                guard !Task.isCancelled else { return }
                await turn()
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                await turn()
            }
        }
    }

    /// Turns the card over about its vertical axis, swapping face and back edge-on.
    private func turn() async {
        withAnimation(.easeIn(duration: 0.3)) { angle = 90 }
        try? await Task.sleep(for: .milliseconds(300))
        showsBack.toggle()
        angle = -90
        withAnimation(.easeOut(duration: 0.3)) { angle = 0 }
    }

    private var face: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ivory)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.black.opacity(0.18)))
                .shadow(color: .black.opacity(0.35), radius: 5, y: 4)
            VStack {
                HStack { heart; Spacer(); heart }
                Spacer()
                heart
                Spacer()
                HStack { heart; Spacer(); heart }
            }
            .padding(.horizontal, 23).padding(.vertical, 24)
            VStack(spacing: -4) {
                Text("5").font(.system(size: 27, weight: .bold, design: .serif))
                Text("♥").font(.system(size: 20))
            }
            .foregroundStyle(Color.suitRed)
            .padding(.top, 8).padding(.leading, 9)
        }
        .frame(width: 112, height: 168)
    }
    private var heart: some View {
        Text("♥").font(.system(size: 27)).foregroundStyle(Color.suitRed)
    }
}
