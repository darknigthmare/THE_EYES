# THE EYES — asset, animation, audio and rendering production

**Status:** art direction and production specification. The Godot prototype uses its committed procedural/primitive environment and effects to demonstrate play. The catalogues below define assets to produce for the polished game; they are not a claim that every listed model, texture, animation or sound is already present. Count actual files from an asset manifest before reporting a completed pack.

## 1. Visual identity

The First Observance is an impossible ceremonial machine: a theatre, a testing chamber and a place of worship assembled around an intelligence that can look but cannot walk. The Eye should appear physically anchored, with a socket and mechanical/organic attachments that explain why it observes from a fixed point. Its movement between sockets reads as an interruption of reality, followed by a new opening of the lid.

The original visual language combines worn pale mineral surfaces, blackened metal, fine brass registration marks, amber observation light and restrained cyan objective light. A survivor's route is readable from silhouette and value before it is readable from detail. Horror comes from being watched, the sound of a mechanism preparing and the visible cost of crossing an exposed space.

The cited inspirations inform tension, asymmetry and challenge structure. Produce original costumes, masks, typography, arenas, traps and audio signatures. Do not import film characters, recognizable franchise props, copied game HUDs or promotional imagery as production assets. Each item must have its own silhouette and material history.

### 1.1 Semantic palette

| Meaning | Visual language | Redundant cue |
| --- | --- | --- |
| Safe navigation/available objective | Desaturated cyan edge and stable horizontal pattern | Objective glyph and readable label |
| Eye attention | Amber-to-copper directional sweep | Exposure meter, eyelid icon, directional sound |
| Imminent trap | Bright bounded perimeter, inward-moving ticks | Mechanical rise and hazard label |
| Active harmful interval | Filled striped region and raised geometry | Impact sound plus persistent hurt-zone shape |
| Completed seal | Warm white/cyan fixed light, enclosed glyph | Explicit Complete state |
| Illusion | Slightly broken registration and delayed reflection | Discoverable pattern rule; never color alone |
| Unavailable/cooling | Dim material and empty segmented ring | Remaining seconds or reason text |

Pure darkness is not a puzzle unless the player has a clear tool, a reliable clue and a recoverable mistake. Keep gameplay silhouettes visible at the low-end graphics preset. Bloom may decorate a warning, but cannot be its only visible component.

## 2. Scale, axes and interchange

Author a source model once, then validate engine-specific imports. Godot recommends glTF 2.0 and supports `.glb` as a compact scene interchange format. [Source](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html). Retain editable source files for authored art, plus documented export settings; a compressed game-ready export is not a replacement for the source.

| Convention | Godot prototype | UE5 target |
| --- | --- | --- |
| Up axis | +Y | +Z |
| Camera/gameplay forward convention | −Z | +X |
| Imported character model convention | Verify source-facing axis; glTF models commonly face +Z | Import with explicit facing correction |
| Project scale | Treat one gameplay unit as one metre | 100 default centimetres per metre |
| Floor anchor | Bottom of collision/capsule at ground | Same physical reference after conversion |
| Socket orientation | Authored origin/forward | Converted and verified, not copied Euler values |

Godot distinguishes camera forward from an oriented model's front, so a character facing backwards after import should be fixed at the visual-root/import boundary rather than by reversing all movement code. Unreal uses a Z-up, left-handed system and defaults distance to centimetres. [Godot conventions](https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html), [Unreal coordinates](https://dev.epicgames.com/documentation/en-us/unreal-engine/coordinate-system-and-spaces-in-unreal-engine), [Unreal units](https://dev.epicgames.com/documentation/en-us/unreal-engine/units-of-measurement-in-unreal-engine).

Use a calibration scene containing a one-metre cube, a two-metre doorway, a standing survivor, an interaction target and all four Eye socket arrows. Confirm dimensions, normal direction, UV orientation, material colors and collision after each importer/pipeline change. Do not convert positions with a blind axis swap without testing handedness and rotation.

### 2.1 Proposed physical standards

These are first-pass art/layout dimensions to validate against the actual movement controller:

- Survivor standing height 1.75–1.90 m; collision independent of outfit bulk.
- Main shared corridor at least 2.4 m clear width; chokepoints must be deliberate and tested with the full survivor count.
- Standing cover at least 2.1 m high; crouch cover initially 1.1–1.3 m, adjusted to the actual eye/head samples.
- Ordinary doorway 1.4 m clear width and 2.3 m clear height; a major exit corridor at least 3 m wide.
- Interactable hand surface approximately 0.9–1.2 m above the floor with sufficient free standing space.
- Wall thickness begins at 0.2 m for the chamber kit, then increases where silhouette or lighting requires it.

