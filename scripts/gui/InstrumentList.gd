extends ItemList
class_name InstrumentList, "res://textures/list.png"


func _on_RCC_Connections_instrument_list_changed(instrument_list, instrument_selected):
	clear()
	for inst in instrument_list:
		add_item("  "+inst.name)
	select(instrument_selected)
