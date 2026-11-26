# 07 — Objects and enemies

## Object taxonomy

Every gameplay object belongs to a declared family: objective, carried tool, mechanism, cover, trap, clue, recovery, or decoration. An object may combine families, but its interaction must remain explicit. Decoration does not silently become lethal. A valuable item has a recovery rule and a stable identity; a visual copy is not automatically the same logical object.

| ID | Object | Primary use | Placement and recovery | Production status |
|---|---|---|---|---|
| IT01 | Whisper mote | Silent Countdown delivery | Numbered cradle; returns if unreachable; unique deposit | Prototype core |
| IT02 | Hand lamp | Reveal paths and manage darkness | Refuge charging rack; never required without a recharge route | Planned |
| IT03 | Signal pebble | Create a deliberate noise distraction | Small reusable inventory stack; visible throw arc | Planned |
| IT04 | Mechanical brace | Hold unbanked mechanism progress | Tool cradle near machinery; expires visibly | Planned |
| IT05 | Field dressing | Restore limited health through a channel | Earned supply station; no random compulsory spawn | Planned |
| IT06 | Thread cutter | Temporarily open a thread route | Tethered utility rack; returns on loss | Planned |
| IT07 | Probe weight | Test illusion tiles | Bridge vestibule; recalled if dropped into void | Planned |
| IT08 | Ritual ember | Light sequence vessels | One shared ember; wrong vessel returns it to its cradle and preserves pair banks | v0.2 implemented subset |
| IT09 | Structural piece | Build tower or bridge | Marked storage slot; support preview; reset outside bounds | Planned |
| IT10 | Time vessel | Carry a limited charge | Trial-owned checkpoint cradle | Planned |
| IT11 | Mask | Counter a named phantom behavior | Safe stand before threat; identity remains visible | Planned |
| IT12 | Memory relic | Match a vault target | Six named shapes; four exact-ID indexed cradles; atomic ownership and deposit | v0.2 implemented subset |

Production item inventories are small: one main carried object, one utility tool, and limited consumables. The player should make an obvious carry/drop decision without navigating a large inventory during a chase. Key items cannot be destroyed for score. An Eye cannot consume survivor inventory through an unseen global action.

## Interaction lifecycle

An object progresses through explicit states such as available, reserved, carried, dropped, deposited, or recovering. Reservation is short-lived and prevents two clients from taking the same object. Carrying records the holder's stable player ID. A disconnect releases the object or sends it to a declared cradle. Depositing checks the destination, item identity, ownership, range, and current trial state before consuming anything.

Recovery should be understandable. A lost mote dissolves and reappears at its numbered cradle with a HUD notice. A structural piece returns to the storage outline that matches it. Silent teleports of important objects create confusion and should be restricted to actual invalid-space recovery. A normal dropped item remains where it was placed if reachable.

## Traps

| ID | Trap | Warning and active behavior | Counter | Restrictions |
|---|---|---|---|---|
| TR01 | Needle bed | Footprint lights, plates separate, bounded spike pulse | Step clear or use adjoining cover lane | One hit per activation per survivor |
| TR02 | Shutter press | Side lights and motor windup precede closure | Leave marked compression zone | Occupied escape threshold never seals instantly |
| TR03 | Cinder jet | Vent glows and hisses before a short flame line | Cross during recovery or take service loop | Fire cannot extend beyond marked collision |
| TR04 | Pendulum arm | Rail and sweep arc illuminate | Crouch, jump, or shelter according to shown height | No incompatible simultaneous sweep |
| TR05 | Resonance burst | Expanding wave forecast around emitter | Acoustic shield | Shield rule independent of visual reflections |
| TR06 | False floor | Cracks and support symbols announce instability | Probe or retreat | Certified checkpoint tiles remain safe |
| TR07 | Chain surge | Chain sparks in sequence before energizing | Move toward anchor or use release | No force through solid geometry |
| TR08 | Rewind clutch | Reverse-winding warning at mechanism | Complete a bank or interrupt control | Only unbanked progress can regress |
| TR09 | Light siphon | Sector boundary dims before local blackout | Reach refuge or use lamp | One guaranteed navigation light remains |
| TR10 | Delay thread | Anchored visible strand with debt label | Cut, duck, or take alternate route | No repeated per-frame debt |

