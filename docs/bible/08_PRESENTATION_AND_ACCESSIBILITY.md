# 08 — Presentation and accessibility

This chapter is the production presentation specification. Current prototype features are identified explicitly; the accessibility table is an acceptance target, not a report that every listed option has shipped.

## Art direction

THE EYES uses monumental scale and disciplined contrast. The Eye is the warmest living object in a room of cold manufactured surfaces. Survivor-authored marks use pale cyan or chalk. Mechanisms use tarnished brass and iron. Immediate hazards use a restrained red-orange signal with shape and motion support. The palette is a hierarchy of information, not a requirement that every room be nearly black.

Materials need readable roughness and wear at human contact points. A crank is polished where hands would grip it. A service door has scratches near its real hinges. The Eye's wet surface contrasts with dry stone and matte cloth. The first polished environment should establish this material grammar before producing hundreds of decorative variations.

The prototype uses procedural geometry, materials, eye construction, and generated nonverbal audio. These do not substitute for a finished production character, sculpted creature, authored cinematic, or final soundtrack. Screenshots should distinguish actual gameplay from future visual targets.

## Camera and motion

The production survivor camera should prioritize spatial judgment and offer adjustable field of view within a range verified for that build. Independent controls for head bob, impact shake, motion blur, chromatic effects, and camera roll are production requirements. Disabling these effects must not remove the only warning of an incoming attack. The current prototype provides field of view from 65 to 100 degrees, sensitivity, inverted vertical look, one reduced-motion/vignette option, and an audio toggle; it does not provide all independent production sliders or input remapping.

The Eye camera is fixed to a socket with constrained aim. A transfer uses a brief closure and reappearance rather than a long free-flight camera move. An optional tactical view shows socket topology and public objectives, but no hidden survivor information. Selection highlighting must not reveal actors through cover unless a declared ability permits it.

## Interface hierarchy

The survivor HUD presents remaining match time, three seal states, health, stamina, current carried object, exposure, and a contextual action. It should not show every future mechanic at once. The most urgent element is the local action or warning; persistent status stays quiet until relevant. A trial timer is explicitly labeled separately from the match timer.

The Eye HUD presents current socket, energy, command costs, cooldowns, valid target state, and known observations. A target icon distinguishes visible, blocked, out of range, and cooling down. The same input must not trigger a different expensive command because a hidden selection changed one frame earlier. Commands should be previewable and cancelable before a committed windup where appropriate.

Production menus should separate Play, How to Play, Trial Archive, Settings, and Credits. The current menu provides **Enter as a survivor**, **Take the Eye's seat**, **Field Manual**, and **Settings**, with archetype, difficulty, and seed selection. The trial catalogue is documentation, not an implemented in-game archive or practice selector. Production online modes appear only once the session flow exists.

## Trial instruction format

Every trial begins with a short card containing the goal, primary verb, failure consequence, and one counterplay hint. For example: “Bring three whisper motes to the basin. Carry one at a time. Loud movement draws attention. Delivered motes stay safe.” The detailed archive then explains the full rule. This supports both immediate play and deeper study.

World signs mirror the important information. A player who closes the instruction card can still identify the basin, glyph sequence, or crank. Progress is represented physically as well as in the HUD. The final seal makes the exit visibly change, with a distinct audio cue and a route marker that points to a real connected path.

## Sound and music

Audio layers are functional. The ambient bed establishes material and scale. Socket movement announces attention changes. Trap warnings identify mechanism and direction. Character breaths reflect exertion. The Eye's vocal layer remains sparse enough that it does not mask a nearby hazard. Music responds to state but is never the sole timing source for a mandatory action.

The prototype uses procedurally generated nonverbal cues. A production sound list includes eye blink, iris strain, socket arrival, energy charge, trap warning/active/recovery, footsteps by surface, quiet movement, pickup/drop/deposit, seal bank, exit opening, minion perception, attack windup, hurt, recovery, victory, and defeat. Each cue needs a priority and concurrency limit.

Mix priorities place lethal warnings and essential interactions above ambience and dialogue. Repeated events are rate-limited. A swarm of sound events must not cut off the warning that makes a trap fair. Dynamic range presets support headphones, speakers, and a reduced-range environment. Independent volume controls cover music, ambience, effects, dialogue, and voice communication.

## Accessibility requirements

| Area | Requirement | Verification |
|---|---|---|
| Vision | Shapes, names and positions supplement color | Complete every trial in grayscale review |
| Hearing | Captions and visual timing for meaningful audio | Complete sound-themed trials with audio muted |
| Motion | Adjustable shake, bob, roll and disruptive effects | Finish traversal with reduced-motion preset |
| Motor input | Remapping, hold/toggle options, scalable timing in practice | Test keyboard, controller and simplified input profile |
| Cognition | Plain instructions, replayable cues, stable terminology | New player can explain objective after one instruction |
| Text | Scalable text, readable contrast, speaker labels | Review at minimum supported resolution and maximum scale |
| Photosensitivity | Avoid rapid full-screen flashes; provide restrained effects | Inspect worst-case overlapping effects |

Competitive settings require careful separation. A preference that removes camera shake should not change gameplay difficulty. A practice assist that widens a timing window changes scoring rules and is labeled accordingly. Custom lobbies can select shared assists openly. Accessibility must not be treated as a secret advantage or a reason to withhold basic information.

## Communication and social interface

Pings use a small vocabulary: danger, need help, objective, follow, wait, item, and ready. They report what the player can perceive. A ping through a solid wall does not reveal a hidden minion unless the player has valid information. Repeated pings are rate-limited and can be muted. Contextual text allows useful cooperation without voice chat.

Player identity appears clearly during a rescue or item exchange. The Eye sees only the information its role is meant to know. Spectators do not receive unrestricted tactical knowledge that would undermine hidden-state play. Production moderation, blocking, reporting, and privacy controls belong to the online milestone; the local prototype does not claim a service backend.

## Results and learning

Results explain the outcome first: who escaped, whether the deadline expired, or which survivors were eliminated. The prototype displays the result reason, elapsed time, seal count, wounds, seed, and difficulty. Production results should add contributions, rescues, recoveries, time under gaze, and useful Eye pressure metrics. Avoid a single score that encourages farming a downed player or refusing to help because rescues are inefficient.

A future match timeline and practice replay can explain visibility situations. The current `last_observance.json` stores a result, seed, counters, and event ledger; it is not a mid-match save or a deterministic full replay. Settings persist separately in `settings.cfg`. Replaying an Echoes demonstration is an implemented puzzle control, not a match-replay system.
