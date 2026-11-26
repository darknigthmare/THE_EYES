# 06 — The twenty-five trials

## Catalogue contract

This chapter preserves all twenty-five titles from the supplied concept and expands them into playable specifications. **Only The Silent Countdown, Trial of the Echoes, and Clockwork Relay are selected for the current Godot slice.** The other entries are production designs, not finished levels. Their timings are initial production proposals to be tested with the final controller and supported player counts.

Each trial has an instruction phase, an active phase, at least one checkpoint, a failure/recovery rule, and a permanent completion. The Eye's interventions use the shared energy, visibility, warning, cooldown, and concurrency rules. An intervention may complicate a solution; it cannot secretly replace the solution after commitment or erase a banked seal.

Team scaling changes workload and simultaneous roles rather than multiplying every timer. A one-person practice version replaces mandatory partners with safe anchors or sequential controls. A five-to-seven-person Classic version offers useful parallel work. Downed or disconnected players cannot leave a mandatory two-person mechanism permanently unsolvable.

Blueprint names below describe implementation seams: a common trial controller accepts a validated interaction, updates authoritative state, commits a checkpoint, and emits completion exactly once. They are design instructions for future Unreal work, not claims that binary `.uasset` graphs already exist.

## T01 — The Labyrinth of Shadows

**Status / realm:** planned; Labyrinth of Shadows. **Skill:** route planning and observation. **Goal:** activate three index switches, then reach the exit alcove.

The room is a three-loop maze around a central pillar. Its moving walls have four approved configurations, each with a fully connected service spine. Floor grooves and a six-second bell sequence announce a shift. A diagram at each safe pocket shows the next open connections. Players can memorize routes, but a map is always available at protected intervals.

The first switch fixes one loop, the second reveals the remaining switch sector, and the third opens the exit. Each switch is a permanent checkpoint. A baseline active duration of 150 seconds creates pressure without requiring perfect movement. The Eye can command one early shift, arm a marked pressure plate, or darken an optional shortcut. It cannot close every path to an uncompleted switch.

Touching a plate produces a one-second warning before a bounded spike burst. A wrong turn costs travel time; it does not kill. A player caught in a transition is moved only by physical wall motion with a safety stop, or returned to the nearest legal pocket if geometry fails. Five-to-seven survivors split among loops, while solo practice reduces the distance between switches.

**Unreal hookup:** `BP_Trial_Labyrinth` owns a configuration index and switch bitset; wall components report occupancy before transition. The server validates connectivity against the approved configuration table before committing a shift.

**Acceptance:** every configuration remains solvable from every safe pocket; a dropped key object is reachable; the Eye cannot crush a motionless player without the declared warning and an available escape volume. The distinct design is readable spatial rerouting, not an arbitrary sequence of hidden doors.

## T02 — The Silent Countdown

**Status / realm:** prototype core; Labyrinth of Shadows. **Skill:** controlled movement and carrying. **Goal:** deliver three whisper motes to a resonant basin.

Three clearly numbered motes rest in separate cradles. A survivor carries one at a time and deposits it through an explicit interaction. Each accepted deposit consumes a unique mote and permanently increments the basin. The prototype requires exactly three. Production variants can change route geometry, but the HUD always shows the current total and remaining work.

The production version adds a sound-threshold needle and an accessible caption meter. The prototype uses movement noise, gaze feedback, and temporary AI noise memory: walking is safer than sprinting, and crouching is quieter still. The Eye may investigate from a socket. Production noise-triggered hazards and a dedicated trial countdown are extensions; delivered prototype motes remain banked.

Production timing begins at 120 seconds for a compact route. Noise above the threshold creates a short pressure event and may return an undelivered dropped mote to its cradle. A carrier who falls or disconnects releases the mote to a reachable recovery point. The Eye can threaten the direct return lane, forcing a choice between speed and cover.

With a full team, three carriers can work in parallel while others distract or prepare safe routes. Solo practice keeps all three deliveries but shortens travel. No microphone input is required; “silence” refers to game actions, so players can communicate and use accessibility devices normally.

**Unreal hookup:** `BP_Trial_SilentCountdown` owns consumed mote IDs; pickup and deposit are server-validated transactions. Audio events publish approximate locations through the perception system.

**Acceptance:** duplicate deposit requests cannot add progress; a lost mote recovers; every archetype can finish; delivered progress survives all Eye interventions.

## T03 — Threads of Fate

**Status / realm:** planned; Dollhouse. **Skill:** paired movement and pacing. **Goal:** move paired survivors across three mechanical platforms and secure both tether ends at the far anchor.

The arena is a long sewing table with broad platforms, moving gaps, and lower recovery trays. Partners share a visible tether with slack, tension, and overload states. Tension slows movement before it can cause harm. The tether is a game constraint with bounded forces, not an uncontrolled physics rope capable of launching a player.

The source's shared-health idea becomes a limited shared **strain** pool. Ordinary damage remains personal; excessive tether strain affects both partners after an explicit warning. This preserves interdependence without allowing one malicious jump to instantly eliminate two people. A pair can pause at each anchor to reset strain and bank progress. The baseline crossing takes ninety to 150 seconds.

The Eye can accelerate one platform within a visible speed range or activate a sweeping obstacle after a warning. It cannot pull the tether directly through cover. Partners counter by shortening the gap between them, waiting for a safe cycle, or selecting a wider route. A fall lands on a recovery tray and asks the standing partner to operate a return winch.

