extends Node

# Root screen, must be a StackBasedMenuScreen
export var root_screen_node_path: NodePath

onready var loading_screen = preload("res://ui/LoadingScreen.tscn")

var loading_screen_instance: Node = null

# Screen or scene stack
var screens := []


func _ready() -> void:
	loading_screen_instance = loading_screen.instance()
	
	var root_screen = get_node(root_screen_node_path)
	var _error = root_screen.connect("navigate", self, "_on_StackBasedMenu_navigate")
	
	screens.push_back(root_screen)


func _notify_scene_on_add_to_tree(data: Object) -> void:
	assert(!screens.empty())
	
	(screens.back() as StackBasedMenuScreen).on_add_to_tree(data)


func _notify_scene_on_load() -> void:
	assert(!screens.empty())
	
	(screens.back() as StackBasedMenuScreen).on_load()


func _push_back_new_scene(scene_path: String) -> void:
	remove_child(screens.back())
	
	var scene = load(scene_path)
	var instanced_scene: StackBasedMenuScreen = scene.instance()
	
	add_child(instanced_scene)
	screens.push_back(instanced_scene)
	
	var _error = instanced_scene.connect("navigate", self, "_on_StackBasedMenu_navigate")
	_error = instanced_scene.connect("go_back", self, "_on_StackBasedMenu_go_back")


func _on_StackBasedMenu_navigate(scene_path: String, data: Object) -> void:
	yield(_fade_in(), "completed")
	
	_push_back_new_scene(scene_path)
	
	_notify_scene_on_add_to_tree(data)
	
	yield(_fade_out(), "completed")
	
	_notify_scene_on_load()


# TODO: Also add data when going back?
func _on_StackBasedMenu_go_back() -> void:
	yield(_fade_in(), "completed")
	
	var current_scene: Node = screens.pop_back()
	
	remove_child(current_scene)
	current_scene.queue_free()
	
	var previous_scene: StackBasedMenuScreen = screens.back()
	add_child(previous_scene)
	
	previous_scene.on_add_to_tree(null)
	
	yield(_fade_out(), "completed")
	
	_notify_scene_on_load()


func _fade_in() -> void:
	add_child(loading_screen_instance)
	
	loading_screen_instance.play_loading_animation()
	
	yield(loading_screen_instance, "fade_in_finished")


func _fade_out() -> void:
	loading_screen_instance.fade_out()
	
	yield(loading_screen_instance, "fade_out_finished")
	
	remove_child(loading_screen_instance)


func _on_StackBasedMenu_tree_exiting():
	if not loading_screen_instance.is_inside_tree():
		loading_screen_instance.queue_free()
