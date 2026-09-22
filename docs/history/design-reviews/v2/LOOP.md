# The loop: how design and dev round-trip, and when it ends

Two sides, one orchestrator (Connor), one judge (the phone). This file exists so the
round-trip cannot quietly become a diversion.

## Exit condition

**The loop ends when `MainMenuView` (Paper 1a) runs on Connor's phone at Large, XXXL and AX2,
and Connor says it looks right.**

That is the destination. Not a full app, not every screen, not a resolved dark mode. One
screen, on device, approved. After that, the paper system is proven and the remaining screens
are ordinary work — built from the package, reviewed in `design-sync.md`, no design rounds
required unless something genuinely new comes up.

Until then, every round must move 1a closer to a phone. A round that does not is a diversion.

## Round budget

Three rounds before the first build. If the build does not land in round three, the problem is
the design system, not the screen — stop and re-scope rather than opening round four.

| Round | Dev side produces | Design side produces |
|---|---|---|
| 1 | `design-review.md` — feasibility, where Swift should change the design, sequencing, disagreements | Answers by number; 1a redrawn only where the review earned it |
| 2 | `Theme.Paper` + `PaperKit.swift` + one screenshot of a single stamped band on device | Whatever 1a detail round 1 proved wrong; nothing else |
| 3 | `MainMenuView` built from 1a, screenshots at Large / XXXL / AX2, `design-sync.md` | Verdict per deviation: accept, or one specific change |

## Per-round contract

Each round produces **exactly one file from each side** and one numbered decision list. No
round is allowed to widen scope. Three rules:

1. **One file each.** `design-review.md` / `design-sync.md` from dev; a decision list plus at
   most one changed screen from design. Not a folder of new explorations.
2. **New ideas do not enter the loop.** Anything that is not needed for 1a on a phone goes
   into `docs/ideas.md` as one line and is not discussed this round. Good idea, not now.
3. **Decisions are numbered and answered by number.** An unanswered number stays open; it
   never becomes an assumption.

Things explicitly parked until after the exit condition: dark mode, Rule Book and Walkthrough,
pass-and-play setup, the roadmap board, Murphy's Law engine strength, the undo consumable
question.

## State discipline

**If it is not in `CLAUDE.md` or `github.md`, it did not happen.** Chat history is not state;
by round five nobody remembers round two.

At the end of every round, Connor pastes both round files into the design chat, and design
must, in that same turn:

- rewrite **Where things stand** in `CLAUDE.md` — current direction, what just changed, what is
  now parked;
- add the answered decisions to **Decisions made (do not re-ask)**;
- update **Known debts**, removing anything the round resolved;
- refresh `## Last sync` in `github.md` with the real date and the commit, and keep the screen
  map honest.

Rewriting, not appending. A notes file that only grows stops being read.

## Drift control

Colour and token drift is mechanical, so catch it mechanically instead of by eye:

- dev exports `docs/design-sync/tokens.json` from `Theme.Paper` on every build;
- design reads it before drawing and flags any value that does not match `DESIGN-SYSTEM.md`;
- `scripts/contrast-sample.swift` covers every pair in the contrast audit and runs in CI;
- snapshot tests per screen at three text sizes are the design fixtures — a failing snapshot
  is a design question, not a test failure.

Zero rounds should be spent arguing about a hex code.
