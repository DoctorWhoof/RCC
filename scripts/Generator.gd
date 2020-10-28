extends Node

static func rcc_fill_buffer(note:int, instrument:RccInstrument, mono:bool, frame_rate:int	)->Array:
	var length :int= instrument.mix_rate/frame_rate
	var increment := get_pitch_increment(instrument, note)
	var out_right := (instrument.pan+1.0)/2.0
	var out_left := (instrument.pan-1.0)/-2.0
	var normalized_value := instrument.previous_normalized_value
	var buffer := []
	var first_frame := true
	var value:int = instrument.previous_value
	var first_flip := false

	instrument.commit_envelopes()
	increment=get_pitch_increment(instrument, note)

	#This is the loop that fills in the array to be returned
	while length > 0:
		#Column advance and loop
		instrument.column += increment
		if instrument.column >= instrument.wave_envelope.length() or instrument.column < 0:
			instrument.column = fmod(instrument.column, instrument.wave_envelope.length())

		#Get value at the current column
		var tentative_value:int = instrument.wave_envelope.data[instrument.column]

		#Store precise loop points for SFZ export on waveform sign flip
		if sign(tentative_value)>sign(instrument.previous_value):
			#If this is the first flip in this tick, store how many samples it took to get here
			if not first_flip:
				instrument.commit_in_offset = instrument.current_sample
				instrument.current_wavelength = get_note_length(instrument,note)
				first_flip = true
			#Always acquire commit_out_offset, since I just want to keep the latest
			instrument.commit_out_offset = instrument.current_sample

		#New column detection. If column is the same, value gradually fades using analog_attentuation
		if int(instrument.column) != int(instrument.previous_column):
			#Commit values on column change
#			instrument.commit_envelopes()
#			increment=get_pitch_increment(instrument, note)
			value = tentative_value
			#New actual value on column means we calculate the final normalized value with volume envelope attenuation, etc.
			if value != instrument.previous_value:
				normalized_value = float(value)/float(instrument.wave_envelope.max_value)
				normalized_value *= instrument.volume_envelope.normalized()
				instrument.previous_value = value
				instrument.previous_normalized_value = normalized_value
				#Since column has changed, reset output attenuation
				if not first_frame: instrument.out_level = 1.0
			else:
				#No new value, keep attenuating out multiplier
				instrument.out_level *= instrument.analog_attenuation
			instrument.previous_column = instrument.column
		else:
			#Same column means same value, keep attenuating out multiplier
			instrument.out_level *= instrument.analog_attenuation

		#Apply out multiplier to value and apply instrument volume to it
		var level := (instrument.out_level * normalized_value) * instrument.volume

		#Noise Mix
		var noise_env :float =  instrument.noise_envelope.normalized()
		var noise_level:float = ((randf()*2.0)-1.0)*instrument.volume_envelope.normalized()
		level = (level*(1.0-noise_env))+(noise_level*noise_env)

		#Append array with mono or stereo data
		if mono:
			buffer.append(level)
		else:
			buffer.append(Vector2(level*out_left, level*out_right))

		#Counters
		length -= 1
		instrument.current_sample += 1
		first_frame = false
	return buffer


#Helper function for rcc_fill_buffer. It's used in two places in that function.
static func get_pitch_increment(instrument:RccInstrument, note:int)->int:
	var increment = instrument.wave_envelope.length()/get_note_length(instrument, note)
	return increment


#number of samples for current note
static func get_note_length(instrument:RccInstrument, note:int)->float:
	var pitch_offset:float = instrument.pitch_envelope.normalized()
	var note_offset:float = instrument.note_envelope.current() + (instrument.transpose*12) + pitch_offset
	var multiplier:= pow(1.059463094359, note+note_offset-1)
	var frequency:= (261.625565300 * multiplier) #C4 times multiplier
	return( (1.0/frequency)*instrument.mix_rate )


#For SCC wavetables, use array with size=32, amplitude from-16 to 16 (32 5bit samples)
static func wave_table(frequency:float, wave_amplitude:float, volume:float, waveform:Array)->AudioStreamSample:
	# prepare data variables
	var data = []
	var length := get_length(frequency, AudioServer.get_mix_rate())
	# generate data
	for i in range(length):
		var column := i/(length/waveform.size())
		var value = clamp( waveform[column], -wave_amplitude, wave_amplitude )*volume
#		print(str(column)+": "+str(value))
		data.append( value/wave_amplitude )
	# create sample from generated data
	var sample = AudioUtil.write_16bit_samples(data)
	prepare_sample(sample,length)
	data.clear()
	return sample


static func sine_wave(frequency:float, volume:float)->AudioStreamSample:
	# prepare data variables
	var data = []
	var length := get_length(frequency, AudioServer.get_mix_rate())
	# generate data
	for i in range(length):
		data.append( sin((i/length)*TAU)*volume )
	# create sample from generated data
	var sample = AudioUtil.write_16bit_samples(data)
	prepare_sample(sample,length)
	data.clear()
	return sample


