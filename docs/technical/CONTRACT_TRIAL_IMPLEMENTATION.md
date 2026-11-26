# THE EYES — six-trial contracts and Blueprint construction

This is the UE5 construction specification for the v0.2 Godot rule contract in [`trial_set.gd`](../../game/scripts/trial_set.gd). It extends the [original Blueprint foundation](UE5_BLUEPRINT_IMPLEMENTATION.md). All Unreal classes and graphs named here must still be authored in Unreal Editor; the CSV files are source data and are not imported `.uasset` tables. No UE5 runtime, replication or packaging result is claimed by these instructions.

The gameplay definitions below follow the local prototype. The networking, save and editor integration choices are a proposed UE5 implementation. Keep those two evidence levels separate when reviewing the port.

## 1. Identity: a seal slot is different from a trial

| Physical bay | Stable slot ID | First trial / catalogue | Second trial / catalogue |
| --- | --- | --- | --- |
| Northwest | `silent` | `silent` / T02 | `vault` / T24 |
| Northeast | `echoes` | `echoes` / T05 | `ritual` / T10 |
| South | `relay` | `relay` / T08 | `clock` / T16 |

The three existing slot IDs remain stable so the exit still requires exactly three seals. They do not name the active apparatus. `SlotId=silent, TrialId=vault` is valid. A HUD must obtain the trial's display name through the registry, rather than label that seal “Silent Countdown.”

Contract IDs are exactly `first`, `second` and `mix`; **Seeded Mix** is a display label. `mixed` is not the canonical saved/network ID. The local rule module falls back to `first` for an unknown contract. The proposed network admission layer should reject an unknown requested contract with a readable reason before starting a match, then let the host explicitly choose a supported value.

Use [`DT_TrialRegistry.csv`](../../unreal/Data/DT_TrialRegistry.csv), [`DT_TrialSlots.csv`](../../unreal/Data/DT_TrialSlots.csv) and [`DT_Contracts.csv`](../../unreal/Data/DT_Contracts.csv). Import schemas and field types are in the [data handoff](../../unreal/Data/README.md). `BlueprintAssetName` is an authoring identifier; it is not a claim that an asset path already resolves. After creating each class, assign a real class reference in the editor-owned registry asset and validate all six references before admitting a match.

## 2. Components and data ownership

Add `BPC_TrialContracts` to `BP_EyesGameMode`. It owns the resolved slot selection, private puzzle definitions, active child registration and one-time seal admission. The GameMode exists authoritatively on the server in the planned multiplayer implementation. Publish only the intended public snapshot through `BP_EyesGameState`. See Epic's [GameMode/GameState framework](https://dev.epicgames.com/documentation/en-us/unreal-engine/game-mode-and-game-state-in-unreal-engine).

Create these child classes under `/Game/TheEyes/Trials/`: `BP_TrialMemoryVault`, `BP_TrialRitualCircle`, and `BP_TrialClockRoom`, each extending `BP_TrialBase` and implementing `BPI_Trial`. Use the existing `CanInteract`, `ReceiveValidatedAction`, `GetPublicTrialState`, and `AbortParticipant` contract. Do not add a client-callable completion shortcut.

| Owner | Field | Blueprint type | Authority / replication |
| --- | --- | --- | --- |
| GameMode contract component | `ContractId` | Name | Server choice, locked before Preparation |
| GameMode contract component | `MatchEpoch` | Integer | Increment for a new match; server only copy drives validation |
| GameMode contract component | `ResolvedSlots` | Array of `ST_ResolvedSlot` | Server; publish filtered snapshot |
| GameMode contract component | `TrialBySlot` | Map of Name to BP_TrialBase reference | Server only; never accept client class/path values |
| GameState | `ContractSnapshot` | `ST_ContractSnapshot` | RepNotify, shared |
| TrialBase | `SlotId`, `TrialId` | Name | Immutable after registration; replicated public identity |
| TrialBase | `TrialEpoch`, `Revision` | Integer | Attempt/match freshness and snapshot ordering |
| Survivor cargo component | `Cargo` | `ST_CargoState` | Server-owned; RepNotify for visible item/own prompt |
| Memory Vault | `Targets` | Integer array, length 4 | Server; reveal through legitimate clue presentation |
| Memory Vault | `Cradles` | Integer array, length 4 | RepNotify; -1 empty, otherwise an accepted relic 0–5 |
| Ritual Circle | `Sequence` | Integer array, length 5 | Server; presentation reveals the required clue |
| Ritual Circle | `LitPrefix`, `BankedPrefix` | Integer | Coherent public trial snapshot |
| Ritual Circle | `HoldSeconds` | Float | Server elapsed time; public progress/deadline view |
| Ritual Circle | `EmberOwner` | Participant ID / actor reference | Server; replicate visible carrier when relevant |
| Clock Room | `Hands`, `Target`, `Start` | Integer arrays, length 3 | Server writes; public mechanism snapshot |
| Clock Room | `ReadyAt` | Real | Server clock-command deadline |
| Trial action gate | `ActorReadyAt` | Map of participant ID to Real | Server only; deposit/vessel rate state |

