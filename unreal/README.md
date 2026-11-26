# THE EYES — Unreal Engine 5 foundation

**Status: construction foundation, not a playable Unreal build.** The runnable game prototype is the [Godot project](../game). This folder supplies a content-only `.uproject`, input configuration, two CSV tuning tables and a precise Blueprint construction plan. No Unreal Editor has compiled or tested these assets in this delivery, and there are no `.uasset` or `.umap` files yet.

The intended UE5 game is entirely authored in Blueprints, with English gameplay text. There are no project C++ modules, C++ gameplay classes or build targets here. Built-in engine plugins remain engine implementation details; enabling Enhanced Input or Niagara does not add project C++ source.

## Open the foundation

1. Install a supported Unreal Engine **5.x** version through your normal Epic installation. Choose and record a project version before content production; the descriptor deliberately leaves `EngineAssociation` empty instead of claiming a tested engine release.
2. Open `TheEyes.uproject`. If the launcher asks for an engine association, select your installed UE5 version. For an installation that does not recognize the file association, open Unreal Editor's project browser, use **Browse**, and select this descriptor.
3. Accept the built-in Enhanced Input and Niagara plugins. This shell has no custom binary module to rebuild. If the editor reports a plugin incompatibility, select a supported UE5 release and verify the bundled plugin before proceeding; do not invent missing modules.
4. Create a **Basic** level and immediately save it as `/Game/TheEyes/Maps/L_FirstObservance`.
5. Create the folders and assets in the order below. Set Project Settings → Maps & Modes only after the corresponding map and Blueprint classes actually exist. No config here points to a nonexistent map or GameMode.
6. Follow the [Blueprint implementation guide](../docs/technical/UE5_BLUEPRINT_IMPLEMENTATION.md). Start with the local survivor loop, then run the network tests before considering any public multiplayer build.

## Asset creation order

| Order | Create in the editor | Output location |
| --- | --- | --- |
| 1 | Enums, structures, interfaces and the imported scalar tables | `/Game/TheEyes/Data`, `/Game/TheEyes/Interfaces` |
| 2 | `BP_EyesGameMode`, `BP_EyesGameState`, `BP_EyesPlayerState`, `BP_EyesPlayerController` | `/Game/TheEyes/Framework` |
| 3 | Survivor character, Eye pawn, interaction and status components | `/Game/TheEyes/Characters`, `/Game/TheEyes/Components` |
| 4 | Input actions and mapping contexts | `/Game/TheEyes/Input` |
| 5 | Arena floor, occluders, four sockets and exit corridor | `/Game/TheEyes/Maps/L_FirstObservance` |
| 6 | Trial base, three live trial children, mote, receiver, trap and escape gate | `/Game/TheEyes/Trials`, `/Game/TheEyes/World` |
| 7 | HUD, main menu, options and result widgets | `/Game/TheEyes/UI` |
| 8 | Eye/survivor controllers, blackboards and behavior trees | `/Game/TheEyes/AI` |
| 9 | Original meshes, materials, VFX, animations and sounds | `/Game/TheEyes/Art`, `/Game/TheEyes/Audio` |
| 10 | Functional test map and packaged development build | `/Game/TheEyes/Tests` |

## Set the startup classes after creation

In `BP_EyesGameMode` defaults, select the newly created GameState, PlayerState and PlayerController. Leave Default Pawn Class as the spectator pawn while the role assignment path is being built; then spawn and possess the appropriate survivor or Eye pawn on the server. Set `BP_EyesGameMode` as the game default in Maps & Modes, and choose `L_FirstObservance` as both the editor startup map and game default map for the first milestone.

Assign the intended GameMode to the map's World Settings too, or clear an accidental per-map override. Add the actual map to the packaging map list once its local and network tests pass. A successful project open is not proof that gameplay has been implemented.

## Decisions already fixed

- The Eye changes between authored sockets; it never freely translates through the arena.
- Targeting combines angular eligibility with collision queries. A wall must block a harmful gaze command.
- Clients request actions through their owned PlayerController. The server validates and commits gameplay state.
- Complete three seals, then survive an escape countdown. The first legitimate survivor crossing wins for the survivor team.
- The prototype's three trials are **The Silent Countdown**, **Trial of the Echoes**, and **Clockwork Relay**. The other 22 remain design entries until their assets and acceptance tests exist.
- The complete game's 5–7 survivors versus one Eye, session browser, reconnect, party modes and cross-platform services remain development work.

## Working documents

- [Blueprint classes, variables and node recipes](../docs/technical/UE5_BLUEPRINT_IMPLEMENTATION.md)
- [Networking, replay boundaries and save contracts](../docs/technical/NETWORK_AND_SAVE_CONTRACTS.md)
- [Art, animation, audio and rendering production](../docs/technical/ASSET_PRODUCTION.md)
- [Verified primary sources and their scope](../docs/technical/SOURCES.md)
- [CSV import instructions](Data/README.md)

Before marking the Unreal milestone playable, attach actual editor compile output, a packaged smoke-test log and two-client test results to its change request. Until then, link users to the Godot prototype rather than treating this descriptor as an executable game.
