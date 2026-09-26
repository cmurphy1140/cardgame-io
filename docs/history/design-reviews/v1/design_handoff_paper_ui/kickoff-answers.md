# Kickoff answers — Catch 5 Paper

Answers to the kickoff prompt in `README.md`. Read: `README.md` (the HANDOFF.md
it names — the zip has no separate file by that name), `Catch 5 Paper.dc.html`
screen 1a, and Explorations 1j / 2a / 2e. No UI written; nothing in `Sources/`
edited.

---

## 1 · `Theme.Paper`

Goes inside the existing `public enum Theme` in `Sources/CatchFiveUI/Theme.swift`.
House style there is `Color(red:green:blue:)` with the reason in a doc comment —
the package has no hex initializer, so the hexes are converted.

```swift
    /// The paper world: everything off the felt (Catch 5 Paper.dc.html).
    /// Crimson is this world's only signal colour — no gold token may be imported by a paper view (D33, 3e).
    public enum Paper {
        // MARK: Ground and ink
        /// #EFE3C1 — the scorepad ground, under the seeded stipple.
        public static let ground = Color(red: 0.937, green: 0.890, blue: 0.757)
        /// #FBF5E4 — the lighter sheet on the ground: licence, resume strip, slips.
        public static let card = Color(red: 0.984, green: 0.961, blue: 0.894)
        /// #1C1A17 — 13.6:1 on ground and on card. Rules, borders, the system plate.
        public static let ink = Color(red: 0.110, green: 0.102, blue: 0.090)
        /// #6E6450 — label ink. 5.4:1 on card, 4.6:1 on ground. Replaces the mock's #8A7F6A,
        /// which measured 3.6 / 3.1 and fails (Explorations 2a); #8A7F6A is deliberately not defined here.
        public static let muted = Color(red: 0.431, green: 0.392, blue: 0.314)
        /// #5C5546 — secondary body copy, 6.8:1 on card.
        public static let sub = Color(red: 0.361, green: 0.333, blue: 0.275)
        /// #C9BC98 — hairline rules and field dividers.
        public static let rule = Color(red: 0.788, green: 0.737, blue: 0.596)
        /// #A69F8E — the darker strip under a band's bottom edge.
        public static let bandStrip = Color(red: 0.651, green: 0.624, blue: 0.557)

        // MARK: Signal
        /// #B8322A — the one signal colour. 5.5:1 on card, 4.7:1 on ground and as a band under cream.
        public static let crimson = Color(red: 0.722, green: 0.196, blue: 0.165)
        /// #7A1F1C — the hard drop under crimson display type.
        public static let crimsonDark = Color(red: 0.478, green: 0.122, blue: 0.110)
        /// #A52A24 — 5.6:1 under cream. Use instead of `crimson` wherever cream text on a crimson
        /// band falls below 16 pt, since `crimson` only passes at 18 pt bold and up (2a).
        public static let crimsonDeep = Color(red: 0.647, green: 0.165, blue: 0.141)
        /// #295742 — partner green, 7.6:1 as text on card, 6.5:1 as a band under cream.
        public static let green = Color(red: 0.161, green: 0.341, blue: 0.259)
        /// #17302A — the hard drop under green display type.
        public static let greenDark = Color(red: 0.090, green: 0.188, blue: 0.165)

        // MARK: Seats (Explorations 2b)
        public enum Seat { case south, north, east, west }
        /// One colour per seat, for setup bands, the handoff card and seat tiles later.
        public static func color(_ seat: Seat) -> Color {
            switch seat {
            case .south: crimson                                        // you
            case .north: green                                          // partner
            case .east: Color(red: 0.133, green: 0.188, blue: 0.310)    // #22304F navy, 10.2:1 under cream
            case .west: Color(red: 0.722, green: 0.580, blue: 0.231)    // #B8943B mustard
            }
        }
        /// Cream fails on mustard at 2.2:1, so the West band alone takes ink text at 6.1:1 (2a).
        public static func text(on seat: Seat) -> Color { seat == .west ? ink : ground }

        // MARK: Type
        /// CSS tracking is a fraction of the font size; SwiftUI's `.tracking` is points.
        public static func tracking(_ em: Double, at size: Double) -> Double { em * size }
        public enum Size {
            /// Band 18/700 at .08em, row 17–18/700 at .06em, label 11/700 at .14em.
            public static let band = 18.0, bandTracking = 0.08
            public static let row = 18.0, rowTracking = 0.06
            public static let label = 11.0, labelTracking = 0.14
            /// The floor on device. The mock's 9 and 10 pt licence labels rise to this (hard rule 3).
            public static let minimum = 11.0
        }

        // MARK: Pieces
        /// The mock's 56 pt is the floor; 1a's paired buttons run 64 and its full-width one 58.
        public static let buttonHeight = 56.0
        public static let buttonRadius = 6.0
        /// The plate carries a 3 pt ring of its own colour, then 1.5 pt of cream from 3 to 4.5.
        public static let ringInset = 3.0
        public static let ringWidth = 1.5
        /// The hard offset shadow every plate and sheet casts: no blur, down and right.
        public static let shadowOffset = 3.0
        public static let shadowOpacity = 0.28
        public static let cardRadius = 14.0
        public static let cardBorder = 3.0
        /// A double rule is two 2 pt lines with 4 pt of ground between them.
        public static let ruleThickness = 2.0
        public static let ruleGap = 4.0
        /// A band's darker bottom strip.
        public static let bandStripHeight = 6.0

        // MARK: Deckle
        /// Cards tear along the bottom only; the top stays clean under the band.
        public static let deckleDepth = 8.0
        public static let decklePoints = 16
        public static let deckleSeed: UInt64 = 5

        // MARK: Stamps
        /// Rubber stamps sit crooked, never square.
        public static let stampRotation = -8.0...(-3.0)
        public static let stampBorder = 2.5
        public static let stampTracking = 0.14
        /// Crimson on ground is 4.7:1 with no margin, so a stamp never goes below this (2a).
        public static let stampMinimumSize = 13.0

        // MARK: Surface
        /// `PaperSurface`, seeded like `FeltView`: flecks per 256 pt tile, then the dark/light split.
        public static let stippleCount = 2600
        public static let stippleTile = 256.0
        public static let stippleDarkShare = 0.55
        public static let stippleDarkAlpha = 0.05...0.17
        public static let stippleLightAlpha = 0.15...0.45
        public static let stippleSeed: UInt64 = 13
        /// The ground texture is laid over `ground` at this strength.
        public static let textureOpacity = 0.8
        /// Suit watermarks, menu only.
        public static let watermarkOpacity = 0.09
        /// #6B5A2E — the watermark's own brown. Not in the token block; see deviation 4.
        public static let watermark = Color(red: 0.420, green: 0.353, blue: 0.180)
        /// The licence photo's diagonal hatch: #E4D6AE stripes on `ground`, 3 pt on 3 pt at 135°.
        public static let hatch = Color(red: 0.894, green: 0.839, blue: 0.682)
        public static let hatchPitch = 3.0
    }
```