A decorative doorway must align with an actual wall opening and traversable connection. No door actor floating in the middle of a room may claim to connect two sealed regions. Map layout review checks physical destination, floor height, sightlines, collision, navigation and narrative purpose together.

## 3. Characters and entities

### 3.1 The Eye

Build the entity as separate layers: sclera shell, iris disk, pupil/aperture, upper/lower lids, wet rim, mounting ring, socket interface, cables/tendons, and optional ceremonial frame. The iris needs enough depth/parallax to feel like an organism; it must not become a flat billboard viewed obliquely. Its look target is constrained by the legal socket aim, so the visible pupil and actual threat direction agree.

Required states: dormant; awakening; searching; target acquired; accumulating exposure; command windup; commanding; energy recovery; blink-out; socket-arrival; escape rage; victory; defeat/withdrawal. Transition durations must match gameplay timestamps. Rage can intensify breathing, lid tension and ring motion without changing collision or erasing the warning budget.

The Eye's command silhouette is more important than fine veins. The trap windup should have one unmistakable contraction and sound; summoning should have a different shape/cadence. Do not use random high-frequency strobing as a replacement for animation.

### 3.2 Survivor art direction

The gameplay archetypes have descriptive identities and distinct silhouettes. Final character detail is owned by the bible; these production notes support the four first-pass roles.

| Character/archetype | Silhouette/material cues | Gameplay readability |
| --- | --- | --- |
| Mara Vale — Veil | Narrow layered coat, matte fabrics, asymmetric scarf or collar | Crouched posture reads immediately; no exaggerated camouflage invisibility |
| Nadiya Sayegh — Tinker | Work apron, compact tool harness, rolled sleeves | Hands and carried items stay legible at machinery |
| June Arlen — Runner | Lightweight split jacket, reinforced footwear, open shoulder shape | Sprint acceleration and stamina fatigue clearly differ |
| Ada Fen — Keeper | Soft structured overcoat, small recovery pouch, broad stable stance | Rescue/healing actions are recognizable from a distance |

Avoid assigning role solely by color. The eyes, head shape, haircut and clothing should establish each original character without resembling a specific licensed protagonist. Preserve consistent body proportion and attach-point locations across outfits. A cosmetic cannot shrink the visible body or hide a carried objective to gain a competitive advantage.

### 3.3 Nightmare creatures

The first phantom is a tall folded silhouette, its limbs resembling incorrect perspective rather than a generic zombie. It unfolds during a clearly visible spawn period, moves with a measured searching rhythm and attacks with a brief planted lunge. Additional proposed families: Listener (sound-led pursuit), Mimic (delayed survivor gesture), Stitcher (temporary route pressure), and Witness (stationary auxiliary observation). Each family requires a separate behavior/readability contract before asset production.

A creature model is not an implemented enemy. Its deliverable includes rig, animation clips, collision, navigation dimensions, attack timing, sound cues, hit response, expiry and test encounter.

## 4. Modular environment production register

All rows in this section are **planned production assets**. The procedural slice may represent their function with simple geometry; that does not count as the finished model.

| ID family | Pieces | Requirements |
| --- | --- | --- |
| `ENV_FLOOR` | 2 m tile, 4 m tile, edge, drain, raised dais | Matching pivots/UV density; no hidden collision seams |
| `ENV_WALL` | Solid, slit, window, arch opening, corner, end cap | Thickness; explicit EyeVisibility profile; light-tight joins |
| `ENV_PILLAR` | Full pillar, broken pillar, crouch-cover block | Clear occlusion role and navigable clearance |
| `ENV_DOOR` | Frame, single leaf, double gate, slide gate | Hinge/slide sockets, open/closed collision states, threshold |
| `ENV_STAIRS` | Straight flight, landing, narrow stair, ramp | Step/ramp collision test and safe handrails |
| `ENV_RAIL` | Straight, corner, terminal, warning rail | No accidental snagging or exploitable gaps |
| `ENV_EYE_SOCKET` | Four frame variants, iris mount, shutter | Shared origin, scale and visual activation state |
| `ENV_MACHINE` | Gear cluster, flywheel, belt, crank, piston | Movable subparts with stable pivots; separate collision |
| `ENV_CABLE` | Hanging, bundled, wall conduit, connector | Decorative pieces ignore targeting where appropriate |
| `ENV_SIGNAGE` | Room placard, floor arrow, trial glyph plate | English text, high contrast, non-color identifiers |
| `ENV_EXIT` | Triple-seal gate, threshold, escape tunnel | Exact collision opening and behind-gate escape volume |
| `ENV_SKYVOID` | Distant architecture, suspended silhouettes, haze | Non-traversable background with bounded rendering cost |

