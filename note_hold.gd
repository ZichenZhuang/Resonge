class_name NoteHold
extends Node3D

@export var speed: float
var duration: float = 1.0
var start_time: float = 0.0
var lane: int = 1

const HIT_ZONE_Z = 0.0
const PERFECT_WIN = 1.0
const GREAT_WIN   = 2.0
const PORTAL_Z    = 17.0	# anything beyond this is cropped on hold

var state: String = "idle"		# idle → holding → ready_to_release → done / missed
var hittable: bool = false
var hit_quality: String = ""
var hold_clock: float = 0.0
var lock_z: float = 0.0

var tail_mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("notes")
	_build_tail_mesh()

func _process(delta: float) -> void:
	match state:
		"idle":
			translate(Vector3(0, 0, 1) * speed * delta)
			_update_head_hittable()
			if global_transform.origin.z > HIT_ZONE_Z + GREAT_WIN + 1.0:
				state = "missed"
				print("🔴 Missed HOLD note lane", lane)
		"holding", "ready_to_release":
			# Lock head position at lock_z
			var pos = global_transform.origin
			pos.z = lock_z
			global_transform.origin = pos
			
			_update_tail_shrink()
			if state == "holding":
				hold_clock += delta
				if hold_clock >= duration:
					state = "ready_to_release"
					print("🟢 Hold duration complete – release key lane", lane)
		"done", "missed":
			queue_free()

func start_hold() -> void:
	if state != "idle":
		return

	lock_z = global_transform.origin.z  # current head position

	if lock_z > PORTAL_Z:
		# User tapped late, trim tail immediately
		var overrun: float = lock_z - PORTAL_Z
		_trim_tail(overrun)

		# Preload hold_clock to the corresponding elapsed time (clamped)
		var elapsed_time: float = min(overrun / speed, duration)
		hold_clock = elapsed_time

		print("⏳ Late tap: trimming tail for overrun", overrun)
	else:
		hold_clock = 0.0

	state = "holding"
	print("⏳ Holding… lane", lane, "remain", str(duration - hold_clock), "s")

func end_hold() -> void:
	if state == "holding":
		state = "missed"
		print("❌ Released early – miss lane", lane)
	elif state == "ready_to_release":
		state = "done"
		print("✅ Hold complete lane", lane)

func _update_head_hittable() -> void:
	var dist: float = abs(global_transform.origin.z - HIT_ZONE_Z)
	hittable = dist <= GREAT_WIN
	if dist <= PERFECT_WIN:
		hit_quality = "perfect"
	elif dist <= GREAT_WIN:
		hit_quality = "great"
	else:
		hit_quality = ""

# ---------- tail helpers ----------
func _build_tail_mesh() -> void:
	if tail_mesh and is_instance_valid(tail_mesh):
		remove_child(tail_mesh)
		tail_mesh.queue_free()

	tail_mesh = MeshInstance3D.new()
	tail_mesh.name = "tail"

	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.1, speed * duration)
	tail_mesh.mesh = box

	# Bright white unlit material with emission
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.flags_unshaded = true
	tail_mesh.material_override = mat

	tail_mesh.position = Vector3(0, 0, -box.size.z * 0.5)
	add_child(tail_mesh)

func _trim_tail(overrun_dist: float) -> void:
	if not tail_mesh:
		return
	var old_box: BoxMesh = tail_mesh.mesh as BoxMesh
	var new_len: float = max(old_box.size.z - overrun_dist, 0.01)

	# Create a new BoxMesh with updated size
	var new_box := BoxMesh.new()
	new_box.size = Vector3(old_box.size.x, old_box.size.y, new_len)

	tail_mesh.mesh = new_box
	tail_mesh.position = Vector3(0, 0, -new_len * 0.5)

func _update_tail_shrink() -> void:
	if not tail_mesh:
		return  # no tail to update

	var remaining_frac: float = clamp(1.0 - hold_clock / duration, 0.0, 1.0)
	var new_len: float = speed * duration * remaining_frac

	# Remove tail when length is near zero
	if new_len <= 0.001:
		tail_mesh.queue_free()
		tail_mesh = null
		print("Hold tail deleted (length reached zero)")
		return

	# Update tail size and position if tail_mesh still exists
	var new_box := BoxMesh.new()
	new_box.size = Vector3(0.8, 0.1, new_len)  # fixed X,Y size

	tail_mesh.mesh = new_box
	tail_mesh.position = Vector3(0, 0, -new_len * 0.5)

	print("Hold tail length:", new_len)

func set_duration(new_duration: float) -> void:
	duration = new_duration
	if is_inside_tree():
		# If tail was freed previously (tail_mesh == null), rebuild it
		if tail_mesh == null:
			_build_tail_mesh()
		else:
			# Otherwise just rebuild the mesh with updated duration
			_build_tail_mesh()
