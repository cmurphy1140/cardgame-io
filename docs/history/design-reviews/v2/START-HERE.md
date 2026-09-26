# Catch 5 — design review request (no implementation this round)

**Date:** 16 Sept 2026 · **Repo:** `cmurphy1140/catch-5` · **From:** the design side
**Your role this round: sounding board, not builder.**

## Do not write UI code in this pass

Do not open a branch, do not add SwiftUI files, do not refactor `Theme`. Nothing here is
approved for implementation yet. We are deliberately parked one step short of the build so
the two sides can converge first.

What we want back is a **plan and a critique** — see "What to send back".

## Where this round sits

Read `LOOP.md` before the design files. It states the exit condition (MainMenuView on a
phone at three text sizes, approved), the three-round budget before the first build, and the
one-file-each-per-round contract. **This is round 1 of 3.** The loop ends at a real screen on
a real phone, not at a finished design.

Two consequences for your review:

- Sequence your feasibility notes around getting **1a** onto a phone. Screens parked until
  after that: dark mode, Rule Book and Walkthrough, pass-and-play setup, roadmap board. Price
  them if it is cheap to do so, but do not let them shape your recommended order.
- Ideas that are not needed for 1a belong in `docs/ideas.md` as one line each, not in
  `design-review.md`. Good idea, not now.

One mechanical ask, because it saves whole rounds: export
`docs/design-sync/tokens.json` from `Theme.Paper` on every build, so colour drift is caught by
a diff instead of by eye.

## What this package is
The design system we landed on for everything *off the felt*: the frame around the game.
1950s card-room paper. Cream scorepad ground, paper cards with a torn bottom edge, ink
bands, crimson as the only signal colour, rubber stamps instead of badges.

`screens/` holds clean PNGs of every hi-fi screen. `design/` holds the source design files
(HTML — a spec, not shippable code; open any `.dc.html` in a browser). `DESIGN-SYSTEM.md`
holds the tokens, the hard rules, the decisions already made, and the open questions.

## Three things to hold in mind while you read it

1. **There is no north star, and that is on purpose.** No single screen, doc line, or earlier
   direction is binding. The paper direction is the current consensus, not law. If a screen
   fights the platform, say so and propose the trade — you will not be overruling a sacred
   artifact.
2. **Apple's HIG and the research we leaned on are guidelines, not de facto.** Where a
   guideline and the card-room character collide, we want the collision named and priced,
   not silently resolved in either direction. "HIG says X" is the start of an argument, not
   the end of one.
3. **This is a family card game, not a product launch.** Feasibility and pragmatism beat
   fidelity. If a detail costs a week of Canvas work for 2 % of the feel, cut it and tell us.

## What to send back

One markdown file, `design-review.md`, at the repo root. Paste it into the design chat too.

```
## 1. Read-back
In your words: what this design system is, in five sentences. If your read differs from
ours, that gap is the most useful thing in this document.

## 2. Feasibility pass, screen by screen
For each screen in screens/: green / amber / red.
  green  — ordinary SwiftUI, build as drawn
  amber  — buildable, but the cost is worth naming (say the cost in hours and in risk)
  red    — fights SwiftUI, the data model, or the platform; propose the alternative
Name the specific mechanism for the amber and red ones (Canvas cost, clip-path equivalent,
layout that will break at AX2, state that does not exist in the model yet).

## 3. Where the Swift shape should change the design
The part we most want. Screens whose structure fights `RootView`'s screen/sheet/cover model,
the existing `Settings`/`MatchHistory`/`Cast` types, or the navigation you would naturally
write. Tell us what the app wants to be and where our drawing is swimming upstream.

## 4. Cheap wins we are missing
Things that are nearly free in SwiftUI that we did not ask for and probably should —
haptics, sensible transitions, Dynamic Type behaviour, state restoration, what
`.contextMenu`/`.refreshable` would buy us for free.

## 5. Sequencing you would actually follow
Not our order — yours. What you would build first to de-risk the rest, and what you would
deliberately defer. Say which screen you would build as the proof so both sides can look at
one real thing on a phone before the rest.

## 6. Questions and disagreements
Numbered, one decision each, each with the two options you would accept. Include the places
you think we are wrong about the design, not only the places you need information.
```

Keep it under three pages. Prose and bullets; no code beyond a signature or a token name.

## Ground rules for the critique

- Do not invent numbers. If an estimate is a guess, mark it as a guess.
- Read the actual repo before pricing anything — `Theme.swift`, `RootView.swift`,
  `docs/screen-flow.md`, `Cast.swift`, `Settings.swift`, `MatchHistory.swift`.
- The felt table is out of scope entirely (see hard rule 1).
- Disagreement is the deliverable. A review that says "looks good, here is the code" is a
  failed review this round.
