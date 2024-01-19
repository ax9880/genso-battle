extends AudioStreamPlayer


export(float) var fade_time_seconds: float = 0.9

onready var tween: Tween = $Tween

func _ready() -> void:
	if Loader.connect("scene_changed", self, "_on_Loader_scene_changed") != OK:
		printerr("Failed to connect to Loader signal")


func _on_Loader_scene_changed() -> void:
	if not tween.is_active():
		tween.interpolate_property(self,
			"volume_db",
			volume_db,
			-80,
			fade_time_seconds,
			Tween.TRANS_LINEAR)
		
		tween.start()
