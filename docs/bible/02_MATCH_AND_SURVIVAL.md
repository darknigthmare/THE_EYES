# 02 — Match and survival

## Scope and units

This chapter defines the production rules. All times are seconds unless stated otherwise; distance is meters. The Godot slice may use a smaller population, shorter durations, and simplified recovery. Its tested constants remain authoritative for that build. The production default is six survivors against one Eye, with supported Classic variants for five and seven survivors.

The v0.3 implementation adds a distinct local Squad recovery model: one human with four AI allies, a 35-second downed window, six continuous seconds of physical rescue, 35 restored health, and five seconds of protection. Interruption fully resets that rescue attempt. Solo retains Second Sight. These scoped prototype rules are specified in [Squad and rescue](13_SQUAD_AND_RESCUE.md); production proposals below do not silently override them.

## Match state machine

| State | Entry | Available actions | Exit |
|---|---|---|---|
| Lobby | Session created | Role, character, accessibility and loadout selection | Required participants ready |
| Preparation | Valid map and spawn set loaded | Read rules, move in receiving area, inspect routes | 25-second countdown ends |
| Hunt | Preparation ends | Three trials, rescue, items, Eye commands | Three seals, all eliminated, or match timeout |
| Escape | Third seal acquired | Exit route opens, Eye escalates within caps | First survivor exits, all eliminated, or escape timeout |
| Survivors win | A living survivor crosses the valid exit trigger | Results and optional survivor epilogue | Rematch or lobby |
| Eye wins | No living or recoverable survivors, or timer expires | Results | Rematch or lobby |
| Aborted | Invalid session state or explicitly cancelled practice | Diagnostic result with no progression penalty | Lobby |

Use a single authoritative outcome. A seal completed during the same simulation step as a timer expiry uses the server event ordering defined for the build; display the resulting reason. The proposed ordering is: resolve accepted interactions, resolve valid escapes, resolve damage, then resolve timeout. This ensures that crossing the exit at zero does not depend on which HUD rounded first. A completed match cannot accept late damage or change its winner.

## Objectives and permanent progress

Three selected trials award three distinct seals. At least one trial is spatial, one tests interpretation or memory, and one tests coordinated operation. The selection process respects realm compatibility, player count, accessibility configuration, and objective placement. It never picks three trials that all require the same absent specialist. Every archetype can complete every required action.

A seal is a durable checkpoint. The Eye can interrupt an incomplete interaction, force a temporary detour, or reduce unbanked progress within a documented cap. It cannot erase a completed trial. The door displays three physical recesses, the HUD shows the same count, and all clients receive the same authoritative state. A survivor who rejoins sees the actual seal state immediately.

The baseline Hunt timer is twelve minutes. Completing the third seal starts a ninety-second Escape phase, subject to a maximum total duration chosen by the mode. The Eye receives an energy refill capped at its normal maximum and a visible Rage modifier; damage does not become an instant kill. Escalation increases frequency and territorial pressure while preserving warning durations and mandatory safe opportunities.

## Survivor controls and movement

The production controller supports walking, sprinting, crouching, jumping, interacting, carrying, dropping, using a tool, contextual pinging, and the archetype ability. First-person movement is the initial clarity target; an optional third-person camera requires separate visibility and corner-peeking review. Walking speed starts at 4.3 m/s, sprinting at 6.2 m/s, and crouching at 2.5 m/s. These are tuning hypotheses rather than a declaration of prototype values.

Stamina starts at 100. Sprinting consumes 18 per second and recovers 15 per second after one second without sprinting. Exhaustion prevents sprinting until stamina reaches 20, avoiding rapid stuttering at zero. Jumping has a modest fixed stamina cost, but core safe routes must remain walkable so that exhaustion is not a hidden death sentence. Carrying heavy objects reduces speed; dropping is immediate and never requires opening inventory.

Crouching lowers the collision capsule and sound radius. The camera follows with a short eased movement that can be reduced in accessibility settings. The capsule only returns to standing height when clearance exists. Movement collision, Eye visibility, interaction range, and camera obstruction use intentionally separate tests. Decorative grass must not become a reliable wall against gaze unless the material visibly communicates that role.

## Visibility, noise and exposure

Sight is the intersection of valid range, the Eye's facing cone, and an unobstructed trace to meaningful survivor sample points. A survivor behind solid cover does not accumulate gaze exposure. Partial cover may expose the head or torso; the HUD displays the actual exposure category. The Eye's AI cannot use hidden exact positions simply because the scene contains those nodes.

Noise is an event, not constant omniscience. Sprinting, dropped heavy props, failed checks, or ringing a bell creates a temporary location cue with uncertainty. A noise cue identifies an area and age, not a perfect moving outline. Crouching reduces footstep noise but does not silence intentionally loud machinery. The Eye may choose to investigate a cue by changing sockets, spending time away from another objective.

