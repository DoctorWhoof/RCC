class_name EnvelopePresets


static func generate(
		index:int,
		use_loop:bool,
		length:int,
		min_value:int,
		max_value:int,
		amplitude:float=-1,
		loop_in:int=-1,
		loop_out:int=-1
	) -> Envelope:

	var env := Envelope.new()
	env.min_value = min_value
	env.max_value = max_value
	env.is_edited=false
	env.shape=index

	if length>-1: env.set_length(length)
	if loop_in>-1: env.loop_in = loop_in
	if loop_out>-1: env.loop_out = loop_out
	if amplitude<0: amplitude=max_value
	var temp_data = env.data.duplicate()

	var loop_length:= env.data.size()
	if use_loop: loop_length = env.loop_out - env.loop_in + 1

	match index:
		Envelope.Waveform.square:
			temp_data = Generator.array_square(loop_length, -amplitude, amplitude, 0.5, true)
		Envelope.Waveform.pulse25:
			temp_data = Generator.array_square(loop_length, -amplitude, amplitude, 0.25, true)
		Envelope.Waveform.pulse10:
			temp_data = Generator.array_square(loop_length, -amplitude, amplitude, 0.1, true)
		Envelope.Waveform.triangle:
			temp_data = Generator.array_triangle(loop_length, -amplitude, amplitude, true)
		Envelope.Waveform.sawtooth:
			temp_data = Generator.array_sawtooth(loop_length, -amplitude, amplitude, true)
		Envelope.Waveform.flat:
			temp_data = Generator.array_flat(loop_length, env.default_value, true)
		Envelope.Waveform.sine:
			temp_data = Generator.array_sine(loop_length, -amplitude, amplitude, true)
		Envelope.Waveform.noise:
			temp_data = Generator.array_noise(loop_length, -amplitude, amplitude, true)
		Envelope.Waveform.falloff:
			temp_data = Generator.array_falloff(loop_length, amplitude,true)
		Envelope.Waveform.falloff_linear:
			temp_data = Generator.array_falloff_linear(loop_length, amplitude, true)
		Envelope.Waveform.noise1bit:
			temp_data = Generator.array_noise(loop_length, -amplitude, amplitude, true)
			for n in loop_length:
				if temp_data[n]>=0:
					temp_data[n]=amplitude
				else:
					temp_data[n]=-amplitude
		Envelope.Waveform.hit_sustain:
			replace_in_array(temp_data, 0, [10,12,15,12,10,9,8,7,6,5,4,3,2,1,0] )
			env.max_value = 15
			env.min_value = 0
			env.loop = false
			env.attack = true
			env.release = true
		Envelope.Waveform.arpeggio:
			replace_in_array(temp_data, env.loop_in, [0,12,-12])
			env.max_value = 12
			env.min_value = -12
			env.loop = true
			env.attack = false
			env.release = false
		Envelope.Waveform.arpeggio_chord:
			replace_in_array(temp_data, env.loop_in, [0,5,10])
			env.max_value = 12
			env.min_value = -12
			env.loop = true
			env.attack = false
			env.release = false
		Envelope.Waveform.tremolo:
			replace_in_array(temp_data, env.loop_in, [0,1,0,-1])
			env.max_value = 12
			env.min_value = -12
			env.loop = true
			env.attack = false
			env.release = false
		Envelope.Waveform.slide:
			replace_in_array(temp_data, 0, [0, -4, -8, -12, -16, -20, -24, -28, -32])
			env.max_value = 32
			env.min_value = -32
			env.loop = false
			env.attack = false
			env.release = false
		Envelope.Waveform.bass:
			replace_in_array(temp_data, 0, [12,0,-8,-16,-24,-32] )
			env.max_value = 32
			env.min_value = -32
			env.loop = false
			env.attack = false
			env.release = false
		Envelope.Waveform.chime1:
			env.set_length(64)
			loop_length = env.data.size()
			var square_len := loop_length/4
			var sine_len := loop_length/8
			var tri_len := loop_length
			env.loop_out = 63
			var square = Generator.array_square(square_len, -amplitude/8, amplitude/8, 0.5, true)
			var sine = Generator.array_sine(sine_len, -amplitude/6, amplitude/6, true)
			var tri = Generator.array_sine(tri_len, -amplitude/4, amplitude/4, true)
			for n in range(env.data.size()):
				env.data[n]=square[n%square_len] + sine[n%sine_len] + tri[n]
			return env
		Envelope.Waveform.chime2:
			env.set_length(64)
			loop_length = env.data.size()
			var square_len := loop_length/4
			var sine_len := loop_length
			var tri_len := loop_length/8
			env.loop_out = 63
			var square = Generator.array_square(square_len, -amplitude/4, amplitude/4, 0.5, true)
			var sine = Generator.array_sine(sine_len, -amplitude/2, amplitude/2, true)
			var tri = Generator.array_triangle(tri_len, -amplitude/4, amplitude/4, true)
			for n in range(env.data.size()):
				env.data[n]=square[n%square_len] + sine[n%sine_len] + tri[n%tri_len]
			return env
		Envelope.Waveform.chime3:
			env.set_length(64)
			loop_length = env.data.size()
			var len_a := loop_length
			var len_b := loop_length/4
			var len_c := loop_length/8
			var len_d := loop_length/16
			env.loop_out = 63
			var sine_a = Generator.array_sine(len_a, -amplitude/2, amplitude/2, true)
			var sine_b = Generator.array_sine(len_b, -amplitude/4, amplitude/4, true)
			var sine_c = Generator.array_square(len_c, -amplitude/8, amplitude/8, 0.25, true)
			var sine_d = Generator.array_sawtooth(len_d, -amplitude/8, amplitude/8, true)
			for n in range(env.data.size()):
				env.data[n]=sine_a[n%len_a] + sine_b[n%len_b] + sine_c[n%len_c] + sine_d[n%len_d]
			return env
		Envelope.Waveform.harmonic_sine:
			env.set_length(64)
			loop_length = env.data.size()
			var len_a := loop_length
			var len_b := loop_length/4
			var len_c := loop_length/8
			var len_d := loop_length/16
			env.loop_out = 63
			var sine_a = Generator.array_sine(len_a, -amplitude/4, amplitude/4, true)
			var sine_b = Generator.array_sine(len_b, -amplitude/4, amplitude/4, true)
			var sine_c = Generator.array_sine(len_c, -amplitude/8, amplitude/8, true)
			var sine_d = Generator.array_sine(len_d, -amplitude/12, amplitude/12, true)
			for n in range(env.data.size()):
				env.data[n]=sine_a[n%len_a] + sine_b[n%len_b] + sine_c[n%len_c] + sine_d[n%len_d]
			return env
		Envelope.Waveform.harmonic_triangle:
			env.set_length(32)
			loop_length = env.data.size()
			var len_a := loop_length
			var len_b := loop_length/4
			var len_c := loop_length/8
			var len_d := loop_length/16
			env.loop_out = 31
			var sine_a = Generator.array_triangle(len_a, -amplitude/2, amplitude/2, true)
			var sine_b = Generator.array_triangle(len_b, -amplitude/4, amplitude/4, true)
			var sine_c = Generator.array_triangle(len_c, -amplitude/8, amplitude/8, true)
			var sine_d = Generator.array_triangle(len_d, -amplitude/12, amplitude/12, true)
			for n in range(env.data.size()):
				env.data[n]=sine_a[n%len_a] + sine_b[n%len_b] + sine_c[n%len_c] + sine_d[n%len_d]
			return env
		Envelope.Waveform.harmonic_saw:
			env.set_length(64)
			loop_length = env.data.size()
			var len_a := loop_length
			var len_b := loop_length/4
			var len_c := loop_length/8
			var len_d := loop_length/16
			env.loop_out = 63
			var sine_a = Generator.array_sawtooth(len_a, -amplitude/2, amplitude/2, true)
			var sine_b = Generator.array_sawtooth(len_b, -amplitude/4, amplitude/4, true)
			var sine_c = Generator.array_sawtooth(len_c, -amplitude/8, amplitude/8, true)
			var sine_d = Generator.array_sawtooth(len_d, -amplitude/12, amplitude/12, true)
			for n in range(env.data.size()):
				env.data[n]=sine_a[n%len_a] + sine_b[n%len_b] + sine_c[n%len_c] + sine_d[n%len_d]
			return env
		Envelope.Waveform.harmonic_square:
			env.set_length(32)
			loop_length = env.data.size()
			var len_a := loop_length
			var len_b := loop_length/2
			var len_c := loop_length/4
			var len_d := loop_length/16
			env.loop_out = 31
			var sine_a = Generator.array_square(len_a, -amplitude, amplitude, 0.5, true)
			var sine_b = Generator.array_square(len_b, -amplitude, amplitude, 0.5, true)
			var sine_c = Generator.array_square(len_c, -amplitude, amplitude, 0.5, true)
			var sine_d = Generator.array_square(len_d, -amplitude, amplitude, 0.5, true)
			for n in range(env.data.size()):
				env.data[n]=(sine_a[n%len_a] + sine_b[n%len_b] + sine_c[n%len_c] + sine_d[n%len_d])/4.0
			return env
		_:
			temp_data = Generator.array_flat(loop_length, env.default_value, true)

	if use_loop:
		for n in range(env.loop_in, env.loop_out+1):
			if n < env.data.size():
				env.data[n]=temp_data[n-env.loop_in]
			else:
				break
	else:
		env.data = temp_data

	return env


