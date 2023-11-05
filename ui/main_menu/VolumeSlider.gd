extends HSlider

# https://www.gdquest.com/tutorial/godot/audio/volume-slider/

export var bus_name := "Music"


onready var bus_index := AudioServer.get_bus_index(bus_name)
onready var slide_sound_effect := $SlideSoundEffect


signal on_changed(bus_name, volume)


func _ready() -> void:
	value = db2linear(AudioServer.get_bus_volume_db(bus_index))
	
	var _error = connect("value_changed", self, "_on_VolumeSlider_value_changed")


func _on_VolumeSlider_value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_db(bus_index, linear2db(new_value))
	
	slide_sound_effect.play()
	
	emit_signal("on_changed", bus_name, new_value)
