extends HSlider
# https://www.gdquest.com/tutorial/godot/audio/volume-slider/

signal on_changed(bus_name, volume)

export var _bus_name := "Music"

onready var _bus_index := AudioServer.get_bus_index(_bus_name)
onready var _slide_sound_effect := $SlideSoundEffect


func _ready() -> void:
	value = db2linear(AudioServer.get_bus_volume_db(_bus_index))
	
	var _error = connect("value_changed", self, "_on_VolumeSlider_value_changed")


func _on_VolumeSlider_value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_db(_bus_index, linear2db(new_value))
	
	_slide_sound_effect.play()
	
	emit_signal("on_changed", _bus_name, new_value)
