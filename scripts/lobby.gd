extends Control

onready var hero_select = get_node("HeroSelect/Hero")
onready var level_select = get_node("LevelSelect")
onready var start_game_button = get_node("StartGame")
onready var ready_button = get_node("Ready")

func _ready():

	# Connect (to networking)
	get_node("Username").connect("text_changed", self, "_send_name")
	get_node("Spectating").connect("toggled", self, "_set_info_callback", ["spectating"])
	ready_button.connect("toggled", self, "_set_info_callback", ["ready"])
	start_game_button.connect("pressed", networking, "start_game")
	# Connect (from networking)
	networking.connect("info_updated", self, "render_player_list")
	get_tree().connect("connected_to_server", self, "_connected")

	# Connect (static)
	get_node("Back").connect("pressed", self, "_exit_to_menu")

	var spectating = util.args.get_value("-silent")
	get_node("Spectating").pressed = spectating
	# Shown, maybe, in _check_begun
	start_game_button.hide()
	if get_tree().is_network_server():
		start_game_button.show()

	if get_tree().is_network_server():
		# We put level in our players dict because it's automatically broadcast to other players
		var level = util.args.get_value("-level")
		if level == "r":
			level = randi() % level_select.get_item_count()
		level = int(level)
		_set_level(level)

		level_select.show()
		level_select.select(level)
		level_select.connect("item_selected", self, "_set_level")
	else:
		level_select.hide()

	if get_tree().is_network_server():
		_connected()

func _connected():

	_send_name()
	networking.set_info_from_server("ready", false)
	networking.set_info_from_server("spectating", util.args.get_value("-silent"))
	networking.set_info_from_server("begun", false)
	if util.args.get_value("-hero") == "r":
		hero_select.random_hero()
	else:
		hero_select.set_hero(int(util.args.get_value("-hero")))

	if util.args.get_value("-start-game"):
		networking.start_game()

func _set_level(level):
	networking.level = level

# Because of the annoying way callbacks work (automatic parameter, optional parameter)
# We need a utility function for making these kinds of callbacks for set_info
func _set_info_callback(value, key):
	networking.set_info_from_server(key, value)

sync func set_hero(peer, hero):
	networking.players[peer].hero = hero
	render_player_list()

func _send_name():
	var name = get_node("Username").text
	networking.set_info_from_server("username", name)

func _check_begun():
	if networking.players.has(1) and networking.players[1].has("begun"):
		var game_started = networking.players[1].begun
		if game_started:
			start_game_button.show()
			start_game_button.text = "Join game"
			# The "Ready" toggle doesn't really make sense on a started game
			ready_button.hide()

func render_player_list():
	_check_begun()
	var list = ""
	var hero_names = hero_select.hero_names
	for p in networking.players:
		var player = networking.players[p]
		# A spectating server is just a dedicated server, ignore it
		if p and player.has("spectating") and not (player.spectating and p == 1):
			var username = player.username if player.has("username") else "Loading..."
			list += "%-15s " % username
			var hero = hero_names[player.hero] if player.has("hero") else "Loading..."
			list += "%-10s " % hero
			var team = "Loading..."
			if player.has("is_right_team"):
				if player.is_right_team:
					team = "Right Team"
				else:
					team = "Left Team"
			list += "%-11s" % team
			var ready_text = "Ready" if player.has("ready") and player.ready else ""
			list += "%-6s" % ready_text
			if player.has("spectating") and player.spectating:
				list += "Spectating"
			list += "\n"
	get_node("PlayerList").set_text(list)

func _exit_to_menu():
	get_tree().network_peer.close_connection()
	get_tree().change_scene("res://scenes/menu.tscn")

