# Gameplay verification — all nine suites

Run from the repository root with **Godot 4.7.2**. Import a fresh checkout before
running the nine suites:

```bash
godot --headless --path game --editor --import
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_director.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_world.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_survivor_route.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_trial_set.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_second_world.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_second_survivor_route.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_squad_state.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_squad_world.gd
godot --headless --path game --fixed-fps 60 --audio-driver Dummy --script res://tests/test_squad_route.gd
```

These are GDScript tests running inside the actual Godot engine and loading the
production rule modules or main scene. Assertion runners exit `0` on success
and `1` on failure. The three survivor-route runners likewise return a nonzero
status if normal inputs cannot complete their route or produce a recorded route
failure. The verification and release workflows also reject Godot error
diagnostics even if a process happens to return zero.

## Current v0.3 results

| Suite | Purpose | Verified result |
| --- | --- | --- |
| [test_director.gd](test_director.gd) | Match phases, Eye transactions, original objectives and outcomes | 27 cases; 125 assertions; zero failures |
| [test_world.gd](test_world.gd) | Original scene physics, occlusion, interactions and First bot completion | 6 cases; 60 assertions; zero failures |
| [test_survivor_route.gd](test_survivor_route.gd) | First survivor route against active Story Eye AI | Escape at 267.93 simulated seconds |
| [test_trial_set.gd](test_trial_set.gd) | Contract selection and alternate-trial authority | 23 cases; 2,098 assertions; zero failures |
| [test_second_world.gd](test_second_world.gd) | Alternate apparatus, shared physical commands and all mixed bot routes | 16 cases; 137 assertions; zero failures |
| [test_second_survivor_route.gd](test_second_survivor_route.gd) | Second survivor route against active Story Eye AI | Escape at 324.17 simulated seconds |
| [test_squad_state.gd](test_squad_state.gd) | Squad life, rescue, freeze and one recovery | 26 cases; 120 assertions; zero failures |
| [test_squad_world.gd](test_squad_world.gd) | Real Squad physics, rescue, healing, orders and perception | 23 cases; 234 assertions; zero failures |
| [test_squad_route.gd](test_squad_route.gd) | First/Second/Mix Squad sessions against active Story Eye AI | Three team escapes at 46.88 / 86.80 / 46.72 seconds |

The six assertion suites total **121 cases and 2,774 assertions**, with zero failures. The retained v0.2 subtotal is 72 cases / 2,420 assertions. The two complete solo
survivor routes and three complete Squad sessions are additional completion scenarios; their results are not
invented assertion counts. All times below are simulated gameplay time, not
execution time or a hardware performance benchmark. The [v0.3 verification
report](../../docs/qa/V0_3_VERIFICATION.md) records exact route outcomes and
separates source, rendering, Windows, and Unreal evidence.

## Shared authority contract

`TrialDirector` is a rendering-independent `RefCounted` object. It decides match
phases, objective completion, Eye resource transactions, and victory. The world
layer must verify the physical interaction before calling a method: proximity,
carried mote identity, actual gaze occlusion, trigger overlap, and which survivor
was eliminated are world responsibilities. Calling an API directly is not a
network security boundary; the prototype has no multiplayer server.

`TrialSet` adds the alternate-trial state behind the same match lifecycle. The
three contracts are `first`, `second`, and `mix`; each activates exactly one
trial in each of the three slots. Legacy slot keys `silent`, `echoes`, and
`relay` remain stable even when their active trials are `vault`, `ritual`, and
`clock`. The scene's shared `trial_world.gd` path validates actor membership,
physical reach, line of sight, objective cargo, and real ritual occupancy before
submitting alternate-trial commands. Neither domain module alone establishes
physical reach or an online security boundary.

The world must report each survivor elimination only once. The authority clamps
the aggregate population and stops accepting reports after the match ends, but
does not own per-actor identity. It likewise assumes `deliver_mote()` corresponds
to one consumed physical mote. Future authoritative networking must validate the
actor/object identifiers before these calls.

### Time and phases