Sustained visible gaze builds an exposure meter. A short glance gives warning; continued exposure enables a mark or punishment condition. Cover causes decay after a brief delay. The production baseline uses approximately three seconds of uninterrupted clear gaze to reach a mark threshold, subject to ability modifiers. A mark lasts a bounded period and reveals only what its stated effect permits. A marked survivor can still use cover to block damaging commands.

## Health, rescue and elimination

Survivors begin with 100 health. Common hazards remove roughly 15–30 health after a warning. A damage grace window prevents a single overlapping trap volume from applying full damage every frame. Separate major hazards cannot form an unavoidable chain during that grace window; control returns before another lethal condition can mature.

At zero health, a production survivor enters a downed state if a recovery opportunity remains. They crawl slowly, ping once per cooldown, and can receive a teammate rescue. Baseline revive requires six seconds of continuous interaction and returns 35 health. Interruption retains a small documented fraction rather than all progress. Rescue grants brief protection against immediate re-damage, visibly signaled to both sides.

The first failed punishment may substitute for a down, depending on mode. Repeated captures eventually cause elimination; the maximum allowed strikes is visible before the match. A teammate never has to guess whether the next mistake removes someone permanently. Eliminated players receive a useful spectator view without privileged information that could be relayed to active friends. An escaped player's team has already won under the default rules, so any extended epilogue is optional and cannot reverse that result.

## Punishment as recovery gameplay

A punishment is a short, clearly bounded challenge, normally twenty to forty seconds, reached through a visible capture event. It should be simpler than a full seal trial and usable when a player is stressed. Examples include aligning three safe symbols, crossing a lit maintenance route, or holding a pressure valve through two pulses. Success returns the survivor to a legal reentry point with a short protection interval. Failure consumes a strike or produces a downed state according to the declared mode.

The punishment's timer pauses during a loading or transition failure. The reentry point cannot be inside active damage, under another player's body, or behind a permanently locked door. If all preferred anchors are unsafe, use the receiving chamber. The Eye cannot manually target punishment rooms unless that particular mode explicitly budgets a separate intervention; the base design gives captured players a brief opportunity to recover agency.

## Interaction model

Every interactive object has a verb, range, state, owner where relevant, and completion rule. A prompt says “Hold to crank,” “Take whisper mote,” or “Deposit mote,” not a generic “Use” when the consequence matters. Hold duration is represented by a progress ring and by the object's animation. Releasing the button has the same behavior on keyboard and controller.

Pickup and deposit are atomic. Two survivors cannot duplicate a single mote, and a disconnect cannot permanently remove it from the match. Dropped key items stay in reachable space; if physics sends one outside the playable bounds, it returns to a clearly marked fallback cradle after a short delay. The Eye cannot spend energy on an already disabled or invalid target. A denied command explains the actual reason without consuming the resource.

## Teamplay and selfish choices

The default Classic mode rewards cooperation and does not let one survivor grief the team by deleting seals, locking every route, or consuming a unique key. Doors that survivors can close always reopen from both accessible sides or have a predictable temporary lock. Body blocking at critical doors is mitigated through collision rules, wider thresholds, or an unstuck action that cannot be used to bypass hazards.

Temptation events are opt-in Custom rules. The Eye may offer a private benefit in exchange for an announced cost, such as revealing the accepting player's own route to restore stamina. The cost cannot secretly sabotage a teammate's irreversible objective. Offers use a clear accept/decline UI and expire. The post-match ledger records accepted deals. This produces social tension without relying on concealed rule changes or permanent harassment incentives.

## Difficulty and adaptation

Difficulty changes AI reaction delay, resource income, trial complexity, and recovery allowance. It does not remove essential warning signals, make safe tiles indistinguishable, or turn a solvable puzzle into a coin flip. Practice mode explains why a command succeeded and can visualize the Eye's actual sight lines. Standard mode removes diagnostic aids but retains actionable feedback. Severe mode narrows resource margins and combines more pressures while preserving the same mechanical truth.

The Eye's adaptive director uses observed events: recently noisy sectors, completed objectives, sightings, and failed survivor checks. It cannot directly read the player's intention or press an ability because a hidden health variable would guarantee a kill. Adaptation should be explainable in a replay. Balance review measures exposure time, trial abandonment, rescue success, idle waiting, and the distribution of survivor participation, not only win rate.

## Fairness acceptance examples

A survivor taking cover before the mark threshold must see exposure stop increasing. A survivor who returns with the final mote while another completes Echoes must bank both changes without dropping a seal. A living survivor crossing the valid exit during a simultaneous distant death must produce the declared team victory. A dropped objective item behind a moving wall must remain recoverable. A player who disables camera shake must still recognize every trap warning. A six-person lobby with no Engineer must still be able to operate Clockwork Relay.

These cases belong in repeatable acceptance tests and human play sessions. Numeric tuning can vary; the outcomes above define the game's contract with the player.
