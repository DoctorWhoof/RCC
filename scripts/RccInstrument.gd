extends Resource
class_name RccInstrument

export var name:= "Default Instrument"
export var pan:= 0.0
export var volume:= 1.0
export var transpose := 0

#export var loop := true
export var length := 8
export var loop_in := 0
export var loop_out := 7
export var sustain := true

export var scheme := ExportStyle.Minimal
export var mix_rate := 44100
export var half_precision := false
export var range_min := 2
export var range_max := 6
export var sample_interval := 3
export var multi_sample := true
export var psg_volume := false

export var vibrato := false
export var vibrato_fade := false
export var vibrato_depth := 8
export var vibrato_rate := 8

export var analog_attenuation := 0.996
export var analog_noise := 0.01
export var analog_spike := 0.05
export var analog_spike_attenuation := 0.85
export var filter_size := 5

export(Dictionary)var mappings

export(Resource) var wave_envelope
export(Resource) var pitch_envelope
export(Resource) var note_envelope
export(Resource) var volume_envelope
export(Resource) var noise_envelope
export(Resource) var morph_envelope



#internal playback state, managed by rcc_track
var column := 0.0
var previous_column := -1.0
var previous_value:int = -1
var previous_normalized_value:float = 1.0
var out_level:= 1.0
var current_wavelength := 1.0
var current_sample := 0
#var position:= -1

#Sfz export looping helpers
var commit_in_offset:int=0
var commit_out_offset:int=0
var loop_in_offset:int=0
var loop_out_offset:int=0

var envelopes := []

func _init():
	wave_envelope = Envelope.new()
	pitch_envelope = Envelope.new()
	note_envelope = Envelope.new()
	volume_envelope = Envelope.new()
	noise_envelope = Envelope.new()
	morph_envelope = Envelope.new()

	wave_envelope.name = "Envelope Wave"
	pitch_envelope.name = "Envelope Pitch"
	note_envelope.name = "Envelope Note"
	volume_envelope.name = "Envelope Volume"
	noise_envelope.name = "Envelope Noise"
	morph_envelope.name = "Envelope Morph"


func reset():
	column = -1
	out_level = 1.0
	previous_value = -1
	current_sample = 0
	current_wavelength = 0
	commit_in_offset = 0
	commit_out_offset = 0
	loop_in_offset = 0
	loop_out_offset = 0
	wave_envelope.reset()
	volume_envelope.reset()
	pitch_envelope.reset()
	note_envelope.reset()
	noise_envelope.reset()
	morph_envelope.reset()


func tick_forward():
	volume_envelope.tick_forward()
	pitch_envelope.tick_forward()
	note_envelope.tick_forward()
	noise_envelope.tick_forward()
	morph_envelope.tick_forward()


func release():
	volume_envelope.is_releasing = true
	pitch_envelope.is_releasing = true
	note_envelope.is_releasing = true
	noise_envelope.is_releasing = true
	morph_envelope.is_releasing = true


func at_end()->bool:
	var completed = true
	if not volume_envelope.empty(): if not volume_envelope.is_done: completed = false
	if not pitch_envelope.empty(): if not pitch_envelope.is_done: completed = false
	if not note_envelope.empty(): if not note_envelope.is_done: completed = false
	if not noise_envelope.empty(): if not noise_envelope.is_done: completed = false
	if not morph_envelope.empty(): if not morph_envelope.is_done: completed = false
	return completed


func cut_off():
	volume_envelope.cut_off()
	pitch_envelope.cut_off()
	note_envelope.cut_off()
	noise_envelope.cut_off()
	morph_envelope.cut_off()


func commit_envelopes():
	volume_envelope.commit_value()
	pitch_envelope.commit_value()
	note_envelope.commit_value()
	noise_envelope.commit_value()
	morph_envelope.commit_value()


