import CatchFive
@testable import CatchFiveUI
import Foundation
import Testing

@Test func rulesSheetEndsWithTheFamilysNoteAndAMailLink() throws {
    #expect(RulesText.signOff == "We're honored you took a seat at our table. This game has been part of my family for generations. Always will be. The rules stay as they are, but if you have ideas for the app, email me. I'd love to hear them.")
    #expect(RulesText.contactEmail == "cmurphy1140@gmail.com")
    let url = RulesText.contactURL
    #expect(url.absoluteString == "mailto:cmurphy1140@gmail.com?subject=Catch%205")
    let parts = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    #expect(parts.scheme == "mailto")
    #expect(parts.path == "cmurphy1140@gmail.com")
    #expect(parts.queryItems == [URLQueryItem(name: "subject", value: "Catch 5")])
    // Not a rule: the verbatim check against the rules document never sees it.
    #expect(!RulesText.allText.contains(RulesText.signOff))
}
