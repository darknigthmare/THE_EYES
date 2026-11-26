# THE EYES — UE5 Blueprint implementation specification

**Document status:** implementation plan for the UE5 version. The runnable prototype is the Godot project in `game/`; the Unreal directory is a content-only starting point. Every `BP_`, `BPC_`, `BPI_`, `WBP_`, `BT_`, `BB_`, `IA_` and `IMC_` identifier below names an asset to create in Unreal Editor, unless a later delivery supplies the actual asset. This document does not pretend that text is a compiled Blueprint graph.

**Language and scope:** English UI and data labels; project gameplay authored entirely with Blueprints. First reproduce the original local three-trial loop in The First Observance, then the [six-trial contract extension](CONTRACT_TRIAL_IMPLEMENTATION.md), [v0.3 Survivor Squad construction](SQUAD_IMPLEMENTATION.md) and [v0.4 Third Observance extension](THIRD_TRIAL_IMPLEMENTATION.md), before adding authoritative multiplayer. The latest local pool has nine trial subsets and four contracts, with three seals per match. The final classic format targets 5–7 survivors against one human or AI Eye. The local Godot modes distinguish one solo survivor, four survivor bots against the human Eye, and a squad of one human plus four AI survivors. These are local simulations, not network implementations.

## 1. Architecture and ownership

The design places rule decisions in the authoritative match layer, world representation in actors, and input requests in owned controllers. Epic's framework separates the server-only GameMode from the replicated GameState; a client cannot use a GameMode instance as its shared match model. This is why this project uses the following split. [Source: Game Mode and Game State](https://dev.epicgames.com/documentation/en-us/unreal-engine/game-mode-and-game-state-in-unreal-engine).

| Asset | Parent | Responsibility | Exists/executes authoritatively |
| --- | --- | --- | --- |
| `BP_EyesGameInstance` | GameInstance | Local settings, menu transitions, selected session parameters | Each process, never the shared truth |
| `BP_EyesGameMode` | GameModeBase | Role admission, match initialization, result arbitration, disconnect policy | Server |
| `BP_EyesGameState` | GameStateBase | Readable match snapshot, synchronized deadline, seal state, result | Server writes; clients receive |
| `BP_EyesPlayerState` | PlayerState | Public roster identity, role, archetype, team status | Server writes |
| `BP_EyesPlayerController` | PlayerController | Local input and widgets; validated server request entry points | Owned client plus server |
| `BP_SurvivorCharacter` | Character | Ground movement, crouch, collision, interaction origin, representation | Server gameplay; owning-client movement support |
| `BP_EyePawn` | Pawn | Fixed-socket camera, constrained aim, visual Eye, ability component | Server gameplay; owning-client view |
| `BPC_SurvivorStatus` | ActorComponent | Health, stamina, gaze exposure, rescue/recovery states | Server |
| `BPC_EyeAbilities` | ActorComponent | Energy, cooldown deadlines, accepted command execution | Server |
| `BPC_Interaction` | ActorComponent | Focus query and prompt selection | Local focus; server revalidation |
| `BP_EyeSocket` | Actor | Stable socket identity, legal transform, permitted view bounds | Authored level data |
| `BP_TrialBase` | Actor | Trial lifecycle, participant registry, completion dispatch | Server |
| `BP_TrialSilent` | BP_TrialBase | Mote delivery and noise pressure | Server |
| `BP_TrialEchoes` | BP_TrialBase | Teaching sequence and ordered response | Server |
| `BP_TrialRelay` | BP_TrialBase | Validated hold work and checkpointed progress | Server |
| `BP_Mote` | Actor | Single transferable objective item with persistent item ID | Server |
| `BP_TrapBase` | Actor | Idle/warning/active/recovery state machine | Server; clients display |
| `BP_Phantom` | Character | Telegraph, navigation, attack and expiry | Server |
| `BP_ExitGate` | Actor | Seal-gated collision, escape volume and feedback | Server |
| `BP_EyeAIController` | AIController | Observation history and legal command selection | Server |
| `BP_SurvivorAIController` | AIController | Objective/cover/recovery decisions for bot slots | Server |
| `WBP_EyesHUD` | UserWidget | Role-specific data display and input hints | Local only |
| `BP_EyesSaveGame` | SaveGame | Versioned local preferences/unlocks | Local persistence |

