extends HBoxContainer

onready var name_label: Label = $VBoxContainer/HBoxContainer/NameLabel
onready var texture_rect: TextureRect = $NinePatchRect/TextureRect
onready var glow_texture_rect: TextureRect = $NinePatchRect/GlowTextureRect
onready var weapon_type_texture_rect: TextureRect = $NinePatchRect/WeaponTypeTexture

# Job that this container is showing
var job: Job

var is_draggable: bool = false

var compare_job: Job

signal view_button_clicked
signal change_button_clicked
signal unit_selected
signal unit_dropped_on_unit(target_unit_item, dropped_unit_item)


func initialize(_job: Job, _is_draggable: bool = false, _compare_job: Job = null) -> void:
	job = _job
	is_draggable = _is_draggable
	compare_job = _compare_job
	
	if not is_draggable:
		$NinePatchRect.mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	name_label.text = tr(job.job_name)
	texture_rect.texture = job.portrait
	weapon_type_texture_rect.texture = load(Enums.WEAPON_TYPE_TEXTURES[job.stats.weapon_type])
	
	# TODO: Add label translations

	if compare_job != null:
		_show_compared_number($VBoxContainer/VBoxContainer/HBoxContainer3/HealthNumber, job.stats.health, compare_job.stats.health)
		
		_show_compared_number($VBoxContainer/VBoxContainer/HBoxContainer/AttackNumber, job.stats.attack, compare_job.stats.attack)
		_show_compared_number($VBoxContainer/VBoxContainer/HBoxContainer/DefenseNumber, job.stats.defense, compare_job.stats.defense)
		
		_show_compared_number($VBoxContainer/VBoxContainer/HBoxContainer2/SpiritualAttackNumber, job.stats.spiritual_attack, compare_job.stats.spiritual_attack)
		_show_compared_number($VBoxContainer/VBoxContainer/HBoxContainer2/SpiritualDefenseNumber, job.stats.spiritual_defense, compare_job.stats.spiritual_defense)
	else:
		_show_number($VBoxContainer/VBoxContainer/HBoxContainer3/HealthNumber, job.stats.health)
		
		_show_number($VBoxContainer/VBoxContainer/HBoxContainer/AttackNumber, job.stats.attack)
		_show_number($VBoxContainer/VBoxContainer/HBoxContainer/DefenseNumber, job.stats.defense)
		
		_show_number($VBoxContainer/VBoxContainer/HBoxContainer2/SpiritualAttackNumber, job.stats.spiritual_attack)
		_show_number($VBoxContainer/VBoxContainer/HBoxContainer2/SpiritualDefenseNumber, job.stats.spiritual_defense)


func _show_number(label: Label, job_stat: int) -> void:
	label.text = str(job_stat)


func _show_compared_number(label: Label, job_stat: int, compare_job_stat: int) -> void:
	var difference: int = job_stat - compare_job_stat
	
	if difference > 0:
		label.add_color_override("font_color", Color.green)
		
		label.text = "%d (%+d)" % [job_stat, difference]
	elif difference < 0:
		label.add_color_override("font_color", Color.red)
		
		label.text = "%d (%+d)" % [job_stat, difference]
	else:
		_show_number(label, job_stat)


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
	var nine_patch_rect = $NinePatchRect.duplicate()
	
	nine_patch_rect.modulate.a = 0.75
	
	return nine_patch_rect


func hide_view_button() -> void:
	#$ViewButton.hide()
	pass


func hide_change_button() -> void:
	$ChangeButton.hide()


func _on_ViewButton_pressed() -> void:
	emit_signal("view_button_clicked")


func _on_ChangeButton_pressed() -> void:
	emit_signal("change_button_clicked")


func _on_NinePatchRect_mouse_entered() -> void:
	# TODO: Allow selecting units using keyboard?
	# The issue is that if you hover, you grab focus here, but if you hover away,
	# you should look focus. The mouse expectations and the keyboard expectations
	# are different
	glow_texture_rect.show()


func _on_NinePatchRect_mouse_exited() -> void:
	glow_texture_rect.hide()


func _on_NinePatchRect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		emit_signal("unit_selected")

