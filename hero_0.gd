extends "res://player.gd"

const wallride_speed = 2

master func _integrate_forces(state):
	._integrate_forces(state)
	wallride(state)

func wallride(state):
	var ray = get_node("Ray")
	# If our feet aren't touching, but we are colliding, we are wall-riding
	if !ray.is_colliding() and get_colliding_bodies():
		print("riding")
		var aim = get_node("Yaw").get_global_transform().basis
		var direction = Vector3()
		if Input.is_action_pressed("move_forwards"):
			direction -= aim[2]
		if Input.is_action_pressed("move_backwards"):
			direction += aim[2]
		#var n = -1 * (state.get_transform() * state.get_contact_local_normal(0))
		#direction = n.slide(direction) * wallride_speed
		direction *= 0.1
		set_gravity_scale(-0.1)
		apply_impulse(Vector3(), direction)
		state.integrate_forces()
	else:
		# We need to return to falling (we aren't riding anymore)
		set_gravity_scale(1)
