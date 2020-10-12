extends Node

export var record := false
var recordingeffectmaster:AudioEffect

# Called when the node enters the scene tree for the first time.
func _ready():
	if record:
		AudioServer.add_bus_effect(0, AudioEffectRecord.new())
		recordingeffectmaster = AudioServer.get_bus_effect(0, 0)
		recordingeffectmaster.set_recording_active(true)

func _physics_process(delta):
	if record:
		if OS.get_ticks_msec()>5000:
			recordingeffectmaster.set_recording_active(false)  #to stop recording
			var final_recording = recordingeffectmaster.get_recording()  #to grab recording
			final_recording.save_to_wav("user://test.wav")  #I would set the path with a filedialog
			print("finished recording wav")
			get_tree().quit()

