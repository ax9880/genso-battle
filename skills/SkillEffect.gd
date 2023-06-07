extends Node2D

class_name SkillEffect


export(PackedScene) var heal_particles_packed_scene: PackedScene

onready var skill_sound := $SkillSound
onready var tween := $Tween

signal effect_finished


func start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	emit_signal("effect_finished")
