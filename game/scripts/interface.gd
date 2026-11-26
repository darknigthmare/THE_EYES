class_name EyesInterface
extends CanvasLayer

signal start_requested(mode: String, archetype: String, difficulty: String, seed_value: int, contract: String)
signal resume_requested
signal menu_requested
signal echo_pressed(symbol: int)
signal echo_replay_requested
signal echo_close_requested
signal settings_changed(values: Dictionary)

const INK = Color("0d191f")
const PAPER = Color("e9e2d1")
const MUTED = Color("98b0b1")
const GOLD = Color("d4b785")
const MINT = Color("89d8c5")
const ROSE = Color("e39382")

var root: Control
var menu: Control
var hud: Control
var pause_panel: Control
var echo_panel: Control
var result_panel: Control
var help_panel: Control
var title_font: Font = preload("res://assets/fonts/ObservanceSerif.ttf")
var text_font: Font = preload("res://assets/fonts/Interface.ttf")
var mono_font: Font = preload("res://assets/fonts/Readout.ttf")
var role_select: OptionButton
var difficulty_select: OptionButton
var seed_select: SpinBox
var contract_select: OptionButton
var observance_label: Label
var timer_label: Label
var phase_label: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var gaze_bar: ProgressBar
var health_label: Label
var gaze_label: Label
var ability_label: Label
var objective_label: Label
var hint_label: Label
var notification: Label
var controls_label: Label
var compass_label: Label
var eye_label: Label
var seal_labels: Dictionary = {}
var seal_bars: Dictionary = {}
var echo_text: Label
var echo_symbols: Array[Button] = []
var result_title: Label
var result_body: Label
var result_stats: Label
var overlay_material: ShaderMaterial
var flash_label: Label
var minimap: Control
var map_positions: Array[Vector3] = []
var map_actor: Vector3 = Vector3.ZERO
var map_eye: int = 0
var is_eye_mode: bool = false
var settings: Dictionary = {"audio":true,"reduced_motion":false,"invert_y":false,"sensitivity":1.0,"fov":79.0}
var notification_left: float = 0.0
var setting_controls: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme = Theme.new()
	theme.default_font = text_font
	theme.default_font_size = 17
	root.theme = theme
	var veil = ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_material = ShaderMaterial.new()
	overlay_material.shader = load("res://assets/materials/screen.gdshader")
	veil.material = overlay_material
	root.add_child(veil)
	_build_menu()
	_build_hud()
	_build_pause()
	_build_echo()
	_build_result()
	_build_help()
	for view: Control in [menu, hud, pause_panel, echo_panel, result_panel, help_panel]:
		view.visibility_changed.connect(_refresh_visible_panel.bind(view))
	show_menu()

func _refresh_visible_panel(view: Control) -> void:
	if view.is_visible_in_tree():
		_refresh_controls.call_deferred(view)

func _refresh_controls(parent: Control) -> void:
	parent.update_minimum_size()
	parent.queue_redraw()
	for child in parent.get_children():
		if child is Control:
			_refresh_controls(child)

func style(bg: Color, border: Color = Color.TRANSPARENT, width: int = 1, radius: int = 3) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func panel(parent: Control, at: Vector2, size_value: Vector2, fill: Color, border: Color = Color.TRANSPARENT) -> Panel:
	var p = Panel.new()
	p.position = at
	p.size = size_value
	p.add_theme_stylebox_override("panel",style(fill,border))
	parent.add_child(p)
	return p