| Difficulty | Preparation | Hunt | Escape |
| --- | ---: | ---: | ---: |
| Story | 8 s | 600 s | 90 s |
| Standard | 8 s | 480 s | 65 s |
| Ruthless | 8 s | 360 s | 50 s |

Preparation protects participants: powers, elimination, escape, and objective
progress are rejected. Preparation does not consume hunt time. A frame crossing
the preparation boundary correctly spends its remainder in the hunt. For
example, `step(10)` on a new Standard match leaves `time_left = 478`.

All three seals start a fresh escape window. `time_left` remains the last hunt
value during escape; the HUD must display `escape_left` instead. Completing the
third seal with one second of hunt time remaining still grants the full escape
window. This deliberate last-chance rule is independent of difficulty.

The first valid escape immediately wins the round for the survivor team. All
survivors eliminated or either active clock reaching zero wins for the Eye.
The terminal phase freezes resources, clocks, and objectives, and emits exactly
one result. Negative, zero, infinite, and NaN frame durations are ignored.

### Eye transactions

| Power | Energy | Cooldown | Requires verified sight |
| --- | ---: | ---: | --- |
| Trap | 25 | 4 s | Yes |
| Mark | 20 | 6 s | Yes |
| Summon | 45 | 16 s | Yes |
| Blink | 8 | 2 s | No |

Energy starts at 100, regenerates at 4 per live second, and caps at 100. Terror
builds at 0.7 per live second and caps at 100; the world displays it as telemetry. It does not modify AI, damage or abilities.

Rejected actions never spend energy or start a cooldown. `switch_socket()`
accepts only indices 0–3 and rejects the current socket without a cost. The
physical layer handles the visible blink transition and trap warning period.

### First contract: three immutable seals

- **Silent Countdown:** three accepted deliveries complete the seal. Later
  delivery calls return `false`; completed progress is never removed.
- **Trial of the Echoes:** a seeded permutation of symbols 0–3 supplies four
  distinct symbols. Correct inputs advance; an incorrect valid symbol resets
  the current attempt and increments `echo_errors`. An out-of-range input is
  ignored without a penalty. Completed sequences cannot be reset by later input.
- **Clockwork Relay:** `relay_progress` is normalized from 0 to 1. Twelve net
  seconds of holding complete it. Four and eight seconds lock checkpoints at
  one-third and two-thirds. Releasing decays unbanked progress at `1/24` per
  second, stopping at the last checkpoint. Completion is permanent. The caller
  must pass `actively_holding = false` on released ticks if decay is desired.

### Events

The signal is `event_raised(kind: String, payload: Dictionary)`.

| Kind | Payload keys |
| --- | --- |
| `phase` | `phase`, `previous` |
| `power` | `power`, `cost`, `cooldown`, `energy` |
| `delivery` | `delivered`, `required` |
| `echo_correct` | `progress`, `required` |
| `echo_error` | `errors`, `progress` |
| `seal` | `seal`, `completed`, `required` |
| `result` | `winner`, `reason`, `escaped`, `alive` |

Result reasons are `first_escape`, `all_eliminated`, `hunt_timeout`, and
`escape_timeout`. `phase: ended` is emitted before `result` so views may stop
input before presenting the final panel. A successful socket change emits the
`blink` power event before assigning `eye_socket`; world code should update its
camera after `switch_socket()` returns `true`.

## Original director coverage and limits

The 27 test cases cover seeded puzzles, phase boundaries, invalid inputs,
transactional costs, line-of-sight refusal, cooldown boundaries, socket changes,
permanent objectives, relay checkpoints, first escape, each defeat path, event
ordering, terminal idempotence, and replay reset.

The domain tests do not exercise 3D geometry. The separate world suite below
covers actual movement, occlusion, physical interactions, and bot completion.
Neither suite establishes that audio is audible, controls feel good, or a
rendered HUD is legible; those require rendered playtesting.

## World integration suite

Import resources on a fresh checkout, then run the actual scene with fixed
physics timing:

```bash
godot --headless --path game --editor --import
godot --headless --path game --fixed-fps 60 --audio-driver Dummy \
  --script res://tests/test_world.gd
```

This suite creates the real main scene and exercises its world-facing methods,
`CharacterBody3D` movement, and `PhysicsDirectSpaceState3D` rays. Its six cases
include 60 assertions:

