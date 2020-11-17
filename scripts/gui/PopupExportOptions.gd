extends PopupDialog

enum ExportStyle { Baked, Minimal }

var path := ""
var _export_mode = ExportMode.SingleWave
var _export_style = ExportStyle.Baked
var rcc_node:Rcc


onready var _progress_popup := $Popup_Progress
onready var _progress_bar := $Popup_Progress/Bar
onready var _progress_text := $Popup_Progress/Label2

onready var _file_dialog := $FileDialog
onready var _path_line := $VBoxContainer/HBox_Path/LineEdit_Path

onready var baked_check := $VBoxContainer/HBoxContainer/VBox_1/CheckBox_Baked
onready var minimal_check := $VBoxContainer/HBoxContainer/VBox_2/CheckBox_Minimal

onready var scheme_check := $VBoxContainer/CheckBox_Scheme
onready var precision_check := $VBoxContainer/HBox_Precision/CheckBox_Precision
onready var precision_option := $VBoxContainer/HBox_Precision/Option_Precision
onready var rate_check := $VBoxContainer/HBox_Rate/CheckBox_Rate
onready var rate_option := $VBoxContainer/HBox_Rate/Option_Rate

onready var none_check := $VBoxContainer/HBox_Numbers/CheckBox_None
onready var prepend_check := $VBoxContainer/HBox_Numbers/CheckBox_Prepend
onready var append_check := $VBoxContainer/HBox_Numbers/CheckBox_Append
onready var digits_spinbox := $VBoxContainer/HBox_Numbers/SpinBox_Digits

onready var spaces_check := $VBoxContainer/HBox_Spaces/CheckBox_Spaces
onready var remove_samples_check := $VBoxContainer/HBox_OldFiles/CheckBox_OldFiles



func open(mode):
	assert(rcc_node, "PopupExportOptions: Error, No RCC node provided")
	var project = rcc_node.project

	_export_mode = mode
	path = project.export_path
	_file_dialog.current_dir = path
	_path_line.text = path
	#load values from rcc.project
	if project.file_numbers == FileNumbers.None:
		none_check.pressed = true
	if project.file_numbers == FileNumbers.Prepend:
		prepend_check.pressed = true
	if project.file_numbers == FileNumbers.Append:
		append_check.pressed = true

	if project.override_rate > 0:
		rate_option.selected = project.override_rate
		rate_check.pressed = true
	else:
		rate_check.pressed = false

	if project.override_precision > -1:
#		print("Precision:", project.override_precision)
		precision_option.selected = project.override_precision
		precision_check.pressed = true
	else:
		precision_check.pressed = false

	match project.file_numbers:
		FileNumbers.None: none_check.pressed = true
		FileNumbers.Append: append_check.pressed = true
		FileNumbers.Prepend: prepend_check.pressed = true

	digits_spinbox.value = project.digit_count

#	_last_export_style = project.export_style
	_export_style = project.export_style
	match project.export_style:
		ExportStyle.Baked: baked_check.pressed = true
		ExportStyle.Minimal: minimal_check.pressed = true

	remove_samples_check.pressed = project.remove_old_samples
	spaces_check.pressed = project.convert_spaces

	if scheme_check.pressed:
		match mode:
			ExportMode.SingleWave, ExportMode.AllWaves:
				baked_check.pressed = true
				minimal_check.pressed = false
				baked_check.disabled = true
				minimal_check.disabled = true
				scheme_check.disabled = true
			_:
				baked_check.disabled = false
				minimal_check.disabled = false
				scheme_check.disabled = false
				match _export_style:
					ExportStyle.Baked:
						baked_check.pressed = true
						minimal_check.pressed = false
					ExportStyle.Minimal:
						baked_check.pressed = false
						minimal_check.pressed = true
	else:
		baked_check.disabled = true
		minimal_check.disabled = true

	popup_centered()


func _on_Button_Cancel_pressed() -> void:
	visible=false


func _on_Button_Export_pressed() -> void:
	#Without these "yield" lines, I can't actually see the File window disappear and the progress bar
	#appear BEFORE the files have actually been exported. They introduce a 1 frame delay between each action.
	yield(get_tree(),"idle_frame")
	_progress_popup.popup_centered()
	_progress_bar.value = 0
