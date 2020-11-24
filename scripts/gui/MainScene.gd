extends Control

signal instrument_list_changed(instrument_list, selected)
signal instrument_selected(instrument)
signal file_exported()

export(NodePath) var rcc_path
export var max_undo_levels := 20

var rcc :Rcc
var key_jazz_track:= 0

var _undo_stack := []

onready var _save_dialog := $FileDialogs/FileDialog_Save
onready var _load_dialog := $FileDialogs/FileDialog_Load
onready var _export_dialog := $FileDialogs/FileDialog_Export
onready var _export_options_popup := $FileDialogs/Popup_ExportOptions


func _enter_tree():
	rcc = get_node(rcc_path) as Rcc


func _ready():
	var screen_size := OS.get_screen_size()
	var window_size := OS.get_window_size()
	OS.set_window_position(Vector2((screen_size.x*0.5)-(window_size.x*0.5), 0))

	_undo_stack.resize(max_undo_levels)

	var session = ResourceLoader.load("user://session.tres")
	if session:
		print("Loading session file.")
		rcc.project = session
		_load_dialog.current_dir = rcc.project.path.get_base_dir()
		_save_dialog.current_dir = rcc.project.path.get_base_dir()
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


func undo_push():
	_undo_stack.push_back( rcc.project.get_selected().duplicate() )
#	_undo_stack.push_back( rcc.project.duplicate() )
#	print("storing undo")
	if _undo_stack.size()>max_undo_levels:
#		print("Trimming undo stack")
		_undo_stack.pop_front()


func undo_pull():
	var undo_intrument = _undo_stack.pop_back()
#	var undo_project = _undo_stack.pop_back()
	if undo_intrument:
#	if undo_project:
		print("retrieving undo")
		rcc.project.instruments[rcc.project.selected_index] = undo_intrument.duplicate()
#		rcc.project = undo_project.duplicate()
		rcc.tracks[key_jazz_track].instrument = rcc.project.get_selected()
		emit_signal("instrument_selected", rcc.project.get_selected())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		undo_pull()
#	elif event.is_action_pressed("redo"):
#		undo_


func _on_Wavetable_envelope_changed(env):
	if not rcc.project.empty():
		undo_push()
		rcc.project.get_selected().wave_envelope = env#.duplicate()


func _on_Pitch_envelope_changed(env):
	if not rcc.project.empty():
		undo_push()
		rcc.project.get_selected().pitch_envelope = env#.duplicate()


func _on_Note_envelope_changed(env):
	if not rcc.project.empty():
		undo_push()
		rcc.project.get_selected().note_envelope = env#.duplicate()


func _on_Volume_envelope_changed(env):
	if not rcc.project.empty():
		undo_push()
		rcc.project.get_selected().volume_envelope = env#.duplicate()
		rcc.tracks[key_jazz_track].stop_note()


func _on_Noise_envelope_changed(env):
	if not rcc.project.empty():
		undo_push()
		rcc.project.get_selected().noise_envelope = env#.duplicate()
		rcc.tracks[key_jazz_track].stop_note()


func _on_Morph_envelope_changed(env):
	if not rcc.project.empty():
		undo_push()
		rcc.project.get_selected().morph_envelope = env#.duplicate()
		rcc.tracks[key_jazz_track].stop_note()


func _on_Piano_note_played(note, octave):
	rcc.tracks[key_jazz_track].play_note(note, octave)


func _on_Piano_note_stopped():
	rcc.tracks[key_jazz_track].stop_note()
	key_jazz_track+=1
	if key_jazz_track>rcc.tracks.size()-1:
		key_jazz_track=0


func _on_Piano_playback_stopped() -> void:
	rcc.tracks[key_jazz_track].stop()


func _on_InstrumentList_item_selected(index):
	rcc.project.selected_index = index
	rcc.tracks[key_jazz_track].instrument = rcc.project.get_selected()
	rcc.tracks[key_jazz_track].stop_note()
	rcc.tracks[key_jazz_track].reset_mix_rate()
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_name_changed(inst_name):
	undo_push()
	rcc.project.get_selected().name = inst_name
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_pan_changed(pan):
	undo_push()
	rcc.project.get_selected().pan = pan
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_transpose_changed(transpose):
	undo_push()
	rcc.project.get_selected().transpose = transpose
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_volume_changed(vol):
	undo_push()
	rcc.project.get_selected().volume = vol
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)


