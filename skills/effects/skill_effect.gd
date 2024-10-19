class_name SkillEffect
extends Node2D


signal effect_finished

export(PackedScene) var heal_particles_packed_scene: PackedScene
export(float) var delay_before_absorbing_damage_seconds: float = 0.5
export(float) var delay_after_absorbing_damage_seconds: float = 0.5
export(float) var delay_after_skill_without_absorb_seconds: float = 0.2

var _target_count: int = 0
var _targets_affected: int = 0

var _absorbed_damage: int = 0
var _max_absorbed_damage: int = 0

var _pusher: Pusher

# Cell of the unit that is using the current skill
var _start_cell: Cell

# Array<Unit> of units so that units are not affected by the skill or pushed several times
# by the same skill (e.g. as a skill is applied over a row and the unit is pushed
# to each cell, but only in the direction in which the cells are evaluated).
var _affected_units: Array

onready var _skill_sound := $SkillSound
onready var _tween := $Tween


func start(unit: Unit, skill: Skill, target_cells: Array, start_cell: Cell, pusher: Pusher) -> void:
	_target_count = target_cells.size()
	
	_pusher = pusher
	_start_cell = start_cell
	
	_affected_units = []
	
	if _target_count == 0:
		call_deferred("emit_signal", "effect_finished")
	else:
		$SkillSound.play()
		
		_targets_affected = 0
		_absorbed_damage = 0
		_max_absorbed_damage = skill.max_heal
		
		_start(unit, skill, target_cells)


func _start(_unit: Unit, _skill: Skill, _target_cells: Array) -> void:
	printerr("Override SkillEffect._start()")
	
	emit_signal("effect_finished")


func _build_heal_particles(unit: Unit) -> void:
	var particles: CPUParticles2D = heal_particles_packed_scene.instance()
	
	# Particles is freed automatically after its timer expires
	unit.add_child_at_offset(particles)
	
	particles.emitting = true
	
	$AbsorbHealSound.play()


func _apply_skill(unit: Unit, skill: Skill, target_cell: Cell) -> void:
	var target_unit: Unit = target_cell.unit
	
	if target_unit != null and not target_unit in _affected_units:
		_affected_units.push_back(target_unit)
		
		var callback = funcref(self, "on_damage_absorbed")
		
		target_unit.apply_skill(unit, skill, callback)
		
		if skill.is_healing():
			_build_heal_particles(target_unit)
		else:
			# TODO: For missile skill, show the other effect
			pass
		
		if skill.is_pusher:
			_pusher.push_unit(_start_cell, target_cell)


func on_damage_absorbed(damage: int) -> void:
	if damage > 0:
		_absorbed_damage += damage


func _update_count(unit: Unit) -> void:
	_targets_affected += 1
	
	if _targets_affected >= _target_count:
		if _absorbed_damage > 0:
			$DelayBeforeAbsorbingDamageTimer.start()
			
			yield($DelayBeforeAbsorbingDamageTimer, "timeout")
			
			unit.inflict_damage(int(max(-_max_absorbed_damage, -_absorbed_damage)))
			
			_build_heal_particles(unit)
			
			$DelayAfterAbsorbingDamageTimer.start()
			
			yield($DelayAfterAbsorbingDamageTimer, "timeout")
		else:
			$DelayAfterSkillWithoutAbsorbTimer.start()
			
			yield($DelayAfterSkillWithoutAbsorbTimer, "timeout")
		
		emit_signal("effect_finished")
		hide()
		
		if $SkillSound.playing:
			yield($SkillSound, "finished")
		
		if $AbsorbHealSound.playing:
			yield($AbsorbHealSound, "finished")
		
		queue_free()
