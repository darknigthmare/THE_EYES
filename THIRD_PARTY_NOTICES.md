# Third-party notices

This document identifies third-party components included in the prototype and its Windows export. Their licenses apply to their respective components. It does not select or change a license for Darknigthmare's original THE EYES project code, designs, procedural artwork or audio.

## Godot Engine

THE EYES uses **Godot Engine**, distributed under the MIT/Expat license. The Windows executable includes the engine runtime. The full engine license is provided in `licenses/GODOT_LICENSE.txt`; engine component copyright notices and license texts are in `licenses/GODOT_COPYRIGHT.txt`. In the source repository those files are in the top-level `licenses/` directory; the Windows package places them beside the game in its `licenses/` directory.

The copyright and license inventory is extracted from the actual build engine using `Engine.get_license_text()`, `Engine.get_copyright_info()` and `Engine.get_license_info()`. Its metadata records the engine version. The engine-source inventory can contain components that are not used by a particular platform export; keeping the complete inventory preserves the corresponding notices. The build helper regenerates these notices for the chosen engine rather than relying on an unrelated future version's text.

Official sources:

- [Godot Engine license](https://godotengine.org/license/)
- [Godot: complying with licenses](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)
- [Godot Engine license metadata API](https://docs.godotengine.org/en/stable/classes/class_engine.html)

## Fonts

The font files below are copied font binaries with project-local filenames; they are not original THE EYES typeface designs. Typeface identity and copyright are retained in the binaries and accompanying notices.

| Project file | Typeface | Applicable notice |
| --- | --- | --- |
| `game/assets/fonts/Interface.ttf` | Open Sans Regular | Google copyright; Apache License 2.0 |
| `game/assets/fonts/Readout.ttf` | DejaVu Sans Mono Book | Bitstream Vera-derived license and DejaVu public-domain changes |
| `game/assets/fonts/ObservanceSerif.ttf` | Liberation Serif Regular | Google/Red Hat copyright; SIL Open Font License 1.1 |

Source-repository notices are in `game/assets/fonts/`: `LICENSE_OpenSans.txt`, the complete `LICENSE_Apache-2.0.txt`, `LICENSE_DejaVu.txt` and `LICENSE_Liberation.txt`. The Windows archive includes readable copies in `licenses/fonts/` in addition to the fonts embedded in game resources.

The supplied distribution copyright files also describe Debian packaging files. Those packaging-script terms do not relicense the font binaries: the sections covering `Files: *` state the relevant font terms. No Debian packaging scripts are included as part of the game.

## Original prototype assets and references

The prototype's authored geometry, procedural materials, interface layout and synthesized game audio are project assets. Godot's own bundled third-party resources remain covered by its inventory. No character, scene, soundtrack or screenshot from Saw, Squid Game, Fall Guys or Dead by Daylight is bundled as a game asset; those titles appear as conceptual references in the supplied design discussion.

The UE5 folder is a project foundation and documentation; it does not redistribute Unreal Engine binaries or Epic sample/marketplace assets. A future UE5 distribution must carry its own actual component and asset notices.
