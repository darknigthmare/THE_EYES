# Gameplay verification — seventeen suites for v0.5

Use standard **Godot 4.7.2** and run from the repository root. Import a fresh
checkout before running any scene-based tests:

```bash
godot --headless --path game --editor --import
```

## Required suites

| Script under `game/tests/` | Evidence |
| --- | --- |
| `test_director.gd` | Match phases, timers, original seal authority and Eye command rules |
| `test_world.gd` | Original physical arena and unopposed bot completion |
| `test_survivor_route.gd` | Complete First Solo against active Story Eye through ordinary input |
| `test_trial_set.gd` | Deterministic selection, existing alternate rules and expanded Mix27 registry |
| `test_second_world.gd` | Existing physical alternate-trial cases; Second and all 27 distinct mixed bot routes |
| `test_second_survivor_route.gd` | Complete Second Solo against active Story Eye through ordinary input |
| `test_squad_state.gd` | Downed/bleedout/rescue authority, reservations, interruption and team wipe |
| `test_squad_world.gd` | Actual rescue movement, walls, Keeper targeting, orders, spectating and Relay integration |
| `test_squad_route.gd` | First, Second and current Mix Squad sessions against active Story Eye |
| `test_third_trials.gd` | Cell ownership/charge, continuous holds, unique rope clues, phrase banking and damping |
| `test_third_world.gd` | Real Third apparatus, range/LOS/holds, rescue priority, clue epochs, cargo cleanup and rematch |
| `test_third_survivor_route.gd` | Complete Third Solo and Squad sessions against active Story Eye |
| `test_practice_state.gd` | Single active bay, nine completions, seeded parity, retired authority and no competitive result |
| `test_practice_records.gd` | Bounded per-archetype records, validation, preserved future schema and file recovery |
| `test_practice_ui.gd` | Real workshop controls, per-role notebook, field manual, result and visible save errors |
| `test_practice_world.gd` | Physical admission, inactive bays, pause/focus/held-input cleanup, retries and normal-match return |
| `test_practice_routes.gd` | Nine individual drills completed through ordinary input and physics, with no state injection |

Run any suite using the same fixed-step invocation as CI:

```bash
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_third_trials.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_third_world.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_third_survivor_route.gd
```

The two workflows enumerate all seventeen scripts explicitly and reject engine
errors even when Godot returns zero. Each process has a bounded timeout.
Measured counts and outcomes are in the [v0.5 verification report](../../docs/qa/V0_5_VERIFICATION.md).
Historical counts belong to their [v0.2](../../docs/qa/V0_2_VERIFICATION.md) and
[v0.3](../../docs/qa/V0_3_VERIFICATION.md) reports and are not reused as proof for
changed source.

## Evidence boundaries

**Domain assertions** invoke deterministic rule objects without geometry. They
can prove ownership, rejection, banking and generation invariants. They cannot
prove collision, visibility, a working camera or an accessible route.

**Physical fixtures** instantiate the actual scene, deliberately position actors
and sometimes apply wounds to reproduce an edge case. They run real range,
architecture rays, controller and authority paths. These are isolated tests,
not complete pressured matches. The Third tests specifically cover a downed ally
beside a lamp/rope, so held E cannot rescue and work a trial at the same time.
They also cover clue changes during observation and release of old helper/domain
instances on rematch.

**Unopposed bot routes** start ordinary Eye-mode matches and leave the human Eye
looking outside the chamber. Bots navigate and interact normally from the
preparation phase until three seals and an actual escape. They receive no
position, health, speed, timer or objective overrides. The Mix runner discovers
all 27 distinct bay tuples rather than assuming 27 seeds are distinct. Every tuple
must complete within 450 simulated seconds. This establishes reachability and
physical task support, not adversarial balance.

**Active-Eye survivor routes** use normal input, camera steering, the real
CharacterBody controller, ordinary class powers, real hazards and the normal
match clocks. Their informed driver knows the map and reads available public
puzzle data after visiting the clue station. It never changes health, positions,
clock budgets, completed objectives or Eye perception. First/Second Solo,
First/Second/Mix Squad and Third Solo/Squad are separate sessions. A victory
through ally escape is valid Squad behavior; the ledger identifies the human's
own work. Their times are simulation observations, not expected novice duration
or hardware frame-rate measurements.

## Native presentation

`capture_workshop.gd` stages eight v0.5 views: menu, catalogue, practice HUD with
the guide open and folded, manual, completion, catalogue save error and result
save error. The folded-guide view checks that all four Strings tags are exposed;
the error views check the visible notebook warning in both entry and completion.
`capture_ui.gd` preserves the earlier capture fixtures. `capture_third.gd`
prepares the current menu, Squad, Light, Strings, Chimes and manual for actual
renderer inspection. These helpers deliberately stage camera and scene states.
Screenshots are visual evidence and are never counted as input-only completion.
Native software-renderer output does not establish a hardware performance target.

## Windows publication gate

The release workflow imports the exact revision, passes all seventeen gameplay
suites, exports with the pinned official Windows template and transfers the
unchanged archive to a native Windows runner. The executable must pass **21
headless startup cases**: Solo Survivor, Eye and Squad under First, Second,
Third and Seeded Mix, plus each of the nine Workshop drills. Every result must identify the requested contract and
actual session mode (and selected trial for practice), return zero and contain no engine diagnostics.

`WINDOWS_SMOKE.json` schema 3 records the source commit, archive SHA-256, Godot version,
Windows platform and each case. It explicitly reports headless mode and that a
graphical hardware playtest has not been performed. The final publication job
rechecks the report and hashes before creating a new versioned prerelease.
Existing releases and tags are preserved.
