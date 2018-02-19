extends "res://scripts/placeable.gd"

var touch_charge = 4
var being_touched = 0

func _process(delta):
	if being_touched > 0:
		maker_node.switch_charge += touch_charge * delta

func init(maker):

	for player in get_node("/root/Level/Players").get_children():
		player.connect("body_entered", self, "count_bodies", [player, 1])
		player.connect("body_exited", self, "count_bodies", [player, -1])

	var master_player = get_node("/root/Level/Players/%d" % get_tree().get_network_unique_id())
	var friendly = maker.player_info.is_right_team == master_player.player_info.is_right_team
	var color = maker.friend_color if friendly else maker.enemy_color

	var mat = SpatialMaterial.new()
	color.a = 0.5
	mat.flags_transparent = true
	mat.albedo_color = color
	get_node("MeshInstance").set_surface_material(0, mat)

	.init(maker)

func count_bodies(with, player, delta):
	if with == self:
		if player != maker_node:
			being_touched += delta

