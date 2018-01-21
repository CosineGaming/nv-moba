# Copyright (c) 2015 Calinou
# This source code form is governed by the MIT license.
# Original: https://raw.githubusercontent.com/Calinou/fps-test/master/scripts/player.gd

extends RigidBody

var view_sensitivity = 0.25
var yaw = 0
var pitch = 0

var timer = 0

# Walking speed and jumping height are defined later.
var walk_speed = 2
var jump_speed = 3
const air_accel = .6
var floor_friction = 0.92
var air_friction = 0.98

var health = 100
var stamina = 10000

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

func _input(event):
	if is_network_master():

		if event is InputEventMouseMotion:
			yaw = fmod(yaw - event.relative.x * view_sensitivity, 360)
			pitch = max(min(pitch - event.relative.y * view_sensitivity, 85), -85)
			get_node("Yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
			get_node("Yaw/Pitch").set_rotation(Vector3(deg2rad(pitch), 0, 0))

		# Toggle mouse capture:
		if Input.is_action_pressed("toggle_mouse_capture"):
			if (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				view_sensitivity = 0
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				view_sensitivity = 0.25

		# Quit the game:
		if Input.is_action_pressed("quit"):
			quit()


master func _integrate_forces(state):
	control_player(state)
	rpc_unreliable("set_status", get_transform(), get_linear_velocity(), get_angular_velocity())

slave func set_status(tf, lv, av):
	set_transform(tf)
	set_linear_velocity(lv)
	set_angular_velocity(av)

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

		if object is RigidBody or object is StaticBody:
			var point = ray.get_collision_point() - object.get_translation()
			var floor_angular_vel = Vector3()
			if object is RigidBody:
				floor_velocity = object.get_linear_velocity()
				floor_angular_vel = object.get_angular_velocity()
			elif object is StaticBody:
				floor_velocity = object.get_constant_linear_velocity()
				floor_angular_vel = object.get_constant_angular_velocity()
			# Surely there should be a function to convert Euler angles to a 3x3 matrix
			var tf = Basis(Vector3(1, 0, 0), floor_angular_vel.x)
			tf = tf.rotated(Vector3(0, 1, 0), floor_angular_vel.y)
			tf = tf.rotated(Vector3(0, 0, 1), floor_angular_vel.z)
			floor_velocity += tf.xform_inv(point) - point
			yaw = fmod(yaw + rad2deg(floor_angular_vel.y) * state.get_step(), 360)
			get_node("Yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))

		var diff = floor_velocity + direction * walk_speed
		state.apply_impulse(Vector3(), diff * get_mass())
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

	state.integrate_forces()

func _exit_scene():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Functions
# =========

# Quits the game:
func quit():
	get_tree().quit()
