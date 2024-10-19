extends AudioStreamPlayer


export(float) var fade_time_seconds: float = 0.9

onready var _tween: Tween = $Tween


func _ready() -> void:
	if Loader.connect("scene_changed", self, "_on_Loader_scene_changed") != OK:
		printerr("Failed to connect to Loader signal")


func _on_Loader_scene_changed() -> void:
	if _tween.is_active():
		return
	
	var _error = _tween.interpolate_property(self,
			"volume_db",
			volume_db,
			-80,
			fade_time_seconds,
			Tween.TRANS_LINEAR)
	
	if not _tween.start():
		push_warning("Failed to start _tween to fade out audio")
