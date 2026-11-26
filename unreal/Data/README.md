# UE5 data table handoff

These UTF-8 CSV files contain scalar migration defaults. They are source data, not already imported Unreal assets. The live Godot authority in `trial_director.gd`, `trial_set.gd`, `third_trials.gd`, `squad_state.gd` and their world adapters remains the executable source of truth for the prototype. Reconcile intentional balance changes with these files before each engine migration milestone. The v0.4 update at the end of this document extends the v0.2 slot/contract schema; use the current CSV headers when creating editor structures.

## Import without project C++

1. In Unreal Editor, create **Blueprints → Structure** named `ST_EyePowerRow` under `/Game/TheEyes/Data/Structs`.
2. Add fields exactly named `EnergyCost` (Float), `CooldownSeconds` (Float), `RequiresLineOfSight` (Boolean). Compile/save the structure. The CSV `Name` column is the row key and is not another member of the structure.
3. Import `DT_EyePowers.csv`, choose **DataTable**, then choose `ST_EyePowerRow`. Keep missing/extra-field warnings enabled and resolve all warnings.
4. Create `ST_MatchPresetRow` with the fields listed below, then import `DT_MatchPresets.csv` in the same way.
5. Inspect every imported row. Save the resulting `.uasset` tables in `/Game/TheEyes/Data/Tables`. Verify `trap` reads 25 and 4, and `standard` reads 480 and 65 using `Get Data Table Row` in a temporary Blueprint test actor.

| Match preset member | Blueprint type |
| --- | --- |
| PreparationSeconds | Float |
| HuntSeconds | Float |
| EscapeSeconds | Float |
| EnergyMaximum | Float |
| EnergyRegenPerSecond | Float |
| MotesRequired | Integer |
| EchoLength | Integer |
| RelayWorkSeconds | Float |

The CSV import uses a row structure and a stable first-column key; Epic documents that format in its [Data Driven Gameplay guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/data-driven-gameplay-elements-in-unreal-engine). The guide's code examples do not require this project to add C++: create the row structures as editor-authored Blueprint Structure assets. If a chosen engine version transforms member names during an import, export one test row from that version and compare headers before importing the full table.

## Identity rules

The row identifiers `trap`, `mark`, `summon`, `blink`, `story`, `standard`, and `ruthless` are machine identifiers. English display labels may change without changing those keys. Additions require a schema review; renamed keys require explicit migration. Do not localize keys, derive them from asset filenames, or key persistent state by array position.

No challenge actor classes are embedded in these tables. `data/design_catalog.json` holds the design catalogue; the Unreal trial registry must map each admitted trial's stable identifier to a real authored Blueprint class before it can enter the match pool.

## v0.2 contract and alternate-trial tables

Five additional CSVs keep the six-trial handoff explicit. The `Name` column is always the row key, not an extra struct member. Create the following **Blueprint Structure** assets and import the matching file as a DataTable. CSV values describe a construction contract; editor import and Blueprint execution still need validation in the selected UE version.

| CSV / row structure | Members and Blueprint types |
| --- | --- |
| `DT_TrialRegistry.csv` / `ST_TrialRegistryRow` | `CatalogueId` Name; `SlotId` Name; `BlueprintAssetName` Name |
| `DT_TrialSlots.csv` / `ST_TrialSlotRow` | `BayId` Name; `FirstTrialId` Name; `SecondTrialId` Name; v0.4 adds `ThirdTrialId` Name |
| `DT_Contracts.csv` / `ST_ContractRow` | `DisplayName` String; `NorthwestVariant` Integer; `NortheastVariant` Integer; `SouthVariant` Integer; `SealCount` Integer; `RulesVersion` String |
| `DT_AlternateTrialDefaults.csv` / `ST_AlternateTrialDefaultsRow` | Integer: `RelicPoolCount`, `VaultTargetCount`, `RitualVesselCount`, `RitualCheckpointA`, `RitualCheckpointB`, `ClockHandCount`, `ClockPositions`. Float: `RitualHoldSeconds`, `ActorAttemptCooldownSeconds`, `ClockCommandCooldownSeconds` |
| `DT_ClockLevers.csv` / `ST_ClockLeverRow` | `LeverIndex` Integer; `HandADelta` Integer; `HandBDelta` Integer; `HandCDelta` Integer |

`BlueprintAssetName` records the class to create, without inventing an asset path. Once those classes exist, assign real `BP_TrialBase` class references in the editor-owned runtime registry. A row with no assigned authored class is not eligible for selection.

`DT_TrialSlots` has exactly three row keys: `silent`, `echoes`, `relay`. v0.2 mapped each bay to two trial IDs; the current v0.4 rows add a third. `DT_Contracts` now has keys `first`, `second`, `mix`, `third`; `mixed` is not an accepted alias. Variant values 0/1/2 select the first/second/third trial from the relevant slot, while -1 consumes one layout-stream choice in the inclusive range 0–2. The explicit bay order is northwest, northeast, south. Do not use an unspecified map or DataTable iteration order to consume random draws. The v0.2/v0.3 Mix draw was 0–1; see the seed compatibility note below.

