extends OptionButton


func _ready():
	add_item("Baked Envelopes", ExportStyle.Baked)
	add_item("Wavetable + Envelopes", ExportStyle.Minimal)
	selected = 0
