extends HBoxContainer


signal change_button_clicked
signal unit_selected
signal unit_dropped_on_unit(target_unit_item, dropped_unit_item)
signal unit_double_clicked()

var _is_draggable: bool = false

onready var _name_label: Label = $VBoxContainer/HBoxContainer/NameLabel


func initialize(job: Job, is_draggable: bool = false, compare_job: Job = null) -> void:
	_is_draggable = is_draggable
	
	_name_label.text = tr(job.job_name)
	
	$UnitIcon.initialize(job, _is_draggable)
	
	var compare_job_stats: Stats = null
	
	if compare_job != null:
		compare_job_stats = compare_job.stats
	
	$VBoxContainer/UnitStatsContainer.initialize(job.stats, compare_job_stats)


func set_change_button_as_choose_button() -> void:
	$ChangeButton.text = tr("CHOOSE")


func highlight() -> void:
	if $AnimationPlayer.current_animation.empty():
		$AnimationPlayer.play("highlight")
		
		$HighlightAudio.play()


# This method is untyped because it returns a Variant
func get_drag_data(_position: Vector2):
	if _is_draggable:
		set_drag_preview(_build_drag_preview())
		
		return self
	else:
		return null


# https://www.youtube.com/watch?v=cNvzGKCkNXg
# https://github.com/exploregamedev/Godot-demos/blob/main/IntroToDragAndDrop-part_1/demo-final
func can_drop_data(_position: Vector2, data) -> bool:
	# And data.is_in_group("draggable")
	return _is_draggable and data is HBoxContainer and data != self


func drop_data(_position: Vector2, data) -> void:
	emit_signal("unit_dropped_on_unit", self, data)


# Builds a drag preview using the unit's icon
func _build_drag_preview() -> Control:
	$UnitIcon/TextureRect2.hide()
	
	var nine_patch_rect = $UnitIcon.duplicate()
	
	nine_patch_rect.modulate.a = 0.75
	
	return nine_patch_rect


func hide_change_button() -> void:
	$ChangeButton.hide()


func _on_ChangeButton_pressed() -> void:
	emit_signal("change_button_clicked")


func _on_UnitIcon_mouse_entered() -> void:
	$UnitIcon.show_glow()


func _on_UnitIcon_mouse_exited()  -> void:
	$UnitIcon.hide_glow()


func _on_UnitIcon_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		emit_signal("unit_selected")
	
	if event is InputEventMouseButton and event.doubleclick:
		emit_signal("unit_double_clicked")

