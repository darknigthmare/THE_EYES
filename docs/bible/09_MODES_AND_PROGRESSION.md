# 09 — Modes and progression

## Current local prototype

The published v0.2 observatory prototype supports two local role experiences: one human survivor against an AI Eye, and one human Eye against four AI survivors. It uses the same three-seal goal and visible exit. The v0.2 prototype offers First, Second, and Seeded Mix contracts, selecting exactly one active trial in each of three bays from a six-trial pool. These are local content configurations, not online lobbies, split-screen, or a finished cooperative campaign. See [Prototype contracts](12_PROTOTYPE_CONTRACTS.md) for the precise subsets and verification status.

The **v0.3 Squad** adds one human survivor and four AI allies against the AI Eye. It uses the same contracts, map, and three-seal victory rule, with Work/Follow/Hold commands and one physical revival per actor. Immediate visible-shadow evasion, rescue and open-exit evacuation override orders; Hold remembers each bot's own position when issued. Human elimination switches to ally spectating while a surviving teammate can still win. See [Squad and rescue](13_SQUAD_AND_RESCUE.md) for implementation evidence, timings, and limits.

Story, Standard, and Ruthless are tuning presets. The current rule module uses Hunt/Escape windows of 600/90, 480/65, and 360/50 seconds respectively, with eight seconds of preparation. The escape window starts fresh after the third seal. These values are for the prototype and should be measured before promotion into the final Classic design.

Version 0.4 expands the pool to nine implemented trials and adds Third Observance. First, Second, Third and Seeded Mix each activate one trial in every bay; Mix has 27 combinations. All three ordinary local match modes share these four contracts.

Version 0.5 adds **The Trial Workshop**, a separate single-player practice session. The player chooses one of the nine existing trials, an archetype and a seed. The real apparatus and physical interactions remain, while the Eye, damage, deadline and escape requirement are disabled. Completing the selected trial produces a practice result and updates its separate local journal. It does not resolve a competitive match or add a fifth contract.

The production Classic, Endless, Custom and progression systems below remain proposals. The prototype has no online lobby, campaign, unlock economy, mid-match save or full replay system. The implemented practice subset is distinguished from future training below.

## Production Classic

Classic targets five to seven survivors against one Eye, with six survivors as the initial balance reference. The team completes three compatible trials and escapes. The first valid escape is a team victory under the base rule; the result screen separately acknowledges individual survival and rescue. This protects the stated source concept and avoids changing victory semantics silently between menus and gameplay.

Players select a role preference before matchmaking. The system should explain expected role assignment and avoid forcing repeated unwanted Eye games. Friends can form survivor groups, while the Eye role has clear policies for premade information advantages. Matchmaking quality, regional latency, reconnect behavior, and disconnect penalties require observed service data and are not solved by this design document alone.

## Endless Observance

Endless presents successive trial sets with a regroup interval. Survivors bank a score at each set and choose whether to continue or leave. The Eye gains new pressure options in bounded tiers, while survivors earn temporary tools. Escalation changes combinations and resource margins; warning durations retain a minimum fairness floor.

Each set has a deterministic seed and a published rule summary. A run can end through elimination or voluntary extraction. Persistent rewards favor reaching meaningful checkpoints, not spending the longest possible time in a farmable safe state. Human-controlled Eye Endless is a separate balance variant; the initial target uses AI to avoid making one person sit through an indefinite session.

## Custom Observance

Custom exposes explicit settings: player count within tested bounds, trial pool, map, seed, Eye controller, match duration, health/recovery model, assistance presets, and optional temptation events. Invalid combinations are rejected with a reason. A solo lobby cannot select an unmodified trial that requires two simultaneous human operators. An insufficient trial pool cannot quietly fall back to an undocumented mode.

Settings are visible to every participant before readying. Changing a consequential rule resets readiness. Presets can be exported as data, but untrusted presets cannot execute code or load arbitrary assets. A “chaos” preset may combine unusual rules only after a solvability and performance check; surprise is not an excuse for a broken match.

