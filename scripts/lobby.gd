extends Control

var port = null # Defined by command-line argument with default

var my_info = {}
var server_playing = true
var global_server_ip = "nv.cosinegaming.com"
var ip = null
var players_done = []
var is_connected = false # Technically this can be done with ENetcetera but it's easier this way

onready var matchmaking = preload("res://scripts/matchmaking.gd").new()

var matchmaker_tcp


func _ready():
	add_child(matchmaking)

	get_node("GameBrowser/Play").connect("pressed", self, "connect_global_server")
	get_node("PlayerSettings/HeroSelect").connect("item_selected", self, "select_hero")
	get_node("PlayerSettings/Username").connect("text_changed", self, "resend_name")
	get_node("JoinedGameLobby/StartGame").connect("pressed", self, "start_game")
	get_node("CustomGame/Server").connect("pressed", self, "_server_init")
	get_node("CustomGame/Client").connect("pressed", self, "_client_init")
	get_node("CustomGame/Singleplayer").connect("pressed", self, "_singleplayer_init")
	get_node("CustomGame/LevelSelect").connect("item_selected", self, "select_level")

	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")

func collect_info():
	if not "username" in my_info:
		my_info.username = get_node("PlayerSettings/Username").get_text()
	if not "hero" in my_info:
		my_info.hero = get_node("PlayerSettings/HeroSelect").get_selected_id()
	if not "is_right_team" in my_info:
		my_info.is_right_team = false # Server assigns team, wait for that

func select_hero(hero):
	var description = get_node("PlayerSettings/HeroSelect").hero_text[hero]
	get_node("PlayerSettings/HeroDescription").set_text(description)
	if is_connected:
		rpc("set_hero", get_tree().get_network_unique_id(), hero)

sync func set_hero(peer, hero):
	player_info[peer].hero = hero
	render_player_list()

func resend_name():
	if is_connected:
		var name = get_node("PlayerSettings/Username").get_text()
		rpc("set_name", get_tree().get_network_unique_id(), name)

sync func set_name(peer, name):
	player_info[peer].username = name
	render_player_list()

func render_player_list():
	if has_node("PlayerSettings"):
		var list = ""
		var hero_names = get_node("PlayerSettings/HeroSelect").hero_names
		for p in player_info:
			list += "%-15s" % player_info[p].username
			list += "%-20s" % hero_names[player_info[p].hero]
			if player_info[p].is_right_team:
				list += "Right Team"
			else:
				list += "Left Team"
			list += "\n"
		get_node("JoinedGameLobby/PlayerList").set_text(list)

sync func assign_team(peer, is_right_team):
	player_info[peer].is_right_team = is_right_team
	if peer == get_tree().get_network_unique_id():
		if is_right_team:
			get_node("PlayerSettings/Team").set_text("Right Team")
		else:
			get_node("PlayerSettings/Team").set_text("Left Team")
	render_player_list()

