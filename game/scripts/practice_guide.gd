class_name EyesPracticeGuide
extends RefCounted
## Authored instructions and public progress only. Never returns a puzzle answer.

const PracticeState = preload("res://scripts/practice_state.gd")


static func entry(trial_id: String) -> Dictionary:
	for row: Dictionary in PracticeState.catalogue():
		if row.trial_id == trial_id:
			return row.duplicate(true)
	return {}


static func snapshot(game, records: Dictionary) -> Dictionary:
	var session = game.director.practice
	var row: Dictionary = entry(session.trial_id)
	var state = game.director.trial_set
	var actor_id: int = game.player.get_instance_id()
	var heading: String = "READ THE STATION"
	var text_value: String = row.get("summary", "")
	match session.trial_id:
		"silent":
			heading = "DELIVER THE WHISPER" if game.player.carrying >= 0 else "FIND A WHISPER"
			text_value = "Carry it to the northwest desk and press E. Each delivered mote stays banked." if game.player.carrying >= 0 else "Approach a glowing whisper mote until its pickup prompt appears, then press E. Deliver three distinct motes."
			text_value += "\nDelivered: %d / 3." % game.director.motes_delivered
		"echoes":
			heading = "WATCH THE DEMONSTRATION" if game.echo_showing else ("REPEAT THE SYMBOLS" if game.echo_open else "REACH THE ECHOES")
			text_value = "Go to the northeast station and press E. Watch all four numbered symbols before answering."
			if game.echo_open:
				text_value = "The framed symbols are the demonstration. Wait until it finishes; the Eye is inactive in practice." if game.echo_showing else "Use the four numbered buttons or physical 1–4 keys. R replays the demonstration; E closes the panel. A wrong answer resets the current symbol sequence."
			text_value += "\nAccepted inputs: %d / 4." % game.director.echo_index
		"relay":
			heading = "CHARGE THE RELAY"
			text_value = "At the south wheel, hold E within reach. Progress banks at one third and two thirds. Release E or step away to see how unfinished work decays to the latest bank."
		"vault":
			heading = "DELIVER THE RELIC" if state.carried_relic(actor_id) >= 0 else "READ THE FOUR TARGETS"
			text_value = "Read the northwest desk with E, then retrieve a requested relic from a shelf. Each numbered cradle requires its own target."
			if state.carried_relic(actor_id) >= 0:
				text_value = "You are carrying a relic. Walk to its matching numbered cradle and press E. A wrong cradle leaves it in your hands; G returns it safely."
			text_value += "\nFilled cradles: %d / 4." % _filled_cradles(state.vault_cradles)
		"ritual":
			if state.ritual_index >= 5:
				heading = "STAY INSIDE THE RING"
				text_value = "All vessels are lit. Remain inside the northeast ring for eight continuous seconds. You may move within it; leaving resets this final hold.\nHeld: %.1f / 8 seconds." % state.ritual_hold
			else:
				heading = "CARRY THE EMBER" if state.ember_owner == actor_id else "READ THE VESSEL ORDER"
				text_value = "Read the northeast station, pick up the shared ember with E and visit the vessels in the engraved order. Correct pairs become permanent banks; G returns the ember.\nVessels: %d / 5; banked: %d." % [state.ritual_index,state.ritual_bank]
		"clock":
			heading = "ALIGN THE HANDS"
			text_value = "Inspect the target at the south clock. Walk to its three levers: E turns forward, R reverses. X at the centre resets. When the hands match, return to the central press and use E.\nLever moves: %d." % state.clock_moves
		"light":
			var cell: int = state.third.carried_cell(actor_id)
			heading = "ALIGN THE REFUGE" if cell >= 0 else "FIND A NUMBERED CELL"
			text_value = "Carry each numbered cell to the matching lamp along the west side. The starting refuge and lit lamps recharge your lantern."
			if cell >= 0:
				text_value = "Cell %d belongs to Refuge %d. Hold E still there for two seconds. Recharge at the starting refuge or a lit lamp; G returns the cell.\nLantern: %d%%." % [cell+1,cell+1,ceili(state.third.charge_for(actor_id))]
			text_value += "\nLit refuges: %d / 3." % state.third.light_lit.count(true)
		"strings":
			heading = "COMBINE THE TWO CLUES"
			text_value = "At the northeast desk, read the current side and shape-family clues. Find the rope satisfying both; hold E still for two seconds. Read again after each stage. A wrong cut locks the catch for three seconds.\nBanked stages: %d / 3." % state.third.strings_stage
		"chimes":
			heading = "READ THE CURRENT PHRASE"
			text_value = "Read the south score, then walk between the numbered bells. E strikes; R moves or removes the shared damper. Wrong notes restart only the current phrase. In a match, the Eye hears these sounds.\nBanked phrases: %d / 2; notes in this phrase: %d / 4." % [state.third.chimes_phrase,state.third.chimes_index]
	if session.completed:
		heading = "DRILL COMPLETE"
		text_value = "You completed the selected trial through its normal interactions. Retry the same seed to compare your route, choose another seed or move to the next drill."
	return {"trial_id":session.trial_id,"title":row.get("title",session.trial_id),"slot_id":session.slot_id,"archetype":game.player.archetype,"seed":session.seed,"elapsed":session.elapsed,"progress":game.director.progress_for_slot(session.slot_id),"guide_title":heading,"guide_text":text_value,"completed":session.completed,"records":records}


static func _filled_cradles(cradles: Array) -> int:
	var result: int = 0
	for relic in cradles:
		if int(relic) >= 0:
			result += 1
	return result
