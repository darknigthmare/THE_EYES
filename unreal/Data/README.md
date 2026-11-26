# UE5 data table handoff

These UTF-8 CSV files contain scalar migration defaults. They are source data, not already imported Unreal assets. The live Godot script `game/scripts/trial_director.gd` remains authoritative for the shipped prototype. Reconcile intentional balance changes with these files before each engine migration milestone.

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
| `DT_TrialSlots.csv` / `ST_TrialSlotRow` | `BayId` Name; `FirstTrialId` Name; `SecondTrialId` Name |
| `DT_Contracts.csv` / `ST_ContractRow` | `DisplayName` String; `NorthwestVariant` Integer; `NortheastVariant` Integer; `SouthVariant` Integer; `SealCount` Integer; `RulesVersion` String |
| `DT_AlternateTrialDefaults.csv` / `ST_AlternateTrialDefaultsRow` | Integer: `RelicPoolCount`, `VaultTargetCount`, `RitualVesselCount`, `RitualCheckpointA`, `RitualCheckpointB`, `ClockHandCount`, `ClockPositions`. Float: `RitualHoldSeconds`, `ActorAttemptCooldownSeconds`, `ClockCommandCooldownSeconds` |
| `DT_ClockLevers.csv` / `ST_ClockLeverRow` | `LeverIndex` Integer; `HandADelta` Integer; `HandBDelta` Integer; `HandCDelta` Integer |

`BlueprintAssetName` records the class to create, without inventing an asset path. Once those classes exist, assign real `BP_TrialBase` class references in the editor-owned runtime registry. A row with no assigned authored class is not eligible for selection.

`DT_TrialSlots` has exactly three row keys: `silent`, `echoes`, `relay`. Each maps to a physical bay and two admitted trial IDs. `DT_Contracts` has keys `first`, `second`, `mix`; `mixed` is not an accepted alias. Variant values 0/1 select the first/second trial from the relevant slot, while -1 consumes one layout-stream choice. The explicit bay order is northwest, northeast, south. Do not use an unspecified map or DataTable iteration order to consume random draws.

The defaults row `prototype_0_2` supplies a pool of six relics and four target cradles; five ritual vessels, checkpoints at two/four and an eight-second final occupancy; a 0.35-second actor attempt interval; three clock hands, six positions and a 0.25-second global clock interval. `DT_ClockLevers` supplies the forward transform for each lever. Reverse multiplies all three deltas by -1 and uses positive modulo six.

Two spatial/generation constraints are specified in the construction graphs rather than additional CSV columns: the ritual ring has a **280 cm horizontal radius** and permits movement inside it during the eight-second hold; the clock generator uses **MinimumSolutionCommands=4**, performing a bounded breadth-first traversal to select a start from the current graph's 48 distance-four candidates among 108 reachable states. A random scramble count cannot substitute for shortest-path distance. See the [generation and occupancy recipes](../../docs/technical/CONTRACT_TRIAL_IMPLEMENTATION.md).

### Import acceptance

1. Create/save the five structures with the exact member names and types above. Import the CSVs with extra/missing-field warnings enabled. If editor-generated structure member names differ, export a one-row test table from that editor version and reconcile friendly headers; do not disable import warnings to conceal the mismatch.
2. Inspect all six registry rows and all three slot rows. Confirm every `SlotId` exists and matches the corresponding first/second pair.
3. Read each contract using `Get Data Table Row`: First is `(0,0,0)`, Second `(1,1,1)`, Mix `(-1,-1,-1)`, and all require three seals. Reject any other variant or seal count at runtime admission.
4. Verify the defaults remain 6/4 relic pool/targets, 5 vessels, 8.0 seconds, checkpoints 2/4, 0.35/0.25 seconds, and six clock positions. Confirm lever C changes Hands C and A, while leaving Hand B unchanged.
5. Author the missing trial classes and run the [graph recipes and acceptance matrix](../../docs/technical/CONTRACT_TRIAL_IMPLEMENTATION.md). CSV syntax checks alone do not establish Unreal import or gameplay correctness.

The readable `DisplayName` string is a migration convenience. When localization is introduced, resolve it through a String Table/Text presentation layer while keeping machine IDs unchanged. Do not localize contract keys, slot IDs, relic IDs or catalogue IDs.
