# Play THE EYES — The Observance Collection

Version **0.2.0** is a local 3D prototype with two asymmetric roles and one
complete match arena. Six trial subsets are playable, with three active per
match. The 25-trial bible describes the larger target game.

## Windows package

Download the [Windows x64 ZIP](https://github.com/darknigthmare/THE_EYES/releases/download/v0.2.0/THE_EYES_v0.2.0_Windows_x64.zip)
from the [v0.2.0 release](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.2.0).

Extract `THE_EYES_v0.2.0_Windows_x64.zip` completely, then launch `THE_EYES.exe`.
Game data is embedded in the executable; Godot need not be installed. Use the
package and SHA-256 provided on that release. This is an unsigned development
build, not an installer.

The release workflow exports and structurally checks the executable, then runs
that exact package natively on Windows in headless mode for both roles under
all three contracts. See the release asset `WINDOWS_SMOKE.json` for execution
evidence. A graphical Windows hardware playtest remains required. See
[verification](qa/V0_2_VERIFICATION.md).

## Source project

Install the standard **Godot 4.7.2** editor on Windows, Linux or macOS. Import
`game/project.godot`, wait for resource import and press F5. It uses GDScript,
not C#, and the Compatibility renderer. Earlier engine versions are unverified.

Choose Story for a first survivor run. Keeper heals with Q; Veil reduces noise
and offers a short gaze-resistance ability. Select **Enter as a survivor** to
face the AI Eye, or **Take the Eye's seat** to oppose four AI survivors. There
is no lobby or network session in 0.2.0.

## Choose a contract

**First Observance** uses Countdown, Echoes and Relay. **Second Observance**
uses Memory Vault, Ritual Circle and Clock Room. **Seeded Mix** chooses one of
two trials in each bay, giving eight sets. Both roles support every contract.
The seed fixes the selected trials and puzzle setup. It does not freeze AI or
physics timing. Exactly three seals are required in every case.

## First Observance survivor run

1. You start in the south with eight protected seconds. Inspect the map with Tab.
2. Pick up one cyan whisper mote using E. Carry only one at a time. Deliver it
   to Silent Countdown in the northwest. Repeat three times. Sprinting with a
   mote makes noise; crouching is quieter.
3. At the northeast Echo station, press E. Watch the symbols and repeat the
   order with 1–4 or the buttons. R replays; E/Escape lets you retreat. The Eye
   keeps acting while the puzzle panel is open.
4. At the south Relay, hold E. The first and second thirds remain banked if you
   must release the wheel and hide.
5. After all seals break, reach the north door and hold E for 1.5 seconds.

Move with WASD/ZQSD or arrows. Shift sprints, Ctrl/C crouches, Space jumps,
Q activates your ability, G releases cargo, Tab toggles the map and Escape
pauses. Dropping a mote leaves it in the world; a relic returns to its shelf
and the shared ember returns to its cradle, so neither can be lost.

Key bindings use physical QWERTY positions. On AZERTY, the Q-labelled ability
is therefore **A**, while movement is ZQSD. Use the top-row 1–4 key positions
without Shift for symbols and Eye sockets. This applies to the Eye's Q-labelled
summon command as well.

The active Eye is brighter. Stone walls and the central monument block its
sight. Gold floor warnings precede spikes by 1.5 seconds. Shadows appear after
a two-second warning and pursue through physical navigation; break their sight.
Completed seals cannot be erased.

Your first lethal wound offers **Second Sight**: press E when the ring turns
green, three times within 25 seconds. A wrong press costs two seconds. Success
returns you with 50 vitality and five seconds of protection. The next lethal
wound is final.

| Archetype | Character | Passive | Q ability |
| --- | --- | --- | --- |
| Veil | Mara Vale | Footstep noise ×0.55 | Quiet Step: 5 s quieter steps/reduced gaze gain; 25 s cooldown |
| Tinker | Nadiya Sayegh | Relay work ×1.4 | Overclock for 8 s: additional ×1.6 Relay rate, or advice for the next Clock lever/direction; 25 s cooldown |
| Runner | June Arlen | 135 stamina; 8 m/s sprint | Second Wind: movement ×1.25 for 5 s; 22 s cooldown |
| Keeper | Ada Fen | Recovery-oriented kit | Mend: up to 30 vitality; 35 s cooldown |

## Second Observance survivor run

1. **Memory Vault, northwest:** E at the desk reveals four named relics for
   eight seconds. Replay whenever needed. Six distinct relics stand on the
   southern shelves. Carry one with E and bring it to the exact numbered
   cradle. Correct placements bank permanently. An incorrect deposit retains
   your cargo; G returns it safely to its shelf.
2. **Ritual Circle, northeast:** take the shared ember and follow the engraved
   five-vessel order. E lights a nearby vessel. The second and fourth vessels
   bank pairs. Choosing an incorrect unlit vessel loses the current unbanked
   part and returns the ember; clicking an already lit vessel is harmless.
   After all five are lit, remain in the ring for eight continuous seconds.
   **Keep moving inside its 2.8 m radius** to evade hazards. Leaving resets
   only that final hold, not the vessels. Jumping above the floor or entering
   Second Sight cannot contribute occupancy.
3. **Clock Room, south:** read the target and current positions, numbered 0–5.
   Walk to lever A, B or C. E turns forward; R turns backward. A moves A+B, B
   moves B+C, C moves C+A. Match all three hands, then press E at the centre
   to confirm. X at the centre restores the initial puzzle. Each generated
   start is exactly four optimal turns from its target. Overclock temporarily
   advises a legal next turn, but you must travel and use the lever yourself.
4. Break the three seals and hold E at the north doorway, as in First.

You can complete these trials in any order. Seeded Mix uses the same apparatus
and rules for whichever three trials were selected. Absent trials cannot be
advanced by using their old locations.

## First Eye run

You cannot walk. Aim with the mouse; switch sockets with 1–4 or the wheel. The
map shows only survivors currently in your line of sight. Survivors have real
bodies, collision, navigation and objectives.

| Command | Energy | Cooldown | Use |
| --- | ---: | ---: | --- |
| Left click | 25 | 4 s | Visible floor trap; warning before strike |
| Right click | 20 | 6 s | Visible survivor; faster gaze buildup for 6 s |
| Q | 45 | 16 s | Visible open floor, at least 3 m from survivors |
| Socket change | 8 | 2 s | A different fixed viewpoint |

Influence regenerates at 4/s, capped at 100. Gaze damages when its meter fills;
breaking sight lowers it. Two shadows can coexist. Their 20 s lifetime includes
the warning. Terror is atmosphere telemetry in 0.2.0, not a spendable ultimate.

## Settings and persistence

Sound, reduced camera motion/vignette, inverted vertical look, sensitivity and
field of view are adjustable. Escape pauses the complete local match. Inputs
are fixed; remapping and controller support are later milestones. Silent
Countdown uses in-game noise; the microphone is never read.

Godot's `user://` directory contains `settings.cfg` and, after a match,
`last_observance.json`. Schema 2 records the version, contract, exact selected
trial mapping, result, seed, counters and event ledger. It is not a mid-match
save or deterministic full replay.

## Export from source

```bash
python3 tools/build_windows.py --output /absolute/path/to/build
```

Use an installed matching Godot template, or pass
`--template /absolute/path/to/windows_release_x86_64.exe`.
The helper restores the repository preset even on an export error.
