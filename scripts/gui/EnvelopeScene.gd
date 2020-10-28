extends Control
class_name EnvelopeScene, "res://textures/envelope.png"

enum Role {
	wave, volume, pitch, note, noise, morph
}

signal envelope_changed(env)

export(Role) var envelope_type

onready var presets := $VBoxContainer/HBoxContainer_Tools/presets
onready var editor := $VBoxContainer/editor
onready var min_value := $VBoxContainer/HBoxContainer_Tools/min_SpinBox
onready var max_value := $VBoxContainer/HBoxContainer_Tools/max_SpinBox
onready var loop := $VBoxContainer/HBoxContainer_Tools/loop_Checkbox
onready var attack := $VBoxContainer/HBoxContainer_Tools/attack_Checkbox
onready var release := $VBoxContainer/HBoxContainer_Tools/release_Checkbox
onready var edit_menu := $VBoxContainer/HBoxContainer_Tools/Menu_Edit

func _ready():
	match envelope_type:
		Role.wave:
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
			presets.add_item("Custom", Envelope.Waveform.custom)
			presets.add_item("Flat", Envelope.Waveform.flat)
			presets.add_item("Falloff", Envelope.Waveform.falloff)
			presets.add_item("Linear Falloff", Envelope.Waveform.falloff_linear)
			presets.add_item("Triangle", Envelope.Waveform.triangle)
			presets.add_item("Noise", Envelope.Waveform.noise)
			presets.add_item("Hit/Sustain", Envelope.Waveform.hit_sustain)
		Role.pitch:
			presets.add_item("Custom", Envelope.Waveform.custom)
			presets.add_item("Flat", Envelope.Waveform.flat)
			presets.add_item("Sine", Envelope.Waveform.sine)
			presets.add_item("Triangle", Envelope.Waveform.triangle)
			presets.add_item("Sawtooth", Envelope.Waveform.sawtooth)
			presets.add_item("Slide", Envelope.Waveform.slide)
			presets.add_item("Noise", Envelope.Waveform.noise)
		Role.note:
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
			presets.add_item("Custom", Envelope.Waveform.custom)
			presets.add_item("Flat", Envelope.Waveform.flat)
		Role.morph:
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
	loop.connect("toggled", self, "_change_loop" )
	attack.connect("toggled", self, "_change_attack" )
	release.connect("toggled", self, "_change_release" )

	edit_menu.get_popup().add_item("Copy     ")
	edit_menu.get_popup().add_item("Paste    ")
	edit_menu.get_popup().connect("index_pressed", self, "_on_edit_menu_pressed")

	edit_menu.get_popup().set("custom_constants/vseparation", 12)

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
	attack.pressed = editor.envelope.attack
	release.pressed = editor.envelope.release
	editor.refresh(false)


func _envelope_changed(env):
	if env.is_edited:
		presets.selected = presets.get_item_index(Envelope.Waveform.custom)
	emit_signal("envelope_changed", env)


func _preset_selected(index:int):
	editor.envelope.generate_preset( presets.get_item_id(index), editor.envelope.length() )
	min_value.value = editor.envelope.min_value
	max_value.value = editor.envelope.max_value
	loop.pressed = editor.envelope.loop
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


func _change_loop(value:bool):
	editor.envelope.loop=value
	release.disabled = not value
	attack.disabled = not value
	editor.refresh(false)


func _change_attack(state:bool):
	editor.envelope.attack=state
	editor.refresh(false)


func _change_release(state:bool):
	editor.envelope.release=state
	editor.refresh(false)


func _on_main_instrument_selected(instrument):
	if instrument:
		match envelope_type:
			Role.wave: editor.envelope = instrument.wave_envelope
			Role.pitch: editor.envelope = instrument.pitch_envelope
			Role.note: editor.envelope = instrument.note_envelope
			Role.volume: editor.envelope = instrument.volume_envelope
			Role.noise: editor.envelope = instrument.noise_envelope
			Role.morph: editor.envelope = instrument.morph_envelope
		_refresh_controls()
#		editor.refresh(false)


func _on_edit_menu_pressed(index:int):
	match index:
		0:	#Copy
			Clipboard.envelope = editor.envelope.duplicate()
			editor.refresh(false)
			_refresh_controls()
		1:	#Paste
			if Clipboard.envelope:
				editor.envelope = Clipboard.envelope.duplicate()
				editor.refresh(false)
				_refresh_controls()