## Trial practice and Eye training

The **v0.5 Workshop** implements the trial selector, explicit rules and controls, real single-trial completion, same-seed retry, new-seed retry and next-trial progression. The player starts at the normal survivor spawn and travels to the apparatus; inactive bays do not provide extra cargo or seals. The Field Manual is available during paused play. Its explanations do not reveal generated puzzle answers that the player has not reached physically. See [The Trial Workshop](15_TRIAL_WORKSHOP.md) for all nine lessons and the exact delivery boundary.

The local journal has nine trial records with separate Veil, Tinker, Runner and Keeper profiles. Attempts and completions are counted; the latest attempt and best completed time retain their seeds. Best times are compared only within the same archetype. This is a bounded local learning summary, without a leaderboard, rewards, unlocks or power progression. The normal match ledger remains separate.

Optional safe-zone, gaze-trace and interaction-range debug overlays remain future training aids. They are not implied by the current HUD or Field Manual, and must be explicitly identified if later introduced.

**Eye training remains planned.** It would introduce socket switching, legal targeting, energy budgeting and respecting cover. Scenarios include an obvious blocked target, a noisy but hidden survivor, an exposed operator and an escape route with two choices. A tutorial succeeds only if the player can identify why a command is unavailable and can use another socket to create a legitimate opportunity. The Workshop is survivor trial practice and does not claim to teach or qualify these Eye scenarios.

## Progression philosophy

Progression expands expression, knowledge, and variety. It should not make an experienced survivor inherently harder to catch through permanent hidden health bonuses, or give a veteran Eye shorter warnings that new players cannot survive. Starting characters and base abilities remain competitive. Unlocks include clothing variations, socket ornament, banners, archive entries, voice selections, and alternative balanced tools.

An account level can reflect activity without determining match power. Character familiarity tracks played actions, such as rescues or completed trials, and unlocks narrative scenes. Trial mastery uses transparent objectives: complete without dropping a mote, rescue a partner after a fall, or identify every true clue. It does not require deliberately sabotaging strangers.

## Reward ledger

Award participation for meaningful work: objective progress, successful distraction tied to teammate progress, rescue, recovery, and reaching the escape. The Eye earns credit for legal contested pressure, varied socket use, and successful prediction. Cap repeated actions on the same trapped target. Team success provides a shared reward so players have a reason to help even when they are unlikely to escape personally.

The post-match ledger shows the source of rewards. A player should not need a hidden formula to understand why a rescue mattered. Any premium business model is a later product decision; this bible does not introduce paid power, a store, or a live economy. Monetization must not determine the readability or fairness of the core game.

## Campaign and seasonal content

A first narrative arc introduces the four realms in a curated order, interleaved with archive discoveries. Campaign variants can use AI and authored dramatic moments, while competitive maps reuse validated systems. Story completion unlocks alternate explanations and cosmetic identity, not essential mechanics withheld from multiplayer newcomers.

Future seasons should add one coherent pressure family at a time: for example, linked movement with Threads of Fate and Warden's Chains, or testimony with Mirrors of Deceit and Whispers of the Void. Adding all twenty-five trials at once would make onboarding and balance difficult. The catalogue is a production reservoir, and the release plan selects complete, tested subsets.

## Online boundary

The UE5 target uses an authoritative session model and Blueprint gameplay. Session discovery, account identity, cross-platform play, anti-cheat, persistence, moderation, and dedicated-server operations are separate workstreams with explicit acceptance gates. “Blueprint-only” is a gameplay authoring constraint, not evidence that every platform service works without integration.

No current documentation should imply that a local bot encounter is already a live online game. The next networking milestone must demonstrate at least one remote survivor, the Eye's authority checks, synchronized trial state, reconnect handling, and consistent victory resolution under simulated delay before its mode is exposed as supported.
