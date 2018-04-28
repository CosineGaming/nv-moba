# Stuns people at a distance, removing their linear velocity

extends "res://scripts/player.gd"

onready var destroy_ability = get_node("MasterOnly/Destroy")

var stun_charge = 1
var velocity_charge = 10 # This one is instantaneous, so it gets quita weight

var zoom_factor = 3
var sens_factor = 10

# --- Godot overrides ---

func _ready():
	colored_meshes.append("Yaw/Pitch/Beam")

func _process(delta):
	if is_network_master():

		var stun = Input.is_action_pressed("hero_4_stun")
		var is_stunning = false

		if Input.is_action_just_pressed("hero_4_zoom"):
			get_node("TPCamera").cam_fov /= zoom_factor
			get_node("TPCamera").cam_view_sensitivity /= sens_factor
			get_node("TPCamera").cam_smooth_movement = false
		if Input.is_action_just_released("hero_4_zoom"):
			get_node("TPCamera").cam_fov *= zoom_factor
			get_node("TPCamera").cam_view_sensitivity *= sens_factor
			get_node("TPCamera").cam_smooth_movement = true

		var looking_at = pick()
		if looking_at and looking_at.has_method("destroy"):
			destroy_ability.cost = looking_at.destroy_cost
			destroy_ability.disabled = false
			if Input.is_action_just_pressed("primary_ability"):
					if switch_charge > looking_at.destroy_cost:
						switch_charge -= looking_at.destroy_cost
						looking_at.rpc("destroy")
		else:
			destroy_ability.disabled = true

		if stun:
			var players = get_node("/root/Level/Players").get_children()
			var player = pick_from(players)
			if player != -1:
				# We get charge for just stunning, plus charge for how much linear velocity we cut out
				switch_charge += stun_charge * delta
				switch_charge += velocity_charge * players[player].get_linear_velocity().length() * delta
				rpc("stun", players[player].get_name(), get_node("TPCamera/Camera/Ray").get_collision_point())
				is_stunning = true

		if not is_stunning:
			rpc("unstun")

# --- Player overrides ---

# --- Own ---

sync func stun(net_id, position):
	# Stun the thing!
	var player = get_node("/root/Level/Players/%s" % net_id)
	player.set_linear_velocity(Vector3())

	# Show the beam!
	var beam = get_node("Yaw/Pitch/Beam")
	get_node("Yaw/Pitch").look_at(position, Vector3(0,1,0))
	beam.show()
	var us = get_node("TPCamera/Camera").get_global_transform().origin
	var distance = position - us
	beam.scale = Vector3(1,distance.length(),1)
	# We move the beam up by half the scale because the position is based on the center, not the bottom
	beam.translation.z = -distance.length() / 2 # We face -z direction

sync func unstun():
	var beam = get_node("Yaw/Pitch/Beam")
	beam.hide()

