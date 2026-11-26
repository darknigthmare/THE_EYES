# THE EYES — Game Bible

**Design version:** 0.5 · **Created:** 26 November 2026 · **Language:** English · **Owner:** Darknigthmare

**A room can hunt you even when its monster cannot move.** THE EYES is an original asymmetric nightmare game about observation, coordinated trials, and escape. A team of survivors breaks the seals of a hostile ritual theatre while an enormous, physically immobile Eye occupies fixed sockets, studies movement, and commands the machinery through its gaze.

This bible turns the supplied concept and all twenty-five proposed games into a consistent production design. It is a specification, not a claim that every listed feature already exists. The Godot prototype implements the central encounter; Unreal Engine 5, using Blueprints for gameplay, is the production destination.

## Reading order

| Chapter | Purpose |
|---|---|
| [01 — Vision and fiction](01_VISION_AND_FICTION.md) | Product promise, identity, world, narrative rules, tone and boundaries |
| [02 — Match and survival](02_MATCH_AND_SURVIVAL.md) | Complete match state machine, movement, damage, rescue, objectives and fairness |
| [03 — Survivors](03_SURVIVORS.md) | Eight original characters, four archetypes, ability rules and readable silhouettes |
| [04 — The Eye](04_THE_EYE.md) | Fixed vantage points, visibility, attention economy, powers, AI and counterplay |
| [05 — Realms and level design](05_REALMS_AND_LEVEL_DESIGN.md) | Four realms, connected layouts, socket placement, props and traversal rules |
| [06 — Trial catalogue](06_TRIAL_CATALOGUE.md) | All twenty-five trials, including rules, layout, warnings, recovery and implementation seams |
| [07 — Objects and enemies](07_OBJECTS_AND_ENEMIES.md) | Items, interactive props, traps, punishment spaces and minions |
| [08 — Presentation and accessibility](08_PRESENTATION_AND_ACCESSIBILITY.md) | Art, animation, effects, sound, interface, communication and accessibility |
| [09 — Modes and progression](09_MODES_AND_PROGRESSION.md) | Classic, Endless, Custom, practice, progression and social systems |
| [10 — Production and acceptance](10_PRODUCTION_AND_ACCEPTANCE.md) | Delivery phases, content status, test scenarios, budgets, risks and release gates |
| [11 — Source traceability](11_SOURCE_TRACEABILITY.md) | Mapping from the attached brief to this design, including deliberately clarified rules |
| [12 — Prototype contracts](12_PROTOTYPE_CONTRACTS.md) | Exact First, Second and Seeded Mix scope; physical v0.2 trial subsets and verification boundaries |
| [13 — Squad and rescue](13_SQUAD_AND_RESCUE.md) | The Survivor Accord: implemented local five-survivor team, orders, recovery, support and acceptance gates |
| [14 — The Third Observance](14_THIRD_OBSERVANCE.md) | Nine-trial pool, refuge charge, evidence-based rope cuts, physical bell phrases and 27 Mix layouts |
| [15 — The Trial Workshop](15_TRIAL_WORKSHOP.md) | Nine single-trial practice lessons, physical completion, retry flow, Field Manual and separate per-archetype records |

The structured companion is [design_catalog.json](../../data/design_catalog.json). It identifies every trial, realm, character, archetype, and high-level status. Narrative detail remains in these chapters. Actual executable tuning lives in the Godot implementation; proposed production tuning in this bible must not silently override tested code.

## What this delivery means

The published v0.1 local Godot slice implements **The Silent Countdown**, **Trial of the Echoes**, and **Clockwork Relay** in one observatory. Its roles are a survivor against an AI Eye, and the Eye against four AI survivors. The **v0.2 Godot implementation** adds physical subsets of **The Memory Vault**, **The Ritual Circle**, and **The Clock Room** as alternate apparatus in the same three bays. First, Second, and Seeded Mix contracts always require three seals; six trials are available to the contract selector, not six simultaneous mandatory objectives. See [the exact implemented scope and verification evidence](12_PROTOTYPE_CONTRACTS.md). Domain checks, physical bot routes through all eight mixed combinations, and a complete Second survivor route against the active Story Eye have passed. Native Windows headless startup has passed for both roles under all three contracts. Graphical Windows playthrough and Unreal gameplay remain unverified.

