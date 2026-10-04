# Tactile table: audit and first-version plan

Branch `ui/tactile-table`, started 2026-10-04 from `main` at `cb21ba4`. Simulator: `Catch 5 UX Review`
(iPhone 16, iOS 18.6). Scope of the first version: the playing table and the trick, then a recording for
review before any other screen changes. Bidding, the hand result, Home and the score sheet come after.

## What the current table does badly (observed 2026-10-04 on `main`)

Captured with the `bidding`, `trump`, `table`, `result` and `home` launch stages on the simulator.

| # | Weakness | Where it shows |
|---|---|---|
| 1 | **One flat plane.** Header, table and hand area are the same oak with no edge, recess or light, so nothing says where play happens; the trick floats on the grain. | Every table state |
| 2 | **Teams are invisible at the seats.** Partner and opponents wear the same disc, ring and carved name; US/THEM appear only on the score pad. | `table`, `bidding` |
| 3 | **Turn is hard to follow.** A 3 pt gold ring and three dots are the only cue; a computer's card fades in from the screen's edge, not from the player, so you cannot tell who just played without reading. | `table` |
| 4 | **Contract and score are scattered,** and the bid corner can be missing: in the `table` capture the top-left corner is empty although JC holds the bid (trump only shows as a small carved ♣ beside JC's name). | `table` |
| 5 | **Cards read as tiles, not cards.** One big centre rank, a small top-left index, no pips, no second index, 2:3 proportions; legal cards lift only 6 pt and a selected card gives no cue that a second tap plays it. | hand in `table`, `bidding` |
| 6 | **Motion stops at the important moments.** No deal at the start of a hand (cards appear); the finished trick drifts off and fades instead of being gathered and taken; the hand result jumps in the instant the last card lands. Each pile card also shifts slightly when its trick completes (its toss is keyed to the completed-trick count). | play, hand end |

## Direction

Keep the oak, the cream cards, the dark-red accents and the carved, inlaid and lying-on-the-table language
of D94. Add depth and order rather than panels.

- **The table gets a playing field:** a walnut panel inlaid in the oak with a maple stringing line, recessed
  (shadow under the top edge, a lit lower lip), lit from above. The trump suit is inlaid at its centre in
  maple, or in a red wood for hearts and diamonds, once it is named. Seats sit round the panel on the oak, so
  every carved name stays on wood it reads on.
- **Teams by rim:** your side's portraits keep the light ring, the opponents' wear an oxblood ring.
- **Turn:** a pool of lamplight on the field slides to the seat whose turn it is, alongside the gold halo.
- **Cards:** poker proportions (1:1.4), a large index in two corners, real pip layouts, framed court letters;
  slightly larger hand cards; a clear lifted state for legal cards, a sunk and shaded state for illegal ones,
  and a selected card that rises with the words "Tap again to play" (or drag it up to play).
- **Motion, all in a flight layer that only draws:** cards deal from the dealer's deck to every seat, a played
  card travels from that player to its spot on the field, a finished trick gathers onto the winning card and
  is pulled to the winner, and the hand result waits until that has happened. Reduce Motion swaps every
  flight for a crossfade.

## Boundaries

- No engine, rules, bidding, save or computer-decision change. `Sources/CatchFive/` is not touched.
- Animation state lives in the view (`TableMotion`), derived from the match after each accepted action. A
  flight only hides the card it carries until it lands; the match is never waited on or rewritten.
- Undo, a new game or a restored game clear every flight at once. Backgrounding cancels nothing that matters:
  flights are decoration and the scheduler already pauses.
- No new dependencies or assets; everything is drawn in code.
