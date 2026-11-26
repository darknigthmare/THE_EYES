# The Trial Workshop — session, records and Unreal handoff

## Status and scope

This document specifies the **v0.5.0 Trial Workshop** in the local Godot prototype and its Blueprint porting contract. The Workshop selects one of the existing nine implemented trials for one human survivor. It reuses the actual controller, physical apparatus and trial rules. The ordinary Solo, Eye and Squad modes still use the four contracts and require three seals followed by escape.

The playable implementation is under `game/`. The Unreal portion below is a construction recipe with a tenth source CSV; no editor-authored practice assets, compiled Blueprint graphs or packaged Unreal gameplay are supplied. Actual executed checks belong in [V0_5_VERIFICATION.md](../qa/V0_5_VERIFICATION.md), not in the acceptance plan below. The [bible chapter](../bible/15_TRIAL_WORKSHOP.md) explains the learning goals and all nine lessons.

## Authority and responsibilities

| Owner | Responsibility | Must not do |
| --- | --- | --- |
| `TrialDirector` | Admit the selected trial, keep practice phase/time, accept its real seal and emit one completion | Open escape, resolve a competitive winner or accept another bay's progress |
| `TrialSet` and the existing trial domains | Preserve generated puzzles, cargo ownership, action intervals, checkpoint and failure rules | Replace physical commands with tutorial completion shortcuts |
| Physical world adapters and `main.gd` | Spawn one human, configure the active apparatus, validate movement/range/sight and suppress opponent/damage paths | Spawn helpers that finish the drill or let inactive props supply cargo |
| `PracticeState` | Expose the stable nine-entry catalogue and presentation of admitted progress | Reveal a generated answer outside the apparatus's normal evidence path |
| `PracticeRecords` | Keep bounded local attempts/completions and per-archetype timing; validate and save the separate journal | Resolve gameplay, append unbounded history or overwrite a protected unreadable/future file |
| Interface and practice UI | Select trial/archetype/seed, present steps, show progress/result and request retries | Award seals, write a competitive result or silently resume after closing the manual |

The critical separation is between an objective being **live** and the opponent being **allowed to act**. Trial interaction must admit phase `practice`; Eye attacks, gaze damage, ordinary defeat/escape and competitive result persistence must explicitly exclude practice. Extending a common live predicate without checking these consumers would accidentally re-enable pressure.

## Selection and identity

`PracticeState.catalogue()` returns nine entries in the authored order below. Each entry has the fields `trial_id`, `slot_id`, `title`, `summary`, `instructions`, `checkpoints` and `controls`. `instructions` is an ordered array of step strings; the summary, checkpoint explanation and controls are display strings. Stable IDs, rather than a translated title or card position, select gameplay and key records.

| Order | `trial_id` | Catalogue ID | `slot_id` | Trial |
| ---: | --- | --- | --- | --- |
| 1 | `silent` | T02 | `silent` | The Silent Countdown |
| 2 | `echoes` | T05 | `echoes` | Trial of the Echoes |
| 3 | `relay` | T08 | `relay` | Clockwork Relay |
| 4 | `vault` | T24 | `silent` | The Memory Vault |
| 5 | `ritual` | T10 | `echoes` | The Ritual Circle |
| 6 | `clock` | T16 | `relay` | The Clock Room |
| 7 | `light` | T04 | `silent` | Light in the Darkness |
| 8 | `strings` | T07 | `echoes` | Strings of Despair |
| 9 | `chimes` | T17 | `relay` | Chimes of Doom |

The `silent`, `echoes` and `relay` slot names remain stable identifiers for the northwest, northeast and south apparatus families. A `light` drill occupies the `silent` slot; this does not make it Silent Countdown. HUD titles must follow the selected trial ID.

The chosen archetype is one of `Veil`, `Tinker`, `Runner` and `Keeper`. Seeds admitted by the practice selector/journal are integers **1–999999**. A new seed rebuilds the generated setup, but two seeds can legitimately produce some identical features. The seed does not encode physical timing, a complete input replay or cross-version equivalence.

