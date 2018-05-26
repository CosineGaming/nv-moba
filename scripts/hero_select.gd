extends OptionButton

const hero_names = [
	"INDUSTRIA",
	"IRA",
	"LUSSURIA",
	"CARITAS",
	"PAZIENZA",
	"SUPERBIA",
]

const hero_text = [
	"DILIGENCE.\n\nWallride by jumping on walls.\n\nHold left click to go faster (but spend switch charge).",
	"WRATH.\n\nPress E and click (or just click) to build a wall.\n\nRight click to destroy one.",
	"LUST.\n\nYou attract nearby heroes.\n\nPress E to switch to repelling them.",
	"GENEROSITY.\n\nMake contact with a friend to boost their speed.\n\nPress E to separate.",
	"PATIENCE.\n\nHold left mouse button on an enemy to slow them down.\n\nPress E to delete someone else's building (costs charge).",
	"PRIDE.\n\nDrag on enemies to bully them around.\n\nClick to build a portal. Click again to build its partner (costs charge).",
]

func _ready():
	for hero_index in range(hero_names.size()):
		add_item(hero_names[hero_index], hero_index)

	connect("item_selected", self, "set_hero")

func set_hero(hero):
	select(hero)
	networking.set_info_from_server("hero", hero)

func random_hero():
	var hero = randi() % hero_names.size()
	set_hero(hero)
	return hero