func _on_InstrumentInspector_scheme_changed(value) -> void:
	undo_push()
	rcc.project.get_selected().scheme = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_mixrate_changed(rate):
	undo_push()
	rcc.project.get_selected().mix_rate = rate
	rcc.tracks[key_jazz_track].reset_mix_rate()
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_precision_changed(is_half_precision):
	undo_push()
	rcc.project.get_selected().half_precision = is_half_precision
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_length_changed(value):
	undo_push()
	var inst = rcc.project.get_selected()
	inst.set_envelope_size(value, inst.loop_in, inst.loop_out)
	update_auto_vibrato()
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_loop_in_changed(value):
	undo_push()
	var inst = rcc.project.get_selected()
	inst.set_envelope_size(inst.length, value, inst.loop_out)
	update_auto_vibrato()
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_loop_out_changed(value):
	undo_push()
	var inst = rcc.project.get_selected()
	inst.set_envelope_size(inst.length, inst.loop_in, value)
	update_auto_vibrato()
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_range_max_changed(value):
	undo_push()
	rcc.project.get_selected().range_max = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_range_min_changed(value):
	undo_push()
	rcc.project.get_selected().range_min = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_multisample_changed(is_multisample):
	undo_push()
	rcc.project.get_selected().multi_sample = is_multisample
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_interval_changed(value):
	undo_push()
	rcc.project.get_selected().sample_interval = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_vibrato_changed(value) -> void:
	undo_push()
	rcc.project.get_selected().vibrato = value
	update_auto_vibrato()
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_vibrato_depth_changed(value) -> void:
	undo_push()
	rcc.project.get_selected().vibrato_depth = value
	update_auto_vibrato()
	emit_signal("instrument_selected", rcc.project.get_selected())


func update_auto_vibrato():
	var inst:RccInstrument = rcc.project.get_selected()
	var env:Envelope = inst.pitch_envelope
	var new_env:Envelope
	if inst.vibrato:
		var height:float = (inst.vibrato_depth / env.max_value) * env.max_value
		print("vibrato:",height)
		new_env = EnvelopePresets.generate(
			Envelope.Waveform.sine,
			true, env.length(),
			env.min_value,
			env.max_value,
			height,
			inst.loop_in,
			inst.loop_out
		)
		new_env.loop = true
		new_env.attack = false
		new_env.release = false
	else:
		new_env = EnvelopePresets.generate(
			Envelope.Waveform.flat,
			false,
			env.length(),
			env.min_value,
			env.max_value,
			0,
			inst.loop_in,
			inst.loop_out
		)
		new_env.loop = false
		new_env.attack = false
		new_env.release = false
	rcc.project.get_selected().pitch_envelope = new_env


func _on_InstrumentInspector_vibrato_fade_changed(value) -> void:
	undo_push()
	rcc.project.get_selected().vibrato_fade = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_vibrato_rate_changed(value) -> void:
	undo_push()
	rcc.project.get_selected().vibrato_rate = value
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_psg_volume_changed(value) -> void:
	undo_push()
	rcc.project.get_selected().psg_volume = value
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

	new_inst.vibrato = inst.vibrato
	new_inst.vibrato_depth = inst.vibrato_depth
	new_inst.psg_volume = inst.psg_volume

	new_inst.scheme = inst.scheme
	new_inst.mix_rate = inst.mix_rate
	new_inst.half_precision = inst.half_precision
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
			_on_InstrumentList_item_selected(rcc.project.selected_index)
			emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected_index)
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
		5: #Quit
			_save_session()
			get_tree().quit()
			print("Quit: Auto saving session")


func _on_Menu_Export_item_pressed(index):
	_export_options_popup.rcc_node = rcc
	match index:
		0: #Selected to WAV
			_export_options_popup.open(ExportMode.SingleWave)
		1: #Selected to SFZ
			_export_options_popup.open(ExportMode.SingleSFZ)
		2: #All to WAV
			_export_options_popup.open(ExportMode.AllWaves)
		3: #All to SFZ
			_export_options_popup.open(ExportMode.AllSFZs)


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