Three token-block values are not carried in: `#8A7F6A` (hard rule 4 retires it —
11 uses in 1a alone), and the `display` / `body` font families, which wait on
question 2.

---

## 2 · Every inline style pattern in Paper 1a

Only what is inside the `data-screen-label="1a Main menu"` div.

### Frame and surface

| Inline style in 1a | SwiftUI |
|---|---|
| `width:393px;min-height:852px;border-radius:44px;box-shadow:0 20px 50px` on the screen div | Nothing — that is the artboard's phone mock, not app chrome. The screen is the full `RootView` bounds. |
| `background:#EFE3C1` + `position:absolute;inset:0;background-image:url('{{ paper }}');background-size:128px 128px;opacity:.8` | `ZStack { Theme.Paper.ground; PaperSurface().opacity(0.8) }` — a seeded `Canvas`, never a PNG (hard rule 5). `.allowsHitTesting(false)`, `.accessibilityHidden(true)`. |
| watermark layer `color:#6B5A2E;opacity:.09` with 8 `<svg>` at `left/top/right` incl. negatives, each `transform:rotate(…)` | `ZStack` of suit `Shape`s in `.overlay`, placed with `.offset`, turned with `.rotationEffect(.degrees(…))`, `.foregroundStyle(Theme.Paper.watermark).opacity(0.09)`, whole screen `.clipped()` so the negative offsets bleed off-edge as they do here. |
| `position:relative;display:flex;flex-direction:column;gap:20px;padding:48px 24px 28px;flex:1` | `VStack(spacing: 20)` + `.padding(.top, 48).padding(.horizontal, 24).padding(.bottom, 28)` + `.frame(maxHeight: .infinity)`. |
| `<div style="flex:1;"></div>` | `Spacer()`. |
| `pointer-events:none` | `.allowsHitTesting(false)`. |

