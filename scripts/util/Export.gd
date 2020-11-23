class_name Export

static func to_sfz(
		inst:RccInstrument,
		dir_path:String,
		mix_rate:int,
		index:int,
		override_precision:int,
		space_char:String,
		remove_samples:bool,
		digit_count:int,
		export_style:int,
		file_numbers:int
	):

	var file := File.new()
	var filename := inst.name

	match file_numbers:
		FileNumbers.Prepend:
			filename = str(index).pad_zeros(digit_count)+" "+filename
		FileNumbers.Append:
			filename = filename+" "+str(index).pad_zeros(digit_count)
	filename = filename.replace(" ", space_char)

	var samples_path := filename + "_samples"
	var dir := Directory.new()

	filename += ".sfz"

	dir.open(dir_path)
	dir.make_dir(samples_path)

	#Remove previously exported wav files
	if remove_samples:
		if dir.open(dir_path+"/"+samples_path) == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".wav"):
					dir.remove(file_name)
				file_name = dir.get_next()
			print("Clean up: Removed previously exported samples on ", samples_path)
		else:
			print("Clean up: No previously exported samples found.")

	#Prepare inst variables
	var text := "//Sfz test export from RCC\n\n"
#	var loop_mode = "one_shot"
#	if inst.will_loop(): loop_mode = "loop_sustain"

	#Prepare some variables for the sfz regions
	var regions_text := ""
	var lo_key := 0
	var hi_key := 128
	var interval := inst.sample_interval
	var inc:int= ceil(interval/2.0)

	#First we export the wave files:
	if export_style == ExportStyle.Minimal:
		regions_text += sfz_region(
									inst,
									mix_rate,
									to_wave_minimal(
										inst,
										dir_path+"/"+samples_path,
										mix_rate,
										override_precision,
										space_char
									),
									0, 0, 128,
									export_style
								)
	else:
		if inst.multi_sample:
			for oct in range(inst.range_min, inst.range_max+1):
				for n in range(0, 12, interval):
					var note := ((oct-4)*12)+n
					hi_key = note+48+inc-1
					if n > 11-interval and oct==inst.range_max: hi_key = 128
					regions_text += sfz_region(
												inst,
												mix_rate,
												to_wave_baked(
													inst,
													dir_path+"/"+samples_path,
													mix_rate,
													note,
													true,
													override_precision,
													space_char,
													digit_count
													),
												note, lo_key, hi_key,
												export_style
											)
					lo_key = hi_key+1
		else:
			regions_text += sfz_region(
										inst,
										mix_rate,
										to_wave_baked(
											inst,
											dir_path+"/"+samples_path,
											mix_rate,
											0,
											true,
											override_precision,
											space_char,
											digit_count
										),
										0, 0, 128,
										export_style
									)

	#Then we generate the text for the SFZ file
	file.open(dir_path+"/"+filename, File.WRITE)
	text+="\n<control>\n"
	text+="default_path="+samples_path+"/\n"

	#SFZ Group
	text+="\n<group>\n"
	text+="group="+str(abs(index))+"\n"
	text+="off_by="+str(abs(index))+"\n"
	text+="pan="+str(int(inst.pan*50))+"\n"
	text+="volume="+str((1-inst.volume)*-50)+"\n"    #TO DO: Use db scale (non linear). This is a quick hack.

#	if export_style == ExportStyle.Baked: text+="loop_mode="+loop_mode+"\n"

	text+="ampeg_release=5\n"
	text+="ampeg_attack=0\n"
	text+="polyphony=1\n"
	text+="note_polyphony=1\n"

	var loop_mode = "no_loop"
	match export_style:
		ExportStyle.Baked:
			if inst.will_loop(): loop_mode = "loop_sustain"
		ExportStyle.Minimal:
			loop_mode = "loop_continuous"
	text+="loop_mode="+loop_mode+"\n"

	if inst.vibrato:
		var frequency_multiplier := 1.1
		var vibrato_depth:float = ((inst.vibrato_depth*0.667)/inst.pitch_envelope.max_value)*200
		var vibrato_freq:float = 1.0/((inst.loop_out-inst.loop_in+1.0)*0.01667/frequency_multiplier)
		text+="pitchlfo_fade=0.1\n"
		text+="pitchlfo_depth="+str(vibrato_depth)+"\n"
		text+="pitchlfo_freq="+str(vibrato_freq)+"\n"

	if export_style == ExportStyle.Minimal: text+=sfz_envelopes(inst)

	#SFZ Regions
	text+=regions_text

	#Output file
	file.store_line(text)
	file.close()


