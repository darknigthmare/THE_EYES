class_name PracticeState
extends RefCounted
## One selected trial, with no match timer or result. World validation stays in
## the existing trial worlds; the workshop never substitutes solved puzzles.

const TrialSetRules = preload("res://scripts/trial_set.gd")
const TRIAL_IDS: Array[String] = ["silent", "echoes", "relay", "vault", "ritual", "clock", "light", "strings", "chimes"]
const MAX_SECONDS: float = 31536000.0

var trial_id: String = ""
var slot_id: String = ""
var seed: int = 0
var elapsed: float = 0.0
var active: bool = false
var completed: bool = false


func configure(p_trial_id: String, p_seed: int) -> bool:
	var slot: String = TrialSetRules.slot_for_trial(p_trial_id)
	if slot.is_empty() or not TrialSetRules.valid_practice_seed(p_seed):
		return false
	trial_id = p_trial_id
	slot_id = slot
	seed = p_seed
	elapsed = 0.0
	active = true
	completed = false
	return true


func step(delta: float) -> void:
	if active and is_finite(delta) and delta > 0.0:
		# This is a storage bound, never a deadline or a completion condition.
		elapsed = minf(MAX_SECONDS, elapsed + minf(delta, MAX_SECONDS))


func complete(p_trial_id: String) -> Dictionary:
	if not active or completed or p_trial_id != trial_id:
		return {}
	active = false
	completed = true
	return {"trial_id": trial_id, "slot_id": slot_id, "seed": seed, "elapsed": elapsed}


func snapshot() -> Dictionary:
	return {"trial_id": trial_id, "slot_id": slot_id, "seed": seed, "elapsed": elapsed, "active": active, "completed": completed}


static func entry(p_trial_id: String) -> Dictionary:
	for item: Dictionary in catalogue():
		if str(item.trial_id) == p_trial_id:
			return item
	return {}


