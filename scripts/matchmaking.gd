extends Node

var SERVER_TO_SERVER_PORT = 54671
var MATCHMAKING_PORT = 54672
var GAME_SIZE = 6
# Number of games we can make without blowing up the computer
var MAX_GAMES = 50 # Totally random guess

var next_port = 54673

# Filled with queue info which contains
# { "netid" }
var skirmishing_players = []
var skirmish
# To avoid the confusion of the gameSERVERS being CLIENTS,
# we just call them games whenever possible
# var games = []
var game_connections = []
var game_streams = []

# Matchmaker to game servers
var matchmaker_to_games

enum messages {
	ready_to_connect,
}

onready var lobby = get_node("..")

func _ready():
	# By default, having this node doesn't do naything
	# You must call start_matchmaker to enable it
	# If not called, don't call _process (= don't matchmake)
	set_process(false)

func start_matchmaker():
	# Actually run the matchmaker
	set_process(true)

	# Setup skirmish server
	skirmish = spawn_server()

	# Set up communication between GAMESERVERS
	# This is necessary for eg, when a player leaves to backfill
	matchmaker_to_games = TCP_Server.new()
	if matchmaker_to_games.listen(SERVER_TO_SERVER_PORT):
		print("Error, could not listen")

	# Use ENet for matchmaker because we can (makes client code cleaner)
	var matchmaker_to_players = NetworkedMultiplayerENet.new()
	print("Starting matchmaker on port " + str(MATCHMAKING_PORT))
	matchmaker_to_players.create_server(MATCHMAKING_PORT, MAX_GAMES)
	get_tree().set_network_peer(matchmaker_to_players)
	matchmaker_to_players.connect("peer_connected", self, "queue")

func _process(delta):
	# Manage connection to GAMESERVERS (not clients)
	if matchmaker_to_games.is_connection_available(): # check if a gameserver's trying to connect
		var game = matchmaker_to_games.take_connection() # accept connection
		game_connections.append(game) # store the connection
		var stream = PacketPeerStream.new()
		stream.set_stream_peer(game) # bind peerstream to new client
		game_streams.append(stream) # make new data transfer object for game
	for stream in game_streams:
		if stream.get_available_packet_count():
			var message = stream.get_var()
			if message == messages.ready_to_connect:
				var port = stream.get_var()
				print("Server " + str(port) + " has requested connection")
				skirmish_to_game(port, GAME_SIZE)

func queue(netid):
	print("Player " + str(netid) + " connected.")
	add_to_game(netid, skirmish)
	skirmishing_players.append(netid)
	check_queue()

# # This is only for clients, but it's in here so we can rpc it easily
# slave func join_game(port):
# 	#

func add_to_game(netid, port):
	networking.rpc_id(netid, "reconnect", port)

func skirmish_to_game(port, count=1):
	for i in range(count):
		if not skirmishing_players.size():
			return false
		print(skirmishing_players[0])
		print("to")
		print(port)
		add_to_game(skirmishing_players[0], port)
	return true

func check_queue():
	# Prefer making a full game to backfilling
	if skirmishing_players.size() >= GAME_SIZE:
		spawn_server()
		# games.append(port)

func spawn_server():
	OS.execute("util/server.sh", ['-port='+str(next_port)], false)
	next_port += 1
	return (next_port - 1) # Return original port