Odd teams assign one person a movable anchor sled. Solo practice uses that sled throughout. Disconnecting a partner automatically converts their endpoint to a safe anchor until replacement. A completed pair crossing cannot be undone by later entrants.

**Unreal hookup:** `BP_Trial_ThreadsOfFate` coordinates paired IDs, anchor checkpoints, and a replicated tension value. Movement assistance is authoritative and capped; cosmetics interpolate the rope.

**Acceptance:** no tether can cross a solid wall or multiply collision impulses; latency does not generate damage by itself; both endpoints have a recovery route. The trial is about negotiated movement rather than sacrificing a partner.

## T04 — Light in the Darkness

**Status / realm:** planned; Void of Despair. **Skill:** resource management and route discovery. **Goal:** connect three refuge lamps and reach the lit exit.

The arena is a network of stone islands connected by wide dark causeways. A handheld lamp reveals symbols, hazard edges, and phantom silhouettes. Its charge is finite, but refill stations exist at each permanent refuge. Darkness reduces information; it does not make the floor collision disappear. Critical ledges retain a minimum contrast outline.

Players find a power cell, carry it to a refuge, and complete a short alignment interaction. Each activated refuge becomes a permanent checkpoint with a small safe radius. The baseline trial lasts 150 seconds. Standing outside any lit zone slowly increases chill after a warning; returning to light stops it. Immediate unavoidable damage from a global blackout is prohibited.

The Eye can dim one nonessential lamp for eight seconds, spawn a telegraphed phantom at a legal anchor, or rotate a search beam. It cannot extinguish every refuge at once. Survivors can share illumination, alternate carriers, and preserve charge by using known routes. Light both reveals dangers and advertises position, creating a readable tradeoff.

A depleted lamp recharges slowly near a refuge. A failed crossing returns the survivor to the latest refuge with a time or health cost. Solo practice provides a wider personal cone; team mode offers multiple narrow cones that can combine. Audio cues have visual equivalents, and color is not the only distinction between safe and unsafe light.

**Unreal hookup:** a trial controller tracks refuge bits and cell ownership; light volumes report safety state independently of visual rendering quality.

**Acceptance:** the lowest graphics setting preserves all rules; a player with no lamp charge can still reach a recovery point; the Eye cannot create an all-dark unavoidable failure state.

## T05 — Trial of the Echoes

**Status / realm:** prototype core; cross-realm ritual station. **Skill:** observation and short-term memory. **Goal:** reproduce a demonstrated four-symbol pattern.

Four glyphs have distinct numbers, shapes, positions, and sounds. The prototype selects a seeded permutation of the four symbols. A demonstration presents the sequence, then the survivor submits inputs. A wrong valid symbol resets the current attempt; an out-of-range or unrelated input must not mutate the trial. Completion banks a seal once.

Production versions can translate glyphs into gestures—step, crouch, raise a hand, and turn—while keeping equivalent remappable input actions. The initial pattern uses four steps; harder variants add length only after teaching the vocabulary. A replay request is allowed with a modest time cost rather than forcing a player to guess. The standard demonstration window must be readable without relying on sound.

The production Eye may introduce a clearly framed decoy echo between real steps or activate a nearby hazard that forces the player to abandon an attempt. Decoy echoes are not implemented in the prototype. A true production cue always uses the Registrar's frame and stable timing; a decoy has a learnable difference. The Eye cannot change an accepted sequence while it is being entered. No final build should call a physically impossible timing window “memory difficulty.”

Team variants distribute two portions of the sequence among observers, who can communicate through pings. Solo uses a complete demonstration. Failure gives a brief recovery interval and restarts the current attempt, not the entire match. Completed progress remains permanent.

**Unreal hookup:** `BP_Trial_Echoes` holds seed, sequence, input index, demonstration state, and attempt number. Accepted inputs are validated in order; cosmetic cues derive from that state.

**Acceptance:** identical seeds reproduce the same sequence; an incorrect fourth input cannot accidentally complete; repeated completion requests are idempotent; accessibility settings retain both timing and information.

## T06 — Bridge of Illusions

**Status / realm:** planned; Void of Despair. **Skill:** evidence-based route selection. **Goal:** cross three banks of floating tiles and lock a return bridge.

Each bank offers several routes, with stable and unstable tiles identified through multiple consistent clues: engraved support symbols, a delayed reflection, and a probe response. A survivor can test a tile with a reusable weight before stepping onto it. The puzzle is deduction under pressure, not a compulsory coin toss or a replica of a familiar glass-bridge scene.

The Eye may move an unoccupied future tile after a three-second announcement, but cannot change a tile once tested and committed to during that bank. Locking a checkpoint stabilizes the previous bank for the rest of the team. The baseline crossing budget is 120 seconds, with enough time to inspect at least one legal route at normal movement speed.

An unstable tile bends and cracks before collapsing. A survivor can retreat during this warning. Falling routes to a lower recovery shelf with a short alignment puzzle, then rejoins the latest checkpoint. Only an explicitly declared severe variant uses elimination after repeated falls.

Teams assign scouts, probe carriers, and route recorders. Solo practice offers the same information with fewer simultaneous platforms. The Eye can obscure a duplicate clue or create a false reflection; at least one reliable clue remains. Probes cannot be lost permanently outside the play space.

**Unreal hookup:** tile state is a finite enum with `Untested`, `Certified`, `Warning`, `Collapsed`, and `Locked` transitions. The trial owns a reachable-route proof for each bank.