The defaults row `prototype_0_2` supplies a pool of six relics and four target cradles; five ritual vessels, checkpoints at two/four and an eight-second final occupancy; a 0.35-second actor attempt interval; three clock hands, six positions and a 0.25-second global clock interval. `DT_ClockLevers` supplies the forward transform for each lever. Reverse multiplies all three deltas by -1 and uses positive modulo six.

Two spatial/generation constraints are specified in the construction graphs rather than additional CSV columns: the ritual ring has a **280 cm horizontal radius** and permits movement inside it during the eight-second hold; the clock generator uses **MinimumSolutionCommands=4**, performing a bounded breadth-first traversal to select a start from the current graph's 48 distance-four candidates among 108 reachable states. A random scramble count cannot substitute for shortest-path distance. See the [generation and occupancy recipes](../../docs/technical/CONTRACT_TRIAL_IMPLEMENTATION.md).

### Import acceptance

1. Create/save the five structures with the exact member names and types above. Import the CSVs with extra/missing-field warnings enabled. If editor-generated structure member names differ, export a one-row test table from that editor version and reconcile friendly headers; do not disable import warnings to conceal the mismatch.
2. Inspect all nine current registry rows and all three slot rows. Confirm every `SlotId` exists and matches the corresponding first/second/third set.
3. Read each contract using `Get Data Table Row`: First is `(0,0,0)`, Second `(1,1,1)`, Third `(2,2,2)`, Mix `(-1,-1,-1)`, and all require three seals. Reject any other variant or seal count at runtime admission.
4. Verify the defaults remain 6/4 relic pool/targets, 5 vessels, 8.0 seconds, checkpoints 2/4, 0.35/0.25 seconds, and six clock positions. Confirm lever C changes Hands C and A, while leaving Hand B unchanged.
5. Author the missing trial classes and run the [graph recipes and acceptance matrix](../../docs/technical/CONTRACT_TRIAL_IMPLEMENTATION.md). CSV syntax checks alone do not establish Unreal import or gameplay correctness.

The readable `DisplayName` string is a migration convenience. When localization is introduced, resolve it through a String Table/Text presentation layer while keeping machine IDs unchanged. Do not localize contract keys, slot IDs, relic IDs or catalogue IDs.

## v0.3 Survivor Squad defaults

Create **Blueprint Structure** `ST_SquadDefaultsRow`, then import [`DT_SquadDefaults.csv`](DT_SquadDefaults.csv) as `DT_SquadDefaults`. As in the other tables, `Name` is the row key and not a structure field. This table applies only to `SessionMode=squad`; do not accidentally apply its rescue policy to solo Second Sight or the human Eye mode.

| Member | Blueprint type | `prototype_0_3` value |
| --- | --- | ---: |
| HumanSurvivors | Integer | 1 |
| BotSurvivors | Integer | 4 |
| BleedoutSeconds | Float | 35 |
| RescueSeconds | Float | 6 |
| RescueHealth | Float | 35 |
| ProtectionSeconds | Float | 5 |
| RescueRangeCm | Float | 180 |
| KeeperRangeCm | Float | 400 |
| KeeperHealAmount | Float | 30 |
| KeeperCooldownSeconds | Float | 35 |
| KeeperIncludesSelf | Boolean | true |
| KeeperSelfWinsEqualHealth | Boolean | true |
| RelayCombinedRateMaximum | Float | 1.8 |
| RecoveriesPerMember | Integer | 1 |

The distance fields are UE centimetres, corresponding to 1.8 m rescue and 4 m Keeper range in Godot. Rescue requires physical line of sight and six uninterrupted stationary seconds; input release, movement, applied damage, range/sight failure or life/phase change resets the reservation and progress. One helper owns one subject, and each subject has at most one helper. The second lethal fall after rescue eliminates the member. A team with no active helper remaining resolves the downed members as a wipe.

Keeper chooses the most injured eligible active team member **including self**. Other candidates require range and clear line of sight. Self wins equal-health ties, then stable registered actor order resolves other ties. Neither Keeper nor ordinary healing replenishes the one rescue allowance. Boolean columns preserve this targeting policy explicitly; the actual graph must implement it.

Create enum assets for the stable life IDs `active/downed/eliminated` and order IDs `work/follow/hold`, with explicit name mapping for records rather than persisted enum ordinals. Orders persist until changed; temporary rescue tasks do not overwrite the stored order, Follow falls back to Work while the leader is inactive, and Escape overrides ordinary orders. Immediate evasion of a nearby visible shadow takes priority even over rescue: cancel its progress, move by a physically clear navigation step, then resume legitimate work/rescue. Pause also clears reservations/progress before freezing all timers. The authority owns this policy rather than the CSV importer. Aggregate all valid squad Relay work once per physics update and cap the combined rate at 1.8 times base; do not apply the same elapsed time independently for each helper. Solo rates stay unchanged.

