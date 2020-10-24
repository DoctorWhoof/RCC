extends ScrollContainer

export var scroll_time := 1.0
export var time_step := 0.02

onready var _scrollbar := get_h_scrollbar()
onready var _piano := $Piano_Keys

var _current_scroll := 0
var _target_scroll := 0
var _alpha := 0.0
var _timer:Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.name = "key_timer"
	_timer.wait_time = 0.02
	_timer.connect("timeout", self, "_on_timer_timeout")
	add_child(_timer)
	yield(get_tree(), "idle_frame")
	_scrollbar.value = rect_size.x/2


func _on_Piano_note_played(note, octave) -> void:
	var octaves:int = (_piano.last_octave-_piano.first_octave)+1
	var total_keys:float = octaves*12
	var current_key:float = note + (octave*12)
	var key_position:float = current_key/total_keys
	var key_width:int= _piano.rect_min_size.x / total_keys
	var visible_keys:int = (rect_size.x/_piano.rect_min_size.x) * total_keys
	var min_key:int = (_scrollbar.value/rect_size.x)*(total_keys-visible_keys)
	var max_key:int = min_key+visible_keys

#	print("scroll: ", _scrollbar.value)
#	print("current: ",current_key, "; min:", min_key, "; max:", max_key)

	if current_key < min_key or current_key > max_key:
		_current_scroll = _scrollbar.value
		_target_scroll = _scrollbar.max_value * key_position
		_timer.start()
		_alpha = 0.0

#		_scrollbar.value = _scrollbar.max_value * key_position


func _on_timer_timeout():
	_scrollbar.value = lerp(_current_scroll, _target_scroll, _alpha)
	_alpha += ((1.0/scroll_time)*time_step)
	if _alpha >= 1.0:
		_timer.stop()
		print("stop")