static func replace_in_array(arr:Array, pos:int, new_data:Array):
	var index := 0
	while index < new_data.size() and pos < arr.size():
		arr[pos]=new_data[index]
		index+=1
		pos+=1


static func array_blur(arr:Array, radius:int, mix:float, quantize:=true) ->Array:
	var new_arr:= []
	var rad := abs(radius)
	for n in range(arr.size()):
		var value :float= 0.0
		if radius != 0:
			var width :int= (rad*2)+1
			var i:int=-rad
			while i <= rad:
				value += arr[ (n+i) % arr.size() ]
				i += 1
			var blurred :float= value/width
			if quantize: blurred = round(blurred)
			if mix < 1.0:
				blurred = lerp(arr[n], blurred, mix)
			new_arr.append(blurred)
		else:
			value = arr[n]
			new_arr.append(value)
	return new_arr


static func array_multiply(arr:Array, amount:float, quantize:=true) ->Array:
	var new_arr:= []
	for n in range(arr.size()):
		var value:float = arr[n] * amount
		if quantize: value = round(value)
		new_arr.append(value)
	return new_arr


static func array_noise(arr:Array, amount:float, quantize:=true) ->Array:
	var new_arr:= []
	for n in range(arr.size()):
		var noise :float = rand_range(-amount, amount)
		var value:float = arr[n] + noise
		if quantize: value = round(value)
		new_arr.append(value)
	return new_arr


static func array_add_sine(arr:Array, sine_len:int, amplitude:float, quantize:=true) ->Array:
	var new_arr:= []
	var sine_a = Generator.array_sine(sine_len, -amplitude, amplitude, true)
	print("sine amp:", amplitude, " len:", sine_len)
	for n in range(arr.size()):
		var value:float = sine_a[n%sine_len]
		var combined:float = arr[n]+value
		if quantize: combined = round(combined)
		new_arr.append(combined)
	return new_arr


static func array_clamp(arr:Array, min_value:float, max_value:float) -> Array:
	var new_arr := []
	for a in arr:
		new_arr.append(clamp(a, min_value, max_value))
	return new_arr


