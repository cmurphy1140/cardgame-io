# The design system we landed on

Everything **off the felt**: menu, player card, settings, statistics, achievements, wallet
and shop, bot roster, pit boss, roadmap board, plus the setup and pass-and-play screens
still at wireframe stage.

## The idea

A 1950s card room's paper ephemera. The app's frame is a scorepad, a driver's licence, a
shop slip, a cork board — things that could have been left on the table. Character comes
from procedure and typography, not from decoration: seeded grain, stamped headings, torn
paper edges, ruled lines. Wit is in the copy, never in an emoji.

## Colour

Primaries, used only in titles and important subheaders:

```
ink      #1C1A17     felt green  #295742     crimson  #B8322A   (the CATCH word, signals)
```

Everything else is black or beige boxes, banded with three accents placed **close together**
so the depth reads as paper layers rather than as colour:

```
aged copper #A0634C   (ink text on it)
gilded gold #C6A460   (ink text on it — cream fails at 3.75)
cream       #EFE3C1
dark copper #7E4A36   (border tone)
```

Grounds and supporting values:

```
ground  #EFE3C1   card #FBF5E4   rule #C9BC98   band strip #A69F8E
muted   #6E6450   sub  #5C5546   small labels #767066
crimson dark #7A1F1C   green dark #17302A   navy #22304F   mustard #B8943B (ink text)
```

Rules: three colours per screen, maximum. Seat colours appear only on pass-and-play screens.
Gold stays on the felt — paper uses crimson stamps instead ("gold on paper reads tacky").

## Type

```
display  Barlow Condensed 800/700     body  Barlow 400/600
         (SF with .fontWidth(.condensed) is an acceptable substitute — tell us if you prefer it)

band   18 / 700 / .08em tracking
row    17–18 / 700 / .06em
label  11 / 700 / .14em      ← 11 pt is the floor on device, no exceptions
stamp  border 2.5–3 pt, rotate −3…−8°, tracking .14
```

## Components (the kit the screens are built from)

`DeckleEdge` (8 pt, 16 seeded points, bottom edge only) · `PaperCard` · `Band` +
6 pt strip · `RuleHeading` · `StampText` · `LinkRow` · `InsetRingButtonStyle` (56 pt, radius
6, 3 pt plate + 1.5 pt cream inset ring, 3/3 ink-28 % shadow) · `FlipDigit` · `PaperHeader`.

## Hard rules

1. **The felt table is untouchable.** Playing surface, ivory cards, green backs, seat tiles,
   portraits, auction pills, gold's five meanings. The paper work stops at the table edge.
2. No gold token in any paper view. Crimson `#B8322A` is paper's only signal colour.
3. Text never below 11 pt on device. The licence must stack to one column at ≥ XXL.
4. Muted label ink is `#6E6450` — not the `#8A7F6A` that appears in older wireframes, which
   fails contrast.
5. Textures are seeded procedures (`textures.js` → `Canvas`), never PNGs. Same LCG as
   `GrainRandom`.

## Screen inventory

Hi-fi (in `screens/`, source in `design/Catch 5 Paper.dc.html`):

| Id | Screen | Notes |
|---|---|---|
| 1a | Main menu | CATCH/FIVE wordmark + badge (menu only), PLAY MATCH, Play With Bots ǀ Pass and Play, Resume strip when a match is saved, licence strip, LEARN as two face-up cards, WALLET · SETTINGS footer, house-advice joke slip behind a 5♥. Two states via props: no player card / card out. |
| 1i | Home / player card | The licence at full size — name, D.O.B. = joined, CLASS, WINS/MATCHES, RESTRICTIONS, ENDORSEMENTS (max 3 pinned). Fill-it-out for new players, stats for returners. |
| 1c | Statistics | Full page. |
| 1d | Achievements | 12, card-room pun names, DONE stamp or fraction, pin toggle. |
| 1e | Wallet & shop | Chips, bot play only (win 50, contract 15). Re-deal 25, undo 10, card back 350, felt colours 500, bots 400. No ledger. |
| 1f | Bot roster | One list, stamped tier headers; bio = name · drink · former job. |
| 1g | Tell the pit boss | Modal card. Category chips, note, attach last hand, files a GitHub issue. |
| 1h | Roadmap board | Three pinned columns from `docs/roadmap.md` + `docs/ideas.md`. Wide layout. |
| 1b | Settings | `screens/1b-settings-prior-pass.png` is from the previous pass; the modal is being redrawn and is **not** current. Review it as intent only. |

Wireframes only, in `design/Catch 5 Paper Explorations.dc.html` (1a–1i) — structure and flow,
not visuals: Play With Bots setup, pass-and-play setup, handoff cover, band timer, licence
login, hand-end stamps, bot dossier, how to play, pause card. `1j` is the working doc;
`2a–2f` are the contrast audit, seat colours, chip economy, bot voices, AX2 licence, motion.

## Decisions already made (please critique, but do not re-ask)

- Paper is the primary frame. The earlier burgundy deck box survives only as the table's
  header band during play. (`design/reference/` has the old direction if you want it.)
- Player card doubles as local auth: name + favourite drink masked as a password. No server,
  hashed storage required.
- Settings and pit boss are modal cards; statistics, achievements, wallet and roster are full
  pages. Settings › More holds Roster, Tell the pit boss, What's in the works, How Catch 5 is
  built.
- Bot roster: Beginner Ronald (free) & Jane; Regular Ruby (free) & Brad; Shark Florian (free)
  & Phoebe; Wildcard Cranky Connor (free after 25 wins). Paid 400 chips. Tier sets a default
  strength that setup can override.
- Pass and Play: 2–4 humans, two humans sit as partners, bots fill the rest; name + HIM/HER +
  face per human; timers Off/15/30/60 per phase; timeout = random legal action; handoff cover
  with a 3-second flip-clock countdown.
- Setup presets: Beginner's Luck / Murphy's Law as a quick-apply row; CTA "LET'S PLAY".
- Flip-clock digits: bid/play timer on the table header band, and the wallet balance.
- LEARN row: two face-up black playing cards (R♥ RULE BOOK, W♠ WALKTHROUGH).

## Known debts and open questions

- **Dark mode is promised, not built.** The menu's light/dark toggle is two playing cards
  (A♥ cream, A♠ `#1D262F`); picking dark currently does nothing. Night ground `#1D262F`,
  cards stay cream. Every paper screen needs a second ground and a fresh contrast audit.
- **Murphy's Law / HARD strength has no engine player** (only Easy and Standard exist).
  Parked — say if you would rather we drop the preset than promise it.
- **Undo consumable vs free** is undecided (working doc Q10).
- Licence labels sit at 9 px in the mock; 11 pt is the device floor and the layout must stack
  at ≥ XXL. `Theme.textBoostSteps = 2` makes large type the common case, not the edge case.
- Rule Book and Walkthrough views are not designed yet, only linked from LEARN.
- Portraits render through `textures.js` `portraitParts` (React.createElement) — fine for
  mocks, needs the `PortraitView` recipe on device.
- Setup, pass-and-play, handoff and How to Play exist as wireframes only.

## What we would find most useful from you

Not a fidelity audit. The places where the SwiftUI shape, the data model, or the flow you
would naturally write suggest a **better** design than what we drew — and the places where
our drawing quietly assumes state or engine behaviour the app does not have.