`ST_ResolvedSlot` contains `SlotId` Name, `TrialId` Name, `TrialEpoch` Integer and `Complete` Boolean. `ST_ContractSnapshot` contains `Revision` Integer, `MatchEpoch` Integer, `ContractId` Name, `RulesVersion` String and an **array** of resolved slot records. Use a small replicated array of structures, with stable IDs, rather than relying on iteration order or assuming a replicated Blueprint Map is supported. Blueprint structs are authored through the editor's Structure asset workflow; Epic documents [struct variables, nested fields and split pins](https://dev.epicgames.com/documentation/en-us/unreal-engine/blueprint-struct-variables-in-unreal-engine).

`ST_CargoState` contains a kind (`None`, `Mote`, `Relic`, `Ember`), stable item ID, carrier participant ID and an ownership revision. Make it the single authority for objective carrying. The original `CarriedMote` convenience reference must derive from it after this migration; two independent cargo authorities can otherwise allow a mote and an ember in the same hands.

## 3. Resolve a contract once

Create `ResolveContract(ContractId, MatchSeed)` on `BPC_TrialContracts`:

1. `Switch Has Authority` → authority branch only. Require Lobby/preparation admission and no active match. `Get Data Table Row` for the exact contract key; fail admission when missing.
2. Initialize a dedicated layout `RandomStream`. Use explicit seed initialization, not a Blueprint instance's automatically generated initial seed. Epic documents `Make Random Stream`, `Set Random Stream Seed` and the stream-specific random nodes in [Random Streams](https://dev.epicgames.com/documentation/en-us/unreal-engine/random-streams-in-unreal-engine).
3. Iterate the explicit slot order `[silent, echoes, relay]`. Read the slot row and the matching northwest/northeast/south variant field from the contract row. Value 0 chooses `FirstTrialId`; 1 chooses `SecondTrialId`; -1 uses one `Random Bool from Stream`. Other values reject the configuration.
4. Resolve the chosen ID in the six-trial registry. Require matching `SlotId`, a valid child class and an authored spawn anchor for that bay. Add one `ST_ResolvedSlot`. Reject duplicates, missing bays or an active count other than three.
5. Generate each admitted trial's puzzle in its own random stream. Persist the resolved values before any client receives control. Record `RulesVersion=0.2.0` for this rule set.
6. Spawn/register the chosen child at the bay anchor. Spawn no inactive child, or explicitly disable its collision, overlap generation, tick, visibility, interactable registration and objective item spawners. Merely hiding a mesh leaves invisible interactions possible.
7. Publish `ContractSnapshot` in one revision and start Preparation. Every later action must match the registered actor, slot, trial ID and epoch. A stale reference to the prior contract's apparatus fails before any inventory/progress mutation.

There are eight possible mixed selections. Their existence follows from three independent binary choices; it does not mean an arbitrary list of eight seeds necessarily covers all combinations. Record the resolved slot tuple in coverage tests.

### Cross-engine seed boundary

The Godot rule module uses separate seeds derived with these XOR salts: layout `0x534554`, vault `0x5641554C54`, ritual `0x52495455414C`, clock `0x434C4F434B`. These are a description of the Godot implementation, **not** a promise that UE's random stream yields the same sequence. Some salts exceed a 32-bit integer, while Epic documents an integer initial seed for its Blueprint stream node. Do not silently narrow them and call the result a compatible port. See [Make Random Stream](https://dev.epicgames.com/documentation/en-us/unreal-engine/BlueprintAPI/Math/Random/MakeRandomStream).

For an exact migration fixture, import the resolved slot IDs, four vault targets, five ritual indices, three clock target values and three clock start values. For native UE generation, define/version UE-specific stream seeds and validate the generated result. Keep the original Echo stream independent so adding a cosmetic or alternate-trial draw does not perturb it.

## 4. Shared action admission

