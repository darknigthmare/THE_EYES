class_name EyesSoundscape
extends Node

var enabled: bool = true
var ambience: AudioStreamPlayer
var sounds: Dictionary = {}

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for key in ["step","warning","seal","fail","echo","pickup","blink","heartbeat"]:
		sounds[key] = load("res://assets/audio/"+key+".wav")
	ambience = AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/ambience.wav")
	if ambience.stream is AudioStreamWAV:
		ambience.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ambience.stream.loop_end = 44100*12
	ambience.volume_db = -22
	add_child(ambience)
	ambience.play()

func play(key: String, pitch: float = 1.0, volume: float = -10.0) -> void:
	if not enabled or not sounds.has(key):
		return
	var p = AudioStreamPlayer.new()
	p.stream = sounds[key]
	p.pitch_scale = pitch
	p.volume_db = volume
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func set_enabled(value: bool) -> void:
	enabled = value
	AudioServer.set_bus_mute(0,not enabled)

func _exit_tree() -> void:
	stop_all()

func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
	sounds.clear()
