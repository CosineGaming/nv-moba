extends "res://scripts/player.gd"

var merge_power = .1
var merged = null

var old_layer
var old_mask

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	if not merged:
		var cols = get_colliding_bodies()
		for col in cols:
			if col.is_in_group("player"):
				var same_team = col.player_info.is_right_team == player_info.is_right_team
				if same_team:
					merge(col)

func merge(other):
	hide()
	# Disable collisions
	old_layer = collision_layer
	old_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	if is_network_master():
		# Assume their PoV, but no control
		other.get_node("Yaw/Pitch/Camera").make_current()
	# Boost them!
	other.walk_speed *= (1 + merge_power)
	other.air_accel *= (1 + merge_power)
	merged = other

func unmerge():
	show()
	# Re-enable collisions
	collision_layer = old_layer
	collision_mask = old_mask
	if is_network_master():
		get_node("Yaw/Pitch/Camera").make_current()
	# Undo the boost
	merged.walk_speed /= (1 + merge_power)
	merged.air_accel /= (1 + merge_power)
	merged = null