# 10 — Production and acceptance

## Delivery truth

The repository contains a playable Godot prototype and a production design for an Unreal Engine 5 game. Those are two different maturity levels. The executable prototype is the evidence for current behavior. This bible is the detailed plan for content and systems beyond it. A prepared Unreal project descriptor, configuration, or Blueprint implementation guide is not equivalent to compiled playable Blueprint assets.

| Area | Current delivery category | Completion evidence required for production |
|---|---|---|
| One local 3D arena | Prototype implementation | Recorded complete playthrough and collision review |
| Solo survivor and Eye roles | Verified v0.2 prototype implementation | Both roles complete fair matches with human testers |
| Local human-plus-four-AI Squad | Published v0.3: local domain/world checks, three pressured contract routes, native-renderer inspection and nine native Windows startup cases passed | Graphical Windows playthrough and broader human balance/UX qualification |
| Three active trials from nine selected families | Nine implemented Godot subsets; three active per match | Reset, failure, recovery, completion and physical interaction tests |
| Single-trial Workshop | v0.5 Godot session policy: one selected trial, one human, no Eye/deadline/escape | All nine physical completion routes, inactive-bay denial, retry/reset and ordinary-mode regressions |
| Local practice journal and reading flow | v0.5 bounded per-archetype records, paused Field Manual and focus-loss pause | Once-only completion, persistence failure/reload, future-schema protection and explicit resume checks |
| Four fixed sockets | Prototype core | Correct visual and authoritative sight behavior |
| Four archetypes | Prototype mechanics | Final animations, readable effects and measured balance |
| Eight named survivors | Detailed design | Models, animation sets, voices and narrative integration |
| Twenty-five trials | Nine implemented prototype subsets; sixteen planned | Per-trial content and acceptance sheet |
| Four full realms | Detailed design | Complete level graphs, art, navigation and performance |
| Online multiplayer | Planned architecture | Remote-session and authority tests under delay |
| UE5 Blueprint gameplay | Implementation specification and foundation | Assets created, compiled, run and tested in Unreal Editor |
| Progression and platform services | Planned | Persistence, privacy, service and recovery verification |

The release report can narrow or update this matrix after actual verification. It must never promote a planned feature merely because its name appears in a menu, a catalogue, or a data file.

## Milestone sequence

**M0 — The First Observance.** Establish the complete local loop: role selection, preparation, three distinct trials, Eye pressure, escape, defeat, restart, and controls. Deliver source, startup instructions, meaningful automated checks, actual runtime captures, and known limitations. Measure whether a new player understands how to break gaze and earn a seal.

**M0.2 — Alternate contracts.** Add the physical Memory Vault, Ritual Circle, and Clock Room subsets inside the existing bays. Preserve First, add Second, and validate all eight Seeded Mix combinations. Test exact relic/cradle identity, pair-bank recovery, continuous ring occupancy, reversible clock moves, physical bot interactions, inactive-prop cleanup, and the unchanged three-seal outcome rule. The Godot implementation and scoped domain, physical bot-route, and active Story survivor-route checks have passed; [Prototype contracts](12_PROTOTYPE_CONTRACTS.md) records their evidence and limits. The published v0.2 Windows archive passed its six native headless startup cases; broader human balance/usability testing remains separate work.

**M0.3 — The Survivor Accord.** Add a local human-and-four-AI Squad on the existing six-trial observatory. Implement Work/Follow/Hold, physical rescue with per-actor recovery limits, Keeper support, roster state, and ally spectating. Preserve Solo Second Sight and Eye-mode behavior. Verify command priorities, cargo recovery, interruption, team wipe, a single aggregate Relay update per frame, actual escape, and all existing regressions. Current local evidence includes 26 domain cases / 120 assertions, 23 physical world cases / 234 assertions, three successful Story/Keeper Squad contracts and five inspected native frames. Existing regressions retain their outcomes. The published v0.3 Windows archive passed all nine native headless mode/contract startup cases; graphical Windows playthrough and broader qualification remain unverified; see [the verification report](../qa/V0_3_VERIFICATION.md).

**M0.4 — The Third Observance.** Add three complete observatory subsets: Light in the Darkness, Strings of Despair and Chimes of Doom. Validate charge and cargo recovery, uniquely explainable shape/side clues, deliberate interruptible cutting, permanent phrase banks, damping and real noise perception. Every bot visits the clue stand and performs the same spatially validated actions as a human. Expand Mix to all 27 mappings and explicitly record the seed-selection migration. Improve survivor silhouettes, labels and squad readability. Require the twelve-suite gameplay gate and twelve native Windows mode/contract startups before publication. The [v0.4 report](../qa/V0_4_VERIFICATION.md) records actual evidence. This local extension does not complete M1.

