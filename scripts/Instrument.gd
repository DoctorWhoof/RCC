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

export var mix_rate := 44100
export var half_precision := false
export var range_min := 2
export var range_max := 6
export var sample_interval := 3
export var multi_sample := true

export var analog_attenuation := 0.998
export var analog_noise := 0.001
export var analog_spike := 0.05
export var analog_spike_attenuation := 0.85
export var filter_size := 2

export(Resource) var wave_envelope
export(Resource) var pitch_envelope
export(Resource) var volume_envelope
export(Resource) var noise_envelope
export(Resource) var morph_envelope

#internal playback state, managed by rcc_track
var column := 0.0
var previous_column := -1.0
var previous_value:int = -1
var previous_normalized_value:float = 1.0
var out_level:= 1.0
#var position:= -1

#Sfz export looping helpers
var commit_in_offset:int=0
var commit_out_offset:int=0
var loop_in_offset:int=0
var loop_out_offset:int=0

func _init():
	wave_envelope = Envelope.new()
	pitch_envelope = Envelope.new()
	volume_envelope = Envelope.new()
	noise_envelope = Envelope.new()
	morph_envelope = Envelope.new()
	wave_envelope.name = "Envelope Wave"
	pitch_envelope.name = "Envelope Pitch"
	volume_envelope.name = "Envelope Volume"
	noise_envelope.name = "Envelope Noise"
	morph_envelope.name = "Envelope Morph"


func reset():
	column = 0
#	previous_column = -1.0
#	previous_value = -1
	wave_envelope.reset()
	volume_envelope.reset()
	pitch_envelope.reset()
	noise_envelope.reset()
	morph_envelope.reset()


func tick_forward():
	volume_envelope.tick_forward()
	pitch_envelope.tick_forward()
	noise_envelope.tick_forward()
	morph_envelope.tick_forward()


func release():
	volume_envelope.is_releasing = true
	pitch_envelope.is_releasing = true
	noise_envelope.is_releasing = true
	morph_envelope.is_releasing = true


func at_end()->bool:
	var completed:bool= (
		volume_envelope.is_done and
		pitch_envelope.is_done and
		noise_envelope.is_done and
		morph_envelope.is_done
	)
	return completed


func cut_off():
	volume_envelope.cut_off()
	pitch_envelope.cut_off()
	noise_envelope.cut_off()
	morph_envelope.cut_off()


func commit_envelopes():
	volume_envelope.commit_value()
	pitch_envelope.commit_value()
	noise_envelope.commit_value()
	morph_envelope.commit_value()


func set_envelope_size(new_length:int, new_loop_in:int, new_loop_out:int):
	length = new_length
	loop_in = new_loop_in
	loop_out = new_loop_out
	volume_envelope.set_envelope_size(length, loop_in, loop_out)
	pitch_envelope.set_envelope_size(length, loop_in, loop_out)
	noise_envelope.set_envelope_size(length, loop_in, loop_out)
	morph_envelope.set_envelope_size(length, loop_in, loop_out)


func effective_start()->int:
	var e := loop_in
	if not volume_envelope.empty(): e = min(e, volume_envelope.effective_start())
	if not pitch_envelope.empty(): e = min(e, pitch_envelope.effective_start())
	if not noise_envelope.empty(): e = min(e, noise_envelope.effective_start())
	if not morph_envelope.empty(): e = min(e, morph_envelope.effective_start())
	return e


func effective_end()->int:
	var e := 0
	if not volume_envelope.empty(): e = max(e, volume_envelope.effective_end())
	if not pitch_envelope.empty(): e = max(e, pitch_envelope.effective_end())
	if not noise_envelope.empty(): e = max(e, noise_envelope.effective_end())
	if not morph_envelope.empty(): e = max(e, morph_envelope.effective_end())
	return e


func will_loop()->bool:
	var result = pitch_envelope.loop or volume_envelope.loop or noise_envelope.loop or morph_envelope.loop
	return result

#MATH

func least_common_factor(a:int, b:int)->int:
	if a>b:
		return (a/gcd(a,b))*b
	return (b/gcd(a,b))*a


func gcd(a:int, b:int)->int:
	if b==0:
		return a
	return gcd(b, a%b)