### 4.1 Interactive props

| Asset | Movable parts | Required feedback |
| --- | --- | --- |
| Whisper mote and carry shell | Core, cage, handle | Available/carried/delivered states |
| Silent receiver | Three sockets, shutter | Individual accepted slots; rejected empty-hand prompt |
| Echo lectern | Glyph panel, four keys, projector | Teaching/response/error/completion |
| Relay console | Crank, work dial, checkpoint pawls | Work, release decay, protected checkpoint, seal |
| Spike floor | Warning border, retractable teeth | Safe/warning/harmful/recovery, synchronized collision |
| Flame vent | Valve, nozzle, grille | Distinct warming sound and escape-safe perimeter |
| Collapsing tile | Support latch, surface | Announced commitment window and recovery route |
| Locker/cover booth | Door, occupancy cue | Entry/exit, occupied state, nonblocking escape policy |
| Recovery station | Pad, lamp, resource slot | Eligible/ineligible/recovery in progress |
| Summon anchor | Folded frame, particle origin | Legal location, arrival warning, occupied/inactive |
| Seal assembly | Three detachable glyphs, gate linkage | Permanent recorded completion |
| Practice marker | Replay symbol and plaque | Clear separation from live match objective |

### 4.2 Four realm adaptations

**Twisted Carnival:** keep ritual machinery visible beneath layers of faded painted entertainment architecture. Distorted stalls, abandoned tickets, looping marionette rigging and a carousel supply scale cues. No copied clown face or recognizable amusement-park mascot.

**Labyrinth of Shadows:** heavy repeating panels with unique scars and numbering let players orient despite rearrangement. Wall shifts are mechanical events with end positions and safe recesses. “Infinite” atmosphere can be scenic; navigable topology remains finite and testable.

**Dollhouse:** oversized domestic forms use the same credible doors, floors and passage logic. Cloth seams, carved joints and mismatched scale imply a constructed world. Human-size access routes are visibly cut into oversized furniture rather than inexplicably clipping through it.

**Void of Despair:** exposed islands and floating architecture use strong silhouette, rails, depth markers and landing platforms. The void's emptiness must not erase the evidence needed to judge a jump. Falling recovery paths are authored, not arbitrary teleport destinations.

## 5. Materials and textures

Create reusable masters for painted metal, brass, stone/plaster, cloth, rubber, wet organic surface, glass and emissive glyphs. A material instance changes wear, roughness, tint and emission without duplicating the whole shading graph. Reserve unique high-resolution textures for objects that regularly fill the camera, such as the Eye and first-person hands.

Proposed texture targets: 2K for hero props/character material sets, 1K for smaller interactables, 512–1K tiling masks/decals where adequate, and 4K only for justified hero close-ups. These are production budgets to validate, not a mandate to upscale low-information assets. Keep a low-memory set and measure actual residency.

Pack data textures deliberately and record channel meaning. Do not import a roughness mask as sRGB color. Verify normal-map handedness in each engine's chosen import settings. Keep stylized scratches away from objective glyphs so wear never makes a puzzle unreadable.

Material parameters with gameplay meaning must be driven by replicated state: warning progress, trap phase, seal success, exposure indication. Purely decorative flicker may be local but should have bounded amplitude and a reduced-effects alternative.

## 6. Animation checklist

### 6.1 Survivor set

Produce and verify: idle/breathing; walk forward/back/strafe; sprint start/loop/stop; crouch idle/walk; jump start/apex/land; hard landing; carry idle/walk; pickup; deposit; interact tap; crank start/loop/release; glyph press; hit small/heavy; injured locomotion; downed idle/crawl; assist/revive pair; recover stand; eliminated; escape threshold; win/lose reaction. The player controller may use fewer clips in v0.1; track missing clips explicitly.

Each clip records loop status, root-motion policy, duration, contact frames, event windows and allowed interruption points. Do not let an animation notify be the sole authority for a critical interaction. Server rules decide when a deposit is accepted; animation presents that accepted action.

### 6.2 Eye and props

Eye clips: open, search sweep, fixation, mark contraction, summon dilation, trap squeeze, blink closed, reappear, rage start/loop, withdraw. Prop animations: gate unlock for each seal, gate open/close, receiver slot latch, Echo key depression, flywheel accelerate/decelerate, trap warning/deploy/retract and phantom unfolding.