func label(parent: Control, value: String, at: Vector2, size_value: Vector2, font_size: int = 18, color: Color = PAPER, font: Font = null) -> Label:
	var l = Label.new()
	l.text = value
	l.position = at
	l.size = size_value
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	if font != null:
		l.add_theme_font_override("font",font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button(parent: Control, value: String, at: Vector2, size_value: Vector2, primary: bool = false) -> Button:
	var b = Button.new()
	b.text = value
	b.position = at
	b.size = size_value
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size",17)
	b.add_theme_stylebox_override("normal",style(GOLD if primary else Color("14272d"),GOLD if primary else Color("405357")))
	b.add_theme_stylebox_override("hover",style(Color("e8d1a7") if primary else Color("254249"),GOLD))
	b.add_theme_stylebox_override("pressed",style(Color("b39b72") if primary else Color("314d52"),MINT))
	b.add_theme_stylebox_override("focus",style(Color.TRANSPARENT,MINT,2))
	b.add_theme_color_override("font_color",INK if primary else PAPER)
	b.add_theme_color_override("font_hover_color",INK if primary else PAPER)
	b.add_theme_color_override("font_pressed_color",INK if primary else PAPER)
	parent.add_child(b)
	return b

func _full(parent: Control, color: Color = Color.TRANSPARENT) -> ColorRect:
	var c = ColorRect.new()
	c.color = color
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(c)
	return c

func _option(parent: Control, at: Vector2, w: float, values: Array[String]) -> OptionButton:
	var o = OptionButton.new()
	o.position = at
	o.size = Vector2(w,45)
	for value in values:
		o.add_item(value)
	o.add_theme_stylebox_override("normal",style(Color("15262d"),Color("42565a")))
	o.add_theme_stylebox_override("hover",style(Color("254049"),GOLD))
	o.add_theme_stylebox_override("focus",style(Color.TRANSPARENT,MINT,2))
	parent.add_child(o)
	return o

func _build_menu() -> void:
	menu = _full(root)
	# Fade rather than cover the live 3D scene: this is the actual arena.
	var gradient = Gradient.new()
	gradient.set_color(0,Color(0.025,0.055,0.068,0.98))
	gradient.set_color(1,Color(0.025,0.055,0.068,0.0))
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.25,0)
	texture.fill_to = Vector2(1,0)
	var fade = TextureRect.new()
	fade.texture = texture
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(fade)
	label(menu,"D A R K N I G T H M A R E    /    O R I G I N A L S",Vector2(64,38),Vector2(720,30),13,GOLD,mono_font)
	label(menu,"A S Y M M E T R I C A L   N I G H T M A R E",Vector2(66,144),Vector2(670,30),13,MINT,mono_font)
	label(menu,"THE EYES",Vector2(59,177),Vector2(780,116),102,PAPER,title_font)
	label(menu,"THE OBSERVANCE COLLECTION",Vector2(68,300),Vector2(650,37),19,GOLD,mono_font)
	var description = label(menu,"It cannot follow you.\nIt only needs to see you.",Vector2(68,359),Vector2(610,84),29,PAPER,title_font)
	description.add_theme_constant_override("line_spacing",8)
	label(menu,"Six trials. Three seals. One way out.",Vector2(68,463),Vector2(620,32),17,MUTED)
	button(menu,"ENTER AS A SURVIVOR     →",Vector2(68,518),Vector2(570,60),true).pressed.connect(_start.bind("survivor"))
	button(menu,"TAKE THE EYE'S SEAT       →",Vector2(68,590),Vector2(570,54)).pressed.connect(_start.bind("eye"))
	label(menu,"SURVIVOR",Vector2(70,670),Vector2(180,24),11,MUTED,mono_font)
	label(menu,"DIFFICULTY",Vector2(289,670),Vector2(160,24),11,MUTED,mono_font)
	label(menu,"SEED",Vector2(480,670),Vector2(150,24),11,MUTED,mono_font)
	role_select = _option(menu,Vector2(68,697),205,["Veil · stealth","Tinker · machinery","Runner · speed","Keeper · recovery"])
	difficulty_select = _option(menu,Vector2(285,697),175,["Story","Standard","Ruthless"])
	difficulty_select.selected = 1
	seed_select = SpinBox.new()
	seed_select.position = Vector2(472,697)
	seed_select.size = Vector2(166,45)
	seed_select.min_value = 1
	seed_select.max_value = 999999
	seed_select.value = 271126
	menu.add_child(seed_select)
	button(menu,"FIELD MANUAL",Vector2(68,771),Vector2(270,43)).pressed.connect(func(): help_panel.show())
	button(menu,"SETTINGS",Vector2(350,771),Vector2(288,43)).pressed.connect(func(): pause_panel.show())
	label(menu,"PLAYABLE GODOT PROTOTYPE  /  0.2.0  /  ENGLISH",Vector2(68,853),Vector2(760,25),11,MUTED,mono_font)
	var contract_panel = panel(menu,Vector2(875,538),Vector2(502,282),Color(0.03,0.07,0.09,0.92),Color("54635c"))
	label(contract_panel,"CHOOSE YOUR OBSERVANCE",Vector2(24,20),Vector2(454,25),13,GOLD,mono_font)
	contract_select = _option(contract_panel,Vector2(24,61),454,["First Observance","Second Observance","Seeded Mix"])
	var descriptions: Array[String] = [
		"THE FIRST / Learn the chamber\nCarry whispers, remember the Echoes, and charge the Relay.",
		"THE SECOND / The Registrar's devices\nIdentify four relics, kindle the Ritual, and solve the coupled Clock.",
		"SEEDED MIX / Eight combinations\nOne of two trials in each bay. Your seed fixes the selection and its puzzles."
	]
	var contract_description = label(contract_panel,descriptions[0],Vector2(24,123),Vector2(454,105),17,PAPER)
	contract_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contract_description.set_deferred("size",Vector2(454,105))
	contract_select.item_selected.connect(func(index: int): contract_description.text = descriptions[index])
	label(contract_panel,"LOCAL SOLO + ADVERSARIAL AI",Vector2(24,247),Vector2(454,20),10,MUTED,mono_font)