Do not create one giant Level Blueprint containing every trial. The level places instances and assigns IDs. Shared code lives in components, functions and child actors. Avoid casting a trial to each concrete trial subtype from the GameMode: the base class and interface are the extension points.

## 2. Asset vocabulary and data

Create these enums first:

| Enum | Entries |
| --- | --- |
| `E_MatchPhase` | Lobby, Preparation, Hunt, Escape, Ended |
| `E_PlayerRole` | Survivor, Eye, Spectator |
| `E_SurvivorLife` | Active, Injured, Downed, Recovering, Eliminated, Escaped |
| `E_TrialPhase` | Dormant, Teaching, Active, Succeeded, Failed, Resetting |
| `E_TrapPhase` | Idle, Warning, Active, Recovery, Disabled |
| `E_PowerId` | Trap, Mark, Summon, Blink |
| `E_RequestResult` | Accepted, WrongRole, WrongPhase, BadTarget, Occluded, OutOfRange, CoolingDown, InsufficientEnergy, RateLimited, StaleRequest |

Use names such as `trial.silent_countdown` and `socket.first_observance.north` as persistent IDs. Keep readable text separate. An enum is convenient for four fixed power choices; catalogue content should use stable names so adding the twenty-sixth trial does not renumber saved state.

### 2.1 Structures

| Blueprint structure | Members |
| --- | --- |
| `ST_MatchSnapshot` | Revision Integer; Phase E_MatchPhase; PhaseEndsAt Real; MatchId String; PublicSeed Integer; SilentComplete Bool; EchoesComplete Bool; RelayComplete Bool; AliveCount Integer; EscapedCount Integer; Winner E_PlayerRole; HasWinner Bool |
| `ST_PowerRuntime` | PowerId E_PowerId; ReadyAt Real |
| `ST_TrialPublicState` | Revision Integer; TrialId Name; Phase E_TrialPhase; Progress Float; CompletedCount Integer; RequiredCount Integer; PhaseEndsAt Real; DisplayCue Integer |
| `ST_NoiseEvent` | Source Actor reference; Origin Vector; Loudness Float; OccurredAt Real; Kind Name |
| `ST_ObservedTarget` | Target Actor reference; LastVisibleLocation Vector; LastSeenAt Real; Confidence Float |
| `ST_InteractionRequest` | Target Actor reference; ActionId Name; Sequence Integer; TrialAttempt Integer |
| `ST_TrapState` | Revision Integer; Phase E_TrapPhase; WarningEndsAt Real; ActiveEndsAt Real; RecoveryEndsAt Real; ActivationId Integer |

Use the engine's real-number pin type consistently for server times. Inspect the selected UE5 version's exposed types rather than silently connecting a lower-precision conversion into long-running deadlines. There is no need to persist absolute server times across separate matches.

`unreal/Data` supplies seven actual CSV files and their import schemas: the two original tuning tables plus the v0.2 contract/slot/registry/alternate-default/clock-lever tables. Use separate scalar structures for those imports. Keep nested runtime snapshots out of CSV until their engine-version-specific serialization has an explicit test.

### 2.2 Core variable table

