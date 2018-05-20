extends Control

var port = null # Defined by command-line argument with default

onready var hero_select = get_node("HeroSelect/Hero")
onready var level_select = get_node("LevelSelect")

func _ready():

	get_node("Username").connect("text_changed", self, "_send_name")
	get_node("StartGame").connect("pressed", networking, "start_game")

	var spectating = util.args.get_value("-silent")
	get_node("Spectating").pressed = spectating
	get_node("Spectating").connect("toggled", networking, "set_spectating")

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

	networking.connect("info_updated", self, "render_player_list")
	get_tree().connect("connected_to_server", self, "_connected")
	if get_tree().is_network_server():
		_connected()

func _connected():
	_send_name()
	if util.args.get_value("-hero") == "r":
		hero_select.random_hero()
	else:
		print(util.args.get_value("-hero"))
		hero_select.set_hero(int(util.args.get_value("-hero")))

	if util.args.get_value("-start-game"):
		networking.start_game()

func _set_level(level):
	networking.set_info("level", level)

sync func set_hero(peer, hero):
	networking.players[peer].hero = hero
	render_player_list()

func _send_name():
	var name = get_node("Username").text
	networking.set_info("username", name)

func render_player_list():
	var list = ""
	var hero_names = hero_select.hero_names
	for p in networking.players:
		list += "%-15s" % networking.players[p].username
		list += "%-20s" % hero_names[networking.players[p].hero]
		if networking.players[p].is_right_team:
			list += "Right Team"
		else:
			list += "Left Team"
		list += "\n"
	get_node("PlayerList").set_text(list)

