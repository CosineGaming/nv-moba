extends Node

var SERVER_TO_SERVER_PORT = 54671
var MATCHMAKING_PORT = 54672
var SERVER_SIZE = 6

var next_port = 54673

# Filled with queue info which contains
# { "netid" }
var skirmishing_players = []
var skirmish
# To avoid the confusion of the gameSERVERS being CLIENTS,
# we just call them games whenever possible
var games = []
var game_connections = []
var game_streams = []

# Matchmaker to game servers
var matchmaker_to_games

func _ready():
	set_process(false)

func run_matchmaker():
	skirmish = spawn_server()
	matchmaker_to_games = TCP_Server.new()
	if matchmaker_to_games.listen(SERVER_TO_SERVER_PORT):
		print("Error, could not listen")
	set_process(true)

func _process(delta):
	# Manage connection to GAMESERVERS (not clients)
	if matchmaker_to_games.is_connection_available(): # check if a gameserver's trying to connect
		var game = matchmaker_to_games.take_connection() # accept connection
		game_connections.append(game) # store the connection
		var stream = PacketPeerStream.new()
		stream.set_stream_peer(game) # bind peerstream to new client
		game_streams.append(stream) # make new data transfer object for game
		print("Server has requested connection")

master func queue(info):
	var netid = get_tree().get_rpc_sender_id()
	rpc_id(netid, "join_game", skirmish)
	skirmishing_players.push(netid)
	check_queue()

func check_queue():
	if skirmishing_players.size() >= SERVER_SIZE:
		var port = spawn_server()
		games.push(port)
		for p in skirmishing_players:
			rpc_id(p.netid, "join_game", port)

func spawn_server():
	OS.execute("util/server.sh", [], false)
	next_port += 1
	return (next_port - 1) # Return original port

