class_name NoteHold
extends Node3D

@export var speed: float
var duration: float = 1.0
var start_time: float = 0.0
var lane: int = 1

const HIT_ZONE_Z = 0.0
const PERFECT_WIN = 1.0
const GREAT_WIN   = 2.0
const PORTAL_Z    = -1.1	# anything beyond this is cropped on hold

var state: String = "idle"		# idle → holding → ready_to_release → done / missed
var hittable: bool = false
var hit_quality: String = ""
var hold_clock: float = 0.0
var lock_z: float = 0.0

var tail_mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("notes")
	_build_tail_mesh()

	# Lower spawn position by 1 unit on Z-axis (or adjust as needed)
	var pos = global_transform.origin
	global_transform.origin = pos

var freeze_movement: bool = false  # add at class level

func _process(delta: float) -> void:
	match state:
		"idle":
			if freeze_movement:
				print("DEBUG idle pos.z =", global_transform.origin.z)
			else:
				translate(Vector3(0, 0, 1) * speed * delta)
				_update_head_hittable()
				
			# Print local and global Z positions for debugging
			print("Local Z:", transform.origin.z, " | Global Z:", global_transform.origin.z)
		
		"holding", "ready_to_release":
			var pos = global_transform.origin
			pos.z = lock_z
			global_transform.origin = pos

			_update_tail_shrink()
			if state == "holding":
				hold_clock += delta
				var ms = delta * 1000.0
				score_counter.add_score(int(50 * ms))
				if hold_clock >= duration:
					state = "ready_to_release"
					print("🟢 Hold duration complete – release key lane", lane)

			if tail_mesh and is_instance_valid(tail_mesh):
				var tail_global_z = tail_mesh.global_transform.origin.z + (tail_mesh.mesh.size.z * 0.5)
				if tail_global_z > 18.0:
					print("🧹 Tail passed z=18.0 – deleting hold note lane", lane)
					queue_free()

			# Also print local and global Z here for debugging
			print("Local Z:", transform.origin.z, " | Global Z:", global_transform.origin.z)

		"done", "missed":
			queue_free()


func start_hold() -> void:
	if state != "idle":
		return

	var current_z := global_transform.origin.z
	var overrun = max(current_z - PORTAL_Z, 0.0) # how much we passed the portal

	# Snap head to PORTAL_Z regardless of early/late
	lock_z = PORTAL_Z
	var pos := global_transform.origin
	pos.z = PORTAL_Z
	global_transform.origin = pos

	# Tail trimming only if we're late
	if overrun > 0.0:
		_trim_tail(overrun)
		hold_clock = min(overrun / speed, duration)
		print("⏪ Late tap – trimming tail by", overrun)
	else:
		hold_clock = 0.0
		print("⏩ Early tap – no tail trim")

	# Freeze movement for debugging
	freeze_movement = true
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

	var mat := StandardMaterial3D.new()
	mat.depth_draw_mode = 2  # DEPTH_DRAW_NEVER
	mat.depth_test = false
	mat.albedo_color = Color(1, 1, 1)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.flags_unshaded = true

	# THIS MAKES IT 'NO DEPTH' — renders on top, no depth write/test
	mat.depth_draw_mode = 2  # DEPTH_DRAW_NEVER
	mat.depth_test = false
	mat.render_priority = 100
	tail_mesh.material_override = mat

	tail_mesh.position = Vector3(0, 0, -box.size.z * 0.5)
	add_child(tail_mesh)

func _trim_tail(overrun_dist: float) -> void:
	if not tail_mesh:
		return

	var old_box: BoxMesh = tail_mesh.mesh as BoxMesh
	var old_len: float = old_box.size.z
	var new_len: float = max(old_len - overrun_dist, 0.01)

	var new_box: BoxMesh = BoxMesh.new()
	new_box.size = Vector3(old_box.size.x, old_box.size.y, new_len)
	tail_mesh.mesh = new_box

	var shift_z: float = overrun_dist + (new_len * 0.5)
	tail_mesh.position = Vector3(0, 0, -shift_z)

	print("DEBUG _trim_tail: overrun =", overrun_dist,
		  " old_len =", old_len,
		  " new_len =", new_len,
		  " shift_z =", shift_z)

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
