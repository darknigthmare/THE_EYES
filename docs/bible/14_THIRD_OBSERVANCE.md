# 14 — The Third Observance

## Purpose and scope

The Third Observance expands the local Godot observatory with three more **playable prototype subsets** from the authored catalogue: **T04 — Light in the Darkness**, **T07 — Strings of Despair**, and **T17 — Chimes of Doom**. Each asks a different question under the same Eye pressure: can the survivor manage a limited resource, interpret an explicit clue, and choose when to make noise?

The level remains the existing connected observatory. These apparatus do not constitute finished Void of Despair, Labyrinth of Shadows or Twisted Carnival realms. They establish the rules, physical interactions, bot responsibilities, feedback and recovery paths that a later realm can develop. The catalogue entries retain their larger environments and proposed Eye interventions as design work.

The three new subsets use the ordinary survivor controller, collision and visibility checks. They also work with the local Squad and human Eye sessions. A match still requires **three seals** and the ordinary north-door escape. Nine available trials do not mean nine mandatory objectives in one match.

This chapter describes the v0.4 rule contract. The release verification report must be consulted for actual tested scenarios and platform evidence; rules described here are not, by themselves, a test result.

## Contract selection and identity

| Stable bay / seal slot | First | Second | Third |
| --- | --- | --- | --- |
| Northwest / `silent` | Silent Countdown, T02 | The Memory Vault, T24 | Light in the Darkness, T04 |
| Northeast / `echoes` | Trial of the Echoes, T05 | The Ritual Circle, T10 | Strings of Despair, T07 |
| South / `relay` | Clockwork Relay, T08 | The Clock Room, T16 | Chimes of Doom, T17 |

The contract IDs are `first`, `second`, `mix` and `third`. The first, second and third contracts select the complete corresponding column. **Seeded Mix** chooses one of three entries per bay, yielding **27 possible selections**. A slot remains the stable three-seal identity; the selected trial supplies its display name and its interaction rules.

### Seed compatibility

v0.4 extends the Mix draw from two candidates to three. Therefore an old v0.2/v0.3 Mix seed is **not a promise of the same selected trials in v0.4**. A seed remains deterministic within the same rules version. First and Second keep their named apparatus and established puzzle rules. Record the rules version and the resolved selection with a result; a seed alone is insufficient to describe a historical match.

The contract is fixed when a match starts. Finishing a trial cannot reroll an unfinished bay. All completion events are permanent and admitted once, including events that arrive in the same simulation tick.

## T04 subset — Light in the Darkness

### Physical task

Three individually numbered power cells supply three matching refuge lamps along the western route. The northwest base refuge starts lit and remains a recovery point. A survivor picks up one available cell, carries it to the matching lamp, and performs a **two-second stationary alignment**. The lamp then becomes a permanent lit refuge and the cell is consumed into that checkpoint.

Numbers and names identify matching objects; color is a supporting cue. The cell must actually be carried by the interacting actor. Being near the destination or having another survivor's cell nearby is insufficient. A cell has one owner, a survivor carries at most one objective cargo, and simultaneous pickup requests cannot create copies.

The whole trial completes when all three lamps are activated. The already activated lamps remain useful to teammates, including those who were downed or delayed elsewhere. No later mistake extinguishes them.

### Lamp charge

Every eligible survivor has an individual lamp-charge value:

| Parameter | Prototype rule |
| --- | --- |
| Initial / maximum charge | 100 |
| Drain | 4 charge per second while carrying a cell outside a lit refuge |
| Recharge | 12 charge per second inside a valid lit refuge |
| Refuge reach | Within 3 m, with clear line of sight |
| Alignment reach | Within 1.8 m of the matching lamp, with clear line of sight |
| Alignment time | 2 continuous stationary seconds while holding E |

The base refuge always provides recharge. An activated lamp adds another recharge position. Walls block a refuge's gameplay coverage; a decorative light seen through geometry does not authorize recharge. Overlapping refuges do not multiply the recharge rate.

