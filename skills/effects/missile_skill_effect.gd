extends SkillEffect


export(PackedScene) var particle_arc_scene: PackedScene
export(PackedScene) var hit_effect_packed_scene: PackedScene


func _start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	for target_cell in target_cells:
		if target_cell.unit == unit:
			_on_ParticleArc_target_reached(unit, skill, target_cell)
		else:
			var particle_arc: Node2D = particle_arc_scene.instance()
			
			unit.add_child_at_offset(particle_arc)
			
			var _error = particle_arc.connect("target_reached", self,
							"_on_ParticleArc_target_reached",
							[unit, skill, target_cell])
			
			var start_position: Vector2 = _get_start_position(unit)
			var target_position: Vector2 = _get_target_position(target_cell, skill)
			
			particle_arc.play(start_position, target_position)


# Instance heal particles / instance the next effect on arrival
# It should free itself once it's done
func _on_ParticleArc_target_reached(unit: Unit, skill: Skill, target_cell: Cell) -> void:
	var hit_effect: Node2D = hit_effect_packed_scene.instance()
	
	# Hit effect has to free automatically
	# TODO: If skill is targeted individually, add hit effect as child of target_cell.unit
	target_cell.add_child(hit_effect)
	
	hit_effect.play()
	
	_apply_skill(unit, skill, target_cell)
	
	_update_count(unit)


func _get_start_position(unit: Unit) -> Vector2:
	if unit.is2x2():
		return unit.get_offset_origin()
	else:
		return unit.position


func _get_target_position(target_cell: Cell, skill: Skill) -> Vector2:
	if skill.is_targeted_individually() and target_cell.unit.is2x2():
		return target_cell.unit.get_offset_origin()
	else:
		return target_cell.position
