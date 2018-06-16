extends "res://scripts/player.gd"

var fly_cost = 50 # Per second
var fly_strength = 0.25
var glide_factor = 0.08
var glide_build = 0
var climb_speed = 3
var time_to_glide = 0.3
var glide_ramp = glide_factor / 1 # In per second; written as time to full / glide_factor

var _gliding = false
var _glide = 0
var _touch_count = 0
var _orig_air_friction = air_friction

func _ready():
	charge_height = -20 # It's too easy to abuse the fall charge by looking down and holding space

func _process(delta):
	if get_colliding_bodies():
		_touch_count = 0
	else:
		_touch_count += delta
	if Input.is_action_pressed("jump") and _touch_count > time_to_glide:
		_glide = clamp(_glide + delta * glide_ramp, 0, glide_factor)
	else:
		_glide = 0

func control_player(state):
	var skip_controls = false
	if Input.is_action_pressed("jump") and touching_wall(state):
		# Head towards climb speed, but don't slow down to it
		var climb_force = max((climb_speed - linear_velocity.y) * get_mass(), 0)
		state.apply_impulse(Vector3(), Vector3(0, climb_force, 0))
	else:
		if _glide:
			if Input.is_action_pressed("primary_mouse"):
				var cost = fly_cost * state.step
				if charge > cost:
					var forward = -$Yaw/Pitch.get_global_transform().basis.z.normalized()
					linear_velocity += forward * fly_strength
					build_charge(-cost)
			preserve_direction()
			preserve_direction(_glide, false)
			if translation.y > charge_height:
				build_charge(glide_build * linear_velocity.length() * state.step)
			air_friction = 1 - 0.01
			skip_controls = true
		else:
			air_friction = _orig_air_friction
	state.integrate_forces()
	if not skip_controls:
		.control_player(state)

func touching_wall(state):
	for i in range(state.get_contact_count()):
		var last_wall_normal = state.get_contact_local_normal(i)
		# Make sure it isn't the floor
		if last_wall_normal.dot(Vector3(0,1,0)) < 0.95:
			return true
	return false