static func sfz_region(
		inst:RccInstrument,
		mixrate:int,
		wave_filename:String,
		note:int,
		lo_key:int,
		hi_key:int,
		export_style:int
	)->String:

	var samples_per_tick := mixrate/60
	var loop_in := inst.loop_in_offset
	var loop_out := inst.loop_out_offset-1
#	var loop_out := loop_in + inst.current_wavelength - 1     #ALT METHOD
	var length := (1+inst.effective_end()-inst.effective_start())*samples_per_tick

	#Fix for very low pitch notes, which causes the flip detection to fail and loop in and loop out to be the same
	if loop_out<=loop_in:
		print(inst.name,": Required low pitch fix")
		loop_out=loop_in+inst.current_wavelength-1

	var text :="\n<region>\n"
	text +="sample="+wave_filename+"\n"
	text +="lokey="+str(lo_key)+" hikey="+str(hi_key)+"\n"

	if export_style == ExportStyle.Minimal:
		text +="pitch_keycenter="+str(note+49-(inst.transpose*12))+"\n"
#		text+="loop_mode=loop_continuous\n"
#		text+="loop_type=forward\n"
	else:
		text +="pitch_keycenter="+str(note+48)+"\n"
#		var loop_mode = "one_shot"
#		if inst.will_loop(): loop_mode = "loop_sustain"
#		text+="loop_mode="+loop_mode+"\n"

	if inst.will_loop():
		text +="loop_start="+str(loop_in)+"\n"
		text +="loop_end="+str(loop_out)+"\n"
	return text


static func sfz_envelopes( inst:RccInstrument )->String:
	var volume := envelope_text(inst, inst.volume_envelope, "eg01")
	var volume_text := "\n"

	if volume["point_count"]:
		volume_text += "eg01_amplitude=100\n"
		volume_text += "eg01_points="+str(volume["point_count"])+"\n"
		volume_text += volume["points"]
		if inst.volume_envelope.loop:
			volume_text += "eg01_sustain="+str(volume["loop_out"])+"\n"

	var pitch := envelope_text(inst, inst.note_envelope, "eg03")
	var pitch_text := "\n"

	if pitch["point_count"]:
		pitch_text += "eg03_pitch="+str(inst.note_envelope.max_value*50)+"\n"
		pitch_text += "eg03_points="+str(pitch["point_count"])+"\n"
		pitch_text += pitch["points"]
		if inst.note_envelope.loop:
			pitch_text += "eg03_sustain="+str(pitch["loop_out"])+"\n"

	return volume_text + pitch_text


static func envelope_text(inst:RccInstrument, env:Envelope, eg_text:String, tick_duration:=0.01667)->Dictionary:
	var text := "\n"
	var last := -99.0
	var last_tick := 0
	var loop_in := -1
	var loop_out := -1
	var points := []
	var points_text := ""

	inst.reset()
	var n := inst.effective_start()
	var end := inst.effective_end()
	var ticks_since_last:= 0
	while n <= end:
		if not env.empty():
			inst.commit_envelopes()
			ticks_since_last += 1

			var value:float = env.normalized(true)
			var time := tick_duration * ticks_since_last
			var previous_point = points.back()

			var is_loop_in := false
			var is_loop_out := false

			if n == env.loop_in:
				is_loop_in = true
				loop_in = points.size()

			if n == env.loop_out:
				is_loop_out = true
				loop_out = points.size()

			if n == 0: time = 0
			if n == 1: value = points[0][1]
			if (value != last) or (is_loop_in) or (is_loop_out) or (n==1):
				var slope:float = atan2(value-last,time)
				if n>0 and not is_loop_out:
					if is_similar(previous_point[2], slope, 0.001):
						time += points.back()[0]
						points.pop_back()
				points.append([time, value, slope])
				ticks_since_last = 0
			last_tick = n
			last = value

		if n == inst.effective_loop_in():
			inst.loop_in_offset = inst.commit_in_offset
		if n == inst.effective_loop_out():
			inst.release()
			inst.loop_out_offset = inst.commit_out_offset
		inst.tick_forward()
		n += 1

	for i in points.size():
		points_text += eg_text+"_time"+str(i)+"="+str(points[i][0])+"\n"
		points_text += eg_text+"_level"+str(i)+"="+str(points[i][1])+"\n"

	var dict := {
		"text":text,
		"point_count":points.size(),
		"points":points_text,
		"loop_in":loop_in,
		"loop_out":loop_out
	}
	return dict