**Acceptance:** every generated bank has a demonstrably safe route; certification cannot be revoked mid-step; players using reduced reflections still receive the support-symbol clue. The final bridge is a team reward rather than a punishment for those who arrived later.

## T07 — Strings of Despair

**Status / realm:** planned; Labyrinth of Shadows. **Skill:** symbolic logic and communication. **Goal:** release three suspended cages by cutting the correct support sequence.

Survivors stand on secure platforms inside hanging frames. Each frame displays four ropes with shape tags, not color alone. A nearby panel describes relations such as “the knot beside the open eye supports the empty counterweight.” The solution is generated from a small validated logic template, and the panel contains all required evidence.

Players inspect, mark, and cut ropes through deliberate interactions. A correct cut lowers the frame one stage and banks progress. An incorrect cut engages a safety catch, costs time, and exposes the frame to a telegraphed hazard. The first mistake never drops a player into unavoidable death. The baseline puzzle lasts ninety seconds with a twenty-second emergency extension available through teamwork.

The Eye can obscure one clue panel for six seconds, shake the cage to interrupt an interaction, or shorten the next safe observation window. It cannot hide all copies of the clue or alter rope identities after the player begins a cut. Survivors can relay information from a protected viewing balcony.

In a team match, three cages use complementary clue fragments. In solo practice, the panels are reachable in sequence and one cage is active at a time. A disconnected participant's cage locks safely and transfers its control to the remaining team. Successful release opens the floor route for everyone.

**Unreal hookup:** a rope puzzle asset stores the generated relation set and expected sequence; interaction requires matching rope ID and current stage. The visual rope is separate from the authoritative support state.

**Acceptance:** every puzzle has a unique explainable solution; colorblind settings preserve identification; repeated wrong cuts cannot trap the match without recovery; the final release event fires once.

## T08 — Clockwork Relay

**Status / realm:** prototype core; Twisted Carnival. **Skill:** commitment, timing and shared operation. **Goal:** charge a large mechanism until its seal locks.

The prototype uses twelve seconds of net held interaction. Progress banks at four and eight seconds. Releasing the mechanism decays unbanked progress at one twenty-fourth of full charge per second, stopping at the latest bank. This creates an incentive to stay committed while ensuring that a necessary retreat does not erase all work.

The station is physically exposed from at least one socket and sheltered from another. Survivors choose when to operate and when to move. The mechanism has a clear rotating indicator, an interaction prompt, and visible checkpoint detents. Production versions add two auxiliary handles that let teammates stabilize the wheel or open a brief covered operating window.

The Eye can threaten the prototype operator with a local hazard or a summoned shadow. The production design also proposes a bounded rewind of only unbanked progress; that power is not implemented in the prototype. It cannot remove a locked detent or close the only retreat. Rewind needs a recognizable reverse-winding cue before it applies. A production relay should offer at least one meaningful operating opportunity between consecutive interventions.

Solo practice permits sequential stabilization. A full team gains faster progress with diminishing returns, preventing six players from finishing instantly. The Engineer archetype improves efficiency but is never required. Letting go is immediate on damage, range loss, or input release; an interrupted player must not remain logically attached to the wheel.

**Unreal hookup:** `BP_Trial_ClockworkRelay` tracks validated contributors, progress, banked checkpoint, and rewind eligibility. Progress is integrated on authority and replicated as state rather than per-frame input events.

**Acceptance:** decay never crosses the bank; simultaneous contributors respect the cap; completion is permanent; a disconnected operator is removed; the moving wheel's visuals match actual progress.

## T09 — Glass Symphony

**Status / realm:** planned; Twisted Carnival. **Skill:** reading waves and selecting cover. **Goal:** cross a resonant gallery and silence its emitter.

The gallery contains three distinct panel types: solid acoustic shields, brittle screens, and open frames. Their edges, supports, and engraved symbols identify them even without reflections. Sound waves travel as visible expanding bands. Players move between shields, crouch behind low barriers, and avoid brittle panels that turn into hazardous fragments after a warning.

The first wave is harmless and demonstrates the rule. Later waves arrive at predictable intervals that the Eye can adjust within a visible range. A baseline crossing takes ninety seconds. Midway, a survivor can lock a service shutter that creates a permanent checkpoint. Reaching the far console disables the emitter and opens a safe route for remaining teammates.

The Eye can select one of two emitters, arm a brittle panel, or create a misleading reflected wave. The real wave has a consistent edge pattern and sound caption. It cannot arrive through a shield designated as solid unless that shield visibly enters a destruction sequence first.

A failed cover choice causes bounded damage and pushes the survivor toward a safe pocket, rather than through another active hazard. Broken panels remain broken, making the route easier to understand over time. Team mode lets one survivor operate shutters while others advance. Solo uses timed latches that remain open long enough for one person.

**Unreal hookup:** wave actors evaluate shield occlusion using gameplay geometry; glass components expose explicit acoustic states. Cosmetic shards are non-damaging unless a marked fragment zone is active.

**Acceptance:** low graphics quality preserves wave fronts and panel types; standing behind a valid shield reliably works; physical debris cannot block the only route; the final emitter shutdown is authoritative and permanent.

## T10 — The Ritual Circle

**Status / realm:** planned; Dollhouse. **Skill:** sequencing and defensive movement. **Goal:** light five ritual vessels in the correct relation and hold the final circle.

