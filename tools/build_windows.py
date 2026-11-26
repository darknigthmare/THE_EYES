#!/usr/bin/env python3
"""Export and package THE EYES for Windows x64 using Python's standard library.

Run from any directory. An explicit --output must be an absolute directory.
Install export templates matching the chosen Godot version, or pass --template.
The preset is restored byte-for-byte even if export/packaging raises an error.
This verifies export output and its PE header; it does not execute Windows code.
ZIP ordering/timestamps are deterministic for identical payloads, but Godot's
exported executable itself is not claimed to be byte-for-byte reproducible.
"""

from __future__ import annotations

import argparse
import configparser
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
ERROR_LINE = re.compile(
    r"(?im)^\s*(?:SCRIPT\s+)?ERROR\s*:|\bParse Error\s*:|\bFailed to export project\b"
)

QUICK_START_EN = """THE EYES — THE TRIAL WORKSHOP
Windows x64 prototype v{version}

START
Extract the complete ZIP to a folder, then open THE_EYES.exe. Keep any supplied
data files beside the executable. Godot Editor is not needed to play this build.
The game is in English. Start in the Trial Workshop to learn one trial.
For your first match, choose Story / Keeper / First Observance, then select:
  PLAY SOLO AS A SURVIVOR — survive the AI Eye and escape.
  LEAD A LOCAL SQUAD — lead four AI allies against the AI Eye.
  TAKE THE EYE'S SEAT — control the Eye against four AI survivors.
  ENTER THE TRIAL WORKSHOP — practise one trial without an Eye or countdown.

THE TRIAL WORKSHOP
Choose one of nine trials, an archetype and a seed, read its steps and controls,
then start. Walk from the normal spawn to the real apparatus. Only the selected
trial is active. Cargo, puzzle rules, checkpoints and abilities work normally;
there is no Eye damage, time limit or escape after the selected seal.
Finish for a Workshop result, then retry the same seed, try another seed or
move to the next trial. Escape also offers retry and the trial selector.
An admitted start counts as an attempt; leaving early is not a completion.
The local notebook keeps attempts, completions and best times per archetype.
Practice results are separate from ordinary match victories.

SURVIVOR CONTROLS
WASD / the corresponding physical ZQSD keys on AZERTY, or arrow keys: move.
Mouse: look. Shift: sprint. Ctrl or C: crouch. Space: jump.
E: interact / hold at the Relay. Q: use the chosen archetype's ability.
Tab: show/hide map. Escape: pause or close a trial panel.
F1: open the Field Manual. Closing it during a session returns to pause.
Choose Resume when ready. Losing application focus pauses the session too;
returning focus never resumes automatically.

SURVIVOR SQUAD — YOU AND FOUR AI ALLIES
B: Work on objectives. F: Follow you. V: Hold position.
The first lethal fall downs a squad member for up to 35 seconds. Hold E near
a downed ally for six continuous seconds to rescue them with 35 health and
five seconds of protection. Interrupting a rescue resets its progress.
Each member has one rescue chance; their next lethal fall eliminates them.
If nobody remains active to help, the squad is lost. Keep someone standing.
Rescue requires clear sight within 1.8 metres; moving or taking a hit interrupts
it. Keeper restores 30 health to the most injured eligible active team member,
including self. Allies must be visible within four metres; self wins an equal-
health tie. The cooldown is 35 seconds. After elimination,
1–4 or the mouse wheel cycles the remaining allies' cameras. Read the roster
and contextual prompt for the current squad order, life state and rescue.

CONTRACTS — THREE SEALS PER MATCH
First Observance selects the original three trials below. Second Observance
selects Memory Vault, Ritual Circle and Clock Room. Third Observance selects
Light in the Darkness, Strings of Despair and Chimes of Doom. Seeded Mix selects
one of three trials per bay: 27 layouts from nine trials. A seed is stable
within this game version. Mix changed from v0.3 to v0.4; v0.5 retains that pool.

FIRST OBSERVANCE
Silent Countdown: collect and deliver three motes; use cover and quiet movement.
Trial of the Echoes: watch the four-symbol sequence, then answer with 1–4.
R replays the sequence; E leaves the panel. In matches the Eye remains active.
Clockwork Relay: hold E at the machinery; work is protected at checkpoints.
In a match, three seals open the exit. Reach it and hold E for 1.5 seconds
before the fresh escape countdown ends. Workshop ends at its selected seal.

THIRD OBSERVANCE
Light: carry each numbered cell to its matching refuge lamp. Hold E still for
two seconds to align. Charge drains only while carrying outside lit refuges;
return to the starting refuge or a lit lamp to refill. G returns cargo safely.
Strings: read the side and shape clues, then hold E at the correct rope for
two seconds. Wrong cuts trigger a three-second catch; earlier stages stay banked.
Chimes: read two four-note phrases, then walk between the numbered bells. E
strikes, R toggles the one shared damper at the nearby bell. A wrong note resets
only the current phrase and makes a loud sound. The first phrase stays banked.

SECOND OBSERVANCE
Memory Vault: remember four requested relics and deliver each to its matching cradle.
Ritual Circle: kindle the five vessels in order, then stay in the ritual circle.
Clock Room: E turns a lever forward; R reverses it. X resets at the centre.
Match all hands, then use E on the central press to submit. G returns cargo.
Read each station's instructions and the in-game manual for its controls.

EYE CONTROLS
Mouse: aim. 1–4 or mouse wheel: change fixed observation socket.
Left mouse: activate a targeted trap. Right mouse: mark a visible survivor.
Q: summon. Commands consume energy, have cooldowns and require legal targets.
Stop every survivor from escaping. Walls and cover interrupt line of sight.

SETTINGS AND RECORDS
Settings cover audio, reduced motion/vignette, look sensitivity/inversion and
survivor/spectator FOV. The Eye keeps its fixed authored view.
From v0.5, local data uses the stable THE_EYES application-data folder.
On Windows, open %APPDATA%\\THE_EYES in File Explorer. Old title-based folders
are left untouched and are not automatically imported.
settings.cfg stores options. last_observance.json (schema 3) stores an ordinary
match result; practice_records.json (schema 1) is the separate bounded notebook.
There are nine trial records with four archetype profiles each, without an
unbounded history. One practice_records.json.bak preserves the previous notebook
before replacement. It is loaded only if the primary is absent and the backup
is valid. An unreadable or unknown-schema primary is preserved without fallback.
An invalid existing backup also blocks saving. A failed save is reported even if the previous notebook was restored. Neither
record resumes an unfinished session. Key rebinding,
controller support and Eye training remain future work.

SCOPE
This is a local playable Godot prototype, not the completed UE5 multiplayer game.
Nine trials support four match contracts and individual Workshop drills.
The full 25-trial design and UE5 Blueprint foundation
are in the source repository. There is no online matchmaking in this build.

VERIFICATION AND CREDITS
SHA256SUMS.txt lists package file hashes. BUILD_INFO.json records export/format
checks. A PE header check does not prove execution on a Windows machine.
The official release also provides WINDOWS_SMOKE.json: its gate is 21 native
headless startups (12 ordinary mode/contract cases and nine practice trials).
Those startup checks do not replace a graphical Windows playthrough.
See THIRD_PARTY_NOTICES.md and licenses/ for engine and font attributions.
Source: https://github.com/darknigthmare/THE_EYES
"""

