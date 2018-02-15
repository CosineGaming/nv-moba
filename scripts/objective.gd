extends RigidBody

var left = 0
var right = 0
var active = false
var right_active = false
var activation_margin = 0.1

var update_frequency = 2 # In secs. This isn't too fast-paced, so don't clog the network with updates every frame
var update_count = 0

var master_team_right = null

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
		if right_active == master_team_right:
			# We DO own the correct one; display left counting, blue
			get_node("../HUD/LeftTeam").add_color_override("font_color_shadow", Color(0,0,1))
			get_node("../HUD/RightTeam").add_color_override("font_color_shadow", Color(0,0,0,0))
		else:
			# We DO NOT own the correct one; display right counting, red
			get_node("../HUD/LeftTeam").add_color_override("font_color_shadow", Color(0,0,0,0))
			get_node("../HUD/RightTeam").add_color_override("font_color_shadow", Color(1,0,0))

func _process(delta):

	# Figure out what team we're on
	# We have to do this here because we never know when the master player will actually be added
	if master_team_right == null:
		var master_player = get_node("/root/Level/Players/%d" % get_tree().get_network_unique_id())
		master_team_right = master_player.player_info.is_right_team

	# Count the percents
	if active:
		if right_active:
			right += delta * build_rate
		else:
			left += delta * build_rate
	update_count += delta
	if is_network_master() and update_count > update_frequency:
		update_count = 0
		rset_unreliable("left", left)
		rset_unreliable("right", right)

	# Check for game over
	var game_over = false
	var winner_right
	if left >= 100:
		game_over = true
		winner_right = false
		left = 100
	if right >= 100:
		game_over = true
		winner_right = true
		right = 100
	if game_over:
		var text = "You lose :("
		if winner_right == master_team_right:
			text = "You win!!!"
		get_node("../HUD/Finish").set_text(text)
		Engine.set_time_scale(0.1)

	# Render the percents
	var on_left = left
	var on_right = right
	# Always display OUR team on the LEFT (in blue)
	if master_team_right:
		on_left = right
		on_right = left
	get_node("../HUD/LeftTeam").set_text("%d%%" % on_left)
	get_node("../HUD/RightTeam").set_text("%d%%" % on_right)

