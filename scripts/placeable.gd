extends StaticBody

var maker_node

func init(maker):
	maker_node = maker

	var mat = get_node("MeshInstance").get_surface_material(0)
	mat.flags_transparent = true
	mat.albedo_color.a = 0.5

func place():
	# Originally, the ghost is disabled to avoid weird physics
	get_node("CollisionShape").disabled = false
	get_node("MeshInstance").get_surface_material(0).flags_transparent = false

func make_last():
	var mat = get_node("MeshInstance").get_surface_material(0)
	mat.flags_transparent = true
	mat.albedo_color.a = 0.9

