extends Control

var port = null # Defined by command-line argument with default

onready var hero_select = get_node("HeroSelect/Hero")

func _ready():
	if get_tree().is_network_server():
		get_node("LevelSelect").show()
	else:
		get_node("LevelSelect").hide()

	get_node("Username").connect("text_changed", self, "_send_name")
	get_node("StartGame").connect("pressed", self, "_start_game")

	var spectating = util.args.get_value("-silent")
	get_node("Spectating").pressed = spectating
	# 
	get_node("Spectating").connect("toggled", networking, "set_spectating") # TODO
	# get_node("CustomGame/LevelSelect").connect("item_selected", self, "select_level") TODO
	# _send_name()
	# hero_select.set_hero(0)

	networking.connect("info_updated", self, "render_player_list")
	get_tree().connect("connected_to_server", self, "_send_settings")
	if get_tree().is_network_server():
		_send_settings()

func _send_settings():
	print("sending")
	_send_name()
	hero_select.random_hero()

sync func set_hero(peer, hero):
	networking.players[peer].hero = hero
	render_player_list()

func _send_name():
	var name = get_node("Username").text
	networking.set_info("username", name)

func render_player_list():
	print(JSON.print(networking.players))
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

func _start_game():
	_collect_info()
	var level = 2 # TODO
	networking.rpc_id(1, "start_game", level)