All world interactions route through the owned PlayerController's server request function. Bind identity to the server's possessed pawn; never accept an arbitrary participant ID as proof of ownership. Reuse the framework's range, physical trace, phase, life, request-sequence and target-registry checks. RPC ownership rules are documented by Epic in [Remote Procedure Calls](https://dev.epicgames.com/documentation/en-us/unreal-engine/remote-procedure-calls-in-unreal-engine).

After common admission, require `Target.TrialId == ResolvedSlots[Target.SlotId].TrialId`, matching match/trial epochs, active Hunt/Escape as allowed by the trial, and `Complete=false`. The local prototype pauses trial mutation in Preparation and after the result; preserve that boundary. Cleanup of already-held cargo remains legal after a result but cannot change a seal.

The general controller request budget remains an initial network-design ceiling of eight interaction requests per second. Individual trial rules are tighter: **0.35 s per actor** for real vault deposit and ritual vessel attempts, and **0.25 s globally** for clock operations. Store server deadline timestamps rather than decrementing a client timer. A wrong eligible deposit/vessel attempt consumes its interval; an invalid index, empty cargo or already-filled destination rejects without a gameplay commit. Repeated use of an already-lit ritual vessel is a harmless no-op.

Use a server function without latent nodes between validation and commit. Update ownership and progress before dispatching presentation events. `OnRep` handlers refresh visible state idempotently; they do not consume cargo or award a seal again.

## 5. Memory Vault graph recipe

Author six relic actors with stable indices: **0 Orb, 1 Spire, 2 Cube, 3 Ring, 4 Crown, 5 Diamond**. Author four numbered cradle actors with indices 0–3. Each actor has a separate readable silhouette, an interaction collider, an origin transform for recovery, and a registered parent-trial reference. Accepted placements may be completed in any order; each cradle has its own exact target.

### Setup

Create integer array `[0,1,2,3,4,5]`. Use a stream-driven Fisher–Yates permutation: for indices 5 down to 1, call `Random Integer in Range from Stream(0, Index)`, exchange the two entries, then take the first four. Validate length/range/uniqueness and initialize `Cradles=[-1,-1,-1,-1]`. The clue board shows the four target silhouettes with cradle numbers through the chosen reveal policy. Colour supplements shape and text.

### Pickup

`ReceiveValidatedAction(PickupRelic)` → common gates → relic index 0–5 → cargo kind None → relic is neither already banked nor owned by another participant → set relic ownership and participant cargo together → increment ownership revision → attach its representation to the approved carry socket → publish updated state. Two players requesting the same relic in one server tick are serialized; the second request sees the first ownership commit and fails.

### Deposit

`ReceiveValidatedAction(DepositRelic)` → common gates → cradle index 0–3 → empty cradle → carrier owns a relic → actor deadline elapsed → set next deadline to server time +0.35. Compare carried index with `Targets[CradleIndex]`:

- Wrong: send rejection feedback, keep cargo, preserve all cradles.
- Correct: set `Cradles[CradleIndex]` to the relic ID, clear carrier ownership, lock the relic to the cradle, increment revision and publish. Only then emit an accepted-deposit event.

If no cradle remains -1, call the guarded trial completion path once. A duplicate request cannot match an empty destination or held item anymore. Do not use a global “four pickups” counter as proof of completion.

### Release and recovery

On lethal wound, disconnect policy, invalid carrier destruction or deliberate drop, clear the cargo owner and return the unbanked relic to a reachable authored origin or approved drop anchor. Recheck collision and navigation. A banked relic never respawns into the pickup pool. The local `release_actor` rule removes unbanked ownership; the world is responsible for displaying/recovering the released item. The UE equivalent must preserve the same division.

## 6. Ritual Circle graph recipe

Place five interactable vessel actors, one ember cradle, a readable five-symbol clue, and a ring overlap volume with an unambiguous ground boundary. Generate a permutation of `[0,1,2,3,4]` using its own stream. Set `LitPrefix=0`, `BankedPrefix=0`, `HoldSeconds=0`, and no ember owner.

### Ember and vessels

A legal ember pickup requires an empty cargo slot, no current ember owner, an incomplete ritual and fewer than five lit vessels. Reserve the unique ember and assign it to the survivor's cargo in one commit.

For a vessel action: common gates → vessel index 0–4 → current ember ownership → not already lit → actor deadline elapsed → set deadline to now +0.35. Compare the vessel ID with `Sequence[LitPrefix]`.

On a correct answer, increment `LitPrefix`. If it is now 2 or 4, set `BankedPrefix=LitPrefix`. Refresh every vessel from the accepted prefix of the sequence. At five, clear ember ownership, return its representation to the cradle or dormant state, and enable the final ring step. No seal is awarded yet.

