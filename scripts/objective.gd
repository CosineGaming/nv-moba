extends RigidBody

sync var left = 0
sync var right = 0
var active = false
var right_active = false
var activation_margin = 0.1

var update_frequency = 1 # In secs. This isn't too fast-paced, so don't clog the network with updates every frame
var update_count = 0

var master_team_right = null
var friend_color
var enemy_color

var build_rate = 1.5
var restart_count = 0
var restart_time = 15

func _integrate_forces(state):
	var rot = get_rotation().x

	if active:
		activation_margin = 0
	if rot > activation_margin:
		active = true
		right_active = false
	if rot < -activation_margin:
		active = true
		right_active = true
	if active:
		if right_active == master_team_right:
			# We DO own the correct one; display left counting, blue
			get_node("../HUD/LeftTeam").add_color_override("font_color_shadow", friend_color)
			get_node("../HUD/RightTeam").add_color_override("font_color_shadow", Color(0,0,0,0))
		else:
			# We DO NOT own the correct one; display right counting, red
			get_node("../HUD/LeftTeam").add_color_override("font_color_shadow", Color(0,0,0,0))
			get_node("../HUD/RightTeam").add_color_override("font_color_shadow", enemy_color)

func _process(delta):

	# Figure out what team we're on
	# We have to do this here because we never know when the master player will actually be added
	if master_team_right == null:
		var master_player = util.get_master_player()
		if master_player:
			master_team_right = master_player.player_info.is_right_team
			friend_color = master_player.friend_color
			enemy_color = master_player.enemy_color
		else:
			master_team_right = true # Doesn't matter, it's all graphical and we're headless
			friend_color = Color()
			enemy_color = Color()
		var name = "right" if master_team_right else "left"
		var full_name = "res://assets/objective-%s.png" % name
		get_node("MeshInstance").get_surface_material(0).albedo_texture = load(full_name)

	# Count the percents
	if active:
		if right_active:
			right += delta * build_rate
		else:
			left += delta * build_rate
	update_count += delta
	if is_network_master() and update_count > update_frequency:
		update_count = 0
		rset("left", left)
		rset("right", right)

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
		# You won't believe this, but because time_scale is 0.1 we have to multiply times 10 for proper timing
		restart_count += delta * 10
	if restart_count > restart_time:
		get_node("/root/Lobby").reset_state()
		Engine.set_time_scale(1)

	# Render the percents
	var on_left = left
	var on_right = right
	# Always display OUR team on the LEFT (in blue)
	if master_team_right:
		on_left = right
		on_right = left
	get_node("../HUD/LeftTeam").set_text("%d%%" % on_left)
	get_node("../HUD/RightTeam").set_text("%d%%" % on_right)

func _exit_tree():
	var lobby = get_node("/root/Lobby")
	lobby.call_deferred("pre_configure_game", lobby.my_info.level)