static func catalogue() -> Array[Dictionary]:
	# Fresh values on every call keep UI edits from changing the shared catalogue.
	return [
		{
			"trial_id": "silent", "slot_id": "silent", "title": "Silent Countdown",
			"summary": "Carry three motes to the north-west altar, one at a time.",
			"instructions": [
				"Find a cyan mote in the arena and press E within reach to pick it up.",
				"Carry it to the north-west altar and press E to deliver it.",
				"Repeat with the two remaining motes. Each delivery stays banked.",
				"Use G if you need to drop your mote. Carrying and movement follow the normal match rules.",
			],
			"checkpoints": "Each of the three deliveries is permanent for this attempt.",
			"controls": "E pick up / deliver · G drop · Ctrl crouch",
		},
		{
			"trial_id": "echoes", "slot_id": "echoes", "title": "Trial of the Echoes",
			"summary": "Observe four symbols, then repeat their order at the north-east shrine.",
			"instructions": [
				"Approach the north-east shrine and press E to open its memory panel.",
				"Watch the four symbols. Use R to replay the sequence whenever you need it.",
				"Enter the same order with keys 1–4 or the symbol buttons.",
				"A wrong symbol resets the current sequence. E or Escape closes the panel.",
			],
			"checkpoints": "Complete all four symbols in one correct sequence.",
			"controls": "E open / close · 1–4 symbols · R replay · Esc close",
		},
		{
			"trial_id": "relay", "slot_id": "relay", "title": "Clockwork Relay",
			"summary": "Hold the southern relay and learn how its charge checkpoints work.",
			"instructions": [
				"Approach the southern relay and hold E while in reach.",
				"Keep holding until its charge fills. A normal survivor needs twelve seconds of active charge.",
				"Release E or move away to see unbanked charge decay; the one-third and two-thirds marks stay saved.",
				"Tinker's normal machinery advantage still applies. Notebook best times are kept per survivor archetype.",
			],
			"checkpoints": "Charge banks at one third and two thirds.",
			"controls": "Hold E charge · Release E stop · Q survivor ability",
		},
		{
			"trial_id": "vault", "slot_id": "silent", "title": "The Memory Vault",
			"summary": "Memorize the four relics and fill their matching north-west cradles.",
			"instructions": [
				"Read the north-west memory desk with E. For eight seconds, it shows the relic required by each of the four numbered cradles.",
				"Find that relic among the six on the southern shelves and pick it up with E.",
				"Return to the matching cradle and press E. You can carry only one relic at a time.",
				"Use the desk again to review the targets. A wrong deposit keeps the relic in your hands; G returns it to its shelf.",
			],
			"checkpoints": "Every correctly filled cradle stays filled.",
			"controls": "E read / pick up / deposit · G return relic",
		},
		{
			"trial_id": "ritual", "slot_id": "echoes", "title": "The Ritual Circle",
			"summary": "Carry the ember through five vessels, then remain inside the circle.",
			"instructions": [
				"At the north-east ritual, read the engraved vessel order and take the ember with E.",
				"Visit each vessel in that order and press E to light it. Correct pairs bank at two and four vessels.",
				"A wrong unlit vessel rolls back only unbanked progress and returns the ember. Take it again to continue.",
				"Once all five are lit, remain grounded inside the central ring for eight continuous seconds. Leaving resets only this final hold.",
			],
			"checkpoints": "Vessels bank at two and four. The final circle hold must be continuous.",
			"controls": "E take ember / light vessel · G return ember · Stay inside ring",
		},
		{
			"trial_id": "clock", "slot_id": "relay", "title": "The Clock Room",
			"summary": "Turn coupled hands to match the southern clock's visible target.",
			"instructions": [
				"Read the three target numbers at the southern clock. Hands wrap through positions 0–5.",
				"At a lever, E turns forward and R turns backward. A moves A+B, B moves B+C, and C moves C+A.",
				"Match all three hands to their targets, then press E at the centre to submit.",
				"Use X at the centre to restore the starting hands if you want to rethink the same puzzle.",
			],
			"checkpoints": "Hands keep their positions until you turn or reset them; submit validates the full pattern.",
			"controls": "E forward / submit · R reverse · X reset at centre",
		},
		{
			"trial_id": "light", "slot_id": "silent", "title": "Light in the Darkness",
			"summary": "Carry numbered cells through safe light and align three matching lamps.",
			"instructions": [
				"Pick up a numbered cell with E and bring it to the matching numbered lamp along the west side of the arena.",
				"Carried charge drains outside safe light. The starting refuge and lit lamps recharge it when visible and nearby.",
				"With charge remaining, stand still in reach of the matching lamp and hold E for two continuous seconds.",
				"Movement, lost reach or empty charge interrupts alignment. Recharge and start a fresh hold; G returns the cell to its source.",
			],
			"checkpoints": "Each aligned lamp stays lit and becomes another recharge refuge.",
			"controls": "E pick up · Hold E align while still · G return cell",
		},
		{
			"trial_id": "strings", "slot_id": "echoes", "title": "Strings of Despair",
			"summary": "Read the clue and cut the matching tagged rope through three stages.",
			"instructions": [
				"Read the current clue in the north-east bay: it names the left or right pair and a shape family.",
				"Inspect the four tags. Circle and Crescent are curved; Triangle and Diamond are angular.",
				"Stand still within reach of the matching rope and hold E for two continuous seconds to cut it.",
				"Release E before each new cut. A wrong rope causes a three-second catch; correctly completed stages stay banked.",
			],
			"checkpoints": "Three stages are banked separately. The clue and tags change after each correct pull.",
			"controls": "Read clue / tags · Hold E cut while still · Release between cuts",
		},
		{
			"trial_id": "chimes", "slot_id": "relay", "title": "Chimes of Doom",
			"summary": "Read and play two four-note phrases on the southern numbered bells.",
			"instructions": [
				"Visit the southern score and read the current four-note phrase. Its numbers match the four bells.",
				"Walk to each required bell and press E to strike it in order. Respect the short delay between strikes.",
				"R toggles the shared damper on the nearby bell. A correct damped strike is quieter; a wrong strike is always loud.",
				"A wrong note resets only the current phrase. Finish both phrases to complete the trial.",
			],
			"checkpoints": "The first phrase stays banked while you practise the second.",
			"controls": "E strike bell · R toggle damper · Read score nearby",
		},
	]