The vessels sit around a central table, each bearing a shape and a short inscription. The instructions define a sequence through relationships rather than vague trial and error. Players can inspect a complete reference tablet before starting. Each correct pair locks into a stable partial pattern; the Eye cannot erase a locked pair.

Lighting a vessel requires a short interaction with a shared ember. Carrying the ember exposes its holder through a warm glow but does not prevent movement. The baseline ritual lasts 120 seconds. After the final vessel, the team occupies a marked safe ring for eight seconds while phantoms approach from announced entrances.

The Eye can extinguish one unbanked vessel, rotate an outer barrier, or call a phantom. It cannot change the meaning of the inscriptions after the attempt begins. Survivors counter by splitting reading and carrying roles, banking pairs quickly, or using the central table as cover. A wrong vessel causes a local smoke pulse and returns the ember to the last banked state.

Solo practice reduces the final hold to a single controllable lane and lets the ember rest safely in a cradle. Team mode uses multiple safe positions, so body blocking does not decide the result. Completion weakens the Eye briefly through reduced energy regeneration and awards a permanent seal; the exact debuff is shown to both sides.

**Unreal hookup:** a sequence controller manages vessel state, ember ownership, locked pairs, and final occupancy. The hold begins only after all required vessels are valid.

**Acceptance:** the puzzle is solvable from its written clues; extinguishing never touches banked progress; the ember recovers if dropped outside bounds; multiple players cannot light the same vessel twice in one step.

## T11 — The Tower of Babel

**Status / realm:** planned; Dollhouse. **Skill:** construction and load planning. **Goal:** build a stable access tower to reach an elevated seal press.

The arena supplies a finite set of clearly marked structural blocks: bases, braces, platforms, and ladders. Pieces snap to approved sockets when placement is valid. A preview shows support and remaining load capacity before commitment. The tower is a construction puzzle with bounded physics, not a pile of uncontrolled rigid bodies that may explode under network correction.

Three height bands form checkpoints. Once a band is properly braced, it cannot be completely destroyed. The baseline build lasts 180 seconds. Players retrieve pieces from storage lanes, choose an arrangement, and operate a test lever. A failed test highlights the unsupported connection rather than collapsing the entire structure without explanation.

The Eye can shake an unbraced upper section, lock one storage lane briefly, or mark a damaged component for replacement. A three-second warning gives builders time to step onto a stable band. The Eye cannot remove the last available piece required for a valid solution. Survivors can over-brace for safety at the cost of extra travel, or take a lighter route with more exposure.

Team mode distributes carrying and assembly. Solo uses lighter pieces and an automatic temporary clamp. Falling from a work platform lands on a recovery mat or lower locked band. All pieces outside the build bounds return to storage. Completion opens a permanent ladder for everyone.

**Unreal hookup:** construction slots store occupancy and dependency IDs; a support-graph validator approves placement and checkpoint locking. Visual physics is cosmetic after snapping.

**Acceptance:** at least two valid assemblies exist; required pieces cannot be lost; an Eye shake never removes locked support; a player standing inside a preview volume blocks placement safely. Cooperation is about planning a structure, not exploiting collision.

## T12 — Mirrors of Deceit

**Status / realm:** planned; Twisted Carnival. **Skill:** comparison and controlled observation. **Goal:** identify three true passages through a mirror gallery.

The gallery contains repeated alcoves whose reflections disagree in specific, learnable ways. A true passage reflects an engraved symbol with the correct orientation and preserves a small survivor-authored scratch. False surfaces omit one of these facts. The clues are available in texture and geometry, so advanced real-time reflections are presentation rather than a gameplay requirement.

Players inspect a mirror, mark their conclusion, and activate its frame. A correct choice opens a physical passage and banks that stage. A wrong choice releases a short-lived reflection phantom with a visible spawn warning, then resets only the current stage. The baseline route lasts 120 seconds.

The Eye can animate a reflection out of sync, shatter a nonessential mirror, or place a decoy silhouette in a future alcove. It cannot change a mirror's certified state after a player commits. The real player avatar and the phantom have a distinct edge treatment and audio cue at close range. A deliberate inspection interaction can confirm the difference without requiring perfect eyesight.

Team mode gives each branch a complementary clue. Solo practice places both clues within one safe alcove. Players who disable reflective effects see an equivalent etched display. Shattered glass is placed along edges and cannot randomly create invisible collision in the path.

**Unreal hookup:** each mirror holds a puzzle-state record and clue variant; reflection rendering reads that record. The authoritative solution never depends on a client screen-space reflection result.

**Acceptance:** every correct choice can be explained through two clues; reduced graphics preserve the puzzle; phantoms expire; no branch creates an irreversible softlock. The challenge tests interpretation rather than memorizing a random left/right sequence.

## T13 — The Abyss Walk

**Status / realm:** planned; Void of Despair. **Skill:** pacing and environmental timing. **Goal:** cross a suspended causeway and secure three stabilizers.

The causeway alternates broad rest platforms with narrower beams. Wind indicators, hanging ribbons, and a visible gust meter show the next force direction. The controller offers a deliberate brace action that slows movement and reduces wind influence. Balance is handled through predictable movement modifiers, not random camera jolts or hidden directional input reversals.

Each stabilizer calms the section behind it and provides a recovery checkpoint. The baseline crossing lasts 120 seconds. Missing segments require a clearly signposted jump or a deployable bridge plank; the standard route supports both choices. Players can wait for a lull, but the Eye may use that delay to reposition.

