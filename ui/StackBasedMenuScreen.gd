extends Control

class_name StackBasedMenuScreen


signal navigate(scene_path)
signal go_back()


func change_scene(scene_path: String) -> void:
	if Loader.change_scene(scene_path) == OK:
		_remove_focus(self)
	else:
		printerr("Failed to change scene to %s" % scene_path)


# Emits navigate signal and removes focus in all buttons
func navigate(scene_path: String) -> void:
	emit_signal("navigate", scene_path)
	
	_remove_focus(self)


func go_back() -> void:
	emit_signal("go_back")
	
	_remove_focus(self)


# Callback executed when the loading animation finished playing and the
# scene should allow input now. Restores focus in all buttons
func on_load() -> void:
	print("%s loaded" % [name])
	
	_restore_focus(self)


# Disables focus from all the buttons in the scene, recursively
func _remove_focus(node: Node) -> void:
	for child in node.get_children():
		_remove_focus(child)
	
	if node is Button:
		node.focus_mode = Control.FOCUS_NONE


# Reenables focus in all the buttons in the scene, recursively
func _restore_focus(node: Node) -> void:
	for child in node.get_children():
		_restore_focus(child)
	
	if node is Button:
		node.focus_mode = Control.FOCUS_ALL