On a wrong answer, set `LitPrefix=BankedPrefix`, set `HoldSeconds=0`, clear ember ownership and return the ember to the cradle. Refresh all vessels from the surviving prefix. The wrong request must not erase banked pairs or instantly hand the ember back to a remote player. They must physically retrieve it again.

### Continuous occupancy

On an authoritative fixed update, after the five-vessel prerequisite, query the ring's overlapping survivor actors. The Godot rule uses a **2.8 m horizontal radius** and rejects an actor whose foot origin is more than 0.5 m above/below the arena floor. For the UE construction, use 280 cm for the ring radius and compare the survivor's foot position with the authored ring floor, accounting for the Character capsule origin. Filter destroyed actors, eliminated/escaped/downed/ineligible states and non-participant objects. One or more eligible survivors inside means occupied. A body-shaped physics prop does not count.

If occupied, add authoritative elapsed seconds once, regardless of the number of survivors, and clamp to eight. **Moving within the ring preserves the hold**; no stationary requirement, held interaction key or per-step reset is part of this rule. Survivors can circle within its boundary to manage gaze pressure. If unoccupied, set only `HoldSeconds` to zero. At eight, call the guarded completion path. Two survivors do not halve the hold time; one can replace the other without an empty sampled interval. Retain all five lit vessels when the ring empties.

Use a server timer or tick cadence suitable for this eight-second action and derive elapsed time from the authority. Do not add one frame's requested duration per overlap actor or accept a client “held for eight seconds” message. For a temporarily paused local game, no gameplay elapsed time accrues; an online options menu does not pause the authority.

## 7. Clock Room graph recipe

Place three visible hand meshes, three separate physical levers, a reset control and a central seal press. Each hand index is an integer in 0–5. The three forward transforms, also provided in `DT_ClockLevers.csv`, are A `(1,1,0)`, B `(0,1,1)`, C `(1,0,1)`. Reverse multiplies the chosen transform by -1.

### Modular update

Create pure Blueprint function `Wrap6(Value)` with integer nodes `((Value % 6) + 6) % 6`. The second positive adjustment is required for negative intermediate values. `ApplyLever(Hands,LeverIndex,Direction)` rejects any lever outside 0–2 or direction other than -1/+1, reads the corresponding transform, and applies `Wrap6` to each hand. Never rotate the visual mesh and then infer integer state from approximate world angles.

Generate three target values in 0–5, then choose the starting state by **shortest-path distance**, using the bounded graph walk in `TrialSet._clock_distant_starts`. A fixed number of random scramble moves is insufficient because reversible moves can cancel and leave an almost solved puzzle.

The current coupled transforms reach **108 configurations** from a given target. **48 configurations have a shortest solution of four lever commands.** The generator picks one of those 48 using its dedicated clock stream, so every generated start requires at least four commands; the current graph's selected candidates are exactly four commands away. This is a count of legal lever operations, excluding travel and the final central confirmation. These values follow the current transform graph and are covered by the domain suite; a future transform change must recompute the candidates and update its rules version.

Create Blueprint function `BuildDistantStarts(Target, MinimumCommands=4)`:

1. Encode `A*36+B*6+C`; initialize a 216-entry Integer distance array to -1, set the target entry to 0, and queue the target state. Maintain a queue cursor and an initially empty candidate array.
2. While the cursor is below queue length, read the state's recorded shortest distance. If it is at least four, append it to candidates and do not expand it further.
3. Otherwise, evaluate each of the three forward and reverse transforms with `Wrap6`. For an unseen neighbor, set its distance to current +1 and enqueue it exactly once.
4. After the bounded traversal, require a nonempty candidate array. The present transforms produce the 108 reachable states and 48 candidates above. Select one candidate with the clock random stream. Do not retry random scrambles until a difficulty threshold happens to pass.
5. Store the selected start and target as resolved configuration. On reset, copy that same stored start; never generate a new puzzle.

Arbitrary independently chosen start/target triples are not necessarily connected under these transforms. A validator must find a legal route before admitting externally imported puzzle data. Preserve the minimum-four-command constraint for a new v0.2-compatible match; when resuming a legitimate in-progress state, a shorter remaining solution is expected and must not cause rejection.

### Turn, reset and confirmation

All three operations share `ReadyAt` on the trial actor. Common gates → server time at least ReadyAt → action-specific bounded payload:

