import CatchFive
@testable import CatchFiveUI
import Foundation
import Testing

@Test func rulesSheetOpensWithWhereTheGameComesFrom() {
    #expect(RulesText.origin == "A New England variant of Pitch, passed down through generations. We hope you enjoy it as much as we do.")
}

@Test func tipCardOpensWithTheOriginThenElevenTipsInOrder() {
    #expect(TipDeck.origin == TipDeck.Face(label: "WHERE IT COMES FROM", text: RulesText.origin))
    #expect(TipDeck.tips.count == 11)
    #expect(TipDeck.tips.first == "The five of trump is worth 5 of the 9 points. Protect yours, and hunt theirs.")
    #expect(TipDeck.tips[5] == "If everyone passes, the dealer has to bid 2.")
    #expect(TipDeck.tips.last == "No Wi-Fi needed. On a plane? Read a book, or play our game.")
    #expect(TipDeck.tip(0) == TipDeck.Face(label: "TIP 1 OF 11", text: TipDeck.tips[0]))
    #expect(TipDeck.tip(10).label == "TIP 11 OF 11")
    // A stored index past the end, or a hand-edited negative one, still lands on a real tip.
    #expect(TipDeck.tip(11) == TipDeck.tip(0))
    #expect(TipDeck.tip(-1) == TipDeck.tip(10))
}

@MainActor @Test func tipsContinueFromTheLastVisitAcrossLaunchesAndWrap() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let model = GameModel(match: try Match(deck: GameModel.deck(), dealer: 3), settingsURL: url)
    #expect(model.settings.nextTip == 0)
    #expect(model.takeNextTip().label == "TIP 1 OF 11")
    #expect(model.takeNextTip().label == "TIP 2 OF 11")
    // The next index is saved with the settings, so the next launch picks up at tip 3.
    let reloaded = GameModel(match: try Match(deck: GameModel.deck(), dealer: 3), settings: try SettingsStore.read(from: url), settingsURL: url)
    #expect(reloaded.takeNextTip().label == "TIP 3 OF 11")
    for _ in 3..<11 { _ = reloaded.takeNextTip() }
    #expect(reloaded.takeNextTip().label == "TIP 1 OF 11")
    // A settings file from before the tip card starts at the first tip.
    let old = try JSONDecoder().decode(Settings.self, from: Data(#"{"haptics": false}"#.utf8))
    #expect(old.nextTip == 0)
}

@Test func homeOffersBackToTheTableOnlyWithAMatchInProgress() {
    #expect(MainMenuView.homeButtons(matchInProgress: true) == [
        .init(title: "Back to the table", prominent: true, action: .backToTable),
        .init(title: "Deal me in", prominent: false, action: .dealMeIn),
    ])
    #expect(MainMenuView.homeButtons(matchInProgress: false) == [
        .init(title: "Deal me in", prominent: true, action: .dealMeIn),
    ])
}

@MainActor @Test func theShuffleRunsOnceAtTheStartOfEachHandAndHoldsNothingUp() throws {
    let model = GameModel(match: try Match(deck: GameModel.deck(), dealer: 3))
    #expect(RiffleShuffle.startsHand(model.match.hand))
    model.send(.bid(nil))
    #expect(!RiffleShuffle.startsHand(model.match.hand))
    for _ in 0..<400 where model.match.hand.phase != .finished {
        if model.isHumanTurn { model.showHint(); model.send(try #require(model.hint).action) } else { model.stepComputer() }
    }
    model.nextHand()
    #expect(RiffleShuffle.startsHand(model.match.hand))
    // A quick riffle, and nothing the scheduler waits for: no pause reason exists for it.
    #expect(RiffleShuffle.seconds <= 0.6)
    #expect(!TablePause(sceneActive: true, welcomeShown: false, sheetShown: false, dialogShown: false,
                        inspectingTrick: false, drawShown: false).isPaused)
}
