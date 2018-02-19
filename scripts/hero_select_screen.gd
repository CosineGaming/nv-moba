extends ColorRect

func _ready():
	get_node("Hero").connect("item_selected", self, "update_description")
	update_description(0)

func update_description(hero):
	var description = get_node("Hero").hero_text[hero]
	get_node("HeroDescription").set_text(description)

