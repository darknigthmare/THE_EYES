# 15 — The Trial Workshop

## Purpose and delivery boundary

**The Trial Workshop** is the v0.5 learning mode for the nine implemented observatory trials. A player selects one trial, an archetype and a seed, learns its physical apparatus, completes it, and can immediately try again. It gives the player time to understand a rule before applying that rule under the Eye's pressure.

The Workshop uses the existing Godot arena, survivor controller and trial authorities. It does not add a tenth trial, another realm, a network session or an Unreal executable. First, Second, Third and Seeded Mix remain the four match contracts; each match still selects three trials from the existing nine-trial pool. Practice is a separate session policy with one selected objective.

This chapter describes the intended v0.5 behavior. The version's release report is the authority for completed verification and platform qualification. A teaching description, a journal entry or a screenshot is not evidence that a player has mastered the same trial in a pressured match.

## The learning promise

The player should be able to answer five questions without leaving the game:

1. What must I complete in this trial?
2. Which physical object do I need to approach, read or carry?
3. What input performs the action, and what can interrupt it?
4. What happens when I make a mistake, and what progress remains safe?
5. What proves that this particular practice session is complete?

The Workshop removes opposing pressure while retaining the actual task. A player still walks through collision, reaches the correct apparatus, carries uniquely owned objects, observes the public clues, waits for real interaction intervals and completes the same checkpoints. The interface explains the current task; it does not press controls, teleport the player through the route or award progress for reading a page.

## Entering a drill

The selection screen presents all nine implemented trials by their stable name and learning goal. It also exposes the survivor archetype and seed used for the next attempt. The selected drill's rule and main controls are visible before starting. A practice record can indicate prior completion, but the player does not need a prior win or unlock to enter any drill.

Only the selected trial's bay is active. The other bays are inactive and cannot supply cargo, answer puzzle commands or earn extra seals. They must be visually distinguishable from active work. Their completion flags are not pre-filled to imitate a three-seal match; the practice authority asks for one real completion.

The player starts with one local human survivor. There are no AI allies to finish the task while the player reads, and no human Eye opponent. The fixed Eye and observatory architecture may remain visible as part of the setting, but the Workshop does not run the Eye's attack loop, gaze wounds, traps or summoned shadows. It has no Hunt deadline and does not require an escape after completion. An elapsed practice time measures the player's attempt; it is not a countdown to failure.

The archetype remains a real choice. Movement, stamina, abilities and role-specific help use the normal survivor implementation. Tinker can therefore learn the machinery with the same mechanical advantages available in a match, while Runner can learn a route with their normal movement behavior. Practice records must preserve this context instead of suggesting that unlike archetypes produced interchangeable timing results.

## Practice is a complete session type

A drill has a short and explicit lifecycle: selection, active practice, completion, then a new choice. The selected trial's authoritative completion ends the active attempt once. The result screen identifies a **Workshop trial completion**, with the trial, seed, archetype and recorded elapsed time. It must not show a survivor-team victory, a defeated Eye, an escape count or a three-seal accomplishment.

The completion screen offers distinct decisions:

- Repeat the selected trial with the same seed to refine the same puzzle or route.
- Start a new seeded attempt of that trial to test understanding beyond a memorized answer.
- Move to the next trial in the authored selection order.
- Return to the Workshop selection or main menu.

Every relaunch rebuilds transient trial state: carried objects, partial holds, cooldowns, stage observation, banked checkpoints and the attempt timer. Starting an admitted drill increments its attempt count; only a legitimate completion increments the completion count or updates a finishing time. There is no list of past attempts or saved partial session. A restart begins a new attempt.

A new seed requests a new deterministic setup; it is not a promise that every visible feature will differ. The original trials include fixed geometry, fixed quantities and mechanics whose variation can coincide between seeds. Repeating a seed within this version reproduces the trial's generated puzzle state. It does not create a replay of every input or physics frame.

## The nine lessons

### Silent Countdown — ownership and delivery

**Learn:** recognize an objective, carry one item at a time and finish a delivery at the real destination.

Approach a whisper mote, take it with E and bring it to the northwest station. E at the station deposits the carried mote. All three distinct motes are required. The completion display advances on accepted deposits, not on visiting a pickup or walking through the station.

The normal movement and cargo rules remain useful to learn even without an attacking Eye. Sprinting with a mote produces the existing noise behavior, but the Workshop does not turn that sound into an enemy intervention. Releasing cargo does not count as a delivery. A practice completion teaches the delivery route; it does not certify stealth against the Eye.

### Trial of the Echoes — observe, replay, answer

**Learn:** read a demonstration and enter the demonstrated order without confusing symbol identity with an input action.

Reach the northeast station and use E to open the Echoes panel. Watch the four-symbol demonstration, then answer using the numbered inputs or the corresponding buttons. The replay control repeats the demonstration. Leaving the panel allows another physical attempt.

