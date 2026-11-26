# THE EYES — Third Observance construction contract

## 1. Evidence boundary and source ownership

The executable rule definitions are the Godot files [`third_trials.gd`](../../game/scripts/third_trials.gd), [`third_world.gd`](../../game/scripts/third_world.gd) and [`third_apparatus.gd`](../../game/scripts/third_apparatus.gd). `TrialSet` composes the rule domain; `EyesTrialWorld` delegates its new spatial actions; `EyesTrialApparatus` owns the selected presentation child. The existing director remains the authority for the three seals, match phase, timeout and escape.

The UE5 section below is a **Blueprint construction specification**. CSV tables and named classes are source instructions. They are not imported `.uasset` files, compiled Blueprint graphs, a running Unreal level or a packaged Unreal game. Unreal execution and network behavior need their own editor and runtime validation.

| Layer | Responsibilities | Must not do |
| --- | --- | --- |
| `ThirdTrials` | Seeded puzzle state, unique cell ownership, charge, continuous hold accounting, checkpoints, cooldowns, one-time completion | Query scene geometry or accept arbitrary world positions as validated proof |
| `EyesThirdWorld` | Registered actor/life checks, range, line of sight, movement, held input, refuge coverage, informed bot tasks, lifecycle cancellation | Award a seal directly because a visual looks complete |
| `EyesThirdApparatus` | Cells, refuge rings/lamps, rope tags/cage/safety catches, bell silhouettes/score/damper, visible carried cells | Alter authoritative puzzle progress in a rendering callback |
| `TrialSet` / director | Contract selection, legacy cargo compatibility, progress adaptation, permanent seal admission, match state | Count the same bay more than once |
| Main controller | Input routing, pause/damage hooks, existing Eye noise perception, HUD/result integration | Turn an action into a remote completion shortcut |

The world is the physical boundary. Pure domain tests establish state invariants; they do not establish reachability or visibility. Both are required before a feature is represented as playable.

## 2. Four contracts, three stable slots

The registry contains nine trial IDs. Stable slots remain `silent`, `echoes`, `relay`, in northwest/northeast/south order. Each slot has a three-element candidate list:

| Slot | Variant 0 | Variant 1 | Variant 2 |
| --- | --- | --- | --- |
| `silent` | `silent` | `vault` | `light` |
| `echoes` | `echoes` | `ritual` | `strings` |
| `relay` | `relay` | `clock` | `chimes` |

`first`, `second` and `third` choose variants 0, 1 and 2 respectively. `mix` consumes one selection-stream draw in the inclusive range 0–2 per bay. There are 27 combinations, each still requiring three seals. `grand_mix` is not an admitted contract.

`DT_TrialSlots.csv` adds `ThirdTrialId`; the editor-owned `ST_TrialSlotRow` must add that Name member before import. `DT_Contracts.csv` retains its existing scalar headers but now admits variant 2 and records rules version `0.4.0`. All runtime references must resolve before a match is admitted.

### Selection migration

The v0.3 Mix algorithm drew 0–1. Expanding its range deliberately changes historical Mix seed mappings. Do not reinterpret a saved v0.3 result using the v0.4 selector. Preserve its version and resolved mapping. The local result ledger is a post-match record, not an authoritative save/resume or replay system.

Independent puzzle streams keep rope and bell generation independent of contract-selection draw count. Godot and Unreal random-stream implementations are not promised to generate identical puzzles from one numeric seed. A future cross-engine replay format must store the resolved puzzle or define a shared tested generator.

## 3. Domain API and event ordering

`configure(seed, mapping)` clears transient state and leaves the domain inactive. `set_live(true)` admits play; `set_live(false)` interrupts continuous work. `step(delta)` advances cooldowns only while live and with a positive finite delta.

