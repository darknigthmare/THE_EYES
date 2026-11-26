# 13 — The Survivor Accord: local Squad and rescue

**Version 0.3.0 — published implementation.** The life/rescue domain,
physical world fixtures, three complete pressured Squad sessions, existing
Solo/Eye regression suites, and native-renderer inspection have passed their
recorded checks. The official v0.3 Windows archive has passed all nine native
headless mode/contract startup cases. Its own report identifies the exact source
build and archive; no v0.2 result is reused as evidence for this version. See the
[v0.3 verification record](../qa/V0_3_VERIFICATION.md) for evidence and limits.

## The playable promise

The Survivor Accord adds one human survivor and four AI teammates against the
AI Eye. The human moves through the existing observatory, participates in its
trials, gives simple orders, and can rescue an ally or receive a rescue. This
is a local five-survivor session controlled on one machine. It adds no network
lobby, remote human partner, split screen, new arena, or seventh trial.

Solo remains one human against the AI Eye with its existing Second Sight
recovery. The Eye seat remains one human Eye against four AI survivors with
its existing rules. The three contracts—First, Second, and Seeded Mix—retain
the same six trial subsets and three active seal slots. T20 The Gauntlet and
T06 Bridge of Illusions remain planned designs.

| Session entry | Participants | Recovery model |
| --- | --- | --- |
| Play Solo as a Survivor | One human survivor; AI Eye | Existing first-fall Second Sight timing room |
| Lead a Local Squad | One human survivor; four AI allies; AI Eye | One ally-assisted revival per survivor |
| Take the Eye's Seat | One human Eye; four AI survivors | Existing Eye-mode survivor lifecycle |

A single valid escape still wins for the team. An eliminated human can therefore
watch remaining allies and still receive the correct team-victory result if
one escapes. Five separate escape requirements would silently change the source
brief and are not introduced here.

## Five readable identities, four archetypes

The human chooses Veil, Tinker, Runner, or Keeper and uses the corresponding
primary identity. The four bots include one of every archetype. The bot whose
archetype matches the human uses the alternate identity from the existing
bible, avoiding duplicate names within the five-person roster.

| Archetype | Human / usual bot identity | Matching-human bot identity |
| --- | --- | --- |
| Veil | Mara Vale | Ivo Mercer |
| Tinker | Nadiya Sayegh | Tomas Venn |
| Runner | June Arlen | Elias Rook |
| Keeper | Ada Fen | Soren Bell |

These are labels for the procedural survivor bodies and their established kits.
They do not add selectable archetypes, completed character rigs, dialogue
performances, or eight finished art assets. A name remains attached to the same
actor through injury, rescue, elimination, and spectating.

## Orders and physical priorities

The order keys are physical keyboard bindings **B — Work**, **F — Follow**, and
**V — Hold**. The current order is visible beside the roster; each member also
reports its present task so that an override is understandable.

| Order | Intended ordinary behavior | Important boundary |
| --- | --- | --- |
| Work | Seek unfinished selected trials and perform their real physical interactions | Bots use the existing trial authority and world dispatcher; an order cannot award a seal |
| Follow | Navigate toward the human's current location | Followers still obey collision, traversable routes, and immediate survival responses |
| Hold | Save each bot's own position when changing to this order and remain near that point | It does not use one shared anchor at the human's feet; repeating the current order does not capture new points |

Immediate visible-shadow evasion, a viable rescue, and open-exit evacuation
take priority over all three orders.
Once escape opens, bots head toward the real exit even if their previous order
was Follow or Hold; a feasible rescue may take priority during that journey.
The commands express ordinary priorities, not permission to freeze an ally in
a lethal state or prevent the entire team from leaving.

The Squad self-preservation override reacts to a shadow within 4.5 metres only
when the actor has actual line of sight and the shadow's remaining warmup is
below 0.7 seconds. It considers sixteen nearby destinations 2.8 metres away,
rejects blocked or occluded destinations, and favors increasing distance from
the threat while retaining some progress toward the legitimate task. The bot
physically sprints to its chosen point; it does not teleport or obtain global
knowledge of hidden enemies. Evasion cancels any partial rescue. When the
immediate threat passes, ordinary planning resumes, including a fresh rescue
if viable. The roster reports **Evading a shadow** so this override is visible.
This bounded response improves survival without guaranteeing that every rescue
can succeed under pressure.

Work deliberately lets allies make real progress. The player's influence comes
from participating, routing the group, timing orders, providing support, and
responding to the Eye. Whether the bots leave enough meaningful decisions to
the human is a playtest question; autonomous completion is not to be hidden by
undocumented trial caps or fake teammate animations.

## First fall, rescue, and elimination

Every Squad actor follows the same life states: `active`, `downed`, and
`eliminated`. The human does not receive an additional Second Sight attempt in
this session. Each actor has at most one successful revival.