QUICK_START_FR = """THE EYES — THE TRIAL WORKSHOP
Prototype Windows x64 v{version}

DEMARRER
Extrais toute l'archive ZIP dans un dossier, puis ouvre THE_EYES.exe. Conserve
les éventuels fichiers de données à côté de l'exécutable. L'éditeur Godot n'est
pas nécessaire pour jouer. Le jeu est en anglais. Commence dans The Trial
Workshop pour apprendre une épreuve ; choisis Story / Keeper / First Observance
pour ta première partie contre l'Œil.
  PLAY SOLO AS A SURVIVOR : joue un survivant face à l'Œil contrôlé par l'IA.
  LEAD A LOCAL SQUAD : dirige quatre alliés IA face à l'Œil contrôlé par l'IA.
  TAKE THE EYE'S SEAT : incarne l'Œil face à quatre survivants contrôlés par l'IA.
  ENTER THE TRIAL WORKSHOP : apprends une épreuve sans Œil ni compte à rebours.

L'ATELIER DES ÉPREUVES
Choisis une des neuf épreuves, ta classe et une graine. Lis les étapes et les
commandes, puis démarre. Rejoins les vrais objets depuis le point de départ
habituel. Une seule épreuve est active ; elle conserve ses transports, règles,
paliers et pouvoirs de classe. Aucun dégât de l'Œil, délai ou sortie finale.
Une fois l'épreuve réussie, recommence la même graine, change de graine ou
passe à la suivante. Échap propose aussi la relance et le choix d'épreuve.
Un démarrage accepté compte comme tentative ; l'abandon n'est pas une réussite.
Le carnet local compte les tentatives et réussites, avec un meilleur temps
séparé pour chaque classe. L'atelier n'enregistre pas une victoire de partie.

COMMANDES SURVIVANT
ZQSD sur AZERTY / WASD sur QWERTY, ou flèches : déplacement.
Souris : regarder. Maj : courir. Ctrl ou C : s'accroupir. Espace : sauter.
E : interagir / maintenir au mécanisme. A sur AZERTY / Q sur QWERTY : capacité.
Tab : afficher/masquer le plan. Échap : pause ou fermeture du panneau d'épreuve.
F1 : ouvrir le manuel. Le fermer pendant une session ramène à la pause.
Choisis Resume pour reprendre. Changer d'application met aussi le jeu en pause ;
revenir dans sa fenêtre ne relance pas automatiquement la simulation.

ESCOUADE — TOI ET QUATRE ALLIÉS IA
B : travailler sur les objectifs. F : te suivre. V : tenir la position.
La première chute mortelle met un membre à terre pour 35 secondes maximum.
Maintiens E près d'un allié à terre pendant six secondes sans interruption
pour le relever avec 35 points de vie et cinq secondes de protection.
Toute interruption remet le secours à zéro. Chaque membre n'a qu'une chance
de sauvetage ; sa prochaine chute mortelle l'élimine. Si plus personne ne
reste actif pour aider, l'escouade est perdue. Garde quelqu'un debout.
Le secours exige une vue dégagée à moins de 1,8 m ; bouger ou subir un coup
l'interrompt. Keeper rend 30 points de vie au membre actif le plus blessé,
lui-même compris. Les alliés doivent être visibles à 4 m maximum ; à égalité,
Keeper se soigne lui-même. La recharge dure 35 s. Après
élimination, 1 à 4 ou la molette change la caméra de l'allié observé. Le HUD
affiche l'ordre, l'état de chaque membre et la progression des secours.

CONTRATS — TROIS SCEAUX PAR PARTIE
First Observance choisit les trois épreuves initiales décrites ci-dessous.
Second Observance choisit Memory Vault, Ritual Circle et Clock Room. Third
Observance ajoute Light in the Darkness, Strings of Despair et Chimes of Doom.
Seeded Mix choisit une des trois épreuves de chaque zone : 27 configurations.
La graine reste stable dans une même version. Mix a changé entre v0.3 et v0.4 ;
la v0.5 garde ce même ensemble de neuf épreuves.

FIRST OBSERVANCE
Silent Countdown : collecte et rapporte trois orbes, en utilisant les couverts.
Trial of the Echoes : observe les quatre symboles, puis reproduis avec 1 à 4.
R rejoue la séquence ; E quitte le panneau. En partie, l'Œil reste actif.
Clockwork Relay : maintiens E au mécanisme ; les paliers protègent ta progression.
En partie, les trois sceaux ouvrent la sortie. Rejoins-la et maintiens E
1,5 seconde avant la fin du nouveau délai. L'atelier finit à son seul sceau.

THIRD OBSERVANCE
Light : porte chaque cellule au refuge de même numéro, puis maintiens E deux
secondes immobile. La charge baisse seulement en portant hors des refuges ;
rejoins le refuge initial ou une lampe allumée pour recharger. G restitue la cellule.
Strings : lis les deux indices (côté et forme), puis maintiens E deux secondes
près de la bonne corde. Une erreur bloque trois secondes ; les paliers restent acquis.
Chimes : lis deux phrases de quatre notes et rejoins les cloches numérotées.
E frappe ; R déplace ou enlève l’unique sourdine. Une fausse note réinitialise
seulement la phrase actuelle et fait du bruit. La première phrase reste acquise.

SECOND OBSERVANCE
Memory Vault : retiens les quatre reliques demandées et livre-les aux bons socles.
Ritual Circle : allume les cinq récipients dans l'ordre, puis reste dans le cercle.
Clock Room : E avance un levier, R l'inverse ; X réinitialise au centre.
Aligne les aiguilles, puis valide avec E au centre. G restitue l'objet porté.
Lis les instructions de chaque poste et le manuel du jeu pour ses commandes.

COMMANDES DE L'ŒIL
Souris : viser. 1 à 4 ou molette : changer de point d'observation fixe.
Clic gauche : activer un piège ciblé. Clic droit : marquer un survivant visible.
A sur AZERTY / Q sur QWERTY : invoquer. Les actions coûtent de l'énergie
et ont un temps de recharge.
Empêche tous les survivants de s'échapper. Les murs et couverts bloquent la vision.

RÉGLAGES ET CARNETS
Son, mouvements/vignette réduits, sensibilité/inversion et champ de vue du
survivant ou du spectateur se règlent depuis la pause. L'Œil garde sa vue fixe.
Depuis la v0.5, les données locales utilisent le dossier stable THE_EYES.
Sous Windows, ouvre %APPDATA%\\THE_EYES dans l'Explorateur. Les anciens dossiers
portant le titre du jeu restent intacts, sans importation automatique.
settings.cfg conserve les options. last_observance.json (schéma 3) conserve le
résultat d'une partie ; practice_records.json (schéma 1) est le carnet séparé
de l'atelier, avec neuf épreuves et quatre fiches de classe chacune. Il ne crée
pas un historique sans limite. practice_records.json.bak conserve une seule
copie précédente. Elle est chargée uniquement si le principal manque et si elle
est valide. Un principal illisible ou de schéma inconnu reste intact, sans
chargement de secours. Une copie invalide bloque aussi l'enregistrement.
Un échec est signalé même si le carnet précédent a été
restauré. Ces fichiers ne reprennent
pas une session interrompue. Touches personnalisables, manettes et entraînement
de l'Œil restent à ajouter.

CONTENU DE CETTE VERSION
Prototype Godot jouable en local. Neuf épreuves, quatre contrats et un atelier
pour apprendre chaque épreuve séparément sont disponibles. La bible complète
des 25 épreuves et la préparation UE5 entièrement en Blueprints sont dans le dépôt.
Le multijoueur en ligne et le jeu UE5 complet ne sont pas inclus dans ce prototype.

VERIFICATION ET CREDITS
SHA256SUMS.txt contient les empreintes des fichiers. BUILD_INFO.json décrit les
contrôles d'export et de format. Un contrôle PE ne prouve pas une exécution Windows.
La publication officielle joint WINDOWS_SMOKE.json : le gate exige 21 démarrages
natifs sans affichage, soit 12 cas mode/contrat et neuf entraînements.
Ce contrôle ne remplace pas une partie graphique complète sous Windows.
Les licences du moteur et des polices figurent dans THIRD_PARTY_NOTICES.md et licenses/.
Sources : https://github.com/darknigthmare/THE_EYES
"""

