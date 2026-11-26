# 04 — The Eye

This chapter specifies the production antagonist. The section **Current prototype tuning** identifies what the local Godot implementation currently provides; fuller animation, escalation, illusion, AI-scoring and result-analysis proposals elsewhere are future work.

## Physical identity

The Eye is an enormous living organ seated inside a mechanical and ritual socket. Its sclera is imperfect, its iris moves with intent, and its lid closes before a transfer. Supporting rings, cables, sculptural ribs, and a deep cavity make each socket part of the architecture. The Eye never becomes a free-moving flying camera. Even when a human player controls it, its position comes from a valid socket and its aim respects that socket's limits.

The visible organ is also an information display. A relaxed iris means observation; a narrowing pupil means commitment; a contracting ring announces a socket transition; a bright charged rim announces an expensive command. The physical animation, audio, and survivor HUD agree on the same state. An animation cannot imply that the Eye is looking left while its authoritative gaze points right.

## Observation network

Every arena has an authored graph of sockets. A socket stores a unique ID, transform, allowed aim range, associated room, connected sockets, and activation conditions. Designers place sockets to expose meaningful choices rather than provide perfect surveillance. At least one approach to each trial must be protected from the currently occupied socket, or have intermittent cover that permits progress.

The observatory uses four sockets across its prototype contracts. The final game can support larger graphs, but socket count is not difficulty by itself. The important measurements are travel time between survivor cover, time lost by the Eye when switching, and the number of objectives that can be threatened from one position. A socket covering all three seals and the exit is presumptively invalid unless its use has a severe, visible limitation.

A transfer closes the source Eye, plays a traveling mechanical cue, and opens the destination after a short transition. The Eye cannot activate a trap during the closed interval. Previously committed hazards continue according to their announced state, so changing sockets does not cancel damage silently. Survivors can recognize the destination by sound and by a local socket light before the new gaze becomes dangerous.

## Current prototype tuning

The v0.1 domain implementation establishes the following values; the v0.2 prototype retains them unless its release notes state a tuning change. The alternate trial rules are specified in [Prototype contracts](12_PROTOTYPE_CONTRACTS.md). Runtime verification must confirm the renderer and input layer call these rules correctly.

| Rule | Prototype value |
|---|---:|
| Preparation | 8 seconds |
| Story Hunt / Escape | 600 / 90 seconds |
| Standard Hunt / Escape | 480 / 65 seconds |
| Ruthless Hunt / Escape | 360 / 50 seconds |
| Energy capacity / regeneration | 100 / 4 per second |
| Trap cost / cooldown | 25 / 4 seconds |
| Mark cost / cooldown | 20 / 6 seconds |
| Summon cost / cooldown | 45 / 16 seconds |
| Blink cost / cooldown | 8 / 2 seconds |
| Silent Countdown | 3 unique consumed motes |
| Echoes | Seeded permutation of 4 symbols |
| Clockwork Relay | 12 seconds net hold; bank at 4 and 8 seconds |
| Relay release decay | 1/24 of full progress per second, bounded by last checkpoint |

All combat powers require verified line of sight in the prototype rules. Blink changes sockets and does not require target line of sight. These are implementation values, not balance conclusions from a large population of players. The Eye wins if all survivors are eliminated or the active deadline expires. The first valid survivor escape wins the round for the survivor side; the human survivor must hold E at the open north doorway for 1.5 seconds.

Prototype **Terror** rises as atmosphere telemetry and appears in the Eye HUD. It is not spendable, does not unlock an ultimate, and does not change AI behavior or damage. Opening the exit starts the escape deadline but does not currently grant an energy refill or a separate Rage power. Prototype socket changes reposition the Eye and provide a 0.85-second reacquisition warning without gaze gain; the fuller production eyelid-transition presentation remains separate work.

## Attention and resources

The production design separates **energy**, the spendable budget for commands, from **terror**, an escalation measure built through meaningful pressure. Energy recovers at a predictable rate and has a visible cap. Terror does not rise from repeatedly damaging an already trapped player or idling at a spawn; it rises from contested trial time, first sightings, and successful but fair interventions.

The Eye cannot spend more than it has, chain commands during a global recovery interval, or queue a command at a target that no longer exists. A failed validation does not consume energy. When two inputs arrive together, process them deterministically. The UI previews the selected cost and explains “Blocked,” “Out of range,” “Recharging,” or “Not enough energy.” A human Eye needs to understand missed opportunities as clearly as survivors understand damage.

## Power families