| Event | Squad result |
| --- | --- |
| First lethal fall | Enter downed state with a 35-second bleedout clock |
| Valid continuous rescue | Complete six continuous seconds before bleedout ends, while stationary within 1.8 metres and with clear physical sight |
| Rescue interrupted | Release the reservation and reset that attempt's progress to zero |
| Rescue completed | Return active with 35 health and five seconds of protection; consume the actor's single revival |
| Bleedout expires | Eliminate the downed actor |
| Lethal fall after revival | Eliminate immediately; no second down/revive cycle |
| No active rescuer remains | Eliminate remaining downed members and resolve the team wipe |
| Pause | Freeze bleedout and cancel partial rescue; resume requires a new continuous hold |

The shared life authority manages identities, states, deadlines, and exclusive
rescue reservations. The world validates real proximity, line of sight,
continuous held input or bot action, and any interruption before advancing a
rescue. Moving, jumping, releasing E, losing reach or sight, taking a hit,
visible-shadow evasion, and pause reset progress. A domain method call alone
does not establish that a helper can reach
through a wall. One helper cannot rescue several subjects simultaneously, and
several helpers cannot multiply the same six-second rescue. Reasserting the
same valid helper/subject pair during a hold does not restart its timer.

The no-active-rescuer rule resolves an otherwise unwinnable wait: if every
remaining member is downed or eliminated, nobody can perform the rescue. The
session ends through the ordinary match outcome rather than leaving the human
watching five independent bleedout clocks. Match-end and reset handling
clear reservations and reject later revival or objective mutations.

Carried objective ownership is released safely when a carrier falls or
is eliminated. Required relics and the shared ember remain obtainable, and
mote handling follows its existing physical release path. A rescue restores an
actor; it cannot restore consumed cargo or duplicate a completed placement.

## Keeper support and shared objective work

The Squad extension of Keeper's **Mend** selects the most injured eligible
active squad member, **including the Keeper themself**. Allies must be within
four metres and clear line of sight. Equal health favors self; stable actor
order breaks a tie between allies. This prevents a critically hurt Keeper from
ignoring their own condition to heal a slightly injured neighbor. The existing
30-health amount, 100-health cap, and 35-second cooldown remain the starting
prototype values. Downed actors are ineligible; healing does not substitute for
the six-second rescue or replenish a spent revival. The integrated world
fixtures verify physical target validation, wall occlusion, self/ally ties,
amount, and cooldown. Solo self-healing remains unchanged.

Multiple Squad members can work on the existing objective system, but a shared
mechanism must advance once per physics frame. **Clockwork Relay's combined
Squad contribution is capped at 1.8 times the base rate**, rather than applying
a separate full frame of progress for each helper. The Solo contribution rules
remain unchanged. Other trials retain their identity checks, pair banks,
explicit final controls, and permanent seals. Five actors do not create extra
relic copies, extra embers, or five simultaneous incompatible Clock turns.

Tinker's Overclock remains advice for a physical Clock operation, and its Relay
contribution remains subject to the Squad aggregate cap. Veil and Runner keep
their existing stealth and movement functions. No class is required to perform
a rescue.

## Roster, rescue feedback, and spectating

The right HUD contains five compact rows with name, archetype, current state,
health or bleedout time, rescue progress, and task. The player's row is labelled
YOU. Downed status uses text and numbers as well as color. The roster hides while
Tab displays the existing map, so the two surfaces do not cover one another.
The active order and B/F/V legend stay with the roster. A contextual prompt
explains holding E to rescue a nearby downed ally.

After human elimination, **1–4 or the mouse wheel** selects a remaining ally's
actual camera position. This is observation of surviving teammates, not a
free-flying Eye view or a replacement controllable body. A team win is labelled
**YOUR SQUAD ESCAPED**, which remains truthful when the human did not personally
survive. The manual distinguishes Squad rescue from Solo Second Sight.

The interface keeps its existing five-argument `start_requested` signal and
emits `squad` as the session mode. `show_game(eye_mode)` remains unchanged.
`set_squad_enabled(bool)` controls the additional presentation, and
`update_squad(Dictionary)` receives order, leader state, member records, and
rescue text. Its `revive_progress` values are normalized from zero to one; the
life authority stores seconds and the world converts them for display.

## Local verification and published release evidence

The current implementation has passed these separate checks in Godot 4.7.2:

| Evidence | Observed result | What it establishes |
| --- | --- | --- |
| [Squad life authority](../../game/scripts/squad_state.gd) | 26 domain cases / 120 assertions / zero failures | Life states, deadlines, exclusive rescue pairs, one recovery, wipe and reset |
| [Physical Squad fixtures](../../game/tests/test_squad_world.gd) | 23 cases / 234 assertions / zero failures | Actual range, walls, interruption, pause, abilities, orders, spectator cameras and shared Relay updates |
| Existing four assertion suites | 72 cases / 2,420 assertions / zero failures | Director, original world, six-trial authority, and Second/Mix physical-world regression |
| Existing two Solo routes | First 267.93 s; Second 324.17 s, both successful | Normal-input completion against the active Story Eye; prior Second Sight route remains valid |
| Interface checks and native frames | Five-row states, map exclusion, team results, menu, rescue and spectator presentation inspected | Scoped API and actual renderer evidence, not a performance benchmark |

