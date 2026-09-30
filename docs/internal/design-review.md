# Increment 1: Table Menu Affordance Before/After

## Before
The table's `ScoreBarView` featured a `gearshape` icon that opened a generic SwiftUI `Menu` with six actions:
- Pause game
- Undo last action
- Settings
- Statistics
- How to play
- Start a new game

This caused a mismatch between the gear icon (usually meaning "Settings") and its function as a general menu, while also making the table controls redundant with the hamburger Main Menu.

## After
The table's `Menu` has been replaced with a single `pause.circle` button. 
- Tapping it invokes the `WelcomeCard` (the Pause card), preserving the required three actions: `Continue game`, `New match`, and `Main menu`.
- General controls (Settings, Statistics, Tutorial) are now correctly accessed via the `Main menu`, resolving the icon mismatch and enforcing the design rule that "table gear means general controls while main menu uses hamburger".
