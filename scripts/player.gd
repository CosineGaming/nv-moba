# Original: https://raw.githubusercontent.com/Calinou/fps-test/master/scripts/player.gd

extends RigidBody

var view_sensitivity = 0.25

# Walking speed and jumping height are defined later.
var walk_speed = 0.8 # Actually acceleration; m/s/s
var jump_speed = 5 # m/s
var air_accel = .1 # m/s/s
var floor_friction = 1-0.08
var air_friction = 1-0.03
var player_info # Set by lobby

var walk_speed_build = 0.006 # `walk_speed` per `switch_charge`
var air_speed_build = 0.006 # `air_accel` per `switch_charge`

var switch_charge = 0
var switch_charge_cap = 200 # While switching is always at 100, things like speed boost might go higher!
var movement_charge = 0.1 # In percent per meter (except when heroes change that)

const fall_height = -50

var debug_node
var recording

slave var slave_transform = Basis()
slave var slave_lin_v = Vector3()
slave var slave_ang_v = Vector3()

var tp_camera = "TPCamera"
var master_only = "MasterOnly"

var master_player
var friend_color = Color("#4ab0e5") # Blue
var enemy_color = Color("#f04273") # Red

var ai_instanced = false

signal spawn

func _ready():

	set_process_input(true)
	debug_node = get_node("/root/Level/Debug")
	if is_network_master():
		get_node(tp_camera).set_enabled(true)
		spawn()
		if "is_ai" in player_info and player_info.is_ai and not ai_instanced:
			add_child(preload("res://scenes/ai.tscn").instance())
			ai_instanced = true
	else:
		get_node("PlayerName").set_text(player_info.username)
		# Remove HUD
		remove_child(get_node(master_only))

sync func spawn():
	emit_signal("spawn")
	if "record" in player_info:
		write_recording() # Write each spawn as a separate recording
	var placement = Vector3()
	var x_varies = 5
	var z_varies = 5
	# No Z, because that's the left-right question
	if player_info.is_right_team:
		placement = get_node("/root/Level/RightSpawn").get_translation()
	else:
		placement = get_node("/root/Level/LeftSpawn").get_translation()
	# So we don't all spawn on top of each other
	placement.x += rand_range(0, x_varies)
	placement.z += rand_range(0, z_varies)
	recording = { "time": 0, "states": [], "events": [], "spawn": Vector3() }
	recording.spawn = var2str(placement)
	recording.switch_charge = var2str(switch_charge)
	set_transform(Basis())
	set_translation(placement)
	set_linear_velocity(Vector3())
	get_node(tp_camera).cam_yaw = 0
	get_node(tp_camera).cam_pitch = 0

func event_to_obj(event):
	var d = {}
	if event is InputEventMouseMotion:
		d.relative = {}
		d.relative.x = event.relative.x
		d.relative.y = event.relative.y
		d.type = "motion"
	if event is InputEventKey:
		d.scancode = event.scancode
		d.pressed = event.pressed
		d.echo = event.echo
		d.type = "key"
	if event is InputEventMouseButton:
		d.button_index = event.button_index
		d.pressed = event.pressed
		d.type = "mb"
	return d

func _input(event):
	if is_network_master():
		if Input.is_action_just_pressed("switch_hero"):
			switch_hero_interface()
		# Quit the game:
		if Input.is_action_pressed("quit"):
			quit()
		if "record" in player_info:
			recording.events.append([recording.time, event_to_obj(event)])

func begin():
	master_player = get_node("/root/Level/Players/%d" % get_tree().get_network_unique_id())
	# Set color to blue (teammate) or red (enemy)
	var color
	if master_player.player_info.is_right_team == player_info.is_right_team:
		color = friend_color
	else:
		color = enemy_color
	# We have a base MaterialSettings to use inheritance with heroes
	# Unfortunately we cannot do this with the actual meshes,
	# because godot decides if you change the mesh you wanted to change the material as well
	# So "MaterialSettings" is a dummy mesh in player.tscn that's hidden
	# We call .duplicate() so we can set this color without messing with other players' colors
	var mat = get_node("MaterialSettings").get_surface_material(0).duplicate()
	mat.albedo_color = color
	get_node("Yaw/MainMesh").set_surface_material(0, mat)
	get_node("Yaw/Pitch/RotatedHead").set_surface_material(0, mat)

