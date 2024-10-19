class_name StackBasedMenuScreen
extends Control


signal navigate(scene_path, data)
signal go_back()


func change_scene(scene_path: String, data: Object = null) -> void:
	if Loader.change_scene(scene_path, data) == OK:
		_remove_focus(self)
	else:
		printerr("Failed to change scene to %s" % scene_path)


# Emits navigate signal and removes focus in all buttons
# Passes the given data to the new scene
func navigate(scene_path: String, data: Object = null) -> void:
	emit_signal("navigate", scene_path, data)
	
	_remove_focus(self)


func go_back() -> void:
	emit_signal("go_back")
	
	_remove_focus(self)


func on_add_to_tree(_data: Object) -> void:
	pass


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
