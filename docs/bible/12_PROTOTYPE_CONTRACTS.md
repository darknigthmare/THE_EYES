# 12 — Prototype contracts and v0.2 scope

**Version boundary:** this chapter preserves the six-trial v0.2/v0.3 contract and its measured results. Version 0.4 adds Third and expands Mix from 8 to 27 mappings; [chapter 14](14_THIRD_OBSERVANCE.md) is authoritative for that extension.

The v0.3 local Squad builds on these six trial subsets. Its additional orders, rescue rules, and evidence boundaries are in [Squad and rescue](13_SQUAD_AND_RESCUE.md).

**Status: implemented in the local Godot v0.2 prototype.** Domain checks, physical bot routes, and an active Story survivor route have passed for the tested build. Native Windows headless startup has passed for both roles under all three contracts. Graphical Windows playthrough and Unreal gameplay remain unverified. This chapter records implementation boundaries and the evidence available on 26 November 2026.

## One observatory, three active trials

The v0.2 prototype retains the connected 54 × 48 m observatory, its four fixed Eye sockets, and the three-seal exit rule. Each of the northwest, northeast, and south apparatus bays offers two possible trials. A match activates exactly one trial per bay. Alternate apparatus replaces the inactive trial's props, interactions, and objective prompts inside the existing connected arena.

| Contract | Internal ID | Northwest bay | Northeast bay | South bay |
|---|---|---|---|---|
| First | `first` | T02 — The Silent Countdown | T05 — Trial of the Echoes | T08 — Clockwork Relay |
| Second | `second` | T24 — The Memory Vault | T10 — The Ritual Circle | T16 — The Clock Room |
| Seeded Mix | `mix` | Silent Countdown **or** Memory Vault | Echoes **or** Ritual Circle | Relay **or** Clock Room |

The three independent bay choices give Seeded Mix eight possible combinations. A given seed and build resolve to the same combination. The existing rule-module slot IDs remain `silent`, `echoes`, and `relay`; those identify the northwest, northeast, and south seal slots even when their alternate trial is active. Runtime trial IDs are `silent`, `vault`, `echoes`, `ritual`, `relay`, and `clock`. Public names come from the active trial. Separate puzzle random streams preserve each trial's seeded layout across contract choices and leave the original Echoes sequence stream unchanged.

The First contract preserves the original three trial families. Version 0.2 adds three physical trial subsets and brings the prototype pool to six of the twenty-five designs. There are still only three seals to earn in a match. Inactive props, obsolete objective objects, and their interaction paths cannot award progress.

## T24 — The Memory Vault: physical retrieval and indexed cradles

The northwest apparatus contains the reference desk and four indexed cradles. Six distinct relics occupy the southern storage shelves: **Orb, Spire, Cube, Ring, Crown, and Diamond**, with IDs 0 through 5 respectively. A seeded target selects four distinct relic IDs. E at the desk reveals the requested cradle order for eight seconds; the player then walks to the actual relic, picks it up, carries it, and deposits it at the matching physical cradle. The reference can be shown again at the desk.

A deposit validates the actor, proximity, held relic, cradle index, and the exact target ID for that cradle. A correct placement becomes permanent and consumes that carried relic. A wrong placement retains the cargo and leaves accepted cradles unchanged. One actor carries one objective object at a time across both original and alternate trials. G returns a relic to its shelf or the ember to its cradle; a legacy mote drops through its existing physical path. A lethal wound releases carried objective ownership through the same recovery path, keeping required objects obtainable.

Shapes, names, and cradle numbers carry the rule; color is supplementary. The Eye applies its existing gaze, floor traps, and shadows to the carrier's route. The player can use cover between the southern shelves and northwest cradles, re-read the reference, and bank one permanent placement at a time. The full production design's moving decoys, split-team clue windows, and realm-specific vault environments remain future work.

## T10 — The Ritual Circle: spatial sequence and sustained occupancy

Five physical vessels surround the northeast ritual apparatus. A shared ember is collected from its cradle and used to light vessels in a seeded permutation of IDs 0–4. The player moves to the chosen vessel and interacts physically.

Correct prefix lengths of two and four form permanent pair checkpoints. A wrong **unlit** vessel rolls the sequence back only to its latest pair checkpoint and returns the ember to its cradle. Previously banked pairs remain lit. Repeated interaction with an already lit vessel is harmless. The fifth correct vessel finishes the lighting sequence and releases the ember, but does not yet award the seal.

The final step requires **eight continuous seconds of actual survivor occupancy inside the ritual ring**. The world checks eligible actors within a 2.8 m horizontal radius of the ring center and at floor level. Survivors may keep moving inside this boundary: circling the central pedestal offers a practical response to the Eye's tracking while preserving occupancy. The HUD explicitly prompts the player to keep moving inside the ring. If no eligible survivor remains inside, only the final hold resets to zero; all five lit vessels remain intact. Another attempt therefore repeats the hold, not the completed lighting sequence. Bots and the human use the same actor-based occupancy rule.

Existing gaze, traps, and shadows can make the hold dangerous and force a retreat. An Eye power that extinguishes candles, a new phantom family, a completed Dollhouse map, and an energy-regeneration debuff on ritual completion remain production designs.

## T16 — The Clock Room: coupled physical controls

The south apparatus contains three visible clock hands, three spatially separated levers, a reset control, and a central seal press. Each hand has six integer positions, 0–5. The target constellation and gear relationships are readable on the apparatus. Forward lever effects are:

