# THE EYES 0.3 — verification record

**The Survivor Accord · 26 November 2026.** This report separates local engine
tests, native-renderer inspection, executable startup and the unfinished Unreal
handoff. **The v0.3.0 prerelease is published**, after all three release jobs
succeeded on source commit `c0b95341f728affe06933be9835d7ac9ff55abf3`.
[Download and official reports](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.3.0).

## What changed

The local `squad` session adds one human survivor and four physical AI allies.
The human still uses the survivor controller; `session_mode` preserves the real
requested mode in the startup marker and schema 3 match record. Solo Survivor
and human Eye keep their existing populations and recovery rules.

The new state machine owns active/downed/eliminated transitions, one recovery,
35-second bleedout, exclusive six-second rescue and interruption reset. The
world layer validates actor membership, 1.8 m reach, actual physics sight and
continuous stationary holding. A successful rescue restores 35 HP and 5 seconds
of protection. Downed actors release cargo and cannot move, advance trials,
heal, take repeated damage or escape. Elimination changes the director's
population exactly once.

Work/Follow/Hold route the same physical bots. Rescue and open-door evacuation
override ordinary orders. Immediate visible-shadow avoidance interrupts a
rescue before the helper resumes their legitimate task. Keeper heals the most
injured eligible active squad member including self; allies must be within 4 m
and clear sight, self wins equal-health ties. Human elimination activates a
camera at an actual remaining ally, selected with 1–4/wheel.

## Environment

- Godot **4.7.2.stable.official.ed1daf0bf**, standard GDScript build.
- Linux headless tests with fixed 60 Hz and Dummy audio.
- Native screenshots: Compatibility/OpenGL renderer through Xvfb and Mesa
  llvmpipe, 1280×800. This is software rendering, not a hardware benchmark.
- Native Windows runtime: all nine headless startup cases passed for the exact published archive. Interactive graphical Windows playthrough remains unverified.

## Production-engine gates

| Suite | Observed result |
| --- | --- |
| `test_director.gd` | 27 cases / 125 assertions / 0 failures |
| `test_world.gd` | 6 cases / 60 assertions / 0 failures; First bots escape at 52.95 s |
| `test_trial_set.gd` | 23 cases / 2,098 assertions / 0 failures |
| `test_second_world.gd` | 16 cases / 137 assertions / 0 failures; Second and all 8 Mix mappings complete |
| `test_survivor_route.gd` | Active Story Eye: solo First escape at 267.93 s, 86 HP, 2 wounds, no Second Sight |
| `test_second_survivor_route.gd` | Active Story Eye: solo Second escape at 324.17 s, 80 HP, 11 wounds, 1 normal Second Sight |
| `test_squad_state.gd` | 26 cases / 120 assertions / 0 failures |
| `test_squad_world.gd` | 23 cases / 234 assertions / 0 failures; physical AI rescue in 7.50 s |
| `test_squad_route.gd` | Three complete Story/Keeper Squad sessions; all pass |

The six retained suites reproduce the previous release's outcomes. Their four
assertion suites account for 72 cases and 2,420 assertions, with two additional
full solo routes. Squad state adds 26 cases / 120 assertions and physical Squad fixtures add
23 cases / 234 assertions. The six assertion suites total **121 cases and
2,774 assertions, with zero failures**. The two solo routes and three Squad
sessions are additional completion scenarios, not invented assertion counts.

### Physical Squad fixtures

The 23 world cases load the actual main scene and isolate population/identity,
preparation, foreign actor rejection, downed cargo/ability/trial/ritual guards,
real-wall rescue and healing occlusion, distance limits, moving/releasing/hurt
rescue interruption, pause reset/freeze, exclusive reservations, helper loss,
exact six-second completion and protection expiry, single elimination/wipe,
Keeper targeting/ties/cooldowns, Work/Follow/Hold/escape behavior, real spectator
camera switching, rematch cleanup and Eye perception of eligible visible allies.

A staged wounded human is rescued by an AI that walks **7.64 m along a nine-point
AStar path**, using its production CharacterBody controller, then completes the
continuous hold. Total travel plus rescue is **7.50 simulated seconds**; the
human receives 35 HP and protection exactly once. The fixture positions actors
and applies a normal lethal wound to isolate this check. It is not claimed as
a full match against the Eye.

A dedicated main-scene physics-tick fixture verifies the combined Relay path:
a human and four allies produce exactly **0.15 progress in one second** at the
1.8× cap; a lone human holding produces **1/12 per second**, with no extra decay
from the empty allied contribution pass.

### Full Squad sessions

| Contract | Seed | Result | Simulated time | Human distance | Human HP | Team wounds | Orders |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| First | 271126 | Survivor team escaped | 46.88 s | 102.76 m | 33 | 4 | 3 |
| Second | 271126 | Survivor team escaped | 86.80 s | 93.87 m | 20 | 6 | 3 |
| Mix | 271126 | Survivor team escaped | 46.72 s | 86.57 m | 100 | 1 | 3 |

All three runs use ordinary input actions, real survivor movement and collisions,
normal trial interactions, and the active AI Eye. The informed driver knows the
map and legal puzzle actions. It issues Follow/Hold/Work, works on the south
mechanism, moves through cover, heals through the ordinary ability and attempts
the exit. The four allies do their own work and can win for the team.

The routes do not teleport actors, inject damage, restore health, set seals,
extend clocks or disable Eye perception. The final runs needed no rescue;
rescue correctness is established by the separate domain/world fixtures. This
is completion evidence for these configurations, not a novice usability study
or a claim of balance across all archetypes, seeds and difficulties.

### Defects caught during integration

