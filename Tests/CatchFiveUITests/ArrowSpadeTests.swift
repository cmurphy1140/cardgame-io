import CatchFive
@testable import CatchFiveUI
import Foundation
import SwiftUI
import Testing

@Test func homeIsACarvedBackArrowWithNoWord() {
    // D95: the house and the word are gone; a back arrow alone, still read as "Home" by VoiceOver, a full thumb tall.
    #expect(TableTopRow.home == TableTopRow.Button(title: "Home", symbol: "arrow.backward", showsTitle: false))
    #expect(!TableTopRow.home.showsTitle)
    #expect(TableTopRow.home.title == "Home")
    #expect(TableTopRow.rules.showsTitle)
    #expect(Theme.Table.topRowHeight >= 44)
}

@MainActor @Test func carvedSuitsAreCutConcaveLikeTheLetters() {
    // D95: a big suit is cut as deep as its size, so the upper edge's shadow and the lit lip still show on it,
    // and its floor catches more light than its top, the way a recess does; the floor still reads at 3:1.
    #expect(Carving.depth(size: Theme.Table.carvedNameSize) == 1)
    #expect(Carving.depth(size: Theme.Table.trumpLineSuitSize) > 1)
    #expect(Carving.depth(size: 10) == 1)
    for suit in Suit.allCases {
        #expect(Carving.contrast(Carving.floor(for: suit), on: Theme.Wood.base) >= 3)
        #expect(Carving.luminance(Carving.floor(for: suit), over: Theme.Wood.base)
                > Carving.luminance(Carving.ink(for: suit), over: Theme.Wood.base))
    }
    #expect(Carving.floor(for: .hearts) == Carving.floor(for: .diamonds))
    #expect(Carving.floor(for: .hearts) != Carving.floor(for: .spades))
}

@Test func theBidCornerSetsTheSuitAndTrumpOnOneLine() {
    // D95: "♠ Trump" together, the suit a little taller than the word so it still reads first, the tally under the line.
    #expect(ContractPlaque.trumpLine(.spades) == "♠ Trump")
    #expect(ContractPlaque.trumpLine(.hearts) == "♥ Trump")
    #expect(Theme.Table.trumpLineSuitSize > Theme.Table.trumpWordSize)
    #expect(Theme.Table.trumpLineSuitSize * 1.1 + Theme.Table.tallyHeight <= Theme.Table.bidBoxSuitSize * 1.15)
}
