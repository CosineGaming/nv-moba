# Swap with friends

extends "res://scripts/player.gd"

export var charge_time = 20
export var charge_multiplier = 3

var charge_bars = []

func _ready():
	pass

func _process(delta):
	if is_network_master():
		for i in range(charge_bars.size()):
			if charge_bars[i]:
				charge_bars[i].row = i
			else:
				charge_bars.remove(i)

func _input(event):
	if is_network_master():
		if event.is_action_pressed("primary_mouse"):
			var with = pick_by_friendly(true)
			if with:
				# Perform swap
				var temp = with.translation
				with.translation = translation
				translation = temp
				# Become with's master for a moment, and indicate its new location
				var status = with.get_status()
				with.rpc("set_status", status) # Needs to be reliable, because we're the only ones aware

				# Set up charge
				var bar = preload("res://scenes/gain_charge_bar.tscn").instance()
				get_node("MasterOnly/ChargeBar").add_child(bar)
				bar.time = charge_time
				bar.factor = charge_multiplier
				bar.tracking_player = with
				charge_bars.append(bar)

