# 10 — Production and acceptance

## Delivery truth

The repository contains a playable Godot prototype and a production design for an Unreal Engine 5 game. Those are two different maturity levels. The executable prototype is the evidence for current behavior. This bible is the detailed plan for content and systems beyond it. A prepared Unreal project descriptor, configuration, or Blueprint implementation guide is not equivalent to compiled playable Blueprint assets.

| Area | Current delivery category | Completion evidence required for production |
|---|---|---|
| One local 3D arena | Prototype implementation | Recorded complete playthrough and collision review |
| Survivor and Eye roles | Prototype implementation | Both roles complete fair matches with human testers |
| Three active trials from six selected families | Six implemented Godot subsets; three active per match | Reset, failure, recovery, completion and physical interaction tests |
| Four fixed sockets | Prototype core | Correct visual and authoritative sight behavior |
| Four archetypes | Prototype mechanics | Final animations, readable effects and measured balance |
| Eight named survivors | Detailed design | Models, animation sets, voices and narrative integration |
| Twenty-five trials | Six implemented prototype subsets; nineteen planned | Per-trial content and acceptance sheet |
| Four full realms | Detailed design | Complete level graphs, art, navigation and performance |
| Online multiplayer | Planned architecture | Remote-session and authority tests under delay |
| UE5 Blueprint gameplay | Implementation specification and foundation | Assets created, compiled, run and tested in Unreal Editor |
| Progression and platform services | Planned | Persistence, privacy, service and recovery verification |

The release report can narrow or update this matrix after actual verification. It must never promote a planned feature merely because its name appears in a menu, a catalogue, or a data file.

## Milestone sequence

**M0 — The First Observance.** Establish the complete local loop: role selection, preparation, three distinct trials, Eye pressure, escape, defeat, restart, and controls. Deliver source, startup instructions, meaningful automated checks, actual runtime captures, and known limitations. Measure whether a new player understands how to break gaze and earn a seal.

**M0.2 — Alternate contracts.** Add the physical Memory Vault, Ritual Circle, and Clock Room subsets inside the existing bays. Preserve First, add Second, and validate all eight Seeded Mix combinations. Test exact relic/cradle identity, pair-bank recovery, continuous ring occupancy, reversible clock moves, physical bot interactions, inactive-prop cleanup, and the unchanged three-seal outcome rule. The Godot implementation and scoped domain, physical bot-route, and active Story survivor-route checks have passed; [Prototype contracts](12_PROTOTYPE_CONTRACTS.md) records their evidence and limits. Native Windows release checks and broader human balance/usability testing remain separate gates.

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

Visual and human checks inspect the rendered game at supported resolutions, both roles, each difficulty, all six selected trial subsets, escape, defeat, and restart. Three trials are active per match; the eight mixed combinations also need integration coverage. Capture real frames. Human sessions answer whether warnings are understood and whether the Eye has interesting decisions. A screenshot of the title screen alone does not establish that a match can be completed.

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

The next useful decision is based on evidence from the playable slice: whether the Eye's fixed observation creates enough agency for both sides. If that succeeds, expand content and port to UE5. If it fails, improve socket topology, sight readability, and intervention timing before producing the nineteen remaining trial environments or fuller realm versions of the six selected subsets.