The six assertion suites together account for **121 cases and 2,774 assertions,
with zero failures**. Full-route scenarios are additional checks and are not
included in that assertion total. Existing First/Second and all eight Mix bot
mappings retain their prior verified outcomes. Exact per-suite reports and
limits are recorded in [the v0.3 QA report](../qa/V0_3_VERIFICATION.md).

The physical rescue fixture stages one downed human and sends a real AI along
a nine-point AStar path. It travels **7.64 metres**, then completes the rescue;
travel plus hold takes **7.50 simulated seconds**. The actor receives 35 HP and
five seconds of protection once. This is an isolated staged rescue with normal
movement and world validation, not an entire match. Separate physical checks
verify occluded/out-of-range rejection and all interruption causes, including
pause cancellation and frozen bleedout.

A main-scene physics test combines human and four-bot Relay contributions for
one second and observes **0.15 normalized progress**, matching the 1.8× cap.
A lone human still produces **1/12 progress per second**, with no extra decay
from an empty allied pass. This checks the actual shared update path rather
than only comparing constants.

### Complete Squad sessions

The normal-input driver completed all three Story/Keeper contracts using seed
271126, each issuing Follow, Hold and Work and obtaining all three seals:

| Contract | Simulated team-win time | Human HP | Team wound events |
| --- | ---: | ---: | ---: |
| First | 46.88 s | 33 | 4 |
| Second | 86.80 s | 20 | 6 |
| Seeded Mix | 46.72 s | 100 | 1 |

These runs use real movement, collision, legal trial interactions, ordinary
healing and the active AI Eye. The driver does not teleport actors, inject
wounds, reset health, set objective progress, or extend clocks. The allies can
complete work and produce the winning escape. **None of these final three
routes contained a down**; the domain and isolated world checks supply rescue
evidence. The driver knows the map and legal puzzle actions, so its times are
neither a novice playtest result nor proof of balance across all configurations.

Actual native-renderer captures show the [menu](../qa/v0.3/menu.png),
[five-person roster](../qa/v0.3/squad.png), [rescue](../qa/v0.3/rescue.png),
[spectator view](../qa/v0.3/spectator.png), and [manual](../qa/v0.3/manual.png).
The rescue and spectator scenes are deliberately staged presentation fixtures.
They establish legible states and controls, not a second full-playthrough claim.
The transient notice now has a dark backplate, and spectator UI identifies the
observed ally without advertising use of their ability.

### Records, published build and remaining qualification

The post-match `last_observance.json` ledger uses **schema 3**, preserving the
real `session_mode` and a `squad_summary` alongside seed, selected trials,
metrics and events. It does not supply a mid-match save or a complete replay.

The [official v0.3.0 release](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.3.0)
has passed all **nine native Windows headless startup combinations**: Solo, Eye
and Squad, each with First, Second and Mix. Its
[WINDOWS_SMOKE.json](https://github.com/darknigthmare/THE_EYES/releases/download/v0.3.0/WINDOWS_SMOKE.json)
uses schema 2 and records nine successful cases for the exact distributed
archive. The source build is `c0b95341f728affe06933be9835d7ac9ff55abf3`.

| Release evidence | Recorded value |
| --- | --- |
| [Build and release workflow](https://github.com/darknigthmare/THE_EYES/actions/runs/45874067936) | Run `45874067936`; passed |
| Linux build job | `140096569556` |
| Native Windows job | `140099982444` |
| Publication job | `140105343129` |
| Windows archive size | 39,079,274 bytes |
| Windows archive SHA-256 | `adcf90c809a99ab024af09439704437852f93eb70a96f4340014b349fdc1d820` |
| Smoke report SHA-256 | `eaeae2b794980bd844946cbb260fe9d6a3d916aaeedc8a5f9c3f224967b7dc95` |

[Feature verification](https://github.com/darknigthmare/THE_EYES/actions/runs/45873381917)
passed for source `cafae25145909f89b56c9c914650973934014105`.
[Main verification](https://github.com/darknigthmare/THE_EYES/actions/runs/45874067644)
passed for the published source build above. These identifiers keep the source
checks, executable and startup evidence traceable when later documentation
commits change the repository head.

The nine native startup cases do not establish an interactive graphical Windows
playthrough or hardware performance. Those checks, broad balance, online play
and compiled UE5 gameplay remain separate work. The UE5 handoff contains eight
importable CSV specifications and construction recipes; completed playable
Blueprint assets have not been authored or executed here.
