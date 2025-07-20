extends Node3D

@onready var bg_sprite: Node3D = $backgroundSprite

func _change_background(bg_name: String) -> void:
	var path = "res://backgrounds/" + bg_name + ".png"
	var bg_texture = load(path)
	
	if bg_texture is Texture2D:
		bg_sprite.texture = bg_texture

		var tex_size = bg_texture.get_size() 
		var scale_x = 5000/ tex_size.x
		var scale_y = 3000/ tex_size.y

	
		bg_sprite.scale = Vector3(scale_x, scale_y, 1.0)
	else:
		print("Coded wrong idiot:", path)

func _ready() -> void:
	_change_background("abandonedCity")
	$backgroundSprite.scale = bg_sprite.scale
