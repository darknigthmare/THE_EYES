# Content assets to author in Unreal Editor

This directory intentionally contains no fabricated `.uasset` or `.umap` files. The project descriptor is a content-only shell, not a playable UE5 build. Create the Blueprint classes, interfaces, structs, data tables and level described in [the setup guide](../README.md) and [the implementation specification](../../docs/technical/UE5_BLUEPRINT_IMPLEMENTATION.md).

All authored UE5 content belongs under `Content/TheEyes/`. Commit the real editor-created assets after a successful compile, save and play-in-editor check. Generated caches and compiled engine files stay excluded.

