extends SkillEffect


# Frame at which the skill is activated
export(int) var activation_frame: int = 0
export(PackedScene) var animation_packed_scene: PackedScene

var target_count: int = 0
var targets_affected: int = 0
var absorbed_damage: int = 0
var max_absorbed_damage: int = 0


func _ready() -> void:
	$AnimatedSprite.hide()
	$AnimatedSprite.stop()


func start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	target_count = target_cells.size()
	
	if target_count == 0:
		emit_signal("effect_finished")
		
		return
	
	targets_affected = 0
	absorbed_damage = 0
	max_absorbed_damage = skill.max_heal
	
	$SkillSound.play()
	
	for cell in target_cells:
		var animated_sprite: AnimatedSprite = animation_packed_scene.instance()
		
		add_child(animated_sprite)
		animated_sprite.position = cell.position
		
		if activation_frame > 0:
			var _error = animated_sprite.connect("frame_changed", self,
							"_on_AnimatedSprite_frame_changed",
							[animated_sprite, unit, skill, cell.unit])
		else:
			_apply_skill(unit, skill, cell.unit)
		
		var _error = animated_sprite.connect("animation_finished", self,
						"_on_AnimatedSprite_animation_finished",
						[unit],
						CONNECT_ONESHOT)
		
		animated_sprite.play()


func _apply_skill(unit: Unit, skill: Skill, target_unit: Unit) -> void:
	if target_unit != null:
		var callback = funcref(self, "on_damage_absorbed")
		
		target_unit.apply_skill(unit, skill, callback)


func on_damage_absorbed(damage: int) -> void:
	if damage > 0:
		absorbed_damage += damage


func _build_heal_particles(unit: Unit) -> void:
	var particles: CPUParticles2D = heal_particles_packed_scene.instance()
	
	unit.add_child(particles)
	
	particles.emitting = true


func _on_AnimatedSprite_frame_changed(animated_sprite: AnimatedSprite, unit: Unit, skill: Skill, target_unit: Unit) -> void:
	if animated_sprite.frame == activation_frame:
		_apply_skill(unit, skill, target_unit)


func _on_AnimatedSprite_animation_finished(unit: Unit) -> void:
	targets_affected += 1
	
	if targets_affected >= target_count:
		if absorbed_damage > 0:
			unit.inflict_damage(max(-max_absorbed_damage, -absorbed_damage))
			
			_build_heal_particles(unit)
		
		emit_signal("effect_finished")
		hide()
		queue_free()