| Domain operation | Purpose |
| --- | --- |
| `pickup_cell(actor_id, cell)` | Reserve an available, unbanked numbered cell for one actor |
| `carried_cell(actor_id)`, `cell_available(cell)` | Read ownership and bank state |
| `charge_for(actor_id)` | Read individual lamp charge; a newly admitted actor starts at 100 |
| `update_light_charge(actor_id, delta, in_refuge)` | Apply the one valid recharge/drain condition once for that actor/tick |
| `update_light_hold(actor_id, lamp, delta, valid)` | Accumulate or cancel the carrier's physically validated alignment |
| `strings_clue()`, `strings_answer()` | Expose the readable clue and its derived domain solution |
| `update_strings_hold(actor_id, rope, delta, valid)` | Resolve one deliberate cut, with stage freshness and release admission |
| `strike_bell(actor_id, bell)` | Accept a bounded discrete note or a meaningful wrong strike |
| `toggle_damper(actor_id, bell)` | Move/remove the single shared damper after its cooldown |
| `interrupt_actor`, `interrupt_all` | Cancel incomplete work without erasing checkpoints |
| `release_actor(actor_id)` | Return owned cell and cancel that actor's work |

The `cargo_admission` callback lets `TrialSet` reject conflicting legacy cargo. The world also rejects carried motes, relics and ember conflicts. This is defense at both boundaries, not a reason to maintain separate contradictory inventories.

State is committed before events are emitted. `light_deposit`, `strings_cut`, `chime_strike` and `chime_error` therefore describe the resulting state. Completion is emitted once after its local completed bit is set. Event consumers may update feedback and pass the signal to the director; they must not reinterpret it as permission to skip the next stage.

### Event vocabulary

| Event | Significant payload / meaning |
| --- | --- |
| `light_pickup` | Actor and cell acquired |
| `light_released` | Actor and cell returned to availability |
| `light_depleted` | Charge crossed from positive to empty; alignment is cancelled |
| `light_deposit` | Actor, cell/lamp, number lit and required total |
| `strings_error` | Actor, attempted rope, current stage, catch duration 3, noise 10 |
| `strings_cut` | Actor, rope, newly banked stage count, required total 3 |
| `damper` | Actor, requested bell and resulting shared damper ID, -1 if removed |
| `chime_error` | Actor, struck bell, current phrase, reset index, noise 10, damped flag |
| `chime_strike` | Actor, bell, old/next phrase, resulting index, banked flag, noise and damped flag |

Wrong bell strikes are admitted actions with failure feedback and cooldown, although the Boolean completion/advance result is false. Code must not equate every `false` return with “no state changed.” Invalid actor/index/cooldown attempts, by contrast, produce no admitted strike event. Use events or explicit before/after state when animating the physical bell.

## 4. Light: ownership, resource and checkpoint graph

The local domain stores `light_cells` as actor-to-cell ownership, `light_lit` as three permanent Boolean checkpoints, `light_charge` per actor and `light_holds` per actor. Cell IDs and lamp IDs are 0–2 internally; user-facing labels are 1–3.

For each valid actor, once per physics update:

1. Determine refuge coverage from the permanent base and already lit lamps. A distance of at most 3 m and an architecture line-of-sight test are both required.
2. In a valid refuge, increase charge by `12 × delta`, capped at 100. Otherwise, if carrying a cell, subtract `4 × delta`, floored at zero. Otherwise retain charge.
3. Resolve the nearby physical alignment candidate. Require the same carried cell and lamp ID, an unlit lamp, positive charge, held E, 1.8 m reach, clear sight and a stationary grounded actor.
4. Feed one eligible elapsed interval into that actor's hold. On any failed eligibility, clear its partial hold.
5. At two seconds, mark the lamp lit, consume ownership, clear the hold and emit the deposit. When all lamps are lit, complete the `silent` slot once.

There is no extra recharge factor for several overlapping refuges and no extra alignment speed from several actors. A released cell retains the actor's remaining charge; dropping and picking it up is not a refill exploit. Restart supplies a fresh domain and fresh charge. Depleted charge limits alignment only, so every layout must retain a reachable base refuge.

