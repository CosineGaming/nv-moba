extends Control

var port = null # Defined by command-line argument with default

# var my_info = {}
remote var players = {}
var global_server_ip = "nv.cosinegaming.com"
var ip = null
var players_done = []
var is_connected = false # Technically this can be done with ENetcetera but it's easier this way

onready var matchmaking = preload("res://scripts/matchmaking.gd").new()

var matchmaker_tcp

var right_team_next = false

func _ready():
	add_child(matchmaking)

	if get_tree().is_network_server():
		get_node("LevelSelect").show()

	get_tree().connect("network_peer_connected", self, "_register_player")

	get_node("Username").connect("text_changed", self, "_send_name")
	get_node("StartGame").connect("pressed", self, "_start_game")
	# get_node("CustomGame/LevelSelect").connect("item_selected", self, "select_level") TODO
	_send_name()

func _register_player(peer):
	players[peer] = {}
	if is_network_server():
		rset(peer, "players", players)

func _collect_info():
	var my_id = get_tree().get_network_unique_id()
	var my_info = networking.players[my_id]
	if not "username" in my_info:
		my_info.username = get_node("Username").get_text()
	if not "hero" in my_info:
		my_info.hero = get_node("HeroSelect/Hero").get_selected_id()
	if not "is_right_team" in my_info:
		my_info.is_right_team = false # Server assigns team, wait for that

func select_hero(hero):
	var description = get_node("HeroSelect").hero_text[hero]
	get_node("HeroDescription").set_text(description)
	var my_id = get_tree().get_network_unique_id()
	networking.players[my_id].hero = hero
	rpc("set_hero", get_tree().get_network_unique_id(), hero)

sync func set_hero(peer, hero):
	networking.players[peer].hero = hero
	render_player_list()

func _send_name():
	if is_connected:
		var name = get_node("Username").text
		rpc("_set_name", get_tree().get_network_unique_id(), name)

sync func _set_name(peer, name):
	networking.players[peer].username = name
	render_player_list()

func render_player_list():
	if has_node("PlayerSettings"):
		var list = ""
		var hero_names = get_node("HeroSelect").hero_names
		for p in networking.players:
			list += "%-15s" % networking.players[p].username
			list += "%-20s" % hero_names[networking.players[p].hero]
			if networking.players[p].is_right_team:
				list += "Right Team"
			else:
				list += "Left Team"
			list += "\n"
		get_node("JoinedGameLobby/PlayerList").set_text(list)

sync func assign_team(peer, is_right_team):
	networking.players[peer].is_right_team = is_right_team
	if peer == get_tree().get_network_unique_id():
		if is_right_team:
			get_node("Team").set_text("Right Team")
		else:
			get_node("Team").set_text("Left Team")
	render_player_list()

func _start_game():
	_collect_info()
	var level = 2 # TODO
	networking.rpc_id(1, "start_game", level)