func set_envelope_size(new_length:int, new_loop_in:int, new_loop_out:int):
	length = new_length
	loop_in = new_loop_in
	loop_out = new_loop_out
	volume_envelope.set_envelope_size(length, loop_in, loop_out)
	pitch_envelope.set_envelope_size(length, loop_in, loop_out)
	note_envelope.set_envelope_size(length, loop_in, loop_out)
	noise_envelope.set_envelope_size(length, loop_in, loop_out)
	morph_envelope.set_envelope_size(length, loop_in, loop_out)


func effective_start()->int:
	var e := loop_in
	if not volume_envelope.empty(): e = min(e, volume_envelope.effective_start())
	if not pitch_envelope.empty(): e = min(e, pitch_envelope.effective_start())
	if not note_envelope.empty(): e = min(e, note_envelope.effective_start())
	if not noise_envelope.empty(): e = min(e, noise_envelope.effective_start())
	if not morph_envelope.empty(): e = min(e, morph_envelope.effective_start())
	return e


func effective_end()->int:
	var e := 0
	if not volume_envelope.empty(): e = max(e, volume_envelope.effective_end())
	if not pitch_envelope.empty(): e = max(e, pitch_envelope.effective_end())
	if not note_envelope.empty(): e = max(e, note_envelope.effective_end())
	if not noise_envelope.empty(): e = max(e, noise_envelope.effective_end())
	if not morph_envelope.empty(): e = max(e, morph_envelope.effective_end())
	return e+preroll_length()


func preroll_length()->int:
	if will_loop():
		#if it's a looping instrument, a single non-empty, non-looping envelope will cause pre-roll
		if not volume_envelope.loop: if not volume_envelope.empty(): return length
		if not pitch_envelope.loop: if not pitch_envelope.empty(): return length
		if not note_envelope.loop: if not note_envelope.empty(): return length
		if not noise_envelope.loop: if not noise_envelope.empty(): return length
		if not morph_envelope.loop: if not morph_envelope.empty(): return length
	return 0


func attack_length()->int:
	if volume_envelope.loop: if volume_envelope.attack: if not volume_envelope.empty(): return loop_in
	if pitch_envelope.loop: if pitch_envelope.attack: if not pitch_envelope.empty(): return loop_in
	if note_envelope.loop: if note_envelope.attack: if not note_envelope.empty(): return loop_in
	if noise_envelope.loop: if noise_envelope.attack: if not noise_envelope.empty(): return loop_in
	if morph_envelope.loop: if morph_envelope.attack: if not morph_envelope.empty(): return loop_in
	return 0



func release_length()->int:
	var rel_length:= length-loop_out-1
	if volume_envelope.loop: if volume_envelope.release: if not volume_envelope.empty(): return rel_length
	if pitch_envelope.loop: if pitch_envelope.release: if not pitch_envelope.empty(): return rel_length
	if note_envelope.loop: if note_envelope.release: if not note_envelope.empty(): return rel_length
	if noise_envelope.loop: if noise_envelope.release: if not noise_envelope.empty(): return rel_length
	if morph_envelope.loop: if morph_envelope.release: if not morph_envelope.empty(): return rel_length
	return 0


func loop_length()->int:
	if will_loop():
		return loop_out+1-loop_in
	return length


func effective_length()->int:
	return preroll_length()+attack_length()+loop_length()+release_length()


func effective_loop_in()->int:
	return preroll_length()+attack_length()


func effective_loop_out()->int:
	return preroll_length()+attack_length()+loop_length()-1


func will_loop()->bool:
	if volume_envelope.loop: if not volume_envelope.empty(): return true
	if pitch_envelope.loop: if not pitch_envelope.empty(): return true
	if note_envelope.loop: if not note_envelope.empty(): return true
	if noise_envelope.loop: if not noise_envelope.empty(): return true
	if morph_envelope.loop: if not morph_envelope.empty(): return true
	return false

#MATH

#func least_common_factor(a:int, b:int)->int:
#	if a>b:
#		return (a/gcd(a,b))*b
#	return (b/gcd(a,b))*a
#
#
#func gcd(a:int, b:int)->int:
#	if b==0:
#		return a
#	return gcd(b, a%b)
