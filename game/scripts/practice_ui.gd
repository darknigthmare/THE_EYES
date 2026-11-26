class_name EyesPracticeInterface
extends RefCounted
## Presentation only. Session authority and the local notebook belong to main.

const ROLES: Array[String] = ["Veil", "Tinker", "Runner", "Keeper"]

var host
var catalogue: Array = []
var records: Dictionary = {}
var selected_trial: String = "silent"
var current_snapshot: Dictionary = {}
var catalog_panel: Control
var catalog_intro: Label
var catalog_warning_panel: Control
var catalog_warning_message: Label
var catalog_cards: Dictionary = {}
var catalog_title: Label
var catalog_summary: Label
var catalog_instructions: Label
var catalog_checkpoints: Label
var catalog_controls: Label
var notebook_label: Label
var selected_record_label: Label
var role_select: OptionButton
var seed_select: SpinBox
var start_button: Button
var guide_panel: Control
var guide_title: Label
var guide_text: Label
var guide_controls: Label
var progress_panel: Control
var trial_title: Label
var progress_label: Label
var progress_bar: ProgressBar
var result_panel: Control
var result_content: Panel
var result_warning_panel: Control
var result_warning_message: Label
var result_actions: Array[Button] = []
var result_title: Label
var result_body: Label
var result_record: Label
var retry_button: Button


func build(interface) -> void:
	host = interface
	_build_catalog()
	_build_drill()
	_build_result()
	hide_all()


func _paragraph(parent: Control, value: String, at: Vector2, size_value: Vector2, font_size: int = 16, color: Color = Color("e9e2d1")) -> Label:
	var text: Label = host.label(parent,value,at,size_value,font_size,color)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.set_deferred("size",size_value)
	return text


func _build_catalog() -> void:
	catalog_panel = host._full(host.root,Color(0.02,0.045,0.058,0.98))
	catalog_panel.name = "TrialWorkshopCatalog"
	host.label(catalog_panel,"THE TRIAL WORKSHOP",Vector2(62,38),Vector2(1190,65),46,host.PAPER,host.title_font)
	catalog_intro = _paragraph(catalog_panel,"One trial at a time. Learn its real controls with no Eye and no countdown.",Vector2(66,111),Vector2(1190,36),18,host.MUTED)
	notebook_label = host.label(catalog_panel,"LOCAL NOTEBOOK  /  0 OF 9 TRIALS COMPLETED",Vector2(68,157),Vector2(870,24),12,host.GOLD,host.mono_font)
	catalog_warning_panel = host.panel(catalog_panel,Vector2(66,105),Vector2(1308,77),Color("33251f"),host.ROSE)
	catalog_warning_panel.name = "NotebookCatalogWarning"
	host.label(catalog_warning_panel,"SESSION ONLY / NOTEBOOK NOT SAVED",Vector2(16,7),Vector2(1276,22),12,host.ROSE,host.mono_font)
	catalog_warning_message = _paragraph(catalog_warning_panel,"",Vector2(16,32),Vector2(1276,38),14,host.PAPER)
	catalog_warning_panel.hide()
	var detail: Panel = host.panel(catalog_panel,Vector2(970,194),Vector2(404,521),host.INK,Color("526265"))
	catalog_title = _paragraph(detail,"CHOOSE A TRIAL",Vector2(23,21),Vector2(358,66),28,host.PAPER)
	catalog_title.add_theme_font_override("font",host.title_font)
	catalog_summary = _paragraph(detail,"",Vector2(23,94),Vector2(358,67),15,host.MUTED)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(23,175)
	scroll.size = Vector2(358,198)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	detail.add_child(scroll)
	catalog_instructions = Label.new()
	catalog_instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	catalog_instructions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_instructions.add_theme_font_size_override("font_size",16)
	catalog_instructions.add_theme_color_override("font_color",host.PAPER)
	catalog_instructions.add_theme_constant_override("line_spacing",5)
	catalog_instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(catalog_instructions)
	catalog_checkpoints = _paragraph(detail,"",Vector2(23,387),Vector2(358,55),13,host.MINT)
	catalog_controls = _paragraph(detail,"",Vector2(23,450),Vector2(358,50),12,host.GOLD)
	selected_record_label = _paragraph(catalog_panel,"",Vector2(972,731),Vector2(402,49),13,host.MUTED)
	host.label(catalog_panel,"SURVIVOR",Vector2(68,735),Vector2(200,20),11,host.MUTED,host.mono_font)
	var role_options: Array[String] = ["Veil · stealth","Tinker · machinery","Runner · speed","Keeper · recovery"]
	role_select = host._option(catalog_panel,Vector2(66,762),210,role_options)
	role_select.item_selected.connect(func(_index: int): _refresh_record())
	host.label(catalog_panel,"PUZZLE SEED",Vector2(299,735),Vector2(190,20),11,host.MUTED,host.mono_font)
	seed_select = SpinBox.new()
	seed_select.position = Vector2(297,762)
	seed_select.size = Vector2(162,45)
	seed_select.min_value = 1
	seed_select.max_value = 999999
	seed_select.value = 271126
	catalog_panel.add_child(seed_select)
	host.button(catalog_panel,"NEW SEED",Vector2(475,762),Vector2(155,45)).pressed.connect(_choose_new_seed)
	start_button = host.button(catalog_panel,"START THIS TRIAL   →",Vector2(650,762),Vector2(295,45),true)
	start_button.pressed.connect(_start_selected)
	host.button(catalog_panel,"MAIN MENU",Vector2(66,832),Vector2(210,42)).pressed.connect(func(): host.menu_requested.emit())
	host.button(catalog_panel,"F1  FIELD MANUAL",Vector2(297,832),Vector2(255,42)).pressed.connect(func(): host.guide_requested.emit())
	host.label(catalog_panel,"Workshop completions stay in this local notebook, separate from matches.",Vector2(584,842),Vector2(790,25),12,host.MUTED)