Charge drains only during the stated carrying condition. It does not decrease merely because the actor exists, walks without a cell, opens the menu or waits in a refuge. A depleted lamp blocks alignment but leaves movement, floor collision and all recovery routes available. The survivor can walk back to a known refuge or return the cell with **G** and try again. This subset does not implement chill damage, forced falls or invisible floors.

### Alignment and interruption

The survivor must remain stationary, grounded, alive and active, with valid range and sight for the entire hold. Input release, movement, damage, pause, loss of sight or loss of the carried cell interrupts the hold and discards its partial progress. Picking up or reaching the lamp does not bank a fraction of a seal. Only completed lamps are checkpoints.

Shared work cannot turn one two-second alignment into an instantaneous completion. Each cell has one carrier and the alignment belongs to that carrier. Another survivor can finish a different lamp, but cannot contribute a second copy of elapsed time to this one.

### AI and readability

Bots reserve available cells, use the same physical pickup and alignment path, and return to recharge when necessary. A bot's cargo is visible. Its task appears in the roster as collecting, recharging or aligning. The human HUD reports carried-cell identity and charge; world lamp numbers and lit states make the route understandable without reading an internal variable.

This local subset uses the existing Eye's gaze, traps and shadows. It does not add the catalogue's lamp-dimming power, a new phantom species or a full dark-island environment.

## T07 subset — Strings of Despair

### An explainable rope puzzle

The northeast apparatus presents a suspended cage mechanism with four individually tagged supports. Three successful releases lower it through three permanent safety catches. The player reads the current panel, identifies one rope and holds **E for two stationary seconds** near that rope.

The four tags have names and distinct geometry:

| Shape family | Tags |
| --- | --- |
| Curved | Circle, Crescent |
| Angular | Triangle, Diamond |

Each left/right pair contains one curved and one angular tag. The clue specifies **one pair and one shape family**, such as “right pair, curved tag.” Exactly one rope satisfies both facts. Rope identities are generated from a bounded template with this invariant; the puzzle does not require guessing an arbitrary rope number.

The evidence stays visible. Reading and observing it is an ordinary physical action, and the current stage remains fixed while a player considers the answer. Tag arrangement and clues may differ by seed. Within a stage, the clue is fixed. A teammate's successful cut banks that stage, cancels every partial hold from the old stage and reveals the next clue; a new cut requires ending the old eligible hold and beginning a fresh one.

### Correct cut, wrong cut and recovery

A correct two-second cut releases one stage and banks it. The next clue describes the next stage. The third correct release completes the bay's seal exactly once.

A wrong deliberate cut engages a **three-second safety catch** and emits a loud noise event that leaves **10 seconds of Eye noise memory** at the apparatus. The apparatus shows its locked state and then becomes available again. The current stage is retried; earlier completed stages remain banked. The prototype does not drop the actor into a pit or inflict an unavoidable damage chain. The ordinary Eye can investigate the sound while the player spends time recovering.

The hold requires 1.8 m reach, a clear sightline, stationary grounded movement and an eligible actor. Release, movement, applied damage, pause or sight/range failure cancels incomplete work. Simultaneous actors cannot double the timer or release several stages with one hold. A new stage requires its own valid cut.

### AI and larger design

Bots first spend time physically observing the clue desk, then select a rope from the same public clue. They cannot remotely finish a stage or treat a disappeared/downed operator as still cutting. Orders, hazards and rescue can interrupt their work in the same way as other tasks.

This is one ground-accessible, three-stage cage mechanism. The full catalogue's three independently occupied cages, complementary clue fragments, protected balcony, emergency extension and special Eye clue-obscuring/shaking actions remain future realm work. The subset preserves the catalogue's central promise: a unique explainable solution, deliberate commitment and a recoverable safety catch.

## T17 subset — Chimes of Doom

### Walk the score

Four physical bells have stable numbers, names and different silhouettes. A visual score contains **two four-note phrases**. Each phrase is a seeded permutation of the four bell identities. The player observes the score, walks to the corresponding bell and presses **E** to strike it.

The score remains available visually. Players do not need to distinguish pitches or hear a preview to solve the trial. A bell's number and identity remain the same throughout a phrase. Accepted strikes advance the score one note at a time; the global strike interval is **0.45 seconds**.

