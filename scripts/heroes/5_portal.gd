extends "res://scripts/placeable.gd"

var portal_charge = -5
var other

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

func _exit_tree():
	# We delete in pairs
	if other:
		maker_node.placement.placed.remove(index - 1)
		other.queue_free()

func init(maker, index):

	# If index is odd, we're the second (1, 3...), if even, first (0, 4...)
	var second = index % 2 != 0
	var is_friend = util.is_friendly(maker)
	var color_set = friend_colors if is_friend else enemy_colors
	var color = color_set[int(second)]

	var mat = SpatialMaterial.new()
	# color.a = 0.5
	# mat.flags_transparent = true
	mat.albedo_color = color
	get_node("MeshInstance").set_surface_material(0, mat)

	.init(maker, index)

func place():
	.place()
	var second = index % 2 != 0
	if second:
		# Our responsibility to complete the pairing
		other = maker_node.placement.placed[index - 1]
		other.other = self

func player_collided(with, player):
	if with == self:
		portal(player)

func portal(player):
	if player.player_info.is_right_team == maker_node.player_info.is_right_team:
		if other:
			if maker_node.switch_charge > -portal_charge:
				var spawn_distance = 1.75
				# Find a sane place to spawn
				# -Z is in the direction of the portal
				# X is enough away from the portal to avoid infinite loop
				# With both axes, gravity could never bring us to hit the portal
				var to = other.to_global(Vector3(spawn_distance,0,-spawn_distance)) 
				player.set_translation(to)
				maker_node.switch_charge += portal_charge

