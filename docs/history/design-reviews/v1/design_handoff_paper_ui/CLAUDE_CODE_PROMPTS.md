# Claude Code prompts, in order

Run one at a time from the repo root with this folder copied to `docs/design/paper-ui/`. Each prompt ends with a stop so you can review. Use plan mode for 0 and 1.

## 0. Orientation (no code)

```
Read AGENTS.md, docs/decisions.md, docs/ideas.md, docs/screen-flow.md, then
docs/design/paper-ui/README.md in full. Open the two .dc.html files in a
browser and describe what you see, screen by screen, in your own words.
List every place the README's claims about the code (Explorations 3a, 3b,
3c, 4e) disagree with current main, with file:line. Do not fix anything.
End with the open questions from the README that block slice 2 or 3, and
nothing else.
```

## 1. Plan

```
Using the README's "Suggested order of work", write docs/design/paper-ui/
PLAN.md: one section per slice with files touched, new types, tests to add,
and the decision (D-number) each slice records in docs/decisions.md. Keep
the felt untouched; flag anything that would touch TableView, FeltView,
seat tiles or the fan as "felt: needs a call". Nothing in the plan may
import Theme's gold token from a paper view. Stop for review.
```

## 2. Theme.Paper and PaperKit

```
Implement slice 2 from PLAN.md. Add Theme.Paper with the exact hex values in
the README's token table (use #6E6450 for muted, not #8A7F6A). Build
PaperKit: DeckleEdge (seeded 16-point torn bottom edge, 8 pt), PaperCard,
Band, RuleHeading, StampText, LinkRow, InsetRingButtonStyle(.ink/.crimson),
FlipDigit, PaperHeader. Add a paper stipple Canvas seeded like FeltView.
Replace MenuButtons usages with InsetRingButtonStyle so no menu or tutorial
button imports .gold (this closes design item 3e). Extend
scripts/contrast-sample.swift with muted-on-card, muted-on-ground,
cream-on-crimson, ink-on-mustard. Add previews for each component at Large,
XXL and AX2. Run the tests and the build; report what you could not run.
```

## 3. Licence, menu, settings

```
Implement slice 3. Add Settings.joined (default earliest MatchRecord.date,
else now) and a stable licence number. Build LicenseCard matching Catch 5
Paper 1a exactly (labels 11 pt minimum on device, stacked layout at XXL+
per Explorations 2e). Rewrite MainMenuView to 1a: title, PLAY MATCH rule,
two buttons, Resume strip when a match is in progress, LicenseCard, HOW TO
PLAY, WALLET · SETTINGS footer, House advice slip. Settings becomes a paper
sheet per 1b with the four MORE links (Roster, Pit boss, Board, Explainer)
stubbed. If the frame question (README Q1) is unanswered, keep the current
RootView background and put paper inside it. Preview fixtures: new player,
Regular with 3 pins, saved match.
```

## 4. Records, wallet, achievements, roster

```
Implement slice 4. Extend MatchRecord with fivesCaught, biddersSet,
nineAndOut, cleanSweep, kind, humanSeats and a per-hand [HandSummary]
array, all decodeIfPresent with defaults; compute them once in
recordMatchIfFinished(). Add Wallet and Achievements Codable stores beside
MatchHistory, applied idempotently by record id (+50 win, +15 contract;
solo matches only). Achievements: the 12 in Catch 5 Paper 1d; Murphy Who?
and Full House stay defined but unreachable until their features exist.
Build WalletView (1e), AchievementsView (1d, PIN toggle, max 3), RosterView
(1f, read-only, Roster.swift with the seven bots and portrait recipes; do
not change Cast or seatNames yet). Tests: zero records, duplicate record,
resume after record, negative scores.
```

## 5. Scorebook

```
Implement slice 5 per Explorations 4a, 4b and the metric table in 4e.
Move StatisticsView out of ReviewView.swift into ScorebookView with
Overview, Bidding, Scoring, History. Every rate shows "x of y". Personal
contracts and team contracts are separate denominators. Swift Charts:
step LineMark for the score trajectory, BarMark for made-by-bid-level, ink
axes, no grid, tabular numerals. Drill-down: bid level -> hands -> hand
summary -> existing ReviewView. Filters default to solo; pass-and-play,
tutorial and unfinished are visible but separate. Tests: zero denominator,
3 of 4, partner won the auction, renamed player keeps history.
```

## 6. Setup and presets

```
Implement slice 6 per Explorations 1a. MatchSetup value type; GameModel.
newGame(setup:). SetupView: your seat, partner, opponents (pick from
roster, dice per seat), table settings (strength, speed, beginner,
haptics, dice per row), presets row (Beginner's Luck / Randomize all /
Murphy's Law) with the 2 s crimson tick, LET'S PLAY. Murphy's Law per the
answer to README Q3; if unanswered, implement it as a preset over
Standard + Quick + beginner off and say so. Tier sets the default strength.
```

## 7. Pass and play

```
Implement slice 7 per Explorations 3b and 4c. GameModel.humanSeats;
rekey isHumanTurn, send, stepComputer, humanCards, undo, hints,
performance and MatchRecord to the active human. Handoff is a TablePause
reason; cover shows "PASS TO <name>", a 3 s lockout, then a deliberate
"I'M <NAME> · SHOW MY HAND" tap. Re-cover on background and resume. Hidden
hands must be absent from accessibility labels, not just hidden. Undo
cannot cross a handoff. Hints off. TurnTimer: Off/15/30/60 per phase,
expiry submits a random legal action through the bot path; digits in the
band per Explorations 3c (middle slot while bidding, appended to the
contract chip in play); ivory digits, never gold. Timers and the cover
are covers, not felt changes; anything that must touch TableView gets a
"felt: needs a call" note and stops.
```

## 8. Pit boss, board, licence login

```
Implement slice 8. PitBossView builds a github.com/cmurphy1140/catch-5/
issues/new URL with title "[<category>] <first 60 chars>", labels
from-the-table,<category>, body from resumeContext, lastHandOutcome and
describe() per Explorations 3d; opens in Safari. scripts/export-board.py
turns docs/roadmap.md and docs/ideas.md into board.json; BoardView shows
Ideas / In progress / Shipped; a test asserts the JSON matches the docs.
LoginView becomes the licence application (Explorations 1e) with the
print animation from 2f, skippable, crossfade under Reduce Motion.
```

## Ground rules for every prompt

- Felt untouched. Gold stays felt-only; no paper view imports it.
- One haptic per event. Reduce Motion preserves information.
- Never compute points or chips from an animation callback.
- Record a D-number in docs/decisions.md for each decision the slice makes.
- Report tests you ran and tests you could not run, separately.