func _start(mode: String) -> void:
	var archetype = ["Veil","Tinker","Runner","Keeper"][role_select.selected]
	var difficulty = ["story","standard","ruthless"][difficulty_select.selected]
	start_requested.emit(mode,archetype,difficulty,int(seed_select.value),["first","second","mix"][contract_select.selected])

func _bar(parent: Control, at: Vector2, size_value: Vector2, color: Color) -> ProgressBar:
	var b = ProgressBar.new()
	b.position = at
	b.size = size_value
	b.max_value = 100
	b.show_percentage = false
	var background_style = style(Color("24383c"),Color.TRANSPARENT,0,0)
	var fill_style = style(color,Color.TRANSPARENT,0,0)
	for s in [background_style,fill_style]:
		s.content_margin_left = 0
		s.content_margin_right = 0
		s.content_margin_top = 0
		s.content_margin_bottom = 0
	b.add_theme_stylebox_override("background",background_style)
	b.add_theme_stylebox_override("fill",fill_style)
	parent.add_child(b)
	# Apply the requested height after replacing the theme's minimum-sized bars.
	b.size = size_value
	return b

func _build_hud() -> void:
	hud = _full(root)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	observance_label = label(hud,"THE FIRST OBSERVANCE",Vector2(38,24),Vector2(620,40),26,PAPER,title_font)
	phase_label = label(hud,"PREPARATION",Vector2(40,66),Vector2(650,25),12,GOLD,mono_font)
	timer_label = label(hud,"08:00",Vector2(1175,24),Vector2(222,46),35,PAPER,mono_font)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	compass_label = label(hud,"N  ·  THE UNSEEN DOOR",Vector2(470,32),Vector2(500,30),11,MUTED,mono_font)
	compass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var objective_box = panel(hud,Vector2(36,117),Vector2(314,172),Color(0.025,0.06,0.075,0.85),Color("344a4e"))
	label(objective_box,"BREAK THE THREE SEALS",Vector2(16,13),Vector2(288,22),11,GOLD,mono_font)
	var names = {"silent":"I    SILENT COUNTDOWN","echoes":"II   TRIAL OF THE ECHOES","relay":"III  CLOCKWORK RELAY"}
	var i: int = 0
	for key in names:
		seal_labels[key] = label(objective_box,names[key],Vector2(16,45+i*37),Vector2(286,22),12,PAPER,mono_font)
		seal_bars[key] = _bar(objective_box,Vector2(16,72+i*37),Vector2(280,2),MINT)
		i += 1
	objective_label = label(hud,"",Vector2(38,307),Vector2(470,76),15,MUTED)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.set_deferred("size",Vector2(470,76))
	var bottom = panel(hud,Vector2(36,744),Vector2(334,116),Color(0.025,0.06,0.075,0.85),Color("344a4e"))
	health_label = label(bottom,"VITALITY  100",Vector2(16,12),Vector2(270,20),11,PAPER,mono_font)
	health_bar = _bar(bottom,Vector2(16,39),Vector2(300,5),MINT)
	stamina_bar = _bar(bottom,Vector2(16,50),Vector2(300,3),GOLD)
	ability_label = label(bottom,"Q  ·  QUIET STEP  /  READY",Vector2(16,72),Vector2(304,27),10,GOLD,mono_font)
	var danger_panel = panel(hud,Vector2(1070,757),Vector2(334,103),Color(0.025,0.06,0.075,0.85),Color("344a4e"))
	gaze_label = label(danger_panel,"UNSEEN",Vector2(17,13),Vector2(300,22),12,MINT,mono_font)
	gaze_bar = _bar(danger_panel,Vector2(17,45),Vector2(300,5),ROSE)
	eye_label = label(danger_panel,"ACTIVE SOCKET  01  /  NORTH",Vector2(17,64),Vector2(300,24),10,MUTED,mono_font)
	var reticle = label(hud,"·",Vector2(703,425),Vector2(34,40),27,PAPER)
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label = label(hud,"",Vector2(390,616),Vector2(660,80),19,PAPER)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.set_deferred("size",Vector2(660,80))
	notification = label(hud,"",Vector2(380,140),Vector2(680,78),23,GOLD,title_font)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification.set_deferred("size",Vector2(680,78))
	controls_label = label(hud,"WASD / ZQSD  Move    SHIFT  Sprint    CTRL  Crouch    E  Interact    Q/A  Ability    G  Drop    TAB  Map    ESC  Pause",Vector2(382,866),Vector2(1020,24),10,MUTED,mono_font)
	flash_label = label(hud,"",Vector2(390,233),Vector2(660,30),14,ROSE,mono_font)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minimap = Control.new()
	minimap.position = Vector2(1050,127)
	minimap.size = Vector2(344,350)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.draw.connect(_draw_map)
	hud.add_child(minimap)
	minimap.hide()

