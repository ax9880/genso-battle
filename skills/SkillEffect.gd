extends Node2D


onready var skill_sound := $SkillSound


signal animation_done


# Array<Cell>
func play_animation(targets: Array) -> void:
	
	emit_signal("animation_done")
