extends MarginContainer


export(String, FILE, "*.tscn") var next_scene: String

export(Resource) var chapter_data: Resource 

export(float) var enemy_phase_container_fade_time_seconds: float = 0.75

export(PackedScene) var view_unit_menu_packed_scene: PackedScene

export(float) var view_unit_menu_fade_time_seconds: float = 0.5

var _timer: Timer
var _player_turn_count: int = 0
var _total_drag_time_seconds: float = 0

var _is_battle_finished: bool = false

onready var _progress_bar: TextureProgress = $CanvasLayer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/TextureProgress
onready var _tween: Tween = $CanvasLayer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/TextureProgress/Tween


func _ready() -> void:
	set_process(false)
	
	GameData.load_data()
	
	$BattleTheme.play()


func _process(_delta: float) -> void:
	var percentage_left = _progress_bar.max_value * _timer.time_left / _timer.wait_time
	
	_progress_bar.value = percentage_left


func on_instance(data: Object) -> void:
	assert(data is ChapterData)
	
	chapter_data = data


func _update_turn_count() -> void:
	$CanvasLayer/MarginContainer/HBoxContainer/VBoxContainer2/TurnCountLabel.text = "%d" % _player_turn_count


## Signals

func _on_Board_drag_timer_started(timer: Timer) -> void:
	_timer = timer
	
	_progress_bar.value = _progress_bar.max_value
	
	set_process(true)


func _on_Board_drag_timer_stopped(time_left_seconds: float) -> void:
	set_process(false)
	
	if _timer != null:
		_total_drag_time_seconds += _timer.wait_time - time_left_seconds
	
	_timer = null


func _on_Board_drag_timer_reset() -> void:
	var _error = _tween.interpolate_property(_progress_bar, "value", 
		_progress_bar.value, _progress_bar.max_value,
		0.5,
		Tween.TRANS_LINEAR)
	
	_error = _tween.start()


func _on_Board_player_turn_started() -> void:
	_player_turn_count += 1
	
	_update_turn_count()


func _on_Board_victory() -> void:
	if _is_battle_finished:
		return
	
	_is_battle_finished = true
	
	$CanvasLayer/VictoryScreen.initialize(_total_drag_time_seconds, _player_turn_count)
	$CanvasLayer/VictoryScreen.grab_focus()
	
	$CanvasLayer/VictoryScreen.show()


func _on_Board_defeat() -> void:
	if _is_battle_finished:
		return
	
	_is_battle_finished = true
	
	$CanvasLayer/DefeatScreen.show()
	$CanvasLayer/DefeatScreen.grab_focus()
	
	$BattleTheme.stop()


func _on_DefeatScreen_quit_button_pressed() -> void:
	if Loader.change_scene("res://ui/pre_battle_menu/stack_based_pre_battle_menu.tscn") != OK:
		printerr("Failed to return to pre-battle menu")


func _on_DefeatScreen_try_again_button_pressed() -> void:
	if Loader.change_scene(filename, chapter_data) != OK:
		printerr("Failed to reload scene")


func _on_VictoryScreen_continue_button_pressed() -> void:
	if Loader.change_scene(next_scene, chapter_data) != OK:
		printerr("Failed to change to %s" % next_scene)


func _on_GiveUpButton_pressed() -> void:
	_on_Board_defeat()
	
	$Board.on_give_up()


func _on_DragModeOptionButton_drag_mode_changed(drag_mode: int) -> void:
	$Board.update_drag_mode(drag_mode)


func _on_Board_enemy_phase_started(current_enemy_phase: int, enemy_phase_count: int) -> void:
	var control: Control = $CanvasLayer/EnemyPhaseCenterContainer
	
	control.show()
	
	var control_tween: Tween = $CanvasLayer/EnemyPhaseCenterContainer/Tween
	
	var _error = control_tween.interpolate_property(control,
		"modulate",
		Color.transparent,
		Color.white,
		enemy_phase_container_fade_time_seconds,
		Tween.TRANS_LINEAR)
	
	_error = control_tween.start()
	
	$CanvasLayer/EnemyPhaseCenterContainer/NinePatchRect/Label.text = "%s %d/%d" % [tr("BATTLE"), current_enemy_phase, enemy_phase_count]


func _on_Board_enemies_appeared() -> void:
	var control: Control = $CanvasLayer/EnemyPhaseCenterContainer
	
	var control_tween: Tween = $CanvasLayer/EnemyPhaseCenterContainer/Tween
	
	var _error = control_tween.interpolate_property(control,
		"modulate",
		control.modulate,
		Color.transparent,
		enemy_phase_container_fade_time_seconds,
		Tween.TRANS_LINEAR)
	
	_error = control_tween.start()
	
	yield(control_tween, "tween_all_completed")
	
	$CanvasLayer/EnemyPhaseCenterContainer.hide()


func _on_Board_unit_selected_for_view(unit: Unit) -> void:
	var view_unit_menu_tween = $ViewUnitMenuCanvasLayer/Tween
	
	if not view_unit_menu_tween.is_active():
		var view_unit_menu: Control = view_unit_menu_packed_scene.instance()
		
		$ViewUnitMenuCanvasLayer.add_child(view_unit_menu)
		
		view_unit_menu.initialize_from_data(unit.get_job(), unit.get_base_stats(), unit.get_stats(), unit.get_level(), unit.get_skills(), unit.get_status_effects(), unit.faction == Unit.PLAYER_FACTION, true, unit.faction == Unit.ENEMY_FACTION)
		
		var _error = view_unit_menu.connect("go_back", self, "_on_ViewUnitMenu_go_back", [view_unit_menu])
		
		view_unit_menu.modulate = Color.transparent
		
		view_unit_menu_tween.interpolate_property(view_unit_menu,
			"modulate",
			Color.transparent,
			Color.white,
			view_unit_menu_fade_time_seconds,
			Tween.TRANS_SINE)
		
		view_unit_menu_tween.start()
		
		$ViewUnitMenuCanvasLayer/SelectUnitAudio.play()


func _on_ViewUnitMenu_go_back(view_unit_menu: Control) -> void:
	var view_unit_menu_tween = $ViewUnitMenuCanvasLayer/Tween
	
	view_unit_menu_tween.interpolate_property(view_unit_menu,
		"modulate",
		view_unit_menu.modulate,
		Color.transparent,
		view_unit_menu_fade_time_seconds,
		Tween.TRANS_SINE)
	
	view_unit_menu_tween.start()
	
	yield(view_unit_menu_tween, "tween_all_completed")
	
	view_unit_menu.queue_free()

