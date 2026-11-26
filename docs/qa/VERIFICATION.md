# Verification — THE EYES 0.1.0

Verified on **26 November 2026** using the real **Godot
4.7.2.stable.official.ed1daf0bf** engine. This report describes the current
Godot prototype and explicitly separates production designs from executable
evidence.

## Results

| Gate | Evidence | Result |
| --- | --- | --- |
| Project import and startup | Actual project/resource import and headless scene execution | Pass |
| Match authority | 27 GDScript cases, 125 assertions | Pass, zero failures |
| World/physics integration | 6 cases, 60 assertions, real ray queries and CharacterBody3D motion | Pass, zero failures |
| Physical bot completion | Four normal survivors navigate, collect, deliver, solve, charge and escape | Pass, 52.18 simulated seconds |
| Survivor completion | Story/Keeper, normal movement and interactions, active Eye AI | Pass, 267.93 simulated seconds |
| Native 3D rendering | Godot Compatibility renderer, OpenGL/Mesa llvmpipe, virtual X display | Actual rendered screenshots, visually inspected |
| Windows export | Official matching export template; error-free Godot export; PE32+ AMD64 headers; ZIP CRC verification | Export/package verified; Windows execution pending |
| Design catalogue | JSON parse, unique IDs, all 25 original source trial titles, three selected prototype trials | Pass |
| Documentation | Relative links, prototype/production distinctions and runtime constants reviewed | Pass |
| Unreal foundation | Descriptor JSON and CSV tables validated | Construction foundation only; Unreal Editor not run |

The domain and world suites provide **185 assertions**. They execute production
GDScript, not a separately reimplemented rules model. Commands and detailed
coverage are in [the test guide](../../game/tests/README.md).

## Complete match evidence

### Four physical survivors

The Eye-mode route leaves the human Eye looking outward and makes no power
inputs. Four unmodified AI survivors move using collision and the normal
navigation grid. They consume three distinct motes, complete the Echo sequence,
charge the Relay, reach the real doorway and hold the escape interaction.

No actor is teleported along this route. Health, speed, time and objective state
are not boosted. The run completes in **52.18 simulated seconds**. This proves
the bot objective loop and physical route are connected; it does not establish
balance against an expert human Eye.

### Survivor against active Eye AI

The informed input driver controls a Keeper on Story difficulty. It uses the
normal movement inputs, steers the view, walks the map, collects and delivers
each mote, observes the Echo pattern, sends the same symbol handler used by
keyboard input, holds the Relay and holds the exit. The Eye AI remains active.

The final run escapes in **267.93 simulated seconds**, at **86 vitality**, with
**two gaze wounds**, **one ordinary cooldown-limited Keeper heal**, and **no
Second Sight activation**. There are no test teleports, health overrides, time
extensions, speed multipliers or forced objective completions.

The driver knows the map and puzzle state and deliberately takes cautious cover
detours. This is reproducible completion evidence, not a novice usability study,
a difficulty certification, or an exact replay guarantee. Standard/Ruthless
survivor completion has not been certified by this route.

## Bugs corrected before delivery

- **Bot interaction reach:** the former arrival tolerance could halt a mote
  carrier just outside delivery range. The corrected tolerance is covered by
  the full physical bot run.
- **Cover selection:** a point outside the current view cone is not necessarily
  behind cover. Safe-point selection now checks actual geometry occlusion.
- **Carried noise:** sprinting with a mote gives a temporary audible location
  clue; it does not directly add gaze through walls. A regression assertion
  guards this rule.
- **Story pressure:** the live completion attempt motivated slower Story gaze
  accumulation/tracking and less aggressive mark timing. A socket change has
  a 0.85-second gaze acquisition warning.
- **Echo actor timers:** opening the puzzle locks movement while keeping actor
  timers active; it cannot freeze a brief damage immunity into permanent safety.
- **UI layout:** compact bars use their intended dimensions; manual text is
  wrapped within its columns and does not overlap the neighboring instructions.
  Newly visible panels refresh their text drawing so headings and button labels
  appear reliably alongside the body text.
- **Audio cleanup:** shutdown stops playback before the engine closes; headless
  tests do not allocate looping audio.

## Rendered evidence

These are screenshots captured directly from Godot, not concept images or web
mockups:

| Screenshot | Inspection purpose |
| --- | --- |
| [Menu](menu.png) | Role selection, archetype/difficulty/seed choices, actual arena background |
| [Survivor](survivor.png) | First-person chamber, trial station, compact HUD and controls |
| [Eye](eye.png) | Fixed socket perspective, influence, cooldowns and sight-filtered map |
| [Field manual](manual.png) | Two readable instruction columns and return control |
| [Echo trial](echo.png) | Staged inspection of sequence observation, symbol buttons and the live surrounding HUD |

The capture helper is [capture_ui.gd](../../game/tests/capture_ui.gd). It requires
a real display/renderer. Any staged UI inspection is labelled in its source;
it is not substituted for the separate physical completion tests. Software
rendering here does not provide a meaningful hardware FPS benchmark. The virtual
display reports that VSync cannot be changed; this is a display-driver warning,
not a gameplay assertion failure.

## Windows package and scope

The build uses the official Godot 4.7.2 Windows x64 release template. The
packager embeds game data, includes English/French quick starts and engine/font
notices, checks the PE64 format and every ZIP member, and writes SHA-256 values.
The executable is an unsigned development build. Its exact export metadata is
recorded in `BUILD_INFO.json` inside the downloadable Windows package.

A native Windows machine was not available to run the executable. No Windows
hardware, macOS, gamepad, ultrawide, online-network or production UE5 performance
claim is made. The project was not opened or compiled in Unreal Editor.

## Remaining production work

The shipped game is the complete local slice described in the README: one
arena, two roles, three trials, four archetypes, the simplified shadow, and one
recovery room. The other **22 trials**, the four complete production realms,
networked 5–7 versus 1 play, lobby/reconnect, final character rigs and animations,
production audio, controller/remapping, progression and complete UE5 assets are
planned work. Their specifications and acceptance criteria are in the bible.

