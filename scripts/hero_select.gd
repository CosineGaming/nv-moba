extends OptionButton

const hero_names = [
	"INDUSTRIA",
	"IRA",
	"LUSSURIA",
	"CARITAS"
]

func _ready():
	for hero_index in range(hero_names.size()):
		add_item(hero_names[hero_index], hero_index)
