extends Control
class_name InstrumentInspector, "res://textures/inspector.png"

signal name_changed(inst_name)
signal volume_changed(vol)
signal pan_changed(pan)
signal transpose_changed(octaves)
signal precision_changed(is_half_precision)
signal length_changed(value)
signal loop_in_changed(value)
signal loop_out_changed(value)
signal mixrate_changed(rate)
signal range_min_changed(value)
signal range_max_changed(value)
signal multisample_changed(is_multisample)
signal interval_changed(value)

onready var name_field := $HBox/VBox/HBox_Name/LineEdit_name
onready var volume_field := $HBox/VBox/HBox_Volume/SpinBox_volume
onready var pan_field := $HBox/VBox/HBox_Pan/SpinBox_pan
onready var transpose_field := $HBox/VBox/HBox_Transpose/SpinBox_transpose

onready var length_field := $HBox/VBox/HBox_Length/SpinBox_length
onready var in_field := $HBox/VBox/HBox_Loop/SpinBox_loop_in
onready var out_field := $HBox/VBox/HBox_Loop/SpinBox_loop_out

onready var mixrate_button := $HBox/VBox/HBox_MixRate/OptionButton_MixRate
onready var precision_button := $HBox/VBox/HBox_Precision/OptionButton_precision
onready var multisample_check := $HBox/VBox/HBox_Multisample/CheckBox_Multisample
onready var interval_field := $HBox/VBox/HBox_Interval/SpinBox_Interval
onready var range_min_field := $HBox/VBox/HBox_OctaveRange/SpinBox_rangeMin
onready var range_max_field := $HBox/VBox/HBox_OctaveRange/SpinBox_rangeMax
onready var total_label := $HBox/VBox/HBox_Total/Label_Total

#EXPERIMENTAL: Avoids feedback loops when receiving an "instrument_selected" signal
var suspend_signals := false

func _on_LineEdit_name_text_changed(new_text):
	if suspend_signals: return
	emit_signal("name_changed", new_text)


func _on_SpinBox_volume_value_changed(value):
	if suspend_signals: return
	emit_signal("volume_changed", value)


func _on_SpinBox_pan_value_changed(value):
	if suspend_signals: return
	emit_signal("pan_changed", value)


func _on_SpinBox_transpose_value_changed(value):
	if suspend_signals: return
	emit_signal("transpose_changed", value)


func _on_OptionButton_precision_item_selected(index):
	if suspend_signals: return
	match index:
		0: emit_signal("precision_changed", false)
		_: emit_signal("precision_changed", true)


func _on_OptionButton_MixRate_item_selected(index):
	if suspend_signals: return
	match index:
		0: emit_signal("mixrate_changed", 44100)
		_: emit_signal("mixrate_changed", 22050)


func _on_SpinBox_length_value_changed(value):
	in_field.max_value = value-1
	out_field.max_value = value-1
	in_field.value = clamp(in_field.value, 0, value-1)
	out_field.value = clamp(out_field.value, in_field.value, value-1)
	if suspend_signals: return
	emit_signal("length_changed",length_field.value)


func _on_SpinBox_loop_in_value_changed(value):
	if suspend_signals: return
	out_field.min_value = in_field.value
	emit_signal("loop_in_changed", in_field.value)


func _on_SpinBox_loop_out_value_changed(value):
	if suspend_signals: return
	emit_signal("loop_out_changed", out_field.value)


func _on_CheckBox_Multisample_toggled(button_pressed):
	range_max_field.editable = button_pressed
	range_min_field.editable = button_pressed
	interval_field.editable = button_pressed
	if not button_pressed:
		total_label.text = "Total samples: 1"
	else:
		calculate_total_samples()
	if suspend_signals: return
	emit_signal("multisample_changed", button_pressed)

func _on_SpinBox_rangeMin_value_changed(value):
	range_max_field.min_value=value
	calculate_total_samples()
	if suspend_signals: return
	emit_signal("range_min_changed", value)


func _on_SpinBox_rangeMax_value_changed(value):
	range_min_field.max_value=value
	calculate_total_samples()
	if suspend_signals: return
	emit_signal("range_max_changed", value)


func _on_SpinBox_Interval_value_changed(value):
	if suspend_signals: return
	emit_signal("interval_changed", value)
	calculate_total_samples()


func calculate_total_samples():
	var total:int= ((range_max_field.value-range_min_field.value+1)*12)/interval_field.value
	total_label.text = "Total samples: "+str(total)


func _on_main_instrument_selected(instrument):
#	print(instrument.name,", ",instrument.loop_in,", ",instrument.loop_out)
	if instrument:
		suspend_signals = true
		name_field.text = instrument.name
		volume_field.value = instrument.volume
		pan_field.value = instrument.pan
		transpose_field.value = instrument.transpose
		length_field.value=instrument.length
		in_field.value=instrument.loop_in
		out_field.value=instrument.loop_out
		multisample_check.pressed=instrument.multi_sample
		range_min_field.value=instrument.range_min
		range_max_field.value=instrument.range_max
		interval_field.value=instrument.sample_interval
		calculate_total_samples()
		match instrument.mix_rate:
			44100: mixrate_button.selected = 0
			_: mixrate_button.selected = 1
		match instrument.half_precision:
			false: precision_button.selected = 0
			_: precision_button.selected = 1
		suspend_signals=false
