import CatchFive
@testable import CatchFiveUI
import Foundation
import Testing

@MainActor @Test func theTableBarHasTableAndClarifyWithTheirDropDowns() {
    // N68: one skinny bar, two boxes; Table pauses, starts over or goes home, Clarify answers what's on the table.
    #expect(TableBar.Box.allCases.map(\.title) == ["Table", "Clarify"])
    #expect(TableBar.TableItem.allCases.map(\.title) == ["Pause", "New game", "Home"])
    #expect(TableBar.newGameChoices.map(\.title) == ["Solo", "Pass and play"])
    #expect(TableBar.newGameChoices.map(\.mode) == [.solo, .passAndPlay])
    #expect(TableBar.answers.map(\.topic) == ["The bid box", "The scorecard", "Tap the suit", "Tap a face"])
    #expect(TableBar.answers.allSatisfy { !$0.text.isEmpty })
    #expect(TableBar.howToPlay == "How to play")
    // Play waits while a drop-down is open.
    #expect(TablePause(menuShown: true).isPaused)
    #expect(!TablePause().isPaused)
    // The pause card says the game keeps its place.
    #expect(WelcomeCard.keepsPlace == "You can leave the app and come back to this exact spot.")
}
