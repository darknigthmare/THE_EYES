# THE EYES v0.4 verification — The Third Observance

## Evidence status

[The v0.4.0 development release](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.4.0) was published on 26 November 2026
from [54937979ba9c](https://github.com/darknigthmare/THE_EYES/commit/54937979ba9c34d1ab41738daa64a1982020e1dd). All twelve gameplay suites and all twelve
native Windows startup cases passed in the [exact-build workflow](https://github.com/darknigthmare/THE_EYES/actions/runs/45888895728).
The final local measurements below are also reproduced by the feature and main
CI runs. Earlier release evidence remains separate from this v0.4 report.

## Scope under verification

The local Godot prototype now has nine trial subsets and four contracts: First,
Second, Third and Seeded Mix. Mix expands to 27 distinct bay mappings. A match
still requires three seals and the real north exit. Solo, human Eye and local
human-plus-four-AI Squad remain the only session types.

New systems are unique cell ownership, recoverable lantern charge, permanent
refuge lamps, continuous physical alignment/cutting, uniquely explainable rope
clues, three permanent cage stages, physical bell travel, two banked phrases,
one shared damper and real-location noise memory. Bots must observe the current
clue/phrase at the physical stand, abandon stale goals and use the same spatial
command checks as a human. Rescue takes priority over a held apparatus action.

## Evidence layers

| Layer | Establishes | Does not establish |
| --- | --- | --- |
| Rule assertions | Determinism, rejection, ownership, charge, banks, cooldowns, generator uniqueness and lifecycle | Physical reach, camera, usability |
| World fixtures | Actual scene, geometry rays, range, stationary holds, damage/pause, rescue priority and rematch cleanup | A complete adversarial human session |
| Unopposed bot routes | Preparation, all three seals and physical exit through every Mix mapping | Active Eye pressure or novice balance |
| Ordinary-input routes | Scoped full completion against the active Story Eye, using normal movement and commands | Every seed, difficulty, archetype or human skill level |
| Native renderer captures | Actual visual layout for staged menu and apparatus views | Full-match gameplay evidence or hardware frame rates |
| Native Windows startups | The exact exported executable reaches requested scenes and exits cleanly | Graphical Windows playthrough or driver qualification |

Physical fixtures deliberately stage actor positions and wounds to isolate an
edge case. Full route drivers do not inject position, health, speed, clocks,
Eye visibility or objective progress. They are informed scripts that know the
map and read public puzzle data after reaching its clue station.

## Integration corrections

Review found and corrected the following concrete issues before publication:

- A held E near a downed ally could previously rescue and work a lamp/rope in
  parallel. World eligibility now suppresses the trial action when rescue has
  priority, and physical overlap fixtures cover both apparatus types.
- A strong parent/child RefCounted ownership cycle retained trial helpers after
  rematch. WeakRef parent access and a fresh-match reference test cover cleanup.
- A clue changing during a bot's two-second observation could inherit the old
  observation time. The observed stage/phrase now identifies that interval;
  new evidence requires its own full observation.
- A human advancing the bell score while a bot travelled could make its saved
  target stale. The bot now checks the observed phrase and current public note
  before damping or striking.
- A cached carried-lantern model could show the first cell's number after a
  later pickup. The visible identity now follows the actual owned cell.

These cases have dedicated regressions in the Third world suite. Sound values
are attention-memory durations at the actual event location, not measured sound
intensity. An incorrect damped strike stays loud in both sound feedback and
its ten-second attention event.

## Current measured results

The final local integration run used Godot 4.7.2, fixed 60 Hz physics and
sequential headless execution with two CPU affinity. Editor import completed
with exit code 0. All twelve suites below exited with code 0, with no script
error, engine error or ObjectDB leak diagnostic in the retained final logs.

| Suite | Coverage | Result |
| --- | --- | --- |
| `test_director.gd` | 27 cases / 125 assertions | Passed |
| `test_world.gd` | 6 cases / 60 assertions | Passed |
| `test_survivor_route.gd` | 1 complete ordinary-input session | Passed |
| `test_trial_set.gd` | 23 cases / 2,118 assertions | Passed |
| `test_second_world.gd` | 35 cases / 279 assertions | Passed |
| `test_second_survivor_route.gd` | 1 complete ordinary-input session | Passed |
| `test_squad_state.gd` | 26 cases / 120 assertions | Passed |
| `test_squad_world.gd` | 23 cases / 234 assertions | Passed |
| `test_squad_route.gd` | 3 complete ordinary-input sessions | Passed |
| `test_third_trials.gd` | 31 cases / 1,780 assertions | Passed |
| `test_third_world.gd` | 23 cases / 162 assertions | Passed |
| `test_third_survivor_route.gd` | 2 complete ordinary-input sessions | Passed |

The eight assertion suites contain **194 cases and 4,878 assertions**.
The four route suites contribute **seven complete pressured sessions**, counted
separately from assertions. All route drivers use Story, Keeper and seed 271126.
The First and Second Solo sessions completed in 267.93 and 324.17 simulated
seconds, ending at 86 and 80 vitality. Second also recovered through one real
Second Sight sequence.

Second World includes **28 unopposed bot routes**: Second Observance and all
27 distinct Mix mappings. Every route earned its three selected seals and
exited, taking 31.52–97.65 simulated seconds. These routes deliberately
point the human Eye away; they do not claim adversarial balance.

| Third session | Completion time | Human travel | Human health | Human trial contribution |
| --- | --- | --- | --- | --- |
| Survivor | 328.88 s | 1087.86 m | 65 | 3 lamps / 3 rope stages / 8 correct bell strikes |
| Squad | 74.13 s | 203.14 m | 100 | 0 lamps / 2 rope stages / 6 correct bell strikes |

Development attempts exposed a Third Solo driver that kept holding under
attack, waited for excessive recharge and abandoned nearby objectives on
repeated long detours. The driver now follows the numbered refuge route,
budgets charge for the next trip, retreats from visible attacks and accepts a
bounded short approach while healthy. Clue observation stays on the same
stage/phrase throughout its two-second wait.
No production damage, clocks, speeds, seed or completed state were weakened for
this result. The final run above supersedes those failed development attempts.

[Machine-readable results and tested-source hashes](v0.4/GAMEPLAY_RESULTS.json)
and [complete final local logs](v0.4/GAMEPLAY_LOG.txt) preserve the measured
outcomes. [Six native captures and visual review](v0.4/VISUAL_REVIEW.md) document
staged 1280 × 800 views of the menu, Squad, Light, Strings, Chimes and manual.
They are visual fixtures, not full-match recordings. The Chimes support partly
occludes its score in that illustration; the carried cell's small model number
is covered by the world regression, not by the Light screenshot.

## Windows publication evidence

The [release workflow](https://github.com/darknigthmare/THE_EYES/actions/runs/45888895728) completed successfully from commit
`54937979ba9c34d1ab41738daa64a1982020e1dd`. Linux build job `140146378655`, native Windows job
`140147438124` and publication job `140147685765` all passed.

The unchanged exported executable passed the complete matrix:

| Session mode | First | Second | Third | Mix |
| --- | --- | --- | --- | --- |
| Human survivor | Passed | Passed | Passed | Passed |
| Human Eye | Passed | Passed | Passed | Passed |
| Local human + four-AI Squad | Passed | Passed | Passed | Passed |

Each case requested 240 frames, exited with code 0, emitted the exact requested
mode/contract readiness marker and contained no engine error diagnostic. The
[original Windows report](https://github.com/darknigthmare/THE_EYES/releases/download/v0.4.0/WINDOWS_SMOKE.json) is also retained
[byte-for-byte in the repository](v0.4/WINDOWS_SMOKE.json).

The [official Windows archive](https://github.com/darknigthmare/THE_EYES/releases/download/v0.4.0/THE_EYES_v0.4.0_Windows_x64.zip) contains **39,119,006 bytes**.
Its SHA-256 is:

`0b7bdb2ac5c3378b1404b25f60b7bfed6a111941dae787c88dbf664e3055b2b1`

The Windows report SHA-256 is:

`cee9c2155418a2cd33b745a17af9f91654f4ac3f928c47f3f9ceae0ef2dd833e`

A fresh download matched the GitHub asset hashes and official checksum file.
ZIP CRC, all 12 internal file hashes, the PE32+ AMD64 executable, the clean build
commit, Godot 4.7.2, the pinned export template and Windows resource versions
0.4.0.0 were verified. The report explicitly records **headless** execution and
`graphical_hardware_playtest: false`; startup is separate from interactive
Windows graphical qualification.

The [feature CI](https://github.com/darknigthmare/THE_EYES/actions/runs/45888531783) and
[build-commit main CI](https://github.com/darknigthmare/THE_EYES/actions/runs/45888895748)
also completed all twelve gameplay suites. Subsequent publication evidence edits
change documentation and catalogue metadata only; the shipped `game/` and
`tools/` bytes are retained for the final backup comparison.

## Remaining qualification

Graphical Windows interactive playthroughs, named-hardware frame-time targets,
novice usability and broad Standard/Ruthless balance remain unverified. There
are no remote multiplayer sessions, full realm maps, progression services or
compiled playable Unreal assets in this delivery. Sixteen catalogue trials and
the full production variants of the nine implemented subsets remain planned.
