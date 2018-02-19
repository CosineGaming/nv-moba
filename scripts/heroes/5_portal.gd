extends "res://scripts/placeable.gd"

var portal_charge = 15
var other
var index

var enemy_colors = [
	Color("#d14013"),
	Color("#ecb521"),
]

var friend_colors = [
	Color("#1209c4"),
	Color("#2066e7"),
]

func _ready():
	for player in get_node("/root/Level/Players").get_children():
		player.connect("body_entered", self, "player_collided", [player])

func init(maker):

	var maker_portals = maker.placement.placed
	index = maker_portals.size() # No -1, because we haven't actually been added to the array yet
	# If index is odd, we're the second (1, 3...), if even, first (0, 4...)
	var second = index % 2 != 0
	var is_friend = util.is_friendly(maker)
	var color_set = friend_colors if is_friend else enemy_colors
	var color = color_set[int(second)]

	var mat = SpatialMaterial.new()
	color.a = 0.5
	mat.flags_transparent = true
	mat.albedo_color = color
	get_node("MeshInstance").set_surface_material(0, mat)

	.init(maker)

func player_collided(with, player):
	if with == self:
		portal(player)

func find_other():
	var maker_portals = maker_node.placement.placed
	var count = maker_portals.size()
	# If index is odd, we're the second (1, 3...), if even, first (0, 4...)
	var second = index % 2 != 0
	var delta = -1 if second else 1
	if index + delta < count:
		other = maker_portals[index + delta] # Second-to-last: we're already included
		return other
	else:
		return null

func portal(player):
	if player.player_info.is_right_team == maker_node.player_info.is_right_team:
		if find_other():
			var spawn_distance = 2
			# Find a sane place to spawn
			# -Z is in the direction of the portal
			# X is enough away from the portal to avoid infinite loop
			# With both axes, gravity could never bring us to hit the portal
			var to = other.to_global(Vector3(spawn_distance,0,-spawn_distance)) 
			player.set_translation(to)
			maker_node.switch_charge += portal_charge

