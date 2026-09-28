/// Why the table may not let a computer act right now. Every input is UI state; none of it is an action,
/// so nothing here reaches the replay log. Stacked covers stay paused until the last one is gone.
struct TablePause: Equatable, Hashable {
    /// The scene is in the foreground and interactive.
    var sceneActive = true
    /// The returning player's welcome card is over the table.
    var welcomeShown = false
    /// Any sheet or panel: settings, tutorial, review, a team's score panel (N62), statistics.
    var sheetShown = false
    /// A confirmation dialog or an alert is up.
    var dialogShown = false
    /// The player reopened the last trick to look at it.
    var inspectingTrick = false
    /// The draw for dealer is on the table before the first hand.
    var drawShown = false
    /// The Table or Clarify drop-down is open under the bar (N68).
    var menuShown = false

    var isPaused: Bool { !sceneActive || welcomeShown || sheetShown || dialogShown || inspectingTrick || drawShown || menuShown }
}
