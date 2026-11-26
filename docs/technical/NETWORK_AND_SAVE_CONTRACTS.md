# THE EYES — network and persistence contracts

**Status:** specified for the future UE5 build. The Godot v0.3 scope remains local: Solo Survivor, human Eye and Survivor Squad with one human plus four AI allies. It does not provide a lobby server, internet matchmaking, replicated clients, reconnect or cross-platform accounts. This document makes those future features concrete enough to implement and test without implying they already exist. The squad's exact authority and proposed Blueprint request/lease recipes are in [Squad Implementation](SQUAD_IMPLEMENTATION.md).

## 1. Session model

The first network milestone uses a packaged **listen-server** session with one host and invited clients. It targets the classic match rule: 5–7 survivor slots and one Eye slot. A small development session may have fewer people and fill agreed slots with AI. The authority model must remain the same in local, listen-server and any later dedicated-server deployment.

Choose a single supported online subsystem and record its version before shipping an internet lobby. The initial implementation should use a LAN test before depending on external account services. Cross-play, NAT traversal, relay services, platform invitations, entitlements and moderation are separate integrations; selecting a Blueprint node labelled Create Session does not establish all of them.

Blueprint-only means all **project gameplay** remains Blueprint-authored. Dedicated-server packaging and platform integrations can have engine/distribution prerequisites that must be verified for the chosen toolchain. This foundation does not claim to provide a ready dedicated-server target or a hosted service. Preserve the listen-server milestone rather than silently adding project C++ to bypass a tooling constraint.

### 1.1 Match identity

| Field | Purpose | Authority |
| --- | --- | --- |
| MatchId | Unique instance identifier for events, reconnect and reward idempotency | Host/server |
| ProtocolVersion | Message/schema compatibility | Build constant |
| ContentVersion | Admitted trial/map registry version | Build manifest |
| RulesVersion | Tuning/schema compatibility | Build manifest |
| MapId | Stable map ID, not arbitrary path from client | Server allowlist |
| DifficultyId | Validated preset ID | Host choice before lock |
| SessionMode | Classic, custom or agreed test variant | Server |
| MatchSeed | Reproduction input | Server |
| ResolvedLayout | Selected trial and hazard configuration | Server, filtered public view |
| ParticipantId | Match-local participant identity | Admission layer |

The join handshake rejects incompatible protocol or mandatory content versions with a clear message. A client cannot request an arbitrary package path to load. A cosmetic mismatch may degrade gracefully only when it does not affect collision, cue readability or trial rules.

## 2. Who may know and change what

Epic's GameMode/GameState split supplies the engine framework; the following visibility choices are project policy. GameState carries shared state, while GameMode remains authoritative on the server. [Source](https://dev.epicgames.com/documentation/en-us/unreal-engine/game-mode-and-game-state-in-unreal-engine).

| Information | Server | Owning participant | Other survivors | Human Eye |
| --- | --- | --- | --- | --- |
| Phase, deadline, awarded seals | Full | Full | Full | Full |
| Public roster/life states | Full | Full | Full | Allowed public subset |
| Survivor position | Full simulation | Own movement | Replicated relevant world actors | Only representation allowed by visibility policy |
| Survivor health/stamina details | Full | Full | Team policy | No exact private values by default |
| Echo answer sequence | Full | Only currently presented teaching cues | Presented cues in scope | No secret answer array |
| Personal whisper clue | Full | Own clue | Only if player shares it | No private clue by default |
| Eye energy and cooldowns | Full | Eye sees full | Public telegraph only | Full |
| Hidden objective shuffle | Full | Revealed information only | Revealed information only | Only legitimate observation |
| Local remapping/accessibility | Irrelevant unless gameplay affects rules | Full | None | Own settings only |
| Authentication ticket | Admission service only | Local opaque token when necessary | Never | Never |

Rendering an enemy actor without drawing its name is not protection against a modified client reading replicated position. A later competitive mode must decide which actors/state remain network relevant to the Eye, and test that policy. Until then, advertise a trusted-friends prototype rather than claim anti-cheat guarantees.

