extends Node

signal instrument_list_changed(instrument_list, selected)
signal instrument_selected(instrument)

export(NodePath) var rcc_path
var rcc :Rcc
var key_jazz_track		:= 0

func _enter_tree():
	rcc = get_node(rcc_path) as Rcc


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_save_session()
		print("Quit: Auto saving session")


func _ready():
	var session = ResourceLoader.load("user://session.tres")
	if session:
		rcc.project = session
	else:
		rcc.project.create_instrument(Envelope.Waveform.square,0)
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)
	_on_InstrumentList_item_selected(rcc.project.selected)


func _on_Wavetable_envelope_changed(env):
	if not rcc.project.empty():
		rcc.project.get_selected().wave_envelope = env


func _on_Pitch_envelope_changed(env):
	if not rcc.project.empty():
		rcc.project.get_selected().pitch_envelope = env


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
	rcc.project.selected = index
	rcc.tracks[key_jazz_track].instrument = rcc.project.get_selected()
	rcc.tracks[key_jazz_track].stop_note()
	rcc.tracks[key_jazz_track].reset_mix_rate()
	emit_signal("instrument_selected", rcc.project.get_selected())


func _on_InstrumentInspector_name_changed(inst_name):
	rcc.project.get_selected().name = inst_name
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


func _on_InstrumentInspector_pan_changed(pan):
	rcc.project.get_selected().pan = pan
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


func _on_InstrumentInspector_transpose_changed(transpose):
	rcc.project.get_selected().transpose = transpose
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


func _on_InstrumentInspector_volume_changed(vol):
	rcc.project.get_selected().volume = vol
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


func _on_InstrumentInspector_mixrate_changed(rate):
	rcc.project.get_selected().mix_rate = rate
	rcc.tracks[key_jazz_track].reset_mix_rate()
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


func _on_InstrumentInspector_precision_changed(is_half_precision):
	rcc.project.get_selected().half_precision = is_half_precision
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


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
		rcc.project.remove(rcc.project.selected)
		rcc.project._validate_selection()
		emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)
		_on_InstrumentList_item_selected(rcc.project.selected)


func _on_Button_add_pressed():
	rcc.project.create_instrument(Envelope.Waveform.square, rcc.project.size())
	_on_InstrumentList_item_selected(rcc.project.size()-1)
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


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


	rcc.project.selected+=1
	rcc.project.insert(rcc.project.selected, new_inst)
	_on_InstrumentList_item_selected(rcc.project.selected)
	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


func _on_Button_raise_pressed():
	if rcc.project.selected > 0:
		rcc.project.swap_instrument(rcc.project.selected, rcc.project.selected-1)
		_on_InstrumentList_item_selected(rcc.project.selected)
		emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


func _on_Button_lower_pressed():
	if rcc.project.selected < rcc.project.size()-1:
		rcc.project.swap_instrument(rcc.project.selected, rcc.project.selected+1)
		_on_InstrumentList_item_selected(rcc.project.selected)
		emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


#func _on_Button_New_pressed():
#	rcc.project.clear()
#	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)
#
#
#func _on_Button_Load_pressed():
#	rcc.project = ResourceLoader.load("user://session.tres")
#	assert(rcc.project, "Error loading session file")
#	emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)


func _save_session():
	var err := ResourceSaver.save("user://session.tres", rcc.project)
	if err: print("Error saving session file: ",err)


func _on_Menu_Project_item_pressed(index):
	print(index)
	match index:
		0: #New
			rcc.project.clear()
			emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)
			print("Project Cleared")
		1: #Load
			rcc.project = ResourceLoader.load("user://session.tres")
			assert(rcc.project, "Error loading session file")
			emit_signal("instrument_list_changed", rcc.project.instruments, rcc.project.selected)
			print("Project loaded")
		2: #Save
			var err := ResourceSaver.save("user://session.tres", rcc.project)
			if err: print("Error saving session file: ",err)
			print("Project Saved")
		3: #Save As
			var err := ResourceSaver.save("user://session.tres", rcc.project)
			if err: print("Error saving session file: ",err)
			print("Project Saved As")
		4: #Quit
			_save_session()
			get_tree().quit()
			print("Quit: Auto saving session")


func _on_MenuButton_item_pressed(index):
	match index:
		0: #Selected to WAV
			Export.to_wave(rcc.project.get_selected(), "user://", 0, false)
			print("Exported selected to WAV")
		1: #Selected to SFZ
			Export.to_sfz(rcc.project.get_selected())
			print("Exported selected to SFZ")
		2: #All to WAV
			for inst in rcc.project.instruments:
				Export.to_wave(inst, "user://", 0, false)
			print("Exported all instruments to WAV")
		3: #All to SFZ
			for inst in rcc.project.instruments:
				Export.to_sfz(inst)
			print("Exported selected to SFZ")





