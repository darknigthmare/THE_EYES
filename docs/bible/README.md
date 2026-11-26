# THE EYES — Game Bible

**Design version:** 0.1 · **Date:** 26 November 2026 · **Language:** English · **Owner:** Darknigthmare

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

The structured companion is [design_catalog.json](../../data/design_catalog.json). It identifies every trial, realm, character, archetype, and high-level status. Narrative detail remains in these chapters. Actual executable tuning lives in the Godot implementation; proposed production tuning in this bible must not silently override tested code.

## What this delivery means

The local Godot slice is **The First Observance**: one encounter built around three seals, a giant Eye, four fixed observation sockets, and an exit. Its playable roles are a survivor against an AI Eye, and the Eye against four AI survivors. The three implemented trial families are **The Silent Countdown**, **Trial of the Echoes**, and **Clockwork Relay**. The prototype uses original procedural presentation. Read [the play guide](../PLAY.md) and the repository's verification report for the exact controls, tested features and known limitations.

The production design targets **five to seven survivors against one Eye**, with human or AI control. Online sessions, the complete twenty-five-trial pool, all four realm campaigns, full character art, progression services, and cross-platform play are future work. Blueprint specifications and project scaffolding are not compiled Unreal gameplay assets.

## Design authority and terminology

Use **Eye** for the active antagonist and **Eyes** for the larger fictional institution. A **socket** is a fixed point the Eye may occupy; a **gaze** is its current visible aim; a **seal** is permanent team progress; a **trial** earns a seal; a **punishment** is a short recovery challenge; a **minion** acts inside the space on behalf of the Eye. A **realm** is a themed map family. An **observance** is one match.

Parameters described as **production baseline** are starting hypotheses, subject to measured playtests. Numbers are deliberately concrete enough to implement and compare, but are not presented as proven balance. The most important invariants survive tuning: visible rules, truthful completed progress, no mandatory sacrifice without an alternative, no unavoidable damage chain, and an escape route that remains physically connected.

When changes conflict, resolve them in this order: user brief and explicit user decisions; verified playable behavior for the current release; this bible's invariants; production tuning proposals; cosmetic convenience. Record the resolution in the source traceability chapter and release notes. This prevents the design from growing into a list of incompatible promises.