func _build_pause() -> void:
	pause_panel = _full(root,Color(0.01,0.025,0.035,0.88))
	var p = panel(pause_panel,Vector2(444,112),Vector2(552,680),INK,Color("526265"))
	label(p,"A MOMENT UNSEEN",Vector2(34,24),Vector2(500,55),38,PAPER,title_font)
	label(p,"The observance waits while this menu is open.",Vector2(34,87),Vector2(480,38),14,MUTED)
	var options = [["audio","Sound & atmosphere"],["reduced_motion","Reduce camera motion & vignette"],["invert_y","Invert vertical look"]]
	for i in range(options.size()):
		var c = CheckButton.new()
		c.text = options[i][1]
		c.position = Vector2(30,147+i*51)
		c.size = Vector2(476,43)
		c.button_pressed = settings[options[i][0]]
		c.toggled.connect(_setting_bool.bind(options[i][0]))
		setting_controls[options[i][0]] = c
		p.add_child(c)
	label(p,"LOOK SENSITIVITY",Vector2(34,321),Vector2(420,24),11,GOLD,mono_font)
	var sensitivity = HSlider.new()
	sensitivity.position = Vector2(34,356)
	sensitivity.size = Vector2(476,28)
	sensitivity.min_value = 0.3
	sensitivity.max_value = 2.5
	sensitivity.step = 0.1
	sensitivity.value = 1.0
	sensitivity.value_changed.connect(_setting_number.bind("sensitivity"))
	setting_controls.sensitivity = sensitivity
	p.add_child(sensitivity)
	label(p,"FIELD OF VIEW",Vector2(34,404),Vector2(420,24),11,GOLD,mono_font)
	var fov = HSlider.new()
	fov.position = Vector2(34,440)
	fov.size = Vector2(476,28)
	fov.min_value = 65
	fov.max_value = 100
	fov.value = 79
	fov.value_changed.connect(_setting_number.bind("fov"))
	setting_controls.fov = fov
	p.add_child(fov)
	button(p,"RETURN",Vector2(34,510),Vector2(476,54),true).pressed.connect(func(): pause_panel.hide(); resume_requested.emit())
	button(p,"LEAVE THE OBSERVANCE",Vector2(34,578),Vector2(476,48)).pressed.connect(func(): pause_panel.hide(); menu_requested.emit())

