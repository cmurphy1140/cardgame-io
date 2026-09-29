import Foundation

public enum SaveError: Error, Equatable {
    case invalidData, unsupportedVersion(Int)
}

enum SavedAction: Codable, Sendable {
    case nineAndOut(seat: Int)
    case bid(seat: Int, amount: Int?)
    case trump(seat: Int, suit: Suit)
    case play(seat: Int, card: Card)
    case nextHand(deck: [Card])

    func apply(to match: inout Match) throws {
        switch self {
        case let .nineAndOut(seat): try match.bidNineAndOut(seat: seat)
        case let .bid(seat, amount): try match.bid(seat: seat, amount: amount)
        case let .trump(seat, suit): try match.chooseTrump(seat: seat, suit: suit)
        case let .play(seat, card): try match.play(seat: seat, card: card)
        case let .nextHand(deck): try match.startNextHand(deck: deck)
        }
    }
}

private struct Archive: Codable {
    let version: Int
    let initialDeck: [Card]
    let initialDealer: Int
    let actions: [SavedAction]
}

/// Versioned local saves. Replay validates actions through the ordinary rules.
public enum MatchSave {
    public static func encode(_ match: Match) throws -> Data {
        let archive = Archive(version: 2, initialDeck: match.initialDeck,
                              initialDealer: match.initialDealer, actions: match.actions)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(archive)
    }

    public static func decode(_ data: Data) throws -> Match {
        do {
            let archive = try JSONDecoder().decode(Archive.self, from: data)
            // Version 2 marks the trump opening lead (D91). Both replay under today's rules, so a version 1
            // game that opened without trump fails replay and is set aside like any unreadable save.
            guard [1, 2].contains(archive.version) else { throw SaveError.unsupportedVersion(archive.version) }
            return try Match.replaying(deck: archive.initialDeck, dealer: archive.initialDealer, actions: archive.actions)
        } catch let error as SaveError {
            throw error
        } catch {
            throw SaveError.invalidData
        }
    }

    /// Atomic replacement preserves the previous save if replacement cannot complete.
    public static func write(_ match: Match, to url: URL) throws {
        try encode(match).write(to: url, options: .atomic)
    }

    public static func read(from url: URL) throws -> Match {
        try decode(Data(contentsOf: url))
    }
}
