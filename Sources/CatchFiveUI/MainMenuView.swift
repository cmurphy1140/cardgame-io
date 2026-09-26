import CatchFive
import SwiftUI

/// The main menu (spec R31): who is playing, where the saved match stands, and every destination that is
/// not the table itself. Continue game leads back to the match untouched; New match replaces it after a
/// word of warning; How to play opens the lessons. Settings, Statistics and the build explainer wait in a
/// hamburger menu in the top-right corner, one tap from here in every mode (spec R29), as a bare glyph
/// with no plate (spec R19).
struct MainMenuView: View {
    @ObservedObject var model: GameModel
    @ObservedObject var tutorial: TutorialModel
    /// Continue or a fresh deal: the table takes over.
    let onPlay: () -> Void
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

                // One setting for guidance (spec R14): on adds hints and explanations, off is a clean table.
                Toggle(isOn: $model.settings.beginnerMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Beginner mode").font(.headline)
                        Text("Hints and guided play").font(.footnote).opacity(0.75)
                    }
                }
                .tint(Color.suitRed)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Theme.Wood.inlay.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.ivory.opacity(0.14)))

                VStack(spacing: 10) {
                    if model.match.winner == nil {
                        MenuButtons.prominent("Continue game", action: onPlay)
                        MenuButtons.plain("New match") {
                            if model.matchInProgress { confirmNewMatch = true } else { model.newGame(); onPlay() }
                        }
                    } else {
                        MenuButtons.prominent("New match") { model.newGame(); onPlay() }
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
        .alert("Start over?", isPresented: $confirmNewMatch) {
            Button("Start new match", role: .destructive) { model.newGame(); onPlay() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This replaces your saved game.") }
    }
}


/// The home-screen signature card: a real five-of-hearts pip layout, larger than gameplay cards.
private struct HomeFiveCard: View {
    var body: some View {
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
