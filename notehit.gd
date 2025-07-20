extends Node3D

@export var speed: float

var lane: int = 1
var hittable: bool = false
var hit_quality: String = ""  # "perfect", "great", or ""

const HIT_ZONE_Z = 0
const PERFECT_WINDOW = 1
const GREAT_WINDOW = 2

func _ready():
	add_to_group("notes")
	#print("🟡 Spawned note on lane", lane, "at Z =", global_transform.origin.z)

func _process(delta):
	translate(Vector3(0, 0, 1) * speed * delta)

	var z_pos = global_transform.origin.z
	var dist = abs(z_pos - HIT_ZONE_Z)

	if dist <= PERFECT_WINDOW:
		hittable = true
		hit_quality = "perfect"
	elif dist <= GREAT_WINDOW:
		hittable = true
		hit_quality = "great"
	else:
		hittable = false
		hit_quality = ""

	if z_pos > HIT_ZONE_Z + GREAT_WINDOW + 1.0:
		# Miss detected because note passed hit zone without being hit
		print("🔴 Missed note on lane", lane)
		queue_free()
