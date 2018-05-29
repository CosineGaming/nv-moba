extends "res://scripts/player.gd"

onready var placement = preload("res://scripts/placement.gd").new(self, "res://scenes/heroes/1_wall.tscn")
onready var place_wall_ability = get_node("MasterOnly/PlaceWall")

export var looked_at_charge_suck = 25 # charge / sec

# --- Godot overrides ---

func _ready():
	placement.start_action = "hero_1_place_wall"
	placement.confirm_action = "hero_1_confirm_wall"
	placement.delete_action = "hero_1_remove_wall"
	placement.max_placed = 5

func _process(delta):
	if is_network_master():
		var can_build = charge > place_wall_ability.cost
		if can_build:
			if placement.place_input():
				build_charge(-place_wall_ability.cost)

func _exit_tree():
	._exit_tree()
	if placement:
		placement.clear()

# --- Player overrides ---

func spawn():
	.spawn()
	if placement:
		placement.clear()

# --- Own ---

# Passive: suck the charge out of people who look at us!
# This is a special method called by player when any object is looked at
func on_looked_at(who, delta):
	# Why do we check this if we can't look at ourselves? Walls call this method from their looked_at
	# Also, why not use util.is_friendly? Because we're not master, we're slave (looker is master)
	if who.player_info.is_right_team != player_info.is_right_team:
		var subtracted = who.build_charge(-looked_at_charge_suck * delta)
		build_charge(-subtracted)
		# We rset our charge because otherwise it won't be acknowledged
		# because we're not master
		# The *PICKER* is master, we're slave! Well, let's flip that for a mo'
		rset("charge", charge)

