extends Node

func get_master_player():
	return get_node("/root/Level/Players/%d" % get_tree().get_network_unique_id())

func is_friendly(player):
	return player.player_info.is_right_team == get_master_player().player_info.is_right_team