The Eye can select the next gust direction within the announced cycle or activate a brief visual illusion beside the route. It cannot change wind direction during the commitment window after the warning ends. A legal gust must leave a viable brace or shelter response. Survivors counter by moving in short stages and sending one person ahead to operate a windbreak.

Falling leads to a lower shelf with a return ladder and a small time cost. Repeated severe-mode falls may consume strikes. Solo practice automatically latches windbreaks; team mode lets a partner hold them for longer. Collision assists at the beam edge are consistent and disclosed in settings.

**Unreal hookup:** section volumes apply bounded lateral force from an authoritative gust schedule; stabilizers update the safe-section set. The camera's motion intensity is independent of force.

**Acceptance:** every gust is survivable at its warning point; frame rate does not change displacement; the low-motion setting preserves danger information; a fall returns to a valid checkpoint without overlapping another actor.

## T14 — Warden’s Chains

**Status / realm:** planned; Labyrinth of Shadows and Dollhouse. **Skill:** coordination around a shared constraint. **Goal:** move a chained anchor carriage through three locks.

Survivors are linked to an anchor carriage by individual chains. The carriage moves only when the group activates controls in a compatible order. Chain reach is visible on the floor and through tension indicators. Players can temporarily pin their chain to a socket to free another person to reach a control. The trial therefore becomes a spatial allocation puzzle rather than a forced synchronized march.

The baseline sequence lasts 150 seconds. Each lock banks a new carriage position and grants a regroup interval. Controls are arranged so that the minimum supported team can solve the pattern. Extra players receive optional stabilizing or scouting jobs instead of making the puzzle harder through overcrowding.

The Eye can energize a single chain after a clear warning, briefly reduce its slack, or open a hazard lane near the next control. It cannot pull players through walls or combine chain tension with an unavoidable damage volume. A survivor counters by moving toward the anchor, pinning their chain, or asking a partner to release a latch.

Failure engages the carriage brake and resets only the current lock. An emergency release prevents a disconnected or incapacitated participant from trapping the others. Solo practice uses two remote counterweight controls with generous latches. Completion breaks the chains and opens the final gate.

**Unreal hookup:** a shared constraint controller stores carriage checkpoint, participant endpoints, pins, and lock state. Apply movement limits through controlled character logic; cosmetic chain segments follow afterward.

**Acceptance:** an odd-sized group remains solvable; disconnected endpoints release safely; chains cannot generate infinite force; all mandatory controls are reachable under at least one valid pin arrangement.

## T15 — The Marionette’s Dance

**Status / realm:** planned; Twisted Carnival. **Skill:** rhythm, recognition and restraint. **Goal:** perform three short action phrases on a puppet stage.

The stage has four clearly named actions represented by silhouettes and symbols. Each phrase is demonstrated, then performed on a broad timing band. Real instructions appear inside the Registrar's rectangular frame; false instructions have a visibly broken frame and never replace the real cue. The game teaches this distinction through a harmless practice phrase before scoring begins.

A phrase contains three to five actions and lasts roughly fifteen seconds. Three successful phrases complete the trial. The baseline total budget is ninety seconds, including retries. A missed action increases string tension and narrows movement temporarily. Tension decays at the end of a phrase or when a teammate operates a release lever. It does not steal control indefinitely.

The Eye can add a false cue, change the next phrase's tempo within a displayed range, or activate a sweeping stage hazard between phrases. It cannot accelerate a phrase after the player has begun responding. Players counter by following the consistent frame and using the practice beat rather than reacting to every sound.

Team mode allows complementary actions across two stage lanes; solo uses one lane. Audio timing is duplicated by a visual pulse and optional controller vibration. Players can choose a wider timing window in practice without changing the information pattern. Failure restarts the current phrase, preserving previous phrases.

**Unreal hookup:** a phrase asset holds timestamped action IDs, timing tolerance, and cue authenticity. Authoritative scoring uses input timestamps within bounded tolerance; animation follows accepted state.

**Acceptance:** audio-disabled play remains complete; fake cues are distinguishable; timing does not drift with frame rate; repeated input cannot score multiple actions. The puppet fiction supports original rhythm mechanics rather than copying a named elimination game.

## T16 — The Clock Room

**Status / realm:** planned; Labyrinth of Shadows. **Skill:** linked-system reasoning. **Goal:** align three clock hands to a target constellation.

The floor contains a large clock with three hand controls. Turning one hand also moves another through a visible gear ratio. A diagram shows the relationship, and a safe test console lets players preview one step. The target is a symbol constellation rather than an arbitrary real-world time, avoiding ambiguity about twelve-hour notation.

The puzzle is generated from a small set of verified solvable states. Players can reverse a move, reset the current attempt, or ask a teammate to hold a clutch. The baseline solve budget is 150 seconds. Each correctly aligned hand can be temporarily latched, but the final seal requires all three aligned together. A midpoint checkpoint preserves one solved relationship.

The Eye can obscure a duplicate diagram, engage a known gear offset after an announcement, or activate a floor hazard at a marked hour sector. It cannot alter the target after the attempt starts. Hazard sectors have at least one safe route to the controls, and moving clock hands cannot silently crush players against walls.

Solo practice uses persistent clutches; team mode requires brief overlapping operation for an efficient solution. Failure costs time or a bounded health penalty from a hazard, not the loss of solved seals elsewhere. Completing the constellation stops the room and creates a safe shortcut.

