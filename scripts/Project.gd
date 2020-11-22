extends Resource
class_name Project

export var selected_index := 0
export var instruments := []

export var export_style := ExportStyle.Baked
export var path:= ""
export var export_path:=""
export var convert_spaces:= true
export var remove_old_samples := true
export var override_precision := -1
export var override_rate := -1
export var file_numbers := FileNumbers.Prepend
export var digit_count := 3

export var wavetable_min := -127
export var wavetable_max := 127
export var wavetable_length = 32

export var volume_min := 0
export var volume_max := 15

export var note_min := -32
export var note_max := 32

export var pitch_min := -15
export var pitch_max := 15

export var noise_min := 0
export var noise_max := 15

export var morph_min := 0
export var morph_max := 15

func clear():
	instruments.clear()
	create_instrument(Envelope.Waveform.square,0)
	selected_index=0
	path = ""


func get_selected()->RccInstrument:
	if not instruments.empty():
		return instruments[selected_index]
	return null


func size()->int:
	return instruments.size()


func empty()->bool:
	return instruments.empty()


func remove(index):
	instruments.remove(index)


func insert(index, instrument):
	instruments.insert(index, instrument)


func swap_instrument(a:int, b:int):
	var lower = instruments[a]
	var higher = instruments[b]
	instruments[b] = lower
	instruments[a] = higher
	selected_index=b
	_validate_selection()


func create_instrument(waveform:int, index:int):
	var n := instruments.size()
	var inst := RccInstrument.new()

	inst.wave_envelope = EnvelopePresets.generate(waveform, false, wavetable_length, wavetable_min, wavetable_max)
	inst.volume_envelope = EnvelopePresets.generate(Envelope.Waveform.hit_sustain, false, inst.length, volume_min, volume_max)
	inst.pitch_envelope = EnvelopePresets.generate(Envelope.Waveform.flat, false, inst.length, pitch_min, pitch_max)
	inst.note_envelope = EnvelopePresets.generate(Envelope.Waveform.flat, false, inst.length, note_min, note_max)
	inst.noise_envelope = EnvelopePresets.generate(Envelope.Waveform.flat, false, inst.length, noise_min, noise_max)
	inst.morph_envelope = EnvelopePresets.generate(Envelope.Waveform.flat, false, inst.length, morph_min, morph_max)

	inst.name = "Instrument "+str(n)
	instruments.insert(index, inst)
	selected_index = index


func _validate_selection():
	if selected_index < 0:
		selected_index = 0
	elif selected_index > instruments.size()-1:
		selected_index = instruments.size()-1
