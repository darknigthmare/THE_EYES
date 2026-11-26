# THE EYES — Survivor Squad authority and Blueprint construction

**Status:** UE5 construction specification for the v0.3 local squad subset. The Godot implementation lives in [`squad_state.gd`](../../game/scripts/squad_state.gd), [`squad_world.gd`](../../game/scripts/squad_world.gd), `main.gd` and `survivor.gd`. The life authority and physical world adapter have separate responsibilities. Unreal assets named below are assets to create; this repository does not supply compiled squad Blueprints, a playable Unreal map or verified UE networking.

Read the [original framework](UE5_BLUEPRINT_IMPLEMENTATION.md), [six-trial contract extension](CONTRACT_TRIAL_IMPLEMENTATION.md) and [network/persistence contract](NETWORK_AND_SAVE_CONTRACTS.md) first. Keep all project gameplay in Blueprints. Record the exact installed UE version and run the editor acceptance work before calling this port playable.

## 1. Three modes, one match contract

| Requested mode / stable ID | Human controls | Survivor population | Opposition |
| --- | --- | --- | --- |
| Solo Survivor / `survivor` | One survivor | One human | AI Eye |
| Eye / `eye` | Eye in four fixed sockets | Four AI survivors | Human Eye |
| Survivor Squad / `squad` | One survivor and squad orders | One human plus four AI survivors | AI Eye |

`SessionMode` records the requested mode even if a shared internal controller uses survivor movement for both solo and squad. Do not derive it from the possessed pawn class. In v0.3, all three modes use `first`, `second` and `mix`, three active trial slots, and three seals. Version 0.4 additionally supports `third` and expands Mix to 27 selections; apply the [Third Observance extension](THIRD_TRIAL_IMPLEMENTATION.md) alongside these unchanged life/rescue rules. Squad is a local simulation with one human input stream. It is not a network party or multiple local human controllers.

The squad downed/rescue rules apply only to `squad`. They must not accidentally replace solo Second Sight or the existing Eye-mode survivors' life policy. Keep mode admission explicit in GameMode and test the three-mode matrix.

## 2. Assets, data and ownership

Create `E_SquadLife` (`Active`, `Downed`, `Eliminated`) and `E_SquadOrder` (`Work`, `Follow`, `Hold`). Their persisted names are respectively `active`, `downed`, `eliminated`, and `work`, `follow`, `hold`; never persist an enum ordinal as a stable external ID. Gameplay state is server-owned in the proposed Unreal implementation. The current Godot prototype has one local authority and no RPC transport.

| Asset to create | Parent / location | Responsibility |
| --- | --- | --- |
| `BPC_SquadAuthority` | ActorComponent on `BP_EyesGameMode` | Stable member registry, life transitions, exclusive rescue reservations, squad order and wipe arbitration |
| `ST_SquadMemberState` | Blueprint Structure | One member's life, allowance, countdown and rescue state |
| `ST_SquadSnapshot` | Blueprint Structure | Revision, mode, stored order and coherent public roster |
| `BPI_SquadParticipant` | Blueprint Interface | Read identity/status, cancel interactions, apply an already-accepted revival and obtain an interaction origin |
| `BPC_SurvivorStatus` | Existing character component | Actual health, movement eligibility, damage interruption and protection expiry |
| `BB_SquadSurvivor`, `BT_SquadSurvivor` | Blackboard / Behavior Tree | Physical objective, rescue, follow, hold and escape decisions |
| `WBP_SquadRoster` | UserWidget | Read-only team state, tasks and countdowns |
| `IA_SquadWork`, `IA_SquadFollow`, `IA_SquadHold` | Input Actions | B, F, V defaults through the survivor mapping context |
| `ST_SquadDefaultsRow`, `DT_SquadDefaults` | Blueprint Structure / DataTable | Imported scalar construction defaults |