| Owner | Variable/type | Initial value | Replication/visibility |
| --- | --- | --- | --- |
| GameMode | `MatchClosed` Bool | false | Server only |
| GameMode | `TrialActors` Array of BP_TrialBase | Registered instances | Server only |
| GameMode | `PrivateRandomStream` RandomStream | From admitted match seed | Server only |
| GameState | `Snapshot` ST_MatchSnapshot | Preparation data | RepNotify, shared |
| GameState | `DifficultyId` Name | standard | Replicated, shared |
| PlayerState | `ParticipantId` String | Generated by admission | Replicated, public pseudonymous ID |
| PlayerState | `Role` E_PlayerRole | Spectator until admitted | RepNotify |
| PlayerState | `ArchetypeId` Name | veil/tinker/runner/keeper | Replicated |
| PlayerState | `LifeState` E_SurvivorLife | Active | RepNotify |
| SurvivorStatus | `Health` Float | 100 | RepNotify; public health display optional |
| SurvivorStatus | `Stamina` Float | 100 | Replicated as appropriate to HUD policy |
| SurvivorStatus | `GazeExposure` Float | 0 | RepNotify, bounded 0–1 |
| SurvivorCharacter | `CarriedMote` BP_Mote reference | None | RepNotify |
| EyeAbilities | `Energy` Float | 100 | RepNotify |
| EyeAbilities | `PowerRuntime` Array of ST_PowerRuntime | All ReadyAt=0 | RepNotify |
| EyePawn | `SocketId` Name | First socket ID | RepNotify |
| EyePawn | `ValidatedAim` Rotator | Socket default | Replicated |
| TrialBase | `PublicState` ST_TrialPublicState | Dormant | RepNotify |
| TrialEchoes | `AnswerSequence` Integer array | Four seeded symbols | Server only |
| TrialEchoes | `AttemptId` Integer | 0 | Replicated; answers carry it |
| TrapBase | `TrapState` ST_TrapState | Idle | RepNotify |

For replicated actor components, enable replication on both the parent actor and the component. Do not put secret answers in a replicated field and merely hide them in a widget. The detailed visibility contract is in [network and saves](NETWORK_AND_SAVE_CONTRACTS.md).

## 3. Input and possession

