extends HBoxContainer

onready var name_label: Label = $VBoxContainer/HBoxContainer/NameLabel
onready var texture_rect: TextureRect = $NinePatchRect/TextureRect
onready var weapon_type_texture_rect: TextureRect = $NinePatchRect/WeaponTypeTexture

var is_draggable: bool = false

# Job that this container is showing
var job: Job

signal view_button_clicked
signal change_button_clicked
signal unit_dropped_on_unit(target_unit_item, dropped_unit_item)


func initialize(_job: Job, _is_draggable: bool = false) -> void:
	is_draggable = _is_draggable
	job = _job
	
	name_label.text = tr(job.job_name)
	texture_rect.texture = job.portrait
	weapon_type_texture_rect.texture = load(Enums.WEAPON_TYPE_TEXTURES[job.stats.weapon_type])
	
	# TODO: Add label translations
	#tr("ATTACK_LABEL") + ": %d" % job.stats.attack
	$VBoxContainer/VBoxContainer/HBoxContainer3/HealthNumber.text = str(job.stats.health)
	
	$VBoxContainer/VBoxContainer/HBoxContainer/AttackNumber.text = "%d" % job.stats.attack
	$VBoxContainer/VBoxContainer/HBoxContainer/DefenseNumber.text = "%d" % job.stats.defense
	
	$VBoxContainer/VBoxContainer/HBoxContainer2/SpiritualAttackNumber.text = "%d" % job.stats.spiritual_attack
	$VBoxContainer/VBoxContainer/HBoxContainer2/SpiritualDefenseNumber.text = "%d" % job.stats.spiritual_defense


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
	$ViewButton.hide()


func _on_ViewButton_pressed() -> void:
	emit_signal("view_button_clicked")


func _on_ChangeButton_pressed() -> void:
	emit_signal("change_button_clicked")