#	_export_dialog.hide()
	match _export_mode:
		ExportMode.SingleWave:
			var inst = rcc_node.project.get_selected()
			Export.to_wave_baked(inst, path, get_rate(inst), 0, false, get_precision(), get_space(), get_digits())
			print("Exported selected to WAV at '", path,"'")
		ExportMode.SingleSFZ:
			var inst = rcc_node.project.get_selected()
			var index = rcc_node.project.selected_index
			Export.to_sfz(
				inst, path,
				get_rate(inst),
				index,
				get_precision(),
				get_space(),
				remove_samples_check.pressed,
				get_digits(),
				get_export_style(inst),
				get_file_numbers()
			)
			print("Exported selected to SFZ at '", path,"'")
		ExportMode.AllWaves:
			var n :float= 0
			for inst in rcc_node.project.instruments:
				yield(get_tree(),"idle_frame")
				Export.to_wave_baked(inst, path, get_rate(inst), 0, false, get_precision(), get_space(), get_digits())
				_progress_bar.value = (n/rcc_node.project.instruments.size())*100
				_progress_text.text = inst.name
				n+=1
			print("Exported all instruments to single WAV files at ", path)
		ExportMode.AllSFZs:
			var n :float= 0
			for inst in rcc_node.project.instruments:
				yield(get_tree(),"idle_frame")
				Export.to_sfz(
					inst,
					path,
					get_rate(inst),
					n,
					get_precision(),
					get_space(),
					remove_samples_check.pressed,
					get_digits(),
					get_export_style(inst),
					get_file_numbers()
				)
				_progress_bar.value = (n/rcc_node.project.instruments.size())*100
				_progress_text.text = inst.name
				n+=1
			print("Exported all instruments to SFZ files at ", path)
	_progress_popup.hide()
	for track in rcc_node.tracks:
		track.stop()
	visible=false


func _on_CheckBox_Scheme_toggled(button_pressed: bool) -> void:
	if button_pressed:
		baked_check.disabled = false
		minimal_check.disabled = false
	else:
		baked_check.disabled = true
		minimal_check.disabled = true


func _on_Button_Path_pressed() -> void:
	_file_dialog.popup_centered()


func _on_FileDialog_dir_selected(dir: String) -> void:
	path=dir
	_path_line.text=dir
	rcc_node.project.export_path=dir


func _on_Option_Precision_item_selected(index: int) -> void:
	if precision_check.pressed:
		rcc_node.project.override_precision = precision_option.selected
#		print("Precision:", precision_option.selected)


func _on_Option_Rate_item_selected(index: int) -> void:
	if rate_check.pressed:
		rcc_node.project.override_rate = rate_option.selected


func _on_CheckBox_Rate_toggled(button_pressed: bool) -> void:
	match button_pressed:
		true:
			rcc_node.project.override_rate = rate_option.selected
		false:
			rcc_node.project.override_rate = -1


func _on_CheckBox_Precision_toggled(button_pressed: bool) -> void:
	match button_pressed:
		true:
			rcc_node.project.override_precision = rate_option.selected
		false:
			rcc_node.project.override_precision = -1


func _on_CheckBox_None_pressed() -> void:
	rcc_node.project.file_numbers = FileNumbers.None


func _on_CheckBox_Prepend_pressed() -> void:
	rcc_node.project.file_numbers = FileNumbers.Prepend


func _on_CheckBox_Append_pressed() -> void:
	rcc_node.project.file_numbers = FileNumbers.Append


func _on_SpinBox_Digits_value_changed(value: float) -> void:
	rcc_node.project.digit_count = value


func _on_CheckBox_Baked_pressed() -> void:
	rcc_node.project.export_style = ExportStyle.Baked
	_export_style = ExportStyle.Baked


func _on_CheckBox_Minimal_pressed() -> void:
	rcc_node.project.export_style = ExportStyle.Minimal
	_export_style = ExportStyle.Minimal


func _on_CheckBox_Spaces_toggled(button_pressed: bool) -> void:
	rcc_node.project.convert_spaces = button_pressed


func _on_CheckBox_OldFiles_toggled(button_pressed: bool) -> void:
	rcc_node.project.remove_old_samples = button_pressed


func get_rate(inst:RccInstrument)->int:
	var mixrate=inst.mix_rate
	if rate_check.pressed:
		match rate_option.selected:
			0: mixrate=22050
			1: mixrate=44100
			2: mixrate=88200
	return mixrate


func get_precision()->int:
	var precision=-1
	if precision_check.pressed:
		precision=precision_option.selected
	return precision


func get_space()->String:
	var space:= " "
	if spaces_check.pressed: space = "_"
	return space


func get_digits()->int:
	var digits := -1
	if prepend_check: digits = digits_spinbox.value
	return digits


func get_export_style(instrument:RccInstrument)->int:
	var style = instrument.scheme
	if scheme_check.pressed:
		if baked_check.pressed: style = ExportStyle.Baked
		if minimal_check.pressed: style = ExportStyle.Minimal
	return style


func get_file_numbers()->int:
	if prepend_check.pressed: return FileNumbers.Prepend
	if append_check.pressed: return FileNumbers.Append
	return FileNumbers.None

