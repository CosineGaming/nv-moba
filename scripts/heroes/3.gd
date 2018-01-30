extends "res://scripts/player.gd"

var merge_power = .1
var merged = null

var old_layer
var old_mask

var allow_merge_time = 0
var allow_merge_threshold = 0.4

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	if is_network_master():
		allow_merge_time += delta
		if not merged and allow_merge_time > allow_merge_threshold:
			var cols = get_colliding_bodies()
			for col in cols:
				if col.is_in_group("player"):
					var same_team = col.player_info.is_right_team == player_info.is_right_team
					if same_team:
						rpc("merge", col.get_name())

		if merged and Input.is_action_just_pressed("hero_3_unmerge"):
				rpc("unmerge")

sync func merge(node_name):
	var other = get_node("/root/Level/Players").get_node(node_name)
	hide()
	print(other.get_name())
	# Disable collisions
	old_layer = collision_layer
	old_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	gravity_scale = 0
	if is_network_master():
		# Assume their PoV, but no control
		other.get_node("Yaw/Pitch/Camera").make_current()
		get_node("MasterOnly/Boosting").show()
	if other.is_network_master():
		var other_boosted = get_node("Boosted").duplicate()
		other_boosted.show()
		other.get_node("MasterOnly").add_child(other_boosted)
	# Boost them!
	other.walk_speed *= (1 + merge_power)
	other.air_accel *= (1 + merge_power)
	merged = other

sync func unmerge():
	show()
	gravity_scale = 1
	# Re-enable collisions
	collision_layer = old_layer
	collision_mask = old_mask
	if is_network_master():
		get_node("Yaw/Pitch/Camera").make_current()
	if merged.is_network_master():
		merged.get_node("MasterOnly/Boosting").queue_free()
	# Undo the boost
	merged.walk_speed /= (1 + merge_power)
	merged.air_accel /= (1 + merge_power)
	merged = null