LICENSE_SCRIPT = """extends SceneTree
func _initialize() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("One output path is required")
        quit(2)
        return
    var info: Dictionary = {
        "version": Engine.get_version_info(),
        "godot_license": Engine.get_license_text(),
        "third_party_copyright": Engine.get_copyright_info(),
        "third_party_licenses": Engine.get_license_info()
    }
    var output: FileAccess = FileAccess.open(args[0], FileAccess.WRITE)
    if output == null:
        push_error("Cannot write engine notices")
        quit(3)
        return
    output.store_string(JSON.stringify(info, "\\t"))
    output.close()
    quit(0)
"""


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def read_project_metadata(project_file: Path = GAME / "project.godot") -> dict[str, str]:
    """Keep package names and provenance tied to the actual project version."""
    text = project_file.read_text(encoding="utf-8")
    section = re.search(r"(?ms)^\[application\]\s*\n(.*?)(?=^\[|\Z)", text)
    if section is None:
        raise RuntimeError("Project application section is missing")
    result: dict[str, str] = {}
    for key in ("name", "version"):
        match = re.search(r'^config/' + key + r'\s*=\s*("[^\n]*")\s*$', section[1], re.MULTILINE)
        if match is None:
            raise RuntimeError(f"Project config/{key} is missing")
        result[key] = json.loads(match[1])
    if re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?", result["version"]) is None:
        raise RuntimeError("Project version must be a safe semantic version")
    return result


