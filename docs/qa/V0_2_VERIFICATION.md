# Verification — THE EYES 0.2.0

**Evidence snapshot: 26 November 2026. Engine: Godot 4.7.2.** The v0.2 source
scenes, gameplay authority, physical bot routes, and both normal-input survivor
routes have passed their checks. Six actual renderer captures have been
visually inspected after correcting overlapping world labels and manual text.
All six native Windows headless startup cases have also passed for the published
archive. A graphical Windows playthrough remains untested.

This report concerns the local Godot implementation: one connected observatory,
two roles, six trial subsets with three active per round, and First, Second, or
Seeded Mix contract selection. Full production trial variants, online play, and
compiled UE5 gameplay remain outside the delivered source implementation. The
[v0.1 report](VERIFICATION.md) is preserved as historical evidence; its timings
and three-trial catalogue describe that earlier build.

## Results by gate

| Gate | Evidence | Status at this snapshot |
| --- | --- | --- |
| Source import and playable scenes | Actual Godot import/startup and scene-based integration runs | Passed |
| Original match authority | 27 cases; 125 assertions | Passed; zero failures |
| Original physical world | 6 cases; 60 assertions | Passed; zero failures |
| Alternate-trial authority | 23 cases; 2,098 assertions | Passed; zero failures |
| Alternate physical world | 16 cases; 137 assertions | Passed; zero failures |
| First survivor versus active Story Eye | Normal inputs, physics, visible objectives and ordinary abilities | Passed; 267.93 simulated seconds |
| Second survivor versus active Story Eye | Normal inputs, three physical alternate trials and legitimate recovery | Passed; 324.17 simulated seconds |
| First unopposed physical bots | Four ordinary AI survivors and a human Eye taking no power actions | Passed; 52.95 simulated seconds |
| Second and all eight mixed bot configurations | Nine complete routes with three seals and a real exit interaction | Passed; all zero wounds |
| Actual rendered presentation | Six screenshots captured from Godot and inspected | Passed; final captures visually inspected at 1280 × 800 |
| Native Windows exported executable | Required six role × contract headless startup cases | Passed; six cases, exit zero and no engine error diagnostics |
| Graphical Windows playthrough | Interactive executable, real graphical drivers and complete match | Untested |
| Catalogue and bible | JSON, source-title traceability, relative links, exact implemented boundaries | Passed; 25 designs, six implemented subsets, three active per match |
| UE5 foundation | Blueprint implementation recipes, project foundation and data schemas | Specification/foundation only; Unreal Editor gameplay not compiled or run |

The four counted suites total **72 cases and 2,420 assertions**:
125 + 60 + 2,098 + 137. Two additional survivor completion scenarios exercise
normal inputs against an active Eye. They are not added to the assertion total
as invented test counts. The [six-suite guide](../../game/tests/README.md)
contains exact commands, test responsibilities, and failure limits.

These checks execute production GDScript and the actual Godot scene. Domain
fixtures isolate state transitions; physical fixtures use real collision and
ray queries. Complete routes are separately identified below. Simulated route
time is not a wall-clock benchmark, a hardware FPS measurement, or a suggested
completion target for a new player.

## Contract and trial correctness

| Contract | Northwest slot | Northeast slot | South slot |
| --- | --- | --- | --- |
| First (`first`) | Silent Countdown | Trial of the Echoes | Clockwork Relay |
| Second (`second`) | The Memory Vault | The Ritual Circle | The Clock Room |
| Seeded Mix (`mix`) | Silent or Vault | Echoes or Ritual | Relay or Clock |

Exactly one apparatus is active in each bay and exactly three seals open the
exit. All eight mixed configurations are covered by both domain completion and
physical bot routes. Inactive trial actions, props, and cargo cannot provide
extra progress. Existing legacy slot keys remain stable while public prompts
identify the selected trial. Preparation and ended matches reject gameplay
commands; ownership cleanup may still safely release carried cargo.

The Memory Vault tests exact relic identity at each indexed cradle, unique
ownership, permanent accepted deposits, wrong-deposit cargo retention, and
recovery of required objects. The Ritual Circle tests its shared ember, five
spatial vessels, permanent pair banks at two and four, harmless duplicate lit
inputs, rollback of only unbanked progress, and eight continuous occupied
seconds. World checks verify real eligible actor occupancy at floor level and
reset the final hold when the ring is empty.

The Clock Room uses modulo-six integer hands and paired lever effects A+B,
B+C, and C+A. Forward/reverse operations are exact inverses. Bounded breadth-first
generation chooses among 48 states at shortest distance four from the target,
within a 108-state reachable graph. Every generated start consequently requires
four optimal legal turns, plus the separate central seal press. Tests
independently exclude all zero-, one-, two-, and three-turn solutions for
**129 seeds** (0–127 and 271126), execute valid solutions, and verify that the
solver itself does not mutate state or complete a trial.