A wrong valid symbol resets the current response. Unrelated or invalid input cannot advance it. Practice preserves the same seeded sequence and answer validation as a match. The general field guide explains the rule and controls; it does not complete the sequence on the player's behalf. In an ordinary match the Eye remains active while this panel is open, so a practice time is not a pressured completion time.

### Clockwork Relay — commitment and checkpoints

**Learn:** hold an interaction, recognize a permanent checkpoint and distinguish it from unbanked work.

Reach the south mechanism and hold E within the normal valid interaction range. Progress integrates through the real continuous interaction. The first and second checkpoints protect completed thirds when the player lets go. Unbanked progress can decay toward the current bank.

The lesson can be repeated by deliberately releasing after a checkpoint and observing what remains. A full bar and the authoritative seal event complete the drill. Merely leaving E pressed while moving out of reach does not continue work. Tinker's normal contribution advantage remains part of the chosen archetype's practice context.

### The Memory Vault — exact object and slot identity

**Learn:** distinguish the requested item from its destination and check a multi-part reference.

Read the northwest reference to learn the four requested relics. Travel to the shelves, take one real relic and deliver it to its exact numbered cradle. The four target entries correspond to four distinct placements. A correct item in the wrong cradle is still a wrong placement.

Accepted placements remain banked. A wrong deposit does not consume the carried relic or silently replace the request. G returns cargo so another object can be chosen. The practice interface tracks accepted placements; it does not fill a cradle after a player merely reads its name. Replaying the public reference is part of learning the apparatus.

### The Ritual Circle — sequence, pair banks and occupancy

**Learn:** follow an ordered route, understand a recoverable mistake and complete a final occupancy condition.

Take the shared ember and visit the five vessels in their engraved order. Correct pairs form checkpoints. A wrong unlit vessel rolls back the unbanked part and returns the ember; already lit vessels are safe to revisit. The player can inspect this recovery behavior without also fighting the Eye.

Once all five vessels are lit, stay inside the final ring for eight continuous seconds at floor level. Movement within the valid ring is allowed. Leaving it resets the incomplete final hold while preserving the earlier completed vessel work. Jumping above valid floor occupancy cannot stand in for staying in the ring. Completion follows actual occupancy, not a button on the guide.

### The Clock Room — coupled transformations

**Learn:** predict which hands a lever affects, reverse a move and distinguish alignment from confirmation.

Inspect the current and target hand positions. The three levers affect overlapping pairs: A changes A and B, B changes B and C, and C changes C and A. Use E for the forward transform and R for its reverse. The centre reset returns the apparatus to its generated starting state.

After the three hands match, walk to the central press and confirm with E. Matching the display alone does not finish the drill. Tinker's ordinary Overclock advice can suggest the next physical move; it does not move the lever. Repeating the same seed supports learning a coupled puzzle, while a new seed checks whether the player understood the relation rather than memorized a single button sequence.

### Light in the Darkness — a recoverable resource route

**Learn:** match cargo identity, budget charge and build a route of permanent refuges.

Each of the three cells belongs to the lamp with the same number. Carry the cell to that lamp, remain still and maintain E through the normal two-second alignment. A completed lamp becomes a permanent recharge refuge for the rest of the attempt.

Charge drains while a cell is carried outside a valid refuge. The starting refuge and lit lamps restore it. The player can return to recharge, release cargo and try again; empty charge does not disable movement or erase an already lit lamp. A charge value is not itself objective progress. The drill ends only when all three lamps have been physically aligned.

### Strings of Despair — intersect two public clues

**Learn:** explain why one candidate is correct before committing an interaction.

Read the current side clue and shape-family clue. The side selects the left or right pair of ropes. The family selects a curved shape (Circle or Crescent) or an angular shape (Triangle or Diamond). Their intersection identifies one rope. Walk to that rope and hold E while still for the normal two-second cut.

A successful cut banks one of three cage stages and introduces the next clue. A new cut needs a fresh eligible hold; partial progress from the previous stage cannot carry into it. A wrong cut engages the safety catch and preserves earlier completed stages. The player must reason about the current stage's evidence rather than repeat the last rope automatically.

### Chimes of Doom — phrase banks and shared equipment

**Learn:** read an ordered score, travel between stable instrument identities and understand a shared damper.

Read the current four-note phrase and approach each numbered bell in order. E strikes a nearby bell. R moves or removes the one shared damper at that bell. The command intervals and note validation remain the normal trial rules.

The first completed phrase is a permanent checkpoint. A wrong note resets only the current phrase. A correct damped strike produces less noise memory than an ordinary correct strike; a wrong note remains loud. The Workshop can teach these cues and the control sequence, but with no active Eye it cannot measure the tactical benefit of quieter play. Both completed phrases finish the drill.

## Guidance without remote solutions

The practice HUD identifies the selected lesson, current legitimate progress and the next type of action. It should name the physical task in plain language: carry, read, align, cut, strike or confirm. This guidance must be derived from admitted state, so a refused action cannot make the display imply success.

