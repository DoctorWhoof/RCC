extends Resource
class_name Project

export var selected := 0
export var list := []

export var wavetable_min := -127
export var wavetable_max := 127
export var wavetable_length = 32

export var volume_min := 0
export var volume_max := 15
export var volume_length := 8

export var pitch_min := -12
export var pitch_max := 12
export var pitch_length := 8

export var noise_min := 0
export var noise_max := 15
export var noise_length := 8

func clear():
	list.clear()
	selected=0


func get_selected()->RccInstrument:
	if not list.empty():
		return list[selected]
	return null


func size()->int:
	return list.size()


func empty()->bool:
	return list.empty()


func remove(index):
	list.remove(index)


func insert(index, instrument):
	list.insert(index, instrument)


func swap_instrument(a:int, b:int):
	var lower = list[a]
	var higher = list[b]
	list[b] = lower
	list[a] = higher
	selected=b
	_validate_selection()


func create_instrument(waveform:int, index:int):
	var n := list.size()
	var inst := RccInstrument.new()

	inst.wave_envelope.min_value=wavetable_min
	inst.wave_envelope.max_value=wavetable_max
	inst.wave_envelope.generate_preset(waveform,wavetable_length)

	inst.volume_envelope.min_value=volume_min
	inst.volume_envelope.max_value=volume_max
	inst.volume_envelope.generate_preset(Envelope.Waveform.hit_sustain, volume_length)

	inst.pitch_envelope.min_value=pitch_min
	inst.pitch_envelope.max_value=pitch_max
	inst.pitch_envelope.generate_preset(Envelope.Waveform.flat, pitch_length)

	inst.noise_envelope.min_value=noise_min
	inst.noise_envelope.max_value=noise_max
	inst.noise_envelope.generate_preset(Envelope.Waveform.flat, noise_length)

	inst.name = "Instrument "+str(n)
	list.insert(index, inst)
	selected = index


func _validate_selection():
	if selected < 0:
		selected = 0
	elif selected > list.size()-1:
		selected = list.size()-1
