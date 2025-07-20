class_name note_spawner
extends Node3D

@export var tap_scene : PackedScene        # Assign your tap note scene here in the editor
@export var hold_scene : PackedScene       # Assign your hold note scene here in the editor
@export var lane_spawns : Array[NodePath]  # Assign your 6 Marker3Ds in the editor
@export var note_travel_time := 17     # Speed for note movement

var beatmap = [
	{ "time": -2.0, "lane": 1, "type": "tap" },
	{ "time": 2.0, "lane": 2, "type": "hold", "duration": 1 },  # Hold note starting at 3s, lasts 2.5 seconds
]

var timer := 0.0
var next_note_index := 0
var is_playing := false

func _ready():
	if not tap_scene:
		print("tap_scene not assigned!")
	if not hold_scene:
		print("hold_scene not assigned!")
	if lane_spawns.size() == 0:
		print("lane_spawns is empty! Assign lane spawn nodes.")

	start()

func start():
	timer = 0.0
	next_note_index = 0
	is_playing = true

func _process(delta):
	if not is_playing:
		return

	while next_note_index < beatmap.size() and beatmap[next_note_index]["time"] <= timer:
		var data = beatmap[next_note_index]
		print("Spawning note:", data)
		spawn_note(data)
		next_note_index += 1

	timer += delta



func spawn_note(data: Dictionary) -> void:
	var lane_index: int = data["lane"]

	# Validate lane index
	if lane_index - 1 < 0 or lane_index - 1 >= lane_spawns.size():
		push_error("lane_index out of bounds: %d" % lane_index)
		return

	# Get spawn node for lane
	var spawn_node = get_node(lane_spawns[lane_index - 1])
	if spawn_node == null:
		push_error("Spawn node is null for lane %d" % lane_index)
		return

	# Choose scene
	var scene: PackedScene = null
	if data.has("type") and data["type"] == "hold":
		scene = hold_scene
	else:
		scene = tap_scene

	if scene == null:
		push_error("Scene is null! Cannot spawn note for lane %d" % lane_index)
		return

	# Instantiate note
	var inst = scene.instantiate()
	print("Instantiated note of type: ", inst.get_class())

	# If it's a hold note, set specific properties
	if inst is NoteHold:
		var hold_note := inst as NoteHold
		hold_note.set_duration(data.get("duration", 1.0))
		hold_note.start_time = data["time"]
		hold_note.lane = lane_index
		hold_note.speed = note_travel_time
		print("Configured NoteHold: lane=%d, duration=%.2f, speed=%.2f" % [hold_note.lane, hold_note.duration, hold_note.speed])
	else:
		# For tap notes or other types, try to assign lane and speed only if they exist
		if "lane" in inst:
			inst.lane = lane_index
			print("Assigned lane %d to %s" % [lane_index, inst.get_class()])
		else:
			print("Warning: Instantiated node does not have 'lane' property")

		if "speed" in inst:
			inst.speed = note_travel_time
			print("Assigned speed %.2f to %s" % [note_travel_time, inst.get_class()])
		else:
			print("Warning: Instantiated node does not have 'speed' property")

	inst.global_transform.origin = spawn_node.global_transform.origin
	get_parent().add_child(inst)
	print("Spawned note at lane %d at position %s" % [lane_index, str(inst.global_transform.origin)])
