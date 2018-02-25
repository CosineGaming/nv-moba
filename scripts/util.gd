extends Node

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

