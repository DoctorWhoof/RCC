extends Control
class_name RccPiano, "res://textures/piano.png"

signal note_played(note, octave)
signal note_stopped()	#May need to specify the "channel" (track)

export var first_octave := 0
export var last_octave := 7

export var margin := 2
export var black_key_ratio := 0.5

var _octave_rects := []		#one rect for each octave
var _white_rects := {}			#index:octave, value:array containing the key rects
var _black_rects := {}			#index:octave, value:array containing the key rects
var _pressed := false
var _octave := 4

var _safe_rect:Rect2
var _current_rect :Rect2
var _current_note:= -1
#var _current_event := ""
func _ready():
	connect("resized", self, "_on_resized")

	var margins := margin*2
	var octaves := (last_octave - first_octave)+1
	var octsize := Vector2( rect_size.x/octaves, rect_size.y )
	var keysize := Vector2( octsize.x / 7, octsize.y )
	var offset := keysize.x/2

	_safe_rect = Rect2(margin, margin, rect_size.x-margins, rect_size.y-margins)

	for o in range(octaves):
		#Add octave rect
		var rect := Rect2(o*octsize.x, 1, octsize.x-1, octsize.y-2)
		_octave_rects.append( rect )
		#Add key rects using octave as index for each octave's keys
		_white_rects[o]=[]
		_black_rects[o]=[]
		for k in range(7):
			_white_rects[o].append(
				Rect2( rect.position.x+(k*keysize.x)+margin, margin, keysize.x-margins, keysize.y-margins )
			)
			match k:
				0,1,3,4,5:
					_black_rects[o].append(
						Rect2(_white_rects[o][k].position.x+offset, margin, keysize.x-margins, keysize.y*black_key_ratio)
					)


func _draw():
	for n in range(_octave_rects.size()):
		for r in _white_rects[n]:
			draw_rect(r, Color.white )
		for r in _black_rects[n]:
			draw_rect(r, Color.black )
	if _current_note > -1:
		draw_rect(_current_rect, Color.red, false )


func _gui_input(event:InputEvent):
#	var octave_width := rect_size.x/_octave_rects.size()
	var oct :int = (event.position.x/rect_size.x)*_octave_rects.size()

	if event is InputEventMouseButton:
		_pressed = event.pressed
		if _pressed:
			play_note_mouse(event.position, oct)
		else:
			stop_note()
	elif event is InputEventMouseMotion:
		if not _safe_rect.has_point(event.position):
			stop_note()
		if _pressed:
			if not _current_rect.has_point(event.position):
				play_note_mouse(event.position, oct)
				if _current_note < 0:
					stop_note()


func stop_note():
	if _current_note > -1:
		emit_signal("note_stopped")
		_current_note = -1
		update()


func play_note_mouse(mouse:Vector2, oct:int):
	if   _black_rects[oct][0].has_point(mouse):
		_current_note=1
		_current_rect = _black_rects[oct][0]
	elif _black_rects[oct][1].has_point(mouse):
		_current_note=3
		_current_rect = _black_rects[oct][1]
	elif _black_rects[oct][2].has_point(mouse):
		_current_note=6
		_current_rect = _black_rects[oct][2]
	elif _black_rects[oct][3].has_point(mouse):
		_current_note=8
		_current_rect = _black_rects[oct][3]
	elif _black_rects[oct][4].has_point(mouse):
		_current_note=10
		_current_rect = _black_rects[oct][4]
	elif _white_rects[oct][0].has_point(mouse):
		_current_note=0
		_current_rect = _white_rects[oct][0]
	elif _white_rects[oct][1].has_point(mouse):
		_current_note=2
		_current_rect = _white_rects[oct][1]
	elif _white_rects[oct][2].has_point(mouse):
		_current_note=4
		_current_rect = _white_rects[oct][2]
	elif _white_rects[oct][3].has_point(mouse):
		_current_note=5
		_current_rect = _white_rects[oct][3]
	elif _white_rects[oct][4].has_point(mouse):
		_current_note=7
		_current_rect = _white_rects[oct][4]
	elif _white_rects[oct][5].has_point(mouse):
		_current_note=9
		_current_rect = _white_rects[oct][5]
	elif _white_rects[oct][6].has_point(mouse):
		_current_note=11
		_current_rect = _white_rects[oct][6]
	else:
		_current_note=-1

	if _current_note > -1:
		emit_signal("note_played",_current_note,oct)
		update()


func _input(event:InputEvent):
	if event.is_action_type():
		if event.is_action_pressed("octave_down"):
			_octave -= 1
			if _octave < 0: _octave = 0
		elif event.is_action_pressed("octave_up"):
			_octave += 1
			if _octave > 8: _octave = 8

		if event.is_action("note_c"):
			_play_keyboard(0, event)
		elif event.is_action("note_c#"):
			_play_keyboard(1, event)
		elif event.is_action("note_d"):
			_play_keyboard(2, event)
		elif event.is_action("note_d#"):
			_play_keyboard(3, event)
		elif event.is_action("note_e"):
			_play_keyboard(4, event)
		elif event.is_action("note_f"):
			_play_keyboard(5, event)
		elif event.is_action("note_f#"):
			_play_keyboard(6, event)
		elif event.is_action("note_g"):
			_play_keyboard(7, event)
		elif event.is_action("note_g#"):
			_play_keyboard(8, event)
		elif event.is_action("note_a"):
			_play_keyboard(9, event)
		elif event.is_action("note_a#"):
			_play_keyboard(10, event)
		elif event.is_action("note_b"):
			_play_keyboard(11, event)


func _play_keyboard(note:int, event:InputEventKey):
	if event.pressed:
		if note != _current_note:
			emit_signal("note_played",note,_octave)
			_current_note = note
			update()
	else:
		if note == _current_note:
			stop_note()


func _on_resized():
	for n in range(_octave_rects.size()):
		for r in range(_white_rects[n].size()):
			_white_rects[n][r].size.y = rect_size.y
		for r in range(_black_rects[n].size()):
			_black_rects[n][r].size.y = rect_size.y/2