Procedural pupil aim and mechanical gear rotation can remain parameter-driven. Keep those independent from fixed narrative clips so they respond to gameplay without abrupt resets. Event timings belong in an asset metadata sheet and a test scene beside the animation.

## 7. VFX and audio production

| Event | Visual | Audio | Accessibility counterpart |
| --- | --- | --- | --- |
| Eye acquires sight | Directional amber contour, exposure rise | Low inhaling chord | Meter and Seen text |
| Break line of sight | Contour relaxes, exposure decays | Breath recedes | Hidden/decay status |
| Trap warning | Bounded ring and moving tick marks | Mechanical tension ramp | Warning glyph and countdown |
| Mark accepted | Short iris pulse and status icon | Distinct two-part tone | Named status and remaining time |
| Summon windup | Ground folds inward at anchor | Backward fabric/metal sound | Anchor outline and arrival timer |
| Mote delivered | Receiver slot lights once | Short resonant latch | Delivered count |
| Echo teaching | One glyph illuminates at a time | Matched tone | Glyph number/symbol |
| Echo mistake | Panel resets to readable base | Low rejection click | Retry state, no full-screen flash |
| Relay checkpoint | Pawl locks and dial stops falling | Solid mechanical click | Checkpoint marker |
| Third seal | Gate outline opens toward exit | Large release and clear cue | Exit open objective |
| Time pressure | Slower spatial pulses, readable clock | Layer added to score | Numeric countdown |
| Match result | Stable end-state composition | Resolved motif | Result text and reason |

Use layers for ambience: architecture hum, distant mechanisms, occasional air movement, the Eye's near presence, and a sparse musical bed. Gameplay warning sounds have priority over decorative whispers. The music mix should create space before a trap cue instead of masking it with constant intensity.

Record sound source, creator/license, edit chain, loop points and intended loudness. Avoid clipping during stacked events. Provide separate master/music/effects/voice sliders. A future personal-whisper trial requires subtitles that preserve intended recipient scope and a replayable clue; visual clues cannot simply reveal every teammate's secret automatically.

## 8. Godot and UE5 rendering paths

### 8.1 Godot prototype baseline

The prototype's job is consistent navigation, legible warnings and responsive controls. Use its selected renderer and actual supported features. A deliberately staged scene can look atmospheric through material roughness, local lights, color grading and silhouettes without claiming a UE5 rendering technology is present.

If a future Godot visual branch enables SDFGI, budget and test it separately: official documentation restricts it to Forward+ and describes limitations for dynamic occluders/emissive surfaces. It is not available in the Compatibility renderer, and it should not be promised as an identical substitute for Lumen. [Source: SDFGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_sdfgi.html).

Prefer a reproducible reference capture with graphics options and version listed. Compare dark cover, the Eye looking down the arena, a warning trap with all effects, and an exit run. A beautiful empty arena does not prove readability during a busy encounter.

### 8.2 UE5 high-quality target

The proposed high-quality path uses Lumen for scene lighting/reflections where the target hardware and selected UE5 version support it, with a carefully budgeted shadow solution and temporal upscaling if needed. Start from an engine scalability preset and measure the actual game. Epic's performance guide explains Lumen's quality/performance tradeoffs; its platform targets are engine guidance, not measured THE EYES frame rates. [Source](https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-performance-guide-for-unreal-engine).

Use real light actors for critical warning/interaction illumination; a tiny emissive glyph alone may not illuminate surrounding geometry consistently. Diagnose light leaks with distance-field/surface-cache visualizers before increasing every quality setting. Thick closed architecture is preferable to thin overlapping planes. [Source: Lumen technical details](https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-technical-details-in-unreal-engine).

Nanite can be considered for suitably supported high-detail assets, particularly static environment pieces. It does not remove material, memory, instance or platform constraints. Verify the chosen engine version's supported asset/rendering features rather than assuming every transparent, deformed or animated asset follows the same path. [Source: Nanite](https://dev.epicgames.com/documentation/en-us/unreal-engine/nanite-virtualized-geometry-in-unreal-engine).

The essential trap silhouette, Eye direction and puzzle glyphs must remain clear in a fallback lighting/reflection preset. Optimize scenery before reducing the reliability of gameplay cues.

### 8.3 Initial performance budget, to measure

