extends Node

# Root screen, must be a StackBasedMenuScreen
export var root_screen_node_path: NodePath

onready var loading_screen = preload("res://ui/LoadingScreen.tscn")

var _loading_screen_instance: Node = null

# Screen or scene stack
var _screens := []


func _ready() -> void:
	_loading_screen_instance = loading_screen.instance()
	
	var root_screen = get_node(root_screen_node_path)
	var _error = root_screen.connect("navigate", self, "_on_StackBasedMenu_navigate")
	
	_screens.push_back(root_screen)


func _notify_scene_on_add_to_tree(data: Object) -> void:
	assert(!_screens.empty())
	
	(_screens.back() as StackBasedMenuScreen).on_add_to_tree(data)


func _notify_scene_on_load() -> void:
	assert(!_screens.empty())
	
	(_screens.back() as StackBasedMenuScreen).on_load()


func _push_back_new_scene(scene_path: String) -> void:
	remove_child(_screens.back())
	
	var scene = load(scene_path)
	var instanced_scene: StackBasedMenuScreen = scene.instance()
	
	add_child(instanced_scene)
	_screens.push_back(instanced_scene)
	
	var _error = instanced_scene.connect("navigate", self, "_on_StackBasedMenu_navigate")
	_error = instanced_scene.connect("go_back", self, "_on_StackBasedMenu_go_back")


func _on_StackBasedMenu_navigate(scene_path: String, data: Object) -> void:
	yield(_fade_in(), "completed")
	
	_push_back_new_scene(scene_path)
	
	_notify_scene_on_add_to_tree(data)
	
	yield(_fade_out(), "completed")
	
	_notify_scene_on_load()


func _on_StackBasedMenu_go_back() -> void:
	yield(_fade_in(), "completed")
	
	var current_scene: Node = _screens.pop_back()
	
	remove_child(current_scene)
	current_scene.queue_free()
	
	var previous_scene: StackBasedMenuScreen = _screens.back()
	add_child(previous_scene)
	
	previous_scene.on_add_to_tree(null)
	
	yield(_fade_out(), "completed")
	
	_notify_scene_on_load()


func _fade_in() -> void:
	add_child(_loading_screen_instance)
	
	_loading_screen_instance.play_loading_animation()
	
	yield(_loading_screen_instance, "fade_in_finished")


func _fade_out() -> void:
	_loading_screen_instance.fade_out()
	
	yield(_loading_screen_instance, "fade_out_finished")
	
	remove_child(_loading_screen_instance)


func _on_StackBasedMenu_tree_exiting():
	if not _loading_screen_instance.is_inside_tree():
		_loading_screen_instance.free()
	
	for screen in _screens:
		if not screen.is_inside_tree():
			screen.free()
