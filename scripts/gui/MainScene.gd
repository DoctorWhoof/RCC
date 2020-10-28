extends Control

enum ExportMode { SingleWave, SingleSFZ, AllWaves, AllSFZs }

signal instrument_list_changed(instrument_list, selected)
signal instrument_selected(instrument)
signal file_exported()

export(NodePath) var rcc_path
var rcc :Rcc
var key_jazz_track:= 0
var _export_mode = ExportMode.SingleWave

onready var _save_dialog := $FileDialogs/FileDialog_Save
onready var _load_dialog := $FileDialogs/FileDialog_Load
onready var _export_dialog := $FileDialogs/FileDialog_Export
onready var _progress_popup := $FileDialogs/Popup_Progress
onready var _progress_bar := $FileDialogs/Popup_Progress/Bar
onready var _progress_text := $FileDialogs/Popup_Progress/Label2


func _enter_tree():
	rcc = get_node(rcc_path) as Rcc


func _ready():
	var screen_size := OS.get_screen_size()
	var window_size := OS.get_window_size()
	OS.set_window_position(Vector2((screen_size.x*0.5)-(window_size.x*0.5), 0))

	var session = ResourceLoader.load("user://session.tres")
	if session:
		print("Loading session file.")
		rcc.project = session
		_load_dialog.current_dir = rcc.project.path.get_base_dir()
		_save_dialog.current_dir = rcc.project.path.get_base_dir()
		_export_dialog.current_dir = rcc.project.export_path
	else:
		print("Session file not found, creating new one.")
		rcc.project.create_instrument(Envelope.Waveform.square,0)
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)
	_on_InstrumentList_item_selected(rcc.project.selected_index)


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_save_session()
		print("Quit: Auto saving session")


func _save_session():
	var err := ResourceSaver.save("user://session.tres", rcc.project)
	if err: print("Error saving session file: ",err)


func _on_Wavetable_envelope_changed(env):
	if not rcc.project.empty():
		rcc.project.get_selected().wave_envelope = env


func _on_Pitch_envelope_changed(env):
	if not rcc.project.empty():
		rcc.project.get_selected().pitch_envelope = env


func _on_Note_envelope_changed(env):
	if not rcc.project.empty():
		rcc.project.get_selected().note_envelope = env


func _on_Volume_envelope_changed(env):
	if not rcc.project.empty():
		rcc.project.get_selected().volume_envelope = env
		rcc.tracks[key_jazz_track].stop_note()


func _on_Noise_envelope_changed(env):
	pass


func _on_Morph_envelope_changed(env):
	pass


func _on_Piano_note_played(note, octave):
	rcc.tracks[key_jazz_track].play_note(note, octave)


func _on_Piano_note_stopped():
	rcc.tracks[key_jazz_track].stop_note()
	key_jazz_track+=1
	if key_jazz_track>rcc.tracks.size()-1:
		key_jazz_track=0


func _on_InstrumentList_item_selected(index):
	rcc.project.selected_index = index
	rcc.tracks[key_jazz_track].instrument = rcc.project.get_selected()
	rcc.tracks[key_jazz_track].stop_note()
	rcc.tracks[key_jazz_track].reset_mix_rate()
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_name_changed(inst_name):
	rcc.project.get_selected().name = inst_name
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_pan_changed(pan):
	rcc.project.get_selected().pan = pan
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_transpose_changed(transpose):
	rcc.project.get_selected().transpose = transpose
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_volume_changed(vol):
	rcc.project.get_selected().volume = vol
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_mixrate_changed(rate):
	rcc.project.get_selected().mix_rate = rate
	rcc.tracks[key_jazz_track].reset_mix_rate()
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_precision_changed(is_half_precision):
	rcc.project.get_selected().half_precision = is_half_precision
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_length_changed(value):
	var inst = rcc.project.get_selected()
	inst.set_envelope_size(value, inst.loop_in, inst.loop_out)
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_loop_in_changed(value):
	var inst = rcc.project.get_selected()
	inst.set_envelope_size(inst.length, value, inst.loop_out)
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_loop_out_changed(value):
	var inst = rcc.project.get_selected()
	inst.set_envelope_size(inst.length, inst.loop_in, value)
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_range_max_changed(value):
	rcc.project.get_selected().range_max = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_range_min_changed(value):
	rcc.project.get_selected().range_min = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_multisample_changed(is_multisample):
	rcc.project.get_selected().multi_sample = is_multisample
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_interval_changed(value):
	rcc.project.get_selected().sample_interval = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_Button_remove_pressed():
	if rcc.project.size()>1:
		rcc.project.remove(rcc.project.selected_index)
		rcc.project._validate_selection()
		emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)
		_on_InstrumentList_item_selected(rcc.project.selected_index)


