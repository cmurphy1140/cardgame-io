import CatchFive
@testable import CatchFiveUI
import Foundation
import Testing

@Test func rulesSheetOpensWithWhereTheGameComesFrom() {
    #expect(RulesText.origin == "A New England variant of Pitch, passed down through generations. We hope you enjoy it as much as we do.")
}