### Wordmark and rules

| Inline style in 1a | SwiftUI |
|---|---|
| `display:flex;align-items:center;justify-content:center;gap:16px` | `HStack(spacing: 16)`. |
| `filter:drop-shadow(0 3px 0 rgba(0,0,0,.18))` on the 5-and-hands mark | `.shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: 3)` — radius 0 keeps it hard. |
| `font:800 72px/.8 'Barlow Condensed';letter-spacing:-.01em` | size 72, weight `.heavy`, `.tracking(-0.72)`. The `/.8` line box and the parent's `line-height:.72` have no modifier: a fixed `.frame(height: 57.6)` per line, or `VStack(spacing:)` driven negative, checked against the mock. |
| `text-shadow:0 4px 0 #7A1F1C` | `ZStack { Text(…).foregroundStyle(.crimsonDark).offset(y: 4); Text(…).foregroundStyle(.crimson) }` — the drop is a second `Text` behind, `.accessibilityHidden(true)`. |
| `flex:1;border-top:2px solid;border-bottom:2px solid;height:4px` (the rule either side of ★ PLAY MATCH ★) | `VStack(spacing: 4) { Rectangle().frame(height: 2); Rectangle().frame(height: 2) }.frame(maxWidth: .infinity)` — `RuleHeading`. |
| `letter-spacing:.12em` at 16 px | `.tracking(1.92)` — via `Theme.Paper.tracking(0.12, at: 16)`. |
| `<svg><use href="#star">`, `#chev`, `#chip`, `#c5`, `#s-heart` … | Port the 28 symbol paths verbatim as `Shape`s / `Canvas` drawing. They are inline SVG in the DC, not assets, and `#chev` is a *double* chevron (»), not SF Symbols' single one. |

### Buttons

| Inline style in 1a | SwiftUI |
|---|---|
| `display:grid;grid-template-columns:1fr 1fr;gap:12px` | `HStack(spacing: 12)` with both children `.frame(maxWidth: .infinity)`, or `Grid`. |
| `height:64px;border-radius:6px;background:#B8322A;color:#EFE3C1` | `InsetRingButtonStyle(.crimson)`: `.frame(height: 64)`, `RoundedRectangle(cornerRadius: 6).fill(crimson)`, `.foregroundStyle(ground)`. |
| `box-shadow:inset 0 0 0 3px #B8322A,inset 0 0 0 4.5px #EFE3C1` | `.overlay(RoundedRectangle(cornerRadius: 6).inset(by: 3).strokeBorder(Theme.Paper.ground, lineWidth: 1.5))` — the first inset ring is the plate's own colour, so only the cream 1.5 pt band from 3 to 4.5 is visible. |
| `box-shadow:3px 3px 0 rgba(0,0,0,.28)` | `.background { RoundedRectangle(cornerRadius: 6).fill(.black.opacity(0.28)).offset(x: 3, y: 3) }` — a shape behind, not `.shadow`, so it stays a hard plate. |
| `font:700 20px;letter-spacing:.06em;line-height:1.05` + `<br>` | `Text("PLAY WITH\nBOTS")`, `.tracking(1.2)`, `.multilineTextAlignment(.center)`, `.lineSpacing(1)`. |
| `onClick="{{ goSetup }}"` | `Button(action:)`; destination per question 3. |

### Resume strip and licence sheet