def validate_windows_resource_versions(
    project_version: str, preset_file: Path = GAME / "export_presets.cfg"
) -> dict[str, str]:
    """Reject a stale Windows resource version before invoking the editor.

    Project prerelease labels stay in BUILD_INFO and the package name. Windows
    file/product resource versions use the numeric major.minor.patch.0 form.
    """
    presets = configparser.RawConfigParser(strict=True)
    presets.optionxform = str
    try:
        presets.read_string(preset_file.read_text(encoding="utf-8"))
        matches = [
            section for section in presets.sections()
            if re.fullmatch(r"preset\.\d+", section)
            and json.loads(presets.get(section, "name", fallback='""')) == "Windows Desktop"
        ]
        if len(matches) != 1:
            raise RuntimeError("Expected exactly one Windows Desktop export preset")
        preset = matches[0]
        if json.loads(presets.get(preset, "platform")) != "Windows Desktop":
            raise RuntimeError("Windows Desktop preset has the wrong export platform")
        components = [int(part) for part in project_version.split("-", 1)[0].split(".")]
        if len(components) != 3 or any(part < 0 or part > 65535 for part in components):
            raise RuntimeError("Project version cannot fit a numeric Windows resource version")
        expected = ".".join(str(part) for part in components) + ".0"
        result = {}
        for key in ("file_version", "product_version"):
            value = json.loads(presets.get(preset + ".options", "application/" + key))
            if value != expected:
                raise RuntimeError(
                    f"Windows {key} is {value!r}; project {project_version} requires {expected!r}"
                )
            result[key] = value
        return result
    except (configparser.Error, ValueError) as exc:
        raise RuntimeError(f"Invalid Windows export version metadata: {exc}") from exc


