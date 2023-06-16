extends MarginContainer


onready var progress_bar: TextureProgress = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/TextureProgress
onready var tween: Tween = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/TextureProgress/Tween

var timer: Timer
var player_turn_count: int = 0
var total_drag_time_seconds: float = 0


func _ready() -> void:
	set_process(false)
	
	GameData.load_data()


func _process(_delta: float) -> void:
	var percentage_left = progress_bar.max_value * timer.time_left / timer.wait_time
	
	progress_bar.value = percentage_left


func _on_Board_drag_timer_started(_timer: Timer) -> void:
	timer = _timer
	
	progress_bar.value = progress_bar.max_value
	
	set_process(true)


func _on_Board_drag_timer_stopped(time_left_seconds: float):
	set_process(false)
	
	if timer != null:
		total_drag_time_seconds += timer.wait_time - time_left_seconds
	
	timer = null


func _on_Board_drag_timer_reset() -> void:
	var _error = tween.interpolate_property(progress_bar, "value", 
		progress_bar.value, progress_bar.max_value,
		0.5,
		Tween.TRANS_LINEAR)
	
	_error = tween.start()


func _on_Board_player_turn_started() -> void:
	player_turn_count += 1


func _on_Board_victory() -> void:
	$CanvasLayer/VictoryScreen.initialize(total_drag_time_seconds, player_turn_count)
	
	$CanvasLayer/VictoryScreen.show()


func _on_Board_defeat():
	$CanvasLayer/DefeatScreen.show()


func _on_DefeatScreen_quit_button_pressed() -> void:
	get_tree().change_scene("res://ui/PreBattleMenu.tscn")


func _on_DefeatScreen_try_again_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_VictoryScreen_continue_button_pressed() -> void:
	get_tree().change_scene("res://ui/PreBattleMenu.tscn")


func _on_GiveUpButton_pressed() -> void:
	_on_Board_defeat()


func _on_DragModeOptionButton_drag_mode_changed(drag_mode: int) -> void:
	$Board.update_drag_mode(drag_mode)


func _on_Board_enemy_phase_started(current_enemy_phase: int, enemy_phase_count: int) -> void:
	$CanvasLayer/EnemyPhaseCenterContainer.show()
	
	$CanvasLayer/EnemyPhaseCenterContainer/NinePatchRect/Label.text = "%s %d/%d" % [tr("BATTLE"), current_enemy_phase, enemy_phase_count]


func _on_Board_enemies_appeared():
	$CanvasLayer/EnemyPhaseCenterContainer.hide()
