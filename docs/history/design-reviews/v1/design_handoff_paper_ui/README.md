# Handoff: Catch 5 paper UI (everything off the felt)

## Overview
The frame around Connor's Catch 5 card game, redesigned as 1950s card-room paper: cream scorepad ground, paper cards with a torn bottom edge, ink and crimson bands, rubber stamps. Eight hi-fi screens (menu, settings, statistics, achievements, wallet/shop, roster, pit boss, roadmap board), nine wireframes for the screens still owed, and a working doc with open questions and the SwiftUI plan.

## About the design files
Every `.dc.html` in this folder is a **design reference built in HTML**: it shows intended look and behaviour and is not code to ship. The task is to **recreate these in the existing SwiftUI codebase** (`cmurphy1140/catch-5`, `Sources/CatchFiveUI`) using its patterns: `Theme` tokens, `Canvas` procedures like `FeltView`/`WoodGrainView`, `PortraitView` recipes, the `RootView` screen/sheet/cover model in `docs/screen-flow.md`.

Open any `.dc.html` in a browser. Inline styles are the spec; `{{ name }}` holes are data.

## Fidelity
- **Hi-fi:** `Catch 5 Paper.dc.html` screens 1a–1h. Recreate to the pixel where SwiftUI allows; deviations go in `design-sync.md`.
- **Lo-fi:** `Catch 5 Paper Explorations.dc.html` 1a–1i are wireframes (structure and flow only); 1j and 2a–2f are documents.
- **Reference only:** `Catch 5 Box.dc.html`, `Catch 5 Motion.dc.html`, `Table.dc.html` (earlier deck-box direction and the felt table, which is untouchable).

## Hard rules
1. The felt table is not to be changed: surface, cards, backs, seat tiles, portraits, auction pills, gold's five meanings.
2. No gold token in any paper view. Crimson `#B8322A` is paper's only signal colour.
3. Text never below 11 pt on device; the licence stacks to one column at ≥ XXL (Explorations 2e).
4. Muted label ink is `#6E6450`, not the mock's `#8A7F6A` (fails contrast, Explorations 2a).
5. Textures are seeded procedures (see `textures.js`), never PNGs.

---


## What is in the zip

| File | What it is | Read it for |
|---|---|---|
| `Catch 5 Paper.dc.html` | Hi-fi: menu, settings, statistics, achievements, wallet/shop, roster, pit boss, roadmap board (ids 1a–1h) | Exact colours, sizes, spacing, copy. Inline styles are the spec. |
| `Catch 5 Paper Explorations.dc.html` | Wireframes for setup, pass-and-play, handoff, band timer, licence login, hand-end stamps, dossier, tutorial, pause card (1a–1i); working doc (1j); contrast audit, seat colours, economy, voices, AX2 licence, motion (2a–2f) | Open questions, the 14-file SwiftUI plan, measured contrast, motion timings |
| `Catch 5 Box.dc.html`, `Catch 5 Motion.dc.html`, `Table.dc.html` | Earlier: deck-box frame, lid motion spec, felt table | Only if question 1 in 1j keeps the box |
| `textures.js` | Seeded procedures for felt, cloth, paper stipple, portrait parts | Port to `Canvas` verbatim; same LCG as `GrainRandom` |
| `github.md` | Screen map: which repo files each screen was read from | Where to make the change |
| `HANDOFF.md` | This file | |

Open any `.dc.html` in a browser. The `{{ name }}` holes are data; everything else is literal.

## Order of work

1. Answer question 1 in Explorations 1j (box or paper as the frame). Everything else waits on it.
2. `Theme.Paper` tokens (values below). Add `#6E6450` muted ink, not `#8A7F6A` (fails contrast, see 2a).
3. `PaperKit.swift`: DeckleEdge, PaperCard, Band, RuleHeading, StampText, LinkRow, InsetRingButtonStyle, FlipDigit, PaperHeader.
4. One screen end to end: MainMenuView from Paper 1a, with LicenseCard reading real Settings + Statistics. Run at Large, XXXL, AX2. Send screenshots back.
5. Only then the rest, in the order the plan in 1j gives.

## Tokens

