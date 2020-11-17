extends ScrollContainer
class_name MappingEditor

var instrument:RccInstrument


func _ready() -> void:
	pass # Replace with function body.



func _update_mappings():
	for key in instrument.mappings.keys():
		if key is int:
			pass