Practice is not a row in `DT_Contracts` and is not a fifth match contract. The four existing contract rows, nine-trial registry and 27 Mix combinations retain their meaning.

## Admission, live phase and completion

The director entry point is:

```text
TrialDirector.configure_practice(trial_id, seed) -> bool
```

A successful configuration selects one real trial, marks the session as practice and enters phase `practice`. Invalid selection must be rejected before an incomplete session is exposed to the player. The public `is_practice()` and `is_live()` predicates let the world adapters share normal trial interaction while retaining the separate opponent policy.

The other two bays are inactive. Their completion flags stay false; an implementation must not pre-fill them to make a three-seal director finish early. Inactive cargo and apparatus must be hidden or clearly disabled, and the action authority must reject their commands even if stale input reaches it.

| Transition | Required behavior |
| --- | --- |
| Open Workshop | Show catalogue and records; do not count a completion or start the simulation |
| Start an admitted drill | Rebuild the arena session, spawn one human at the normal survivor start, begin one journal attempt, start active elapsed time |
| Run physics | Advance the selected trial and survivor normally; do not consume a Hunt/Escape budget or run Eye/damage pressure |
| Complete selected trial | Bank one real seal, freeze the attempt and emit `practice_completed` once |
| Receive duplicate or late completion | Do not mutate counts, result or frozen elapsed time |
| Retry same seed | Recreate the selected drill and archetype with the same seed; clear all transient apparatus/cargo/hold/cooldown state |
| Retry another seed | Keep the trial and archetype while configuring a fresh admitted seed |
| Next trial | Use the next catalogue entry, wrapping after Chimes; rebuild a new attempt |
| Leave or restart before completion | End the current active attempt without a completion time; a new admitted start counts separately |

The completion event is:

```text
practice_completed {
    trial_id,
    slot_id,
    seed,
    elapsed
}
```

`elapsed` is the active simulation duration of that attempt. It stops while paused and after completion. The selected archetype comes from the admitted session context, not from a later UI selection. A result says that a Workshop trial was completed; it does not manufacture a competitive `result` event, `winner`, escape count or ordinary match record.

The player must still travel from spawn, approach the apparatus, carry actual cargo and satisfy the ordinary completion path. Lamp charge, string safety catches, bell/clock action intervals, banked phases and normal archetype differences remain part of the lesson. Tinker can work Relay faster and Runner can move differently; those are reasons to partition timing records by archetype. Silent Countdown's noise and Chimes' damper remain observable mechanics, but without an active Eye their tactical effectiveness is not being tested.

## Guidance and pause flow

The practice HUD combines the selected trial's stable teaching text with its authoritative progress. It should explain the next kind of action without replacing the player's observation: reach the board, read the phrase, choose the intersection, carry the matching object, or confirm aligned hands. It must not expose a generated Vault list, Echoes answer, rope solution or bell phrase remotely just because the UI can access the underlying state.

The Field Manual is available from menus and with **F1** during play or pause. When opened from a live session it uses the local pause path before displaying text. Closing it returns to that session's pause screen; the player chooses Resume explicitly. When opened from a menu, closing returns to that menu. Reading must neither create a new attempt nor advance active elapsed time.

Focus loss also invokes local pause. Returning application focus does not resume by itself. Pause clears incomplete physical holds according to the existing trial/squad rules and freezes simulation timers; banked checkpoints remain banked. This applies to ordinary local matches as well as practice. It is not a promise about how a future remote game will pause.

The camera setting is labelled **Survivor / spectator FOV** because those are the cameras it changes. The Eye retains its fixed authored view and perception model. Physical keyboard bindings remain the implemented input system. Remapping, gamepad qualification and Eye training are deferred.

## Practice journal schema 1

`PracticeRecords` owns **`user://practice_records.json`**. The ordinary post-match file remains **`user://last_observance.json`**, schema 3. Loading or completing practice must not write the ordinary file. Neither file is a mid-session save or a full replay.

### Stable user-data directory

From v0.5, `game/project.godot` enables `config/use_custom_user_dir=true` and sets `config/custom_user_dir_name="THE_EYES"` in its application section. Settings and records therefore share a stable application-data folder even when the displayed release title changes.

