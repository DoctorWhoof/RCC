extends AudioStreamPlayer
class_name RccTrack

export var latency := 0.5

var instrument:RccInstrument
var playback: AudioStreamPlayback
var note:int						#Current note's numerical value
#var is_playing:bool


func _ready():
	volume_db = -4.0
	stream = AudioStreamGenerator.new()
	stream.buffer_length = latency
	reset_mix_rate(true)
	stop()


func play(from_position:float=0.0):
	.play(from_position)
	set_physics_process(true)


func stop():
	.stop()
	set_physics_process(false)
	stop_note()


#Note value is from 1 to 12
func play_note(note_value:int, octave:int):
	note = (note_value+(octave*12))-48
#	is_playing = true
	instrument.reset()


func stop_note():
	if instrument:
		instrument.release()
#	is_playing = false


func _physics_process(_delta):
	if instrument:
		var tick_rate := 60
		var samples_per_tick := instrument.mix_rate/tick_rate
		var buffer:Array
		if playback.get_frames_available() > samples_per_tick:
			if not instrument.at_end():
				#Instrument being played, get waveform
				buffer = Generator.rcc_fill_buffer(note, instrument, false, tick_rate)
			else:
				#Silence
				buffer = []
				for i in range(instrument.mix_rate/tick_rate):
					buffer.append(Vector2())
			playback.push_buffer(PoolVector2Array(buffer))
		instrument.tick_forward()


func reset_mix_rate(first_run:=false ):
	if stream and instrument:
		stop()
		stream.mix_rate = instrument.mix_rate
		playback = get_stream_playback()
		playback.clear_buffer()
		if not first_run: play()