These are production trap families. The current arena's exact hazards are listed in the release report. Do not claim that a catalogued trap has a final mesh, animation, audio set, or playable implementation merely because its rule exists here.

Each trap uses `Dormant → Telegraph → Active → Recovery → Dormant` with optional `Disabled`. A command rejected in Dormant does not enter Telegraph. A trap cannot be activated again while already active unless its design explicitly supports stacking. The same state drives sound, animation, collision, and UI. A delayed effect must carry an activation ID so that retries cannot apply duplicate damage.

## Minions

**The Hollow** is the baseline pursuer: a tall, folded silhouette with a visible core and a deliberate gait. It follows a recent sighting or noise, attacks after a clear windup, and loses certainty when the target breaks perception. Its purpose is to displace a survivor from a comfortable route, not to replace the Eye with a permanently omniscient chaser.

**The Listener** is a low, articulated creature that turns toward noise events. Quiet movement and sound distractions are real counters. It pauses to listen before committing to a direction. Its attack cue has a visual ripple and caption, so the sound theme does not exclude players who cannot hear it.

**The Reflection** imitates a survivor's outline at a distance but fails a close inspection cue. It performs short scripted approaches and dissolves if exposed by the correct light or observation. It cannot perfectly impersonate player names, chat, or interface markers. Its purpose is hesitation and route uncertainty, with bounded damage if ignored.

**The Seamstress** patrols tether and mask areas, extending a visible filament across a lane. The filament is an obstacle with two anchors, a warning, and a removable endpoint. The creature cannot generate an impassable web across every route. Its attacks emphasize spatial control rather than speed.

**The Usher** guards a doorway and responds to a specific rule, such as a displayed mask or silence threshold. The rule is introduced through an observable demonstration. It is a mobile lock with alternate solutions, not an unkillable enemy that guesses whether the player has understood a riddle.

All five are original production designs. The prototype implements one simplified summoned-shadow family, with at most two active shadows; it does not include five finished minion families. Full production requires separate locomotion, windup, strike, recovery, search, stagger, spawn, and despawn states for each family, plus collision and perception tests.

## Punishment rooms

The base punishment kit contains three forms. **The Breathing Lock** asks the player to confirm during a broad moving safe band; **The Service Descent** asks for a short route through lit landings; **The Ledger** asks for a three-symbol correction with an available clue. Each lasts under forty seconds in normal play and returns the survivor to a known reentry anchor.

The Solo human prototype uses a first-zero-health rhythm recovery opportunity, with a later lethal wound ending that survivor's run. AI survivors do not enter this recovery room. The v0.3 Squad instead applies one ally-assisted revival to each of its five members; its rules are in [Squad and rescue](13_SQUAD_AND_RESCUE.md). This asymmetry is a prototype simplification to expose the mechanic, not the production competitive rule. Production must give equivalent declared recovery rights to all participants.

The implemented recovery room is **Second Sight**. Its current timer is 25 seconds. The player confirms three times during the safe interval of a two-second pulse, currently from 1.2 through 1.8 seconds. A correct confirmation restarts the pulse; a wrong confirmation removes two seconds from the remaining allowance. Three successes return the player with 50 health and five seconds of protection. The room communicates the safe interval with both ring color and explicit “NOW” text. These values are prototype tuning and should be rechecked against the runtime when revised.

## Props and environmental storytelling

The shared prop inventory includes warning plaques, socket cables, maintenance hatches, pressure gauges, relief valves, inspection lamps, empty cradles, tool racks, numbered seals, worn handrails, discarded route markers, and survivor notes. Their placement explains how a place functions. A gauge near a pressure trap should reflect its phase; a purely decorative gauge uses a different visual treatment.

Every asset record tracks source, creator, dimensions, pivot, collision type, interaction anchors, materials, LOD expectations, animation states, sound hooks, and implementation status. Prototype procedural assets remain honestly labeled. The final asset list is a work register, not a statement that all required art has been generated.