| Scenario | Evidence checked |
| --- | --- |
| Occlusion | Central obelisk and perimeter block real rays; west lane stays clear; survivor camera is active. |
| Eye traps | Four physical survivors appear; a trap behind geometry inside the view cone is rejected without a cost; a visible trap has a harmless warning and hits once. |
| World objectives | Distance-gated pickup and delivery consume three distinct motes; carrying noise gives a location clue without directly increasing gaze; Echo panel accepts the sequence; held Relay interaction supplies the third seal; the physical exit stays gated until then. |
| Elimination | Lethal damage reduces the population once; repeated damage and marks on dead survivors are rejected. |
| Shadow collision | A summoned `CharacterBody3D` driven directly toward the central obelisk stops against its real wall. |
| Full bot run | Four unchanged bots navigate the chamber, complete all three trials, and hold the exit within 200 simulated seconds. |

The full First bot run uses Standard and leaves a human-controlled Eye looking
outward. It does not teleport bots, alter their health or speed, mark objectives complete, or change
their navigation. The known seed `271126` completed the route in **52.95
simulated seconds** during verification. The runner prints each bot's task,
position, target, carrying state, and progress so a future failure is diagnosable.

The other cases deliberately place actors at known boundary-test locations and
call the production interaction methods to isolate those checks. They are not
claimed as a complete human playthrough. The suite disables audio output and
suppresses writing a last-match result; the application's normal save behavior
is unchanged.

## First survivor completion against the active Eye AI

```bash
godot --headless --path game --fixed-fps 60 --audio-driver Dummy \
  --script res://tests/test_survivor_route.gd
```

This separate scenario drives an ordinary **Keeper survivor on Story difficulty**
with seed `271126`. It uses normal input actions and first-person view steering;
the production `CharacterBody3D` controller performs movement and collisions.
The Eye AI, physical traps, shadows, gaze, health, stamina, cooldowns, and match
clocks remain active. The driver does not teleport the survivor or modify health,
speed, time, or objective state.

The driver knows the chamber layout, chooses actual ray-occluded cover, responds
to trap warnings and approaching shadows, and sprints when a pursuing shadow
would outrun crouched movement. It observes the complete Echo sequence before
entering the four symbols through the real input handler. It holds the actual
Relay and exit interactions, and can use Keeper's normal cooldown-limited heal.
This is a reproducible completion check by an informed input driver, not a
human usability or difficulty study.

### Verified result

| Milestone | Simulated time |
| --- | ---: |
| Relay seal | 20.92 s |
| First physical mote delivered | 55.15 s |
| Second physical mote delivered | 71.93 s |
| Third physical mote delivered | 196.12 s |
| Echo seal after the full observation | 229.73 s |
| Successful held exit | **267.93 s** |

The survivor escaped with **86 vitality**, two gaze wounds, one ordinary Keeper
heal, and no use of Second Sight. The conservative route took several cover
detours, so this elapsed time should not be treated as the optimal route or a
target for new players. The scenario fails with a nonzero exit code if it cannot
escape within 300 simulated seconds; it prints final state and any movement
stall location.

This check exposed two issues during development: a carried-mote footstep was
directly increasing gaze, and cover selection could mistake the current view
cone for physical occlusion. The production fixes preserve audible clues while
requiring actual gaze for gaze damage, and choose cover using real obstruction.
Story's tracking/gaze pressure was also tuned in production. Tests exercise
those ordinary game rules; no test-only gameplay concessions were introduced.

## Alternate-trial domain suite

`test_trial_set.gd` runs 23 cases and 2,098 assertions against the actual
`TrialSet` and its integration with `TrialDirector`. It covers deterministic
First/Second/Mix selection, all eight possible mixed configurations, separate
seed streams, preparation/end rejection, actor command limits, unique cargo
ownership, configuration reset, retirement of old authority objects, and
three-seal victory through the normal director.

