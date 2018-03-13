extends Node

# Semantic versioning, more or less
# Major: Server cannot accept requests (i.e. new hero, or network protocol change)
# Minor: Gameplay was significantly changed, but these can still technically play together (i.e. master-only scope added)
	# These are things a server admin might choose to reject if it was decided to be significant
# Patch: Anything else: Bugfixes, UI changes, etc
# Currently 0.0.0 which means API, gameplay, etc can change suddenly and frequently
# Don't rely on it for anything
# 1.0.0 will be the reddit release
var version = "0.0.0"

func get_master_player():
	var path = "/root/Level/Players/%d" % get_tree().get_network_unique_id()
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

