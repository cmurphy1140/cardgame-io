# Held for design — after the frame question is answered

Sent separately: `design-question-frame.md` (1j question 1, the box-or-paper reversal).
Everything below waits on that answer; if the box wins, the slip collision (2) and PASS AND PLAY (4) disappear with the
redrawn 1a. Each item is one decision, with the two answers we would accept.

**Attach when sent:** `paper-1a-menu.png`, `wf-2e-licence-ax2.png`.

---

## 1. Barlow or SF — and they are not interchangeable

The token block lists `Barlow Condensed 800/700` **or** `SF .fontWidth(.condensed)` and
picks neither. SF's condensed width is a much gentler squeeze than Barlow Condensed 800,
and the wordmark's compression is carrying most of 1a's period character. Bundled Barlow
does not scale with Dynamic Type unless every call site goes through `UIFontMetrics`,
which defeats `Theme.textBoostSteps = 2` (already shipped: it makes Large read as XXL).

- **Hybrid** — bundle Barlow Condensed for display only (wordmark, band 18/700, row
  18/700); SF for body and the 11 pt labels. Two font files, not six.
- **All SF** — no bundling, Dynamic Type free, and you accept a less compressed
  wordmark. If this one, send an updated 1a so we are matching a real target.

## 2. The House advice slip covers the WALLET link

In `paper-1a-menu.png` the slip renders on top of the footer: the link reads "VALLET".
The footer carries `padding:0 6px 0 240px`, but the slip's card runs to roughly 430 px
inside a 393 px screen. This is at default text size, before Dynamic Type.

- Slip moves above the footer row, or
- Slip narrows to clear 240 px and keeps its rotation.

## 3. LIC. NO. — who generates it, and what is the width budget?

It wraps at default size in 1a (`C5-0002-` / `00`), and 2e drops the field entirely at
AX2. Confirm it is ours to derive (stable from name + joined date), and either give a
format that fits one line at Large, or confirm the wrap is acceptable.

## 4. What PASS AND PLAY does before its engine work exists

Pass-and-play needs `GameModel.humanSeats` (your 3b) and a setup screen — slices 6 and 7.
`PLAY WITH BOTS` can ship now on today's `newGame()`. The black plate is half 1a's
visual weight, so it cannot simply be removed without redrawing the screen.

- Ships **disabled** with a stamped state you specify, or
- 1a ships with one full-width `PLAY WITH BOTS` until slice 7, and you send that variant.

---

## Settled by your files — no answer needed

- `{{ restrictions }}` resolves to BEGINNER MODE, which we already store.
- Every "missing store" field has a drawn zero state: BALANCE `0`, dashed endorsement
  slots, CLASS *New player*. So the licence ships **complete** at slice 3 with constants
  behind balance and endorsements, and slice 4 swaps in the stores without the screen
  changing shape. That removed the scope question entirely.
- Muted ink is `#6E6450` everywhere, including the endorsement pin borders and the
  version line, which 2a does not list by name.
- 1a's button heights are 64 and 58; we read the token block's 56 as a floor and keep
  1a's own numbers.
