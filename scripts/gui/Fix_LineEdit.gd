extends LineEdit

func _ready():
	connect("text_entered", self, "_on_text_entered")

func _on_text_entered(new_text):
	release_focus()

