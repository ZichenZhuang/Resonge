extends Node3D

func _ready():
	var parent = Node3D.new()
	add_child(parent)

	for i in range(7):
		var x_pos = i - 3  # from -3 to 3
		var line = MeshInstance3D.new()
		line.mesh = create_line_mesh(Vector3(x_pos, 0, 0), Vector3(x_pos, 0, 18))
		line.material_override = create_emissive_material(Color(255,255,255))  # Glowing yellowish
		parent.add_child(line)

func create_line_mesh(start: Vector3, end: Vector3) -> Mesh:
	var mesh = ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	return mesh

func create_emissive_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.albedo_color.a = 0.0001  # Set transparency here (0 = fully transparent, 1 = opaque)
	material.flags_transparent = true
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.5
	return material
