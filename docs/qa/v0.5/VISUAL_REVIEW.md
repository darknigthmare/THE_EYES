# v0.5.0 native visual review

Inspection date: 26 November 2026. Method: assistant examination of the eight unchanged PNG files produced by the native Godot renderer. This is a presentation review; it is not a human playtest.

## Provenance

- Runtime and fixture source: [6392ebf30b0acb909e218bc4c12c36e2d0b3faa0](https://github.com/darknigthmare/THE_EYES/commit/6392ebf30b0acb909e218bc4c12c36e2d0b3faa0).
- Successful source workflow: [45903325362](https://github.com/darknigthmare/THE_EYES/actions/runs/45903325362).
- Evidence recovery: [45905214108](https://github.com/darknigthmare/THE_EYES/actions/runs/45905214108), published in [1616e1c94e5535bc25c15f2908babf4287c48120](https://github.com/darknigthmare/THE_EYES/commit/1616e1c94e5535bc25c15f2908babf4287c48120).
- Godot 4.7.2; native OpenGL compatibility renderer, software Mesa and Xvfb. All eight images are 1280 × 800.
- Original visual artifact: 15157461003; 2,159,877 bytes; SHA-256 `f264597193c03d266fe5f872badd84df43a1802a0fc57caab637f6676d01389c`.

[VISUAL_PROVENANCE.json](VISUAL_PROVENANCE.json) records every PNG hash. [RECOVERY_PROVENANCE.json](RECOVERY_PROVENANCE.json) records artifact checks, original dimensions and the exact source. Its human-review flag describes collection time and is not a claim that a person has played the game.

## Observations

| Fixture | Reviewed presentation |
|---|---|
| [Menu](menu.png) | Workshop entry, survivor/contract controls and normal modes fit within the viewport. Gold primary buttons retain dark text. |
| [Workshop catalogue](workshop.png) | All nine cards and launch/navigation controls are visible. The selected drill is distinct; the instruction area scrolls within its panel. Redundant card tooltips no longer cover the instructions. |
| [Practice with guide](practice.png) | Objective text has a dark backing. The guide's H HIDE action is visible, with progress and ordinary controls retained. |
| [Practice with guide folded](practice_clear.png) | All four Strings shapes and labels are exposed. H SHOW WORKSHOP GUIDE remains visible, together with the objective, progress, vitality and controls. |
| [Field manual](manual.png) | Both columns, scroll affordance, control footer and return-to-pause button are visible. The long content scrolls within its designated area. The focused gold button keeps dark text. |
| [Completion](result.png) | Trial, archetype, seed, elapsed time and role-specific best are readable. The singular wording is correct. All five continuation actions fit within the panel. |
| [Catalogue save error](save_error.png) | SESSION ONLY / NOTEBOOK NOT SAVED and the complete explanation appear above the cards, without covering the grid or navigation. |
| [Completion save error](result_save_error.png) | A dedicated warning sits between the notebook summary and action buttons. Its full message and all five actions remain visible, with no overlap. |

No blocking overlap, truncated control or unreadable primary-button focus state was observed in these fixtures. This review closes the four issues found in the earlier captures: the obstructing guide, redundant tooltips, low-contrast focused buttons and objective text blending into the scene.

## Interpretation

The helper deliberately freezes physics, positions the camera and supplies illustrative completion/notebook state. The displayed 00:48 completion is a presentation fixture; it is not the measured ordinary-input Strings route time. Those route observations are in [GAMEPLAY_RESULTS.json](GAMEPLAY_RESULTS.json).

These screenshots establish the inspected layout at this viewport. They do not establish novice usability, all trial views and screen sizes, hardware performance, a graphical Windows playthrough or production-quality UE5 assets.
