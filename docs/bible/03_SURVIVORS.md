# 03 — Survivors

## Roster structure

The production roster contains eight original characters distributed across four archetypes: **Veil** for stealth, **Tinker** for engineering, **Runner** for mobility, and **Keeper** for support. Character identity and role are related but not permanently locked; the initial production build may pair them for readability, while Custom mode can permit alternative training. The Godot slice uses archetype-level mechanics and does not claim that eight finished character models or narrative performances are present.

No role is a key required to open content. Every survivor can interact, carry, solve, revive, and escape. Specialists alter the cost or timing of those actions. Team composition should create plans without turning a new player into an unwanted character choice. Passive bonuses remain modest, and an active ability has an explicit visual tell for the Eye.

## Archetypes

| Archetype | Passive proposal | Active proposal | Cost and recovery | Counterplay |
|---|---|---|---|---|
| Veil | Reduced footstep noise while walking | **Held Breath:** briefly suppress movement noise while retaining normal visible silhouette | 5 seconds active; 35-second cooldown; sprint cancels | Eye can still see the survivor; machinery remains audible |
| Tinker | Faster repair and crank contribution | **Brace:** prevent one incomplete mechanism from regressing during a short interruption | 8-second duration; 40-second cooldown | Eye pressures the operator or changes target; no completed seal is affected |
| Runner | Larger stamina reserve | **Second Wind:** recover stamina and gain a short acceleration burst | 4-second duration; 45-second cooldown | Loud start cue, normal collision, no invulnerability |
| Keeper | Faster revive and better shared recovery | **Steady Hands:** restore a modest amount of health to self or nearby teammate | Limited charges replenished at earned checkpoints | Requires proximity and an interruptible channel |

Exact production values follow playtest evidence. Prototype abilities may be smaller versions; the HUD and release notes must describe the actual effect. The role selection screen presents a concrete action and limitation rather than an unqualified promise such as “invisible” or “immune.”

### Current prototype choices

The playable local slice selects four identities from the full roster. Its ability names and values are intentionally smaller than the cooperative production proposals above:

| Character / archetype | Prototype ability | Current effect |
|---|---|---|
| Mara Vale / Veil | Quiet Step | Movement noise ×0.15 and gaze gain ×0.25 for 5 seconds; 25-second cooldown; passive footstep noise ×0.55 |
| Nadiya Sayegh / Tinker | Overclock | Additional Relay work multiplier ×1.6 for 8 seconds; 25-second cooldown; base Relay contribution multiplier ×1.4 |
| June Arlen / Runner | Second Wind | Movement ×1.25 for 5 seconds; 22-second cooldown; larger 135 stamina reserve and 8 m/s sprint |
| Ada Fen / Keeper | Mend | Restore up to 30 health to self, capped at 100; 35-second cooldown |

The prototype's Keeper action is self-healing, not a completed teammate-targeting medical system. The procedural presentation does not yet constitute final models and animation sets for these named characters. The runtime module and verified release report take precedence if later tuning changes these values.

## 01 — Mara Vale, the surveyor

**Archetype:** Veil. Mara measured abandoned public buildings before her disappearance. She treats every room as a question about load, access, and what has been concealed. Her arrival memory ends at a doorway that did not appear on her drawing. She wants to prove that the Observance is a constructed place and therefore can be escaped.

Her silhouette is a narrow weathered field coat, a short utility satchel, cropped hair, and rolled sleeves. A white survey cord wraps the left wrist. Her palette is slate, chalk, and dull orange. Motion is economical: she checks a corner before moving her shoulders through it, keeps carried objects close, and uses two deliberate taps for a quiet teammate signal.

Mara's cooperative story is learning that measuring alone cannot establish whether a room is safe for someone else. Her private temptation offers a perfect map of her own exit route in exchange for withholding a useful clue. The default game never forces the player to accept. Her archive entries teach real spatial vocabulary and point out socket blind zones. Sample line: “That wall has moved. The scratches haven't.”

## 02 — Ivo Mercer, the stagehand

**Archetype:** Veil. Ivo spent his working life making public spectacles function without being seen. He recognizes pulley systems, trapdoors, and the psychology of an audience. The Carnival appears to know productions that were never performed. His goal is to find the person who kept leaving him cues before his disappearance.

He wears a dark work shirt, a tool belt with soft fabric loops, a patched shoulder, and a narrow red scarf tucked away from machinery. His larger shoulders distinguish him from Mara without implying different hitboxes. He points with an open palm and checks overhead rigging automatically. His humor is dry, protective, and brief during danger.

Ivo's story asks whether staying unseen is the same as refusing responsibility. His cooperative revelation occurs when he deliberately draws the Eye away from a novice. His temptation is a backstage passage that serves only him. Sample line: “Every performance has a place the audience isn't meant to look.”

## 03 — Nadiya Sayegh, the repairer

**Archetype:** Tinker. Nadiya maintained community machinery long past its intended life. She distrusts mechanisms that advertise elegance while hiding failure. The Observance frustrates her because its parts appear repairable but its purpose is not. She wants to leave the machinery safer for whoever comes next.

Her visual identity is a cropped ochre jacket, reinforced knees, close braided hair, and a small case of carefully ordered tools. Animations begin with testing resistance rather than immediately applying force. Her ability tell is a visible brace clipped to a mechanism and a short mechanical ratchet sound. These reads must remain clear in low light.

