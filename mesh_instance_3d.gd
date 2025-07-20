extends MeshInstance3D

var shader_material := ShaderMaterial.new()


const HIT_ZONE_Z = 0
const HIT_WINDOW = 0.5


#func _draw_hit_line():
	#var hit_line = MeshInstance3D.new()
	#var mesh = BoxMesh.new()
	#mesh.size = Vector3(10, 0.1, HIT_WINDOW * 2.0)
	#hit_line.mesh = mesh
#
	#var mat = StandardMaterial3D.new()
	#mat.albedo_color = Color(1, 0, 0)
	#hit_line.material_override = mat
#
	#hit_line.position = Vector3(0, 0, HIT_ZONE_Z)
	#add_child(hit_line)


func _ready():
	#_draw_hit_line()
	mesh = create_glowing_line(Vector3(-2.9, 0, 0), Vector3(2.9, 0, 0))
	shader_material.shader = create_glow_shader()
	material_override = shader_material

	# Optional: lift line slightly above ground if needed
	position.y = 0.1

func create_glow_shader() -> Shader:
	var shader_code := """
		shader_type spatial;
		render_mode unshaded;

		uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
		uniform float glow_strength : hint_range(0.0, 5.0) = 3.0;

		void fragment() {
			ALBEDO = line_color.rgb;
			EMISSION = line_color.rgb * glow_strength;
		}
	"""
	var shader = Shader.new()
	shader.set_code(shader_code)
	return shader

func create_glowing_line(start: Vector3, end: Vector3) -> Mesh:
	var mesh := ImmediateMesh.new()
	mesh.clear_surfaces()

	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()

	return mesh