static func is_similar(a:float, b:float, threshold:float)->bool:
	var diff:float = abs(abs(a)-abs(b))
	return diff < abs(threshold)


static func to_wave_baked(
		inst:RccInstrument,
		path:String,
		mix_rate:int,
		note:int,
		append_note_number:bool,
		override_precision:int,
		space_char:String,
		digit_count:int
	)->String:

	var data = []
	var samples_per_tick :int= mix_rate/60
	inst.reset()

	#main "fill buffer" loop
	var n := inst.effective_start()
	var end := inst.effective_end()
	while n <= end:
		var buffer := Generator.rcc_fill_buffer(note, inst, mix_rate, true, 60)
		for frame in buffer: data.append(frame*0.9)
		if n == inst.effective_loop_in():
			inst.loop_in_offset = inst.commit_in_offset
		if n == inst.effective_loop_out():
			inst.release()
			inst.loop_out_offset = inst.commit_out_offset
		inst.tick_forward()
		n += 1

	return export_wave_file(path, data, inst, note, mix_rate, override_precision, space_char, append_note_number)


static func to_wave_minimal(
		inst:RccInstrument,
		path:String,
		mix_rate:int,
		override_precision:int,
		space_char:String
	)->String:

	var data = []
	var samples_per_tick :int= mix_rate/60
	inst.reset()
	var sample_length:float = ( (1.0/261.625565300)*mix_rate )
	var column_length:float = sample_length/inst.wave_envelope.length()
	var out_level := 1.0
	var previous_value= 0

	for n in range(0,sample_length):
		var column:int = n/column_length
		var value:float = inst.wave_envelope.normalized_sample(column)*0.9

		if value != previous_value:
			out_level = 1.0

		var noise := ((randf()-0.5)*inst.analog_noise ) * out_level

		var final := (value*out_level)+noise

		if inst.psg_volume:
			if final < 0: final *= 0.05

		data.append(final)
		previous_value = value
		out_level *= inst.analog_attenuation

	inst.loop_in_offset = 0
	inst.loop_out_offset = sample_length

	var smooth_data = smooth_array(data)
	return export_wave_file(path, smooth_data, inst, 0, mix_rate, override_precision, space_char, false)


static func export_wave_file(
		path:String,
		data:Array,
		inst:RccInstrument,
		note:int,
		mix_rate:int,
		precision:int,
		space_char:String,
		append_note_number:bool
	)->String:

	# Create sample from generated data
	var baked_wave
	if precision<0:
		match inst.half_precision:
			true: baked_wave = AudioUtil.write_8bit_samples(data)
			false: baked_wave = AudioUtil.write_16bit_samples(data)
	else:
		match precision:
			0: baked_wave = AudioUtil.write_16bit_samples(data)
			1: baked_wave = AudioUtil.write_8bit_samples(data)
	baked_wave.mix_rate = mix_rate

	# Export!
	var filename := inst.name
	filename = filename.replace(" ", space_char)
	if append_note_number:
		filename +="_" + str(note+48) + ".wav"
	else:
		filename += ".wav"

	var exporter := AudioStreamPlayer.new()
	exporter.stream = baked_wave
	exporter.stream.save_to_wav(path+"/"+filename)
	exporter.queue_free()
	return filename


static func note_name(note:int)->String:
	note=note+48
	var oct :int= floor(note/12.0)
	note = note%12
	var text:=""
	match note:
		0: text = "C"
		1: text = "C#"
		2: text = "D"
		3: text = "D#"
		4: text = "E"
		5: text = "F"
		6: text = "F#"
		7: text = "G"
		8: text = "G#"
		9: text = "A"
		10: text = "A#"
		11: text = "B"
	return text+str(oct)


static func smooth_array(arr:Array)->Array:
	var new_arr := []
	for n in range(arr.size()):
		var p0:float = arr[(n-2)%arr.size()]*0.015
		var p1:float = arr[(n-1)%arr.size()]*0.05
		var p2:float = arr[n]*1.87
		var p3:float = arr[(n+1)%arr.size()]*0.05
		var p4:float = arr[(n+2)%arr.size()]*0.015
		new_arr.append((p0+p1+p2+p3+p4)/2.0)
	return new_arr
