# Match authority tests

Run from the repository root with Godot 4.7.2:

```bash
godot --headless --path game --script res://tests/test_director.gd
```

The runner exits `0` on success and `1` when any assertion fails. These are real
GDScript tests running inside Godot, not a second implementation of the rules.
They exercise the same `TrialDirector` loaded by the playable prototype.

## Authority contract

`TrialDirector` is a rendering-independent `RefCounted` object. It decides match
phases, objective completion, Eye resource transactions, and victory. The world
layer must verify the physical interaction before calling a method: proximity,
carried mote identity, actual gaze occlusion, trigger overlap, and which survivor
was eliminated are world responsibilities. Calling an API directly is not a
network security boundary; the prototype has no multiplayer server.

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

### Three immutable seals

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

## Coverage and limits

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

The full bot run leaves a human-controlled Eye looking outward. It does not
teleport bots, alter their health or speed, mark objectives complete, or change
their navigation. The known seed `271126` completed the route in **52.18
simulated seconds** during verification. The runner prints each bot's task,
position, target, carrying state, and progress so a future failure is diagnosable.

The other cases deliberately place actors at known boundary-test locations and
call the production interaction methods to isolate those checks. They are not
claimed as a complete human playthrough. The suite disables audio output and
suppresses writing a last-match result; the application's normal save behavior
is unchanged.

## Survivor completion against the active Eye AI

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
