extends Node

# Semantic versioning, more or less
# Major: Server cannot accept requests (i.e. new hero, or network protocol change)
# Minor: Gameplay was significantly changed, but these can still technically play together (i.e. master-only scope added)
	# These are things a server admin might choose to reject if it was decided to be significant
# Patch: Anything else: Bugfixes, UI changes, etc
# Currently 0.0.0 which means API, gameplay, etc can change suddenly and frequently
# Don't rely on it for anything
# 1.0.0 will be the reddit release
var version = "0.0.2"

var args

onready var Options = preload("res://scripts/args.gd").new().Options

func _ready():
	args = _get_args()

func get_master_player():
	return get_player(get_tree().get_network_unique_id())

func get_player(netid):
	# We not %d? Because sometimes we need to do get_player(thing.get_name())
	var path = "/root/Level/Players/%s" % str(netid)
	if has_node(path):
		return get_node(path)
	else:
		return null

func is_friendly(player):
	var mp = get_master_player()
	if mp:
		return player.player_info.is_right_team == mp.player_info.is_right_team
	else:
		return true # Doesn't matter, we're headless

var last_log_day = 0
func log(s, is_error=false, port=null):
	var output = ""
	var dt = OS.get_datetime()
	# Date, only if it's been over a day (on a separate line)
	if last_log_day != dt.day:
		output += "==== %d-%02d-%02d ====\n" % [dt.year, dt.month, dt.day]
		last_log_day = dt.day
	# Time
	var pm = dt.hour > 12
	var pmtext = "pm" if pm else "am"
	if pm:
		dt.hour -= 12
	output += "[%02d:%02d%s] " % [dt.hour, dt.minute, pmtext]
	if port:
		output += "[Server %d] " % port
	output += str(s)
	print(output)

func _get_args():
	var opts = Options.new()
	opts.set_banner(('A non-violent MOBA inspired by Overwatch and Zineth'))
	opts.add('-singleplayer', false, 'Whether to run singeplayer, starting immediately')
	opts.add('-server', false, 'Whether to run as server')
	opts.add('-matchmaker', false, 'Whether to be the sole matchmaker')
	opts.add('-client', false, 'Immediately connect as client')
	opts.add('-quick-play', false, 'Immediately connect to quick play')
	opts.add('-silent', false, 'If the server is not playing, merely serving')
	opts.add('-ip', '127.0.0.1', 'The ip to connect to (client only!)')
	opts.add('-port', 54673, 'The port to run a server on or connect to')
	opts.add('-hero', 'r', 'Your choice of hero (index)')
	opts.add('-level', 'r', 'Your choice of level (index) - server only!')
	opts.add('-start-game', false, 'Join as a client and immediately start the game')
	opts.add('-ai', true, 'Run this client as AI')
	opts.add('-no-record', true, "Don't record this play for AI later")
	opts.add('-h', false, "Print help")
	opts.parse()
	return opts

