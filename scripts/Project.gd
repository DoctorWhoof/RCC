extends Resource
class_name Project

export var selected := 0
export var instruments := []
export var path:= ""
export var export_path:=""

export var wavetable_min := -127
export var wavetable_max := 127
export var wavetable_length = 32

export var volume_min := 0
export var volume_max := 15

export var note_min := -12
export var note_max := 12

export var pitch_min := -15
export var pitch_max := 15

export var noise_min := 0
export var noise_max := 15

export var morph_min := 0
export var morph_max := 15

#var _clipboard_envelope:Envelope

func clear():
	instruments.clear()
	selected=0


func get_selected()->RccInstrument:
	if not instruments.empty():
		return instruments[selected]
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
	selected=b
	_validate_selection()


func create_instrument(waveform:int, index:int):
	var n := instruments.size()
	var inst := RccInstrument.new()

	inst.wave_envelope.min_value=wavetable_min
	inst.wave_envelope.max_value=wavetable_max
	inst.wave_envelope.generate_preset(waveform,wavetable_length)

	inst.volume_envelope.min_value=volume_min
	inst.volume_envelope.max_value=volume_max
	inst.volume_envelope.generate_preset(Envelope.Waveform.hit_sustain, inst.length)

	inst.pitch_envelope.min_value=pitch_min
	inst.pitch_envelope.max_value=pitch_max
	inst.pitch_envelope.generate_preset(Envelope.Waveform.flat, inst.length)

	inst.note_envelope.min_value=note_min
	inst.note_envelope.max_value=note_max
	inst.note_envelope.generate_preset(Envelope.Waveform.flat, inst.length)

	inst.noise_envelope.min_value=noise_min
	inst.noise_envelope.max_value=noise_max
	inst.noise_envelope.generate_preset(Envelope.Waveform.flat, inst.length)

	inst.morph_envelope.min_value=morph_min
	inst.morph_envelope.max_value=morph_max
	inst.morph_envelope.generate_preset(Envelope.Waveform.flat, inst.length)

	inst.name = "Instrument "+str(n)
	instruments.insert(index, inst)
	selected = index


func _validate_selection():
	if selected < 0:
		selected = 0
	elif selected > instruments.size()-1:
		selected = instruments.size()-1
