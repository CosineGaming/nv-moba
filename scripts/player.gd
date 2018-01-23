# Original: https://raw.githubusercontent.com/Calinou/fps-test/master/scripts/player.gd

extends RigidBody

var view_sensitivity = 0.25
var yaw = 0
var pitch = 0

# Walking speed and jumping height are defined later.
var walk_speed = 1
var jump_speed = 3
const air_accel = .6
var floor_friction = 0.92
var air_friction = 0.98
var player_info # Set by lobby

var switch_charge = 0
var movement_charge = 0.0015

var debug_node

slave var slave_transform = Basis()
slave var slave_lin_v = Vector3()
slave var slave_ang_v = Vector3()

func _ready():
	set_process_input(true)

	# Capture mouse once game is started:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	debug_node = get_node("/root/world/Debug")

	if is_network_master():
		get_node("Yaw/Pitch/Camera").make_current()
		spawn()
	else:
		remove_child(get_node("MasterOnly"))

func spawn():
	var placement = Vector3()
	var x_varies = 10
	var y_varies = 20
	# No Z, because that's the left-right question
	if player_info.is_right_team:
		placement = get_node("/root/world/RightSpawn").get_translation()
	else:
		placement = get_node("/root/world/LeftSpawn").get_translation()
	# So we don't all spawn on top of each other
	placement.x += rand_range(0, x_varies)
	placement.y += rand_range(0, y_varies)
	set_translation(placement)

func _input(event):
	if is_network_master():

		if event is InputEventMouseMotion:
			yaw = fmod(yaw - event.relative.x * view_sensitivity, 360)
			pitch = max(min(pitch - event.relative.y * view_sensitivity, 85), -85)
			set_rotation()

		# Toggle mouse capture:
		if Input.is_action_pressed("toggle_mouse_capture"):
			if (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				view_sensitivity = 0
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				view_sensitivity = 0.25

		if Input.is_action_just_pressed("switch_hero"):
			switch_hero_interface()
		# Quit the game:
		if Input.is_action_pressed("quit"):
			quit()

func set_rotation():
	get_node("Yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
	get_node("Yaw/Pitch").set_rotation(Vector3(deg2rad(pitch), 0, 0))

func _integrate_forces(state):
	if is_network_master():
		control_player(state)
		rpc_unreliable("set_status", get_status())

slave func set_status(s):
	set_transform(s[0])
	set_linear_velocity(s[1])
	set_angular_velocity(s[2])
	yaw = s[3]
	pitch = s[4]
	set_rotation() # Confirm yaw + pitch changes

func get_status():
	return [
		get_transform(),
		get_linear_velocity(),
		get_angular_velocity(),
		yaw,
		pitch,
	]

func control_player(state):

	var aim = get_node("Yaw").get_global_transform().basis

	var direction = Vector3()

	if Input.is_action_pressed("move_forwards"):
		direction -= aim[2]
	if Input.is_action_pressed("move_backwards"):
		direction += aim[2]
	if Input.is_action_pressed("move_left"):
		direction -= aim[0]
	if Input.is_action_pressed("move_right"):
		direction += aim[0]

	direction = direction.normalized()
	var ray = get_node("Ray")

	if ray.is_colliding():
		var up = state.get_total_gravity().normalized()
		var normal = ray.get_collision_normal()
		var floor_velocity = Vector3()
		var object = ray.get_collider()

		state.apply_impulse(Vector3(), direction * walk_speed * get_mass())
		var lin_v = state.get_linear_velocity()
		lin_v.x *= floor_friction
		lin_v.z *= floor_friction
		state.set_linear_velocity(lin_v)

		if Input.is_action_pressed("jump"):
			state.apply_impulse(Vector3(), normal * jump_speed * get_mass())

	else:
		state.apply_impulse(Vector3(), direction * air_accel * get_mass())
		var lin_v = state.get_linear_velocity()
		lin_v.x *= air_friction
		lin_v.z *= air_friction
		state.set_linear_velocity(lin_v)

	var vel = get_linear_velocity()
	switch_charge += movement_charge * vel.length()
	get_node("MasterOnly/SwitchCharge").set_text("%.f%%" % switch_charge)

	state.integrate_forces()

func switch_hero_interface():
	# TODO: Make a real interface
	player_info.hero += 1
	rpc("switch_hero", player_info.hero)

sync func switch_hero(hero):
	var new_hero = load("res://scenes/heroes/%d.tscn" % hero).instance()
	var net_id = get_tree().get_network_unique_id()
	set_name("%d-delete" % net_id) # Can't have duplicate names
	new_hero.set_name("%d" % net_id)
	new_hero.set_network_master(net_id)
	new_hero.player_info = player_info
	get_node("/root/world/players").call_deferred("add_child", new_hero)
	# We must wait until after _ready is called, so that we don't end up at spawn
	new_hero.call_deferred("set_status", get_status())
	queue_free()

func _exit_scene():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Functions
# =========

# Quits the game:
func quit():
	get_tree().quit()
