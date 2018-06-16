# Original: https://raw.githubusercontent.com/Calinou/fps-test/master/scripts/player.gd
# All heroes extend from here. Implements all common behavior

extends RigidBody

signal spawn

# Set by lobby. Contains player metadata (hero, nickname, etc)
var player_info

# Basic movement settings
# These are all public out here because they are customized by heroes

# Walking speed and jumping height are defined later.
var walk_speed = 0.8 # Actually acceleration; m/s/s
var jump_speed = 5 # m/s
var air_accel = .1 # m/s/s
var floor_friction = 1-0.08
var air_friction = 1-0.03

var walk_speed_build = 0.006 # `walk_speed` per `charge`
var air_speed_build = 0.006 # `air_accel` per `charge`

sync var charge = 0
var charge_cap = 200 # While switching is always at 100, things like speed boost might go higher!
var movement_charge = 0.18 # In percent per meter (except when heroes change that)

# Nodes
onready var switch_text = get_node("MasterOnly/ChargeBar/ChargeText")
onready var switch_bar = get_node("MasterOnly/ChargeBar")
onready var switch_bar_extra = get_node("MasterOnly/ChargeBar/Extra")
onready var switch_hero_action = get_node("MasterOnly/SwitchHero")
onready var tp_camera = get_node("TPCamera")
onready var master_only = get_node("MasterOnly")
onready var debug_node = get_node("/root/Level/Debug")

var recording
var ai_instanced = false

var friend_color = Color("#4ab0e5") # Blue
var enemy_color = Color("#f04273") # Red
# These meshes get colored with friendliness
var colored_meshes = [
	"Yaw/MainMesh",
	"Yaw/Pitch/RotatedHead",
]

func _ready():

	set_process_input(true)
	if is_network_master():
		get_node("TPCamera/Camera/Ray").add_exception(self)
		tp_camera.set_enabled(true)
		tp_camera.cam_view_sensitivity = 0.05
		if "is_ai" in player_info and player_info.is_ai and not ai_instanced:
			add_child(preload("res://scenes/ai.tscn").instance())
			ai_instanced = true
		spawn()
	else:
		get_node("PlayerName").set_text(player_info.username)
		# Remove HUD
		remove_child(master_only)

func _input(event):
	if is_network_master():
		if Input.is_action_just_pressed("switch_hero"):
			switch_hero_interface()
		# Quit the game:
		if Input.is_action_pressed("quit"):
			quit()
		if "record" in player_info:
			recording.events.append([recording.time, event_to_obj(event)])
		if Input.is_action_just_pressed("enable_cheats"):
			charge = 199

func _process(delta):
	# All player code not caused by input, and not causing movement
	if is_network_master():

		# Check falling (cancel charge and respawn)
		var fall_height = -400 # This is essentially the respawn timer
		var switch_height = -150 # At this point, stop adding to charge. This makes falls not charge you too much
		var vel = get_linear_velocity()
		if translation.y < switch_height:
			vel.y = 0 # Don't gain charge from falling when below switch_height
		build_charge(movement_charge * vel.length() * delta)
		if get_translation().y < fall_height:
			rpc("spawn")

		# Update charge GUI
		switch_text.set_text("%d%%" % int(charge)) # We truncate, rather than round, so that switch is displayed AT 100%
		if charge >= 100:
			switch_hero_action.show()
		else:
			switch_hero_action.hide()
		if charge > charge_cap:
			# There is however a cap
			charge = charge_cap
		switch_bar.value = charge
		switch_bar_extra.value = charge - 100

		# AI recording
		if "record" in player_info:
			recording.time += delta

		# on_looked_at is a special method for objects that need to respond to being looked at
		# This was the best way to implement Hero 1's passive ability,
		# But it'll probably come in handy more often so I made it kinda universal
		var looking_at = pick()
		if looking_at and looking_at.has_method("on_looked_at"):
			looking_at.on_looked_at(self, delta)

func _integrate_forces(state):
	if is_network_master():
		control_player(state)
		var status = get_status()
		rpc_unreliable("set_status", status)
		record_status(status)
	set_rotation()

func _exit_tree():
	if "record" in player_info:
		write_recording()

# Functions
# =========

# Build all charge with a multiplier for ~~balance~~
func build_charge(amount):
	# If we used build_charge to cost charge, don't mess with it!
	if amount > 0:
		var losing_advantage = 1.2
		var uncapped_advantage = 1.3
		var obj = get_node("/root/Level/FullObjective/Objective")
		if (obj.left > obj.right) == player_info.is_right_team:
			# Is losing (left winning, we're on right or vice versa)
			amount *= losing_advantage
		if obj.right_active != player_info.is_right_team and obj.active:
			# Point against us (right active and left, or vice versa)
			amount *= uncapped_advantage
	else:
		# Only build down to 0
		amount = max(amount, -charge)
	charge += amount
	if is_network_master():
		rset_unreliable("charge", charge)
	return amount

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
	recording.charge = var2str(charge)
	set_transform(Basis())
	set_translation(placement)
	set_linear_velocity(Vector3())
	tp_camera.cam_yaw = 0
	tp_camera.cam_pitch = 0

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

