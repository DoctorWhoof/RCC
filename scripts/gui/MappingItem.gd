extends HBoxContainer
class_name MappingItem

var enabled := true

onready var checkbox := $CheckBox_enable
onready var spinbox := $SpinBox_index
onready var line := $LineEdit_name
onready var button_remove := $Button_remove



func _on_CheckBox_enable_toggled(button_pressed: bool) -> void:
	enabled = button_pressed
	spinbox.editable = button_pressed
	line.editable = button_pressed
