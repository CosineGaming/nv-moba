# Hero three boosts a friend, making them faster

extends "res://scripts/player.gd"

var merge_power = .75
var merged = null

var old_layer
var old_mask

var allow_merge_time = 0
var allow_merge_threshold = 0.4

var original_charge
var boost_charge = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _exit_tree():
	unmerge() # Checks if necessary automatically

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
		if merged:
			# Subtract and then add, so we can continously add this
			switch_charge -= boost_charge
			boost_charge = merged.switch_charge - original_charge
			build_charge(boost_charge)

func control_player(state):
	if !merged:
		.control_player(state)

func set_collisions(on):
	if on:
		collision_layer = old_layer
		collision_mask = old_mask
		gravity_scale = 1
	else:
		old_layer = collision_layer
		old_mask = collision_mask
		collision_layer = 0
		collision_mask = 0
		gravity_scale = 0

func set_boosted_label(node, on):
	if on:
		var boosted_label = $Boosted.duplicate()
		boosted_label.show()
		node.add_child(boosted_label)
	else:
		var boosted_label = node.get_node("Boosted")
		boosted_label.queue_free()

func set_boosting(is_boosting):
	set_collisions(!is_boosting)
	visible = !is_boosting
	if is_network_master():
		get_node("MasterOnly/Boosting").visible = is_boosting
		get_node(tp_camera).set_enabled(!is_boosting)

func set_boosted(node, is_boosted):
	if is_network_master():
		# Assume their PoV, but no control
		node.get_node(node.tp_camera).set_enabled(is_boosted)
	if node.is_network_master():
		set_boosted_label(node, is_boosted)
	var ratio = (1 + merge_power)
	if !is_boosted:
		ratio = 1/ratio # Undo the effect
	node.walk_speed *= ratio
	node.air_accel *= ratio
	if is_boosted:
		original_charge = node.switch_charge
		boost_charge = 0

sync func merge(node_name):
	set_boosting(true)
	var other = $"/root/Level/Players".get_node(node_name)
	set_boosted(other, true)
	merged = other

sync func unmerge():
	if merged:
		set_boosted(merged, false)
		set_boosting(false)
		var pos = merged.get_translation()
		pos.z += 1
		set_translation(pos)
		merged = null