| Inline style in 1a | SwiftUI |
|---|---|
| `sc-if value="{{ hasSaved }}"` | `if model.matchInProgress { … }`. |
| `display:flex;justify-content:space-between;padding:10px 14px;background:#FBF5E4` | `HStack` + `.padding(.vertical, 10).padding(.horizontal, 14).background(Theme.Paper.card)`. |
| `border-left:6px solid #295742` | `HStack(spacing: 0) { Rectangle().fill(green).frame(width: 6); … }`, or `.overlay(alignment: .leading)`. |
| `box-shadow:0 2px 0 rgba(0,0,0,.12)` | shape behind, `.offset(y: 2)`, opacity 0.12. |
| `border:3px solid #1C1A17;border-radius:14px` on the licence | `.overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(ink, lineWidth: 3))` — `strokeBorder`, not `stroke`: CSS borders sit inside the box, SwiftUI's `stroke` straddles the edge. |
| `overflow:hidden` | `.clipShape(RoundedRectangle(cornerRadius: 14))`, which is what crops the `right:-14px;bottom:-16px` spade at `opacity:.08`. |
| `background:#B8322A;padding:8px 14px;color:#EFE3C1` (licence header) | `HStack { … }.padding(.vertical, 8).padding(.horizontal, 14).background(crimson).foregroundStyle(ground)`. |
| `font:700 10px;letter-spacing:.2em;opacity:.85` (THE HOUSE · CATCH FIVE, BALANCE) | 11 pt floor, and drop the `.opacity(0.85)`: cream on crimson is already 4.7:1 with no margin, so fading it fails. |
| `font:700 9px;color:#8A7F6A` ×9 (NAME, D.O.B., CLASS, WINS, MATCHES, RESTRICTIONS, ENDORSEMENTS, LIC. NO., ADVICE FROM THE HOUSE) | 11 pt, `Theme.Paper.muted`, `.tracking(1.54)`. |
| `background:repeating-linear-gradient(135deg,#EFE3C1 0 3px,#E4D6AE 3px 6px)` (photo frame) | A `Canvas` of 135° stripes at `hatchPitch`, in the same seeded family as `PaperSurface`. Not a gradient and not a PNG. |
| `display:grid;grid-template-columns:1fr 1fr;gap:8px 10px;align-content:start` | `Grid(alignment: .topLeading, horizontalSpacing: 10, verticalSpacing: 8)`. |
| `grid-column:1 / -1` on the NAME cell | `.gridCellColumns(2)`; at ≥ XXL the whole grid becomes one column (Explorations 2e), via `@Environment(\.dynamicTypeSize)`. |
| `transform:rotate(-3deg);border:2.5px solid #B8322A;padding:1px 7px;border-radius:3px;letter-spacing:.14em` | `StampText`: `.padding(.horizontal, 7).padding(.vertical, 1)`, `.overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(crimson, lineWidth: 2.5))`, `.rotationEffect(.degrees(-3))`, plus an `.accessibilityLabel` so VoiceOver reads it straight. |
| `align-self:flex-start` | `.frame(maxWidth: .infinity, alignment: .leading)` on the row, or `HStack { stamp; Spacer() }`. |
| `font:italic 600 15px 'Barlow Condensed'` ("New player") | `.italic()` — needs the Condensed italic face if we bundle Barlow (question 2). |
| `{{ wins }}`, `{{ matches }}`, `{{ chips }}` at `font:800 22px` | `.monospacedDigit()` — the Addendum's tabular numerals, adopted in 4e. |
| `width:24px;height:24px;border-radius:50%;border:2px {{ p.border }} #8A7F6A` (endorsement pins) | `Circle().fill(pin.background).overlay(Circle().strokeBorder(muted, style: StrokeStyle(lineWidth: 2, dash: pin.dash)))`. `{{ p.border }}` is a hole carrying a CSS *keyword* (solid/dashed), so it becomes an enum case, not a string. `title="{{ p.name }}"` → `.accessibilityLabel`. |
| `sc-for list="{{ pins }}" as="p"` / `sc-if "{{ isNew }}"` | `ForEach` / `if`. |

### Footer, links, tip