For UE5, create `BP_TrialLightInDarkness`, `BP_RefugeLamp` and `BP_LightCell` from the shared trial/interaction contracts. Keep one authoritative cargo record and a charge component per participant. The candidate lamp's interaction region is an admission aid; it does not replace the range/sight validation. Use an array of three lit bits in the public snapshot and include cell ownership revisions so duplicate requests are rejected.

World centimetre equivalents are 300 cm refuge radius and 180 cm action radius. The domain holds remain seconds. Rendering quality, an omitted light shadow or a lowered bloom setting must not alter gameplay refuge coverage.

## 5. Strings: validated logic and stale-hold rejection

For each of three rounds, generation starts with curved IDs `[Circle, Crescent]` and angular IDs `[Triangle, Diamond]`. Each family can be reversed; each half receives one member of each family, with its local order chosen independently. The clue selects a half and a family. This construction guarantees exactly one valid rope and bounds generation without retry loops.

The world displays tags and the clue. A bot must physically observe before consulting the answer for its task. A future network implementation should publish the same intended clue facts and tag arrangement; secrecy of the raw solution variable is not a substitute for a fair clue.

Each held cut records actor, rope, stage and progress. Changing rope or stage starts a new hold. A two-second resolution clears **all accumulated holds from the old stage**. Actors whose input was held must release it or otherwise break physical eligibility before beginning another cut. This prevents a second helper with 1.99 seconds of stale progress from instantly cutting the new layout.

A wrong cut sets a three-second global safety-catch cooldown and emits noise 10. It changes neither stage count nor earlier banked progress. A correct cut increments the stage and loads the next pre-generated clue. At stage three, the seal becomes permanent. No damaging physics rope or uncontrolled suspended body is needed for the prototype authority.

For UE5, create `BP_TrialStringsOfDespair` with four interaction anchors and a cosmetic cage. Define `ST_StringRound` with four shape IDs, half and family, plus `ST_ContinuousTrialAction` containing actor ID, target, stage/revision and progress. Cancel all actions against the prior revision before publishing the new one. The lowering animation reads the committed stage, with three safety-catch positions. It does not determine whether the stage completed.

The full occupied-cage, balcony and special Eye intervention variants remain outside this construction milestone.

## 6. Chimes: stable identities and noise consequences

Each phrase is a Fisher–Yates permutation of the four stable bell IDs using a dedicated seeded stream. If the two generated phrases are equal, rotating the second by one produces a different phrase without unbounded retries. Each phrase is still a permutation.

The next expected note is selected by `(phrase, index)`. A valid strike sets a global 0.45-second cooldown before resolving correctness. A wrong note resets only the current phrase index and emits noise 10. A correct note advances one index. At index four, increment the phrase and reset the index; after phrase two, complete the `relay` slot once.

The shared damper stores one bell ID or -1. Toggling the already damped bell removes it; another bell replaces it. A global 0.5-second damper cooldown bounds concurrent changes. Correct strikes emit a noise-memory duration of 1 second when damped and 6 seconds otherwise. Wrong strikes always emit 10 seconds. A damper cannot alter a score or excuse an incorrect strike.

Noise is emitted from the actual apparatus position into existing perception. Main sets the Eye's remaining noise memory to the greater of its existing value and the event's duration; the payload values 6/1/10 are seconds in this prototype, not acoustic intensities. It supplies a bounded location clue; it must not create continuous knowledge of a hidden actor's exact movement. Audible effects, bell swing, captions/score and shared damper visuals read the same admitted event. Muting audio retains all solution information.

For UE5, create `BP_TrialChimesOfDoom` and four `BP_ChimeBell` children with stable IDs. Keep phrase/index/damper/cooldown authority in the trial actor, not independently in each bell. A request contains actor and bell identity; it does not contain a client-declared “correct” value. Commit score and noise before replicating the strike event. Do not multicast a second authoritative strike for cosmetic animation.

