# Play THE EYES — The Trial Workshop

Version **0.5.0** is a local 3D Godot prototype with **Solo Survivor, a human-plus-four-AI
Squad, human Eye, and the Trial Workshop**. Practise any one of the nine existing
trials with its real controls and no Eye or deadline, then take those skills into
a match. Ordinary matches still activate exactly three trials. The complete
25-trial bible describes the larger game.

## Start the game

**Windows:** download [THE_EYES_v0.5.0_Windows_x64.zip](https://github.com/darknigthmare/THE_EYES/releases/download/v0.5.0/THE_EYES_v0.5.0_Windows_x64.zip)
from the [v0.5.0 release](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.5.0),
extract the complete archive, and open **THE_EYES.exe**. Godot is not needed for
the package. It is an unsigned development build with embedded game data.

Publication requires the exact exported archive to pass native Windows
headless startup in **21 selections: twelve ordinary mode/contract combinations
and all nine practice trials**. `WINDOWS_SMOKE.json` on the release records the
actual checks. A graphical Windows playthrough is a separate qualification;
consult [v0.5 verification](qa/V0_5_VERIFICATION.md) for completed checks and limits.

**Source:** import `game/project.godot` into standard **Godot 4.7.2**, wait for
resource import, and press **F5**. The project uses GDScript and the Compatibility
renderer. No account, server, plugin, or API key is required.

Start in **The Trial Workshop** to learn an apparatus at your own pace. For your
first match, choose **Story / Keeper / First Observance**. Select your session:

| Menu entry | What you control |
| --- | --- |
| Play Solo as a Survivor | One survivor against the AI Eye; first-fall Second Sight recovery |
| Lead a Local Squad · You + 4 AI | One survivor with four physical AI allies against the AI Eye |
| Take the Eye's Seat | The fixed Eye against four AI survivors |
| Enter the Trial Workshop | One survivor learning one chosen trial, without an Eye or countdown |

There is no network lobby, remote partner, or second local human controller.
The first valid survivor escape wins for the team in the three ordinary match
modes. Workshop practice finishes when you complete its one selected trial.

## Learn in the Trial Workshop

Choose any of the **nine trial cards**, then select Veil, Tinker, Runner or Keeper
and a seed. Read the goal, steps, checkpoint rules and controls, then press
**Start This Trial**. All nine drills are available immediately.

You begin at the normal survivor spawn and walk to the selected apparatus.
Only that trial is active. Carry the real objects, read the station's clues and
complete the normal interactions; the other bays cannot provide extra progress.
Your archetype's movement and ability still apply. There is no active Eye,
gaze damage, Hunt deadline or exit to reach after completion. The HUD's guide
explains what to do without supplying generated puzzle answers from a distance.

The completion screen offers **Retry Same Seed**, **Try Another Seed**,
**Next Trial**, **Choose a Trial** and **Main Menu**. A retry starts fresh,
including cargo, checkpoints, partial holds and the timer. Same-seed practice
reuses the generated setup; another seed may still share some visible details.
Escape also provides a same-seed restart or return to the selector before you
finish. Starting again counts as a new attempt, while leaving early does not
count as completion.

Your local notebook counts attempts and completions and keeps best times
**separately for each archetype**. Tinker and Runner have real mechanical
advantages, so their times are not compared with the other roles. Practice
results stay separate from match victories. The trial rules below are shared
with ordinary play; the Eye pressure and three-seal escape sequence apply to
matches.

**F1** opens the Field Manual during play or pause. Reading pauses local
simulation. Closing the manual during a session returns to pause; choose
**Resume** when ready. Switching away from the application also pauses it,
and returning focus does not resume automatically.

## Contracts and objectives

| Contract | Northwest | Northeast | South |
| --- | --- | --- | --- |
| First Observance | Silent Countdown | Trial of the Echoes | Clockwork Relay |
| Second Observance | The Memory Vault | The Ritual Circle | The Clock Room |
| Third Observance | Light in the Darkness | Strings of Despair | Chimes of Doom |
| Seeded Mix | Countdown, Vault or Light | Echoes, Ritual or Strings | Relay, Clock or Chimes |

Seeded Mix chooses one of three trials per bay, giving **27 sets**. Its selection
changed in v0.4; a v0.3 Mix seed can therefore resolve to a different set. All three
match modes support all contracts. The seed fixes selection and puzzle setup
within a game version; it does not freeze AI or physics timing. Each match
begins with eight protected seconds. Three seals open the north door and start
a fresh escape timer. **Hold E at the door for 1.5 seconds** to leave.

### First Observance

1. **Silent Countdown:** take a cyan whisper mote with E, carry it northwest,
   and deposit it with E. Deliver all three distinct motes. Only one objective
   can be carried at a time; sprinting with a mote makes more noise.
2. **Trial of the Echoes:** press E at the northeast station, observe four
   symbols, then repeat them with 1–4 or the buttons. R replays; E/Escape closes
   the panel. The Eye continues acting while you solve it.
3. **Clockwork Relay:** hold E at the south wheel. The first and second thirds
   remain banked if you must release and hide. In Squad, all contributions
   combine once per physics frame and are capped at 1.8× the base rate.

### Second Observance

1. **The Memory Vault:** E at the northwest desk shows four named targets for
   eight seconds; you can replay the reference. Find them among six relics on
   the southern shelves. Carry each to its exact numbered cradle. Accepted
   placements are permanent. A wrong deposit keeps your cargo; G returns the
   relic safely to its shelf.
2. **The Ritual Circle:** take the shared ember northeast and visit the five
   vessels in their engraved order. E lights a nearby vessel. Correct pairs
   bank at two and four. A wrong unlit vessel rolls back the unbanked part and
   returns the ember; already lit vessels are harmless. Once all five are lit,
   stay inside the ring for eight continuous seconds. **Keep moving inside its
   2.8 m radius** to evade danger. Leaving resets only the hold. Jumping above
   floor level, being downed, or entering Solo Second Sight does not count as
   valid occupancy.
3. **The Clock Room:** read target/current hands, numbered 0–5. Walk to each
   lever: E turns forward, R reverses. A moves A+B, B moves B+C, and C moves C+A.
   Match all hands and press E at the centre to seal. X at the centre resets
   the start. Every generated puzzle is four optimal turns from its target.
   Tinker's Overclock can advise a turn; travel and input remain necessary.

### Third Observance

1. **Light in the Darkness:** carry each numbered cell to its matching lamp
   along the western route. Hold E while still within 1.8 m and clear sight for
   two seconds. Charge starts at 100; carrying outside refuge drains 4/s. The
   starting refuge and permanently lit lamps recharge 12/s within 3 m and clear
   sight. Empty charge blocks alignment, never movement or the return route.
   G returns a cell safely. All three lit refuges bank the northwest seal.
2. **Strings of Despair:** inspect the northeast board. Intersect its two clues:
   left/right pair, and curved (Circle/Crescent) or angular (Triangle/Diamond).
   Exactly one of four ropes satisfies both. Hold E still for two seconds to
   cut. Three stages bank independently. A wrong cut engages a three-second
   catch and emits noise; earlier stages remain locked. Release between cuts.
3. **Chimes of Doom:** read the south score, then physically visit the four
   numbered bells. E strikes; R toggles the one shared damper at the nearby bell.
   Two four-note phrases earn the seal. A wrong note restarts only its phrase;
   phrase one stays banked. A damped correct note is quieter, while a wrong
   note remains loud. Bells retain their identity and also show shapes/text.

Moving, jumping, losing range/sight, taking a hit, releasing E or pausing resets
partial lamp alignment or rope cutting. Completed checkpoints stay permanent.
The full dark-island, suspended traversal and dedicated sound-minion versions
remain production designs; these are connected observatory subsets.

Trials may be completed in any order. Seeded Mix uses the same rules for its
selected apparatus. Inactive trials cannot award extra progress.

## Lead your Squad

The human's chosen archetype joins one bot of each archetype. Names remain
unique: a bot matching your role uses Ivo Mercer, Tomas Venn, Elias Rook, or
Soren Bell; the other bots use Mara Vale, Nadiya Sayegh, June Arlen, or Ada Fen.
The right HUD shows every member's health/state, task, bleedout and rescue
progress. Tab replaces that roster with the map.

| Key | Order | Behavior |
| --- | --- | --- |
| B | Work | Allies pursue the active trials through real movement and interactions |
| F | Follow | Allies navigate toward you; if you become inactive, they can resume Work |
| V | Hold | On switching to Hold, each bot saves its own current position |

Immediate danger, viable rescue, and open-exit evacuation can override ordinary
orders. A bot facing a nearby visible shadow may sprint along a clear physical
route to evade it before resuming work, following, holding, or rescue. Evasion
interrupts a rescue and resets its progress. Hold cannot stop allies evacuating
when the door opens.

### Rescue before bleedout

Each Squad member has **one revival**. Their first lethal fall starts a
**35-second bleedout**. To rescue them, stand still within **1.8 m**, maintain
clear line of sight, and **hold E for six continuous seconds before bleedout
ends**. Bots use the same physical conditions. Only one helper can rescue a
member at a time.

Moving, jumping, releasing E, leaving range, losing sight, or taking a hit
interrupts the attempt and resets it to zero. Pausing freezes bleedout and
cancels partial rescue; after resuming, begin a new continuous hold. A successful rescue restores
**35 HP plus five seconds of protection**. A later lethal fall eliminates the
member immediately. Bleedout also eliminates them. If no active member remains
to help, the squad loses without waiting out every timer.

Mend heals an active actor; it cannot revive the downed or restore a spent
revival. Required cargo is released safely when its carrier falls. If you are
eliminated, **1–4 / mouse wheel** cycles surviving allies' actual viewpoints.
Their escape can still win for the whole team.

## Solo recovery and abilities

Solo keeps **Second Sight** instead of ally rescue. On the first lethal fall,
press E when its ring turns green three times within 25 seconds. A wrong press
costs two seconds. Success returns you with 50 HP and five seconds of protection;
the next lethal fall is final. Squad does not grant this extra recovery room.

| Archetype | Q / AZERTY A ability |
| --- | --- |
| Veil / Mara Vale | Quiet Step: five seconds of much quieter movement and reduced gaze gain; 25-second cooldown; passive footstep noise ×0.55 |
| Tinker / Nadiya Sayegh | Overclock: eight seconds of extra Relay contribution or the next physical Clock instruction; 25-second cooldown; base Relay contribution ×1.4 |
| Runner / June Arlen | Second Wind: movement ×1.25 for five seconds; 22-second cooldown; 135 stamina and 8 m/s sprint |
| Keeper / Ada Fen | Mend: up to 30 HP, capped at 100; 35-second cooldown |

In Squad, **Keeper heals the most injured eligible active member, including
self**. Allies must be within 4 m and clear sight. Equal health favors self;
equal-health allies use stable actor order. In Solo, Mend heals you. Tinker's
combined Squad Relay work is subject to the 1.8× team cap; Solo rates are unchanged.

## Controls and survival

| Input | Action |
| --- | --- |
| WASD / ZQSD or arrows; mouse | Move; look |
| Shift; Ctrl/C; Space | Sprint; crouch; jump |
| E / hold E | Use, charge, rescue or escape as prompted |
| Q / AZERTY A; G | Ability; release objective cargo |
| B / F / V in Squad | Work / Follow / Hold |
| 1–4; R in Echoes | Enter symbols; replay |
| E / R at a Clock lever; X at centre | Forward / reverse; reset |
| E / R at a bell | Strike / toggle the shared damper |
| 1–4 / wheel after Squad elimination | Spectate an ally |
| Tab; Escape | Map; pause/settings |
| F1 | Open the Field Manual; close it back to pause during a session |

Bindings use physical QWERTY positions: the Q-labelled ability is **A on
AZERTY**, and the top-row 1–4 positions work without Shift. Dropping a mote
leaves it in the world; a relic returns to its shelf and the ember or a power cell to its cradle.

Walls and the central monument block the Eye's real sight. Leave a gold trap
warning before its strike. Shadows have a visible arrival warning and use
physical navigation. Completed seals cannot be erased. The microphone is never
read; Silent Countdown responds to in-game movement noise.

## Play the Eye

Aim with the mouse; switch fixed sockets with 1–4 or the wheel. The map shows
survivors currently visible to the Eye. Four AI survivors physically navigate,
carry, solve, and attempt escape under the selected contract.

| Command | Energy | Cooldown | Requirement |
| --- | ---: | ---: | --- |
| Left click: trap | 25 | 4 s | Visible floor trap; warning before strike |
| Right click: mark | 20 | 6 s | Visible survivor |
| Q / AZERTY A: shadow | 45 | 16 s | Visible open floor, at least 3 m from survivors |
| Socket change | 8 | 2 s | A different authored viewpoint |

Influence regenerates at 4/s, capped at 100. Gaze wounds when its meter fills;
breaking sight lowers it. At most two shadows coexist. Terror remains atmosphere
telemetry, not an additional spendable power.

## Settings, records and verification

Settings include audio, reduced camera motion/vignette, vertical-look inversion,
sensitivity and **survivor/spectator field of view**. The Eye retains its fixed
authored view. Escape pauses the complete local session. F1 opens the paused
Field Manual; focus loss pauses as well, and returning focus requires an
explicit Resume. Partial interaction holds restart after pause while completed
checkpoints remain banked. Input remapping, controller support and Eye training
remain future work.

From v0.5, Godot's `user://` directory uses the stable **THE_EYES** application-data
folder. On Windows, enter `%APPDATA%\THE_EYES` in File Explorer to open it.
Changing the release subtitle no longer changes this location. Older versions'
title-based folders remain untouched and are not imported automatically.

This folder contains `settings.cfg` and the post-match
`last_observance.json`. **Schema 3** records `session_mode`, contract, selected
trials, seed, result, metrics, events, and squad summary. This is a result ledger;
it does not resume an interrupted match or replay a complete simulation.

The separate `practice_records.json` uses **schema 1**: nine trials with four
archetype profiles each, bounded attempt/completion counts and last/best timing
fields with their seeds. It keeps no growing history list and does not resume
an unfinished drill. One `practice_records.json.bak` keeps the previous notebook
before replacement. If the primary is absent, the game can load that valid
backup; an unreadable or unsupported-schema primary is preserved without
fallback or replacement. An invalid existing backup also blocks saving.
Training remains available, and a failed save is reported even if the previous
notebook was restored.

See [v0.5 verification](qa/V0_5_VERIFICATION.md) for the actual practice routes,
journal and pause checks, ordinary-mode regressions, rendering and platform
evidence. Older route times and assertion totals belong to their versioned
reports; they are not current performance claims. The [v0.5 release notes](releases/V0_5_0.md)
describe this update's scope.

For an export from source:

```bash
python3 tools/build_windows.py --output /absolute/path/to/build
```

Use a matching installed template or pass
`--template /absolute/path/to/windows_release_x86_64.exe`. The helper restores
the export preset even on an error. The [UE5 foundation](../unreal/README.md)
contains ten CSV tables and Blueprint recipes; a compiled Unreal game is
still a separate implementation milestone.