func _build_cards() -> void:
	for entry in catalog_cards.values():
		entry.button.queue_free()
	catalog_cards.clear()
	for index: int in range(catalogue.size()):
		var item: Dictionary = catalogue[index]
		var id: String = str(item.get("trial_id",""))
		if id.is_empty():
			continue
		var at := Vector2(66+(index%3)*299,194+(index/3)*176)
		var card: Button = host.button(catalog_panel,"",at,Vector2(280,160))
		card.name = "PracticeCard_"+id
		card.tooltip_text = str(item.get("title",id))+" — "+str(item.get("summary",""))
		var title: Label = _paragraph(card,str(item.get("title",id)),Vector2(17,13),Vector2(246,51),20,host.PAPER)
		title.add_theme_font_override("font",host.title_font)
		_paragraph(card,str(item.get("summary","")),Vector2(17,69),Vector2(246,51),13,host.MUTED)
		var state: Label = host.label(card,"NOT YET COMPLETED",Vector2(17,132),Vector2(246,19),10,host.MUTED,host.mono_font)
		card.pressed.connect(_select_trial.bind(id))
		catalog_cards[id] = {"button":card,"state":state}


func _build_drill() -> void:
	progress_panel = host.panel(host.hud,Vector2(36,117),Vector2(352,140),Color(0.025,0.06,0.075,0.94),Color("52665e"))
	progress_panel.name = "WorkshopProgress"
	progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.label(progress_panel,"ONE TRIAL / YOUR OWN PACE",Vector2(16,12),Vector2(320,22),11,host.GOLD,host.mono_font)
	trial_title = _paragraph(progress_panel,"",Vector2(16,41),Vector2(320,51),21,host.PAPER)
	trial_title.add_theme_font_override("font",host.title_font)
	progress_label = host.label(progress_panel,"PROGRESS  0%",Vector2(16,100),Vector2(320,22),11,host.MINT,host.mono_font)
	progress_bar = host._bar(progress_panel,Vector2(16,129),Vector2(320,3),host.MINT)
	guide_panel = host.panel(host.hud,Vector2(1008,117),Vector2(396,470),Color(0.025,0.06,0.075,0.94),Color("52665e"))
	guide_panel.name = "WorkshopGuide"
	guide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.label(guide_panel,"WORKSHOP GUIDE",Vector2(20,16),Vector2(356,23),12,host.GOLD,host.mono_font)
	guide_title = _paragraph(guide_panel,"",Vector2(20,54),Vector2(356,61),26,host.PAPER)
	guide_title.add_theme_font_override("font",host.title_font)
	guide_text = _paragraph(guide_panel,"",Vector2(20,126),Vector2(356,226),17,host.PAPER)
	guide_controls = _paragraph(guide_panel,"",Vector2(20,367),Vector2(356,53),12,host.MINT)
	host.label(guide_panel,"F1  Manual    ESC  Pause / retry",Vector2(20,435),Vector2(356,22),11,host.MUTED,host.mono_font)