def source_provenance() -> dict[str, object]:
    """A source ZIP may have no Git metadata; report that instead of guessing."""
    if shutil.which("git") is None or not (ROOT / ".git").exists():
        return {"source_commit": None, "source_worktree_dirty": None}
    revision = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
        capture_output=True, text=True, check=False,
    )
    status = subprocess.run(
        ["git", "-C", str(ROOT), "status", "--porcelain", "--untracked-files=normal"],
        capture_output=True, text=True, check=False,
    )
    if revision.returncode != 0 or status.returncode != 0:
        return {"source_commit": None, "source_worktree_dirty": None}
    return {"source_commit": revision.stdout.strip(), "source_worktree_dirty": bool(status.stdout.strip())}


def verify_pe(path: Path) -> dict[str, object]:
    """Check DOS/PE signatures, AMD64 machine type and PE32+ optional header."""
    size = path.stat().st_size
    if size < 256:
        raise RuntimeError(f"Executable is too small: {path.name}")
    with path.open("rb") as source:
        if source.read(2) != b"MZ":
            raise RuntimeError(f"Missing DOS MZ signature: {path.name}")
        source.seek(0x3C)
        pe_offset = struct.unpack("<I", source.read(4))[0]
        if pe_offset < 0x40 or pe_offset + 26 > size:
            raise RuntimeError(f"Invalid PE header offset: {path.name}")
        source.seek(pe_offset)
        header = source.read(26)
        if header[:4] != b"PE\0\0":
            raise RuntimeError(f"Missing PE signature: {path.name}")
        machine = struct.unpack_from("<H", header, 4)[0]
        optional_magic = struct.unpack_from("<H", header, 24)[0]
        if machine != 0x8664 or optional_magic != 0x20B:
            raise RuntimeError(f"Expected Windows x64 PE32+ executable: {path.name}")
    return {"format": "PE32+", "machine": "AMD64", "bytes": size}