| Inline style in 1a | SwiftUI |
|---|---|
| `border-top:2px solid #1C1A17;padding:9px 14px;background:#EFE3C1` | `VStack(spacing: 0) { Rectangle().fill(ink).frame(height: 2); HStack { … }.padding(…) }`. |
| `text-decoration:underline;text-decoration-thickness:2px;text-underline-offset:3px` | **No modifier exists.** `.underline()` gives no thickness or offset. Draw it: `.overlay(alignment: .bottom) { Rectangle().frame(height: 2).offset(y: 3) }`. This is the `LinkRow` component. |
| `padding:0 6px 0 240px;justify-content:flex-end;gap:28px` (WALLET · SETTINGS) | `HStack(spacing: 28) { Spacer(); … }.padding(.trailing, 6)` — the 240 px is a mock spacer and will collide at XXL. |
| `text-align:right` | `.frame(maxWidth: .infinity, alignment: .trailing)`. |
| `position:absolute;left:0;bottom:0;width:260px;height:150px` + children at `left:-26px;bottom:-60px` (tip slip and 5♥) | `.overlay(alignment: .bottomLeading) { ZStack { … } }` with `.offset`, then the screen's `.clipped()`. |
| `transform:rotate(-4deg)` / `rotate(-14deg)` | `.rotationEffect(.degrees(-4))` / `(-14)`. |
| `font:italic 400 13px/1.25 'Barlow'` | `.italic()` + `.lineSpacing` to reach 1.25. |
| `{{ paper }}` as a `url()` hole | Not data — a procedure. Rule 5. |

### Deviations that follow from the hard rules, not from a judgement call

1. Eleven labels rise from 9/10 pt to 11 pt (rule 3) — the two licence-header
   micro-labels and nine field labels.
2. All eleven uses of `#8A7F6A` become `#6E6450` (rule 4), including the
   endorsement pin borders and the "Catch 5 · 3.1 paper" version line, which
   2a's table does not list by name.
3. `opacity:.85` comes off the cream-on-crimson micro-labels; at 4.7:1 there is
   nothing to spend.
4. `#6B5A2E` (watermark) and `#E4D6AE` (photo hatch) are used in 1a but absent
   from the token block. Both added to `Theme.Paper` rather than substituted —
   flag if they were meant to derive from existing tokens.
5. Button heights in 1a are 64 and 58, not the token block's 56. Read 56 as the
   floor and keep 1a's own numbers, since "inline styles are the spec."

---

## 3 · The three questions I cannot answer from the files

**1. Box or paper — and it contradicts a recorded project decision, not just an
open design question.** 1j question 1 says everything waits on this, and the
README makes it step 1. What the files do not contain: `AGENTS.md` in this repo
carries an Aesthetic North Star amended September 14 that already decided the
opposite way — "the main menu is the box itself, closed, the title in gold foil,"
deep burgundy boards. Paper 1a is a cream menu, and hard rule 2 forbids a gold
token in any paper view. So this is not a choice between two open options; it
reverses E.8 and needs a numbered entry in `docs/decisions.md` before
`MainMenuView` is touched. Which stands, and is that your call or the
coordinator's?

**2. Barlow bundled, or SF with `.fontWidth(.condensed)`?** The token block gives
both and picks neither, and it changes the enum above. Bundled Barlow is six
files plus `Info.plist` entries and fixed point sizes that do not scale with
Dynamic Type unless every call site goes through `UIFontMetrics` — and 1a needs
the Condensed *italic* face too, for "New player." SF condensed is free, scales,
and `Theme.textBoostSteps = 2` keeps working, at some cost in character. The
whole type column above and the 11 pt floor behave differently between them.

**3. What does 1a actually do at step 4, when half of what it shows and both of
its buttons have nothing behind them?** The README's step 4 is "MainMenuView from
Paper 1a, with LicenseCard reading real Settings + Statistics." Reading the
source: `Settings` has no joined date, and `grep` finds zero occurrences of
chips, wallet or achievements anywhere in `Sources/` — so BALANCE, ENDORSEMENTS,
LIC. NO., CLASS/standing and RESTRICTIONS have no store, and `Wallet.swift` /
`Achievements.swift` are item 5 of a 14-item plan. Separately, PLAY WITH BOTS and
PASS AND PLAY point at `SetupView` and `PassAndPlaySetupView`, which are item 8,
and pass-and-play needs the seat-0 work 3b found in `GameModel`. Does the first
screen ship with those licence fields hidden until their stores land and the two
buttons wired to today's behaviour, or do Wallet, Achievements and the setup
screens land first? Either is buildable; they produce very different screenshots.