## 7. Continuous world admission and lifecycle

The local spatial layer first requires a registered, active, non-eliminated, non-downed actor, an active selected trial, a live match and an unpaused tree. It then checks physical distance and an architecture ray. Continuous actions additionally require low horizontal and vertical speed, feet near the supported floor and current input or a current eligible bot intent.

Cancellation is explicit on pause, applied damage, movement, input release, range/sight loss, cargo loss, actor removal and end-of-match. A result screen must not continue work in the background. A death/recovery transition releases cargo before the next task assignment. Completion bits remain permanent through cancellation.

Bots use physical destinations from the apparatus, shared pathfinding and the public action path. Strings and Chimes have operator reservations to avoid several bots repeatedly invalidating one another's clue/score. A lost operator is released. Bot observation takes two seconds at the actual desk; an actor cannot enter that state from across the arena. Moving, rescue or danger can interrupt the current work. These rules are part of the world integration, not a direct-domain “bot completion” call.

## 8. Proposed UE5 authority and replication

Use the existing Blueprint-only GameMode/GameState/trial architecture. All names here identify assets to author in Unreal Editor.

1. Extend `ST_TrialSlotRow` with `ThirdTrialId`; import the updated registry, slots, contracts and third-trial defaults. Validate all nine actual class references.
2. Extend the shared cargo enum and cargo record with `LightCell`. Preserve unique owner, stable object ID and revision checks across old and new cargo.
3. Create the three trial Blueprint classes and their child apparatus. Register one child trial per selected bay. Bind their completion to the director's existing one-time slot admission.
4. Accept player requests through the owned controller/character. Resolve the actor on authority. Reject stale match/attempt revisions and validate phase, life, target, range, sight and cooldown before applying an action.
5. Integrate continuous progress using the authoritative tick clock. Client-supplied delta, completed duration, charge and correct answer are never authoritative inputs.
6. Replicate public states coherently: lit refuge bits/cell ownership, rope stage/layout/clue/catch deadline, and bell phrase/index/damper/strike deadline. Keep an explicit revision for each puzzle-state transition.
7. Drive meshes, lights, rope/cage motion, bell swing and UI from snapshots/events. Use settings to reduce motion without suppressing clues or warnings.
8. On disconnect or life-state change, cancel work and return cargo through the same cleanup path. A subsequent actor cannot inherit a departed actor's partially completed hold.

This is a network design requirement, not a claim of network support in the local Godot build.

## 9. Validation matrix

The release QA report owns counts, logs and observed timings. The following are required scenario families, not declarations that a particular build has already passed them:

| Family | Required evidence |
| --- | --- |
| Selection | All 27 Mix mappings, same-version seed stability, three-seal completion, inactive apparatus absent |
| Light | Duplicate pickup denial, legacy cargo exclusion, matching IDs, depletion/recharge, single-rate overlap, bank permanence, zero-charge recovery |
| Continuous holds | Exact boundary, release/motion/hit/pause interruption, LOS/range rejection, no downed action, no double integration |
| Strings | Unique public-clue solution across seeds, wrong catch and noise, prior bank retention, stage revision and required release |
| Chimes | Distinct valid phrases, wrong first/second note behavior, global strike/damper cooldowns, noise6/1/10, one completion |
| Physical AI | Observation at desk, actual navigation, legal commands, operator loss/reassignment, no cargo or rescue softlock |
| Regression | Existing Solo/Second/Squad rules and routes retained; expected Mix pool expansion accounted for |
| Presentation | Actual renderer frames of each apparatus and relevant UI; clear distinction between staged captures and playthroughs |
| Platform | Twelve native Windows startup combinations, plus separately reported graphical interactive qualification |

The exported Windows matrix consists of Solo, Eye and Squad under First, Second, Mix and Third. Do not present those startup checks as a full graphical Windows match or as an Unreal test.
