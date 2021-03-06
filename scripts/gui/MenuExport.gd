extends MenuButton

export var item_separation := 16
signal item_pressed(index)


func _ready():
	get_popup().add_item("Selected Instrument to Wav")
	get_popup().add_item("Selected Instrument to SFZ")
	get_popup().add_item("All Instruments to Wav")
	get_popup().add_item("All Instruments to SFZ")

	get_popup().connect("index_pressed", self, "_on_popup_index_pressed")
	get_popup().set("custom_constants/vseparation", item_separation)


func _on_popup_index_pressed(id):
	emit_signal("item_pressed", id)
