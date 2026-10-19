# tr-underworld-recomp

Static recompilation of **Tomb Raider: Underworld** (Xbox 360) to run natively on Windows, built on the [ReXGlue SDK](https://github.com/) v0.10.0.

**Status: milestone 1 of 6, in progress.** The recompiled game reaches the main menu with audio; pressing START still hits unregistered functions (fixed one at a time via `project/tru_functions.toml`).

## No game files here
This repository contains **no game data and no recompiled/generated code**. You must provide your own legally obtained copy of the game, extract it yourself, and generate the code locally with the SDK.

## Contents
- `patches/rexglue-tru.diff`: small documented SDK patches (patch 1 is a workaround for 185 rejected function mappings, to be re-evaluated).
- `project/`: manifest, function overrides and CMake file of the recompiled project.
- `scripts/`: PowerShell helpers (build SDK, install, init + codegen).
- `docs/HANDOVER.md`: technical state of the work.

## Rough workflow
1. Build/install ReXGlue SDK v0.10.0 (commit `f5337cdc...`), apply `patches/rexglue-tru.diff`.
2. Extract your own ISO; run `rexglue init` and `rexglue codegen` on your `default.xex`.
3. Copy `project/tru_functions.toml` next to the generated manifest and build.
4. Run: `tru.exe --game_data_root "<your game folder>" --gpu_plugin xenos`

## License
GPL-2.0-or-later. The ReXGlue SDK (BSD 3-Clause, derived from Xenia) keeps its own copyright notice, see `NOTICE-ReXGlue-SDK.txt`.