#frequency in Hz, duty_cycle is 0.0 to 1.0
static func square_wave(frequency:float, volume:float, duty_cycle:float=0.5)->AudioStreamSample:
	# prepare data variables
	var data = []
	var length := get_length(frequency, AudioServer.get_mix_rate())
	# generate data
	for i in range(length):
		if i<(length*duty_cycle):
			data.append(-volume)
		else:
			data.append(volume)
	# create sample from generated data
	var sample = AudioUtil.write_16bit_samples(data)
	prepare_sample(sample,length)
	data.clear()
	return sample


static func noise_wave(length:int, volume:float)->AudioStreamSample:
	# prepare data variables
	var data = []
	# generate data
	for _i_ in range(length):
		data.append( rand_range(-volume,volume) )
	# create sample from generated data
	var sample = AudioUtil.write_16bit_samples(data)
	prepare_sample(sample,length)
	data.clear()
	return sample


static func triangle_wave(frequency:float, amplitude:float)->AudioStreamSample:
	var length := get_length(frequency, AudioServer.get_mix_rate())
	var data = array_triangle(length,-amplitude, amplitude)
	var sample = AudioUtil.write_16bit_samples(data)
	prepare_sample(sample,length)
	return sample


static func get_length(frequency:float, mix_rate:float)->float:
#	var samples_per_second = AudioServer.get_mix_rate()
	var length = (1.0/frequency)*mix_rate
	return ceil(length)


static func prepare_sample(sample:AudioStreamSample, length:int):
	sample.loop_mode = AudioStreamSample.LOOP_FORWARD
	sample.loop_begin = 0
	sample.loop_end = length
	sample.mix_rate = AudioServer.get_mix_rate()


static func array_square(length:float, min_value:float, max_value:float, duty_cycle:float, quantize:bool=false)->Array:
	var data = []
	data.resize(length)
	if quantize:
		min_value = round(min_value)
		max_value = round(max_value)
	for n in range(length):
		if n<(length*duty_cycle):
			data[n]=max_value
		else:
			data[n]=min_value
	return data


static func array_triangle(length:float, min_value:float, max_value:float, quantize:bool=false)->Array:
	var data = []
	data.resize(length)
	var p := length/2
	for n in range(length):
		var position:int = fmod(n+(length/4),length)
		var value := fit(
			((-1.0)/p)*(p-abs(n%(2*int(p))-p)),
			-1.0, 0.0,
			min_value, max_value
		)
		if quantize: value = round(value)
		data[position]=value
	return data


static func array_sawtooth(length:float, min_value:float, max_value:float, quantize:bool=false)->Array:
	var data = []
	data.resize(length)
	for n in range(length):
		var multiplier := 1.0-(n*(1.0/(length/2)))
		var value := clamp( max_value*multiplier, min_value, max_value )
		if quantize: value = round(value)
		data[n]=value
	return data


static func array_flat(length:float, amplitude:float, quantize:bool=false)->Array:
	var data = []
	data.resize(length)
	for n in range(length):
		if quantize: amplitude = round(amplitude)
		data[n]=amplitude
	return data


static func array_noise(length:float, min_value:float, max_value:float, quantize:bool=false)->Array:
	var data = []
	data.resize(length)
	for n in range(length):
		var value := rand_range(min_value,max_value)
		if quantize: value = round(value)
		data[n]=value
	return data


static func array_sine(length:float, min_value:float, max_value:float, quantize:bool=false)->Array:
	var data = []
	data.resize(length)
	for n in range(length):
		var value := sin((n/length)*TAU)*max_value
		value = clamp(value, min_value, max_value)
		if quantize: value = round(value)
		data[n]=value
	return data


static func array_falloff(length:float, amplitude:float, quantize:bool=false)->Array:
	var data = []
	data.resize(length)
	for n in range(length):
		var multiplier := 1.0/exp(n/(length*.3))
		var value := amplitude*multiplier
		if quantize: value = round(value)
		data[n]=value
	data[length-1]=0.0
	return data

static func array_falloff_linear(length:float, amplitude:float, quantize:bool=false)->Array:
	var data = []
	data.resize(length)
	for n in range(length):
		var multiplier := 1.0-(n*(1.0/length))
		var value := amplitude*multiplier
		if quantize: value = round(value)
		data[n]=value
	data[length-1]=0.0
	return data


static func fit(value:float, a_min:float, a_max:float, b_min:float, b_max:float)->float:
	if value < a_min: return b_min
	if value > a_max: return b_max
	var x := (value-a_min)/(a_max-a_min)
	return b_min + (x*(b_max-b_min))

