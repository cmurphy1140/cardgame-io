repo: cmurphy1140/catch-5
branch: main
path: Sources/CatchFiveUI

## Last sync
date: 2026-09-15T23:04:40Z

### Updated in this project
- Explorations turn 3: data audit of MatchRecord/HandSummary for achievements, pass-and-play engine impact (seat-0 assumptions in GameModel), timer placement corrected against ScoreBarView, pit-boss issue payload from model strings
- Catch 5 Paper Explorations: wireframes for setup, pass-and-play, handoff, band timer, licence login, hand-end stamps, dossier, tutorial, pause card; working doc with 13 questions and a 14-file SwiftUI plan, read from RootView, LoginView, IntroView, Theme, screen-flow.md, catch-five-rules.md
- Catch 5 Paper: cream scorepad direction for every screen off the felt (menu, statistics, achievements, wallet/shop, roster, settings, pit boss, roadmap board)
- Settings fields, Portrait recipe, Cast and Statistics fields read from Settings.swift, SettingsView.swift, Cast.swift, MatchHistory.swift
- Roadmap board columns from docs/roadmap.md (M1–M8) and docs/ideas.md (E.5–E.10)

## Sync history
- 2026-09-15T04:15:37Z — box wiring plan; Table rebuilt from source

### Earlier notes
- Turn 3: wireframes (lid motion, rules leaflet, scorepad, name-plate login, button system) + file-by-file wiring plan read from RootView, MainMenuView, TableView, TutorialView, ReviewView, WelcomeCard, LoginView, IntroView
- Table rebuilt from TableView / TableSurface / HandFanView / CardView / PortraitView (band shape, fan, pile nudges, procedural cast portraits)
- Felt nap procedure copied from FeltView; palette from Theme.swift and CardView.swift

- 2026-09-15T04:03:46Z — first read; Table rebuilt from source; turn 2 material alternatives

## Screen map
| Screen | Repo files |
|---|---|
| Table.dc.html (felt table, header band) | Sources/CatchFiveUI/TableView.swift, TableSurface.swift, ScoreBarView.swift, HandFanView.swift, CardView.swift, PortraitView.swift, Cast.swift, WoodGrainView.swift, Theme.swift |
| Catch 5 Box.dc.html — main menu (1c, 1d, 2a–2c) | Sources/CatchFiveUI/MainMenuView.swift |
| Catch 5 Box.dc.html — how to play (1h) | Sources/CatchFiveUI/Tutorial/TutorialView.swift |
| Catch 5 Box.dc.html — hand review (1i) | Sources/CatchFiveUI/ReviewView.swift |
| Catch 5 Box.dc.html — wiring plan + wireframes (3a–3e) | Sources/CatchFiveUI/RootView.swift, WelcomeCard.swift, LoginView.swift, IntroView.swift, TutorialView.swift, ReviewView.swift, docs/screen-flow.md, docs/architecture.md |
| Catch 5 Box.dc.html — brief | docs/deck-box-plan.md |
| Catch 5 Paper.dc.html — menu, settings (1a, 1b) | Sources/CatchFiveUI/MainMenuView.swift, SettingsView.swift, Settings.swift, Cast.swift |
| Catch 5 Paper.dc.html — statistics (1c) | Sources/CatchFiveUI/MatchHistory.swift, ReviewView.swift (StatisticsView) |
| Catch 5 Paper.dc.html — roster (1f) | Sources/CatchFiveUI/Cast.swift, Sources/CatchFive/ComputerPlayer.swift (Difficulty) |
| Catch 5 Paper.dc.html — roadmap board (1h) | docs/roadmap.md, docs/ideas.md |
| Catch 5 Paper Explorations.dc.html — turn 3 (3a–3e) | Sources/CatchFiveUI/GameModel.swift, TableView.swift, ScoreBarView.swift, HandOutcome.swift, MatchHistory.swift |
| Catch 5 Paper Explorations.dc.html — wireframes + doc (1a–1j) | Sources/CatchFiveUI/RootView.swift, LoginView.swift, IntroView.swift, Theme.swift, Cast.swift, Settings.swift, MatchHistory.swift, docs/screen-flow.md, docs/catch-five-rules.md, docs/ideas.md |