func _setting_bool(value: bool, key: String) -> void:
	settings[key] = value
	settings_changed.emit(settings)

func _setting_number(value: float, key: String) -> void:
	settings[key] = value
	settings_changed.emit(settings)

func sync_settings_controls() -> void:
	for key in setting_controls:
		if setting_controls[key] is BaseButton:
			setting_controls[key].set_pressed_no_signal(settings[key])
		else:
			setting_controls[key].set_value_no_signal(settings[key])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if help_panel.visible:
			help_panel.hide()
			get_viewport().set_input_as_handled()
		elif pause_panel.visible:
			pause_panel.hide()
			resume_requested.emit()
			get_viewport().set_input_as_handled()

func _build_echo() -> void:
	echo_panel = panel(root,Vector2(390,267),Vector2(660,326),Color(0.025,0.06,0.075,0.96),Color("a996c6"))
	label(echo_panel,"TRIAL OF THE ECHOES",Vector2(30,23),Vector2(600,48),33,PAPER,title_font)
	echo_text = label(echo_panel,"Watch the four symbols.",Vector2(30,81),Vector2(600,64),16,MUTED)
	echo_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	echo_text.set_deferred("size",Vector2(600,64))
	var glyphs = ["1  /  I","2  /  II","3  /  III","4  /  IV"]
	for i in range(4):
		var b = button(echo_panel,glyphs[i],Vector2(30+i*151,162),Vector2(140,65))
		b.pressed.connect(func(): echo_pressed.emit(i))
		echo_symbols.append(b)
	button(echo_panel,"R  REPLAY",Vector2(30,250),Vector2(288,45)).pressed.connect(func(): echo_replay_requested.emit())
	button(echo_panel,"E / ESC  STEP AWAY",Vector2(330,250),Vector2(297,45)).pressed.connect(func(): echo_close_requested.emit())

func show_echo_step(index: int, text_value: String, interactive: bool) -> void:
	echo_text.text = text_value
	for i in range(4):
		var b: Button = echo_symbols[i]
		b.disabled = not interactive
		b.modulate = Color("f6dfa6") if i == index else Color.WHITE
		b.add_theme_stylebox_override("normal",style(Color("55685b") if i == index else Color("14272d"),GOLD if i == index else Color("405357")))
		b.add_theme_stylebox_override("disabled",style(Color("55685b") if i == index else Color("14272d"),GOLD if i == index else Color("405357")))
		b.add_theme_color_override("font_disabled_color",PAPER if i == index else MUTED)

func _build_result() -> void:
	result_panel = _full(root,Color(0.015,0.035,0.045,0.9))
	var p = panel(result_panel,Vector2(310,175),Vector2(820,552),INK,Color("667064"))
	label(p,"THE OBSERVANCE IS COMPLETE",Vector2(48,34),Vector2(724,26),12,GOLD,mono_font)
	result_title = label(p,"YOU WERE UNSEEN",Vector2(44,90),Vector2(730,77),53,PAPER,title_font)
	result_body = label(p,"",Vector2(48,190),Vector2(722,90),19,MUTED)
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body.set_deferred("size",Vector2(722,90))
	result_stats = label(p,"",Vector2(48,302),Vector2(722,74),13,GOLD,mono_font)
	button(p,"ANOTHER OBSERVANCE",Vector2(48,421),Vector2(724,63),true).pressed.connect(func(): menu_requested.emit())

