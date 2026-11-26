# v0.4 native visual review

Six **1280 × 800** images were captured with the actual Godot renderer and inspected individually. They show the v0.4 interface, survivor presentation and Third Observance apparatus. These are **staged presentation fixtures, not completed playthroughs**. Gameplay and automated route evidence are recorded separately in [the v0.4 verification report](../V0_4_VERIFICATION.md).

## Image inventory

| Image | Inspected presentation | Scope and limits |
| --- | --- | --- |
| [menu.png](menu.png) | The Third Observance subtitle, version 0.4.0, nine-trial description, Solo / Squad / Eye entry points and the open four-contract selector. | The selector visibly lists First Observance, Second Observance, Seeded Mix and Third Observance. This image does not demonstrate launching each mode. |
| [squad.png](squad.png) | Four distinct survivor outfits and silhouettes, compact world name tags, all five roster entries, readable health and task text. | The four bots are positioned together for comparison. Their displayed tasks are assigned by the fixture; this is not evidence of task execution. |
| [light.png](light.png) | `CELL 2 / LANTERN 62%` in the HUD, an illuminated Refuge 1, the permanent recharge refuge and the alignment/recharge instructions. | One banked lamp and the carried cell are staged. The small carried-object number is outside this first-person framing; the image verifies the HUD identity, not the carried-object identity update. |
| [strings.png](strings.png) | All four physical tags and their text: Circle, Diamond, Triangle and Crescent; the current right-pair / angular clue; hold-to-cut prompts. | The front-facing composition exposes all four shapes. Rope geometry crosses small portions of the distant heading and clue board. The stage is staged and no successful cut is implied. |
| [chimes.png](chimes.png) | The four-bell apparatus, the shared damper on Bell 2, the `DAMPED` status and a first-phrase-banked prompt. | The oblique view leaves part of the score behind the foreground bell support. Treat this as an apparatus/damper illustration, **not proof of complete score readability**. Phrase and note progress are staged. |
| [manual.png](manual.png) | The scrolled Light, Strings and Chimes instructions, Eye controls, scrollbar and fixed confirmation button. | This is the Third Observance portion of a scrollable manual; earlier chapters are outside the frame. |

No screenshot is an illustration generated outside the engine, a fabricated gameplay result, a Windows execution result or an Unreal Engine execution result. No image editing was applied to the captures.

## Capture method

The reproducible fixture is [capture_third.gd](../../../game/tests/capture_third.gd). It loads the normal main scene, selects the `third` contract with seed `271126`, uses the normal apparatus and HUD, and explicitly stages actor positions, camera direction, inventory and checkpoint state. Gameplay physics is frozen, the grace toast is cleared for inspection, and the native viewport is saved after rendering. The menu fixture embeds the contract popup so that its choices are included in the viewport capture.

The helper prints the following marker before saving:

```text
THE_EYES_VISUAL_FIXTURE view=<view> contract=third physics_frozen=true; staged inspection, not playthrough
```

An example invocation, from the repository root on a machine with a working native display:

```bash
godot --path game --resolution 1280x800 --audio-driver Dummy \
  --script res://tests/capture_third.gd -- \
  --capture-path=/absolute/output/light.png --capture-view=light --mute
```

Replace `light` with `menu`, `squad`, `strings`, `chimes` or `manual`. The helper deliberately rejects headless rendering and relative output paths.

## Environment and execution result

The images used Godot **4.7.2.stable.official.ed1daf0bf**, the Compatibility renderer, OpenGL 4.5 and **Mesa 25.0.7 llvmpipe / LLVM 19.1.7** under an authenticated Xvfb display. The virtual desktop was 1440 × 900; the captured game viewport was 1280 × 800. Audio used the Dummy driver and `--mute`, so these images provide no audio verification.

The final Squad, Light, Strings, Chimes and Manual runs used `LIBGL_ALWAYS_SOFTWARE=1`, `LP_NUM_THREADS=1`, `MESA_GLTHREAD=false` and process affinity restricted to CPUs 0 and 1. These settings constrained software-renderer resource use; no game rules changed. The Menu image had already completed successfully with the ordinary software-renderer thread configuration.

An earlier non-final rendering attempt was terminated under the constrained environment. It is not counted as successful evidence. The retained six views all completed with **exit code 0**. The retained final-run logs for Squad, Light, Strings, Chimes and Manual contained no `SCRIPT ERROR` or `ERROR:` entries. This is a rendering check, not a frame-rate or memory benchmark.

The final Squad, Light, Strings and Chimes compositions were recaptured after correcting fixture framing. The Light capture uses the apparatus code containing the carried-cell identity update, but, as recorded above, that small object label is not visible in this framing. Validation of identity changes belongs to the automated world regression checks.

## File integrity

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| menu.png | 308029 | `9be17a10309123294c979d7601d79f556bfb9dca4eaedeb7f9ea4d6709a4b669` |
| squad.png | 383189 | `a2018722e9b0b973e80358d42c24acbb0f416184fe7a8779c51a7c992ae0356f` |
| light.png | 370441 | `807c2332ef06bbcba93644737d024c85f30fd85c1cff2567660f7839c7abed01` |
| strings.png | 414987 | `dac23eb6c3723c98a58232271c0e02ef493d4b04ae90281648484d492f45cbe2` |
| chimes.png | 385047 | `f07515e99ef34d046309b318071d0828726e2d36f53f528af2fff37f051037cc` |
| manual.png | 438702 | `4b8bc93e89c9fa89c859e3615cb65fcbe7c89aa1a53bb60271069aa44d2fcfd0` |

The native captures support the documented presentation observations only. The deterministic rules, input interruptions, bot routes, rescue priority and release gates require their separate test results.