| Metric | Proposed target/test | Status |
| --- | --- | --- |
| Desktop presentation | 60 fps goal at a declared 1080p profile | Target, unmeasured for UE5 |
| Full-frame budget | Approximately 16.7 ms at that goal | Arithmetic budget, not achieved timing |
| Rules service | Fixed bounded intervals; no unbounded scene-wide searches every frame | Design rule |
| Eye visibility | Candidate prefilter, then limited traces at 5–10 Hz | Starting design budget |
| Socket evaluation | Event-driven or about 1 Hz | Starting design budget |
| Hazard VFX | Profile with every allowed simultaneous warning/active effect | Required stress scene |
| Memory | Record peak resident textures/meshes for each declared target machine | No fabricated cap claim |
| Loading | Measure clean boot and cold map load separately | Future benchmark |
| Network | Host plus full intended roster under lag/loss simulation | Future benchmark |

Record CPU, GPU, RAM, resolution, render scale, graphics settings, build type, engine version and map seed beside a performance result. Do not generalize a software-rendered screenshot or an editor on a powerful workstation into a minimum-spec guarantee.

## 9. Asset manifest and acceptance

Every finished asset gets an entry containing: stable AssetId; type; status; source path; runtime path; creator/provenance/license; original or derived classification; intended engine/import settings; dimensions/pivot; collision role; texture dependencies; animation/event timing; budget; verification date; reviewer; associated feature/trial; known limitations.

Use status values **Planned → SourceReady → Imported → Integrated → Verified**. A generated concept image can reach ConceptApproved but is not a rigged character. A model imported without collision is not Integrated. A trap animation without a warning/damage timing test is not Verified.

### 9.1 Acceptance checklist by category

- **Environment:** scale and seams correct; navigation works; no invisible barrier; cover matches Eye visibility; door physically leads somewhere; lighting preset fallbacks retain contrast.
- **Character:** facing/scale correct; skeleton imports; clip transitions and ground contact checked; carry/rescue sockets align; silhouette remains fair across outfits.
- **Interactive prop:** all states visible; collision changes match state; at least one full success and failure/recovery path; duplicate input does not duplicate reward.
- **VFX:** bounded lifetime; no orphan particles after restart; readable at reduced effects; no warning depends solely on flashing or color.
- **Audio:** licensed provenance; distinct gameplay meaning; clean loop; no clipping; sliders route correctly; visual alternative for required clues.
- **UI:** text fits target resolutions; readable at scaling; prompts match active role/device; keyboard focus correct; missing target/cooldown feedback clear.

Keep art evidence distinct from gameplay evidence: a turntable proves a model's appearance, a captured playthrough proves its integration, and a rule test proves the state transition. A delivery report should name the actual files and the evidence for their current status.

## v0.2 apparatus handoff: three alternate trials

The six-trial prototype pool reuses the existing three bays. It does not add a finished realm or an annex. The production art handoff must let each bay swap its trial without moving the shared exits, Eye sockets or essential cover. Keep each apparatus under one authored root with explicit interaction, visual, collision and cargo anchors; disabling an inactive apparatus must also disable its query/overlap registration.

| Apparatus | Required original assets | Readability and interaction criteria |
| --- | --- | --- |
| Memory Vault | Six relic silhouettes: Orb, Spire, Cube, Ring, Crown, Diamond; six pickup origins; four numbered cradles; four-target clue board; held/released/accepted states | IDs 0–5 remain stable. Distinguish shape, text and cradle number without relying on colour. Accepted objects visibly lock into the correct cradle; wrong attempts keep the held item. |
| Ritual Circle | Five vessel variants/markers; ember cradle and carry effect; clue display; banked/unbanked flame states; clear ground ring | Two/four checkpoints have distinct retained states. Five lit vessels transition to a separate eight-second ring hold cue. The 2.8 m radius supports movement while the hold continues. A departed ring resets hold feedback while leaving flames visibly complete. |
| Clock Room | Three discrete six-position hands; three physically distinct levers A/B/C; transform diagram; reset control; central seal press | Show lever coupling before an action. Each hand has an unambiguous zero and six ticks. Correct alignment highlights the central press; it does not falsely announce completion before confirmation. |

These are production requirements derived from the rule contract, not a completed exported art pack. The Godot candidate uses procedural forms. Keep finished asset counts and measured GPU cost in a later import/performance report. Validate text/silhouette readability at gameplay camera distance, in the arena's dark lighting and with low graphical settings. Critical clues and circle boundaries must survive reduced bloom, muted audio and colour-vision differences.

Animation state must follow accepted authority state: a denied pickup does not attach the relic, a vessel error restores only the unbanked flames, and a clock lever may animate after an accepted move while the discrete hand values remain authoritative. The sound design may distinguish pickup, wrong cradle, bank commit, ring occupancy break, clock step, reset and final press, but every required rule cue also has a visible form. No additional copyrighted reference assets are required for this direction.
