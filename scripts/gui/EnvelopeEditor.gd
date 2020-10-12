extends Control
class_name EnvelopeEditor, "res://textures/editor.png"

signal envelope_changed(env)

export(Resource) var envelope
export(DynamicFont) var font

export var fg_color := Color.white
export var bg_color := Color(0.35,0.35,0.35)
export var loop_color := Color.red
export var light_grid_color := Color(0,0,0,0.1)
export var dark_grid_color := Color(0,0,0,0.25)

export var display_grid := true
#export var grid_step := Vector2(8, 64)
export var display_sub_grid := true
#export var sub_grid_step := Vector2(1, 4)

var pressed := false
var last_pos :Vector2
var height :float
var height_margin := 0.1	#fraction of the height
var rect_margin:Vector2
var axis:float
var y_margin_offset:float
#var _grid_step :Vector2
#var _sub_grid_step :Vector2

func _ready():
	#Generate envelope if necessary
	if not envelope: envelope = Envelope.new()
	#delaying a frame before refresh fixed some out-of-sync data being displayed
	yield(get_tree(), "idle_frame")
	#Update view, send "changed" signal
	refresh(false)


func replace_envelope(index:int, length:int, min_value:int, max_value:int):
	envelope.generate_preset(index, length, min_value, max_value)
	refresh(false)


func _gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		pressed = event.pressed
		if pressed:
			if Input.is_key_pressed(KEY_SHIFT):
				#Line drawing with shift
				var pos := mouse_to_waveform(event.position.x, event.position.y)
				var inc:= 1
				var total :float = abs(pos.x-last_pos.x)
				var current :float = 0.0
				if pos.x < last_pos.x: inc=-1
				for x in range(last_pos.x, pos.x, inc):
					var weight :float= current/total
					var y :float= lerp(pos.y, last_pos.y, 1-weight)
					envelope.data[x]=int(y)
					current+=1
				refresh(true)
				emit_signal("envelope_changed",envelope)
		else:
			last_pos = mouse_to_waveform(event.position.x, event.position.y)
			refresh(true)
			emit_signal("envelope_changed",envelope)
	elif event is InputEventMouseMotion:
		if pressed:
			mouse_to_waveform(event.position.x, event.position.y)
			refresh(true)
			emit_signal("envelope_changed",envelope)


func refresh(is_custom_edit:bool):
	if not envelope.data.empty():
		if is_custom_edit:
			envelope.shape=Envelope.Waveform.custom
		envelope.is_edited = is_custom_edit
		update()


func mouse_to_waveform(mouse_x:int,mouse_y:int)->Vector2:
	var width :int= envelope.length()
	var column :int = (mouse_x/rect_size.x)*width
	var row :int = ceil( (1-((mouse_y-y_margin_offset)/rect_margin.y) )*height )+envelope.min_value

	var vec:= Vector2(
		clamp(column,0,envelope.length()-1),
		clamp(row,envelope.min_value, envelope.max_value )
	)
	envelope.data[vec.x]=vec.y
	return vec


func _draw():
	height = abs(envelope.max_value)+abs(envelope.min_value)
	if height == 0: height=2
	rect_margin = Vector2(rect_size.x, rect_size.y*(1.0-height_margin))
#	if height>0:
	axis = abs(envelope.max_value) / height
#	else:
#		axis = 1.0
	y_margin_offset = rect_size.y*(height_margin/2)
	#BG
	var topleft := Vector2(1.0,y_margin_offset)
	var bottomright := Vector2(rect_size.x-1,rect_size.y-y_margin_offset)
#	var bottomright := Vector2(0.0,1.0+y_margin_offset)
	draw_rect(Rect2(0,0, rect_size.x-1, rect_size.y-1), bg_color)
	var y_center :float= (rect_margin.y*axis) + y_margin_offset
	var x_mult :float= rect_margin.x/envelope.length()
	var y_mult :float= -(rect_margin.y/height)

	#Bars
	var skip:= false
	for x in range(envelope.length()):
		var pos := Vector2(x*x_mult, y_center)
		draw_rect(Rect2(pos.x, pos.y, x_mult, envelope.data[x]*y_mult), fg_color)
		#X Subgrid
		if envelope.length() < 120:
			draw_line(Vector2(pos.x, topleft.y), Vector2(pos.x, rect_margin.y+topleft.y), light_grid_color)
			draw_string(font, Vector2(pos.x+4, bottomright.y+font.size), str(envelope.data[x]),fg_color)
		elif envelope.length() < 240:
			skip = not skip
			if skip:
				draw_line(Vector2(pos.x, topleft.y), Vector2(pos.x, rect_margin.y+topleft.y), light_grid_color)

	#Y Subgrid
#	var inc_y := rect_margin.y*_sub_grid_step.y
#	var y:= inc_y
#	while y < rect_margin.y:
#		draw_line(Vector2(0, y), Vector2(rect_margin.x,y), light_grid_color)
#		y+=inc_y

	#Grid
#	y = 0
#	inc_y = rect_margin.y*_grid_step.y
#	while y < rect_margin.y:
#		draw_line(Vector2(0, y), Vector2(rect_margin.x,y), dark_grid_color)
#		y+=inc_y
#	var inc_x := rect_margin.x*_grid_step.x
#	var x:= inc_x
#	while x < rect_margin.x:
#		draw_line(Vector2(x, 0), Vector2(x, rect_margin.y), dark_grid_color)
#		x+=inc_x

	#Axis
	draw_line(Vector2(0, y_center), Vector2(rect_margin.x, y_center), fg_color)

	#Vertical limits
	draw_line(Vector2(0, topleft.y), Vector2(rect_margin.x, topleft.y), dark_grid_color)
	draw_line(Vector2(0, bottomright.y), Vector2(rect_margin.x, bottomright.y), dark_grid_color)

	#Grey out attack and release areas when not used
	if envelope.loop:
		var column_width:float = rect_size.x/envelope.length()
		var greyout := Color(0, 0, 0, 0.5)
		if not envelope.attack:
			draw_rect(Rect2(0,0, column_width*envelope.loop_in, rect_size.y-1), greyout)
		if not envelope.release:
			draw_rect(
				Rect2((envelope.loop_out+1)*column_width, 0, column_width*(envelope.length()-envelope.loop_out+1), rect_size.y-1),
				greyout
			)

	#Loop points
	if envelope.loop:
		draw_line(Vector2((envelope.loop_in*x_mult)+1, 0), Vector2((envelope.loop_in*x_mult)+1, rect_size.y), loop_color)
		draw_line(Vector2(((envelope.loop_out+1)*x_mult)-1, 0), Vector2(((envelope.loop_out+1)*x_mult)-1, rect_size.y), loop_color)