```
ground   #EFE3C1   card #FBF5E4   ink #1C1A17
crimson  #B8322A   crimsonDark #7A1F1C
green    #295742   greenDark  #17302A
navy     #22304F   mustard    #B8943B (ink text on it)
rule     #C9BC98   bandStrip  #A69F8E   muted #6E6450   sub #5C5546
display  Barlow Condensed 800/700   body Barlow 400/600 (or SF .fontWidth(.condensed))
band 18/700 .08em · row 17–18/700 .06em · label 11/700 .14em (never below 11 pt on device)
button  56 pt, radius 6, inset ring 3 pt plate + 1.5 pt cream, shadow 3,3 ink 28 %
deckle  8 pt, 16 points, bottom edge only
stamp   border 2.5–3 pt, rotate −3…−8°, tracking .14
```

## CSS → SwiftUI, the recurring cases

| In the DC | In SwiftUI |
|---|---|
| `clip-path: var(--tear)` | `.clipShape(DeckleEdge())` (a `Shape`, seeded points) |
| `box-shadow: inset 0 0 0 3px X, inset 0 0 0 4.5px cream` | `.overlay(RoundedRectangle(...).inset(by: 3).stroke(cream, lineWidth: 1.5))` |
| `box-shadow: 3px 3px 0 rgba(0,0,0,.28)` | `.background(shape.fill(.black.opacity(.28)).offset(x: 3, y: 3))` |
| `text-shadow: 0 4px 0 dark` | a second `Text` in `dark` offset y 4, behind |
| `border-bottom: 6px solid strip` on a band | `VStack(spacing:0){ band; strip.frame(height:6) }` |
| `transform: rotate(-3deg)` on a stamp | `.rotationEffect(.degrees(-3))` |
| `background-image: url(paper)` | `PaperSurface` Canvas, seeded; never a PNG |
| `display:grid; grid-template-columns:1fr 1fr` | `Grid` (iOS 16) or `LazyVGrid` with two flexible columns |
| `sc-if` / `sc-for` | `if` / `ForEach` |
| `{{ wins }}` | a model property with the same name |
| props in `data-props` (flowMode, newPlayer, savedMatch) | preview parameters / `#Preview` variants |
| `data-screen-label="1c Statistics"` | the view's name in `docs/screen-flow.md` and `github.md` |

## What to send back (design-sync.md)

Put this at the repo root after each screen, and paste it into the design chat:

```
## <Screen> · <date>
built from: Catch 5 Paper #1a (commit …)
screenshots: Large / XXXL / AX2 (attach)
deviations: bullet list — what differs from the DC and why (a sentence each)
tokens changed: name, old, new, reason
questions: numbered, one decision each
next: what you will build unless told otherwise
```

## Prompts to paste into Claude Code

Kickoff:

> Read HANDOFF.md, then open Catch 5 Paper.dc.html and Catch 5 Paper Explorations.dc.html in the zip. Do not write UI yet. Give me: (1) the Theme.Paper enum from the token block, (2) a list of every inline style pattern in Paper 1a with the SwiftUI modifier you will use for it, (3) the three questions you cannot answer from the files. Then stop.

One screen:

> Build MainMenuView from Catch 5 Paper #1a. Inline styles are the spec; copy is verbatim. Use PaperKit components only, no gold token anywhere in the file. Run the simulator at Large, XXXL and AX2, export screenshots to docs/design-sync/, and write design-sync.md in the format from HANDOFF.md. If a value cannot be matched, keep the DC's intent and list it under deviations.

Ask design for something:

> Write a message to the design side. State the screen, the exact problem, what you tried, and the two options you would accept. Attach the screenshot. Under 120 words.

## Ways Claude Code can make the design side faster

- Export `docs/design-sync/tokens.json` from `Theme.Paper` on every build; design imports it, so the two never drift.
- Snapshot tests per screen at three text sizes: they are the design fixtures. A failing snapshot is a design question.
- Extend `scripts/contrast-sample.swift` with every pair in Explorations 2a; run it in CI.
- Keep `docs/screen-flow.md` current; design reads it to know what exists.
- A `board.json` exporter from `docs/roadmap.md` + `docs/ideas.md` for the in-app board (Paper 1h).
- When a design idea needs engine work (HARD strength, per-seat records, joined date), file it as an issue titled `design-needs:` so design can see the cost.


---

## Screen map (from github.md)
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