Use the owned PlayerController for private responses. Shared widgets never obtain their truth from another player's local GameInstance. Keep server-only answers out of replicated arrays, debug strings and public event logs.

## 3. RPC entry points

RPC routing depends on actor ownership. Reliable messages have retransmission costs and should be reserved for low-frequency state transitions; transient aim updates should not accumulate in a reliable queue. [Source: Remote Procedure Calls](https://dev.epicgames.com/documentation/en-us/unreal-engine/remote-procedure-calls-in-unreal-engine).

The rates below are **initial design ceilings**, not measured bandwidth or anti-cheat guarantees. Verify them against the chosen engine version and input handling.

| Event on BP_EyesPlayerController | Direction | Reliability | Initial ceiling | Required server checks |
| --- | --- | --- | ---: | --- |
| `Server_RequestReady(DesiredReady,Seq)` | Client→server | Reliable | 2/s | Lobby phase; own roster slot |
| `Server_RequestRole(Role,ArchetypeId,Seq)` | Client→server | Reliable | 2/s | Lobby only; slot capacity; allowed archetype |
| `Server_RequestInteract(Target,ActionId,Seq,Attempt)` | Client→server | Reliable | 8/s | Owned pawn; role; life; target registry; range; trace; trial phase |
| `Server_StopInteract(Seq)` | Client→server | Reliable | 8/s | Own lease; current sequence |
| `Server_InteractionHeartbeat(LeaseId,Seq)` | Client→server | Unreliable | 5/s | Own active lease; valid range/trace; bounded freshness |
| `Server_RequestPower(PowerId,Target,Seq)` | Client→server | Reliable | 8/s | Own Eye; phase; target; view; costs; cooldown; safe placement |
| `Server_RequestSocket(SocketId,Seq)` | Client→server | Reliable | 4/s | Authored enabled socket; changed socket; Blink resource gates |
| `Server_UpdateEyeAim(Yaw,Pitch,Seq)` | Client→server | Unreliable | 20/s | Finite values; current socket limits; plausible angular change |
| `Server_SubmitEcho(Symbol,AttemptId,Seq)` | Client→server | Reliable | 8/s | Symbol 0–3; current response; own proximity; unseen sequence |
| `Client_RequestResult(Seq,Result)` | Server→owner | Reliable | Per accepted/rejected command | Server generated, no client relay |
| `Client_PrivateCue(CueId,EndsAt)` | Server→owner | Reliable | Bounded authored cues | No other-player payload |

Do not add RPCs for `SetHealth`, `SetEnergy`, `CompleteTrial`, `GiveReward` or `WinMatch`. Clients request intent. The authority derives the result from legal world conditions.

### 3.1 Request processing

1. Confirm the connection owns the controller and currently possesses the required role.
2. Require a finite, bounded payload. Convert unknown IDs to rejection; never index an array with an unchecked symbol or socket number.
3. Check phase, life state, and participant eligibility.
4. Reject duplicates/stale sequences within this participant's current match and request stream. Reset the stream only during a deliberate new match/admission epoch.
5. Check the appropriate rate budget. Rate rejection must not charge energy or reset a cooldown.
6. Resolve the target from the allowed registry, then perform its server-side spatial and state checks.
7. Commit state atomically. Record request sequence/result and authoritative timestamp.
8. Return compact feedback; replicate the resulting state.

A nonnegative monotonic sequence is adequate for duplicate handling inside a match. It is not authentication. An attacker can invent future sequence values, so bound jumps and avoid letting an out-of-range request permanently advance the accepted sequence. Track the last **accepted or deliberately handled** sequence only after basic payload/epoch validation.

### 3.2 Hold leases

For Clockwork Relay, a valid press opens a lease with a server-generated ID. Heartbeats refresh a short expiry, initially 0.6 s. A lost stop packet is therefore bounded. Work accrues from the server's elapsed time only while the participant remains eligible, close enough and unobstructed. Leaving the volume, being downed, disconnecting or ending the match closes the lease immediately.

Network jitter may make progress pause but cannot create extra work. A late heartbeat from an old lease cannot reopen it. If an accessibility option changes hold to toggle, the server still sees the same lease and cancellation rules; it does not receive a faster work rate.

## 4. Replicated snapshots and clocks

Replicate a coherent `ST_MatchSnapshot` with a revision, phase, deadline and result. Trial and trap actors each expose their own similarly versioned snapshot. A client presentation handler must be safe when called repeatedly with the same data. Do not rely on the arrival order of unrelated actor updates to infer that a trial must have completed.

The UI calculates remaining time from `PhaseEndsAt` and the server-time estimate provided by GameState. Only the server decides expiry. Local clock changes, render FPS or a paused options widget cannot extend a live match. The framework's server-time accessor is documented with GameState. [Source](https://dev.epicgames.com/documentation/en-us/unreal-engine/game-mode-and-game-state-in-unreal-engine).

Send persistent gameplay facts as state, not only as multicast events. A client joining after the gate opened must reconstruct the open gate from the current seal/phase state. One-shot sound or particles may be transient; an open collision barrier, completed seal or active warning cannot depend on having received an earlier sound packet.

For moving or rotating hazards, publish authoritative start time, period, direction and state revision. Animate locally from those parameters. Damage checks remain server-side. A warning reaching a client after its harmful interval is a reason to review warning duration and latency policy, not a reason to silently grant client damage authority.

### 4.1 A deliberate latency policy

The initial trial slice favors readable, relatively slow decisions. Set a minimum warning interval large enough to survive the tested lag budget. Use a bounded input tolerance for timing trials and log boundary outcomes. Never accept a client timestamp as unrestricted evidence that an old answer arrived on time.

For future precise rhythm actions, define and test a server-scheduled cue window with a modest tolerance, plus a maximum allowable client timestamp offset. Keep the authoritative submission receipt time and claimed time separately. This is a design task for the rhythm trial milestone; the v0.1 glyph puzzle does not claim rollback or lag compensation.

## 5. Randomness and reproducibility

Use separate logical random streams for layout selection, trial sequence, AI choice jitter and purely cosmetic effects. A new dust particle must not consume the random draw that determines a puzzle answer.

At match creation, store both the seed and the **resolved gameplay configuration**: chosen trials, admitted spawn anchors, ordered puzzle sequences, hazard pattern IDs and rules version. Godot and Unreal use their own random APIs; equal seed integers do not guarantee equal sequences across engines. Exact cross-engine replay requires importing the resolved configuration or implementing and testing a shared random algorithm. This foundation promises neither without evidence.

Public custom seeds are a convenience for practice. If a competitive mode exposes a seed from which all hidden answers can be calculated, those answers are not secret. Use server-private streams for hidden choices and expose only the public parts of a match. A recorded replay for post-match analysis can reveal more than a live spectator feed.

Reject a generated layout before admission if it violates mandatory reachability, safe warning zones, objective item availability or required team roles. Record the rejection reason and fallback to a known solvable configuration. Do not run endless random retries while clients wait in a loading screen.

### 5.1 Contract snapshots and save migration for the six-trial pool

The v0.2 local rule contract uses IDs `first`, `second`, and `mix`, with three stable seal slots `silent`, `echoes`, and `relay`. A slot is a position in the match; its active trial may be `vault`, `ritual`, or `clock`. The full class/graph specification and actual scalar CSVs are in [Contract Trial Implementation](CONTRACT_TRIAL_IMPLEMENTATION.md).

For the current v0.4 extension, use [Third-trial implementation](THIRD_TRIAL_IMPLEMENTATION.md): it adds `third`, three additional trial IDs and a 27-selection Mix pool. Persist the rules version and resolved selection; a historical v0.3 Mix seed must not be re-resolved with the expanded selector. These migration specifications do not add a resumable match or network service to the local prototype.

A proposed UE public snapshot carries `MatchEpoch`, `ContractId`, `RulesVersion`, `Revision`, and an array of `{SlotId, TrialId, TrialEpoch, Complete}`. The server's resolved private configuration also retains the four distinct vault targets, ritual permutation and bank, clock start/target/hands, cargo ownership and eligible command deadlines. Do not regenerate hidden answers when a participant reconnects. Reconstruct visible accepted progress from a coherent snapshot; events alone are insufficient.

Keep secret clue arrays and bot solver paths out of general replication. A world clue intentionally displayed to a legitimate observer is a presentation decision, not permission to distribute every puzzle solution in the public GameState. Public practice seeds in the local build provide reproducibility rather than secrecy. Godot's 64-bit salted seeds and UE RandomStream do not define an identical cross-engine random algorithm.

The controller interaction request additionally binds `MatchEpoch`, `SlotId`, `TrialId`, `TrialEpoch`, and a bounded action payload. Validate actor registration against the resolved slot before applying the existing request rate, physical range/trace, life and phase checks. Deposit/vessel attempts use a 0.35-second per-actor gate; every clock lever/reset/confirm action shares a 0.25-second global gate. Clients cannot submit elapsed ritual hold time; the server measures eligible occupancy in the 280 cm ring, adding time once even with several occupants. Movement within that ring preserves the eight-second hold. Leaving its valid region resets the hold without erasing the lit sequence.

For a future checkpoint schema that adds contract selection, increment its schema version explicitly. A supported legacy checkpoint with the three original slot flags can map to `ContractId=first` and the corresponding original trial IDs. Preserve its stored resolved Echo configuration if present. A legacy save with insufficient layout data may retain settings and records while declining to resume the match; it must not silently generate a different puzzle and label it an exact continuation. Future schema versions remain protected from accidental overwrite by an older build.

At load/admission, validate three unique slot IDs, registry membership, slot/trial compatibility, known contract ID, a supported rules version, unique vault targets in 0–5, ritual permutation 0–4, bank values in {0,2,4} consistent with the lit prefix, and clock array lengths/ranges/reachability. A new v0.2 clock begins at a shortest-path distance of at least four commands; its generator selects among 48 distance-four candidates in the 108-state connected component. Validate that constraint against the stored **initial** state. A legitimate in-progress saved position can be closer to the target and must not be regenerated to restore the initial difficulty. These are proposed UE persistence checks. The Godot prototype still has no mid-match resume or authenticated reconnect service.

### 5.2 Squad mode and report schema 3

The local v0.3 last-match ledger records `session_mode` as `survivor`, `eye` or `squad`, and retains the requested role even when squad reuses survivor movement internally. `squad_summary` records downs, revives, eliminations and orders. These post-match records are schema 3. They do not contain a resumable authority process, an authenticated identity or a network reconnect token. A legacy record must not be interpreted as a squad match merely because it includes bot events; the mode must be explicit.

A future resumable squad snapshot needs the authoritative life state, one-chance recovery count, remaining bleedout, protection deadline, stored order, hold anchors, roster IDs and versioned trial/cargo snapshot. It must clear active rescue leases on disconnect/load rather than resurrect a stale helper reservation. Preserve `RecoveriesUsed` and current life on any approved bot takeover or reconnect. Reject unknown state/order IDs, multiple helpers for one subject, one helper bound to multiple subjects, recovery counts outside 0–1, or positive rescue progress without an eligible reserved pair.

For proposed network play, all squad commands pass through the owned controller and the server's member registry. Order and begin-rescue requests are initially capped at 4/s, stop-rescue at 8/s, and unreliable rescue heartbeats at 5/s with a 0.6-second lease expiry. A client never sends accepted progress, health or a movement/line-of-sight verdict. The server validates the 180 cm rescue range and physical trace continuously, while measuring six seconds of unbroken eligible work. Rate limits and network tolerances are design targets requiring actual latency/loss tests; they are not implemented transport in the local Godot mode.

Freezing or ending the match clears every reservation and resets rescue progress, then stops countdown updates. This differs from a durable checkpoint: it provides no serialization or resume guarantee. The current local schema 3 deliberately saves a match report only. See the [squad state and acceptance specification](SQUAD_IMPLEMENTATION.md) for the 35-second first-fall window, rescue result, one-chance allowance, mode isolation and wipe policy.

## 6. Joining, leaving and reconnect

### 6.1 Lobby admission

Validate build compatibility, assign a stable participant ID and choose a role before spawning gameplay. The host can change difficulty only before the lobby locks. Once all participants accept the selected parameters, generate the match configuration, spawn/possess the correct pawn and begin Preparation.

Advertise the effective player count including bots. The eye slot is singular. An AI Eye yields control to a human only at an explicitly supported safe transition; it must not keep issuing commands after its controller is replaced.

### 6.2 Disconnect during play

Proposed initial policy: reserve a disconnected human slot for up to 60 s; a bot takes over with the same health, held item and current state. Do not respawn the player at full health or release them from an active punishment. If a safe takeover is not yet implemented, end or abort the session transparently rather than leave an immortal disconnected pawn.

The reconnect token must be an opaque, authenticated value supplied by the chosen platform/session service. A plain participant name or a Blueprint hash is not proof of ownership. A successful reconnect checks account/session binding and then returns possession of the existing participant state. The network implementation owns that validation; the local prototype has none of these tokens.

On any departure: release hold leases; update roster presence; protect or drop carried items according to the takeover decision; stop input authority; retain valid cooldown timestamps. Resume a UI from a current snapshot instead of replaying every event since the disconnection.

### 6.3 Host exit and late joins

The first listen-server version has **no automatic host migration**. A host exit ends the session with an explanation and returns clients to their menus. Saving a match seed does not transfer a running authority process.

Late join policy for the first public test: spectator only after Hunt begins. Private custom sessions may allow a new human to take an existing bot slot, preserving its current state. The joiner must receive current trap warnings, trial phases and gate state before obtaining control. Avoid new full-health bodies changing the balance halfway through a match.

## 7. Save boundaries

Use local persistence for user preferences, accessible presentation choices, tutorial completion, practice records and cosmetic unlocks. Do not load a local save into a competitive match as proof of health, inventory, skill unlock entitlement or earned currency.

Epic's save system uses custom SaveGame objects; asynchronous saving has a completion result that can be checked. This project's write flow waits for success before reporting a saved preference. [Source: Saving and Loading](https://dev.epicgames.com/documentation/en-us/unreal-engine/saving-and-loading-your-game-in-unreal-engine).

### 7.1 Proposed SaveGame fields

| Field | Type | Constraints |
| --- | --- | --- |
| SchemaVersion | Integer | Start at 1; reject unsupported future versions |
| ProfileId | String | Local profile identifier, not authentication |
| LastWrittenUtc | String | Diagnostic timestamp only |
| Settings | ST_LocalSettings | Bounded volume/sensitivity/FOV values |
| InputProfileId | Name | Known keyboard/controller profile |
| Rebindings | Array of ST_Binding | Valid action/device identifiers |
| TutorialCompletedIds | Name array | Unique known entries |
| CosmeticUnlockIds | Name array | Local/offline scope until account service exists |
| PracticeRecords | Array of ST_PracticeRecord | Trial ID, rules version, seed/config ID, best result |
| ActiveOfflineCheckpoint | Optional ST_Checkpoint | Only at documented safe phase boundaries |

Do not serialize live actor references. Store stable IDs and reconstruct state through an allowed registry. A removed trial record may remain as an archived record without instantiating an unknown class. Settings migration should recover harmless values independently of a broken gameplay checkpoint.

### 7.2 Save transaction

Collect validated current settings → copy them into a fresh SaveGame object → increment content/schema metadata as required → asynchronous save to the intended slot → on success update the UI's persisted indicator → on failure keep the pending change in memory and provide a retry path. Queue or coalesce repeated slider edits; avoid starting a save operation for every frame of mouse movement.

Before a schema migration, retain a previous compatible backup slot. Load the source into a temporary object, validate its schema and field ranges, perform an explicit version-to-version transformation, then save the transformed result. If conversion fails, leave the source intact and offer fresh defaults for the affected profile. A future-version save should not be overwritten by an older build simply because it could not be decoded.

### 7.3 Offline checkpoints

Checkpoint only at an announced safe boundary, initially before a match or between fully resolved trials. Persist the resolved layout, participant loadouts, completed seals, elapsed phase budget and rules version. On resume, create a fresh session and rebuild legal world state. Do not persist an active damaging trap mid-frame until exact restart behavior has a test.

The current prototype's actual persistence, if any, is described by its own README/code. This plan is not a claim that a partial-match save exists in v0.2. Online matches use the live server's state and session service, not a local `.sav` as host authority.

## 8. Threat and failure register

| Failure or abuse | Required behavior |
| --- | --- |
| Client reports a completed objective | Ignore the claim; derive completion from legal actions |
| Player sends negative/huge interaction duration | Never use client duration to accrue work |
| Eye sends a target through a wall | Server trace rejects without spending energy |
| Client asks to blink to arbitrary coordinates | Resolve a known socket ID; reject coordinates |
| Rapid reliable request spam | Rate limit before expensive work; keep gameplay responsive |
| Repeated packet delivers same mote | Item state and request deduplication make deposit idempotent |
| Old Echo answer after attempt restart | Reject mismatched attempt ID |
| Missing StopInteract packet | Short hold lease expires; no indefinite work |
| Fake reconnect username | Require authenticated slot binding |
| Client changes local timer | Server deadline remains authoritative |
| Headless bot uses hidden actor position | AI evidence audit detects illegal omniscience |
| Trial layout has no exit path | Reject configuration before match admission |
| Save references missing content | Preserve safe settings, quarantine missing checkpoint |
| Two events end the match | One guarded result commit; later events are no-ops |
| Host disconnects | Explicit session-ended result; no false migration promise |

## 9. Network acceptance matrix

Run these in a real UE5 build once implemented; this document records **planned checks**, not passing results.

| Scenario | Setup | Success criterion |
| --- | --- | --- |
| Basic consistency | Host + two clients, one Eye | Same phase, seals and winner; role controls work |
| Occluded power | Survivor behind thick cover | No damage/mark acceptance; no resource debit |
| Out-of-range interaction | Request receiver from another room | No delivery and clear rejection |
| Stale attempt | Begin Echo attempt B, submit from A | Answer rejected; B unchanged |
| Duplicate delivery | Replay accepted deposit request | Count increases exactly once |
| Lost release | Drop stop packet/heartbeat | Relay work stops within lease bound |
| Lag | Emulated 100/200 ms latency | Warnings remain actionable; no client-only wins |
| Packet loss | Emulated 2–5% loss | Snapshots converge; no permanent stuck warning |
| Disconnect carrying | Leave with mote | Bot/drop policy preserves recoverability |
| Disconnect Eye | Leave during cooldown | Policy preserves energy/cooldown; no double controller |
| Late spectator | Join during Escape | Sees open gate and remaining time immediately |
| Save migration | Valid v1, corrupt v1, unsupported v2 | Preserve source; migrate/reject without silent overwrite |
| Mixed builds | Different ProtocolVersion | Rejected before gameplay with a readable reason |
| Match end race | Gate overlap at deadline | One deterministic server-recorded result |

Record build hash, engine version, client count, simulated lag/loss, selected seed/config, observed result and logs. A single local editor window cannot establish network correctness. The milestone report should distinguish engine compile, local gameplay, replicated gameplay, packaging and measured performance.
