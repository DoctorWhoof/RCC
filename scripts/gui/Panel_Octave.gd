extends Control

var _timer:Timer
var _alpha:= 1.0
var _octave := 4
onready var _label := $Octave_Label

func _ready() -> void:
	_timer = Timer.new()
	_timer.name = "key_timer"
	_timer.wait_time = 0.05
	_timer.connect("timeout", self, "_on_timer_timeout")
	add_child(_timer)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("octave_down"):
		_change_octave(_octave-1)
	elif event.is_action_pressed("octave_up"):
		_change_octave(_octave+1)


func _change_octave(value:int):
	_octave=clamp(value,0,8)
	_label.text = "Octave:"+str(_octave)
	visible = true
	_alpha = 1.0
	modulate = Color(1.0, 1.0, 1.0, _alpha)
	_timer.start()


func _on_timer_timeout() -> void:
	_alpha -= 0.025
	modulate = Color(1.0, 1.0, 1.0, _alpha)
	update()
	if _alpha <= 0.0:
		_timer.stop()
		visible = false
