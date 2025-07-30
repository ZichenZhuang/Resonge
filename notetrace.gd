extends Node3D

@export var speed: float

var lane: int = 1
var hittable: bool = false
var hit_registered: bool = false

const HIT_ZONE_Z = 0
const HIT_WINDOW = 1.0  # size of hittable zone before and after HIT_ZONE_Z

func _ready():
	add_to_group("notes")
	

func _process(delta):
	# Move note forward along Z
	print("Global position TRACE:", global_transform.origin)
	translate(Vector3(0, 0, 1) * speed * delta)

	var z_pos = global_transform.origin.z
	var dist = abs(z_pos - HIT_ZONE_Z)

	# Check if note is inside hit window
	if dist <= HIT_WINDOW:
		hittable = true
	else:
		hittable = false

	# If hittable and key is held, register hit once
