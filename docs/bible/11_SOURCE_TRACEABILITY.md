# 11 — Source traceability and clarified decisions

## Source

The source is the user-provided attachment **Texte collé.txt**, supplied with the request to build THE_EYES and place the detailed game bible in `darknigthmare/THE_EYES` on 26 November 2026. It contains the initial English concept, suggested Unreal Blueprint approaches, four example realms, three modes, and twenty-five named challenge ideas. This bible is an original expansion of that supplied material.

The brief's requirements are: an immobile giant Eye, AI or player control, fixed vantage-point transfers, gaze-driven actions, survivors completing objectives and escaping, nightmare settings, punishing games, original variations on broad genre inspirations, English content, and a final UE5 implementation using Blueprints. The later user request permits a Godot prototype. No final production assets, online service, or compiled Unreal gameplay are assumed to exist merely because the brief requests them.

## Requirement mapping

| Source requirement | Design location | Current interpretation |
|---|---|---|
| Immobile Eye that can look | [The Eye](04_THE_EYE.md) | Position changes only through authored sockets; aim controls legal commands |
| Eye controlled by AI or a player | [Modes](09_MODES_AND_PROGRESSION.md) | Both local role experiences selected for prototype; online control planned |
| Five-to-seven survivors | [Match rules](02_MATCH_AND_SURVIVAL.md) | Production Classic target; v0.3 local Squad has one human and four AI survivors; Eye seat retains four bots |
| Traps, marks and summoned creatures | [Eye](04_THE_EYE.md), [Objects](07_OBJECTS_AND_ENEMIES.md) | Shared costs, cooldowns, warnings, visibility and population limits |
| Terror escalation and rage | [Eye](04_THE_EYE.md) | Production escalation separated from prototype energy and escape rules |
| Objectives open an exit | [Match rules](02_MATCH_AND_SURVIVAL.md) | Three permanent seals, then a fresh escape deadline |
| Punishment zones | [Objects](07_OBJECTS_AND_ENEMIES.md) | Short recovery challenges with safe reentry; simplified human prototype recovery |
| Stealth, engineer, athlete and medic roles | [Survivors](03_SURVIVORS.md) | Veil, Tinker, Runner and Keeper, with eight original identities |
| Cooperation and betrayal | [Match rules](02_MATCH_AND_SURVIVAL.md) | Cooperative default; v0.3 implementation provides local orders and ally rescue, while betrayal/temptation remain optional production designs |
| Four nightmare realms | [Realms](05_REALMS_AND_LEVEL_DESIGN.md) | All four preserved as detailed production map families |
| Classic, Endless and Custom | [Modes](09_MODES_AND_PROGRESSION.md) | Full rules specified; local prototype modes honestly scoped |
| Bible practice proposal from chapter 09 | [Modes](09_MODES_AND_PROGRESSION.md), [The Trial Workshop](15_TRIAL_WORKSHOP.md) | v0.5 implements single-trial practice for the existing nine subsets as a prototype extension; Eye training remains planned |
| UE5 Blueprint-only English | Unreal foundation and this English bible | Gameplay architecture and implementation guide; no false claim of compiled assets |

## Challenge mapping

All titles appear in [the trial catalogue](06_TRIAL_CATALOGUE.md) and [the structured catalogue](../../data/design_catalog.json).

| ID | Source title | Prototype selection |
|---|---|---|
| T01 | The Labyrinth of Shadows | Planned |
| T02 | The Silent Countdown | Selected core trial |
| T03 | Threads of Fate | Planned |
| T04 | Light in the Darkness | v0.4 implemented observatory subset |
| T05 | Trial of the Echoes | Selected core trial |
| T06 | Bridge of Illusions | Planned |
| T07 | Strings of Despair | v0.4 implemented observatory subset |
| T08 | Clockwork Relay | Selected core trial |
| T09 | Glass Symphony | Planned |
| T10 | The Ritual Circle | v0.2 implemented physical subset |
| T11 | The Tower of Babel | Planned |
| T12 | Mirrors of Deceit | Planned |
| T13 | The Abyss Walk | Planned |
| T14 | Warden’s Chains | Planned |
| T15 | The Marionette’s Dance | Planned |
| T16 | The Clock Room | v0.2 implemented physical subset |
| T17 | Chimes of Doom | v0.4 implemented observatory subset |
| T18 | The Spiral Stairs | Planned |
| T19 | Strings of Time | Planned |
| T20 | The Gauntlet | Planned |
| T21 | The Infernal Carousel | Planned |
| T22 | Masks of Fear | Planned |
| T23 | The Bone Bridge | Planned |
| T24 | The Memory Vault | v0.2 implemented physical subset |
| T25 | Whispers of the Void | Planned |

