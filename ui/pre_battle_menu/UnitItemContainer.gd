extends HBoxContainer

onready var name_label: Label = $VBoxContainer/HBoxContainer/NameLabel

# Job that this container is showing
var job: Job

var is_draggable: bool = false

var compare_job: Job

signal change_button_clicked
signal unit_selected
signal unit_dropped_on_unit(target_unit_item, dropped_unit_item)
signal unit_double_clicked()


func initialize(_job: Job, _is_draggable: bool = false, _compare_job: Job = null) -> void:
	job = _job
	is_draggable = _is_draggable
	compare_job = _compare_job
	
	name_label.text = tr(job.job_name)
	
	$UnitIcon.initialize(job, is_draggable)
	$VBoxContainer/UnitStatsContainer.initialize(job, compare_job)


func set_change_button_as_choose_button() -> void:
	$ChangeButton.text = tr("CHOOSE")


func get_drag_data(_position: Vector2):
	if is_draggable:
		set_drag_preview(_build_drag_preview())
		
		return self
	else:
		return null


# https://www.youtube.com/watch?v=cNvzGKCkNXg
# https://github.com/exploregamedev/Godot-demos/blob/main/IntroToDragAndDrop-part_1/demo-final
func can_drop_data(_position: Vector2, data) -> bool:
	# And data.is_in_group("draggable")
	return is_draggable and data is HBoxContainer and data != self


func drop_data(_position: Vector2, data) -> void:
	emit_signal("unit_dropped_on_unit", self, data)


# Builds a drag preview using the unit's icon
func _build_drag_preview() -> Control:
	var nine_patch_rect = $UnitIcon.duplicate()
	
	nine_patch_rect.modulate.a = 0.75
	
	return nine_patch_rect


func hide_change_button() -> void:
	$ChangeButton.hide()


func _on_ChangeButton_pressed() -> void:
	emit_signal("change_button_clicked")


func _on_UnitIcon_mouse_entered() -> void:
	# TODO: Allow selecting units using keyboard?
	# The issue is that if you hover, you grab focus here, but if you hover away,
	# you should look focus. The mouse expectations and the keyboard expectations
	# are different
	$UnitIcon.show_glow()


func _on_UnitIcon_mouse_exited()  -> void:
	$UnitIcon.hide_glow()


func _on_UnitIcon_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		emit_signal("unit_selected")
	
	if event is InputEventMouseButton and event.doubleclick:
		emit_signal("unit_double_clicked")

