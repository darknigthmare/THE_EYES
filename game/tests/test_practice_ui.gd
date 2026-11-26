extends SceneTree
## UI boundary fixtures: real controls and panels, no simulated trial completion.
## These verify navigation, notebook attribution and pause/manual transitions.
## Run: godot --headless --audio-driver Dummy --path game
##      --script res://tests/test_practice_ui.gd

const Interface = preload("res://scripts/interface.gd")
const PracticeState = preload("res://scripts/practice_state.gd")

var ui
var cases: int = 0
var assertions: int = 0
var failures: int = 0
var requests: Array = []
var resume_count: int = 0
var guide_count: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for action: String in ["pause","field_manual","practice_guide"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	ui = Interface.new()
	root.add_child(ui)
	ui.practice_start_requested.connect(func(id: String, role: String, seed_value: int): requests.append(["start",id,role,seed_value]))
	ui.practice_restart_requested.connect(func(): requests.append(["retry"]))
	ui.practice_new_seed_requested.connect(func(): requests.append(["new_seed"]))
	ui.practice_next_requested.connect(func(): requests.append(["next"]))
	ui.practice_catalog_requested.connect(func(): requests.append(["catalog"]))
	ui.menu_requested.connect(func(): requests.append(["menu"]))
	ui.resume_requested.connect(func(): resume_count += 1)
	ui.guide_requested.connect(func(): guide_count += 1)
	await process_frame
	_test_direct_practice_start()
	_test_catalog_and_notebook()
	_test_start_and_new_seed()
	_test_single_trial_and_hud()
	_test_guide_toggle_and_contexts()
	_test_manual_and_pause()
	_test_fov_scope()
	_test_missing_timing_record()
	_test_notebook_storage_error()
	_test_result_actions_and_role_record()
	_test_completion_wording()
	_test_session_visual_reset()
	paused = false
	ui.queue_free()
	await process_frame
	print("Practice interface: %d cases, %d assertions, %d failures" % [cases,assertions,failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: "+description)


func _records() -> Dictionary:
	return {"schema_version":1,"trials":{"light":{"attempts":8,"completions":5,"by_archetype":{
		"Tinker":{"attempts":4,"completions":3,"last_seed":321,"last_seconds":32.0,"best_seconds":25.0,"best_seed":123},
		"Keeper":{"attempts":4,"completions":2,"last_seed":321,"last_seconds":97.0,"best_seconds":90.0,"best_seed":456}
	}}}}


func _snapshot() -> Dictionary:
	return {"trial_id":"light","title":"LIGHT IN THE DARKNESS","seed":543210,"archetype":"Keeper","elapsed":97.0,"progress":0.5,"guide_title":"Bring a cell to its lamp","guide_text":"Carry the numbered cell to the matching refuge, then hold E while still and in clear sight.","completed":false,"records":_records()}


func _press_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	ui._unhandled_input(event)


func _find_button(parent: Node, value: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == value:
			return child
		var nested: Button = _find_button(child,value)
		if nested != null:
			return nested
	return null


func _test_direct_practice_start() -> void:
	cases += 1
	_check(ui.practice_view.catalogue.is_empty(),"UI fixture has not visited the catalog")
	ui.show_practice_game(_snapshot())
	_check(ui.practice_view.catalogue.size() == 9 and "align" in ui.practice_view.guide_controls.text,"a direct or command-line drill loads its own trial controls")
	ui.show_menu()


func _test_catalog_and_notebook() -> void:
	cases += 1
	var original: Dictionary = _records()
	ui.show_practice_catalog(PracticeState.catalogue(),original,"Tinker",543210)
	var view = ui.practice_view
	_check(view.catalog_panel.visible and not ui.menu.visible and not ui.hud.visible,"catalog is a dedicated screen")
	_check(view.catalog_cards.size() == 9,"all nine shipped trials are selectable")
	var has_tooltip: bool = false
	for card: Dictionary in view.catalog_cards.values():
		has_tooltip = has_tooltip or not card.button.tooltip_text.is_empty()
	_check(not has_tooltip,"catalog cards cannot cover the selected instructions with redundant tooltips")
	_check("1 OF 9" in view.notebook_label.text,"notebook counts completed trials, not attempts or completions")
	view.catalog_cards.light.button.pressed.emit()
	_check(view.selected_trial == "light" and "LIGHT" in view.catalog_title.text.to_upper(),"a real card selects the corresponding instructions")
	_check(not view.catalog_instructions.text.is_empty() and not view.catalog_controls.text.is_empty(),"selected trial provides steps and controls")
	_check("COMPLETED" in view.catalog_cards.light.state.text and "NOT YET" in view.catalog_cards.clock.state.text,"completion state is written as text, independent of color")
	_check("Tinker best 00:25" in view.selected_record_label.text and "Best seed 123" in view.selected_record_label.text,"Tinker notebook uses Tinker records")
	view.role_select.select(3)
	view.role_select.item_selected.emit(3)
	_check("Keeper best 01:30" in view.selected_record_label.text and not "00:25" in view.selected_record_label.text,"changing role cannot display another class's best time")
	view.role_select.select(0)
	view.role_select.item_selected.emit(0)
	_check("no completed exercise" in view.selected_record_label.text,"an unplayed role is not assigned another role's completion")
	_check(original == _records(),"catalog navigation never mutates the authority's notebook")


func _test_start_and_new_seed() -> void:
	cases += 1
	requests.clear()
	var view = ui.practice_view
	view.role_select.select(1)
	view.seed_select.value = 543210
	view.start_button.pressed.emit()
	_check(requests == [["start","light","Tinker",543210]],"start transmits the selected trial, role and exact seed")
	var old_seed: int = int(view.seed_select.value)
	var seed_button: Button = _find_button(view.catalog_panel,"NEW SEED")
	_check(seed_button != null,"catalog offers another seed without starting a session")
	if seed_button != null:
		seed_button.pressed.emit()
	_check(int(view.seed_select.value) != old_seed and view.seed_select.value >= 1 and view.seed_select.value <= 999999,"new-seed selection is valid and actually changes the seed")
	_check(requests.size() == 1 and view.selected_trial == "light","choosing a seed neither launches a drill nor changes trial")


func _test_single_trial_and_hud() -> void:
	cases += 1
	ui.set_trial_names({"silent":"light","echoes":"","relay":""},"practice")
	_check(ui.seal_labels.silent.visible and not ui.seal_labels.echoes.visible and not ui.seal_labels.relay.visible,"inactive slots do not index a nonexistent trial name")
	ui.show_practice_game(_snapshot())
	var view = ui.practice_view
	_check(ui.practice_enabled and ui.hud.visible and not view.catalog_panel.visible,"starting a drill closes the catalog")
	_check(view.progress_panel.visible and not ui.objective_box.visible and not ui.danger_panel.visible,"workshop shows one trial and removes match seal/gaze panels")
	_check(view.progress_bar.value == 50.0 and "50%" in view.progress_label.text,"workshop progress reflects authority data")
	_check(view.guide_title.text == _snapshot().guide_title and view.guide_text.text == _snapshot().guide_text,"guide renders the provided public instruction")
	var bot_positions: Array[Vector3] = []
	ui.update_hud({"time":100.0,"phase":"PREPARATION","health_text":"VITALITY 100","health":100.0,"stamina":100.0,"gaze":0.0,"gaze_text":"UNSEEN","ability":"Q / READY","objective":"CELL 2 / LANTERN 75%","hint":"E / Use","socket":0,"compass":"NORTH","seals":{"silent":false,"echoes":false,"relay":false},"progress":{"silent":0.5,"echoes":0.0,"relay":0.0},"position":Vector3.ZERO,"bots":bot_positions})
	_check(ui.timer_label.text == "NO TIME LIMIT" and "NO EYE" in ui.phase_label.text,"normal HUD updates cannot introduce a false countdown or phase")
	_check(ui.objective_label.text == "CELL 2 / LANTERN 75%" and "F1" in ui.controls_label.text,"workshop retains supplied cargo/ability feedback and exposes the manual shortcut")
	var backing: StyleBoxFlat = ui.objective_detail_panel.get_theme_stylebox("panel")
	_check(ui.objective_label.get_parent() == ui.objective_detail_panel and ui.objective_detail_panel.is_visible_in_tree() and backing.bg_color.a >= 0.9,"cargo and ability text has a visible dark backing against world inscriptions")
	ui.minimap.show()
	_check(not view.guide_panel.visible,"the map does not overlap the workshop guide")
	ui.minimap.hide()
	_check(view.guide_panel.visible,"closing the map restores the current guide")
	ui.echo_panel.show()
	_check(not view.guide_panel.visible,"the interactive Echoes panel does not overlap the workshop guide")
	ui.echo_panel.hide()
	_check(view.guide_panel.visible,"stepping away from Echoes restores the guide")
	_check(ui.pause_restart_button.visible and ui.pause_catalog_button.visible,"workshop pause offers an explicit retry and catalog")


func _test_guide_toggle_and_contexts() -> void:
	cases += 1
	ui.show_practice_game(_snapshot())
	var view = ui.practice_view
	_check(not view.guide_collapsed and view.guide_panel.visible and not view.guide_reminder.visible,"every fresh drill starts with the guide expanded")
	_press_action("practice_guide")
	_check(view.guide_collapsed and not view.guide_panel.visible and view.guide_reminder.is_visible_in_tree(),"H folds the guide into its visible reminder")
	_check("H" in view.guide_reminder_label.text and "SHOW" in view.guide_reminder_label.text and "H  Guide" in ui.controls_label.text,"both collapsed hint and controls explain how to restore the guide")
	_check(view.progress_panel.visible and ui.objective_detail_panel.visible,"folding the guide preserves trial progress and cargo feedback")
	var updated: Dictionary = _snapshot()
	updated.guide_title = "Latest public instruction"
	ui.update_practice(updated)
	_check(view.guide_collapsed and not view.guide_panel.visible,"ordinary guide updates cannot undo the player's choice")
	ui.minimap.show()
	_press_action("practice_guide")
	_check(view.guide_collapsed and not view.guide_panel.visible and not view.guide_reminder.visible,"the map masks both guide presentations and ignores H")
	ui.minimap.hide()
	_check(view.guide_reminder.visible and not view.guide_panel.visible,"closing the map restores the collapsed state")
	_press_action("practice_guide")
	_check(not view.guide_collapsed and view.guide_panel.visible and view.guide_title.text == updated.guide_title,"H restores the latest guidance without resetting progress")
	ui.echo_panel.show()
	_press_action("practice_guide")
	_check(not view.guide_collapsed and not view.guide_panel.visible and not view.guide_reminder.visible,"Echoes masks the guide and ignores H")
	ui.echo_panel.hide()
	_check(view.guide_panel.visible,"leaving Echoes restores the previous expanded state")
	ui.set_practice_guide_collapsed(true)
	ui.pause_panel.show()
	paused = true
	_press_action("practice_guide")
	_check(view.guide_collapsed and not view.guide_panel.visible and not view.guide_reminder.visible,"pause masks guidance without changing its collapsed state")
	ui.open_field_manual()
	_press_action("practice_guide")
	_check(view.guide_collapsed and ui.help_panel.visible and paused,"H cannot alter the guide or resume while the manual is open")
	ui.close_field_manual()
	_check(not view.guide_reminder.visible,"closing the manual into pause does not reveal the reminder early")
	paused = false
	ui.pause_panel.hide()
	_check(view.guide_collapsed and view.guide_reminder.visible,"explicit return from pause preserves the collapsed state")
	ui.show_practice_game(_snapshot())
	_check(not view.guide_collapsed and view.guide_panel.visible,"retry or a new drill opens its guide again")
	ui.show_game(false)
	_press_action("practice_guide")
	_check(not ui.practice_enabled and not view.guide_collapsed and not view.guide_panel.visible and not view.guide_reminder.visible,"H has no effect in an ordinary survivor match")
	ui.set_squad_enabled(true)
	_press_action("practice_guide")
	_check(ui.squad_enabled and not view.guide_panel.visible and not view.guide_reminder.visible,"H does not alter a normal Squad session")
	ui.show_game(true)
	_press_action("practice_guide")
	_check(ui.is_eye_mode and not view.guide_panel.visible and not view.guide_reminder.visible,"H has no effect in the Eye's mode")
	ui.show_practice_catalog(PracticeState.catalogue(),_records(),"Keeper",543210)
	_press_action("practice_guide")
	_check(view.catalog_panel.visible and not view.guide_collapsed and not view.guide_reminder.visible,"H does not alter the catalog")
	var completed: Dictionary = _snapshot()
	completed.completed = true
	completed.progress = 1.0
	ui.show_practice_game(completed)
	ui.show_practice_result(completed)
	_press_action("practice_guide")
	_check(view.result_panel.visible and not view.guide_collapsed and not view.guide_panel.visible and not view.guide_reminder.visible,"H cannot reopen guidance on a result screen")
	ui.show_practice_game(_snapshot())


func _test_manual_and_pause() -> void:
	cases += 1
	resume_count = 0
	guide_count = 0
	ui.pause_panel.show()
	paused = true
	_press_action("field_manual")
	_check(guide_count == 1,"F1 asks the session owner to open the manual even while paused")
	ui.open_field_manual()
	_check(ui.help_panel.visible and "STAY PAUSED" in ui.help_return_button.text,"manual identifies its pause return destination")
	_check(ui.help_return_button.get_theme_color("font_focus_color") == ui.INK,"focused gold manual button keeps dark readable text")
	_press_action("pause")
	_check(not ui.help_panel.visible and ui.pause_panel.visible and paused,"Escape closes only the manual and keeps the session paused")
	_check(resume_count == 0,"closing the manual never emits resume")
	ui.open_field_manual()
	_press_action("field_manual")
	_check(not ui.help_panel.visible and ui.pause_panel.visible and resume_count == 0,"F1 close also returns to pause without resuming")
	ui.open_field_manual()
	ui.help_return_button.pressed.emit()
	_check(not ui.help_panel.visible and ui.pause_panel.visible and resume_count == 0,"manual button has the same stay-paused behavior")
	ui.pause_resume_button.pressed.emit()
	_check(resume_count == 1 and not ui.pause_panel.visible,"resuming is a separate explicit action")
	paused = false


func _test_fov_scope() -> void:
	cases += 1
	ui.settings.fov = 96.0
	ui.sync_settings_controls()
	ui.show_game(true)
	_check(not ui.setting_controls.fov.editable and "85" in ui.fov_note.text,"Eye mode explains its fixed view and does not offer an ineffective slider")
	_check(ui.setting_controls.fov.value == 96.0,"Eye mode preserves the survivor FOV preference")
	ui.show_game(false)
	_check(ui.setting_controls.fov.editable and ui.setting_controls.fov.value == 96.0,"survivors can still adjust their persisted preference")


func _test_result_actions_and_role_record() -> void:
	cases += 1
	requests.clear()
	var snapshot: Dictionary = _snapshot()
	snapshot.progress = 1.0
	snapshot.completed = true
	ui.show_practice_game(snapshot)
	ui.show_practice_result(snapshot)
	var view = ui.practice_view
	_check(view.result_panel.visible and not ui.result_panel.visible and not ui.hud.visible,"workshop completion uses its own result screen")
	_check("Keeper" in view.result_record.text and "01:30" in view.result_record.text and not "00:25" in view.result_record.text,"result best time belongs to the actual survivor role")
	_check("2 completions with Keeper" in view.result_record.text,"multiple completions retain plural wording")
	_check(view.retry_button.get_theme_color("font_focus_color") == ui.INK,"focused gold retry button keeps dark readable text")
	_check("543210" in view.result_body.text,"result exposes the seed that retry will preserve")
	var choices: Dictionary = {"RETRY SAME SEED":"retry","TRY ANOTHER SEED":"new_seed","NEXT TRIAL   →":"next","CHOOSE A TRIAL":"catalog","MAIN MENU":"menu"}
	for text_value: String in choices:
		var control: Button = _find_button(view.result_panel,text_value)
		_check(control != null,"result exposes "+text_value)
		if control != null:
			control.pressed.emit()
			_check(requests.back() == [choices[text_value]],text_value+" emits a distinct session request")
	_check(snapshot.records == _records(),"result rendering does not write or recalculate records")


func _test_completion_wording() -> void:
	cases += 1
	var notebook: Dictionary = {"schema_version":1,"trials":{"light":{"attempts":1,"completions":1,"by_archetype":{
		"Keeper":{"attempts":1,"completions":1,"last_seed":271126,"last_seconds":48.0,"best_seconds":48.0,"best_seed":271126}
	}}}}
	ui.show_practice_catalog(PracticeState.catalogue(),notebook,"Keeper",271126)
	ui.practice_view.catalog_cards.light.button.pressed.emit()
	_check("1 total completion ·" in ui.practice_view.selected_record_label.text and not "1 total completions" in ui.practice_view.selected_record_label.text,"the catalog uses singular completion for one recorded exercise")
	var snapshot: Dictionary = _snapshot()
	snapshot.completed = true
	snapshot.progress = 1.0
	snapshot.seed = 271126
	snapshot.elapsed = 48.0
	snapshot.records = notebook
	ui.show_practice_game(snapshot)
	ui.show_practice_result(snapshot)
	_check("1 completion with Keeper" in ui.practice_view.result_record.text and not "1 completions" in ui.practice_view.result_record.text,"a first successful exercise uses singular completion on its result")


func _test_missing_timing_record() -> void:
	cases += 1
	var notebook: Dictionary = _records()
	notebook.trials.light.by_archetype.Tinker.best_seed = 0
	notebook.trials.light.by_archetype.Tinker.best_seconds = 0.0
	ui.show_practice_catalog(PracticeState.catalogue(),notebook,"Tinker",543210)
	ui.practice_view.catalog_cards.light.button.pressed.emit()
	_check("3 completed" in ui.practice_view.selected_record_label.text and "no saved best time" in ui.practice_view.selected_record_label.text,"cleaned historical timing retains completions without inventing a record")
	_check(not "00:00" in ui.practice_view.selected_record_label.text,"missing best seed does not display a false zero-second best")
	var snapshot: Dictionary = _snapshot()
	snapshot.archetype = "Tinker"
	snapshot.records = notebook
	snapshot.completed = true
	ui.show_practice_game(snapshot)
	ui.show_practice_result(snapshot)
	_check("No saved best time" in ui.practice_view.result_record.text and not "seed 0" in ui.practice_view.result_record.text,"results handle cleaned records consistently")


func _test_session_visual_reset() -> void:
	cases += 1
	ui.show_menu()
	_check(ui.menu.visible and not ui.practice_enabled and not ui.practice_view.result_panel.visible,"main menu clears workshop presentation")
	_check(not ui.pause_restart_button.visible and not ui.pause_catalog_button.visible,"ordinary sessions do not retain practice actions")
	ui.set_trial_names({"silent":"silent","echoes":"echoes","relay":"relay"},"first")
	ui.show_game(false)
	_check(ui.objective_box.visible and ui.danger_panel.visible and not ui.practice_view.progress_panel.visible,"ordinary match HUD is restored")
	_check(ui.seal_labels.silent.visible and ui.seal_labels.echoes.visible and ui.seal_labels.relay.visible,"three active labels return after a single-trial exercise")
	_check(ui.timer_label.get_theme_font_size("font_size") == 35,"match timer typography is restored")


func _test_notebook_storage_error() -> void:
	cases += 1
	var notebook: Dictionary = _records()
	notebook["_storage_error"] = "The existing notebook is preserved because it uses a newer format. This session remains in memory."
	ui.show_practice_catalog(PracticeState.catalogue(),notebook,"Keeper",543210)
	var view = ui.practice_view
	_check(not ui.hud.visible and view.catalog_warning_panel.is_visible_in_tree(),"catalog storage error remains visible with gameplay HUD hidden")
	_check(view.catalog_warning_message.text == notebook._storage_error,"catalog explains the actual storage failure")
	_check(not view.notebook_label.visible and not view.catalog_intro.visible,"dedicated warning replaces introductory text without overlap")
	var snapshot: Dictionary = _snapshot()
	snapshot.completed = true
	snapshot.records = notebook
	ui.show_practice_game(snapshot)
	ui.show_practice_result(snapshot)
	_check(not ui.hud.visible and view.result_warning_panel.is_visible_in_tree(),"result storage error also stays visible outside the HUD")
	_check(view.result_warning_message.text == notebook._storage_error,"result preserves the actionable failure explanation")
	_check(view.retry_button.position.y > view.result_warning_panel.position.y+view.result_warning_panel.size.y,"result actions move clear of the storage warning")
	ui.show_practice_catalog(PracticeState.catalogue(),_records(),"Keeper",543210)
	_check(not view.catalog_warning_panel.visible and view.notebook_label.visible and view.catalog_intro.visible,"a clean storage snapshot restores the normal catalog")
	snapshot.records = _records()
	ui.show_practice_result(snapshot)
	_check(not view.result_warning_panel.visible and view.retry_button.position.y == 388.0,"a clean result removes the warning and restores button layout")