- Turn: compute next integer hands, increment move count, set ReadyAt to now +0.25, publish the snapshot.
- Reset: copy immutable Start to Hands, set move count to zero, set the same deadline, publish. Reset does not reroll the seed or target.
- Confirm: set the same deadline, then compare all three Hands with Target. Wrong confirmation leaves the hands intact and reports feedback. Exact equality calls guarded completion.

The confirm action must target the actual central press, with its own spatial trace/range checks. Reaching the target while operating a remote lever cannot auto-complete the trial. After completion, reset/turn/confirm are inert.

Visual rotation derives from each integer hand value and an authored zero-angle offset. Interpolate presentation for readability, while interactions and comparison always use the discrete authority state.

### Physical bot solution

A blueprint breadth-first solver uses at most 216 encoded array positions and visits no more than the current connected component's 108 states. Encode a state as `A*36+B*6+C`; maintain fixed-size visited/predecessor/move arrays and a queue. Expand each legal forward/reverse lever move once per state, stop when target is found, then reconstruct the path. Compute this outside per-frame rendering; cache by the actual starting hands and invalidate on a state change. The solver reports the remaining route, which can become shorter than the generator's initial four-command minimum after legitimate progress.

The solver returns `(LeverIndex, Direction)` actions. It must not set Hands or call CompleteTrial. The bot travels to the selected lever, faces/reaches it, submits the same legal interaction, waits for the shared cooldown, and replans if another actor changed the hands. Once aligned, it moves to the central press and submits confirmation.

The Godot v0.2 Tinker extension uses its existing eight-second Overclock window to show the next legal lever/direction as advice, or the central press when aligned. It does not apply the move, change the cooldown or auto-complete the clock. For the UE port, deliver any equivalent clue only to the eligible owning participant, derive it from current authoritative hands, and invalidate it after another operation changes the state. The player still travels and operates the physical controls.

## 8. Bot task extensions

Extend the existing survivor blackboard with `ActiveTrialId` Name, `CargoKind` enum, `CargoItemId` Name, `TargetActor` Object, `DesiredLever` Integer, `DesiredDirection` Integer and `ObservedTrialRevision` Integer. Keep private solution state in the server controller; do not publish it to human clients.

| Active trial | Action selection | Completion evidence |
| --- | --- | --- |
| Vault | Choose an unfilled cradle; reserve its available relic; travel/pick up; travel/deposit | Accepted cradle snapshot, not arrival at a waypoint |
| Ritual | Retrieve ember if needed; travel to next legal vessel; after five, occupy ring | Five accepted vessels plus actual continuous occupancy |
| Clock | Compute next legal lever move; travel/interact; replan on revision change; travel/confirm | Accepted central press while all three hands match |

Reuse recovery/escape priorities above objective work. A bot carrying a released relic must clear its stale plan. When blocked, retry a path or select a legal recovery action; never teleport cargo or simulate an interaction from its former destination. The Eye AI receives the same observable noise, visible carriers and legal targets as other contract variants. A contract change does not grant a new bespoke Eye power.

## 9. Completion and migration checks

`CommitSeal` receives an actor reference and explicit SlotId/TrialId/Epoch. Check the registered actor identity, active configuration, not-ended match and unawarded slot. Mark that slot complete, publish one new snapshot revision and emit its event once. On the third seal, start the existing **fresh escape window**. Do not add three extra seals or reuse elapsed Hunt time as escape time.

Before claiming a UE5 port works, perform these checks in an actual compiled Blueprint/editor build:

- Import all scalar CSVs with no missing/extra-field warnings and inspect typed row values.
- Admit First, Second and all eight resolved Mix combinations; only three active apparatus sets interact.
- Reject stale epoch, inactive child, wrong-slot, out-of-range and occluded requests without progress.
- Race two players for one relic; replay an accepted deposit; reject a wrong cradle without consuming cargo.
- Exercise ritual mistakes immediately before/after both banks, repeat an already-lit vessel, move continuously inside the 280 cm ring, cross its boundary/re-enter, and test two simultaneous occupants.
- Apply each clock move followed by its inverse from every state; verify 108 reachable states, 48 four-command start candidates and a minimum-four-command generated solution; reset after edits; confirm wrong/aligned states at the real press; verify the global cooldown across two controllers.
- End the match while an interaction is pending. Later commands cannot alter seals; released cargo remains recoverable where the lifecycle policy requires it.
- Restore a client snapshot midway through each trial and verify its visual state without replaying old events.

The Godot suites and CI checks are separate evidence for the prototype. They cannot prove Unreal import, Blueprint compilation, network behavior or UE frame time.