After import, use `Get Data Table Row` on `prototype_0_3`, inspect every value and verify both Boolean fields. Then execute the [squad graph and acceptance recipes](../../docs/technical/SQUAD_IMPLEMENTATION.md), including wall/range cancellation, one-chance revival, all-down wipe, Keeper self tie, physical bot orders and separate mode admission. A syntactically valid CSV does not establish a successful Unreal import, compiled graph or playable build.

## v0.4 Third Observance defaults and schema update

The current handoff contains **nine CSV tables**. The new [`DT_ThirdTrialDefaults.csv`](DT_ThirdTrialDefaults.csv) captures the three additional prototype subsets. Create Blueprint Structure `ST_ThirdTrialDefaultsRow` with the exact fields below, then import the row `prototype_0_4`. As elsewhere, `Name` is the row key, not an extra structure member.

| Member | Blueprint type | Value |
| --- | --- | ---: |
| CellCount | Integer | 3 |
| RefugeCount | Integer | 3 |
| LampChargeMaximum | Float | 100 |
| LampDrainPerSecond | Float | 4 |
| LampRechargePerSecond | Float | 12 |
| RefugeRadiusCm | Float | 300 |
| ActionRangeCm | Float | 180 |
| AlignmentSeconds | Float | 2 |
| StringStageCount | Integer | 3 |
| RopesPerStage | Integer | 4 |
| StringCutSeconds | Float | 2 |
| SafetyCatchSeconds | Float | 3 |
| BellCount | Integer | 4 |
| PhraseCount | Integer | 2 |
| NotesPerPhrase | Integer | 4 |
| BellCooldownSeconds | Float | 0.45 |
| DamperCooldownSeconds | Float | 0.5 |
| NormalNoise | Float | 6 |
| DampedNoise | Float | 1 |
| WrongNoise | Float | 10 |
| BotObservationSeconds | Float | 2 |

`RefugeCount` counts the three activatable lamps; the permanent base refuge is an additional recovery anchor. Noise values are durations in seconds of the Eye's approximate noise memory, not decibels or damage. Main retains the greater of the existing duration and the new duration. `WrongNoise` applies to a wrong bell strike even when that bell is damped and to a failed rope cut. Distances are Unreal centimetres; Godot uses 3 m and 1.8 m.

### Required changes to existing row structures

1. Add **`ThirdTrialId` (Name)** to `ST_TrialSlotRow`, then reimport `DT_TrialSlots.csv`. Each slot now contains three candidates.
2. Reimport the nine-row registry and four-row contract table. `light/T04`, `strings/T07` and `chimes/T17` map to `BP_TrialLightInDarkness`, `BP_TrialStringsOfDespair` and `BP_TrialChimesOfDoom`, respectively. These are authoring names until the Blueprint classes actually exist.
3. Admit literal variants **0, 1, 2** and the random value **-1**. Random selects an integer 0–2 once per bay. All contracts still require exactly three seals.
4. Keep the contract keys `first`, `second`, `mix`, `third`. Third is `(2,2,2)`; Mix is `(-1,-1,-1)`. No `grand_mix` key is present.
5. Check the displayed names against the chosen trial IDs. The `silent` slot can contain `light`; its HUD must not display Silent Countdown for that match.

### Seed and record compatibility

The old Mix selector chose between two variants. v0.4 chooses between three and therefore changes the selection associated with old Mix seeds. Within one version, a seed still fixes selection and puzzles. Preserve **rules version and resolved selection** in records; do not treat a seed alone as a cross-version replay identifier. `RulesVersion=0.4.0` on the current contract rows makes that boundary explicit.

First and Second retain their apparatus and established mechanics. The historical v0.2 graph guide describes the original two-candidate selector; use the [v0.4 construction specification](../../docs/technical/THIRD_TRIAL_IMPLEMENTATION.md) for the current three-candidate extension.

### Import and runtime acceptance

Read `prototype_0_4` through `Get Data Table Row` and inspect every numeric field. Verify the three new registry entries resolve to authored classes, the pool has nine entries and the selector can reach all 27 Mix mappings. Then run physical gameplay checks: individual charge and refuge LOS, interrupted two-second holds, unique rope clue solutions, three-second safety catches, first-phrase permanence, global bell/damper cooldowns and noise at the struck bell.

The CSV does not encode the complete logic. The graph must retain cargo uniqueness, active-life admission, physical range/sight, once-per-frame time integration, stale-hold cancellation and once-only seal completion. No table import or Unreal runtime result is established by these source files alone.
