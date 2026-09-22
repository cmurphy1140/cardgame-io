# Ideas held back from the round-1 review

17 September 2026. Produced alongside `design-review.md` (repo root while round 1 is open). START-HERE.md asks for ideas not needed for 1a to go into `docs/ideas.md` as one line each; that file is coordinator-owned, so they wait here until Connor decides which, if any, to move. Nothing here is authorised.

- Passwordless player picker (tap your face), one data folder per card via GameModel.loadDefault(in:), with a player id on MatchRecord so each family member keeps their own history.
- Favourite drink as an unmasked flavour line on the player card, never a password.
- Paper restyle of LoginView and IntroView after the exit condition, keeping today's single name field, face and strength picker.
- Full-size licence as a sheet opened from the menu's player card, printing only stored fields, plus an optional joined date on Settings backfilled from the earliest MatchRecord.date.
- CLASS standing derived from Statistics.wins once Connor sets the thresholds.
- Paper restyle of the Statistics sheet that keeps Average margin, the agreement metric under R30's 'Matched suggested plays' label, and the Recent list.
- Nine-and-out count on Statistics: only partly derivable from stored final scores (a winner under 25 implies a nine-and-out finish, but not every nine-and-out ending leaves one), so a MatchRecord field is the reliable route; pin the engine behaviour with a test either way.
- Optional per-match tallies on MatchRecord (Fives caught off the bidder, bidders set, nine-and-out, clean sweeps) labelled 'since <date>'; needs Connor's decision on whether plan:53's no-new-save-format rule covers history.json.
- Achievements derived from history (ten computable badges, Clean Sweep reworded to nine points), filed beside ideas E.5; pins only once a card shows endorsements.
- Drink and former-job bios for Hazel, Otto and Rue in Settings' Opponents section.
- Chips, wallet, shop and the seven-bot roster as plug-and-pitch ideas; if ever built, a balance derived from history minus purchases, with Undo kept free (plan:52).
- Per-seat computer strength for mixed Easy/Standard tables (engine and match-record change).
- Pass-and-play for plug-and-pitch: human-seat roles in the save, a handoff pause reason, a deliberate tap-to-reveal with no countdown lockout, and no auto-play timers.
- Save per-match difficulty with the match so menu Settings cannot silently change a saved match (the R32 gap; engine track).
- 'Flag this hand' in the Hand review toolbar, sharing the replay JSON and a note through ShareLink, after issue #53 lands.
- Engine helper returning the replay through the last completed hand, so a hand can be flagged mid-hand without leaking cards.
- 'What's in the works' Settings row opening ExplainerView(initial: "roadmap"), labelled as delivery history.
- Paper Settings as a scrolling sheet: HIM/HER cut, opponent names kept, rows stacked at accessibility sizes.
- Night-paper palette with its own contrast audit; paper then follows the system Light/Dark setting rather than an in-app toggle.
- Run scripts/contrast-sample.swift across every contrast-audit pair in CI, as LOOP asks, once the manual pixel sampling in review Q6 earns it.
- CI job for the Large/XXXL/AX2 simulator capture script, only if the manual script earns it.
- Deterministic house-advice tip chosen by day of year, so captures at three sizes differ only in size (cut from the review's cheap wins for length).
- Version string read from the bundle (project.yml MARKETING_VERSION is 1.0), shown in Settings or the explainer instead of the drawn '3.1 paper'.
- Licence 'printed' motion and a matched-geometry hero from menu card to licence sheet, after the licence sheet ships.
- Stamp-landing spring reusing the hand-end haptic, fading under Reduce Motion, with type size capped.
- Resume line reworded to lead / trail / level with negative scores handled.
- @SceneStorage drafts for a half-typed card name or flag note; restore nothing else.
- Suit watermarks and the c5 badge only if Connor misses them after seeing 1a on the phone.
- Rule that every paper signal carries a word or shape, never crimson and green rings alone on seat tiles (Differentiate Without Colour).
- Name a Murphy's Law strength only once the engine track ships a stronger player.
- export-docs.py --app mode that copies changed Markdown without re-rendering every Mermaid diagram.
