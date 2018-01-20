# Copyright (c) 2015 Calinou
# This source code form is governed by the MIT license.
# Original: https://raw.githubusercontent.com/Calinou/fps-test/master/scripts/player.gd

extends KinematicBody

var view_sensitivity = 0.25
var yaw = 0
var pitch = 0

const air_accel = 0.02

var gravity = -1
var tf = Basis()
var velocity = Vector3()

var timer = 0

# Walking speed and jumping height are defined later.
var walk_speed = 3
var jump_speed = 15

var health = 100
var stamina = 10000
var ray_length = 10


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


func _physics_process(delta):
	if is_network_master():
		control_player(delta)
		rset_unreliable("tf", get_transform())
		rset_unreliable("velocity", velocity)
	else:
		set_transform(tf)
		move_and_slide(velocity)

func control_player(delta):

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
	
	var friction

	if is_on_floor():

		friction = 1 - 0.16
		velocity.x *= friction
		velocity.z *= friction
		velocity.y = 0
		velocity += direction * walk_speed

		if Input.is_action_pressed("jump"):
			velocity.y += jump_speed

	else:
		friction = 1 - 0.01
		velocity.x *= friction
		velocity.z *= friction
		velocity.y += gravity
		velocity += direction * air_accel

	move_and_slide(velocity, Vector3(0, 1, 0))

func _exit_scene():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Functions
# =========

# Quits the game:
func quit():
	get_tree().quit()
