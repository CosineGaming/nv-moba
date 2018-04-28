extends "res://scripts/args.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var SERVER_PORT = 54672
var MAX_PLAYERS = 10

var player_info = {}
var my_info = {}
var begun = false
var server_playing = true
var global_server_ip = "nv.cosinegaming.com"
var players_done = []
var is_connected = false # Technically this can be done with ENetcetera but it's easier this way

func setup_options():
	var opts = Options.new()
	opts.set_banner(('A non-violent MOBA inspired by Overwatch and Zineth'))
	opts.add('-singleplayer', false, 'Whether to run singeplayer, starting immediately')
	opts.add('-server', false, 'Whether to run as server')
	opts.add('-client', false, 'Immediately connect as client')
	opts.add('-silent', false, 'If the server is not playing, merely serving')
	opts.add('-hero', 'r', 'Your choice of hero (index)')
	opts.add('-level', 'r', 'Your choice of level (index) - server only!')
	opts.add('-start-game', false, 'Join as a client and immediately start the game')
	opts.add('-ai', true, 'Run this client as AI')
	opts.add('-no-record', true, "Don't record this play for AI later")
	opts.add('-h', false, "Print help")
	return opts

func option_sel(button_name, option):
	var button = get_node(button_name)
	if option == "r":
		option = randi() % button.get_item_count()
	else:
		option = int(option)
	button.select(option)

func _ready():

	my_info.version = [0,0,0] # Semantic versioning: [0].[1].[2]

	randomize()

	get_node("GameBrowser/Play").connect("pressed", self, "connect_global_server")
	get_node("PlayerSettings/HeroSelect").connect("item_selected", self, "select_hero")
	get_node("PlayerSettings/Username").connect("text_changed", self, "resend_name")
	get_node("JoinedGameLobby/StartGame").connect("pressed", self, "start_game")
	get_node("CustomGame/Server").connect("pressed", self, "_server_init")
	get_node("CustomGame/Client").connect("pressed", self, "_client_init")
	get_node("CustomGame/Singleplayer").connect("pressed", self, "_singleplayer_init")
	get_node("CustomGame/LevelSelect").connect("item_selected", self, "select_level")

	var o = setup_options()
	o.parse()

	if o.get_value("-silent"):
		server_playing = false # TODO: Uncaps :(
	if o.get_value("-hero"):
		var hero = o.get_value("-hero")
		option_sel("PlayerSettings/HeroSelect", hero)
		# For some reason, calling option_sel doesn't trigger the actual selection
		select_hero(get_node("PlayerSettings/HeroSelect").get_selected_id())
	if o.get_value("-level"):
		option_sel("CustomGame/LevelSelect", o.get_value("-level"))
	if o.get_value("-server"):
		call_deferred("_server_init")
	if o.get_value("-client"):
		call_deferred("_client_init")
	if o.get_value("-start-game"):
		my_info.start_game = true
		call_deferred("_client_init")
	if o.get_value("-singleplayer"):
		call_deferred("_singleplayer_init")
	if o.get_value("-ai"):
		my_info.is_ai = true
	if not o.get_value("-no-record") and not o.get_value("-ai"):
		my_info.record = true
	if o.get_value('-h'):
		o.print_help()
		quit()

	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")

func connect_global_server():
	_client_init(global_server_ip)

func _client_init(ip=null):
	collect_info()
	var peer = NetworkedMultiplayerENet.new()
	if not ip:
		ip = get_node("CustomGame/IP").get_text()
	ip = IP.resolve_hostname(ip)
	peer.create_client(ip, SERVER_PORT)
	get_tree().set_network_peer(peer)
	get_node("CustomGame/Client").set_text("Clienting!")

func _singleplayer_init():
	collect_info()
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, 1)
	get_tree().set_network_peer(peer)
	player_info[1] = my_info
	start_game()

func _server_init():
	collect_info()
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	is_connected = true
	get_node("CustomGame/Server").set_text("Serving!")
	get_node("JoinedGameLobby").show()
	if server_playing:
		player_info[1] = my_info

func _player_connected(id):
	pass

func _player_disconnected(id):
	if get_tree().is_network_server():
		rpc("unregister_player", id)
	call_deferred("render_player_list")

