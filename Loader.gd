extends Node

var loader: ResourceInteractiveLoader = null

var wait_frames: int = 1

var time_max_ms: int = 100

var current_scene: Node = null

# Data passed from one scene to another
var data: Reference = null

var loading_screen_instance: Node = null

# Flag set to true when the loading screen is active, so that it not
# instanced again in that case.
var is_loading: bool = false

# Some nodes try to change scenes in their _ready() method. When that happens,
# the fade out animation should only play once, not every time the scene is changed.
# This flag is reset when the loader is started, and is set before adding the new scene
# to the tree, and checked again afterwards. It it is false, it means the new scene
# changed scenes in its  _ready() method and a new loader was created. If it
# remains true then the new scene did not change scenes in its _ready() method,
# and we can fade out.
var can_fade_out: bool = false

onready var loading_screen = preload("res://ui/LoadingScreen.tscn")

# Emitted when change_scene() is called and a new scene is going to be loaded
signal scene_changed()


func _ready() -> void:
	var root: Node = get_tree().get_root()
	
	current_scene = root.get_child(root.get_child_count() - 1)
	
	set_process(false)


func _process(_delta: float) -> void:
	if loader == null:
		set_process(false)
	else:
		var current_time_ms : = Time.get_ticks_msec()
		
		if wait_frames > 0:
			wait_frames -= 1
			
			return
		
		while Time.get_ticks_msec() < current_time_ms + time_max_ms:
			var error = loader.poll()
			
			if error == ERR_FILE_EOF:
				var resource = loader.get_resource()
				loader = null
				
				_set_new_scene(resource)
				
				break
			elif error == OK:
				# TODO: Update progress
				
				pass
			else:
				printerr("Error loading scene")
				
				loader = null
				
				break


# https://www.youtube.com/watch?v=5aV_GSAE1kM
# https://dicode1q.blogspot.com/2022/10/background-loading-in-godot-dicode.html
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html#example
func change_scene(path: String, _data = null) -> int:
	if path == "":
		return ERR_CANT_CREATE
	
	if loader != null:
		push_warning("Loader is busy")
		
		return ERR_ALREADY_IN_USE
	
	loader = ResourceLoader.load_interactive(path)
	
	if loader == null:
		printerr("Couldn't load interactive loader for scene %s" % path)
		
		return ERR_CANT_CREATE
	else:
		data = _data
		
		if is_loading:
			_start_loader()
		else:
			call_deferred("_play_loading_animation")
		
		emit_signal("scene_changed")
		
		return OK


func _play_loading_animation() -> void:
	is_loading = true
	
	loading_screen_instance = loading_screen.instance()
	
	get_tree().get_root().add_child(loading_screen_instance)
	
	var _error = loading_screen_instance.connect("fade_in_finished", self, "_on_LoadingScreen_fade_in_finished")
	
	loading_screen_instance.play_loading_animation()


func _set_new_scene(resource: Resource) -> void:
	can_fade_out = true
	
	current_scene = resource.instance()
	
	if current_scene.has_method("on_instance"):
		current_scene.on_instance(data)
		
		data = null
	
	get_tree().get_root().add_child(current_scene)
	
	# This flag can be set to false if the current_scene wants to change
	# scenes in its _ready() method (when it is added to the tree) and 
	# _start_loader() is called
	# This is so that the fade out animation is only played once, for the last
	# scene changed to
	if can_fade_out:
		var _error = loading_screen_instance.connect("fade_out_finished", self, "_on_LoadingScreen_fade_out_finished")
		
		loading_screen_instance.fade_out()


func _start_loader() -> void:
	# Wait until sound effects and such have finished playing
	# TODO: current_scene.cleanup()
	current_scene.queue_free()
	
	wait_frames = 1
	
	set_process(true)
	
	can_fade_out = false


func _on_LoadingScreen_fade_in_finished() -> void:
	_start_loader()


func _on_LoadingScreen_fade_out_finished() -> void:
	is_loading = false
	
	loading_screen_instance.queue_free()
	
	# Enable buttons, input
	if current_scene.has_method("on_fade_out_finished"):
		current_scene.on_fade_out_finished()
