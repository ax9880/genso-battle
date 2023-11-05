extends Node

var loader: ResourceInteractiveLoader = null

var wait_frames: int = 1

var time_max_ms: int = 100

var current_scene: Node = null

onready var loading_screen = preload("res://ui/LoadingScreen.tscn")

var loading_screen_instance: Node = null


func _ready() -> void:
	var root = get_tree().get_root()
	
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
func change_scene(path: String) -> int:
	if path == "":
		return ERR_CANT_CREATE
	
	loader = ResourceLoader.load_interactive(path)
	
	if loader == null:
		printerr("Couldn't load interactive loader!")
		
		return ERR_CANT_CREATE
	else:
		#Events.emit_signal("scene_changed")
		_play_loading_animation()
		
		return OK


func _play_loading_animation() -> void:
	loading_screen_instance = loading_screen.instance()
	
	get_tree().get_root().add_child(loading_screen_instance)
	
	var _error = loading_screen_instance.connect("fade_in_finished", self, "_on_LoadingScreen_fade_in_finished")
	
	loading_screen_instance.play_loading_animation()


func _set_new_scene(resource: Resource) -> void:
	current_scene = resource.instance()
	
	get_tree().get_root().add_child(current_scene)
	
	var _error = loading_screen_instance.connect("fade_out_finished", self, "_on_LoadingScreen_fade_out_finished")
	
	loading_screen_instance.fade_out()


func _start_loader() -> void:
	set_process(true)
	
	wait_frames = 1


func _on_LoadingScreen_fade_in_finished() -> void:
	# Wait until sound effects and such have finished playing
	# TODO: current_scene.cleanup()
	current_scene.queue_free()
	
	_start_loader()


func _on_LoadingScreen_fade_out_finished() -> void:
	loading_screen_instance.queue_free()
	
	# TODO: Enable buttons, input
	#current_scene.on_load()