func _build_help() -> void:
	help_panel = _full(root,Color(0.01,0.025,0.035,0.96))
	# The body gets only the space left between the heading and fixed footer.
	# Overflow scrolls inside this region instead of growing over the controls.
	var margins = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left",78)
	margins.add_theme_constant_override("margin_right",78)
	margins.add_theme_constant_override("margin_top",48)
	margins.add_theme_constant_override("margin_bottom",42)
	help_panel.add_child(margins)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation",20)
	margins.add_child(layout)
	label(layout,"FIELD MANUAL",Vector2.ZERO,Vector2.ZERO,51,PAPER,title_font)
	var body = ScrollContainer.new()
	body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.follow_focus = true
	body.clip_contents = true
	layout.add_child(body)
	var columns = HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",56)
	body.add_child(columns)
	var left = "THREE ACTIVE TRIALS PER MATCH\nFirst keeps the original trials. Second replaces all three. Seeded Mix chooses one of two in each bay.\n\nFIRST: deliver three motes northwest; repeat the Echoes northeast; hold E at the south Relay.\n\nMEMORY VAULT: read four relic names at the northwest desk. Collect them from the southern shelves and fill their exact numbered cradles. G safely returns cargo.\n\nRITUAL CIRCLE: take the shared ember northeast. Follow the engraved five-vessel order; pairs stay banked. Remain inside the ring for eight seconds. Move within it to avoid hazards.\n\nCLOCK ROOM: walk between the south levers. E turns forward; R reverses. Match the target, then press E at the centre. X resets.\n\nComplete all three seals, then hold E at the north door. Use cover to break gaze. Your first fall offers Second Sight."
	var right = "Four AI survivors will collect motes, solve trials and attempt escape. You remain fixed in an Eye socket.\n\n1–4 or mouse wheel: switch sockets. Mouse: look.\nLEFT CLICK: trigger the trap nearest your crosshair. It must be visible; a gold ring warns before the strike.\nRIGHT CLICK: focus a visible survivor. Keep them inside your gaze to wound them.\nQ: call a stalking shadow at a visible floor point. Its arrival is telegraphed.\n\nEnergy, cooldowns, sightlines and a preparation grace limit your powers. Change vantage to find targets; walls block both your sight and your abilities.\n\nTAB reveals the chamber map. ESC pauses. Sound, motion, sensitivity and field of view are adjustable."
	for index in range(2):
		var column = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",20)
		columns.add_child(column)
		label(column,["I / SURVIVOR","II / THE EYE"][index],Vector2.ZERO,Vector2.ZERO,16,GOLD,mono_font)
		var paragraph = Label.new()
		paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		paragraph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		paragraph.add_theme_font_size_override("font_size",16)
		paragraph.add_theme_color_override("font_color",PAPER)
		paragraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paragraph.text = [left,right][index]
		column.add_child(paragraph)
	var controls = Label.new()
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_override("font",mono_font)
	controls.add_theme_font_size_override("font_size",13)
	controls.add_theme_color_override("font_color",MUTED)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.text = "WASD / ZQSD · move    E · use    Q (AZERTY A) · ability    G · drop    R · reverse clock    X · reset clock"
	layout.add_child(controls)
	var ready = button(layout,"I AM READY",Vector2.ZERO,Vector2.ZERO,true)
	ready.custom_minimum_size.y = 56
	ready.pressed.connect(func(): help_panel.hide())

func show_menu() -> void:
	menu.show()
	hud.hide()
	pause_panel.hide()
	echo_panel.hide()
	result_panel.hide()
	help_panel.hide()
	overlay_material.set_shader_parameter("danger",0.0)

func show_game(eye_mode: bool) -> void:
	menu.hide()
	hud.show()
	result_panel.hide()
	pause_panel.hide()
	is_eye_mode = eye_mode
	controls_label.text = "1–4 / WHEEL  Switch socket    MOUSE  Aim    LMB  Trap    RMB  Mark    Q  Summon    TAB  Map    ESC  Pause" if eye_mode else "WASD / ZQSD  Move    SHIFT  Sprint    CTRL  Crouch    E  Interact    Q/A  Ability    G  Drop    TAB  Map    ESC  Pause"
	minimap.visible = eye_mode

func set_trial_names(mapping: Dictionary, contract_id: String) -> void:
	observance_label.text = {"first":"THE FIRST OBSERVANCE","second":"THE SECOND OBSERVANCE","mix":"THE SEEDED OBSERVANCE"}.get(contract_id,"THE OBSERVANCE")
	var index = 0
	for slot in ["silent","echoes","relay"]:
		seal_labels[slot].text = "%s  %s" % [["I  ","II ","III"][index],EyesTrialApparatus.TRIAL_NAMES[mapping[slot]]]
		index += 1

