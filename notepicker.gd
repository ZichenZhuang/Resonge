extends Node3D

@export_range(1, 6)
var line: int = 1
var points := 0

func _lane_for_key(keycode: int) -> int:
	match keycode:
		KEY_A:
			return 1
		KEY_S:
			return 2
		KEY_D:
			return 3
		KEY_J:
			return 4
		KEY_K:
			return 5
		KEY_L:
			return 6
		_:
			return -1

func _unhandled_input(event):
	if event is InputEventKey:
		var key = event.keycode
		
		# Check for single-line tap input (for current 'line')
		var key_for_line = {
			1: KEY_A,
			2: KEY_S,
			3: KEY_D,
			4: KEY_J,
			5: KEY_K,
			6: KEY_L,
		}
		if key_for_line.get(line, -1) == key and event.pressed:
			_try_hit_note()
		
		# General lane-based input handling
		var lane = _lane_for_key(key)
		if lane == -1:
			return
		
		if event.pressed:
			_handle_press(lane)
		else:
			_handle_release(lane)

func _try_hit_note():
	var notes = get_tree().get_nodes_in_group("notes")
	var HIT_ZONE_Z = 0.0
	var PERFECT_WINDOW = 1.0
	var GREAT_WINDOW   = 2.0

	for note in notes:
		if note.lane != line:
			continue

		# ← NEW: ignore hold notes so they aren’t freed here
		if note is NoteHold:
			continue

		var z    = note.global_transform.origin.z
		var dist = abs(z - HIT_ZONE_Z)

		if dist <= PERFECT_WINDOW:
			print("✅ PERFECT hit tap lane", line)
			points += 2
			note.queue_free()
			return
		elif dist <= GREAT_WINDOW:
			print("👍 GREAT hit tap lane", line)
			points += 1
			note.queue_free()
			return

var active_hold_notes := {}  # lane → NoteHold

func _handle_press(lane:int):
	#print("Pressed lane", lane)
	var note = _nearest_hittable_note(lane)
	if note == null:
		return

	if note is NoteHold:
		if note.hittable:
			note.start_hold()
			active_hold_notes[lane] = note
			_give_press_bonus(note)
		else:
			print("Hold note not hittable yet")
	else:
		_score_and_kill(note)

func _handle_release(lane: int):
	print("Released lane", lane)
	var note = active_hold_notes.get(lane)
	if note == null:
		return  # Released but nothing was being held

	if note.state in ["holding", "ready_to_release"]:
		note.end_hold()
		active_hold_notes.erase(lane)


func _nearest_hittable_note(lane:int) -> Node3D:
	var notes := get_tree().get_nodes_in_group("notes")
	var closest: Node3D = null
	var best_dist: float = INF
	for n in notes:
		if n.lane != lane: continue
		if not n.hittable: continue
		var dist: float = abs(n.global_transform.origin.z)
		if dist < best_dist:
			best_dist = dist
			closest = n
	return closest
	
func _score_and_kill(note: Node3D) -> void:
	# Increase points based on note's hit_quality if available
	if "hit_quality" in note and note.hit_quality != "":
		match note.hit_quality:
			"perfect":
				score_counter.add_score(100)
				print("✅ PERFECT tap hit!")
				
			"great":
				score_counter.add_score(50)
				print("👍 GREAT tap hit!")
			_:
				print("Hit note with unknown quality")
	else:
		# Default tap points if no hit_quality property
		points += 1
		print("✅ Tap hit!")
	
	# Remove the note from the scene
	note.queue_free()

func _give_press_bonus(note: Node3D) -> void:
	# Optional: Add bonus points or effects for starting a hold
	points += 1  # example bonus point
	print("Hold started, bonus point awarded!")