Detailed implementation boundaries and production differences are in
[Prototype contracts](../bible/12_PROTOTYPE_CONTRACTS.md). There are no new
bespoke Eye powers, detached completion menus, fabricated annexes, or completed
production realms in this expansion.

## Complete physical bot routes

The original First bot route selects Standard; the nine alternate-world routes
select Story. Each leaves the human Eye looking outward without using powers.
Four normal AI survivors navigate using production physics and pathfinding. They perform the selected trials through the shared
physical dispatcher, obtain all three seals, and interact with the real exit.
The first successful escape resolves the round; the result does not mean all
four actors must cross the door.

The route driver does not teleport actors, boost health or speed, alter the
match clocks, replace paths, or force progress. Isolated boundary fixtures in
the same suites deliberately place actors for individual checks; those fixtures
are not the complete routes reported here.

| Suite / contract | Difficulty | Seed | Simulated escape time | Wounds |
| --- | --- | ---: | ---: | --- |
| Original world / First | Standard | 271126 | **52.95 s** | Not asserted by this check |
| Alternate world / Second | Story | 271126 | 81.08 s | 0 |
| Alternate world / Seeded Mix | Story | 0 | 46.03 s | 0 |
| Alternate world / Seeded Mix | Story | 1 | 46.03 s | 0 |
| Alternate world / Seeded Mix | Story | 2 | 88.43 s | 0 |
| Alternate world / Seeded Mix | Story | 5 | 52.95 s | 0 |
| Alternate world / Seeded Mix | Story | 6 | 84.03 s | 0 |
| Alternate world / Seeded Mix | Story | 7 | 52.95 s | 0 |
| Alternate world / Seeded Mix | Story | 8 | 89.02 s | 0 |
| Alternate world / Seeded Mix | Story | 29 | 84.20 s | 0 |

The First route's **52.95 s** is the current v0.2 result. The **52.18 s** in the
historical v0.1 report remains accurate for that previous build and is not
reused as v0.2 evidence. The nine alternate-world routes cover Second plus one
seed for every distinct mixed mapping. They establish connected physical tasks
and bot command reachability under an idle Eye; active pressure is assessed
separately by the survivor scenarios.

## Survivor routes against the active Eye

Both scenarios select **Keeper, Story, seed 271126**. They use normal movement
and interaction inputs, first-person view steering, production collision, real
objective positions, and ordinary cooldown-limited abilities. The Eye AI,
gaze, traps, shadows, health, stamina, and match clocks stay active. The drivers
do not override position, health, timers, or trial progress.

| Contract | Simulated escape time | Remaining vitality | Wounds | Successful Second Sight recoveries | Clock turns |
| --- | ---: | ---: | ---: | ---: | ---: |
| First | **267.93 s** | **86** | **2** | **0** | Not applicable |
| Second | **324.17 s** | **80** | **11** | **1** | **4**, followed by central confirmation |

The First driver consumes and delivers three distinct physical motes, observes
the full Echo pattern, enters its symbols through the ordinary handler, charges
the actual Relay, and holds the exit. Its recorded run uses one ordinary Keeper
heal and no Second Sight recovery.

The Second driver walks between the Clock controls, observes the Vault desk,
retrieves the correct relics and deposits them into their individual cradles,
then lights the five vessels and completes the real ritual occupancy hold.
Its recovery succeeds through the normal timed Second Sight inputs and receives
the ordinary return-health/protection effect. During the final ritual stage it
moves around the central pedestal while staying within the ring's 2.8 m radius.
The hold requires continuous occupancy, not a stationary survivor. If the actor
leaves, only the final eight-second hold resets; the lit vessels remain banked.

These drivers are informed: they know the map and correctly read available
clues. Their completion demonstrates a viable pressured route for the tested
character, seed, difficulty, and source build. It does not establish novice
usability, optimal routing, all-archetype balance, Standard/Ruthless completion,
or fairness against an expert human Eye.

## Development corrections covered by this evidence

The bot path follower now handles the final short segment from its grid path to
the actual fractional apparatus target when that physical sightline is clear.
This resolves a stall in which a bot stopped near the rounded cell but outside
interaction reach. Complete Second and all mixed routes exercise ordinary
travel through this corrected final segment.

Clock generation now uses true shortest-path distance rather than the number
of scrambling operations, since reversible moves could cancel into a trivial
start. The independent short-solution exclusion guards the intended four-turn
minimum. Ritual instructions now explicitly tell the player to keep moving
inside the ring, matching the occupancy rule and the successful active-Eye
route. Existing v0.1 gaze, cover, and physical interaction regressions remain
in the six required suites.

