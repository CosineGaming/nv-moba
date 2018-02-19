extends "res://scripts/player.gd"

onready var placement = preload("res://scripts/placement.gd").new()

# --- Godot overrides ---

func _ready():
	# connect("start_placement", self, "add_wall")
	# connect("confirm_placement", self, "finalize_wall")
	placement.player = self
	placement.start_action = "hero_1_place_wall"
	placement.confirm_action = "hero_1_confirm_wall"
	placement.delete_action = "hero_1_remove_wall"
	placement.scene_path = "res://scenes/heroes/1_wall.tscn"
	placement.max_placed = 100

func _process(delta):
	if is_network_master():
		placement.place_input()

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