func toggle_mouse_capture():
	if (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		view_sensitivity = 0
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		view_sensitivity = 0.25

# Update visual yaw + pitch components to match camera
func set_rotation():
	get_node("Yaw").set_rotation(Vector3(0, deg2rad(get_node(tp_camera).cam_yaw), 0))
	get_node("Yaw/Pitch").set_rotation(Vector3(deg2rad(-get_node(tp_camera).cam_pitch), 0, 0))

func record_status(status):
	if "record" in player_info:
		for i in range(status.size()):
			status[i] = var2str(status[i])
		recording.states.append([recording.time, status])

func _integrate_forces(state):
	if is_network_master():
		control_player(state)
		var status = get_status()
		rpc_unreliable("set_status", status)
		record_status(status)
	set_rotation()

slave func set_status(s):
	set_transform(s[0])
	set_linear_velocity(s[1])
	set_angular_velocity(s[2])
	get_node(tp_camera).cam_yaw = s[3]
	get_node(tp_camera).cam_pitch = s[4]

func get_status():
	return [
		get_transform(),
		get_linear_velocity(),
		get_angular_velocity(),
		get_node(tp_camera).cam_yaw,
		get_node(tp_camera).cam_pitch,
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

	# Detect jumpable
	var jumpable = false
	var jump_dot = 0.8 # If normal.dot(up) > jump_dot, we can jump
	for i in range(state.get_contact_count()):
		var n = state.get_contact_local_normal(i)
		if n.dot(Vector3(0,1,0)) > jump_dot:
			jumpable = true

	if jumpable: # We can navigate normally, we have a surface
		var up = state.get_total_gravity().normalized()
		var normal = ray.get_collision_normal()
		var floor_velocity = Vector3()
		var object = ray.get_collider()

		var accel = (1 + switch_charge * walk_speed_build) * walk_speed
		state.apply_impulse(Vector3(), direction * accel * get_mass())
		var lin_v = state.get_linear_velocity()
		lin_v.x *= floor_friction
		lin_v.z *= floor_friction
		state.set_linear_velocity(lin_v)

		if Input.is_action_just_pressed("jump"):
			state.apply_impulse(Vector3(), normal * jump_speed * get_mass())

	else:
		var accel = (1 + switch_charge * air_speed_build) * air_accel
		state.apply_impulse(Vector3(), direction * accel * get_mass())
		var lin_v = state.get_linear_velocity()
		lin_v.x *= air_friction
		lin_v.z *= air_friction
		state.set_linear_velocity(lin_v)

	state.integrate_forces()

func _process(delta):
	# All player code not caused by input, and not causing movement
	if is_network_master():
		var vel = get_linear_velocity()
		switch_charge += movement_charge * vel.length() * delta
		var switch_node = get_node("MasterOnly/SwitchCharge")
		switch_node.set_text("%.f%%" % switch_charge)
		if switch_charge >= 100:
			# Let switch_charge keep building, because we use it for walk_speed and things
			switch_node.set_text("100%% (%.f)\nQ - Switch hero" % switch_charge)
		if switch_charge > switch_charge_cap:
			# There is however a cap
			switch_charge = switch_charge_cap

		if get_translation().y < fall_height:
			rpc("spawn")

		if "record" in player_info:
			recording.time += delta

func switch_hero_interface():
	if switch_charge >= 100:
		# Interface needs the mouse!
		toggle_mouse_capture()
		# Pause so if we have walls and such nothing funny happens
		get_tree().set_pause(true)
		var interface = preload("res://scenes/HeroSelect.tscn").instance()
		add_child(interface)
		interface.get_node("Confirm").connect("pressed", self, "switch_hero_master")

func switch_hero_master():
	rpc("switch_hero", get_node("HeroSelect/Hero").get_selected_id())
	# Remove the mouse and enable looking again
	toggle_mouse_capture()
	get_tree().set_pause(false)

sync func switch_hero(hero):
	var new_hero = load("res://scenes/heroes/%d.tscn" % hero).instance()
	var net_id = int(get_name())
	set_name("%d-delete" % net_id) # Can't have duplicate names
	new_hero.set_name("%d" % net_id)
	new_hero.set_network_master(net_id)
	new_hero.player_info = player_info
	get_node("/root/Level/Players").call_deferred("add_child", new_hero)
	# We must wait until after _ready is called, so that we don't end up at spawn
	new_hero.call_deferred("set_status", get_status())
	new_hero.call_deferred("begin")
	queue_free()

func _exit_tree():
	if "record" in player_info:
		write_recording()

# Functions
# =========

func write_recording():
	if recording and recording.events.size() > 0:
		var save = File.new()
		var fname = "res://recordings/%d-%d-%d.rec" % [player_info.level, player_info.hero, randi() % 10000]
		save.open(fname, File.WRITE)
		save.store_line(to_json(recording))
		save.close()

# Quits the game:
func quit():
	get_tree().quit()

