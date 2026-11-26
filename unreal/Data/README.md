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