| Trial | Rules and regression coverage |
| --- | --- |
| Memory Vault | Four distinct targets among six relic IDs; four indexed cradles; exact target validation; wrong deposits retain cargo; accepted cradles remain permanent; release recovers ownership. |
| Ritual Circle | Five seeded vessels; one ember; pair banks at two and four; rollback of only the unbanked prefix; repeated lit-vessel input is harmless; eight continuous occupied seconds; an empty ring resets only the hold. |
| Clock Room | Three integer hands modulo six; paired A+B/B+C/C+A effects; exact inverse controls; global 0.25-second command limit; reset; current-hand validation at the explicit seal press; solver calls do not mutate the puzzle or award completion. |

Clock generation uses bounded breadth-first distance from the target. There are
108 reachable configurations for a given target, and 48 have shortest distance
four. The seeded generator chooses among those 48 starts. The test independently
enumerates all legal move sequences of zero through three turns and excludes
their states for **129 generated seeds**: 0–127 plus 271126. It then obtains and
executes legal solutions before confirming the seal. The graph construction
sets the four-turn minimum; this seed set is regression coverage for the
implemented generator, not a claim that every possible seed was sampled.

Domain fixtures deliberately issue commands directly to isolate authority
behavior. Physical eligibility is covered separately below.

## Alternate apparatus and mixed physical routes

`test_second_world.gd` instantiates the real main scene. Its **16 cases and 137
assertions** combine seven isolated physical checks with nine complete bot
routes: Second and one seed for every distinct Seeded Mix configuration.

The isolated checks cover distant and inactive action rejection, nearest-command
selection, geometry occlusion, unique relic pickup and return, invalid/dead
actors, exclusion between legacy mote and alternate cargo, true floor-level
ritual occupancy, hold reset, reversible physical clock controls, and the
explicit central confirmation. Fixtures place actors deliberately for those
boundary checks; they are not described as complete movement playthroughs.

The nine complete routes use ordinary bot navigation and physics from
preparation through three selected seals and the real exit. The human Eye looks
outward and takes no power actions. Actor position, health, speed, navigation,
clocks, and trial progress receive no route-driver overrides. Every route below
escaped with zero wounds:

| Contract | Seed | Simulated completion time |
| --- | ---: | ---: |
| Second | 271126 | 81.08 s |
| Seeded Mix | 0 | 46.03 s |
| Seeded Mix | 1 | 46.03 s |
| Seeded Mix | 2 | 88.43 s |
| Seeded Mix | 5 | 52.95 s |
| Seeded Mix | 6 | 84.03 s |
| Seeded Mix | 7 | 52.95 s |
| Seeded Mix | 8 | 89.02 s |
| Seeded Mix | 29 | 84.20 s |

The suite discovers distinct mappings from seeds rather than assuming adjacent
seed values produce different combinations. It checks that every route has all
three selected seals before escape, records the active mapping and final
apparatus state, and prints per-bot task/location diagnostics on failure. A
route that fails to escape within 450 simulated seconds fails the suite. These
unopposed routes establish physical connectivity and command reachability;
pressure from an active Eye is exercised by the survivor routes.

## Second survivor completion against the active Eye AI

`test_second_survivor_route.gd` extends the same normal-input driver used by the
First route. It selects **Keeper, Story, seed 271126, Second**. The active Eye,
gaze, physical traps, shadows, movement, collisions, ordinary healing,
cooldowns, health, and match timers remain enabled. The informed driver reads
the available clues, plans legal Clock actions, and walks to the actual controls,
relics, cradles, ember, vessels, and exit. It does not replace those actions with
forced objective state or teleportation.

The verified run escaped at **324.17 simulated seconds** with **80 vitality**,
**11 wounds**, **one successful Second Sight recovery**, and **four legal Clock
turns** followed by central confirmation. Recovery used the normal timed input
challenge and its ordinary health/protection result. During the final ritual
hold, the driver moved around the central pedestal while remaining inside the
2.8 m radius; continuous occupancy does not require standing still. Leaving the
ring would reset only the current eight-second hold, preserving lit vessels.

The runner fails if it cannot escape within 570 simulated seconds or records a
route failure. This is a reproducible pressured completion check for one
informed Keeper on Story. It does not establish balance for a new player, every
archetype, Standard/Ruthless difficulty, or an expert human Eye.

