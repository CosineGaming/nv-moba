extends StaticBody

var maker_node
var touch_charge = 4
var being_touched = 0

func init(maker, color):
	maker_node = maker
	for player in get_node("/root/Level/Players").get_children():
		player.connect("body_entered", self, "count_bodies", [player, 1])
		player.connect("body_exited", self, "count_bodies", [player, -1])
	var mat = SpatialMaterial.new()
	color.a = 0.5
	mat.flags_transparent = true
	mat.albedo_color = color
	get_node("MeshInstance").set_surface_material(0, mat)

func place():
	# Originally, the wall is disabled to avoid weird physics
	get_node("CollisionShape").disabled = false
	get_node("MeshInstance").get_surface_material(0).flags_transparent = false

func make_last():
	var mat = get_node("MeshInstance").get_surface_material(0)
	mat.flags_transparent = true
	mat.albedo_color.a = 0.9

func count_bodies(with, player, delta):
	if with == self:
		if player != maker_node:
			being_touched += delta

func _process(delta):
	if being_touched > 0:
		maker_node.switch_charge += touch_charge * delta

