extends ItemList
class_name InstrumentList, "res://textures/list.png"


func _on_main_instrument_list_changed(instrument_list, selected):
	clear()
	for inst in instrument_list:
		add_item("  "+inst.name)
	select(selected)

