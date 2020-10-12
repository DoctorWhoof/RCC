class_name Export

static func to_sfz(instrument:RccInstrument):
	var samples_path := instrument.name + "_samples/"
	var dir := Directory.new()
	dir.open("user://")
	dir.make_dir(samples_path)

	#Remove previously exported wav files
	if dir.open("user://"+instrument.name) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".wav"):
				dir.remove(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

	#Prepare instrument variables
	var file := File.new()

	var filename := instrument.name + ".sfz"
	var text := "//Sfz test export from RCC\n\n"
	var loop_mode = "one_shot"
	if instrument.will_loop(): loop_mode = "loop_sustain"

	#Prepare some variables for the sfz regions
	var regions_text := ""
	var lo_key := 0
	var hi_key := 128
	var interval := instrument.sample_interval
	var inc:int= ceil(interval/2.0)

	#First we export the wave files:
	if instrument.multi_sample:
		for oct in range(instrument.range_min, instrument.range_max+1):
			for n in range(0, 12, interval):
				var note := ((oct-4)*12)+n
				hi_key = note+48+inc-1
				if n > 11-interval and oct==instrument.range_max: hi_key = 128
				regions_text += sfz_region(	instrument,
											to_wave(instrument,"user://"+samples_path, note),
											note, lo_key, hi_key
										)
				lo_key = hi_key+1
	else:
		regions_text += sfz_region(	instrument,
									to_wave(instrument, "user://"+samples_path, 0),
									0, 0, 128
								)

	#Then we generate the text for the SFZ file
	file.open("user://"+filename, File.WRITE)
	text+="\n<control>\n"
	text+="default_path="+samples_path+"\n"

	#SFZ Group
	text+="\n<group>\n"
	text+="pan="+str(int(instrument.pan*50))+"\n"
	text+="volume="+str((1-instrument.volume)*-50)+"\n"    #TO DO: Use db scale (non linear). This is a quick hack.
	text+="loop_mode="+loop_mode+"\n"
	text+="ampeg_release=5\n"
	text+="ampeg_attack=0.001\n"

	#SFZ Regions
	text+=regions_text

	#Output file
	file.store_line(text)
	file.close()
	print(text)


static func to_wave(instrument:RccInstrument, path:String, note:int=0, append_note_number:bool=true)->String:
	# Prepare data
	var data = []
	var samples_per_tick :int= instrument.mix_rate/60
	instrument.reset()

	#main "fill buffer" loop
	var n := instrument.effective_start()
	var end := instrument.effective_end()
	if end > instrument.length: end = instrument.length
	while n <= end:
		var buffer := Generator.rcc_fill_buffer(note, instrument, true, 60)
		for frame in buffer: data.append(frame*0.9)
		if n == instrument.loop_in:
			instrument.loop_in_offset = instrument.commit_in_offset
		if n == instrument.loop_out:
			instrument.release()
			instrument.loop_out_offset = instrument.commit_out_offset
		instrument.tick_forward()
		n += 1

	# Create sample from generated data
	var baked_wave
	match instrument.half_precision:
		true: baked_wave = AudioUtil.write_8bit_samples(data)
		false: baked_wave = AudioUtil.write_16bit_samples(data)
	baked_wave.loop_mode = AudioStreamSample.LOOP_FORWARD
	baked_wave.loop_begin = 0
	baked_wave.loop_end = instrument.length * samples_per_tick
	baked_wave.mix_rate = instrument.mix_rate

	# Export!
#	var path := instrument.name + "/"
	var filename := instrument.name
	if append_note_number:
		filename +="_" + str(note+48) + ".wav"
	else:
		filename += ".wav"
	var exporter := AudioStreamPlayer.new()
	exporter.stream = baked_wave
	exporter.stream.save_to_wav(path+filename)
	exporter.queue_free()
	return filename


static func sfz_region(instrument:RccInstrument, wave_filename:String, note:int, lo_key:int, hi_key:int)->String:

	var samples_per_tick := instrument.mix_rate/60
	var loop_in := ((instrument.loop_in-instrument.effective_start())*samples_per_tick)+instrument.loop_in_offset
	var loop_out := ((instrument.loop_out-instrument.effective_start())*samples_per_tick)+instrument.loop_out_offset-1
	var length := 1+instrument.effective_end()-instrument.effective_start()

#	#ALT METHOD, doesn't work well for loops with volume or pitch envelopes
#	var wavelength := Generator.get_note_length(instrument,note)
#	var loop_out := loop_in + wavelength

	var text :="\n<region>\n"
	text +="sample="+wave_filename+"\n"
	text +="lokey="+str(lo_key)+" hikey="+str(hi_key)+"\n"
	text +="pitch_keycenter="+str(note+48)+"\n"
	text +="loop_start="+str(loop_in)+"\n"
	text +="loop_end="+str(loop_out)+"\n"
	text +="offset=0\n"
	text +="end="+str(length*samples_per_tick)+"\n"
#	print("effective in: ", instrument.effective_start())
#	print("effective out: ",instrument.effective_end())
#	print("effective length: ",length)
#	print("loop in: ", loop_in)
#	print("loop out: ",loop_out)
#	print("end: ",length*samples_per_tick)
	return text



#static func note_name(note:int)->String:
#	var oct :int= floor(note/12.0)
#	note = note%12
#	var text:=""
#	match note:
#		0: text = "C"
#		1: text = "C#"
#		2: text = "D"
#		3: text = "D#"
#		4: text = "E"
#		5: text = "F"
#		6: text = "F#"
#		7: text = "G"
#		8: text = "G#"
#		9: text = "A"
#		10: text = "A#"
#		11: text = "B"
#	return text+str(oct)