func _build_result() -> void:
	result_panel = host._full(host.root,Color(0.015,0.035,0.045,0.96))
	result_panel.name = "WorkshopResult"
	result_content = host.panel(result_panel,Vector2(268,124),Vector2(904,654),host.INK,Color("667064"))
	var body: Panel = result_content
	host.label(body,"WORKSHOP / TRIAL COMPLETE",Vector2(42,30),Vector2(820,26),12,host.GOLD,host.mono_font)
	result_title = _paragraph(body,"TRIAL COMPLETE",Vector2(40,78),Vector2(824,105),43,host.PAPER)
	result_title.add_theme_font_override("font",host.title_font)
	result_body = _paragraph(body,"",Vector2(43,199),Vector2(818,81),18,host.MUTED)
	result_record = _paragraph(body,"",Vector2(43,296),Vector2(818,63),14,host.MINT)
	result_warning_panel = host.panel(body,Vector2(43,368),Vector2(818,94),Color("33251f"),host.ROSE)
	result_warning_panel.name = "NotebookResultWarning"
	host.label(result_warning_panel,"SESSION ONLY / NOTEBOOK NOT SAVED",Vector2(15,8),Vector2(788,22),12,host.ROSE,host.mono_font)
	result_warning_message = _paragraph(result_warning_panel,"",Vector2(15,35),Vector2(788,48),14,host.PAPER)
	result_warning_panel.hide()
	retry_button = host.button(body,"RETRY SAME SEED",Vector2(43,388),Vector2(398,56),true)
	retry_button.pressed.connect(func(): host.practice_restart_requested.emit())
	var new_seed: Button = host.button(body,"TRY ANOTHER SEED",Vector2(463,388),Vector2(398,56))
	new_seed.pressed.connect(func(): host.practice_new_seed_requested.emit())
	var next_trial: Button = host.button(body,"NEXT TRIAL   →",Vector2(43,462),Vector2(398,51))
	next_trial.pressed.connect(func(): host.practice_next_requested.emit())
	var catalog: Button = host.button(body,"CHOOSE A TRIAL",Vector2(463,462),Vector2(398,51))
	catalog.pressed.connect(func(): host.practice_catalog_requested.emit())
	var menu: Button = host.button(body,"MAIN MENU",Vector2(43,550),Vector2(818,47))
	menu.pressed.connect(func(): host.menu_requested.emit())
	result_actions.assign([retry_button,new_seed,next_trial,catalog,menu])
	for action: Button in result_actions:
		action.set_meta("rest_y",action.position.y)


func show_catalog(items: Array, notebook: Dictionary, archetype: String, seed_value: int) -> void:
	catalogue = items.duplicate(true)
	records = notebook.duplicate(true)
	_refresh_storage_status()
	role_select.select(maxi(0,ROLES.find(archetype)))
	seed_select.value = clampi(seed_value,1,999999)
	_build_cards()
	if not catalog_cards.has(selected_trial) and not catalogue.is_empty():
		selected_trial = str(catalogue[0].get("trial_id",""))
	_select_trial(selected_trial)
	var completed: int = 0
	for item in catalogue:
		if int(_record(str(item.trial_id)).get("completions",0)) > 0:
			completed += 1
	notebook_label.text = "LOCAL NOTEBOOK  /  %d OF %d TRIALS COMPLETED" % [completed,catalogue.size()]
	for id in catalog_cards:
		var count: int = int(_record(id).get("completions",0))
		catalog_cards[id].state.text = "COMPLETED  ·  %d" % count if count > 0 else "NOT YET COMPLETED"
		catalog_cards[id].state.add_theme_color_override("font_color",host.MINT if count > 0 else host.MUTED)
	progress_panel.hide()
	guide_panel.hide()
	result_panel.hide()
	catalog_panel.show()
	if catalog_cards.has(selected_trial):
		catalog_cards[selected_trial].button.grab_focus.call_deferred()


func _record(id: String) -> Dictionary:
	var trials = records.get("trials",{})
	if not (trials is Dictionary):
		return {}
	var entry = trials.get(id,{})
	return entry if entry is Dictionary else {}


func _storage_error() -> String:
	var error = records.get("_storage_error","")
	return str(error).strip_edges() if error is String else ""


func _refresh_storage_status() -> void:
	var error: String = _storage_error()
	var failed: bool = not error.is_empty()
	catalog_warning_panel.visible = failed
	catalog_warning_message.text = error
	catalog_intro.visible = not failed
	notebook_label.visible = not failed
	result_warning_panel.visible = failed
	result_warning_message.text = error
	result_content.position.y = 79 if failed else 124
	result_content.size.y = 744 if failed else 654
	for action: Button in result_actions:
		action.position.y = float(action.get_meta("rest_y"))+(90.0 if failed else 0.0)


func _role_record(id: String, archetype: String) -> Dictionary:
	var roles = _record(id).get("by_archetype",{})
	if not (roles is Dictionary):
		return {}
	var entry = roles.get(archetype,{})
	return entry if entry is Dictionary else {}


func _item(id: String) -> Dictionary:
	for item in catalogue:
		if str(item.get("trial_id","")) == id:
			return item
	return {}