| Platform | Standard location of `user://` |
| --- | --- |
| Windows | `%APPDATA%\THE_EYES` |
| Linux | `~/.local/share/THE_EYES`, or `$XDG_DATA_HOME/THE_EYES` when overridden |
| macOS | `~/Library/Application Support/THE_EYES` |

These locations follow Godot's documented [custom user-directory rules](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#accessing-persistent-user-data-user). The configuration keeps the stable name separate from the project's release subtitle. Earlier versions' default, title-based folders are left untouched and are not automatically migrated. Project source/Drive backups do not include files created on a player's computer.

### Record fields

The root is an object with `schema_version: 1` and `trials`. Only the nine known trial IDs and four known archetype names are retained. Each trial contains aggregate `attempts`, aggregate `completions` and `by_archetype`. Each archetype profile has the following fields:

| Field | Type and meaning |
| --- | --- |
| `attempts` | Bounded integer count of admitted starts for this trial/archetype |
| `completions` | Bounded integer count of accepted completions, no greater than attempts |
| `last_seed` | Seed of the most recently started attempt; zero before any attempt |
| `last_seconds` | Active duration when that latest attempt completes; reset to zero at its start |
| `best_seconds` | Fastest accepted duration for this trial/archetype; zero before any completion |
| `best_seed` | Seed associated with that best completion; zero before any completion |

There are **9 trial records × 4 profiles = 36 bounded profiles**. There is no per-attempt history array and no per-seed dictionary. A profile caps counters at **1,000,000** and admits finite durations up to **31,536,000 seconds**. Trial aggregate counts are recalculated from the four profiles rather than trusted independently. Their maximum follows the four-profile sum. `best_seed > 0` indicates an available best time. A latest duration of zero can describe an unfinished attempt or a valid zero-duration domain fixture; neither it nor the cumulative completion count establishes that the latest attempt finished.

This illustrative fragment shows one profile after two starts and one completion. Omitted trials and roles are omitted only for readability; they are normalized from the admitted catalogue in the actual journal. The numbers are examples, not measured performance:

```json
{
  "schema_version": 1,
  "trials": {
    "relay": {
      "attempts": 2,
      "completions": 1,
      "by_archetype": {
        "Tinker": {
          "attempts": 2,
          "completions": 1,
          "last_seed": 271126,
          "last_seconds": 38.5,
          "best_seconds": 38.5,
          "best_seed": 271126
        }
      }
    }
  }
}
```

The mutation interface is `begin_attempt(trial_id, archetype, seed) -> bool` followed, only after admitted completion, by `complete_attempt(seconds) -> bool`. A begin increments the attempt count, stores the seed and clears the latest duration. A completion increments the completion count and updates the last/best fields at most once. `begin_attempt` rejects an already active attempt: the retry/leave path must call `abandon_attempt()` first. Abandoning clears the in-memory handle without manufacturing a completion or erasing the previous best. Reloading a journal never resumes an active attempt or infers that its unfinished work was completed. `snapshot()` supplies a copy for the UI.

Best-time comparison stays inside a trial/archetype profile. Different seeds share that profile, with each recorded seed making the context visible. These local times have no external ranking, reward or competitive authority. Player-editable data cannot certify mastery or serve as an anti-cheat record.

### Loading, saving and failure behavior

`load_records()` and `save_records()` return a Boolean; `last_error` explains failure. Before using loaded data, validate the root, schema, key allowlists, numbers and per-profile relationships. Reject non-finite timing and malformed values instead of allowing them to contaminate best-time comparisons.

An unreadable primary file, file larger than **131,072 bytes**, invalid root JSON or unsupported schema is preserved. Saving is blocked for that protected load state, including a newer schema produced by a future version. There is no silent fallback over a corrupt or newer primary. The writer rechecks an existing on-disk document before replacement, so a schema changed after initial loading is protected too. The player can continue training; the UI must distinguish an in-memory completion from a successfully saved record.