func _connected_ok():
	rpc("register_player", get_tree().get_network_unique_id(), my_info)
	if "start_game" in my_info and my_info.start_game:
		rpc_id(1, "start_game")
	get_node("JoinedGameLobby").show()
	is_connected = true

func collect_info():
	if not "username" in my_info:
		my_info.username = get_node("PlayerSettings/Username").get_text()
	if not "hero" in my_info:
		my_info.hero = get_node("PlayerSettings/HeroSelect").get_selected_id()
	if not "is_right_team" in my_info:
		my_info.is_right_team = false # Server assigns team, wait for that

remote func register_player(new_peer, info):
	player_info[new_peer] = info
	render_player_list()
	if (get_tree().is_network_server()):
		var right_team_count = 0
		# Send current players' info to new player
		for old_peer in player_info:
			# Send new player, old player's info
			rpc_id(new_peer, "register_player", old_peer, player_info[old_peer])
			if old_peer != new_peer:
				# We need to assign team later, so count current
				if player_info[old_peer].is_right_team:
					right_team_count += 1
				# You'd think this part could be met with a simple `rpc(`, but actually it can't
				# My best guess is this is because we haven't registered the names yet, but I'm not sure (TODO)
				if old_peer != 1:
					# Send old player, new player's info (not us, no infinite loop)
					rpc_id(old_peer, "register_player", new_peer, info)
				if begun:
					rpc_id(old_peer, "spawn_player", new_peer)
					rpc_id(old_peer, "begin_player_deferred", new_peer) # Spawning is deferred
		if not server_playing:
			# We didn't catch this in player_info
			rpc_id(1, "spawn_player", new_peer)
			rpc_id(1, "begin_player_deferred", new_peer) # Spawning is deferred
		var assign_right_team = right_team_count * 2 < player_info.size()
		rpc("assign_team", new_peer, assign_right_team)
		if not begun and player_info.size() == MAX_PLAYERS:
			start_game()
		if begun:
			rpc_id(new_peer, "pre_configure_game", my_info.level)
			rpc_id(new_peer, "post_configure_game")

sync func unregister_player(peer):
	player_info.erase(peer)
	get_node("/root/Level/Players/%d" % peer).queue_free()

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

sync func assign_team(peer, is_right_team):
	player_info[peer].is_right_team = is_right_team
	if peer == get_tree().get_network_unique_id():
		if is_right_team:
			get_node("PlayerSettings/Team").set_text("Right Team")
		else:
			get_node("PlayerSettings/Team").set_text("Left Team")
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

sync func start_game():
	my_info.level = get_node("CustomGame/LevelSelect").get_selected_id()
	rpc("pre_configure_game", my_info.level)

sync func done_preconfiguring(who):
	players_done.append(who)
	if players_done.size() == player_info.size():
		# We call deferred in case singleplayer has placing the player in queue still
		call_deferred("rpc", "post_configure_game")

sync func spawn_player(p):
	var hero = player_info[p].hero
	var player = load("res://scenes/heroes/" + str(hero) + ".tscn").instance()
	player.set_name(str(p))
	player.set_network_master(p)
	player.player_info = player_info[p]
	get_node("/root/Level/Players").call_deferred("add_child", player)

sync func pre_configure_game(level):
	begun = true
	my_info.level = level # Remember the level for future player registration

	var self_peer_id = get_tree().get_network_unique_id()

	# Remove the interface so as to not fuck with things
	# But we still need the lobby alive to deal with networking!
	for element in get_node("/root/Lobby").get_children():
		element.queue_free()

	var world = load("res://scenes/levels/%d.tscn" % level).instance()
	get_node("/root").add_child(world)

	# Load all players (including self)
	for p in player_info:
		player_info[p].level = level
		spawn_player(p)

	rpc_id(1, "done_preconfiguring", self_peer_id)

func begin_player(peer):
	get_node("/root/Level/Players/%d" % peer).begin()

remote func begin_player_deferred(peer):
	call_deferred("begin_player", peer)

sync func reset_state():
	players_done = []
	get_node("/root/Level").queue_free()

sync func post_configure_game():
	# Begin all players (including self)
	for p in player_info:
		begin_player_deferred(p)

