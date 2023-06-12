extends HBoxContainer


onready var name_label: Label = $VBoxContainer/Label
onready var texture_rect: TextureRect = $NinePatchRect/TextureRect
onready var weapon_type_texture_rect: TextureRect = $NinePatchRect/WeaponTypeTexture


signal view_button_clicked
signal change_button_clicked


func initialize(job: Job) -> void:
	name_label.text = tr(job.job_name)
	texture_rect.texture = job.portrait
	weapon_type_texture_rect.texture = load(Enums.WEAPON_TYPE_TEXTURES[job.stats.weapon_type])


func hide_view_button() -> void:
	$ViewButton.hide()


func _on_ViewButton_pressed() -> void:
	emit_signal("view_button_clicked")


func _on_ChangeButton_pressed() -> void:
	emit_signal("change_button_clicked")
