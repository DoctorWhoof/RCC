extends Control
class_name EnvelopeScene, "res://textures/envelope.png"

enum Role {
	wave, volume, pitch, noise, morph
}

signal envelope_changed(env)

export(Role) var envelope_type

onready var presets := $VBoxContainer/HBoxContainer_Tools/presets
onready var editor := $VBoxContainer/editor
onready var length := $VBoxContainer/HBoxContainer_Tools/length_SpinBox
onready var min_value := $VBoxContainer/HBoxContainer_Tools/min_SpinBox
onready var max_value := $VBoxContainer/HBoxContainer_Tools/max_SpinBox
onready var loop := $VBoxContainer/HBoxContainer_Tools/loop_Checkbox
onready var loop_in := $VBoxContainer/HBoxContainer_Tools/in_SpinBox
onready var loop_out := $VBoxContainer/HBoxContainer_Tools/out_SpinBox
onready var attack := $VBoxContainer/HBoxContainer_Tools/attack_Checkbox
onready var release := $VBoxContainer/HBoxContainer_Tools/release_Checkbox


func _ready():
	match envelope_type:
		Role.wave:
			editor.envelope = preload("res://envelopes/envelope_wavetable.tres")
			presets.add_item("Custom", Envelope.Waveform.custom)
			presets.add_item("Pulse 50", Envelope.Waveform.square)
			presets.add_item("Pulse 25", Envelope.Waveform.pulse25)
			presets.add_item("Pulse 10", Envelope.Waveform.pulse10)
			presets.add_item("Sine", Envelope.Waveform.sine)
			presets.add_item("Triangle", Envelope.Waveform.triangle)
			presets.add_item("Sawtooth", Envelope.Waveform.sawtooth)
			presets.add_item("Noise", Envelope.Waveform.noise)
			presets.add_item("Noise 1Bit", Envelope.Waveform.noise1bit)
			presets.add_item("Flat", Envelope.Waveform.flat)
			for node in get_children_in_group(self,"Control_Loop"):
				node.visible=false
			for node in get_children_in_group(self,"Control_Dimensions"):
				node.visible=false
		Role.volume:
			editor.envelope = preload("res://envelopes/envelope_volume.tres")
			presets.add_item("Custom", Envelope.Waveform.custom)
			presets.add_item("Flat", Envelope.Waveform.flat)
			presets.add_item("Falloff", Envelope.Waveform.falloff)
			presets.add_item("Linear Falloff", Envelope.Waveform.falloff_linear)
			presets.add_item("Triangle", Envelope.Waveform.triangle)
			presets.add_item("Noise", Envelope.Waveform.noise)
			presets.add_item("Hit/Sustain", Envelope.Waveform.hit_sustain)
		Role.pitch:
			editor.envelope = preload("res://envelopes/envelope_pitch.tres")
			presets.add_item("Custom", Envelope.Waveform.custom)
			presets.add_item("Flat", Envelope.Waveform.flat)
			presets.add_item("Arpeggio 12/-12", Envelope.Waveform.arpeggio)
			presets.add_item("Arpeggio 5/10", Envelope.Waveform.arpeggio_chord)
			presets.add_item("Tremolo", Envelope.Waveform.tremolo)
			presets.add_item("Sine", Envelope.Waveform.sine)
			presets.add_item("Triangle", Envelope.Waveform.triangle)
			presets.add_item("Slide", Envelope.Waveform.slide)
			presets.add_item("Noise", Envelope.Waveform.noise)
			presets.add_item("Bass", Envelope.Waveform.bass)
		Role.noise:
			editor.envelope = preload("res://envelopes/envelope_noise.tres")
			presets.add_item("Custom", Envelope.Waveform.custom)
			presets.add_item("Flat", Envelope.Waveform.flat)
		Role.morph:
			editor.envelope = preload("res://envelopes/envelope_morph.tres")
			presets.add_item("Custom", Envelope.Waveform.custom)
			presets.add_item("Flat", Envelope.Waveform.flat)

	editor.envelope.generate_preset(editor.envelope.shape, 32)
	editor.refresh(false)
	#Just relay the signal to outside nodes
	editor.connect( "envelope_changed", self, "_envelope_changed")

	#Connect all the UI elements
	presets.connect("item_selected", self, "_preset_selected" )
	min_value.connect("value_changed", self, "_change_min" )
	max_value.connect("value_changed", self, "_change_max" )
	length.connect("value_changed", self, "_change_length" )
	loop.connect("toggled", self, "_change_loop" )
	loop_in.connect("value_changed", self, "_change_loop_in" )
	loop_out.connect("value_changed", self, "_change_loop_out" )
	attack.connect("toggled", self, "_change_attack" )
	release.connect("toggled", self, "_change_release" )

	_refresh_controls()


