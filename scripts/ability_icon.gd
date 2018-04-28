extends Control

onready var hero = get_node("../..")
onready var bar = get_node("Bar")
onready var available = get_node("Available")
export var cost = 1
export var ability_name = "Ability"
export var display_progress = true
# This is intended to be public
var disabled = false

func _ready():
	get_node("Name").text = ability_name

func _process(delta):
	if disabled:
		available.hide()
		bar.value = 0
	else:
		if display_progress:
			if cost == 0:
				bar.value = 100 if hero.switch_charge > 0 else 0
			else:
				bar.value = 100 * hero.switch_charge / cost
		if hero.switch_charge > cost:
			available.show()
		else:
			available.hide()
