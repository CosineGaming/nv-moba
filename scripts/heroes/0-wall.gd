extends StaticBody

var maker_node
var touch_charge = 1

func init(maker, color):
	maker_node = maker
	var mat = SpatialMaterial.new()
	color.a = 0.5
	mat.flags_transparent = true
	mat.albedo_color = color
	get_node("MeshInstance").set_surface_material(0, mat)

func place():
	# Originally, the wall is disabled to avoid weird physics
	get_node("CollisionShape").disabled = false
	get_node("MeshInstance").get_surface_material(0).flags_transparent = false

func _process(delta):
	pass
	# var cols = get_colliding_bodies()
	# for col in cols:
	# 	if col != maker_node: # Don't count ourself. This encourages teamwork and discourages wall-touching-for-charge abuse
	# 		maker_node.switch_charge += touch_charge * delta