func _on_Button_add_pressed():
	rcc.project.create_instrument(Envelope.Waveform.square, rcc.project.selected_index+1)
	_on_InstrumentList_item_selected(rcc.project.selected_index)
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_Button_duplicate_pressed():
#	var new_inst = rcc.project.get_selected().duplicate(true)
#	new_inst.name += " Copy"

	var inst = rcc.project.get_selected()
	var new_inst = RccInstrument.new()
	new_inst.name = inst.name + " Copy"
	new_inst.volume = inst.volume
	new_inst.pan = inst.pan
	new_inst.transpose = inst.transpose
	new_inst.length = inst.length
	new_inst.loop_in = inst.loop_in
	new_inst.loop_out = inst.loop_out
	new_inst.sample_interval = inst.sample_interval
	new_inst.range_min = inst.range_min
	new_inst.range_max = inst.range_max
	new_inst.multi_sample = inst.multi_sample
	new_inst.wave_envelope = inst.wave_envelope.duplicate()
	new_inst.pitch_envelope = inst.pitch_envelope.duplicate()
	new_inst.volume_envelope = inst.volume_envelope.duplicate()
	new_inst.noise_envelope = inst.noise_envelope.duplicate()
	new_inst.morph_envelope = inst.morph_envelope.duplicate()

	rcc.project.selected_index+=1
	rcc.project.insert(rcc.project.selected_index, new_inst)
	_on_InstrumentList_item_selected(rcc.project.selected_index)
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_Button_raise_pressed():
	if rcc.project.selected_index > 0:
		rcc.project.swap_instrument(rcc.project.selected_index, rcc.project.selected_index-1)
		_on_InstrumentList_item_selected(rcc.project.selected_index)
		emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_Button_lower_pressed():
	if rcc.project.selected_index < rcc.project.size()-1:
		rcc.project.swap_instrument(rcc.project.selected_index, rcc.project.selected_index+1)
		_on_InstrumentList_item_selected(rcc.project.selected_index)
		emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_Menu_Project_item_pressed(index):
	match index:
		0: #New
			rcc.project.clear()
			rcc.project.path=""
			_on_Button_add_pressed()
			print("Project Cleared")
		1: #Load
			_load_dialog.popup()
		2: #Save
			if rcc.project.path:
				var err := ResourceSaver.save(rcc.project.path, rcc.project)
				if err: print("Error saving session file: ",err)
				print("Project Saved to ", rcc.project.path)
			else:
				_save_dialog.popup()
		3: #Save As
			_save_dialog.popup()
		4: #Quit
			_save_session()
			get_tree().quit()
			print("Quit: Auto saving session")


func _on_Menu_Export_item_pressed(index):
	match index:
		0: #Selected to WAV
			_export_mode = ExportMode.SingleWave
			_export_dialog.popup()
		1: #Selected to SFZ
			_export_mode = ExportMode.SingleSFZ
			_export_dialog.popup()
		2: #All to WAV
			_export_mode = ExportMode.AllWaves
			_export_dialog.popup()
		3: #All to SFZ
			_export_mode = ExportMode.AllSFZs
			_export_dialog.popup()


func _on_FileDialog_Save_file_selected(path):
	if path:
		var err := ResourceSaver.save(path, rcc.project)
		if err:
			print("Error saving session file: ",err)
		else:
			rcc.project.path = path
			print("Project Saved at ", path)
			_load_dialog.current_dir = rcc.project.path.get_base_dir()
			print("load dir:", _load_dialog.current_dir)


func _on_FileDialog_Load_file_selected(path):
	if path:
		rcc.project = ResourceLoader.load(path)
		if not rcc.project:
			print("Error Loading Project")
		else:
			rcc.project.path = path
			print("Project loaded")
			_save_dialog.current_dir = rcc.project.path.get_base_dir()
			print("save dir:", _save_dialog.current_dir)
			emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_FileDialog_Export_dir_selected(dir):
	#Without these "yield" lines, I can't actually see the File window disappear and the progress bar
	#appear BEFORE the files have actually been exported. They introduce a 1 frame delay between each action.
	yield(get_tree(),"idle_frame")
	rcc.project.export_path = dir
	_progress_popup.popup()
	_progress_bar.value = 0
	_export_dialog.hide()
	match _export_mode:
		ExportMode.SingleWave:
			Export.to_wave(rcc.project.get_selected(), dir, 0, false)
			print("Exported selected to WAV at '", dir,"'")
		ExportMode.SingleSFZ:
			Export.to_sfz(rcc.project.get_selected(), dir)
			print("Exported selected to SFZ at '", dir,"'")
		ExportMode.AllWaves:
			var n :float= 0
			for inst in rcc.project.instruments:
				yield(get_tree(),"idle_frame")
				Export.to_wave(inst, dir, 0, false)
				_progress_bar.value = (n/rcc.project.instruments.size())*100
				_progress_text.text = inst.name
				n+=1
			print("Exported all instruments to single WAV files at ", dir)
		ExportMode.AllSFZs:
			var n :float= 0
			for inst in rcc.project.instruments:
				yield(get_tree(),"idle_frame")
				Export.to_sfz(inst, dir, n)
				_progress_bar.value = (n/rcc.project.instruments.size())*100
				_progress_text.text = inst.name
				n+=1
			print("Exported all instruments to SFZ files at ", dir)
	_progress_popup.hide()