Nadiya's narrative conflict is the temptation to fix a hostile system instead of escaping it. Her best cooperative moments involve teaching another character rather than doing every task herself. A lore unlock lets her identify where the institution has copied human repairs without understanding why they were made. Sample line: “It can be maintained. That doesn't make it worth keeping.”

## 04 — Tomas Venn, the horologist

**Archetype:** Tinker. Tomas repaired public clocks and recorded the small disagreements between them. He understands linked mechanisms but struggles when other people refuse predictable roles. The Clock Room reproduces a sound from his childhood that no surviving clock should make.

He wears a long vest over a pale shirt, fingerless work gloves, and a flat toolkit across the lower back. His distinctive feature is a broken watch on a chain that never becomes a noisy physics prop. His posture is upright until danger, when he moves with unexpected urgency. His interaction animation pauses to count the mechanism's rhythm.

Tomas learns to accept redundancy and imperfect coordination. His temptation is an exact prediction that is only valid if he abandons another survivor. The player may decline without losing required information. Sample line: “A clock can be correct and still be late for you.”

## 05 — June Arlen, the courier

**Archetype:** Runner. June knows cities by the routes that official maps ignore. She is comfortable with motion and uncomfortable with waiting. The institution repeatedly offers her a shorter route whose destination is hidden. Her arc turns speed into responsibility: arriving first can mean holding the exit for others.

June wears a faded green courier shell, a close chest harness, worn trainers, and one taped sleeve. The silhouette is compact and forward-leaning. Sprinting has readable arm motion and a distinct breath rhythm; the active ability produces an exhale and a brief harness-light pulse, not an unreadable teleport.

Her cooperative revelation concerns someone who followed a route she recommended. She keeps a record of safe shortcuts in the hub rather than gaining a numerical speed advantage through story progression. Sample line: “I can get there. Tell me what needs to arrive with me.”

## 06 — Elias Rook, the rescue climber

**Archetype:** Runner. Elias performed difficult rescues in structures that were already failing. He is accustomed to declaring a route unsafe and finding another. The Void challenges him by making distance appear emotionally rather than physically consistent. He wants everyone to stop calling survival luck.

His silhouette includes a broad climbing harness, a short reinforced coat, heavy gloves, and a coil of inert rope. The rope is a visual identity item; it is not advertised as a usable tether unless the mechanic exists. He moves carefully near ledges and plants his feet before carrying weight. His calm speech becomes more precise when the team panics.

Elias's conflict is the belief that he must personally absorb every risk. His story rewards delegating a rescue. His temptation offers a guaranteed solo crossing while closing a secondary route; the offer's consequence is explicit. Sample line: “Three points of contact. One person watching the next step.”

## 07 — Ada Fen, the night nurse

**Archetype:** Keeper. Ada has spent years noticing the small changes that precede a crisis. She reads the Eye through pauses, dilation, and attention. She rejects the institution's claim that suffering reveals a person's true value. Her objective is practical: restore enough stability for people to choose again.

Ada wears a dark blue overshirt, a compact medical pouch, sturdy trousers, and a pale band around one forearm. Her shape language is rounded and grounded. Revive animation is brisk and competent. Healing VFX use a subtle bandage or steady light, with no supernatural implication unless that version of the ability is explicitly introduced.

Her arc confronts exhaustion and the expectation that she must always be available. A cooperative reveal lets another survivor take over her role for a moment. Her temptation trades her own restored health for abandoning a record of someone else's survival, rather than secretly damaging a teammate. Sample line: “You can be afraid and still do the next thing.”

## 08 — Soren Bell, the community organizer

**Archetype:** Keeper. Soren has no miraculous skill. He is good at recognizing when people lack the information to help one another. He remembers a room full of people who agreed on a rule without noticing who had been excluded. The institution treats him as especially inconvenient because he repeats instructions in plain language.

He wears a weathered burgundy jacket, layered practical clothing, and a small notebook attached with a fabric loop. His silhouette is tall and slightly loose, with expressive hands. His support animation begins by making eye contact with a teammate. He uses names in dialogue when the situation permits, reinforcing personhood against the assigned numbers.

His story challenges the urge to treat consensus as proof of fairness. His temptation gives him control over a group decision without requiring consultation. Sample line: “Wait. Does everyone know what happens if we pull this?”

## Animation and readability requirements

Every finished character needs idle, walk, sprint, crouch idle/move, start/stop, jump, landing, interaction, carry, drop, hurt, downed, crawl, revive, rescued, capture, escape, and defeat states. The prototype can use procedural motion; production cannot label a single static model as this full animation set. The asset catalogue tracks each required state separately.

Characters share collision and reach conventions unless a mechanic explicitly changes them. Cosmetic height is normalized around interaction anchors so that one costume does not gain visibility advantages. Team identification combines name, icon, silhouette, and optional outline. Blood, dirt, or darkness must not obscure the state indicator needed for rescue.

Dialogue is contextual and rate-limited. A survivor does not repeat an urgent line on every frame of a hazard overlap. Automatic callouts report facts the character can perceive. Character conversations yield to trap warnings and teammate voice. Subtitle settings preserve speaker names and spatial context.

## Roster acceptance

All four archetypes must finish every mandatory trial in a solo-adjusted practice configuration. A team of identical archetypes must remain viable in Custom. Ability effects must be reversible through normal expiry and correctly cleared on rescue, respawn, and rematch. Character descriptions must match actual mechanics for the build. Narrative content remains optional to the competitive loop, and no lore unlock grants an unadvertised combat advantage.