| Power | Purpose | Required commitment | Survivor answer |
|---|---|---|---|
| **Actuate** | Arm a visible trap or mechanism | Valid target, energy, local warning and cooldown | Leave footprint, take cover, interrupt designated control |
| **Brand** | Convert sustained observation into temporary pressure | Maintained line of sight and mark windup | Break sight, draw attention, use alternate route |
| **Call the Hollow** | Spawn a bounded pursuing minion | Visible legal anchor, high cost, spawn warning, population cap | Reposition, use cover and light, outlast pursuit |
| **Blink** | Occupy another socket | Connected destination and transfer recovery | Move during closure; exploit abandoned lane |
| **False Witness** | Place an illusion in a legal perception zone | Cosmetic deception budget and expiry | Compare authoritative signage, inspect physical clue |
| **Blackout** | Temporarily reduce ambient visibility in one sector | Sector warning, minimum navigation light remains | Carry light, use memorized route, wait behind cover |
| **Rage** | Final phase pressure modifier | Automatically tied to escape state | Use route knowledge and preserved resources |

Only the powers actually exposed by the current build should appear as available controls. False Witness, Blackout, Rage, and advanced Terror combinations are production extensions. A design list does not justify displaying an unusable ability in the prototype menu.

## Trap authorization

Gaze identifies the target through a trace or equivalent query. Merely having a trap inside a broad cone is insufficient when a wall blocks the connection. The final authority checks phase, controller role, target type, target state, range, visibility, cost, cooldown, and the trap's own local constraints. It then reserves the cost and starts a telegraph. This prevents both accidental activation and future multiplayer clients from asserting a hit without validation.

Telegraphs belong to world geometry. A spike bed lights its exact footprint, a blade rail vibrates along its actual sweep, and a closing wall sounds from its physical side. Warnings use shape and motion as well as color. A survivor already standing inside a trap has enough time to reach a legal safe position at normal movement speed unless they deliberately committed to a clearly stated risk.

## Summons

A summon uses a prepared anchor with navigable space, sufficient clearance, and a minimum distance from survivors. The Eye cannot spawn a minion inside a body, behind a sealed wall, or directly on an exit trigger. The spawn effect announces arrival before the actor can damage. The active population cap is low enough that survivors can read individual threats; two meaningful minions are preferable to ten indistinguishable collisions.

Minions have finite persistence and explicit target acquisition. A minion that loses its target searches the last known area, then returns or expires. It cannot inherit the Eye's knowledge of hidden actors automatically. The summoning cost is spent on the opportunity to create pressure, not a guaranteed hit. Minions that become stuck are safely repositioned only to authored anchors, or despawned; they never teleport silently into attack range.

## Illusions with a trustworthy interface

An illusion may be a false corridor mural, a decoy survivor silhouette, an extra reflection, or a misleading whisper. It cannot imitate the real operating-system UI, change a player's accessibility setting, falsify health, or claim that the third seal was banked when it was not. Every gameplay-relevant illusion has at least one learnable distinction, such as a missing shadow, incorrect symbol frame, or different timing.

Repeated exposure should make players better at interpretation. Randomly replacing the correct clue after the player commits is prohibited. An Eye may obscure an optional duplicate clue for a limited period; it cannot remove all evidence needed to solve a mandatory puzzle. The institution can be manipulative while the game remains fair.

## AI control

The AI Eye uses the same public action interfaces as a human. Its perception record contains visible survivors, recent noise areas, objective state visible to the institution, recent socket use, and known hazards. It scores candidate actions by pressure, cost, opportunity, and fairness. A small reaction delay prevents frame-perfect punishment. Difficulty changes the quality and speed of decisions, not access to secret positions.

An example sequence is: hear a loud delivery, choose a socket that can inspect that wing, open with a warning, identify a visible carrier, threaten the obvious return path, then reconsider when the carrier takes cover. If no legal target exists, the AI waits or changes vantage rather than cheating. Record a concise decision reason in diagnostic mode so designers can distinguish poor positioning from broken perception.

## Eye-player experience

The Eye interface emphasizes four things: current socket, visible targets, energy, and available commands. Switching is quick to understand, while aim and timing require skill. A small map may show sockets and public objectives, but never grant hidden real-time survivor positions. The player can inspect an ability's cost without abandoning their view.

Winning as the Eye should require denying the last route or forcing a sequence of mistakes. Losing should reveal where attention was spent ineffectively. Results therefore include socket dwell time, commands denied by cover, traps avoided, active pressure time, and seals contested. Raw damage alone is a poor teaching metric for this role.