func _select_trial(id: String) -> void:
	selected_trial = id
	var item: Dictionary = _item(id)
	catalog_title.text = str(item.get("title","CHOOSE A TRIAL"))
	catalog_summary.text = str(item.get("summary",""))
	var lines := PackedStringArray()
	var steps: Array = item.get("instructions",[])
	for index: int in range(steps.size()):
		lines.append("%d. %s" % [index+1,str(steps[index])])
	catalog_instructions.text = "\n\n".join(lines)
	catalog_checkpoints.text = str(item.get("checkpoints",""))
	catalog_controls.text = str(item.get("controls",""))
	start_button.disabled = item.is_empty()
	for key in catalog_cards:
		var chosen: bool = key == id
		catalog_cards[key].button.add_theme_stylebox_override("normal",host.style(Color("254139") if chosen else Color("14272d"),host.MINT if chosen else Color("405357"),2 if chosen else 1))
	_refresh_record()


func _refresh_record() -> void:
	var role: String = ROLES[role_select.selected]
	var total: Dictionary = _record(selected_trial)
	var personal: Dictionary = _role_record(selected_trial,role)
	var count: int = int(total.get("completions",0))
	if int(personal.get("completions",0)) > 0 and int(personal.get("best_seed",0)) > 0:
		selected_record_label.text = "%d total completions · %s best %s\nBest seed %d · this role only" % [count,role,_time(float(personal.get("best_seconds",0.0))),int(personal.get("best_seed",0))]
	elif int(personal.get("completions",0)) > 0:
		selected_record_label.text = "%d total completions\n%s: %d completed · no saved best time." % [count,role,int(personal.get("completions",0))]
	else:
		selected_record_label.text = "%d total completions\n%s: no completed exercise yet." % [count,role]


func _choose_new_seed() -> void:
	var old_seed: int = int(seed_select.value)
	var next_seed: int = randi_range(1,999998)
	if next_seed >= old_seed:
		next_seed += 1
	seed_select.value = next_seed


func _start_selected() -> void:
	if not _item(selected_trial).is_empty():
		host.practice_start_requested.emit(selected_trial,ROLES[role_select.selected],int(seed_select.value))


func show_drill(snapshot: Dictionary) -> void:
	catalog_panel.hide()
	result_panel.hide()
	progress_panel.show()
	guide_panel.show()
	update_drill(snapshot)


func update_drill(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)
	selected_trial = str(snapshot.get("trial_id",selected_trial))
	var amount: float = clampf(float(snapshot.get("progress",0.0)),0.0,1.0)
	trial_title.text = str(snapshot.get("title",_item(selected_trial).get("title",selected_trial)))
	progress_label.text = "PROGRESS  %d%%" % roundi(amount*100.0)
	progress_bar.value = amount*100.0
	guide_title.text = str(snapshot.get("guide_title","Explore the trial"))
	guide_text.text = str(snapshot.get("guide_text","Move close to an apparatus and read its interaction prompt. F1 opens the field manual."))
	guide_controls.text = str(_item(selected_trial).get("controls","E · interact    G · return cargo    TAB · map"))
	guide_panel.visible = host.hud.visible and not host.minimap.visible and not host.echo_panel.visible and not result_panel.visible


func show_completion(snapshot: Dictionary) -> void:
	update_drill(snapshot)
	records = snapshot.get("records",records).duplicate(true)
	_refresh_storage_status()
	var role: String = str(snapshot.get("archetype","Veil"))
	var personal: Dictionary = _role_record(selected_trial,role)
	result_title.text = str(snapshot.get("title",selected_trial))
	result_body.text = "Completed with %s · seed %d · %s of practice.\nYour next attempt starts a fresh trial. The same seed keeps this puzzle." % [role,int(snapshot.get("seed",0)),_time(float(snapshot.get("elapsed",0.0)))]
	if int(personal.get("completions",0)) > 0:
		result_record.text = "LOCAL NOTEBOOK / %d completions with %s" % [int(personal.get("completions",0)),role]
		if int(personal.get("best_seed",0)) > 0:
			result_record.text += "\nBest for this role: %s · seed %d" % [_time(float(personal.get("best_seconds",0.0))),int(personal.get("best_seed",0))]
		else:
			result_record.text += "\nNo saved best time is available for this role."
	else:
		result_record.text = "LOCAL NOTEBOOK / Exercise complete. This session's record is in memory only." if not _storage_error().is_empty() else "LOCAL NOTEBOOK / Exercise complete. Records are stored on this device."
	progress_panel.hide()
	guide_panel.hide()
	catalog_panel.hide()
	result_panel.show()
	retry_button.grab_focus.call_deferred()


func hide_all() -> void:
	catalog_panel.hide()
	progress_panel.hide()
	guide_panel.hide()
	result_panel.hide()


func _time(seconds: float) -> String:
	var whole: int = maxi(0,ceili(seconds))
	return "%02d:%02d" % [whole/60,whole%60]