func toast(value: String, duration: float = 4.0) -> void:
	notification.text = value
	notification_left = duration

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	notification_left = maxf(0.0,notification_left-delta)
	notification.modulate.a = minf(1.0,notification_left)

func update_hud(info: Dictionary) -> void:
	var seconds = maxi(0,ceili(info.time))
	timer_label.text = "%02d:%02d" % [seconds/60,seconds%60]
	phase_label.text = info.phase
	health_label.text = info.health_text
	health_bar.value = info.health
	stamina_bar.value = info.stamina
	gaze_bar.value = info.gaze
	gaze_label.text = info.gaze_text
	gaze_label.add_theme_color_override("font_color",ROSE if info.gaze > 40 else MINT)
	ability_label.text = info.ability
	objective_label.text = info.objective
	hint_label.text = info.hint
	eye_label.text = "ACTIVE SOCKET  %02d  /  %s" % [info.socket+1,["NORTH","EAST","SOUTH","WEST"][info.socket]]
	compass_label.text = info.compass
	for key in seal_labels:
		seal_labels[key].add_theme_color_override("font_color",MINT if info.seals[key] else PAPER)
		seal_bars[key].value = info.progress[key]*100.0
	overlay_material.set_shader_parameter("danger",info.gaze/100.0)
	overlay_material.set_shader_parameter("strength",0.12 if settings.reduced_motion else 0.7)
	map_actor = info.position
	map_positions = info.bots
	map_eye = info.socket
	minimap.queue_redraw()

func _draw_map() -> void:
	minimap.draw_rect(Rect2(0,0,344,350),Color(0.025,0.06,0.075,0.92))
	minimap.draw_rect(Rect2(0,0,344,350),Color("526568"),false,1)
	minimap.draw_string(mono_font,Vector2(20,29),"CHAMBER / SIGHTLINES",HORIZONTAL_ALIGNMENT_LEFT,-1,12,GOLD)
	var origin = Vector2(172,191)
	var sc = 5.2
	minimap.draw_rect(Rect2(origin+Vector2(-27,-24)*sc,Vector2(54,48)*sc),Color("40545b"),false,1)
	minimap.draw_rect(Rect2(origin+Vector2(-2.65,-2.65)*sc,Vector2(5.3,5.3)*sc),Color("7c8e8e"))
	for x in [-9,9]:
		for z in [-6.5,6.5]:
			minimap.draw_rect(Rect2(origin+Vector2(x-3.6,z-0.4)*sc,Vector2(7.2,0.8)*sc),Color("7c8e8e"))
	for key in EyesArena.STATIONS:
		var p: Vector3 = EyesArena.STATIONS[key]
		minimap.draw_circle(origin+Vector2(p.x,p.z)*sc,5,MINT)
	minimap.draw_circle(origin+Vector2(0,-22)*sc,5,GOLD)
	var ep: Vector3 = EyesArena.SOCKETS[map_eye]
	minimap.draw_circle(origin+Vector2(ep.x,ep.z)*sc,6,ROSE)
	if not is_eye_mode:
		minimap.draw_circle(origin+Vector2(map_actor.x,map_actor.z)*sc,5,PAPER)
	for p in map_positions:
		minimap.draw_circle(origin+Vector2(p.x,p.z)*sc,4,MINT)
	minimap.draw_string(mono_font,Vector2(20,329),"NORTH ↑    TAB  Hide",HORIZONTAL_ALIGNMENT_LEFT,-1,10,MUTED)

func show_result(won: bool, text_value: String, stats: String) -> void:
	echo_panel.hide()
	result_panel.show()
	result_title.text = ("THE GAZE PREVAILS" if is_eye_mode else "YOU WERE UNSEEN") if won else ("THEY BROKE YOUR GAZE" if is_eye_mode else "THE EYE REMEMBERS")
	result_body.text = text_value
	result_stats.text = stats
