extends TabContainer


func _ready() -> void:
	var children = get_children()
	for n in range(children.size()):
		if children[n].hidden:
			children[n].queue_free()
#			set_tab_disabled(n, true)
#			set_tab_title(n, "")