**Unreal hookup:** a discrete state machine stores hand indices and gear transformations. Use integer steps for puzzle logic; smooth hand motion is presentation. A solver validates every generated start-target pair.

**Acceptance:** every seed is solvable within the available move budget; reverse controls behave consistently; diagrams match actual ratios; the Eye's offset cannot create an unreachable state. The intellectual challenge remains understandable under pressure.

## T17 — Chimes of Doom

**Status / realm:** planned; Twisted Carnival. **Skill:** sequence learning and sound management. **Goal:** ring four marked bells in the required order while controlling their noise consequences.

Each bell has a unique shape, numeral, pitch, and strike animation. A demonstration plays the sequence and displays the corresponding symbols. Ringing the correct bell advances a visible score. Ringing a wrong bell resets only the current phrase and emits a loud noise event that attracts a sound-sensitive minion after its spawn warning.

The room provides shutters that can damp one bell's sound at a time. Teams decide whether to spend time dampening a bell or accept the pursuit risk. Two phrases complete the trial, with a baseline budget of 120 seconds. The first phrase is a checkpoint; it cannot be erased by a mistake in the second.

The Eye can move an unoccupied bell carriage along a visible rail between phrases, silence an optional audio preview, or place a phantom near the direct route. It cannot swap bell identities during a phrase. Captions and symbols always preserve the sequence, so hearing is helpful but not mandatory.

Solo practice provides automatic shutters and a slower minion. Team mode lets a runner lure the minion while another player rings. A minion responds to actual noise events and loses track when no new sound is heard; it does not know the carrier's hidden position. Failure gives a short refuge interval before the next attempt.

**Unreal hookup:** bell actors publish stable IDs and noise events; the trial controller accepts sequence inputs; minion perception consumes the same event stream as other systems.

**Acceptance:** bell pitch is not the only identifier; wrong inputs do not spawn beyond the population cap; a moved bell retains its ID; a completed phrase remains banked. The trial combines communication and route control rather than pure musical recall.

## T18 — The Spiral Stairs

**Status / realm:** planned; Void of Despair. **Skill:** traversal under changing orientation. **Goal:** ascend three stair segments and lock the upper observatory.

The staircase winds around a central column with broad landing platforms. Individual steps can retract only during announced cycles, and a visible rail shows the next safe timing. Each landing is a checkpoint. The standard route is climbable without precision bunny-hopping; optional shortcuts reward confident timing.

The source's gravity reversal becomes a controlled set piece on a dedicated transition landing. The player stands inside a safety frame while the world and movement orientation rotate over several seconds. A reduced-motion option keeps the camera level and rotates the environment presentation. No reversal occurs during an uncontrolled jump.

The baseline ascent lasts 150 seconds. The Eye can choose which future segment cycles next, accelerate a step pattern within its published limit, or close an optional shortcut. It cannot retract every route simultaneously. Survivors can lock a segment briefly by operating a landing lever, allowing slower teammates to catch up.

A fall lands on the previous landing or a recovery spiral and consumes time. Repeated severe-mode falls may consume a strike. Solo practice gives each lever a long latch. Team mode allows one survivor to operate while others ascend, with a final latch for the operator's own passage. Completion stabilizes the entire staircase.

**Unreal hookup:** stair segments use authored motion curves and occupancy-safe transition states. Checkpoint and gravity orientation are authoritative; camera easing is local.

**Acceptance:** every retract cycle has a walkable opportunity; no player is trapped below a lever they must hold themselves; orientation transitions preserve input meaning; recovery never places a body inside moving steps. Visual spectacle must follow a reliable traversal model.

## T19 — Strings of Time

**Status / realm:** planned; Void of Despair. **Skill:** route planning and temporary obstacle removal. **Goal:** carry a time vessel through a field of delay threads before its charge expires.

The source describes threads that both increase a countdown and slow players. This design resolves that ambiguity: touching a thread adds **time debt**, reducing the remaining escape allowance, while briefly slowing the carrier. The HUD states the cost before entry. Beneficial time threads, if introduced in a variant, use a separate shape and are never visually interchangeable.

Threads are anchored to visible posts and form traversable patterns with at least one safe route. A reusable cutter can sever a marked anchor for a limited window. The baseline run begins with ninety seconds of charge, and each checkpoint restores a small fixed amount. Thread contact costs a bounded amount with a per-thread immunity interval, preventing frame-by-frame depletion.

The Eye can extend one unoccupied thread after a two-second warning or restore a severed anchor after its protected window ends. It cannot spawn a thread directly through the carrier or remove every legal route. Survivors counter by sending cutters ahead, choosing longer clear paths, or accepting one known debt to avoid greater exposure.

Solo practice gives the carrier a cutter; team mode separates carrying and clearing efficiently without requiring a specific character. If charge reaches zero, the vessel returns to the latest checkpoint and the team pays a match-time penalty. Completion locks a permanent bridge.

**Unreal hookup:** anchors define collision segments and debt events; the vessel owns its timer and checkpoint. Debt is applied on valid entry, not continuous overlap.

**Acceptance:** debt cannot be charged twice for one contact; every pattern is traversable; restored threads respect the warning; UI language consistently distinguishes remaining time from accumulated debt.

## T20 — The Gauntlet

**Status / realm:** planned; Labyrinth of Shadows. **Skill:** applying several learned rules in sequence. **Goal:** pass three connected hazard rooms and open the service exit.

