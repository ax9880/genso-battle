extends Node2D

class_name SkillEffect


onready var skill_sound := $SkillSound
onready var tween := $Tween


signal effect_finished


func execute(_unit: Unit, _skill: Skill, _target_cells: Array) -> void:
	emit_signal("effect_finished")