## Deliberate clarifications

**Completed progress remains truthful.** The source permits resets and illusions of completion. This design allows interruption and unbanked regression but makes a completed seal permanent. Illusions can deceive perception in the world, while authoritative HUD completion remains reliable.

**Randomness is constrained by solvability.** Moving mazes, unstable bridges, and shifting bells use approved states. The Eye can alter future choices after a warning, but cannot retroactively invalidate a committed correct choice. This retains tension while making skill meaningful.

**Threads of Fate uses bounded shared strain.** The source's shared health could let one participant instantly destroy another's run. Shared strain preserves interdependence, while personal health and recoverable falls prevent unrestricted griefing.

**Strings of Time has one clear timer meaning.** The source describes both increasing a countdown and slowing the player. The design defines harmful threads as adding time debt, which reduces remaining allowance. Any beneficial thread must be separately named and identified.

**Audio themes do not require hearing or microphone silence.** Silent Countdown measures in-game noise. Chimes and Whispers provide visual and textual equivalents of essential information. Voice communication remains possible.

**Gravity changes are authored transitions.** The Spiral Stairs keeps the source's surreal reversal as a controlled set piece with a reduced-motion presentation. It does not reverse controls without warning during a jump.

**Doors and moving rooms obey physical layout.** The nightmare setting does not excuse doors floating without walls, unreachable objectives, or randomly disconnected exits. Each realm has a connected graph and service logic.

**The first escape wins.** The brief explicitly states that survivors win if any member escapes. The base mode retains this. Future individual-scoring or last-survivor variants must be named separately and explain their changed outcome rules before play.

## Document status

This bible is a detailed design baseline, not a record of twenty-five completed games. Implementation truth is maintained in the repository's release notes, test report, and runnable source. The machine-readable catalogue distinguishes the original v0.1 trio, the three alternate subsets implemented in v0.2, the three v0.4 observatory subsets, and sixteen remaining planned designs. The [contract chapter](12_PROTOTYPE_CONTRACTS.md) records exactly which production features are included or deferred. Expansion characters, realms, items, and minions remain planned until their actual assets and behavior pass the relevant acceptance gates.

## v0.4 source interpretation

[The Third Observance](14_THIRD_OBSERVANCE.md) implements T04/T07/T17 through connected ground-level apparatus. Portable light uses a recoverable charge budget and permanent refuges; rope clues intersect side and shape family to produce a unique explainable answer; bells require physical travel and preserve the first phrase. The full island/chill, suspended traversal, dedicated sound-minion and trial-specific Eye variants remain proposed production work. Mix expands to 27 layouts in version 0.4; a v0.3 seed can select different trials. First and Second retain independent existing puzzle streams.

## v0.5 source interpretation

[The Trial Workshop](15_TRIAL_WORKSHOP.md) develops the practice proposal already described in chapter 09 while continuing the requested playable prototype and detailed bible. It adds no source trial or new trial family. A selected existing trial uses the same physical rules, seed generation and recoverable checkpoints, under a separate session policy without an Eye or deadline.

The source's first-escape victory remains the rule for ordinary matches. Practice completes on its one selected trial and reports that completion explicitly; it does not invent two completed seals, a survivor victory or an escape. First, Second, Third and Seeded Mix remain unchanged contracts. The separate bounded journal records attempts and completions with best times per archetype. It introduces no economy, power unlocks, online ranking or replay claim.

The Field Manual and focus-loss pause address reading and attention during a local session. They do not solve future network pause semantics. Survivor/spectator FOV is named for the cameras it affects; the Eye keeps its authored fixed view. Input rebinding, gamepad support, Eye training and additional diagnostic overlays remain future implementation work. The Unreal practice table and construction guide are handoff material, not compiled Blueprint assets.