The first room uses timed beam grids, the second uses pressure tiles, and the third uses sweeping mechanical arms. Each room teaches its hazard in a safe vestibule and has a checkpoint door afterward. The sequence combines previously learned verbs; it should not introduce an unexplained new lethal rule in the final room.

The baseline gauntlet lasts 180 seconds. Beam grids have visible emitter states and a safe waiting pocket. Pressure tiles hold a gate with a delayed latch so that the last operator can pass. Mechanical arms have marked sweep lanes and either a jump or crouch solution depending on height. A reduced-dexterity practice variant widens timing windows while preserving order.

The Eye can accelerate one room's cycle, lock an optional bypass, or activate a secondary hazard after a warning. A concurrency budget prevents two incompatible hazards from removing all safe positions. The Eye cannot close a checkpoint door on a body or reset a cleared room for survivors still behind it.

Failure returns the player to the current room's vestibule with a health or time cost. Teams can coordinate plates and call cycles; solo uses timed latches. A survivor who reaches the final control opens a safe maintenance lane for remaining teammates, making a skilled advance useful to the group.

**Unreal hookup:** a parent trial coordinates three child room controllers, each reporting ready, active, checkpoint, and failure states. Hazard combinations come from approved schedules.

**Acceptance:** each room remains independently recoverable; the last plate operator can exit; overlapping hazards always leave a declared answer; checkpoint doors reflect the actual completion state. The gauntlet is a synthesis test, not a random obstacle spam room.

## T21 — The Infernal Carousel

**Status / realm:** planned; Twisted Carnival. **Skill:** relative motion and timed interaction. **Goal:** disable three radial brakes and stop the carousel at the exit.

The carousel is a rotating ring around a fixed central refuge. Survivors ride the ring, move between radial lanes, and interact with brake consoles as they pass stable access windows. Obstacles are attached either to the rotating ring or to the stationary ceiling, with distinct support geometry so their motion is understandable.

The baseline trial lasts 120 seconds. Each disabled brake reduces the available speed range and banks progress. Direction changes always pass through a visible deceleration and pause; the Eye cannot instantly reverse momentum. A fixed horizon marker and optional reduced-motion camera help players read movement without unnecessary discomfort.

The Eye can select a speed within the current limit, activate one sweeping obstacle, or open a marked floor hatch. Survivors counter by using the central refuge, changing radial lanes, and operating consoles during the safe arc. The safe arc is long enough for a normal-speed interaction and retreat. A hazard may pressure the refuge but cannot make all ring positions unsafe simultaneously.

Falling into a hatch lands on a maintenance belt that returns to the center after a short task. Team mode allows multiple brakes to be prepared but requires separate confirmations, avoiding instant completion. Solo uses longer console windows. The final brake creates a permanent stationary bridge.

**Unreal hookup:** authoritative angular state drives the moving platform; character motion accounts for platform velocity. Brake bits constrain the speed controller, while cosmetic machinery follows.

**Acceptance:** platform motion is consistent across frame rates; a reversal cannot occur without warning; riders do not slide because of visual-only motion; the exit alignment is reachable after every legal brake order.

## T22 — Masks of Fear

**Status / realm:** planned; Dollhouse. **Skill:** matching protection to a threat and managing tradeoffs. **Goal:** retrieve three seals from phantom territories using the correct masks.

Three mask families are identified by shape, engraving, and name: the Still Face quiets movement, the Hollow Face obscures recognition, and the Lantern Face reveals concealed paths. Each counters a specific phantom behavior while imposing a stated limitation. The first chamber demonstrates the matching rule without damage.

Players exchange masks at safe cradles or with teammates. The baseline collection lasts 150 seconds. A mask's protection is a visible status with an explicit valid-threat list. It does not grant general immunity. Required clues remain readable through the mask's presentation; restricted vision is represented by a modest vignette that can be reduced while preserving the gameplay field-of-view rule through other feedback.

The Eye can corrupt one mask for a short announced interval, summon a compatible phantom at a legal anchor, or darken an optional route. It cannot corrupt every available counter to a mandatory threat. A corrupted mask shows cracks, a clear HUD label, and an expiry timer. Survivors can wait in a refuge, switch masks, or draw a phantom away.

A failed approach costs health and returns the carried seal to its pedestal. Collected seals bank at a central stand. Solo practice places all mask cradles on a connected route; team mode rewards distributing roles and exchanging equipment. Lost masks return to their cradle.

**Unreal hookup:** mask assets expose protection tags and limitations; phantom attacks validate those tags on authority. Corruption is a timed modifier, not a permanent asset mutation.

**Acceptance:** every threat has an available counter; masks cannot duplicate through exchange; corruption expires reliably; accessibility changes retain identification. The trial tests choosing a tool, not guessing which cosmetic face is secretly safe.

## T23 — The Bone Bridge

**Status / realm:** planned; Void of Despair. **Skill:** construction under rising pressure. **Goal:** build a supported bridge across a heated basin and secure its far anchor.

The “bones” are large architectural remnants with clearly marked load classes. Players place beams into fixed sockets, add braces, and choose between a short fragile span or a longer stable route. Placement previews show support requirements and capacity. A rising heat line supplies time pressure; lava is a stylized environmental hazard rather than an unexplained instant kill everywhere below the bridge.

