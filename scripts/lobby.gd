extends "res://scripts/args.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var SERVER_PORT = 2467
var MAX_PLAYERS = 10
var SERVER_PLAYING = true

var player_info = {}
var my_info = {}

func setup_options():
	var opts = Options.new()
	opts.set_banner(('A non-violent MOBA inspired by Overwatch and Zineth'))
	opts.add('-singleplayer', false, 'Whether to run singeplayer, starting immediately')
	opts.add('-server', false, 'Whether to run as server')
	opts.add('-client', false, 'Immediately connect as client')
	opts.add('-silent-server', false, 'If the server is not playing, merely serving')
	opts.add('-hero', 'r', 'Your choice of hero (index)')
	opts.add('-level', 'r', 'Your choice of level (index) - server only!')
	opts.add('-start-game', false, 'Join as a client and immediately start the game')
	opts.add('-ai', false, 'Run this client as AI')
	opts.add('-record', false, 'Record this play for AI later')
	opts.add('-h', false, "Print help")
	return opts

func option_sel(button_name, option):
	var button = get_node(button_name)
	print("-->")
	if option == "r":
		option = randi() % button.get_item_count()
		print(randi() % 3)
	else:
		option = int(option)
	button.select(option)

func _ready():

	var o = setup_options()
	o.parse()
	
	randomize()

	if o.get_value("-silent-server"):
		SERVER_PLAYING = false # TODO: Uncaps :(
	if o.get_value("-hero"):
		option_sel("HeroSelect", o.get_value("-hero"))
		print(get_node("HeroSelect").get_selected_id())
	if o.get_value("-level"):
		option_sel("ServerStart/LevelSelect", o.get_value("-level"))
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
	if o.get_value("-record"):
		my_info.record = true
	if o.get_value('-h'):
		o.print_help()
		quit()

	# Called every time the node is added to the scene.
	# Initialization here
	get_node("Server").connect("pressed", self, "_server_init")
	get_node("ServerStart").connect("pressed", self, "start_game")
	get_node("Client").connect("pressed", self, "_client_init")
	get_node("Singleplayer").connect("pressed", self, "_singleplayer_init")

	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	
	get_node("HeroSelect").connect("item_selected", self, "select_hero")

func _client_init():
	collect_info()
	var peer = NetworkedMultiplayerENet.new()
	var server_ip = get_node("IP").get_text()
	peer.create_client(server_ip, SERVER_PORT)
	get_tree().set_network_peer(peer)
	get_node("Client").set_text("Clienting!")

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
	get_node("Server").set_text("Serving!")
	get_node("ServerStart").show()
	if SERVER_PLAYING:
		player_info[1] = my_info

func _player_connected(id):
	print("Connect, my friend: " + str(id))

func _player_disconnected(id):
	if get_tree().is_network_server():
		rpc("unregister_player", id)

func _connected_ok():
	rpc("register_player", get_tree().get_network_unique_id(), my_info)
	if "start_game" in my_info and my_info.start_game:
		rpc_id(1, "start_game")

func collect_info():
	if not "username" in my_info:
		my_info.username = get_node("Username").get_text()
	if not "hero" in my_info:
		my_info.hero = get_node("HeroSelect").get_selected_id()
	if not "is_right_team" in my_info:
		my_info.is_right_team = false # Server assigns team, wait for that
	if not "start_game" in my_info:
		my_info.start_game = get_node("ForceStart").pressed

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
					print(right_team_count)
					right_team_count += 1
				# You'd think this part could be met with a simple `rpc(`, but actually it can't
				# My best guess is this is because we haven't registered the names yet, but I'm not sure (TODO)
				if old_peer != 1:
					# Send old player, new player's info (not us, no infinite loop)
					rpc_id(old_peer, "register_player", new_peer, info)
		var assign_right_team = right_team_count * 2 < player_info.size()
		rpc("assign_team", new_peer, assign_right_team)
		if (player_info.size() == MAX_PLAYERS):
			start_game()

sync func unregister_player(peer):
	player_info.erase(peer)
	get_node("/root/Level/Players/%d" % peer).queue_free()

func select_hero(hero):
	rpc("set_hero", get_tree().get_network_unique_id(), hero)

sync func set_hero(peer, hero):
	player_info[peer].hero = hero
	render_player_list()

sync func assign_team(peer, is_right_team):
	player_info[peer].is_right_team = is_right_team
	if peer == get_tree().get_network_unique_id():
		if is_right_team:
			get_node("Team").set_text("Right Team")
		else:
			get_node("Team").set_text("Left Team")
	render_player_list()

func render_player_list():
	var list = ""
	var hero_names = get_node("HeroSelect").hero_names
	for p in player_info:
		list += "%-15s" % player_info[p].username
		list += "%-20s" % hero_names[player_info[p].hero]
		if player_info[p].is_right_team:
			list += "Right Team"
		else:
			list += "Left Team"
		list += "\n"
	get_node("PlayerList").set_text(list)

sync func start_game():
	var level = get_node("ServerStart/LevelSelect").get_selected_id()
	rpc("pre_configure_game", level)

var players_done = []
remote func done_preconfiguring(who):
	players_done.append(who)
	if (players_done.size() == player_info.size()):
		rpc("post_configure_game")

sync func pre_configure_game(level):
	var self_peer_id = get_tree().get_network_unique_id()

	# Remove the interface so as to not fuck with things
	# But we still need the lobby (Control) alive to deal with networking!
	for element in get_node("/root/Control").get_children():
		element.queue_free()

	var world = load("res://scenes/levels/%d.tscn" % level).instance()
	get_node("/root").add_child(world)

	# Load all players (including self)
	for p in player_info:
		var hero = player_info[p].hero
		var player = load("res://scenes/heroes/" + str(hero) + ".tscn").instance()
		player.set_name(str(p))
		player.set_network_master(p)
		player.player_info = player_info[p]
		get_node("/root/Level/Players").call_deferred("add_child", player)

	rpc_id(1, "done_preconfiguring", self_peer_id)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
