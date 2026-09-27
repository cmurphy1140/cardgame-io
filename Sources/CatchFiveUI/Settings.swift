import CatchFive
import Foundation

/// Player preferences. They live outside the rules engine; the table and view model read them.
public struct Settings: Codable, Equatable, Sendable {
    public enum PlaySpeed: String, Codable, CaseIterable, Sendable {
        case relaxed, normal, quick
    }

    public var playSpeed: PlaySpeed
    /// Seat 0 is the human; all four default to the family table (T09).
    public var seatNames: [String]
    public var haptics: Bool
    public var difficulty: Difficulty
    /// The tutorial opens by itself until the player has dismissed it once.
    public var hasSeenRules: Bool
    /// Tutorial lessons (0 to 4) whose exercise has been solved.
    public var completedLessons: Set<Int>
    /// Nil until the login screen has been completed once.
    public var playerName: String?
    /// The face the human chose at login.
    public var playerPortrait: Portrait
    /// Hints and guided play (spec R14). Off is normal mode: a clean table, no coaching, the same rules.
    public var beginnerMode: Bool

    public static let defaultSeatNames = ["Cheryl", "JC", "Connor", "Diane"]
    /// The defaults before the cast existed; files still carrying them migrate on load.
    public static let legacySeatNames = ["You", "West", "Partner", "East"]

    public var hasSignedIn: Bool { playerName != nil }

    /// The one place the player's name is written: trimmed, and mirrored into seat 0. Blank input is ignored.
    public mutating func setPlayerName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        playerName = trimmed
        seatNames[0] = trimmed
    }

    public init(playSpeed: PlaySpeed = .relaxed, seatNames: [String] = Settings.defaultSeatNames,
                haptics: Bool = true, difficulty: Difficulty = .standard, hasSeenRules: Bool = false,
                completedLessons: Set<Int> = [], playerName: String? = nil,
                playerPortrait: Portrait = Cast.defaultPlayerPortrait, beginnerMode: Bool = true) {
        self.playSpeed = playSpeed
        self.seatNames = seatNames
        self.haptics = haptics
        self.difficulty = difficulty
        self.hasSeenRules = hasSeenRules
        self.completedLessons = completedLessons
        self.playerName = playerName
        self.playerPortrait = playerPortrait
        self.beginnerMode = beginnerMode
    }

    // Missing keys fall back to defaults so an older settings file keeps loading.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // A value this build does not recognise (a newer build's enum case) falls back to its default rather
        // than throwing the whole file away, which would sign the player out.
        playSpeed = (try? container.decodeIfPresent(PlaySpeed.self, forKey: .playSpeed)) ?? nil ?? .relaxed
        haptics = (try? container.decodeIfPresent(Bool.self, forKey: .haptics)) ?? nil ?? true
        difficulty = (try? container.decodeIfPresent(Difficulty.self, forKey: .difficulty)) ?? nil ?? .standard
        hasSeenRules = (try? container.decodeIfPresent(Bool.self, forKey: .hasSeenRules)) ?? nil ?? false
        completedLessons = (try? container.decodeIfPresent(Set<Int>.self, forKey: .completedLessons)) ?? nil ?? []
        playerName = (try? container.decodeIfPresent(String.self, forKey: .playerName)) ?? nil
        playerPortrait = (try? container.decodeIfPresent(Portrait.self, forKey: .playerPortrait)) ?? nil ?? Cast.defaultPlayerPortrait
        // A file from before the setting existed keeps the guidance it always had.
        beginnerMode = (try? container.decodeIfPresent(Bool.self, forKey: .beginnerMode)) ?? nil ?? true
        let names = (try? container.decodeIfPresent([String].self, forKey: .seatNames)) ?? nil ?? Settings.defaultSeatNames
        // Only a file from before the cast (no player name yet) still carries the direction defaults by
        // accident; after sign-in a typed "West" is a choice and stays.
        let migrated = playerName == nil ? Settings.migrated(names) : names
        seatNames = migrated.count == 4 ? migrated : Settings.defaultSeatNames
    }

    /// Seats 1 to 3 that still carry the old direction names take the cast's names; custom names are kept.
    static func migrated(_ names: [String]) -> [String] {
        var result = names
        for seat in 1...3 where names[seat] == legacySeatNames[seat] {
            result[seat] = defaultSeatNames[seat]
        }
        return result
    }

    /// How long a finished hand stays on the table, winner ringed, before it is collected: one beat,
    /// `Theme.Motion.botBeat`, so every hand can be read. The saved pace no longer changes it (T11).
    public var trickHold: Duration { Theme.Motion.botBeat }

    /// Pause before a computer acts: the same single beat for leads and follows (T11).
    public func delay(leadingTrick: Bool) -> Duration { Theme.Motion.botBeat }
}

public enum SettingsStore {
    public static func read(from url: URL) throws -> Settings {
        try JSONDecoder().decode(Settings.self, from: Data(contentsOf: url))
    }

    public static func write(_ settings: Settings, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        try encoder.encode(settings).write(to: url, options: .atomic)
    }
}