## Actual rendered captures

The following images were captured from the real Godot renderer and inspected.
They are presentation evidence; the apparatus close-ups deliberately stage a
camera/actor position and do not replace the separate physical route tests.
World clues were separated from vessel/cradle labels; the Clock levers now
show their coupled effects clear of the clock face. The manual uses a container
layout with a separate footer/button and a scrollable body for smaller layouts.
The corrected views were recaptured and visually inspected at 1280 × 800 using
the Compatibility renderer with Mesa llvmpipe on a virtual X display. This is
actual Godot rendering, not a concept image or web mockup.

| Capture | Inspection purpose |
| --- | --- |
| [Contract menu](v0.2/menu.png) | Role, contract, archetype, difficulty and seed selection |
| [Field manual](v0.2/manual.png) | Controls and trial instruction layout |
| [Memory Vault](v0.2/vault.png) | Reference desk, indexed cradles, shapes, labels and HUD |
| [Ritual Circle](v0.2/ritual.png) | Vessels, ember, ring boundary and instructions |
| [Clock Room](v0.2/clock.png) | Target hands, coupled lever inscriptions and central press |
| [Eye in Second](v0.2/eye_second.png) | Socket view, active-trial names and command interface |

The helper is [capture_ui.gd](../../game/tests/capture_ui.gd), which requires an
actual display/renderer. A successful headless suite does not establish image
legibility. Rendered source captures do not establish Windows graphical-driver
compatibility or hardware performance.

## Native Windows release gate

**Passed for the published v0.2.0 archive on 26 November 2026.**
The [release workflow](https://github.com/darknigthmare/THE_EYES/actions/runs/45865864627) completed all three jobs successfully.
The [published smoke report](https://github.com/darknigthmare/THE_EYES/releases/download/v0.2.0/WINDOWS_SMOKE.json) records both roles under First, Second
and Seeded Mix, all six ready markers, zero exit codes and no engine errors.

- Build source: [`4e8e034e60979856cef2fdd1508e28fb144e2812`](https://github.com/darknigthmare/THE_EYES/commit/4e8e034e60979856cef2fdd1508e28fb144e2812).
- Windows ZIP SHA-256: `1e23f7981a5e387b5853a32894ecb820d4dc4ebe4d2e20bc55fc6b9e5576df00`.
- [Release and exact downloadable assets](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.2.0).

The following requirements were applied to that exact archive.
The [release workflow](../../.github/workflows/release-windows.yml) first reruns
all six Linux gameplay suites under the pinned Godot engine and rejects engine
errors even when an exit code is zero. It exports the exact source revision,
checks the Windows template checksum, validates the executable/container, and
records provenance in `BUILD_INFO.json`.

The unchanged exported ZIP must then run on a native Windows runner. The six
startup cases are Survivor and Eye for each of First, Second, and Seeded Mix.
Each uses the actual `THE_EYES.exe` in headless mode and must:

1. Match the expected archive SHA-256, source revision, version, and package
   member checksums.
2. Reach the requested playable scene and emit its
   `THE_EYES_QA_READY role=<role> contract=<contract>` marker.
3. Exit successfully and produce no Godot script, parse, or resource-load error
   diagnostics.

The workflow requests 240 process frames per case and writes
**`WINDOWS_SMOKE.json`** containing the source commit, archive checksum, engine,
platform, and all six outcomes. It explicitly records
`graphical_hardware_playtest: false`. Publication requires a successful report
for that exact archive and checks the checksum again before attaching it to the
release. The published report is the actual workflow output and identifies the
archive independently of this documentation.

Native Windows headless startup remains narrower than a graphical Windows
match. It does not test graphics drivers, controller support, hardware FPS,
interactive input feel, or a full match on Windows. A graphical Windows
playthrough remains **untested** after the successful startup gate. The release
body and attached report identify the exact tested build; later documentation
commits do not change the distributed executable.

## Remaining scope

The implementation remains a local Godot prototype in one 54 × 48 m
observatory, with four fixed Eye sockets. It includes six scoped trial
implementations, four gameplay archetypes, existing procedural art/audio, and
one human Second Sight opportunity. Nineteen other trials and broader variants
remain design work. Networking, a 5–7 versus 1 remote session, final character
rigs, complete realms, controller/remapping coverage, progression services,
mid-match saves, and full deterministic replay are unimplemented.

UE5 project scaffolding, CSV schemas, and Blueprint recipes do not constitute
compiled gameplay assets. Unreal Editor compilation and a playable Unreal map
still require their own implementation and verification.