def run_checked(command: list[str], logs: list[str], *, timeout: int = 900) -> str:
    completed = subprocess.run(
        command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, encoding="utf-8", errors="replace", timeout=timeout,
        check=False,
    )
    logs.append(completed.stdout)
    clean = ANSI.sub("", completed.stdout)
    if completed.returncode != 0 or ERROR_LINE.search(clean):
        tail = "\n".join(clean.splitlines()[-35:])
        raise RuntimeError(f"Godot command failed (exit {completed.returncode}):\n{tail}")
    return clean


def write_runtime_notices(godot: str, destination: Path, scratch: Path, logs: list[str]) -> dict:
    """Use Godot's official Engine metadata; do not invent license inventories."""
    scratch.mkdir(parents=True, exist_ok=True)
    (scratch / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="THE EYES License Export"\n',
        encoding="utf-8",
    )
    script = scratch / "extract_licenses.gd"
    script.write_text(LICENSE_SCRIPT, encoding="utf-8")
    raw = scratch / "runtime_notices.json"
    run_checked(
        [godot, "--headless", "--path", str(scratch), "--script", str(script), "--", str(raw)],
        logs, timeout=60,
    )
    info = json.loads(raw.read_text(encoding="utf-8"))
    if not info.get("godot_license") or not info.get("third_party_licenses"):
        raise RuntimeError("Godot returned incomplete engine license metadata")
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "GODOT_LICENSE.txt").write_text(
        info["godot_license"].rstrip() + "\n", encoding="utf-8"
    )
    parts = [
        "GODOT ENGINE — THIRD-PARTY COPYRIGHT AND LICENSE NOTICES",
        f"Extracted from Godot {info['version'].get('string', 'unknown')} using Engine metadata.",
        "Source: https://godotengine.org/license/",
        "Method: https://docs.godotengine.org/en/stable/about/complying_with_licenses.html",
        "This engine-source inventory may include components not used by a particular export.",
        "It does not license THE EYES original code or artwork.",
        "", "COMPONENT COPYRIGHT NOTICES", "",
    ]
    for component in sorted(info["third_party_copyright"], key=lambda row: row["name"]):
        parts.extend(["=" * 72, component["name"], "=" * 72])
        for entry in component.get("parts", []):
            parts.append("Files:")
            parts.extend("  " + str(value) for value in entry.get("files", []))
            parts.append("Copyright:")
            parts.extend("  " + str(value) for value in entry.get("copyright", []))
            parts.extend(["License: " + str(entry.get("license", "")), ""])
    parts.extend(["", "FULL LICENSE TEXTS", ""])
    for name, license_text in sorted(info["third_party_licenses"].items()):
        parts.extend(["=" * 72, name, "=" * 72, license_text.rstrip(), ""])
    (destination / "GODOT_COPYRIGHT.txt").write_text("\n".join(parts) + "\n", encoding="utf-8")
    metadata = {
        "engine_version": info["version"],
        "method": "Engine.get_license_text/get_copyright_info/get_license_info",
        "source": "https://godotengine.org/license/",
        "components": len(info["third_party_copyright"]),
        "license_texts": len(info["third_party_licenses"]),
    }
    (destination / "GODOT_NOTICE_METADATA.json").write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8"
    )
    return metadata