Use [`DT_SquadDefaults.csv`](../../unreal/Data/DT_SquadDefaults.csv). Its row `prototype_0_3` specifies one human, four bots, 35 seconds bleedout, six seconds rescue, 35 health, five seconds protection, 180 cm rescue range, 400 cm Keeper range, 30 healing, a 35-second Keeper cooldown, Keeper self-inclusive/self-first targeting, a 1.8-times-base combined Relay cap and one recovery allowance. Godot distances are metres; these UE values are centimetres. [Engine units reference](https://dev.epicgames.com/documentation/en-us/unreal-engine/units-of-measurement-in-unreal-engine).

### Runtime variables

The replicated snapshot is a presentation boundary. Server-only maps and actor references stay in authority code; clients do not write them through a widget or interface call.

| Owner / field | Blueprint type | Initial value / authority / replication |
| --- | --- | --- |
| Authority `SessionMode` | Name | `squad`, locked on admission |
| Authority `Members` | Map of Name to `ST_SquadMemberState` | Five admitted members; server only |
| Authority `ParticipantActors` | Map of Name to survivor reference | Registered actors; server only |
| Authority `HumanParticipantId` | Name | Admitted leader; server only |
| Authority `Live` | Boolean | False until a live phase; never supplied by client |
| Authority `StoredOrder` | `E_SquadOrder` | Work on a new match; persists until a new accepted order |
| Authority `HoldAnchors` | Map of Name to Vector | Capture authoritative bot positions for Hold; server only |
| Member `ParticipantId` | Name | Stable match-local ID; not an object address |
| Member `Life` | `E_SquadLife` | Active |
| Member `RecoveriesUsed` | Integer | 0, becomes 1 exactly once on accepted rescue |
| Member `BleedRemaining` | Float | 0 outside Downed; 35 on first fall |
| Member `RescuerId` | Name | None when not reserved |
| Member `RescueProgress` | Float | 0–6 seconds, never client-authored |
| Member `LifeRevision` | Integer | Increment for committed transitions |
| Status `Health` | Float | Existing status authority; public team view follows project policy |
| Status `ProtectedUntil` | Float | Authority clock + 5 on rescue; presentation mirrors remaining time |
| GameState `SquadSnapshot` | `ST_SquadSnapshot`, RepNotify | Coherent revision, leader, order and member summaries |
| Controller `LastOrderSequence`, `LastRescueSequence` | Integer | Accepted request stream per epoch; server only |
| Controller `RescueLease` | Struct | Target, sequence, expiry; server only |

The GameMode/GameState separation follows Epic's authority model; these project schemas are original decisions. [Framework reference](https://dev.epicgames.com/documentation/en-us/unreal-engine/game-mode-and-game-state-in-unreal-engine). `OnRep_SquadSnapshot` updates roster widgets, status markers and interpolation targets. It never awards health, changes an order or completes a rescue. The authority invokes the same presentation refresh locally after committing a change, rather than relying on a remote replication callback to run host UI.

## 3. Match setup and life transition recipe

1. In `BP_EyesGameMode`, validate requested mode and contract before spawning. For squad, register one human and four bots with unique stable IDs. Preserve registration order for deterministic ties. Reject duplicate IDs and missing leader registration.
2. Construct Active member records with zero recoveries and no reservations. Reset `StoredOrder=Work`, hold anchors, statistics and snapshot revision for the new match epoch. No previous match's rescue or protection carries across.
3. Bind each status component's accepted-damage notification to the world adapter. Only real applied damage interrupts a helper's rescue; a rejected or fully protected hit must not be treated as health loss.
4. At an accepted lethal fall, check `Live`, current Active state, and the mode before changing anything. If `RecoveriesUsed=0`, set Downed and `BleedRemaining=35`; otherwise set Eliminated with reason `second_fall`.
5. Release every rescue reservation where this member is helper or subject. Clear ordinary work leases and return/drop objective cargo through the existing trial ownership contract, so a downed body cannot retain a required relic indefinitely.
6. Disable movement and harmful-target eligibility for the downed/eliminated member, while preserving the downed actor as a rescue target. Keep health, collision and presentation changes in the world adapter; the pure life authority does not move an actor.
7. If no Active members remain, set the squad inactive and eliminate all remaining Downed members with `squad_wipe`. Otherwise continue the match for eligible members. A human fall alone does not imply total team defeat.
8. Commit all affected states and links before dispatching events. Event handlers must observe the new state. Repeated damage or callbacks cannot emit another elimination, another revival or another terminal team result.

The Godot authority uses `squad_downed`, `squad_revive_started`, `squad_revive_interrupted`, `squad_revived` and `squad_eliminated` events. Elimination reason IDs are `bleedout`, `second_fall` and `squad_wipe`. `member(id)` returns a copy for inspection; callers must use authority methods rather than mutate that copy.

## 4. Physical rescue and cancellation

### Begin

Route `IA_Interact` Started through the owned controller. Prioritize a valid nearby downed teammate over an unrelated trial interaction. In the authority function, resolve helper and subject by registered IDs and require all of these conditions before reserving:

- A live squad phase, Active helper, Downed subject, distinct IDs and the same team.
- Physical separation at most 180 cm and a clear collision trace between the interaction origins. An angular cone alone is insufficient.
- A stationary helper with an uninterrupted interaction hold. Reuse an explicit movement threshold consistent with the physical port tests; do not hide a new tolerance in a widget.
- No different helper already assigned to the subject, and no different subject already assigned to this helper.

Use `Map Find` with success branches, enum comparisons, `Vector Distance`, and `Line Trace By Channel` with the helper ignored. Treat blocking architecture as failure; verify the collision setup with an actual wall. On success, assign both directions of the reservation and set progress to zero. Repeating Begin for the same valid pair is idempotent and must preserve its progress.

### Advance

Create a single authority update event, driven by a looping timer or the match's existing update. `Set Timer by Event` can schedule the update, but elapsed gameplay time supplies the amount advanced: callback count is not elapsed time. Use a stored authority timestamp, explicitly handle pause/resume, and never accept a client-sent delta. Epic documents timer handles, replacement, cancellation and object lifetime behavior in its [timer guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-timers-in-unreal-engine).

Each update first resolves expired bleedout and revalidates life states, range, sight, movement, damage interruption and the continuing hold. Then it adds only validated elapsed time, capped at six seconds. Match the Godot world's defined ordering for same-frame expiry/completion; the acceptance test at the boundary must determine the result, not an incidental Blueprint graph traversal order. A subject already eliminated by bleedout cannot subsequently be revived by a delayed callback.

At completion, atomically set Active, `RecoveriesUsed=1`, zero bleedout and rescue progress, and remove the reservation. Only then emit the accepted revival with health 35 and protection five seconds. Apply those values once in the world adapter. A Boolean return from an advance request means it was accepted; it does not itself mean completion. Hearing an animation cue or reaching a local progress-bar endpoint must never award health.

### Interrupt or freeze

Completed/Canceled input, helper movement or jump, applied damage, range/trace failure, either actor changing life state, actor removal, immediate shadow evasion, match end and explicit pause/freeze all clear the reservation and reset progress. The next valid attempt starts at zero. Clearing a completed reservation again is harmless and emits no duplicate transition. The pause action must call the authority's freeze/cancel operation **before** pausing the scene; stopping the update loop alone would leave a resumable partial hold. Freeze clears every outstanding reservation, then stops commands and countdowns. Resume starts a fresh elapsed-time baseline, so paused wall-clock time cannot drain bleedout or complete a hold.

One rescue consumes the member's lifetime allowance for that match. Keeper, a new helper, a new order or a different chamber never replenishes it. No self-rescue exists. A helper cannot reserve two subjects and two helpers cannot combine parallel progress on one subject.

## 5. Orders and AI behavior

Store the requested order separately from the current task. `Rescuing`, `Escaping` or `AvoidingHazard` describes what a bot is doing now; it is not a replacement player order. Work/Follow/Hold persists until a changed order is accepted or a new match resets it. Follow uses Work as its effective fallback while the leader is inactive; preserve the stored Follow order so the implementation can resume following an active leader consistently.

On Hold, record each bot's own authoritative position and project it onto usable navigation. Never teleport all allies to the human's feet. Immediate visible-shadow evasion precedes rescue; otherwise viable rescue precedes Escape, and Escape overrides ordinary orders. The human can observe surviving ally cameras after elimination using 1–4 or the wheel; camera selection does not transfer authority, possession or damage immunity.

| Blackboard key | Type | Meaning |
| --- | --- | --- |
| `SelfLife` | Enum | Authoritative member state |
| `Leader` | Object / Actor | Registered human survivor |
| `LeaderActive` | Boolean | Whether Follow currently has an eligible leader |
| `StoredOrder`, `EffectiveOrder` | Enum | Requested command and current fallback |
| `RescueTarget` | Object / Actor | One valid downed ally with a reserved helper |
| `RescueTargetId` | Name | Identity independent from the actor pointer |
| `HoldAnchor` | Vector | Last accepted Hold position |
| `ObjectiveActor`, `ObjectiveSlot` | Object, Name | Current shared trial task |
| `EscapeOpen` | Boolean | Match authority's escape phase |
| `MoveGoal` | Vector | Actual navigation destination |
| `HasInteractionLease` | Boolean | Current work or rescue reservation |
| `ImmediateThreat`, `EvadeGoal` | Object / Vector | Perceived nearby shadow and a physically reachable evasion step |

Create an authority-only service that refreshes eligibility and reservations. Use a priority selector with inactive-member stop, immediate visible-shadow evasion, viable rescue, escape, and ordinary order branches. Work calls the existing physical six-trial tasks; Follow approaches a reachable formation offset; Hold returns to or remains near its anchor. Squad Relay work aggregates all valid human/bot contributions once per physics update and caps the total at 1.8 times base. Do not advance the Relay separately per helper or apply that elapsed time again through the solo path. Solo work rates remain unchanged. Rescue navigates into legal range, stops movement, then requests and maintains the validated hold. Aborting any hold task calls the cancellation function. A pathfinding failure releases its reservation so another helper can attempt the rescue. Decorators abort lower-priority work when the phase or life state changes.

The current Godot evasion policy observes shadows within **4.5 m**, with less than **0.7 s** warmup remaining and a clear physical trace. It evaluates sixteen directions for a **2.8 m** step, rejects blocked/out-of-navigation candidates, favors increased distance from the threats and uses slight progress toward the legitimate task as a secondary preference. It cancels the rescue, sets the real movement controller to sprint toward the selected point and labels the temporary task `evade`; it does not teleport or grant invulnerability. When the immediate threat clears, ordinary thinking/path refresh resumes and the stored order or viable rescue can continue. The Unreal port should use centimetre equivalents and actual navigation/trace checks. The intended priority is mandatory; matching a numerical scoring implementation requires its own physical port tests.

These tasks extend standard Blackboard/Behavior Tree mechanisms documented by [Epic](https://dev.epicgames.com/documentation/en-us/unreal-engine/behavior-tree-in-unreal-engine---quick-start-guide); the priority, formation and eligibility policies above are this project's design. Avoid a fake completion timer that grants a bot a seal or rescue without reaching the relevant world apparatus.

## 6. Keeper support and the AI Eye

Keeper selection is authority-side: begin with the caster as a candidate, then collect other active injured team members within 400 cm and clear physical line of sight. Choose lowest health. Self wins an equal-health tie; other ties retain stable registered actor order. A more severely injured caster therefore heals themself even with a mildly injured ally nearby. If no ally qualifies, self remains the target. Apply at most 30 health without exceeding the member's maximum and start the existing 35-second cooldown once. A downed/eliminated actor is never a healing candidate. Mend does not change recovery allowance, finish a rescue or cancel bleedout.

The Eye must consider all eligible survivors in squad mode rather than retain a single-human target shortcut. For each candidate, validate life state, distance, socket/view cone and real collision occlusion. Select from observed candidates with a deliberate fairness policy; every harmful command still passes the same legal-action validation as the human Eye. Recheck line of sight at commitment, because a remembered position is not a present hit. Keep team rescue knowledge separate from the Eye's perception data, and avoid exposing private roster fields as omniscient targeting shortcuts.

## 7. Future network requests and snapshots

These requests are proposed UE5 multiplayer interfaces, not implemented Godot network features. Host-only squad AI follows the same authority functions. RPCs originate on the owning controller; Unreal ownership determines routing. [RPC reference](https://dev.epicgames.com/documentation/en-us/unreal-engine/remote-procedure-calls-in-unreal-engine).

| Request | Reliability / initial ceiling | Server validation |
| --- | --- | --- |
| `Server_RequestSquadOrder(OrderId,Epoch,Seq)` | Reliable / 4 per second | Owned admitted squad leader; allowed live phase; enum allowlist; current epoch; monotonic bounded sequence |
| `Server_BeginRescue(SubjectId,Epoch,Seq)` | Reliable / 4 per second | Owned helper; life/team; subject registry; 180 cm; physical trace; movement; exclusivity |
| `Server_RescueHeartbeat(LeaseId,Epoch,Seq)` | Unreliable / 5 per second | Current own lease; continuing hold; fresh bounded sequence; revalidate physical conditions |
| `Server_StopRescue(LeaseId,Epoch,Seq)` | Reliable / 8 per second | Own current lease; idempotent cancellation |

The initial heartbeat lease expiry is 0.6 seconds, consistent with the existing interaction contract. These are proposed ceilings and require network testing. Client-supplied progress, health, rescue duration, target position or protection expiry is never accepted. A late heartbeat cannot recreate a canceled lease. Rate rejection does not consume the recovery allowance or reset the valid holder's progress. A disconnect clears the connection's lease and follows the separately chosen bot-takeover policy; reconnect cannot reset first-fall allowance or create a second controller.

Publish coherent member snapshots with revision and authority timestamp. Clients can interpolate countdown displays but must accept later authoritative corrections. Keep teammate-visible health/progress separate from the Eye's allowed public view. The local post-match ledger uses schema 3 with `session_mode` and squad counters; it is not a reconnect snapshot or authority credential.

## 8. Acceptance before an Unreal claim

| Check | Required observation |
| --- | --- |
| Mode admission | Survivor has one human, Eye has four survivor bots, Squad has one human plus four bots; requested mode stays distinct in records |
| First and second fall | First fall downs once; rescue restores 35 health/5 s protection; next lethal fall eliminates once |
| Bleedout boundary | 35 s expiry, completion ordering and large-delta behavior are explicit and match the accepted world contract |
| Real rescue geometry | Wall, range, movement, damage and release each interrupt; old progress cannot be resumed |
| Exclusivity | Two helpers/one subject and one helper/two subjects cannot double-count work |
| Frozen match | No life countdown or command progresses; all hold reservations clear; resume has no wall-clock catch-up |
| Events and wipe | Every listener sees committed states; one active ally prevents wipe; no active ally resolves the team exactly once |
| Orders and threats | Work/Follow/Hold change real movement/tasks; visible-shadow evasion cancels rescue and takes a physical safe step; rescue/Escape override ordinary tasks; stored order survives |
| Keeper | Most-injured eligible team member including self, self-first equal-health tie, stable remaining ties, wall/range filters, cooldown and no downed revival |
| Eye perception | Any eligible squad member may be targeted; a hidden or ineligible member cannot receive an occluded command |
| Cargo and trials | Downing releases work/cargo safely; all six trial variants remain completable; no duplicate seal |
| Network proposal | Two-client latency/loss tests prove ownership, lease expiry, stale-message rejection and coherent late snapshots |
| Package/runtime | Real authored Blueprints compile; packaged Unreal mode boots; actual frame and interaction evidence is captured |

Godot domain tests can establish pure life-state behavior. Physical world tests establish actual scene integration. Input-driven routes establish the particular full match executed. Native Windows headless startup verifies the exported Godot executable's requested mode/contract boot. None of these substitutes for Unreal editor import, Blueprint compilation, network tests or a graphical hardware playtest.

## 9. Observed Godot evidence for the v0.3 handoff

The local final gate passed all nine suites in Godot 4.7.2: **121 assertion cases / 2,774 assertions**, two solo completion routes and three Squad completion sessions. The new squad authority contributes 26 cases / 120 assertions; its physical world suite contributes 23 cases / 234 assertions. The physical suite verifies actual six-second rescue, 35 HP/five-second protection, geometry/movement/damage/input/pause cancellation, exclusive reservations, elimination, Keeper selection, orders, spectator/reset behavior and combined Relay integration.

A staged AI helper travels 7.64 m along a real navigation path and rescues the wounded human in 7.50 simulated seconds including travel. The three full Story/Keeper Squad sessions with seed 271126 complete First, Second and Mix at 46.88 s, 86.80 s and 46.72 s respectively. Those final sessions require no rescue; the isolated physical fixture establishes that behavior separately. Five actual native-renderer frames document presentation. Full methods and limitations are in the [verification record](../qa/V0_3_VERIFICATION.md).

These observations concern the local Godot implementation. The exact-commit CI rerun, official export and Windows startup checks are pending at this candidate stage. No Unreal import, Blueprint compilation or network runtime result follows from these Godot results.
