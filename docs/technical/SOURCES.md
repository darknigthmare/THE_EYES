# Technical sources and verification scope

Reference check: **26 November 2026**. These are official primary documentation pages used to verify engine behavior. The game design, proposed values, naming, rules and milestone criteria in this repository are project decisions. No external documentation proves that a listed THE EYES feature has been implemented or tested.

Epic's pages may show different selected documentation versions, and Godot's `stable`/`latest` selectors can change. The foundation intentionally does not claim a tested UE5 release. Choose and record the exact installed UE5 version before authoring assets; recheck any version-sensitive node or setting. The Godot build's actually tested version belongs in its own validation report.

| Reference | What was verified | Use and limits |
| --- | --- | --- |
| [Epic — Game Mode and Game State](https://dev.epicgames.com/documentation/en-us/unreal-engine/game-mode-and-game-state-in-unreal-engine) | Server-only GameMode, shared GameState, server-time accessor and role of admission callbacks | Basis for authority split; project snapshot schema is original |
| [Epic — Remote Procedure Calls](https://dev.epicgames.com/documentation/en-us/unreal-engine/remote-procedure-calls-in-unreal-engine) | Actor ownership affects execution; Blueprint replicated events; reliability choices | Basis for owned-controller requests; project rate limits are proposed |
| [Epic — Enhanced Input](https://dev.epicgames.com/documentation/en-us/unreal-engine/enhanced-input-in-unreal-engine) | Input actions, value types, triggers and runtime mapping contexts | Basis for role-specific mappings; actual assets must be created |
| [Epic — Traces overview](https://dev.epicgames.com/documentation/unreal-engine/traces-in-unreal-engine---overview) | Collision traces by channel and first blocking hit | Basis for real occlusion checks; project gaze angle/target samples are design choices |
| [Epic — Data Driven Gameplay](https://dev.epicgames.com/documentation/en-us/unreal-engine/data-driven-gameplay-elements-in-unreal-engine) | Data table row schema, CSV import and stable row-name column | CSV supplied; editor Structure/DataTable assets still need creation/import validation |
| [Epic — Behavior Tree quick start](https://dev.epicgames.com/documentation/en-us/unreal-engine/behavior-tree-in-unreal-engine---quick-start-guide) | Blackboard keys, tasks, services and decorators | Project AI priorities/evidence limits are original specifications |
| [Epic — AI Perception](https://dev.epicgames.com/documentation/en-us/unreal-engine/ai-perception-in-unreal-engine) | Sensory stimulus updates and Blueprint events | Optional future sensory component; not proof of perfect occlusion or game fairness |
| [Epic — Replicating variables in Blueprints](https://dev.epicgames.com/documentation/en-us/unreal-engine/replicating-variables-in-blueprints?application_version=4.27) | Replicated/RepNotify concept and authority-authored state | Legacy example, explicitly version-qualified; confirm current editor details |
| [Epic — Saving and Loading](https://dev.epicgames.com/documentation/en-us/unreal-engine/saving-and-loading-your-game-in-unreal-engine) | SaveGame objects, async save/load and completion results | Project schema/backup policy remain implementation work |
| [Epic — Lumen performance guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-performance-guide-for-unreal-engine) | Scalability and lighting/reflection performance tradeoffs | No THE EYES hardware benchmark inferred |
| [Epic — Lumen technical details](https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-technical-details-in-unreal-engine) | Occluder/light-leak considerations, diagnostic modes, small emissive limitations | Art review guidance; exact behavior depends on selected version/settings |
| [Epic — Nanite virtualized geometry](https://dev.epicgames.com/documentation/en-us/unreal-engine/nanite-virtualized-geometry-in-unreal-engine) | Virtualized geometry and version/platform/material constraints | Feature eligibility must be checked per production asset |
| [Epic — Coordinate system and spaces](https://dev.epicgames.com/documentation/en-us/unreal-engine/coordinate-system-and-spaces-in-unreal-engine) | Left-handed, Z-up system and forward/right axes | Basis for import calibration |
| [Epic — Units of measurement](https://dev.epicgames.com/documentation/en-us/unreal-engine/units-of-measurement-in-unreal-engine) | Default distance unit is centimetres | Project source dimensions still require import verification |
| [Godot — Available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html) | glTF/GLB support and recommended interchange format | Source art/export pipeline guidance |
| [Godot — Model export considerations](https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html) | Right-handed Y-up; distinction between camera forward and model front | `latest` page: verify behavior against installed build |
| [Godot — SDFGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_sdfgi.html) | Forward+ requirement and dynamic-scene limitations | Optional future visual branch; not a claimed feature of the Compatibility prototype |
| [Godot — Command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) | Headless/script execution, project path and export command interface | Testing/export mechanism; actual run evidence must come from logs |

## Evidence categories used in this delivery

| Category | What it can establish |
| --- | --- |
| Supplied concept text | The user's intended mechanics, English/Blueprint preference and 25 source trials |
| Game source and committed data | Which rules/assets are present in this revision |
| Executed Godot test logs | The cases actually run in the installed engine |
| Captured gameplay frames | Visual output of the tested scene/build |
| Technical documentation | Planned engine architecture and implementation decisions |
| UE5 descriptor/CSV/config | A real starting scaffold and source data, not a compiled game |
| Git commit/remote branch/PR | Publication state of those exact files |

Future reports should preserve these distinctions. “Specified,” “implemented,” “imported,” “tested” and “published” describe different evidence and should not be used interchangeably.
