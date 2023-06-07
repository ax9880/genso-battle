extends Node2D

class_name SkillEffect

export(PackedScene) var heal_particles_packed_scene: PackedScene

onready var skill_sound := $SkillSound
onready var tween := $Tween

var target_count: int = 0
var targets_affected: int = 0

var absorbed_damage: int = 0
var max_absorbed_damage: int = 0

signal effect_finished


func start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	target_count = target_cells.size()
	
	if target_count == 0:
		emit_signal("effect_finished")
	else:
		$SkillSound.play()
		
		targets_affected = 0
		absorbed_damage = 0
		max_absorbed_damage = skill.max_heal
		
		_start(unit, skill, target_cells)


func _start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	printerr("Override SkillEffect._start()")
	
	emit_signal("effect_finished")


func _build_heal_particles(unit: Unit) -> void:
	var particles: CPUParticles2D = heal_particles_packed_scene.instance()
	
	unit.add_child(particles)
	
	particles.emitting = true


func _apply_skill(unit: Unit, skill: Skill, target_unit: Unit) -> void:
	if target_unit != null:
		var callback = funcref(self, "on_damage_absorbed")
		
		target_unit.apply_skill(unit, skill, callback)
		
		if skill.is_healing():
			_build_heal_particles(target_unit)
		else:
			# TODO: For missile skill, show the other effect
			pass


func on_damage_absorbed(damage: int) -> void:
	if damage > 0:
		absorbed_damage += damage


func _update_count(unit: Unit) -> void:
	targets_affected += 1
	
	if targets_affected >= target_count:
		if absorbed_damage > 0:
			unit.inflict_damage(max(-max_absorbed_damage, -absorbed_damage))
			
			_build_heal_particles(unit)
			
			# TODO: add a delay
		
		emit_signal("effect_finished")
		hide()
		queue_free()
