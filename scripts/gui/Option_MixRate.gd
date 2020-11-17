extends OptionButton


func _ready():
	add_item("22050 Hz", MixRate.Half)
	add_item("44100 Hz", MixRate.Full)
	add_item("88200 Hz", MixRate.Double)
	selected = 1