During active Workshop play, **H** folds or restores the guide on the right so the player can see more of the apparatus. The trial title and progress, objective/cargo information and controls remain visible. When folded, a small **H SHOW WORKSHOP GUIDE** reminder provides the return action. This changes presentation only: the trial continues and its active time keeps advancing.

Every new attempt opens the guide again, including same-seed retry, another seed and the next trial. The choice lasts only for the current attempt and is not saved as a setting or journal field. The map, Echoes panel, pause and F1 manual temporarily hide both guide and reminder without changing that choice; returning restores the previous display state. H is inactive on those screens, in menus/results and during ordinary matches.

The Field Manual can be opened during a session, including from pause. Its trial descriptions preserve the same goal, controls, failure and recovery explanations available from the menu. F1 provides a direct route to that information. The manual is a safe reading surface: opening it pauses local simulation, and closing it returns through the appropriate menu or pause context. It does not automatically resume a background match simply because a page was closed.

Generated puzzle evidence remains tied to the apparatus that presents it. A rule page can explain how to interpret a side/family clue or clock transformation without exposing a hidden answer remotely. Any future explicit answer-reveal assistance must be named, reflected in records and scoped separately from an unaided completion; it is not implied by the Workshop's ordinary instructions.

## Attention, pause and controls

Losing application focus pauses an active local session. Regaining focus does not automatically expose the player to attacks or continue a held interaction. The player deliberately resumes. The same local pause cancels incomplete work according to each trial's existing rules while preserving completed checkpoints.

This is especially useful when reading a clue, switching applications or learning controls, but it is also a normal-match safeguard. It is not a network pause policy. A future remote game must decide separately how local menu access affects the shared simulation.

The FOV setting is explicitly a **survivor and spectator** camera setting. The human Eye retains its authored view and perception relationship. The Workshop does not introduce a gamepad implementation or user key rebinding. Physical QWERTY/ZQSD mapping, the existing accessibility settings and the documented controls remain the current input contract.

## The practice journal

Practice is recorded in `user://practice_records.json`, separately from the ordinary `last_observance.json` match ledger. From v0.5, `user://` uses the stable **THE_EYES** application-data directory, so changing a release subtitle does not select a new records folder. Its purpose is a local learning summary: how often each trial has been attempted and completed, the latest attempt's seed and timing, and the best completed time for the chosen archetype. It does not grant currency, modify health, shorten cooldowns, unlock a stronger role or report competitive wins.

A journal completion must come from the selected trial's admitted completion, once per attempt. Opening the Workshop, reading a page, restarting, leaving an incomplete drill or loading a record must not fabricate a completion. The timer stops during pause and after the attempt ends. Results are observations of this practice policy, not global leaderboard entries or a promise that another machine reproduces the same timing.

Schema 1 contains the nine known trials and four archetype profiles per trial: Veil, Tinker, Runner and Keeper. Each profile holds attempts, completions, the latest attempt's seed and seconds, and the best completed time and seed. The latest seconds reset to zero at the start and are filled on completion; zero alone is not proof of either completion or failure. A prior best remains after an abandoned attempt. Trial totals are sums of the four profiles. The 36 profiles are fixed in number; repeated play does not append an unbounded history. A Runner best is compared with Runner attempts, and a Tinker best with Tinker attempts. Seeds identify the puzzle context but do not divide the journal into additional records.

The stored data is validated before use. Unknown trial identifiers, malformed record types and unsupported schema data must not become instructions for the game to execute. A missing or unusable practice file must leave the player able to train. An unreadable file or unsupported schema is preserved, with writes blocked rather than silently replacing it. A save failure must not be presented as a successfully persisted record. The detailed field types, limits and failure behavior are defined in the [implementation contract](../technical/PRACTICE_IMPLEMENTATION.md).

Before replacing an existing valid notebook, the game retains one `.bak` recovery copy. If replacement removes the primary and then fails, it attempts to restore that copy while still reporting the save failure. At the next load, `.bak` is used only when the primary is absent; a corrupt or newer-schema primary is preserved without fallback. An invalid or unsupported existing backup also blocks saving, protecting that copy. This is a temporary-file replacement with recovery, not a claim of atomic Windows writes. The notebook remains bounded, and old title-based data folders are not automatically migrated.

## Acceptance and remaining production work

The Workshop is ready for a release only after every selected trial can be completed through normal movement and interaction, inactive bays reject work, repeated completion does not duplicate records, and restarting clears the previous attempt. Verification also covers pause/manual/focus transitions, cargo recovery, record isolation and the existing competitive regressions.

The playable delivery remains the Godot prototype. The Unreal handoff specifies an explicit Practice session policy and trial-selection table, but its Blueprint assets still need authoring, compilation and runtime checks in Unreal Editor. Eye training, additional teaching simulations, remappable controls, controller qualification, online practice parties and production progression remain separate work. The Workshop's success criterion is narrower and observable: a human can select, understand, complete and repeat any of the nine existing trials without an opposing Eye or a match deadline.