**M0.5 — The Trial Workshop.** Expose all nine existing trials as separate, physically played survivor drills. Preserve their mechanics, checkpoints, cargo ownership and seed generation. Remove Eye pressure and the match deadline through an explicit practice policy; finish on one real selected seal without fabricating other seals or entering escape. Add clear steps and controls, same/new-seed retry, the next drill, a bounded journal with best times per archetype, F1/paused manual access and focus-loss pause. Require rule and world checks for all nine drills, record isolation and persistence, manual/pause behavior, the ordinary match regressions, and 21 native Windows startups: twelve mode/contract combinations plus nine practice selections. The [v0.5 report](../qa/V0_5_VERIFICATION.md) records which checks actually ran and their limits. Eye training, remapping and gamepad qualification remain separate work. This milestone does not complete the UE5 port.

**M1 — UE5 mechanical port.** Recreate the verified loop in Blueprint actors and components. Import design data, implement authoritative state changes, create one playable level, and match the Godot acceptance scenarios. Use placeholder art where needed, but identify it. Do not port incidental prototype hacks merely to claim parity.

**M2 — Network proof.** Support a small remote session with explicit server authority. Test ownership, sight validation, simultaneous interactions, pickup uniqueness, cooldowns, late state replication, disconnect recovery, and match outcome ordering. Add latency simulation and a replayable event log. Do not expose public matchmaking yet.

**M3 — First production realm.** Finish Twisted Carnival or another chosen realm with a six-trial pool, two polished survivors per initial archetype pair, one finished Eye, two minion families, and a coherent audio kit. Validate the whole realm's dynamic graph and full match readability. The chosen realm must support enough combinations to demonstrate replayability without pretending the complete catalogue is done.

**M4 — Classic alpha.** Bring the population to five-to-seven survivors, add sessions, reconnect policy, settings persistence, reporting surfaces, and a measured matchmaking prototype. Run structured external playtests. Resolve fundamental fairness and communication problems before expanding the art workload.

**M5 — Content expansion.** Add remaining realms and trial families in complete batches. Each batch includes tutorialization, bot support, accessibility, performance, and save/schema migration. Campaign narrative and progression follow the stable core rather than creating pressure to preserve broken mechanics.

## Definition of done for a system

A system is done for a milestone when its player-facing promise is implemented, its invalid states are handled, its feedback matches authority, its performance is within the milestone budget, and its documentation states its actual limits. A function that works once in an ideal scenario is not sufficient for a reusable multiplayer mechanic.

For a trap, completion includes activation denial, energy consumption, warning, collision, one-hit accounting, recovery, cancellation, restart, and visibility. For a trial, it includes initial state, all valid actions, wrong actions, checkpoints, completion exactly once, loss of participants, and reset. For a socket, it includes adjacency, transition, aim limits, camera, world animation, and legal target evaluation.

## Verification layers

Pure rule checks verify deterministic state transitions and invariants: time cannot become negative in a way that revives a match, energy stays within bounds, completed seals stay complete, relay decay stops at checkpoints, and duplicate item IDs do not add progress. These checks are necessary for the gameplay domain, but they do not prove camera quality or physical reachability.

Engine integration checks run the actual project, create the arena, exercise interactions through the same public path used by players, and inspect results. They catch script parsing, missing resources, invalid node paths, and state-to-presentation mismatches. A headless test is useful for logic; it cannot certify lighting, sound mix, or input comfort.

Visual and human checks inspect the rendered game at supported resolutions, both roles, each difficulty, all nine selected trial subsets, escape, defeat, and restart. Three trials are active per match; the 27 mixed combinations also need integration coverage. Capture real frames. Human sessions answer whether warnings are understood and whether the Eye has interesting decisions. A screenshot of the title screen alone does not establish that a match can be completed.

Workshop checks add all nine single-trial routes, truthful inactive-bay presentation, clear instructions, selected-archetype records and the complete retry path. Pause, manual and focus changes must stop active time and incomplete holds without inventing completed progress. A native Windows startup matrix is a packaging gate; it does not replace a graphical Windows playthrough or establish novice comprehension.

## Representative acceptance scenarios

