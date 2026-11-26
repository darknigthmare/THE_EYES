# 05 — Realms and level design

## Spatial contract

The nightmare may change shape, but every playable layout is a physical, connected place. A door sits inside a wall opening and leads to an authored destination. Stairs have landings. Service corridors explain how machinery is reached. A socket has structural support and a sight line that matches its visible aperture. Props have a reason to occupy their location and cannot accidentally block the only escape route.

Each realm is built from a receiving area, a central orientation space, three or more trial wings, at least one return loop, punishment chambers, socket infrastructure, and an exit route. The graph is verified before a seed becomes playable. Dynamic changes modify approved links; they never produce a state in which an active objective and all survivors lie in different permanently disconnected components.

## Common layout metrics

Production metrics begin with 2.4-meter clear doorways, 3-meter secondary corridors, and wider shared interaction areas. The exact controller capsule determines final values. Cover should allow a crouched survivor to break the relevant sight samples while leaving readable edges. A trial interaction needs standing space, a retreat direction, and room for another survivor to pass. Essential prompts are visible before the player enters the danger footprint.

Every mandatory interaction has a navigation solution that does not require exploiting physics. Jumps on the critical path use generous landing surfaces and test with the slowest supported movement state. If a mode demands precise platforming, the route includes checkpoints and an accessible alternative rule set. Camera collision is checked around low ceilings, large props, and tether endpoints.

## The First Observance — prototype arena

The Godot slice is one compact ritual-industrial arena rather than a claim that the four final realms are complete. It contains three seal stations, delivery objects, traversable cover, hazard lanes, four sockets, and a visible exit. The three stations establish different attention costs: a carrier must move through exposed space, a memorizer must concentrate near a terminal, and an operator must commit time to a mechanism.

The layout should make each station identifiable from silhouette and sign: a receiving basin for Silent Countdown, four numbered or shaped glyphs for Echoes, and a large wheel for Clockwork Relay. Navigation lights guide the player back to the central spine. A successful release captures the actual running arena and annotates its implemented routes; concept art is never substituted for gameplay evidence.

The initial prototype arena occupies approximately 54 by 48 meters, with north, east, south, and west sockets at eight meters high. Its three mote placements are around `(−21, 9)`, `(20, 9)`, and `(14, −3)` in the horizontal X/Z plane. These are implementation coordinates for this slice, not universal metrics for the four production realms. They should be rechecked against the scene when geometry changes.

## Realm 01 — Twisted Carnival

**Theme:** performance without celebration. The realm is a derelict fairground enclosed inside a theatre too large to have an exterior. Canvas awnings hang beneath concrete vaults. Ticket booths count people rather than admissions. Attraction music slows when the Eye turns away, suggesting that attention powers the performance.

**Topology:** the receiving wagon opens onto the Parade Court. West leads through the Bell Arcade to the Carousel Pit; east leads through the Mirror Gallery to the Rigging Hall. Both wings reconnect through a backstage service ring. The exit is a shuttered audience tunnel beyond the Court, opened by seals. A punishment lift returns failed players to the backstage ring, preserving reentry without crossing the same active hazard.

**Trial pool:** The Infernal Carousel, The Marionette's Dance, Chimes of Doom, Mirrors of Deceit, Glass Symphony, Clockwork Relay. A production seed selects a compatible set and avoids stacking three sound-critical challenges. The tower attraction can host The Tower of Babel in a later map variation.

**Sockets:** the main proscenium covers the Court but not backstage; a ticket crown covers Bell Arcade; a broken moon overlooks the Carousel; a mirror organ watches the Gallery from a narrow angle. Each socket has a recognizable arrival sound. The backstage ring contains intermittent cover, not permanent immunity.

**Props and materials:** cracked enamel signs, weighted curtains, brass rails, winches, folded benches, mechanical music drums, ticket spindles, lanterns, and inspection hatches. Human-scale service equipment grounds the oversized attractions. Avoid iconic costumes or recognizable attraction designs from existing franchises; the horror comes from this institution's own visual grammar.

**Map-specific danger:** rotating floors and moving rigging. All rotations preserve a stable reference marker. Reversals have a brake phase before changing direction. Decorative ropes are visually distinct from interactable tethers. A player can learn the architecture after one match even when the selected trials vary.

## Realm 02 — Labyrinth of Shadows

**Theme:** authority expressed as impossible administration. Tall archive shelves, numbered doors, inspection windows, and matte stone corridors form a system that appears rational until its numbering contradicts itself. The realm's uncertainty concerns route interpretation, not collision unpredictability.

**Topology:** the Intake Hall leads to a central Index Rotunda. Three wings—Records, Transit, and Audit—form separate loops around it. Sliding partitions change which loop offers the shortest route, while a protected maintenance spine remains connected. The exit is an unnumbered stair behind the Rotunda. Trial completion unlocks its three mechanical shutters.

**Trial pool:** The Labyrinth of Shadows, The Silent Countdown, The Memory Vault, Warden's Chains, Strings of Despair, The Gauntlet. Moving-wall states are authored and validated, not unrestricted random mazes generated during active play. A partition pauses if a body occupies its crush volume and the trial does not explicitly provide a warning and escape margin.

**Sockets:** a central index eye can see the Rotunda and one doorway at a time; corridor sockets have long but narrow view cones; an overhead Audit socket exposes a workstation but loses the adjacent crawl route. The Eye must choose between information at the center and direct intervention in a wing.