The baseline build takes 180 seconds. Each anchored segment becomes a checkpoint and remains safe from total removal. Unbraced pieces creak and visibly bend before failure. The Eye can accelerate heat temporarily, damage one unbanked brace, or awaken a cursed piece whose distinctive markings were visible before pickup. It cannot remove the last valid structural solution.

Survivors counter by distributing weight, bracing before crossing, and using inspection stations to identify cursed material. A cursed piece can be cleaned at a time cost or used with a known risk. No required piece depends on a random hidden curse. Team mode lets carriers and builders specialize; solo makes pieces light enough for one survivor.

A fall lands on a lower service shelf while it remains above the heat line, then returns to the latest anchor. Late in the trial, clearly marked low shelves become unavailable. If the bridge fails, surviving anchored segments remain and replacement pieces appear at supply points. Completion stops the heat rise and opens the route to all teammates.

**Unreal hookup:** a bridge support graph tracks sockets, loads, braces, and anchors; heat is an authoritative timed state. Decorative fragments do not determine structural validity.

**Acceptance:** load limits are visible before crossing; no network physics impulse can destroy an anchored segment; supply remains sufficient after allowed failures; the heat schedule leaves a solvable minimum-time route.

## T24 — The Memory Vault

**Status / realm:** planned; Labyrinth of Shadows and Dollhouse. **Skill:** distributed memory and object identification. **Goal:** retrieve four objects matching a displayed ordered set.

The vault briefly displays four relics with shape, symbol, and spoken or written name. Players then enter storage aisles containing real objects and clearly distinguishable near matches. A reference replay is available at the cost of time. The task is not dependent on tiny texture differences or color alone.

Each retrieved object is placed into a numbered cradle. Correct placements lock; wrong placements reject visibly, emit a noise cue, and impose a short delay. The baseline trial lasts 120 seconds. A carried object remains inspectable, allowing players to compare it with their notes or teammate information before committing.

The Eye can temporarily cover an aisle label, move an unclaimed decoy between approved shelves, or create a phantom carrying a false copy. It cannot change the true target set after the demonstration. An accepted object cannot be replaced by a decoy. Survivors counter by assigning one item to each teammate, using pings to record symbols, and banking items individually.

Solo practice uses a shorter display set or a longer reference window. Team mode may split the initial demonstration between two windows, encouraging communication while preserving a replay option. If a carrier is downed or disconnects, the object drops to a reachable point or returns to its shelf. Wrong choices never destroy unique required items.

**Unreal hookup:** the trial stores target item IDs and slot assignments; pickup ownership and deposit validation use the shared inventory transaction path. Decoys have separate IDs even when visually similar.

**Acceptance:** all targets remain obtainable; a correct object in the wrong slot behaves consistently; repeated deposits cannot duplicate progress; reduced texture quality preserves identifiers. The vault measures practical memory, not willingness to accept an uncheckable guess.

## T25 — Whispers of the Void

**Status / realm:** planned; Void of Despair. **Skill:** evaluating conflicting information. **Goal:** choose a route through three whisper gates using reliable evidence.

At each gate, several voices offer incompatible instructions. One voice follows a rule the player can verify from a physical marker: for example, only the speaker whose bell matches the gate's engraved pattern reports the current path. Captions identify the speaker and display the same distinguishing information. The puzzle is logical testimony, not a hearing test.

Players can inspect the marker, replay a statement, and vote or directly choose a gate. A correct choice banks the stage. A wrong choice leads to a short detour with a recoverable hazard rather than immediate elimination. The baseline route lasts 150 seconds. The reliable voice changes between gates only according to a visible rule, never by arbitrary random selection.

The Eye can amplify a false speaker, create an extra decoy statement, or obscure an optional supporting marker for a bounded period. It cannot remove the primary evidence or change a route after a survivor commits. Survivors counter by comparing sources and communicating what they actually observed rather than following the loudest voice.

Team mode distributes statements among listeners but gives a shared transcript after a brief exchange window. Solo receives all statements sequentially. Spatial audio improves atmosphere but is never the sole clue. Players can mute voice performance while retaining complete text and directional markers. A final gate opens a stable bridge back to the group.

**Unreal hookup:** each gate owns a validated proposition set, evidence key, route state, and accepted decision. Voice playback is presentation linked to statement IDs; the truth table drives the actual result.

**Acceptance:** each gate has a unique evidence-supported solution; captions contain all necessary distinctions; a wrong choice remains recoverable; the Eye cannot turn the puzzle into an unsolvable contradiction. The final trial makes the game's central theme explicit: being observed is dangerous, but uncritical obedience is not the only response.

## Cross-trial scheduling

The director selects complementary pressures. Avoid scheduling three memory tasks, three precision traversal tasks, or three sound-dependent presentations in the same Classic match. Every combination needs one task that a single survivor can advance while the rest recover. Tasks sharing a unique carried item cannot be active simultaneously unless the item can be duplicated through an explicit rule.

Trial timers pause only for declared state transitions, never merely because the Eye changes socket. An optional local trial deadline may impose a recoverable failure while the global match deadline continues. The UI distinguishes those timers by label and location. Completing a trial immediately clears its remaining damaging subevents unless an already announced effect is explicitly part of the completion animation and remains avoidable.

The content acceptance sheet for each trial records supported population, required verbs, average completion time, first-attempt success, recovery success, Eye intervention frequency, accessibility coverage, and known collision risks. A trial enters the production random pool only after both a survivor group and an Eye player can explain its rules from the game itself.
