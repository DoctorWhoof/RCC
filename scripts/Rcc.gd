#RCC - Retro Creative Chip
#Sound player that can play a musical note on a predetermined instrument.
#This is just the note playback engine, and a separate class is required to
#store the songs themselves.

extends Node
class_name Rcc, "res://textures/rcc.png"

export var max_tracks:= 1
export var latency:= 0.05    #In seconds
export(Resource) var project = Project.new()
var tracks:= []
#var mix_rate = 44100

func _enter_tree():
	for n in range(max_tracks):
		var track := RccTrack.new()
#		track.mix_rate = mix_rate
		track.latency = latency
		track.name = "track_"+str(n)
		tracks.append(track)
		add_child(track)


func _ready():
	for track in tracks:
		track.play()