Before writing, the writer validates the primary and any existing `.bak`; an invalid or unsupported backup blocks saving even when the primary can be loaded. It stages a complete new document in `practice_records.json.tmp`, then flushes and closes it. Before replacing an existing valid primary, it copies that primary through `practice_records.json.bak.tmp` and installs **one** `practice_records.json.bak` recovery copy. If preparing this copy fails, it leaves the primary in place and does not start its replacement. The `.bak` remains after a successful save. This is a bounded previous-document backup, without a growing backup history.

The final temporary-to-primary rename is **not claimed to be atomic on Windows**. The [Godot Windows rename implementation](https://github.com/godotengine/godot/blob/master/drivers/windows/dir_access_windows.cpp), consulted on the upstream `master` branch on 26 November 2026, removes an existing destination before its move operation in the ordinary replacement branch. That source inspection motivates the recovery policy; it is not an exact-tag audit of the packaged engine.

If replacement fails after the primary disappears, the writer attempts restoration from `.bak` through `practice_records.json.restore.tmp`. `save_records()` still returns false because the new snapshot was not committed; `last_error` distinguishes restored, preserved and backup-only recovery states. If restoration also fails, the previous document remains in `.bak`. Temporary-file cleanup is attempted on reported failures.

Loading follows an explicit priority:

| Files found | Load and future-write policy |
| --- | --- |
| Valid primary | Load and normalize it; an invalid or unsupported existing `.bak` still blocks the next save |
| Invalid, unreadable or unsupported-schema primary | Preserve it and block writes, even if `.bak` is valid |
| No primary, valid `.bak` | Load the backup into memory and set `recovered_from_backup=true`; a later successful save writes the primary |
| No primary, invalid/unreadable/unsupported-schema `.bak` | Preserve the surviving backup and block writes |
| Neither primary nor `.bak` | Start an empty bounded journal |

A leftover `.tmp` is not assumed to be committed data. Loading a valid backup does not rewrite any file. Saving rechecks a surviving `.bak` before writing, so an upgraded or damaged backup is protected even when the primary disappears after startup. This recovery protocol reduces the risk of losing a prior valid notebook during a failed replacement; it is not a guarantee against every power-loss, filesystem or hardware failure. Executed failure fixtures and platform checks determine the actual evidence.

## Unreal Blueprint construction recipe

### Add an explicit session policy

Extend the existing session-mode enum with a stable **Practice** value and add **Practice** to the phase model. Map serialized names explicitly; do not persist enum ordinals. Give the authoritative session these fields: selected trial ID, selected slot ID, selected archetype ID, seed, active elapsed time and a completion latch. Reuse the existing trial registry and apparatus components.

On a practice launch, validate the row and authored class before destroying the prior session. Spawn one survivor at the normal start; do not spawn AI helpers or an active Eye controller. Instantiate only the chosen apparatus family as interactive. Keep non-selected bays inactive and their seal flags false. The shared interaction admission admits Practice, while opponent, damage, timeout, escape and competitive-result branches explicitly require a match policy.

Accumulate elapsed time from valid active simulation updates. A selected trial's authoritative seal calls a distinct `CompletePractice` path. That path checks selected trial/slot identity and the completion latch, freezes the session, emits a practice result and requests one journal completion. Never call the ordinary `ResolveMatch` as a shortcut. Retry destroys/reinitializes the actual transient world state before beginning the next attempt.

### Import the tenth source table

Import [`DT_PracticeDrills.csv`](../../unreal/Data/DT_PracticeDrills.csv) using an editor-authored `ST_PracticeDrillRow`. The row key is the runtime trial ID. Other fields are `CatalogueId` and `SlotId` (Name), `DisplayOrder` (Integer), `DisplayName` and `LearningGoal` (String), and `RulesVersion` (String). `DisplayOrder` is explicitly 1–9; sort by it rather than assuming DataTable iteration order. Join the row key to `DT_TrialRegistry` and verify the same slot/catalogue IDs.

Epic's [Data Driven Gameplay documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/data-driven-gameplay-elements-in-unreal-engine) describes the row-key/column mapping and import warnings. The project supplies source rows; the editor structures, imported table assets and trial class references still require creation and validation. The CSV does not include fake asset paths or nested tutorial arrays. Author the step/checkpoint/control text from `PracticeState.catalogue()` in the chosen text presentation assets, preserving the same stable IDs.

The rows use `RulesVersion=0.5.0` for the new Workshop selection contract. Ordinary match rows retain their established v0.4 rules boundary because the nine-trial pool, four contracts and Mix selector are unchanged.

### Build the teaching and result widgets

Create a Workshop selection widget with nine entries, four archetypes, seed entry, selected instructions and journal summary. Create an in-game objective/guide panel and a separate Workshop result widget. Wire requests to the session owner; widgets never mark seals or increment records. Include same-seed retry, another seed, next trial, catalogue and main menu actions.

Create the Field Manual overlay with an explicit return destination. Open it from a local active session by pausing first; closing returns to the paused menu. Implement focus-loss pause in the chosen engine/platform integration and verify actual focus events on the packaged target. Do not equate a widget losing keyboard focus with the application losing operating-system focus. Keep the player able to deliberately resume and test all input modes after that transition.

### Port the journal without inventing file equivalence

Create `BP_PracticeJournalSave` as a Blueprint SaveGame class with a schema version and the bounded trial/archetype records. Keep its save slot distinct from ordinary match results. Map fields explicitly and validate them on load. Godot's `user://practice_records.json` and an Unreal SaveGame slot are different storage formats; automatic interchange requires a separately implemented migration and is not supplied here.

Epic's [saving and loading guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/saving-and-loading-your-game-in-unreal-engine) documents SaveGame objects and completion/failure results for save operations. Use that result before reporting persistence. Serialize requests so rapid retries cannot overwrite a newer snapshot with an older asynchronous save. A Blueprint save node alone does not implement the Godot writer's backup/recovery protocol; define and test the selected platform's recovery policy before claiming parity. Preserve unknown future schemas and keep training available after a record failure.

## Acceptance matrix

These are required checks, not a report that they have already passed. The release report must identify the actual command, fixture, source revision and outcome for executed coverage.

| Area | Required observation |
| --- | --- |
| Catalogue | Nine unique entries in explicit order; valid registry/slot joins; no fifth contract |
| Selection | Every known trial admitted; unknown trial/role and invalid seed rejected without exposing a half-built session |
| Isolation | Only selected apparatus supplies objective cargo or accepts progress; inactive seals remain false |
| Domain completion | One real selected seal and one practice event; no competitive result, winner or escape |
| Physical completion | Each of the nine trials completed from the usual spawn through normal movement and accepted interactions |
| Existing mechanics | Exact cargo identity, seeded clues, checkpoints, holds, failure recovery and archetype effects preserved |
| No opponent pressure | No Eye power, gaze wound, trap/shadow damage, deadline or escape requirement during practice |
| Repetition | Same-seed reset reproduces setup; new-seed and next-trial requests rebuild transient state; late events do not leak across attempts |
| Pause/manual/focus | Active time freezes; incomplete holds cancel; manual returns to pause; focus return needs explicit resume |
| Journal | Attempts and completions counted once; four separate archetype bests; bounded normalization, reload and invalid-data checks |
| Persistence failure | Failed/unsupported primary load preserves it without fallback; missing primary can load one valid `.bak`; invalid existing backup blocks saving; failed replacement attempts restoration and still reports failure |
| Stable user directory | Release subtitles do not change the `THE_EYES` data directory; older title-based folders remain untouched |
| Ledger isolation | Practice leaves the ordinary `last_observance.json` unchanged |
| Ordinary regressions | Existing Solo/Eye/Squad, all four contracts and 27 Mix selections retain their outcomes |
| Native Windows startup | The exact exported archive starts all twelve ordinary mode/contract cases and all nine practice selections: 21 cases |
| Unreal gate | Authored assets import, compile and execute the selected engine's functional tests before any playable UE5 claim |

Physical routes establish that the apparatus can be reached and completed. They do not establish that a novice understands every instruction or that the learning transfers to a pressured match. Human usability sessions, graphical Windows playthrough and the Unreal port retain their own evidence requirements.
