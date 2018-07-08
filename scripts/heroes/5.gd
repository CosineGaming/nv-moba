# Bully enemies, place portals for friends

extends "res://scripts/player.gd"

onready var placement = preload("res://scripts/placement.gd").new(self, "res://scenes/heroes/5_portal.tscn")
onready var portal_ability = get_node("MasterOnly/Portal")
onready var teleport_ability = get_node("MasterOnly/Teleport")

var radius = 15
# The spaces make the bracket centered, rather than on of the dots
var first_crosshair = "   [..."
var second_crosshair = "...]   "
var no_portal_crosshair = "+"

var flicking = null
var flick_charge = 3
var flick_strength = 4

# --- Godot overrides ---

func _ready():
	placement.start_action = "primary_ability"
	placement.confirm_action = "primary_mouse"
	placement.delete_action = "secondary_mouse"
	placement.max_placed = 100
	set_process_input(true)

func _process(delta):
	if is_network_master():
		var is_second = placement.placed.size() % 2 != 0
		var portal_crosshair = second_crosshair if is_second else first_crosshair
		var crosshair = no_portal_crosshair if charge < portal_ability.cost else portal_crosshair
		get_node("MasterOnly/Crosshair").set_text(crosshair)
		var can_build = charge > portal_ability.cost
		if placement.place_input(radius, can_build, true) and is_second:
			build_charge(-portal_ability.cost)

		teleport_ability.disabled = placement.placed.size() <= 1

func _input(event):
	flick_input()

func _exit_tree():
	._exit_tree()
	if placement:
		placement.clear()

# --- Player overrides ---

# --- Own ---

func flick_input():
	if Input.is_action_just_pressed("primary_mouse"):
		var pick = pick_by_friendly(false)
		if pick:
			flicking = pick
	if flicking and Input.is_action_just_released("primary_mouse"):
		var aim = get_node("Yaw/Pitch").get_global_transform().basis
		var forwards = -aim[2]
		var distance = (flicking.translation - translation).length()
		forwards *= distance
		var towards = translation + forwards
		var gravity = PhysicsServer.area_get_param(get_world().get_space(), PhysicsServer.AREA_PARAM_GRAVITY_VECTOR)
		# Automatically account for gravity, so as to make UI more intuitive
		towards -= gravity
		rpc("flick", flicking.get_name(), towards)
		flicking = null
		build_charge(flick_charge)

sync func flick(player_id, towards):
	var who = util.get_player(player_id)
	if who.is_network_master():
		var direction = towards - who.translation
		var impulse = direction.normalized() * flick_strength * who.get_mass()
		who.apply_impulse(Vector3(), impulse)