def template_override(original: bytes, template: Path) -> bytes:
    text = original.decode("utf-8")
    sections = re.split(r"(?m)^(\[preset\.\d+\])\s*$", text)
    preset = None
    for index in range(1, len(sections), 2):
        if re.search(r'(?m)^name\s*=\s*"Windows Desktop"\s*$', sections[index + 1]):
            preset = sections[index][1:-1]
            break
    if preset is None:
        raise RuntimeError("Windows Desktop preset was not found")
    options = re.compile(r"(?ms)(^\[" + re.escape(preset) + r"\.options\]\r?\n)(.*?)(?=^\[|\Z)")
    match = options.search(text)
    if match is None:
        raise RuntimeError("Windows Desktop preset options were not found")
    replacement = "custom_template/release=" + json.dumps(template.as_posix(), ensure_ascii=False)
    body, count = re.subn(r"(?m)^custom_template/release\s*=.*$", lambda _: replacement, match[2])
    if count != 1:
        raise RuntimeError("Expected one custom_template/release entry in the Windows preset")
    return (text[:match.start(2)] + body + text[match.end(2):]).encode("utf-8")


@contextmanager
def export_preset(template: Path | None):
    preset = GAME / "export_presets.cfg"
    lock = GAME / ".godot" / "the_eyes_windows_export.lock"
    lock.parent.mkdir(parents=True, exist_ok=True)
    try:
        descriptor = os.open(lock, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError as exc:
        raise RuntimeError("Another Windows export holds the preset lock; finish that export first") from exc
    os.close(descriptor)
    original: bytes | None = None
    changed = False
    try:
        original = preset.read_bytes()
        if template is not None:
            updated = template_override(original, template)
            changed = True
            preset.write_bytes(updated)
        yield
    finally:
        try:
            if changed and original is not None:
                preset.write_bytes(original)
        finally:
            lock.unlink(missing_ok=True)


def write_hashes(directory: Path) -> None:
    files = sorted(path for path in directory.rglob("*") if path.is_file() and path.name != "SHA256SUMS.txt")
    lines = [f"{digest(path)}  {path.relative_to(directory).as_posix()}" for path in files]
    (directory / "SHA256SUMS.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_archive(package_dir: Path, archive: Path) -> None:
    epoch = int(os.environ.get("SOURCE_DATE_EPOCH", "315532800"))
    stamp = datetime.fromtimestamp(max(315532800, min(epoch, 4354819198)), timezone.utc)
    zip_stamp = (stamp.year, stamp.month, stamp.day, stamp.hour, stamp.minute, stamp.second)
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as result:
        for path in sorted(package_dir.rglob("*")):
            if not path.is_file():
                continue
            info = zipfile.ZipInfo(f"{package_dir.name}/{path.relative_to(package_dir).as_posix()}", date_time=zip_stamp)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            with path.open("rb") as source, result.open(info, "w", force_zip64=True) as target:
                shutil.copyfileobj(source, target, 1024 * 1024)
    with zipfile.ZipFile(archive) as check:
        damaged = check.testzip()
        if damaged is not None:
            raise RuntimeError(f"ZIP CRC verification failed for {damaged}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--godot", default="godot", help="Godot editor executable (default: godot on PATH)")
    parser.add_argument("--template", type=Path, help="Optional matching Windows x64 release export template")
    parser.add_argument("--output", required=True, type=Path, help="Absolute output directory (outside game/)")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    project = read_project_metadata()
    windows_versions = validate_windows_resource_versions(project["version"])
    package = f"THE_EYES_v{project['version']}_Windows_x64"
    provenance = source_provenance()
    if not args.output.is_absolute():
        raise RuntimeError("--output must be an absolute directory")
    output = args.output.resolve()
    if output == GAME.resolve() or GAME.resolve() in output.parents:
        raise RuntimeError("Build output must be outside game/ so it cannot be recursively exported")
    executable = shutil.which(args.godot)
    if executable is None:
        raise RuntimeError(f"Godot executable not found: {args.godot}")
    template = args.template.expanduser().resolve() if args.template else None
    if template is not None:
        verify_pe(template)
    output.mkdir(parents=True, exist_ok=True)
    logs: list[str] = []
    try:
        version = run_checked([executable, "--version"], logs, timeout=30).strip()
        if template is not None and (template.parent / "version.txt").is_file():
            expected = (template.parent / "version.txt").read_text(encoding="utf-8").strip()
            if not version.startswith(expected):
                raise RuntimeError(f"Godot/template version mismatch: {version} versus {expected}")
        with tempfile.TemporaryDirectory(prefix=".the-eyes-export-", dir=output) as temporary:
            work = Path(temporary)
            package_dir = work / package
            package_dir.mkdir()
            exe = package_dir / "THE_EYES.exe"
            notices = write_runtime_notices(executable, package_dir / "licenses", work / "notice-extraction", logs)
            with export_preset(template):
                run_checked(
                    [executable, "--headless", "--path", str(GAME), "--export-release", "Windows Desktop", str(exe)],
                    logs,
                )
            pe = verify_pe(exe)
            shutil.copy2(ROOT / "THIRD_PARTY_NOTICES.md", package_dir / "THIRD_PARTY_NOTICES.md")
            font_destination = package_dir / "licenses" / "fonts"
            font_destination.mkdir()
            for notice in sorted((GAME / "assets" / "fonts").glob("LICENSE_*.txt")):
                shutil.copy2(notice, font_destination / notice.name)
            if not (font_destination / "LICENSE_Apache-2.0.txt").is_file():
                raise RuntimeError("Required full Apache 2.0 font license is missing")
            (package_dir / "START_HERE_EN.txt").write_text(QUICK_START_EN.format(version=project["version"]), encoding="utf-8")
            (package_dir / "LIRE_EN_PREMIER_FR.txt").write_text(QUICK_START_FR.format(version=project["version"]), encoding="utf-8")
            build_info = {
                "project": project["name"],
                "project_version": project["version"],
                "windows_resource_versions": windows_versions,
                **provenance,
                "godot_version": version,
                "export_preset": "Windows Desktop",
                "template_sha256": digest(template) if template else None,
                "executable_sha256": digest(exe),
                "pe": pe,
                "verification": ["Godot exit code zero", "No Godot error diagnostics", "PE32+ AMD64 header"],
                "windows_execution_test": "Not performed by this build helper",
                "engine_notice_components": notices["components"],
                "engine_notice_license_texts": notices["license_texts"],
            }
            (package_dir / "BUILD_INFO.json").write_text(
                json.dumps(build_info, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8"
            )
            write_hashes(package_dir)
            archive = work / f"{package}.zip"
            write_archive(package_dir, archive)
            for source in sorted(package_dir.rglob("*")):
                if source.is_file():
                    target = output / source.relative_to(package_dir)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source, target)
            final_archive = output / archive.name
            os.replace(archive, final_archive)
            # Outer checksums additionally cover the ZIP; the inner manifest cannot hash itself.
            package_files = sorted(source for source in package_dir.rglob("*") if source.is_file() and source.name != "SHA256SUMS.txt")
            lines = [f"{digest(output / source.relative_to(package_dir))}  {source.relative_to(package_dir).as_posix()}" for source in package_files]
            lines.append(f"{digest(final_archive)}  {final_archive.name}")
            (output / "SHA256SUMS.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
            print(f"Exported: {output / 'THE_EYES.exe'}")
            print(f"Packaged: {final_archive}")
            print(f"ZIP SHA-256: {digest(final_archive)}")
            print("Verified export diagnostics, PE32+ AMD64 header and ZIP CRCs. Windows execution is a separate test.")
        return 0
    finally:
        (output / "build_windows.log").write_text("\n".join(logs), encoding="utf-8")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Build failed: {error}", file=sys.stderr)
        raise SystemExit(1)
