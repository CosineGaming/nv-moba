extends "res://scripts/player.gd"

export var charge_time = 20
export var charge_multiplier = 3

var charge_timers = {}
var charge_lasts = {}
var charge_players = {}
var charge_timer_bars = {}

func _ready():
	pass

func _process(delta):
	if is_network_master():
		var padding = -20
		var i = 1
		for name in charge_timers.keys():
			# Actual charge
			charge -= charge_lasts[name] * charge_multiplier
			charge += charge_players[name].charge * charge_multiplier
			charge_lasts[name] = charge_players[name].charge

			# Visual
			var bar = charge_timer_bars[name]
			bar.rect_position.y = i * padding
			bar.value = 100 * charge_timers[name].time_left / charge_time
			i += 1

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
				var name = with.get_name()
				# Make a timer
				var timer = Timer.new()
				timer.wait_time = charge_time
				timer.connect("timeout", self, "end_swap_built", [with.get_name()])
				timer.one_shot = true
				add_child(timer)
				timer.start()
				charge_timers[name] = timer
				charge_players[name] = with
				charge_lasts[name] = with.charge
				# Make a bar for it
				var bar = preload("res://scenes/gain_charge_bar.tscn").instance()
				$MasterOnly/ChargeBar.add_child(bar)
				charge_timer_bars[name] = bar

func end_swap_built(key):
	charge_timers[key].queue_free()
	charge_timers.erase(key)
	charge_timer_bars[key].queue_free()
	charge_timer_bars.erase(key)
	charge_lasts.erase(key)

