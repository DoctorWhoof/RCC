extends MenuButton

export var item_separation := 16
signal item_pressed(index)


func _ready():
	get_popup().add_item("New                  ")
	get_popup().add_item("Load                 ")
	get_popup().add_item("Save                 ")
	get_popup().add_item("Save as              ")
	get_popup().add_item("Quit                 ")

	get_popup().connect("index_pressed", self, "_on_popup_index_pressed")
	get_popup().set("custom_constants/vseparation", item_separation)


func _on_popup_index_pressed(id):
	emit_signal("item_pressed", id)