| Scenario | Expected result |
|---|---|
| Survivor hides behind solid cover during gaze | Exposure stops or decays according to rule; no hidden damage |
| Eye attempts a blocked trap | Clear denial; no energy consumed |
| Two players request the same mote | Exactly one owner; no duplication |
| Final mote deposited twice | Third delivery banks once; no extra seal |
| Echoes receives an invalid symbol ID | Input rejected without corrupting sequence |
| Echoes receives a wrong valid symbol | Current attempt resets consistently |
| Relay released after second checkpoint | Decay stops at the eight-second bank |
| Last seal completes | Exit opens and fresh escape deadline starts |
| Survivor exits during concurrent remote damage | Declared event ordering yields one final winner |
| Match timeout with living survivors | Eye victory, explanation, and no continued gameplay mutation |
| Required item falls outside bounds | It returns to a reachable declared cradle |
| Player restarts after defeat | Timers, abilities, hazards, actors and UI reset completely |
| Audio muted and camera shake disabled | Every required warning remains understandable |
| A Workshop drill starts | One selected trial and one human are active; other bays reject commands and provide no objective cargo |
| A practice trial completes | One real seal, one `practice_completed` event, frozen elapsed time and a practice result; no competitive winner or escape phase |
| A practice completion event is repeated | No second completion, additional best-time update or duplicate persisted count |
| Retry follows partial or completed practice | Fresh physical cargo, checkpoints, holds, cooldowns and timer; accepted starts count as new attempts |
| Manual closes during a live local session | Return to pause; simulation resumes only after an explicit player action |
| Application loses and regains focus | Pause on loss, remain paused on return, and clear incomplete interaction holds |
| A journal has an unsupported schema or cannot be read | Preserve the file, block replacement writes and leave training available |
| Notebook replacement fails after its primary disappears | Attempt restoration from one `.bak`, report save failure, and preserve the backup if restoration fails |
| Only a valid notebook `.bak` survives | Load it without rewriting files; a corrupt or newer primary must never trigger fallback |
| Practice follows an ordinary completed match | Update the separate practice journal while preserving the ordinary match ledger |

Prototype verification should record which of these are covered automatically, manually, or not yet. Avoid reporting a future test plan as a completed test run.

## Performance and content budgets

Production targets need measurement on named hardware before claims are made. A useful initial PC goal is stable 60 fps at the chosen quality preset, with reduced settings retaining gameplay information. Treat that as a goal, not a measured result. Track frame-time percentiles, draw calls, active lights, physics bodies, network traffic, and worst-case simultaneous effects.

The Eye's visibility queries use a bounded cadence and a small number of meaningful sample points. Traps update by state transitions where possible. Decorative debris does not need authoritative physics. Large textures, detailed characters, and dynamic lighting should be budgeted after one representative room is measured. Visual richness must not depend on unbounded per-frame work.

Online bandwidth budgets distinguish state that must replicate from cosmetic events that can be reconstructed. A stable trial progress value is more robust than sending every animation frame. Client visuals can interpolate, while the server owns health, energy, item ownership, trial progress, timers, and outcome. The detailed Unreal architecture provides the implementation plan.

## Risks and decisions

| Risk | Observable symptom | Response |
|---|---|---|
| Eye becomes omniscient | Survivors cannot gain time through cover | Audit perception records and socket coverage |
| Trials feel like chores | Long idle holds dominate play | Shorten commitments, add decisions and complementary roles |
| Randomization breaks maps | Unreachable items or sealed routes | Use approved graph states and validation |
| Too many content promises | Many named trials with no finished example | Ship complete batches with status tracking |
| Physics dominates outcomes | Tethers/building fail unpredictably | Use bounded constraints and authoritative discrete states |
| Visual darkness hides rules | Players fail without identifying the cause | Establish contrast floor and redundant cues |
| Bots teach unfair behavior | AI sees hidden targets or ignores hazards | Share public action and perception interfaces |
| Prototype mistaken for production | User expects network or final UE5 assets | Maintain explicit release matrix and screenshots |

## Change control

Every significant design change records the problem, new rule, affected content, migration need, and verification evidence. Preserve the original source intent in the traceability chapter. If the first playtests show that a source idea is unfair—such as erasing completed progress or randomizing a safe tile under a player—change the implementation transparently and explain the preserved fantasy.

The next useful decision is based on evidence from the playable slice: whether the Eye's fixed observation creates enough agency for both sides. If that succeeds, expand content and port to UE5. If it fails, improve socket topology, sight readability, and intervention timing before producing the sixteen remaining trial environments or fuller realm versions of the nine selected subsets.
