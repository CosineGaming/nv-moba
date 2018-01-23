extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var SERVER_PORT = 2467
var MAX_PLAYERS = 10
var SERVER_PLAYING = true

var player_info = {}
var my_info = {}

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_node("Server").connect("pressed", self, "_server_init")
	get_node("ServerStart").connect("pressed", self, "start_game")
	get_node("Client").connect("pressed", self, "_client_init")
	get_node("Singleplayer").connect("pressed", self, "_singleplayer_init")

	get_tree().connect("network_peer_connected", self, "_player_connected")
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
	pre_configure_game()

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

func _connected_ok():
	rpc("register_player", get_tree().get_network_unique_id(), my_info)

func collect_info():
	my_info.username = get_node("Username").get_text()
	my_info.hero = get_node("HeroSelect").get_selected_id()
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
					print(right_team_count)
					right_team_count += 1
				# You'd think this part could be met with a simple `rpc(`, but actually it can't
				# My best guess is this is because we haven't registered the names yet, but I'm not sure (TODO)
				if old_peer != 1:
					# Send old player, new player's info (not us, no infinite loop)
					rpc_id(old_peer, "register_player", new_peer, info)
		var assign_right_team = right_team_count * 2 <= player_info.size()
		rpc("assign_team", new_peer, assign_right_team)
		if (player_info.size() == MAX_PLAYERS):
			start_game()

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

func start_game():
	rpc("pre_configure_game")
	if SERVER_PLAYING:
		pre_configure_game()

var players_done = []
remote func done_preconfiguring(who):
	players_done.append(who)
	if (players_done.size() == player_info.size()):
		rpc("post_configure_game")

remote func pre_configure_game():
	var self_peer_id = get_tree().get_network_unique_id()

	get_node("/root/Control").queue_free()
	var world = load("res://scenes/world.tscn").instance()
	get_node("/root").add_child(world)

	# Load all players (including self)
	for p in player_info:
		var hero = player_info[p].hero
		var player = load("res://scenes/heroes/" + str(hero) + ".tscn").instance()
		player.set_name(str(p))
		player.set_network_master(p)
		get_node("/root/world/players").call_deferred("add_child", player)

	rpc_id(1, "done_preconfiguring", self_peer_id)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
