# Copyright (c) 2015 Calinou
# This source code form is governed by the MIT license.
# Original: https://raw.githubusercontent.com/Calinou/fps-test/master/scripts/player.gd

extends RigidBody

var view_sensitivity = 0.25
var yaw = 0
var pitch = 0

const max_accel = 0.005
const air_accel = 0.02

var timer = 0

# Walking speed and jumping height are defined later.
var walk_speed
var jump_speed

var health = 100
var stamina = 10000
var ray_length = 10

slave var slave_transform = Basis()
slave var slave_lin_v = Vector3()
slave var slave_ang_v = Vector3()

func _ready():
	set_process_input(true)

	# Capture mouse once game is started:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	#set_physics_process(true)
	get_node("Crosshair").set_text("+")
	
	if is_network_master():
		get_node("Yaw/Camera").make_current()

func _input(event):
	if is_network_master():
		
		if event is InputEventMouseMotion:
			yaw = fmod(yaw - event.relative.x * view_sensitivity, 360)
			pitch = max(min(pitch - event.relative.y * view_sensitivity, 85), -85)
			get_node("Yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
			get_node("Yaw/Camera").set_rotation(Vector3(deg2rad(pitch), 0, 0))
	
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



func _integrate_forces(state):
	
	if is_network_master():
		control_player(state)
		rset_unreliable("slave_transform", get_transform())
		rset_unreliable("slave_lin_v", get_linear_velocity())
		rset_unreliable("slave_ang_v", get_angular_velocity())
	else:
		set_transform(slave_transform)
		set_linear_velocity(slave_lin_v)
		set_angular_velocity(slave_ang_v)

func control_player(state):
	
	# Default walk speed:
	walk_speed = 5
	# Default jump height:
	jump_speed = 3

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
	
	# Increase walk speed and jump height while running and decrement stamina:
	if Input.is_action_pressed("run") and is_moving and ray.is_colliding():
		walk_speed *= 1.4
		jump_speed *= 1.2
	
	print("---")
	print(state.get_linear_velocity())

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
			print("isRB||isSB")

		var diff = floor_velocity + direction * walk_speed - state.get_linear_velocity()
		var vertdiff = aim[1] * diff.dot(aim[1])
		print("VD: " + str(vertdiff))
		diff -= vertdiff
		diff = diff.normalized() * clamp(diff.length(), 0, max_accel / state.get_step())
		diff += vertdiff

		print("D: " + str(diff))
		apply_impulse(Vector3(), diff * get_mass())

		if Input.is_action_pressed("jump"):
			apply_impulse(Vector3(), normal * jump_speed * get_mass())

	else:
		apply_impulse(Vector3(), direction * air_accel * get_mass())
	
	print(get_translation())
	print(state.get_linear_velocity())

	state.integrate_forces()

func _exit_scene():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Functions
# =========

# Quits the game:
func quit():
	get_tree().quit()