## Rendering and platform gates

`capture_ui.gd` is a separate visual-inspection helper requiring an actual
display and renderer. Its staged apparatus views position the camera for
inspection and are clearly separated from the movement routes above. A
headless suite cannot establish HUD legibility, audible sound, graphical-driver
compatibility, or usable controls.

Both repository workflows require all nine gameplay suites. The release workflow
then exports the exact source build and requires native Windows **headless
startup** for Solo Survivor, Eye and Squad under each of First, Second, and Seeded Mix.
Those nine executable-startup results, archive SHA-256, source revision, and
engine version belong in `WINDOWS_SMOKE.json`. The v0.3 platform gate remains pending at this source-candidate snapshot. It remains distinct
from a graphical Windows playthrough, which is untested. See the
[verification report](../../docs/qa/V0_3_VERIFICATION.md) and
[release workflow](../../.github/workflows/release-windows.yml) for the exact
required evidence.


## Squad life authority

`test_squad_state.gd` exercises `EyesSquadState`: **26 cases, 120 assertions,
zero failures**. It checks five-member configuration, foreign/self/duplicate
identifiers, first fall, 35-second bleedout, six-second exclusive rescue,
interruption reset, one recovery per member, subsequent elimination, simultaneous
rescues, helper loss, immediate all-downed wipe, atomic events, nonfinite durations,
freeze semantics and rematch isolation. Timed boundary cases step at 60 Hz.

The state module has no position, health-controller or rendering knowledge.
`test_squad_world.gd` separately checks the real scene and physical commands:
**23 cases / 234 assertions / zero failures**. It covers population and unique
names, downed objective eligibility, actual walls and distance limits, release,
movement, damage and pause interruption, exclusive reservations, the six-second
hold/protection lifecycle, single elimination/wipe, Keeper selection and wall
rejection, orders, escape priority, real ally spectator viewpoints, rematch and
visible-only Eye target selection.

Its staged AI rescuer walks 7.64 m along a nine-point AStar path, then finishes the
continuous rescue; total travel plus hold is 7.50 s. The revived human has 35 HP and
normal protection. Actors are deliberately staged and wounded through the real
world boundary, so this is physical rescue evidence, not a full pressured match.

The suite also calls the production main physics update: a human plus four
allies gives exactly 0.15 Relay progress in one second at the 1.8× cap. Human-only
holding produces 1/12 per second without extra decay from the allied pass.

## Three complete Squad sessions

`test_squad_route.gd` extends the existing normal-input route driver. It starts
one human Keeper and four AI allies, chooses Story and seed 271126, and runs all
three contracts against the active AI Eye. It sends Follow, Hold and Work through
ordinary input events, physically moves the human, operates the actual south
mechanism, uses normal cooldown-limited healing, and attempts the north exit.
The other survivors independently walk to and perform their own trial tasks.

No route input changes health, speed, actor positions, clocks, seals, AI perception
or trial progress. The driver can wait for legitimate rescue or spectate after
elimination, but those mechanisms were not needed in these three final runs.
Isolated rescue fixtures are reported separately; successful ordinary routes do
not prove that every rescue scenario is survivable.

| Contract | Team result | Simulated duration | Human final HP | Team wounds | Orders |
| --- | --- | ---: | ---: | ---: | ---: |
| First | Survivors escaped | 46.88 s | 33 | 4 | 3 |
| Second | Survivors escaped | 86.80 s | 20 | 6 | 3 |
| Seeded Mix | Survivors escaped | 46.72 s | 100 | 1 | 3 |

Every run broke all three selected seals. This single informed driver and seed
establish reproducible completion of these configurations, not difficulty balance,
novice usability, every Mix seed, or guaranteed survival on Standard/Ruthless.

During integration, the first Second-contract attempt exposed allies remaining
beside visible pursuing shadows while trying to rescue. The production Squad
AI now checks nearby visible shadows, selects a physically clear evasive step,
cancels any rescue hold, and resumes a legitimate goal when the immediate threat
passes. The Eye still has its normal powers and damage. Solo and human-Eye bot
behavior retain the previous implementation and pass their original routes.