1. **Reservation reassignment:** a closer casualty or a new down could steal a
   helper from an existing rescue. Valid existing pairs now retain exclusivity;
   invalid/released holds reset completely.
2. **Keeper self-healing:** choosing only injured allies could prevent a
   critically injured Keeper from healing themself. Target selection includes
   self and uses a documented tie rule.
3. **Shadow pressure:** an early Second route ended in a rescue-chain wipe.
   Squad allies now evade nearby visible shadows using real open navigation.
   This changes production behavior; the route does not receive a special buff.
4. **Combined Relay:** the human and AI contributions must be integrated once
   per tick. Squad combines rates and caps them at 1.8×; it does not run separate
   charge/decay passes for human and bots.

## Native visual inspection

These are actual Godot frames. The helper deliberately positions actors/cameras
for inspection and stages rescue/spectator conditions through production
methods. They are presentation fixtures, not complete-playthrough evidence.

| Frame | What it verifies |
| --- | --- |
| [Menu](v0.3/menu.png) | Three distinct local role choices and contract selection |
| [Squad](v0.3/squad.png) | Five-member roster, identity, HP, tasks and order legend |
| [Rescue](v0.3/rescue.png) | Downed presentation, six-second hold hint and normalized progress |
| [Spectator](v0.3/spectator.png) | Eliminated human, ally viewpoint, ally status and switch controls |
| [Manual](v0.3/manual.png) | Scrollable English manual and updated rules |

The renderer reports that changing VSync is unsupported on this software
display. Captures complete successfully; that warning is not a gameplay error.
Audio output is deliberately muted in automation. Included synthesized WAVs
and playback code are not equivalent to a subjective listening review.

## Export and Windows boundary

Both repository workflows require all **nine** gameplay suites. The release
workflow pins the engine and official Windows template hashes, exports the
exact source commit, verifies PE32+ AMD64 and ZIP integrity, and records project
and Windows resource versions. A mismatched 0.3.0/ 0.3.0.0 version is rejected.

The same exported ZIP must then pass **nine native Windows headless startups**:
Solo Survivor, Eye and Squad under First, Second and Mix. Each requests 240 frames
and must report its actual `session_mode`, exit zero and contain no engine
errors. A final independent publication check verifies the archive checksum,
source revision and all nine distinct successful role/contract pairs.

**Observed result:** all nine Windows startup cases passed, with zero exits and
no engine errors. The published `WINDOWS_SMOKE.json` is schema 2 and records the
actual requested/loaded session modes, exact source revision and archive hash.
The exporter, Windows runner and publisher all refer to the same archive.
Interactive graphical Windows playthrough remains unverified.

| Mode | First | Second | Mix |
| --- | --- | --- | --- |
| Solo Survivor | Passed | Passed | Passed |
| Human Eye | Passed | Passed | Passed |
| Survivor Squad | Passed | Passed | Passed |

### Publication provenance

| Evidence | Exact record |
| --- | --- |
| Feature commit | `cafae25145909f89b56c9c914650973934014105` |
| Feature verification | [45873381917](https://github.com/darknigthmare/THE_EYES/actions/runs/45873381917), all nine suites passed |
| Merged change | [PR #3](https://github.com/darknigthmare/THE_EYES/pull/3) |
| Build/source commit | `c0b95341f728affe06933be9835d7ac9ff55abf3` |
| Source tree | `257845162decc591970960f4506cff701757c4cb` |
| Main verification | [45874067644](https://github.com/darknigthmare/THE_EYES/actions/runs/45874067644), all nine suites passed |
| Release workflow | [45874067936](https://github.com/darknigthmare/THE_EYES/actions/runs/45874067936), all three jobs succeeded |
| Linux / Windows / publish jobs | `140096569556` / `140099982444` / `140105343129` |
| Release | `459778231`, tag `v0.3.0`, development prerelease |
| Archive | `THE_EYES_v0.3.0_Windows_x64.zip`, 39,079,274 bytes |

| Published file | SHA-256 |
| --- | --- |
| Windows ZIP | `adcf90c809a99ab024af09439704437852f93eb70a96f4340014b349fdc1d820` |
| `WINDOWS_SMOKE.json` | `eaeae2b794980bd844946cbb260fe9d6a3d916aaeedc8a5f9c3f224967b7dc95` |
| `SHA256SUMS.txt` | `1e7b058312563a3a510ee89509f4b1bdbaa5b39b0873eda19a44fe9ef42e292b` |

The API asset digests and published reports identify the delivered bytes.
Later documentation-only commits may record this evidence; the final backup
manifest distinguishes its source snapshot commit from the executable's build
commit and checks that `game/` and `tools/` are identical between them.

## Durable backup and remaining work

The versioned backup destination is
[THE_EYES / 2026-11-26_v0.3.0_release](https://drive.google.com/drive/folders/1-7jT03PU7PJIyEgonHppSiLQC4dtv1UC).
A completed snapshot consists of the official Windows ZIP, official checksums
and Windows report; a clean source ZIP; a full-history Git bundle; the combined
bible/technical book; restoration instructions; a manifest; and backup checksums.
The manifest records the source snapshot and executable build commits separately.
Completion requires source/blob comparison, a fresh bundle restore with Git
integrity/ref checks, and downloaded-byte verification of the Drive payloads.
Folder creation alone is not a completed backup. Earlier version folders and
releases remain independently restorable.

The executable remains a local Godot prototype. Unreal contains a descriptor,
configuration, eight importable CSV specifications and editor construction
recipes, including Squad defaults. UE5 maps/Blueprint assets have not been
authored or executed here. The remaining 19 trial implementations, networking,
production character art/animation, progression, controller/remapping support
and broad performance/UX qualification remain future work.