| Lever | Hand A | Hand B | Hand C |
|---|---:|---:|---:|
| A | +1 | +1 | 0 |
| B | 0 | +1 | +1 |
| C | +1 | 0 | +1 |

All values wrap modulo six. Reversing a lever applies the exact inverse. Each lever changes two hands: A+B, B+C, or C+A. The generator first chooses the seeded target and then performs a bounded breadth-first traversal of legal forward and reverse moves from that target, retaining starts whose shortest distance is four. This paired-hand graph contains 108 states reachable from a given target; 48 of those are at distance four, which is also the graph's maximum shortest distance. The seeded random stream chooses one of those 48 starts. Consequently every generated puzzle requires **exactly four optimal legal lever turns** before the separate seal press. The generator has no random retry loop and does not assume that arbitrary unrelated hand configurations are reachable.

This distance rule prevents a visually scrambled clock from reducing to a zero-, one-, two-, or three-turn puzzle because earlier turns canceled each other. An independent test enumerates every solution of up to three moves and rejects any generated start it could solve. The current verification covers seeds 0–127 and 271126. The general four-turn property follows from selecting states by shortest graph distance; the tested seeds are the regression evidence for this implementation.

The player can reverse a mistaken operation or reset to the seeded start. Existing Eye pressure makes physical travel between controls part of the challenge; a wrong turn is recoverable and never erases seals earned elsewhere. Once all hands match the target, the player must move to and activate the central seal press. That press rechecks the current hands; briefly passing through the target configuration does not finish the trial. Clock commands share a 0.25-second cooldown. Deposit and vessel attempts use a separate 0.35-second per-actor interval.

A breadth-first solver supplies legal next actions to bots, which still travel to the actual controls and submit the shared spatially validated interactions. When Tinker's eight-second **Overclock** is active and the Clock Room is unfinished, the HUD advises the next solver-recommended lever and direction, or the central press when aligned. The player still travels and uses E or R; guidance never turns a hand or confirms the seal automatically. There is no passive Clock work-rate bonus.

Temporary hand clutches, a persistent midpoint latch, Eye-controlled gear offsets, and a complete Clock Room realm chamber remain future work. The implemented subset uses existing gaze, traps, and shadows for pressure.

## Shared implementation boundaries

All trial actions are inactive during preparation and after the match ends. Ownership cleanup may still release carried objects after termination. Completed seals remain permanent. The last active seal starts the existing fresh escape window, and the human survivor holds E at the open north door to leave. Actor validity, physical reach, and line of sight are checked by the shared world interaction path for humans and bots.

The prototype retains local survivor-versus-AI-Eye and Eye-versus-four-AI-survivors modes. It adds no netcode, online lobby, new realm, annex, new bespoke Eye power, mid-match save, or full replay system. The existing character archetypes, Second Sight recovery, and procedural art/audio remain the presentation foundation. Versioned release notes record balance changes separately from contract choice.

Implementation authority is in [TrialSet](../../game/scripts/trial_set.gd), the [physical interaction dispatcher](../../game/scripts/trial_world.gd), and the [apparatus builder](../../game/scripts/trial_apparatus.gd). The [UE5 contract specification](../technical/CONTRACT_TRIAL_IMPLEMENTATION.md) describes the intended port; it is not a compiled Unreal implementation.

## Verified scope and remaining release gates

The following results were obtained with Godot 4.7.2 for the current implementation. Counts and route times are evidence for these named checks, not performance targets or a general difficulty-balance claim.

| Check | Result | Scope |
|---|---|---|
| [Alternate-trial domain suite](../../game/tests/test_trial_set.gd) | 23 cases; 2,098 assertions; zero failures | Contract selection, ownership, checkpoints, reversible controls, explicit confirmation, lifecycle guards, and generated Clock solutions |
| Clock short-solution exclusion within that suite | 129 seeds; no solution in zero through three turns | Seeds 0–127 plus 271126; legal forward and reverse move enumeration independent of the gameplay solver |
| [Physical world suite](../../game/tests/test_second_world.gd) | 16 cases; 137 assertions; zero failures | Spatial guards, cargo recovery, ring occupancy, physical controls, inactive apparatus, and complete bot routes |
| Second plus all eight Seeded Mix bot routes | Nine complete escapes; zero wounds | Ordinary bot movement, shared interaction commands, eight-second preparation, three seals, and real exit interaction; human Eye left idle |
| [Second survivor route](../../game/tests/test_second_survivor_route.gd) | Escape at 324.17 simulated seconds; 80 HP; 11 wounds; one successful Second Sight; four Clock turns | Keeper, Story, seed 271126, active AI Eye, normal input/physics, and no driver overrides of position, health, timers, or progress |

The unopposed Second bot route completed in 81.08 simulated seconds; the eight mixed routes completed in 46.03–89.02 simulated seconds. Those runs establish physical task reachability with several bots. The active Story survivor run separately establishes a complete pressured route, including legitimate recovery and movement inside the ritual ring. Its informed scripted driver knows the map and puzzle clues; it does not substitute for first-time human usability testing or validate every difficulty and archetype.

Six final Godot renderer captures were visually inspected after correcting world-label and manual overlap. The published v0.2.0 executable also passed all six native Windows headless startup cases: both roles under First, Second and Seeded Mix. The [verification report](../qa/V0_2_VERIFICATION.md) links the exact source revision, archive hash, workflow and machine-produced Windows evidence. This does not establish graphical Windows driver compatibility, a complete interactive Windows playthrough or hardware performance. Blueprint assets still require creation, compilation and playtesting in Unreal Editor, and online authority remains planned.