**Props and materials:** stamped metal drawers, slate instructions, perforated acoustic screens, maintenance carts, chain drums, heavy counting machines, ceramic insulators, and wall-mounted clocks with inconsistent faces. Large props repeat enough to teach cover dimensions. A broken drawer is never the only clue to a lethal choice unless its significance has already been taught.

**Map-specific danger:** controlled rerouting. Before a wall moves, floor grooves illuminate and the destination route appears on a diagram. After movement, signs update to the actual graph. A survivor carrying a required object can always reach a valid deposit point, even if the shortest path changes.

## Realm 03 — Dollhouse

**Theme:** care distorted into ownership. Rooms resemble a home built for inhabitants several times human size. Furniture is monumental, fabric becomes terrain, and maintenance passages run inside walls like architectural seams. Mannequins are carefully arranged to imitate family rituals without understanding them.

**Topology:** survivors arrive beneath an enormous dining table. The Hearth Junction links the Nursery, Sewing Room, and Conservatory. Service passages under skirting boards connect the wings, with openings sized for actual player movement. A grand staircase becomes the final escape route to a door whose handle is unreachable until a platform mechanism rises.

**Trial pool:** Threads of Fate, Masks of Fear, The Ritual Circle, The Tower of Babel, Warden's Chains, The Memory Vault. The realm uses paired tasks and object manipulation, but every required task has a declared solution for an odd number of survivors. A disconnected partner is replaced by a safe anchor or bot according to session policy.

**Sockets:** the face of a grandfather clock, a painted nursery ceiling, the dark opening of a cabinet, and a decorative eye above the hearth. Their physical placement explains viewing direction. A socket behind a cabinet cannot see through its back merely because the Eye is fictionally powerful.

**Props and materials:** oversized thread reels, pin cushions, porcelain labels, felt pads, curtain weights, hollow wooden toys, mask cradles, folded blankets, and hand-cranked lifts. Small survivor-authored marks appear near safe human-scale routes. The art differentiates a climbable folded fabric ramp from decorative hanging fabric.

**Map-specific danger:** scale and linked movement. Large moving furniture has predictable rails and safety pockets. Tethers use clear tension indicators and bounded forces. Players are never dragged by a partner's network jitter into a lethal seam. The visual fiction of strings may be dramatic while collision remains stable and explainable.

## Realm 04 — Void of Despair

**Theme:** a place losing agreement about distance and memory. Platforms of black stone and pale bone float beneath a depthless sky. Distant architectural fragments suggest the other realms without reproducing their full layouts. The Eye's sockets are attached to standing rings and suspended monuments, preserving its fixed-location rule.

**Topology:** the Arrival Ring branches into three traversable causeways around a central abyss. Each causeway leads to a trial island and reconnects through lower recovery shelves. The escape path is a rising bridge whose sections lock after each seal. Visual distance may be surreal, but measured movement distances remain stable during an active crossing.

**Trial pool:** The Abyss Walk, Bridge of Illusions, The Spiral Stairs, Strings of Time, The Bone Bridge, Whispers of the Void, Light in the Darkness. A seed does not combine every precision traversal trial. One low-dexterity task and a safe regroup point provide contrast and recovery.

**Sockets:** a high ring surveys the central gap but cannot target lower shelves; lateral monoliths watch specific causeways; a low socket controls the final bridge approach but abandons distant trials. Cover includes stone fins and light screens with explicit sight-blocking behavior. Pure darkness alone is not assumed to block gaze unless the rules say it does.

**Props and materials:** fractured observatory instruments, anchor bells, bone braces, memory vessels, suspended lamps, marked safety hooks, cut thread bundles, and polished stone tablets. The environment needs strong edge readability; atmospheric fog must not erase a required landing surface.

**Map-specific danger:** falling and disorientation. Early falls route to recovery shelves or punishment rooms. The final phase may permit elimination from a clearly marked abyss, with robust ledge and camera feedback. Gravity changes use a transition platform that locks input orientation gradually and offers an accessibility variant with rotating scenery instead of rotating the camera.

## Modular kit and placement rules

Each realm kit includes straight walls, corners, T-junctions, door frames, floor strips, stairs, landings, cover heights, socket assemblies, trial plinths, punishment entrances, exit components, signage, and service props. Modules share snap dimensions. Designers place collision first, then visual dressing. A decorative variant cannot change traversal clearance without updating navigation and sight tests.

Place props in functional clusters: a winch beside the rail it operates, spare parts near a service hatch, a bell where its sound mechanism connects, and a mask stand before the hazard that requires it. Avoid filling space uniformly. Empty lanes communicate traversal and hazard footprints; dense edges communicate maintenance and concealment.

## Dynamic-map acceptance

For every approved map state, verify spawn-to-trial reachability, trial-to-exit reachability, punishment return paths, item recovery, safe standing volumes, socket visibility, and maximum objective travel time. Simulate each wall transition with occupied thresholds. Check the same routes at minimum and maximum supported player count. Reject seeds that create unreachable key items or allow the Eye to cover all mandatory work without moving.

Art review and graph review are separate gates. A visually impressive room may be mechanically unfair; a connected graph may still have nonsensical doors or unsupported platforms. Both must pass before the map is advertised as a finished realm.