The published **v0.3, The Survivor Accord**, adds a local Squad session: one human survivor and four AI allies against the AI Eye. It introduces Work/Follow/Hold orders, one physical ally-assisted revival per actor, a team roster and ally spectating. The life domain and physical world fixtures have passed, as have three complete Story/Keeper Squad sessions and native-renderer inspection. The combined six assertion suites report 121 cases and 2,774 assertions with zero failures. The official v0.3 Windows archive has also passed all nine native headless startup cases: Solo, Eye and Squad under First, Second and Mix. Graphical Windows playthrough remains unverified. It preserves the existing six trials and adds no arena or networking. See [Squad and rescue](13_SQUAD_AND_RESCUE.md).

**Version 0.4 — The Third Observance** adds the implemented observatory subsets of **T04 Light in the Darkness**, **T07 Strings of Despair**, and **T17 Chimes of Doom**. Four contracts are available: First, Second, Third and Seeded Mix. Mix now chooses among three trials per bay for 27 configurations; its old seed-to-layout mapping changes, while First/Second puzzle streams remain independent. Current verification and publication status are recorded in the [v0.4 report](../qa/V0_4_VERIFICATION.md). The detailed rules and production limits appear in [chapter 14](14_THIRD_OBSERVANCE.md).

**Version 0.5 — The Trial Workshop** adds a separate single-player learning session for any one of the nine implemented trials. Choose a trial, archetype and seed, complete the same physical apparatus without an Eye or deadline, and repeat with the same seed, another seed or the next trial. Its bounded local journal records attempts, completions and best times per archetype without changing the ordinary match ledger. F1 opens the Field Manual from play or pause; loss of application focus pauses local simulation until the player resumes. Practice earns its own completion result, while the three match modes, four contracts and 27 Mix layouts retain their rules. See [chapter 15](15_TRIAL_WORKSHOP.md), the [implementation contract](../technical/PRACTICE_IMPLEMENTATION.md) and the [v0.5 verification report](../qa/V0_5_VERIFICATION.md) for scope and actual checks.

The prototype uses original procedural presentation. Read [the play guide](../PLAY.md) and the repository's verification report for the exact controls, tested features and known limitations. The versioned paragraphs above preserve historical evidence; they are not the current release's assertion totals. Production specifications elsewhere in this bible remain broader than the implemented subsets.

The production design targets **five to seven survivors against one Eye**, with human or AI control. Online sessions, the complete twenty-five-trial pool, all four realm campaigns, full character art, progression services, and cross-platform play are future work. Blueprint specifications and project scaffolding are not compiled Unreal gameplay assets.

## Design authority and terminology

Use **Eye** for the active antagonist and **Eyes** for the larger fictional institution. A **socket** is a fixed point the Eye may occupy; a **gaze** is its current visible aim; a **seal** is permanent team progress; a **trial** earns a seal; a **punishment** is a short recovery challenge; a **minion** acts inside the space on behalf of the Eye. A **realm** is a themed map family. An **observance** is one match.

Parameters described as **production baseline** are starting hypotheses, subject to measured playtests. Numbers are deliberately concrete enough to implement and compare, but are not presented as proven balance. The most important invariants survive tuning: visible rules, truthful completed progress, no mandatory sacrifice without an alternative, no unavoidable damage chain, and an escape route that remains physically connected.

When changes conflict, resolve them in this order: user brief and explicit user decisions; verified playable behavior for the current release; this bible's invariants; production tuning proposals; cosmetic convenience. Record the resolution in the source traceability chapter and release notes. This prevents the design from growing into a list of incompatible promises.
