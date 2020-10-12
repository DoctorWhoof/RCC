extends Control


func _ready():
	var screen_size := OS.get_screen_size()
	var window_size := OS.get_window_size()
	OS.set_window_position(Vector2((screen_size.x*0.5)-(window_size.x*0.5), 0))

