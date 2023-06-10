extends MarginContainer


onready var progress_bar: TextureProgress = $MarginContainer/VBoxContainer/TextureProgress
onready var tween: Tween = $MarginContainer/VBoxContainer/TextureProgress/Tween

var timer: Timer


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	var percentage_left = progress_bar.max_value * timer.time_left / timer.wait_time
	
	progress_bar.value = percentage_left


func _on_Board_drag_timer_started(_timer: Timer) -> void:
	timer = _timer
	
	progress_bar.value = progress_bar.max_value
	
	set_process(true)


func _on_Board_drag_timer_stopped():
	set_process(false)


func _on_Board_drag_timer_reset() -> void:
	var _error = tween.interpolate_property(progress_bar, "value", 
		progress_bar.value, progress_bar.max_value,
		0.5,
		Tween.TRANS_LINEAR)
	
	_error = tween.start()
