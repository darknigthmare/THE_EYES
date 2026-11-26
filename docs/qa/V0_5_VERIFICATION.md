# v0.5.0 verification — The Trial Workshop

Date: 26 November 2026. Engine: Godot 4.7.2.stable.official.ed1daf0bf.

## Scope

Seventeen required suites cover the existing competitive game plus the practice
domain, resilient local records, interface, physical lifecycle and nine ordinary-
input completion routes. Fixtures deliberately position actors to exercise edge
cases; complete route tests use normal movement and actions without objective,
health, position, speed or clock injection.

## Gameplay evidence

Source commit: `6392ebf30b0acb909e218bc4c12c36e2d0b3faa0`. [Verified CI run](https://github.com/darknigthmare/THE_EYES/actions/runs/45903325362), attempt 1; Godot job `140194071407`.

The completed CI execution passed **17 suites, 257 cases, 6079 assertions and zero failures**. The import and gameplay gate, native fixture gate and both artifact uploads all completed successfully.

This evidence comes from that exact CI execution. It does not establish a successful local import or local test run.

| Suite | Cases | Assertions | Complete sessions | Failures |
|---|---:|---:|---:|---:|
| `test_director.gd` | 27 | 125 | — | 0 |
| `test_world.gd` | 6 | 60 | — | 0 |
| `test_survivor_route.gd` | — | — | 1 | 0 |
| `test_trial_set.gd` | 23 | 2118 | — | 0 |
| `test_second_world.gd` | 35 | 279 | — | 0 |
| `test_second_survivor_route.gd` | — | — | 1 | 0 |
| `test_squad_state.gd` | 26 | 120 | — | 0 |
| `test_squad_world.gd` | 23 | 236 | — | 0 |
| `test_squad_route.gd` | — | — | 3 | 0 |
| `test_third_trials.gd` | 31 | 1780 | — | 0 |
| `test_third_world.gd` | 23 | 162 | — | 0 |
| `test_third_survivor_route.gd` | — | — | 2 | 0 |
| `test_practice_state.gd` | 14 | 595 | — | 0 |
| `test_practice_records.gd` | 21 | 294 | — | 0 |
| `test_practice_ui.gd` | 12 | 95 | — | 0 |
| `test_practice_world.gd` | 16 | 215 | — | 0 |
| `test_practice_routes.gd` | — | — | 9 | 0 |

### Pressured session observations

| Role | Contract | Seed | Elapsed simulation seconds |
|---|---|---:|---:|
| survivor | first | 271126 | 267.93 |
| survivor | second | 271126 | 324.17 |
| squad | first | 271126 | 46.88 |
| squad | second | 271126 | 86.80 |
| squad | mix | 271126 | 46.88 |
| survivor | third | 271126 | 328.88 |
| squad | third | 271126 | 74.13 |

### Practice session observations

| Trial | Archetype | Seed | Elapsed simulation seconds |
|---|---|---:|---:|
| silent | Keeper | 271126 | 81.67 |
| echoes | Keeper | 271126 | 15.37 |
| relay | Keeper | 271126 | 12.90 |
| vault | Keeper | 271126 | 90.12 |
| ritual | Keeper | 271126 | 27.23 |
| clock | Keeper | 271126 | 5.42 |
| light | Keeper | 271126 | 32.98 |
| strings | Keeper | 271126 | 26.93 |
| chimes | Keeper | 271126 | 25.73 |

### Scope and retained evidence

- The 257 named cases and 6079 assertions come from twelve suite summaries. Some cases deliberately stage edge conditions; these are not 257 complete matches.
- Seven pressured sessions and nine practice sessions use ordinary inputs and real physics. Their elapsed values are simulation observations, not wall-clock benchmarks or novice target times.
- The 28 unopposed bot routes are already included in Second world integration cases/assertions: one Second reference and all 27 distinct Mix mappings. They are not additional pressured human sessions.
- The source CI helper checks process exit status and engine errors. Individual artifact logs do not separately record return codes or wall times; none are fabricated here.
- Legacy route configuration is attributed to the pinned GDScript source, separately from the fields printed by the route marker.

[Machine-readable results and the 117-file source manifest](v0.5/GAMEPLAY_RESULTS.json), [combined verbatim gameplay logs](v0.5/GAMEPLAY_LOG.txt), [18 individual gameplay logs](v0.5/logs/gameplay/), and [recovery provenance](v0.5/RECOVERY_PROVENANCE.json) retain the underlying evidence.

## Native presentation inspection

Eight native staged fixtures were rendered from the same exact source and run using Godot 4.7.2, OpenGL compatibility, software Mesa and Xvfb.

The recovery verifies artifact digests, the source manifest, every PNG hash/header, and all eight capture success markers. **Assistant visual inspection is complete for all eight 1280 × 800 fixtures.** [The visual review](v0.5/VISUAL_REVIEW.md) records the observations. Human playtesting remains outside this evidence. These fixtures do not establish a complete graphical playthrough or hardware performance.

| Fixture | PNG | Dimensions |
|---|---|---:|
| menu | [menu.png](v0.5/menu.png) | 1280 × 800 |
| workshop | [workshop.png](v0.5/workshop.png) | 1280 × 800 |
| practice | [practice.png](v0.5/practice.png) | 1280 × 800 |
| practice_clear | [practice_clear.png](v0.5/practice_clear.png) | 1280 × 800 |
| manual | [manual.png](v0.5/manual.png) | 1280 × 800 |
| result | [result.png](v0.5/result.png) | 1280 × 800 |
| save_error | [save_error.png](v0.5/save_error.png) | 1280 × 800 |
| result_save_error | [result_save_error.png](v0.5/result_save_error.png) | 1280 × 800 |

[Original visual provenance](v0.5/VISUAL_PROVENANCE.json), [individual capture logs](v0.5/logs/visual/), and [recovery provenance](v0.5/RECOVERY_PROVENANCE.json) preserve the source and hashes. The recovery provenance records its collection-time state. The subsequent assistant inspection is documented separately in the visual review.

## Exact Windows publication

WINDOWS_PUBLICATION_EVIDENCE_PENDING

## Boundaries

These tests establish deterministic rules, scoped physical admission and
completion by informed input drivers. They do not establish novice usability,
all-seed/all-difficulty balance, networking, a graphical Windows playthrough,
hardware performance or execution of compiled Unreal Blueprint assets.

Practice times are elapsed simulation observations, separately recorded per
archetype. They are neither leaderboard guarantees nor novice target times.