Enhanced Input separates conceptual actions from device mappings and permits mapping contexts to change with role or UI state. This project uses that support to avoid keeping Eye and survivor commands active at once. [Source: Enhanced Input](https://dev.epicgames.com/documentation/en-us/unreal-engine/enhanced-input-in-unreal-engine).

| Asset | Value type | Initial desktop mapping | Behavior |
| --- | --- | --- | --- |
| `IA_Move` | Axis2D | WASD; alternate ZQSD profile | Survivor only |
| `IA_Look` | Axis2D | Mouse XY | Survivor or Eye view |
| `IA_Sprint` | Bool | Shift | Hold; server checks stamina |
| `IA_Crouch` | Bool | Ctrl | Configurable hold/toggle |
| `IA_Interact` | Bool | E | Start/stop interaction lease |
| `IA_Jump` | Bool | Space | Survivor movement |
| `IA_Trap` | Bool | Left mouse | One press, one request |
| `IA_Mark` | Bool | Right mouse | One press, one request |
| `IA_Summon` | Bool | Q | One press, one request |
| `IA_Socket1` through `IA_Socket4` | Bool | 1–4 | Request authored socket |
| `IA_Echo1` through `IA_Echo4` | Bool | 1–4 | Only active in Echo response context |
| `IA_Pause` | Bool | Escape | Local menu; pause only offline |

Create `IMC_Common`, `IMC_Survivor`, `IMC_Eye`, `IMC_EchoPanel` and `IMC_Menu`. Give Common the lowest priority, role contexts the next priority, and an open modal panel the highest priority. Remove only this project's role contexts when possession changes; avoid clearing another system's unrelated mappings.

**Blueprint recipe — local role setup:** `OnRep_Role` or local possession notification → `Is Local Controller` → fetch `Enhanced Input Local Player Subsystem` → remove previous role context → add new role context → build matching HUD → set appropriate input mode. Run the same setup explicitly for the listen host after server possession. Focus the selected menu button when opening a keyboard/controller menu.

**Survivor movement recipe:** `IA_Move Triggered` → read Vector2D → obtain yaw-only control rotation → `Get Forward Vector`/`Get Right Vector` → `Add Movement Input`. Bind crouch to `Crouch`/`UnCrouch` and use the Character movement component's collision behavior. Do not implement ordinary player locomotion with `Set Actor Location` every frame.

**Eye recipe:** no movement component, gravity, or movement input. Look adjusts a local desired yaw/pitch within the current socket's bounds. Send bounded aim updates at a limited rate; the server clamps them to valid socket angles. Camera rotation is view state; changing socket is a separately validated action.

## 4. Match clock and result arbitration

These migration defaults mirror the intended prototype rules. Recheck the shipped `TrialDirector` when moving a later build to Unreal.

| Preset | Preparation | Hunt | Escape | Starting/max energy | Regeneration |
| --- | ---: | ---: | ---: | ---: | ---: |
| story | 8 s | 600 s | 90 s | 100 | 4/s |
| standard | 8 s | 480 s | 65 s | 100 | 4/s |
| ruthless | 8 s | 360 s | 50 s | 100 | 4/s |

The escape duration is a replacement phase budget; it is not silently added to a still-running Hunt countdown. The displayed deadline belongs to the current phase. A match's result may be committed only once.

**Initialization recipe:** GameMode `BeginPlay` → authority branch → read admitted preset → register uniquely identified trial actors and sockets → fail development validation if IDs duplicate or any mandatory actor is missing → initialize the match random stream → reset trial states → create Preparation snapshot with deadline `ServerNow + PreparationSeconds` → start a 0.1 s rules timer.

**Timer recipe:** rules timer → return immediately when `MatchClosed` → get current authoritative time → compare with current deadline. Preparation expiry starts Hunt and arms trial interaction. Hunt expiry calls `CommitResult(Eye, TimeExpired)`. Escape expiry calls `CommitResult(Eye, EscapeExpired)`. Regenerate energy using elapsed authoritative time since the last update, clamped to the cap.

**Seal recipe:** trial `OnCompleted(TrialId)` → GameMode verifies registered caller and active phase → set its completion flag only if it was false → increment Snapshot revision → if all three true and phase was Hunt, transition to Escape, assign the escape deadline, open the gate and broadcast a warning cue. Repeated completion events do nothing.

**Escape recipe:** gate begin-overlap on server → valid registered survivor → life state still eligible → phase Escape → passage-direction check through the actual gate corridor → `CommitResult(Survivor, Escaped)`. A small volume placed behind the gate does not award an escape while the gate is locked, nor can spectator overlap win.

**CommitResult recipe:** if `MatchClosed`, return → set `MatchClosed=true` first → write winner, reason, Ended phase and revised snapshot → disable remaining damaging interactions → stop rules timers → send result presentation. The guard precedes cosmetic work or saving, so a simultaneous timer and escape callback cannot create two outcomes. The server's accepted event order resolves the boundary case; record that order for diagnosis.

## 5. Correct gaze and legal targeting

A cone is a candidate filter, not proof of unobstructed vision. The supplied source suggested traces as a starting point; this implementation explicitly performs collision queries after the angle check. Epic's trace documentation describes querying collision along a segment and selecting the first blocking hit. [Source: Traces overview](https://dev.epicgames.com/documentation/unreal-engine/traces-in-unreal-engine---overview).

### 5.1 Channel setup

Create `EyeVisibility` as a **trace** channel in Project Settings → Collision. Walls, closed doors, substantial pillars and opaque cover block it. The Eye's decorative mesh ignores it. Survivors block it on the gameplay capsule or deliberate targeting body; tiny loose decorative props ignore it. Transparent VFX neither block nor grant visibility. A mirror may look transparent while remaining an authored blocker: make the visual and rule clear to players.

Create a separate `Interaction` trace channel. A hand-interaction prompt must never make an object selectable through an intervening wall. Add collision profiles deliberately in the editor; the starter config does not globally reclassify unknown assets.

### 5.2 `CanSeeTarget` function

Inputs: `TargetActor`, `TargetPoint`, `MaximumRange`, `HalfAngleDegrees`. Output: `Visible` plus a rejection reason for development HUDs.

1. Reject invalid target, self, eliminated survivor or disallowed actor type.
2. Set `Origin` from the current socket's Eye origin component, not a client-supplied location.
3. Compute `Offset = TargetPoint - Origin`; reject when its squared length exceeds squared range, or when length is effectively zero.
4. Normalize Offset; dot it with the forward vector of `ValidatedAim`. Require `Dot >= Cos(HalfAngleDegrees)`. Ensure the angle-to-cosine node receives the expected unit.
5. `Line Trace By Channel` from Origin to TargetPoint on EyeVisibility, ignoring the Eye actor. Accept if the first blocking hit belongs to TargetActor or there is no blocking hit before the endpoint.
6. For survivors, test authored chest and head samples. One unobstructed sample grants detection; use the same sample policy for both AI and a human Eye. Crouching behind cover must remove both samples to break sight.

Do not aim through the back of a socket: its orientation limits still apply. Do not use the rendering visibility of a mesh as the collision rule. Store `LastSeenLocation` only on successful detection; subsequent pursuit can use that memory, but a fresh harmful command still needs a fresh legal target.

### 5.3 One transaction for Eye commands

| Power | Energy | Cooldown | Legal target |
| --- | ---: | ---: | --- |
| Trap | 25 | 4 s | Visible idle trap actor |
| Mark | 20 | 6 s | Visible active survivor |
| Summon | 45 | 16 s | Visible admitted spawn anchor with safe spacing |
| Blink | 8 | 2 s | Authored, enabled socket different from current socket |

`Server_RequestPower` lives on the owning PlayerController. The server routes a valid request to the possessed Eye's ability component. Requests on arbitrary world traps are not the ownership path. Epic documents that RPC execution depends on the calling actor's ownership and replication; this contract uses the controller so a world target need not be owned by the requester. [Source: RPCs](https://dev.epicgames.com/documentation/en-us/unreal-engine/remote-procedure-calls-in-unreal-engine).

**Node sequence:** validate ownership/role → phase → sequence/rate limit → power ID → target class/state/registry → distance/angle/line of sight or socket eligibility → energy → cooldown → placement/occupancy checks → subtract energy and set cooldown deadline → execute the accepted power. There must be **no Delay, async load or other latent node between final validation and debit**. Rejection leaves energy and cooldown unchanged. An accepted command may finish its announced animation after the target moves, according to the specific power's rules.

Use `RequestResult` feedback for cooldown or blocked sight rather than silently consuming a click. The HUD predicts only a reticle and potential target; the server's response is decisive.

## 6. Socket travel, traps, mark and summoning

### 6.1 Fixed socket travel

`BP_EyeSocket` components: root scene, EyeOrigin scene, CameraMount scene, decorative mounting geometry and an editor arrow. Variables: `SocketId`, `Enabled`, `MinimumYawOffset`, `MaximumYawOffset`, `MinimumPitch`, `MaximumPitch`, `DefaultAim`, `RoomId`.

`Server_RequestSocket(SocketId)` → registry lookup → reject missing/disabled/current socket → legal Blink transaction → assign EyePawn to exact socket transform with `Set Actor Transform` → update SocketId and ValidatedAim → invoke local presentation handler. On the client, `OnRep_SocketId` plays the short closing/opening eyelid and repositions its camera representation. The authoritative Eye remains attached to a single legal socket throughout. It is not a free-flying spectator camera with a decorative travel animation.

Allow no damaging action during an authored blink transition. Use a timestamp such as `CommandsAvailableAt`, not an unbounded cinematic callback. A skipped animation or packet loss must not leave the Eye permanently disabled.

### 6.2 Trap lifecycle

For the first UE5 map, a proposed spike-floor trap has a 1.2 s warning, a 0.45 s harmful interval, and a 5 s local recovery. These are UE5 tuning proposals, not a claim about unverified prototype VFX timings. `BP_TrapBase` owns the state. The Eye's global command cooldown and each trap's local recovery are distinct gates.

Accepted activation → set Warning state and absolute warning deadline → replicate state → play an expanding floor outline and rising mechanical sound. On warning expiry, evaluate the hurt volume on the server, apply damage once per survivor for this ActivationId, then enter Active. On active expiry retract the hazard and enter Recovery. On recovery expiry restore Idle. A survivor entering during Active may be hit once, but never every render frame.

Clients derive animation phase from the replicated deadline. Rejoining during Warning sees the remaining warning, not a newly restarted full animation. Completion of a match makes all damaging phases harmless. Trap visuals must remain readable with bloom, shadows and particles disabled.

### 6.3 Mark and exposure

Separate **being observed** from **spending Mark**. Observation can fill a readable exposure meter; it should decay after genuine cover. Mark is a deliberate command with its own cost and duration. A proposed UE5 first-pass mark reveals a silhouette to the Eye for 4 s and reduces sprint efficiency; it does not supply line of sight through cover for subsequent damage commands.

Store `MarkedUntil` as a server time, bound its extension, and label the effect for the affected survivor. Keep visual distortion optional. Do not require full-screen flashing to communicate an essential status.

### 6.4 Minion anchor and fairness

Use explicit `BP_SummonAnchor` actors with stable IDs. Proposed first-pass limits: at most two active phantoms; spawn location at least 600 cm from each active survivor; clear capsule placement; a 1.4 s visual/audio arrival warning; 14 s maximum lifetime. Validate these before spending energy. Anchor selection may use the Eye's focus, but the client never sends an arbitrary world transform for an unchecked spawn.

`Spawn Actor` on server → set replicated start/expiry times and target memory → initial harmless arrival phase → activate navigation after the warning → remove on lifetime expiry or match end. A phantom's search behavior respects blocked sight and last-known position. Avoid a target reassignment every tick that lets it track an unseen survivor through the entire map.

## 7. A reusable trial contract

Create `BPI_Trial` with `CanInteract(Participant,ActionId)`, `GetPrompt(Participant)`, `GetPublicTrialState`, `ReceiveValidatedAction` and `AbortParticipant`. Only the server calls the mutating path after interaction validation. Create `BPI_Interactable` for the more general focus prompt. Interfaces describe a call contract; their presence does not itself validate a remote action.

`BP_TrialBase` provides: stable TrialId, room bounds, phase, participant set, cancellation behavior, completion guard, progress dispatcher and a map-local reset function. Every child must specify what remains after a failed attempt. The global rule is that an awarded seal is permanent for the match.

### 7.1 The Silent Countdown

Place three unique `BP_Mote` actors, a receiver and routes with real occluders. Each mote has `MoteId`, `State` (Available/Carried/Delivered), `Carrier` and a safe return transform.

**Pickup:** validate survivor active, empty hands, target available, range and interaction trace → set mote Carried and Carrier → attach presentation to carry socket. **Deposit:** validate receiver, carrier and ownership → detach mote → set Delivered before incrementing count → clear carried reference → update trial count → on three unique IDs, complete. Duplicate messages cannot deliver the same mote twice.

**Noise:** sprint, loud landings and selected interactions emit discrete noise events. Route these to Eye memory as a reported approximate origin, not as automatic perfect sight. Crouching reduces footstep stimulus. The first prototype may use a simpler noise meter; final multiplayer still requires authoritative event generation.

**Recovery:** on downing/disconnect, drop the item at a collision-safe nearby floor position. If it falls outside valid traversal space, return it to its stored safe transform. A lost carry item cannot make the match unwinnable. Failure may interrupt an undelivered carry, never revoke a previously awarded seal.

### 7.2 Trial of the Echoes

Maintain separate Teaching and Response phases. During Teaching, the server schedules visible symbol cues with absolute times. During Response, accept one indexed answer event at a time. The chosen UE5 presentation can use four glyph buttons before the full gesture choreography is authored.

On start → increment AttemptId → choose/store four symbols on server → show cue zero → advance cue timer → enter Response. On answer → validate participant and current AttemptId → reject indices outside 0–3 → compare with sequence at AnswerIndex → correct increments once → fourth correct completes the seal. A wrong answer records an error and resets only current attempt progress. Repeated correct submissions with the same request sequence are ignored.

Provide replay of the teaching cue and a reduced-pressure practice variant. Sound has a matched symbol/number cue. A screen reader or hearing-impaired player must not need to identify pitch alone. Client packets cannot include an entire claimed solved sequence or tell the server the puzzle has completed.

### 7.3 Clockwork Relay

Interaction starts a **hold lease** on the server. The lease belongs to an admitted participant, expires if no heartbeat arrives, and is invalidated by distance, blocked interaction, life-state change or wrong phase. Release/cancel clears it immediately. The server adds work using its own elapsed time, not a client-reported duration.

For an initial migration, use 12 s of total work and protected checkpoints at one-third and two-thirds, matching the current `TrialDirector`. When nobody is actively holding, only the unbanked segment decays, at 1/24 normalized progress per second (about 4.17 percentage points per second); confirmed checkpoints persist. Multiple participants increase work at an explicitly capped rate in the full game. Solo and bot modes remain completable by one worker.

At full work → set progress to one → complete once → release every hold lease. An Eye interruption can displace or pressure the worker but cannot wipe completed work arbitrarily. The animation's gear rotation reads progress; gear rotation itself is not the rules variable.

## 8. Applying the contract to all 25 trials

The full rules for each challenge live in the design bible. This table maps them to reusable implementation families and the key additional technical test. These are **future assets**, including fuller versions of the six prototype families.

| Source trial | Core Blueprint family | Required extension/test |
| --- | --- | --- |
| The Labyrinth of Shadows | Route/state puzzle | Validate a traversable path after every authored wall change |
| The Silent Countdown | Carry/deposit | Drop/return every objective item after disconnect or fall |
| Threads of Fate | Paired traversal | Bound tether force; transfer a disconnected partner to safe AI |
| Light in the Darkness | Timed safe regions | At least one reachable refuge through each transition |
| Trial of the Echoes | Ordered response | Stale attempts, duplicate answers and cue accessibility |
| Bridge of Illusions | Readable tile states | Lock a tile's announced result while a player commits to it |
| Strings of Despair | Symbol/constraint puzzle | Server validates a solvable rope configuration |
| Clockwork Relay | Hold/work | Lost release packet, checkpoint persistence, solo scaling |
| Glass Symphony | Telegraph/cover | Collision and visual glass classifications match |
| The Ritual Circle | Ordered multi-object | Completed ritual stages are not erased by repeated extinguish |
| The Tower of Babel | Placement/socket assembly | Server accepts bounded legal placements; no physics exploit shortcut |
| Mirrors of Deceit | Route/illusion | Real collision remains consistent when reflections change |
| The Abyss Walk | Precision traversal | Fall recovery restores at a valid checkpoint |
| Warden's Chains | Shared radius/puzzle | No dragging a recovering partner into an unavoidable kill |
| The Marionette's Dance | Timed action sequence | Latency window uses server scheduling and bounded input tolerance |
| The Clock Room | Coupled controls | Every generated target is reachable from initial hand state |
| Chimes of Doom | Ordered spatial response | Bells have redundant visual identities and a recoverable error |
| The Spiral Stairs | Moving traversal | Checkpoint is safe before rotating the next flight |
| Strings of Time | Timed route modifiers | Deadline modifiers cannot underflow or extend without cap |
| The Gauntlet | Composite trial | Child failures do not duplicate global completion/rewards |
| The Infernal Carousel | Rotating traversal | Acceleration caps, grounded movement and announced reversals |
| Masks of Fear | Equipment/state matching | Clearly announced corruption never deletes the sole valid mask |
| The Bone Bridge | Resource placement | Resource exhaustion has a recovery mechanism |
| The Memory Vault | Recall/retrieval | Duplicate pickups cannot satisfy two distinct required entries |
| Whispers of the Void | Partial-information routing | Personal clues stay scoped; provide readable equivalent cues |

Do not admit a trial to randomized match selection merely because it exists in the catalogue. Its class, required actors, solo/team scaling and acceptance tests must pass first. Randomization selects from an admitted set and stores the selected configuration.

## 9. AI architecture

Behavior Trees and Blackboards are editor-authored Unreal assets. Blackboards hold decision inputs; services can refresh those inputs at chosen intervals and decorators can abort inappropriate branches. This proposal uses that model without duplicating the legal action code. [Source: Behavior Tree quick start](https://dev.epicgames.com/documentation/en-us/unreal-engine/behavior-tree-in-unreal-engine---quick-start-guide).

### 9.1 Eye Blackboard

| Key | Type | Meaning |
| --- | --- | --- |
| MatchActive | Bool | Hunt or Escape |
| CurrentSocket | Object | Registered socket |
| VisibleTarget | Object | Currently legal observed survivor |
| LastNoisePosition | Vector | Approximate reported sound origin |
| LastNoiseAt | Float | Age/decay reference |
| BestTrap | Object | Legal idle target near observed pressure |
| BestSummonAnchor | Object | Legal spaced anchor |
| DesiredSocket | Object | A better observation location |
| EnergyFraction | Float | Available resource fraction |
| HasLegalPower | Bool | At least one accepted candidate |

Refresh visible candidates at 5–10 Hz, not once per render frame for every possible object. Candidate socket evaluation can run at 1 Hz or when a significant event occurs. These are starting budgets to profile, not measured requirements.

**Priority selector:** Ended → cease commands; Escape with visible survivor near gate → evaluate legal pressure; otherwise visible target near legal trap → request trap; then exposed isolated target → mark; then valid anchor and resource reserve → summon; then new evidence in another area → consider socket switch; otherwise sweep view and wait. All command tasks call the same server-side validation functions as a player. A failed command returns failure and recomputes, instead of forcibly bypassing cooldowns.

The Eye may remember where a survivor was seen, but after cover it cannot obtain exact live coordinates from that actor for aim. Noise provides a clue, not hidden omniscience. Log the evidence that caused each socket change in development builds.

### 9.2 Survivor Blackboard and behavior

Keys: CurrentTrial object, GoalLocation vector, CarriedMote object, ThreatLocation vector, IsExposed bool, HasCover bool, HealthFraction float, LifeState enum, ExitOpen bool, AssignedTask name.

Priority selector: eliminated/spectating → idle; exit open → choose safe gate route; downed ally with feasible rescue → rescue; immediate telegraphed danger → dodge to validated safe location; high exposure → enter nearby cover; assigned objective → perform work; otherwise choose an incomplete trial. Use navigation path results and progress timeout recovery. A bot stuck against an occluder for several seconds must replan rather than slide indefinitely.

Keep tasks stable long enough to finish useful work. Use hysteresis before switching objective because another bot has momentarily entered its area. For a human Eye test mode, give each bot a distinct objective preference, then let available bots help unfinished work. The bots must respect the same pickup ranges, sequences and work clocks as a human survivor.

## 10. UI binding and presentation

RepNotify handlers call an idempotent `RefreshFromSnapshot` function. That function updates widgets, gate presentation and objective indicators from present state, so packet loss or late joining does not require replaying every earlier cosmetic event. Epic describes Replicated and RepNotify Blueprint variables as tools for server-authored state distribution; presentation should react to that state without writing authority variables back. [Source: Replicating variables](https://dev.epicgames.com/documentation/en-us/unreal-engine/replicating-variables-in-blueprints?application_version=4.27), a legacy UI reference whose relevant semantics must be checked in the selected UE5 version.

Survivor HUD: phase/deadline, three seal states, health, stamina, observation exposure, carried item, focused interaction, status text and accessible warning direction. Eye HUD: socket identity, resources, command costs and cooldowns, legal target feedback, survivor status and current seal pressure. Neither HUD displays invisible enemy truth simply because it exists in a server-side actor.

A trial panel must close on exit, downing, lost range, scene transition or Escape key. Closing releases any held interaction and restores the role mapping context. Match end clears all prompts and displays outcome/reason plus replay/menu choices. Local options do not pause a live multiplayer session.

## 11. Build milestones and proof requirements

| Milestone | Concrete exit condition |
| --- | --- |
| UE-A: local parity | Import project; complete First, Second and all eight resolved Mix combinations; escape/timeout/replay without stale state |
| UE-B: dual roles | Human Eye at all four sockets; visible/occluded action checks; four legal bot participants finish work |
| UE-C: replicated slice | Listen server plus two clients; owned RPC path; result/deadline agreement; rejected remote invalid actions |
| UE-D: adverse conditions | Packet lag/loss, duplicate/stale request rejection, disconnect carry/relay recovery, late-join snapshots |
| UE-E: content admission | Every new trial passes solvability, scaling, warnings and recovery checks |
| UE-F: delivery candidate | Packaged development executable, map inclusion, input/options/save test, measured performance report |

**Priority regression cases:** hide head and chest behind a wall and request Mark; request a trap behind the Eye; summon into an occupied anchor; send an invalid socket ID; press a completed trial repeatedly; drop a mote outside the traversable floor; release a relay during packet loss; submit an old Echo attempt; reach the gate before three seals; simultaneously expire time and overlap the gate; leave and restart a match after result. These cases prove the central rules rather than only confirming that an animation plays.

The UE5 deliverable becomes playable when these assets are created and the checks run in the editor/package. The currently runnable Godot build validates the game direction and selected rules; it does not substitute for Unreal replication, packaging or performance evidence.