static func get_children_in_group(node:Node, group:String)->Array	:
	var nodes := []
	for child in node.get_children():
		if child.is_in_group(group):
			nodes.append(child)
#			print(child.name," is in group ", group)
		for grandchild in get_children_in_group(child, group):
			nodes.append(grandchild)
	return nodes


func _refresh_controls():
	presets.selected = presets.get_item_index(editor.envelope.shape)
	min_value.value = editor.envelope.min_value
	max_value.value = editor.envelope.max_value
	loop.pressed = editor.envelope.loop
	loop_in.value = editor.envelope.loop_in
	loop_out.value = editor.envelope.loop_out
	attack.pressed = editor.envelope.attack
	release.pressed = editor.envelope.release
	#MAY cause loop out to be length-1. Moving it below here seems to have fixed the problem?
	length.value = editor.envelope.length()
	editor.refresh(false)


func _envelope_changed(env):
	if env.is_edited:
		presets.selected = presets.get_item_index(Envelope.Waveform.custom)
	emit_signal("envelope_changed", env)


func _preset_selected(index:int):
	editor.envelope.generate_preset( presets.get_item_id(index), editor.envelope.length() )
	length.value =editor.envelope.length()
	min_value.value = editor.envelope.min_value
	max_value.value = editor.envelope.max_value
	loop.pressed = editor.envelope.loop
	loop_in.value = editor.envelope.loop_in
	loop_out.value = editor.envelope.loop_out
	editor.refresh(false)
	presets.selected = index


func _change_min(value:float):
	editor.envelope.min_value = value
	editor.envelope.clip_min()
	editor.refresh(false)


func _change_max(value:float):
	editor.envelope.max_value = value
	editor.envelope.clip_max()
	editor.refresh(false)


func _change_length(value:float):
	editor.envelope.set_length(value)
	loop_in.max_value=value-1
	loop_out.max_value=value-1
	editor.refresh(false)


func _change_loop(value:bool):
	editor.envelope.loop=value
	loop_in.editable = value
	loop_out.editable = value
	release.disabled = not value
	attack.disabled = not value
	editor.refresh(false)


func _change_loop_in(value:int):
	editor.envelope.loop_in=value
	editor.refresh(false)


func _change_loop_out(value:int):
	editor.envelope.loop_out=value
	editor.refresh(false)


func _change_attack(state:bool):
	editor.envelope.attack=state
	editor.refresh(false)


func _change_release(state:bool):
	editor.envelope.release=state
	editor.refresh(false)


#func _on_RCC_Connections_instrument_selected(instrument):
#	match envelope_type:
#		Role.wave: editor.envelope = instrument.wave_envelope
#		Role.pitch: editor.envelope = instrument.pitch_envelope
#		Role.volume: editor.envelope = instrument.volume_envelope
#		Role.noise: editor.envelope = instrument.noise_envelope
#		Role.morph: editor.envelope = instrument.morph_envelope
#	editor.refresh(false)
#	_refresh_controls()


func _on_main_instrument_selected(instrument):
	if instrument:
		match envelope_type:
			Role.wave: editor.envelope = instrument.wave_envelope
			Role.pitch: editor.envelope = instrument.pitch_envelope
			Role.volume: editor.envelope = instrument.volume_envelope
			Role.noise: editor.envelope = instrument.noise_envelope
			Role.morph: editor.envelope = instrument.morph_envelope
		editor.refresh(false)
		_refresh_controls()
