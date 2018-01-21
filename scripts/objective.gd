extends RigidBody

var left = 0
var right = 0
var active = false
var right_active = false
var activation_margin = 0.1

var build_rate = 1

func _integrate_forces(state):
	var rot = get_rotation().x
	
	if active:
		activation_margin = 0
	if rot < -activation_margin:
		active = true
		right_active = false
	if rot > activation_margin:
		active = true
		right_active = true
	if active:
		if right_active:
			get_node("../HUD/LeftTeam").add_color_override("font_color_shadow", Color(0,0,0,0))
			get_node("../HUD/RightTeam").add_color_override("font_color_shadow", Color(1,0,0))
		else:
			get_node("../HUD/LeftTeam").add_color_override("font_color_shadow", Color(1,0,0))
			get_node("../HUD/RightTeam").add_color_override("font_color_shadow", Color(0,0,0,0))

func _process(delta):
	if active:
		if right_active:
			right += delta * build_rate
		else:
			left += delta * build_rate
	if left >= 100:
		get_node("../HUD/Finish").set_text("Left wins!")
		Engine.set_time_scale(0.1)
		left = 100
	if right >= 100:
		get_node("../HUD/Finish").set_text("Left wins!")
		Engine.set_time_scale(0.1)
		right = 100
	get_node("../HUD/LeftTeam").set_text("%d%%" % left)
	get_node("../HUD/RightTeam").set_text("%d%%" % right)
