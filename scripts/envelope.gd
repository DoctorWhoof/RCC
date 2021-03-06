extends Resource
class_name Envelope

enum Waveform {
	custom, square, pulse25, pulse10, triangle, sawtooth, sine, noise, noise1bit, flat,
	falloff, falloff_linear, echo, hit_sustain,
	arpeggio, arpeggio_chord, tremolo, slide, bass,
	chime1, chime2, chime3,
	harmonic_sine, harmonic_triangle, harmonic_saw, harmonic_square
}

export(Waveform) var shape := Waveform.flat
export var name := "envelope"

export var default_length := 32
export var default_value := 0.0
export var max_value := 16.0
export var min_value := 0.0

export var attack := true
export var release := true
export var loop := true
export var loop_in := 0
export var loop_out := 32

export var data := []
export var is_edited := false

var value := 0.0
var next := 0.0
var extrapolated_value := 0.0
var position := 0
var is_releasing := false
var is_done := false


func _init():
	data = [0.0]
	reset()


func reset():
	is_done = false
	is_releasing = false
	if attack:
		position = 0
	else:
		position = loop_in
	if not data.empty():
		value = data[position]
		next = data[position]
	else:
		value = 1.0
		next = 1.0
	extrapolated_value = data[data.size()-1]


func cut_off():
	extrapolated_value=0.0
	next = 0.0
	value = 0.0
	position = data.size()
	is_releasing = true
	is_done = true


func _to_string()->String:
	var text := name+"\n"
	text += "current shape:"+str(shape)+"\n"
	text += "loop:"+str(loop)+"; "
	text += "loop_in:"+str(loop_in)+"; "
	text += "loop_out:"+str(loop_out)+"\n"
	return text


func empty()->bool:
	var has_data:= false
	for c in data:
		if c!=0.0:
			has_data=true
	return not has_data


func tick_forward():
	if not attack:
		if position < loop_in:
			position = loop_in

	position+=1

	if loop:
		if position > loop_out:
			if release:
				if is_releasing:
					pass
				else:
					position = loop_in
			else:
				if position >= loop_out: is_done = true
				position = loop_in

	if position >= data.size():
		is_done = true
		position = data.size()
		next = extrapolated_value
		return
	else:
		next = data[position]


#Needs to be called to "apply" the next value to the current. Used by
#RCC tracks to prevent clicking when applying the envelope
func commit_value():
	value = next


func current()->float:
	return value


#returns the currently commited value
func normalized(linear:=false, power:=2.0)->float:
	var amplitude:float = max_value
	if max_value == 0: amplitude = abs(min_value)
	var result:= value/amplitude
	if not linear:
		result = pow(result, power)
	return result


#Returns the immediate value, ignoring the need to commit the value
func normalized_sample(pos:int)->float:
	return data[pos]/max_value


func length()->int:
	return data.size()


func effective_length()->int:
	var effective_in:= 0
	var effective_out:= data.size()
	if loop:
		if not attack: effective_in=loop_in
		if not release: effective_out=loop_out+1
	return effective_out-effective_in


func effective_start()->int:
	var n := 0
	if loop:
		if attack:
			return 0
		else:
			n = loop_in
	else:
		return 0
	return n


func effective_end()->int:
	if loop:
		if release: return length()-1
	else:
		return length()-1
	return loop_out


func set_length(size:int):
	data.resize(size)
	for n in range(data.size()):
		if not data[n]:
			data[n]=0.0
	loop_in = clamp(loop_in, 0, size-1)
	loop_out = clamp(loop_out, 0, size-1)


func set_envelope_size(new_length:int, new_loop_in:int, new_loop_out:int):
	set_length(new_length)
	loop_in = new_loop_in
	loop_out = new_loop_out
#	print(name,", ",length(), ", ",loop_in, ", ", loop_out)


func clip_min():
	if not data.empty():
		for n in range(data.size()):
			if data[n]<min_value: data[n]=min_value


func clip_max():
	if not data.empty():
		for n in range(data.size()):
			if data[n]>max_value: data[n]=max_value