func begin():
	_set_color()

func _set_color():
	var master_player = util.get_master_player()
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
	for mesh in colored_meshes:
		get_node(mesh).set_surface_material(0, mat)

func toggle_mouse_capture():
	if (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Update visual yaw + pitch components to match camera
func set_rotation():
	get_node("Yaw").set_rotation(Vector3(0, deg2rad(tp_camera.cam_yaw), 0))
	get_node("Yaw/Pitch").set_rotation(Vector3(deg2rad(-tp_camera.cam_pitch), 0, 0))

func record_status(status):
	if "record" in player_info:
		for i in range(status.size()):
			status[i] = var2str(status[i])
		recording.states.append([recording.time, status])

remote func set_status(s):
	set_transform(s[0])
	set_linear_velocity(s[1])
	set_angular_velocity(s[2])
	tp_camera.cam_yaw = s[3]
	tp_camera.cam_pitch = s[4]

func get_status():
	return [
		get_transform(),
		get_linear_velocity(),
		get_angular_velocity(),
		tp_camera.cam_yaw,
		tp_camera.cam_pitch,
	]

func is_on_floor(state):
	var jump_dot = 0.5 # If normal.dot(up) > jump_dot, we can jump
	for i in range(state.get_contact_count()):
		var n = state.get_contact_local_normal(i)
		if n.dot(Vector3(0,1,0)) > jump_dot:
			return true
	return false

func control_player(state):

	var aim = global_transform.basis

	var direction = Vector3()

	if Input.is_action_pressed("move_forwards"):
		direction -= aim.z
	if Input.is_action_pressed("move_backwards"):
		direction += aim.z
	if Input.is_action_pressed("move_left"):
		direction -= aim.x
	if Input.is_action_pressed("move_right"):
		direction += aim.x

	direction = direction.normalized()
	var ray = get_node("Ray")

	# Detect jumpable
	var jumpable = is_on_floor(state)

	if jumpable: # We can navigate normally, we have a surface
		var up = state.get_total_gravity().normalized()
		var normal = ray.get_collision_normal()
		var floor_velocity = Vector3()
		var object = ray.get_collider()

		var accel = (1 + charge * walk_speed_build) * walk_speed
		state.apply_impulse(Vector3(), direction * accel * get_mass())
		var lin_v = state.get_linear_velocity()
		lin_v.x *= floor_friction
		lin_v.z *= floor_friction
		state.set_linear_velocity(lin_v)

		if Input.is_action_just_pressed("jump"):
			state.apply_impulse(Vector3(), normal * jump_speed * get_mass())

	else:
		var accel = (1 + charge * air_speed_build) * air_accel
		state.apply_impulse(Vector3(), direction * accel * get_mass())
		var lin_v = state.get_linear_velocity()
		lin_v.x *= air_friction
		lin_v.z *= air_friction
		state.set_linear_velocity(lin_v)

	state.integrate_forces()

func switch_hero_interface():
	if charge >= 100:
		# Interface needs the mouse!
		toggle_mouse_capture()
		# Pause so if we have walls and such nothing funny happens
		get_tree().set_pause(true)
		var interface = preload("res://scenes/hero_select.tscn").instance()
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
	queue_free()

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

# These aren't used by vanilla player, but are used by heroes in common

func pick():
	var look_ray = get_node("TPCamera/Camera/Ray")
	return look_ray.get_collider()
func pick_from(group):
	return group.find(pick())
func pick_player():
	var players = get_node("/root/Level/Players").get_children()
	var sel = pick_from(players)
	if sel != -1:
		return players[sel]
	else:
		return null
func pick_by_friendly(pick_friendlies):
	var pick = pick_player()
	if not pick:
		return null
	var friendly = (pick.player_info.is_right_team == player_info.is_right_team)
	# Friendly and picking friendly, or enemy and picking enemy
	if friendly == pick_friendlies:
		return pick
	else:
		return null

func preserve_direction(factor=1, ignore_y=true):
	var forward_node = $Yaw if ignore_y else $Yaw/Pitch
	var forward = -forward_node.get_global_transform().basis.z.normalized()
	var current = linear_velocity
	if ignore_y:
		current.y = 0
	linear_velocity += factor * current.length() * forward
	linear_velocity -= factor * current

# =========