Completing phrase one creates a permanent checkpoint. A wrong strike during phrase two returns to the beginning of phrase two, without erasing the first. Invalid indices, inactive trials and actions attempted during cooldown are rejected without consuming a note or creating an extra noise event. Both phrases complete the seal once.

### One shared damper

At a bell, **R** moves the single shared damper to that bell. Pressing R again on the damped bell removes it. The damper is team state: it cannot simultaneously protect four instruments because four actors interacted. Its change interval is **0.5 seconds**.

| Strike outcome | Eye noise-memory duration |
| --- | ---: |
| Correct, undamped bell | 6 seconds |
| Correct, damped bell | 1 second |
| Wrong bell, with or without damper | 10 seconds |

Noise is an event from the actual struck bell, routed into the existing Eye perception system. In this implementation the numbers are durations, in seconds, of the Eye's approximate noise memory. They are not decibels, measured loudness or damage values. A new sound uses the greater of the existing memory duration and its own duration; a quieter sound does not erase an already longer memory. Damping offers a real choice between a quicker noisy route and deliberate quieter operation. It does not change the required score, lower damage globally or make an incorrect strike harmless.

Bots spend **two seconds** at the score desk before using the score, then physically travel to bells and use the same damper/strike commands. Shared state is rechecked after another actor advances the phrase, so an old target cannot be accepted as a new arbitrary note.

The prototype does not add sound-sensitive minion species, moving bell carriages, automatic solo shutters or a new Eye power. Those ideas remain in the full T17 catalogue design. Existing shadows and the Eye's ordinary approximate noise memory provide pressure in this local subset.

## Common life, pause and team rules

Downed and eliminated actors cannot pick up cells, align lamps, cut ropes, strike bells or operate a damper. Losing an actor releases owned cargo and incomplete work. A returned cell remains available at its source until legitimately banked; the match cannot become impossible because a carrier fell.

The local pause freezes simulation time and cancels incomplete continuous interactions. Resuming requires a fresh hold. Completed lamps, cage stages and the first bell phrase stay banked. Restart rebuilds the selected apparatus and all transient ownership, charge, cooldown and observation state.

All three session modes share these objective rules. Solo retains Second Sight; Squad retains its one-recovery life model and Work/Follow/Hold orders; the human Eye session retains four bot survivors. There is no network party or additional human controller in this release.

## Presentation changes

Survivors use original procedural prototype silhouettes with arms, a coat or role equipment, and movement-driven limb animation. These are readable placeholders for later character art. Character identity is supplied by the existing named survivor data; no new finished character model or animation set is claimed.

World nameplates use smaller, single-line names in the normal state so they do not obscure apparatus clues. Downed state adds an explicit label. The Squad roster separates health/archetype from the current task so long task names stay readable. The field manual and contract selector explain all nine trials and the new Mix pool.

## Acceptance obligations

Before promoting a build, verify the following against the running game:

1. All 27 Mix selections contain one valid trial in each bay and can reach the three-seal escape state.
2. A cell cannot have two carriers, recharge cannot pass through a wall, and an empty lamp retains a physical recovery route.
3. Every generated rope stage has exactly one solution from its two public clue facts. A wrong cut preserves previous stages and unlocks after its safety catch.
4. Bell cooldowns admit one strike at a time. A wrong note preserves the completed first phrase. Damping changes the emitted noise at the bell and never silences a wrong note.
5. Range, visibility, motion, life changes, damage and pause cannot leave a continuous interaction running unattended.
6. Bots physically observe, navigate and act, using ordinary constraints. A complete human-input route remains a separate verification from isolated fixtures or bot-only runs.
7. Real renderer captures show the active apparatus, charge/clues/score, smaller names and legible roster. Native Windows startup and interactive graphical Windows playthrough are reported separately.

The [construction specification](../technical/THIRD_TRIAL_IMPLEMENTATION.md) and [UE5 CSV handoff](../../unreal/Data/README.md) translate these rules into an editor implementation plan. They do not certify imported tables, compiled Blueprints or an Unreal executable.
