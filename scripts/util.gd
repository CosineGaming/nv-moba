extends Node

var version = [0,0,0] # Semantic versioning: [0].[1].[2]

var args

onready var Options = preload("res://scripts/args.gd").new().Options

func _ready():
	args = _get_args()

func get_master_player():
	var path = "/root/Level/Players/%d" % get_tree().get_network_unique_id()
	if has_node(path):
		return get_node(path)
	else:
		return null

func is_friendly(player):
	var mp = get_master_player()
	if mp:
		return player.player_info.is_right_team == get_master_player().player_info.is_right_team
	else:
		return true # Doesn't matter, we're headless

func _get_args():
	var opts = Options.new()
	opts.set_banner(('A non-violent MOBA inspired by Overwatch and Zineth'))
	opts.add('-singleplayer', false, 'Whether to run singeplayer, starting immediately')
	opts.add('-server', false, 'Whether to run as server')
	opts.add('-matchmaker', false, 'Whether to be the sole matchmaker')
	opts.add('-client', false, 'Immediately connect as client')
	opts.add('-silent', false, 'If the server is not playing, merely serving')
	opts.add('-port', 54673, 'The port to run a server on or connect to')
	opts.add('-hero', 'r', 'Your choice of hero (index)')
	opts.add('-level', 'r', 'Your choice of level (index) - server only!')
	opts.add('-start-game', false, 'Join as a client and immediately start the game')
	opts.add('-ai', true, 'Run this client as AI')
	opts.add('-no-record', true, "Don't record this play for AI later")
	opts.add('-h', false, "Print help")
	opts.parse()
	return opts

